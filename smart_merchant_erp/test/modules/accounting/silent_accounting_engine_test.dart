import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/seeds/standard_coa_seeder.dart';

void main() {
  late AppDatabase db;
  late SilentAccountingEngine engine;
  late StandardCoaSeeder seeder;
  late String fiscalYearId;
  late String yerCurrencyId;
  late String usdCurrencyId;
  late String cashAccountId;
  late String salesAccountId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    engine = SilentAccountingEngine(db);
    seeder = StandardCoaSeeder(db);

    // زراعة شجرة الحسابات والعملات الأساسية
    await seeder.seedAll();

    final fy = await db.select(db.fiscalYearsTable).getSingle();
    fiscalYearId = fy.id;

    final currencies = await db.select(db.currenciesTable).get();
    yerCurrencyId = currencies.firstWhere((c) => c.code == 'YER').id;
    usdCurrencyId = currencies.firstWhere((c) => c.code == 'USD').id;

    final cashAcc = await engine.getAccountByRole('CASH_DRAWER_DEFAULT');
    cashAccountId = cashAcc.id;

    final salesAcc = await engine.getAccountByRole('SALES_REVENUE');
    salesAccountId = salesAcc.id;
  });

  tearDown(() async {
    await db.close();
  });

  group('SilentAccountingEngine Comprehensive Tests', () {
    test('يجب إنشاء قيد متزن بنجاح وتخزين القيم بعملة الأساس', () async {
      final entryId = await engine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-TEST-001',
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        description: 'فاتورة مبيعات نقدية تجريبية',
        lines: [
          JournalLineDraft(
            accountId: cashAccountId,
            debit: 15000.0,
            credit: 0.0,
            description: 'نقد مستلم في الصندوق',
          ),
          JournalLineDraft(
            accountId: salesAccountId,
            debit: 0.0,
            credit: 15000.0,
            description: 'إيراد مبيعات',
          ),
        ],
      );

      expect(entryId, isNotEmpty);

      // التحقق من الرأس
      final entry = await (db.select(db.journalEntriesTable)..where((e) => e.id.equals(entryId))).getSingle();
      expect(entry.referenceType, equals('SalesInvoice'));
      expect(entry.referenceId, equals('INV-TEST-001'));
      expect(entry.status, equals('Posted'));

      // التحقق من الأسطر
      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entryId)))
          .get();

      expect(lines.length, equals(2));
      expect(lines[0].baseDebit, equals(15000.0));
      expect(lines[0].baseCredit, equals(0.0));
      expect(lines[1].baseDebit, equals(0.0));
      expect(lines[1].baseCredit, equals(15000.0));
    });

    test('يجب رفض القيد غير المتزن ورمي استثناء AccountingBalanceException', () async {
      expect(
        () async => await engine.createBalancedEntry(
          fiscalYearId: fiscalYearId,
          referenceType: 'SalesInvoice',
          referenceId: 'INV-BAD',
          currencyId: yerCurrencyId,
          exchangeRate: 1.0,
          description: 'قيد غير متزن عمداً',
          lines: [
            JournalLineDraft(accountId: cashAccountId, debit: 20000.0),
            JournalLineDraft(accountId: salesAccountId, credit: 19500.0), // عجز 500 ريال
          ],
        ),
        throwsA(isA<AccountingBalanceException>()),
      );

      // التأكد من عدم كتابة أي قيد في قاعدة البيانات
      final allEntries = await db.select(db.journalEntriesTable).get();
      expect(allEntries.isEmpty, isTrue);
    });

    test('القيد بعملة أجنبية (USD) يجب أن يحسب قيمة عملة الأساس بدقة', () async {
      final entryId = await engine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-USD-100',
        currencyId: usdCurrencyId,
        exchangeRate: 530.0,
        description: 'مبيعات 100 دولار بسعر 530',
        lines: [
          JournalLineDraft(accountId: cashAccountId, debit: 100.0),
          JournalLineDraft(accountId: salesAccountId, credit: 100.0),
        ],
      );

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entryId)))
          .get();

      // 100 دولار = 53,000 ريال يمني
      expect(lines[0].debit, equals(100.0));
      expect(lines[0].baseDebit, equals(53000.0));
      expect(lines[1].credit, equals(100.0));
      expect(lines[1].baseCredit, equals(53000.0));
    });

    test('يجب منع القيد في فترة مالية مقفلة ورمي FiscalPeriodClosedException', () async {
      // قفل السنة المالية
      await (db.update(db.fiscalYearsTable)..where((fy) => fy.id.equals(fiscalYearId))).write(
        FiscalYearsTableCompanion(isClosed: const Value(true)),
      );

      expect(
        () async => await engine.createBalancedEntry(
          fiscalYearId: fiscalYearId,
          referenceType: 'Manual',
          referenceId: null,
          currencyId: yerCurrencyId,
          exchangeRate: 1.0,
          description: 'قيد في سنة مقفلة',
          lines: [
            JournalLineDraft(accountId: cashAccountId, debit: 500.0),
            JournalLineDraft(accountId: salesAccountId, credit: 500.0),
          ],
        ),
        throwsA(isA<FiscalPeriodClosedException>()),
      );
    });

    test('عكس القيد (Void / Reversal) يجب أن يعكس المدين والدائن ويلغي القيد الأصلي', () async {
      final originalId = await engine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-TO-CANCEL',
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        description: 'فاتورة مراد إلغاؤها',
        lines: [
          JournalLineDraft(accountId: cashAccountId, debit: 8000.0),
          JournalLineDraft(accountId: salesAccountId, credit: 8000.0),
        ],
      );

      // تنفيذ الإلغاء العكسي
      final reversalId = await engine.reverseEntry(
        originalEntryId: originalId,
        cancellationReason: 'خطأ في إدخال الفاتورة',
      );

      expect(reversalId, isNotEmpty);

      // التأكد من تعديل حالة القيد الأصلي إلى Voided
      final originalEntry = await (db.select(db.journalEntriesTable)..where((e) => e.id.equals(originalId))).getSingle();
      expect(originalEntry.status, equals('Voided'));

      // التأكد من أن القيد العكسي مدين بـ 8000 لحساب المبيعات ودائن بـ 8000 لحساب الصندوق
      final reversalLines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(reversalId)))
          .get();

      // سطر 1 كان مديناً أصبح دائناً
      expect(reversalLines[0].accountId, equals(cashAccountId));
      expect(reversalLines[0].baseDebit, equals(0.0));
      expect(reversalLines[0].baseCredit, equals(8000.0));

      // سطر 2 كان دائناً أصبح مديناً
      expect(reversalLines[1].accountId, equals(salesAccountId));
      expect(reversalLines[1].baseDebit, equals(8000.0));
      expect(reversalLines[1].baseCredit, equals(0.0));
    });
  });
}
