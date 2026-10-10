# 📦 PHASE 5: الخزينة، الصناديق، البنوك، وسندات القبض والصرف
## (Treasury Engine, Vouchers, Cash Drawers, Transfers & FX Gain/Loss)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء جدول السندات الشامل في Drift (`PaymentsTable`) لإدارة كل تدفقات النقد والبنوك.
2. بناء دورة **سند القبض (Receipt Voucher)**: قبض ديون العملاء، الإيرادات المتنوعة، ورؤوس الأموال.
3. بناء دورة **سند الصرف (Payment Voucher)**: سداد الموردين، المصاريف التشغيلية (إيجار، كهرباء)، والمسحوبات الشخصية للمالك.
4. معالجة **التحويل بين الصناديق والبنوك (Internal Fund Transfers)**.
5. حل الفخ المحاسبي رقم 13: **معالجة فروق أسعار الصرف التلقائية عند سداد الديون بعملة أجنبية (Realized FX Gain/Loss)**.
6. جرد الصندوق اليومي وإقفال الكاشير (X & Z Drawer Reports) مع معالجة العجز والزيادة.
7. حزمة اختبارات Unit Testing للتحقق من اتزان السندات وفروق العملة.

---

## 2. مخطط جداول Drift للخزينة والسندات (`treasury_tables.dart`)

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'financial_tables.dart';

// جدول السندات الموحد (قبض، صرف، تحويل)
@DataClassName('PaymentData')
class PaymentsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get paymentNumber => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get paymentDate => dateTime().withDefault(currentDateAndTime)();
  
  // نوع السند: 'Receipt' (سند قبض), 'Payment' (سند صرف), 'Transfer' (تحويل داخلي)
  TextColumn get voucherType => text()(); 
  
  // الغرض من السند: 'CustomerDebt', 'SupplierDebt', 'Expense', 'OwnerDrawings', 'Capital', 'Transfer'
  TextColumn get purpose => text()();

  // الطرف المرتبط (العميل أو المورد) - اختياري للمصاريف العامة
  TextColumn get partyId => text().nullable().references(PartiesTable, #id)();

  // الحساب المالي المرتبط (حساب المصروف، أو حساب الإيراد، أو حساب الطرف الثاني)
  TextColumn get targetAccountId => text().references(ChartOfAccountsTable, #id)();

  // طريقة الدفع / الصندوق / البنك المستخدم
  TextColumn get paymentMethodId => text().references(PaymentMethodsTable, #id)();
  TextColumn get cashAccountId => text().references(ChartOfAccountsTable, #id)(); // حساب الصندوق

  // العملة والمبالغ
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  
  RealColumn get amount => real()(); // المبلغ بعملة السند
  RealColumn get baseAmount => real()(); // المبلغ المعادل بعملة الأساس (amount * exchangeRate)

  // ربط بفاتورة معينة (في حال السداد المباشر لفاتورة محددة)
  TextColumn get referenceInvoiceId => text().nullable()();

  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Posted'))(); // Posted, Voided

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. معمارية سندات القبض وسندات الصرف (Treasury Service)

```dart
class TreasuryService {
  final AppDatabase db;
  final SilentAccountingEngine accountingEngine;

  TreasuryService({
    required this.db,
    required this.accountingEngine,
  });

  /// 1. إصدار سند قبض (من عميل أو إيراد متنوع)
  Future<String> createReceiptVoucher({
    required String fiscalYearId,
    required String paymentMethodId,
    required String cashAccountId, // حساب الصندوق المستلم
    required String currencyId,
    required double exchangeRate,
    required double amount,
    required String? partyId, // معرف العميل
    required String? targetAccountId, // إذا كان إيراداً عاماً
    required String? referenceInvoiceId,
    required String notes,
  }) async {
    return await db.transaction(() async {
      final baseAmount = PrecisionMath.roundMoney(amount * exchangeRate);
      final voucherNumber = 'RCV-${DateTime.now().millisecondsSinceEpoch}';

      String finalTargetAccountId;
      if (partyId != null) {
        final party = await (db.select(db.partiesTable)..where((p) => p.id.equals(partyId))).getSingle();
        finalTargetAccountId = party.accountId;
      } else {
        finalTargetAccountId = targetAccountId!;
      }

      final voucherId = await db.into(db.paymentsTable).insert(
        PaymentsTableCompanion.insert(
          paymentNumber: voucherNumber,
          voucherType: 'Receipt',
          purpose: partyId != null ? 'CustomerDebt' : 'GeneralRevenue',
          partyId: Value(partyId),
          targetAccountId: finalTargetAccountId,
          paymentMethodId: paymentMethodId,
          cashAccountId: cashAccountId,
          currencyId: currencyId,
          exchangeRate: Value(exchangeRate),
          amount: amount,
          baseAmount: baseAmount,
          referenceInvoiceId: Value(referenceInvoiceId),
          notes: Value(notes),
        ),
      );

      // توليد قيد اليومية الآلي
      // مدين: الصندوق (زيادة النقدية)
      // دائن: العميل (تخفيض الدين) أو حساب الإيراد
      final journalLines = [
        JournalLineDraft(
          accountId: cashAccountId,
          debit: amount,
          description: 'قبض نقدي بموجب سند $voucherNumber: $notes',
        ),
        JournalLineDraft(
          accountId: finalTargetAccountId,
          credit: amount,
          description: 'سداد دفعة بموجب سند $voucherNumber: $notes',
        ),
      ];

      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'Payment',
        referenceId: voucherId,
        currencyId: currencyId,
        exchangeRate: exchangeRate,
        description: 'قيد سند قبض $voucherNumber',
        lines: journalLines,
      );

      return voucherId;
    });
  }

  /// 2. إصدار سند صرف (سداد مورد أو مصروف عام)
  Future<String> createPaymentVoucher({
    required String fiscalYearId,
    required String paymentMethodId,
    required String cashAccountId, // الصندوق المنصرف منه
    required String currencyId,
    required double exchangeRate,
    required double amount,
    required String? partyId, // المورد
    required String? expenseAccountId, // حساب المصروف (إيجار، كهرباء، رواتب...)
    required String notes,
  }) async {
    return await db.transaction(() async {
      final baseAmount = PrecisionMath.roundMoney(amount * exchangeRate);
      final voucherNumber = 'PAY-${DateTime.now().millisecondsSinceEpoch}';

      String finalDebitAccountId;
      if (partyId != null) {
        final party = await (db.select(db.partiesTable)..where((p) => p.id.equals(partyId))).getSingle();
        finalDebitAccountId = party.accountId;
      } else {
        finalDebitAccountId = expenseAccountId!;
      }

      final voucherId = await db.into(db.paymentsTable).insert(
        PaymentsTableCompanion.insert(
          paymentNumber: voucherNumber,
          voucherType: 'Payment',
          purpose: partyId != null ? 'SupplierDebt' : 'Expense',
          partyId: Value(partyId),
          targetAccountId: finalDebitAccountId,
          paymentMethodId: paymentMethodId,
          cashAccountId: cashAccountId,
          currencyId: currencyId,
          exchangeRate: Value(exchangeRate),
          amount: amount,
          baseAmount: baseAmount,
          notes: Value(notes),
        ),
      );

      // توليد قيد اليومية الآلي
      // مدين: المورد (تخفيض التزامه) أو المصروف (إثبات النفقة)
      // دائن: الصندوق (نقص النقدية)
      final journalLines = [
        JournalLineDraft(
          accountId: finalDebitAccountId,
          debit: amount,
          description: 'صرف بموجب سند $voucherNumber: $notes',
        ),
        JournalLineDraft(
          accountId: cashAccountId,
          credit: amount,
          description: 'منصرف من الصندوق بموجب سند $voucherNumber',
        ),
      ];

      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'Payment',
        referenceId: voucherId,
        currencyId: currencyId,
        exchangeRate: exchangeRate,
        description: 'قيد سند صرف $voucherNumber',
        lines: journalLines,
      );

      return voucherId;
    });
  }

  /// 3. التحويل المالي بين الصناديق والبنوك
  Future<String> transferFunds({
    required String fiscalYearId,
    required String fromCashAccountId,
    required String toCashAccountId,
    required String paymentMethodId,
    required String currencyId,
    required double exchangeRate,
    required double amount,
    required String notes,
  }) async {
    return await db.transaction(() async {
      final baseAmount = PrecisionMath.roundMoney(amount * exchangeRate);
      final voucherNumber = 'TRF-${DateTime.now().millisecondsSinceEpoch}';

      final voucherId = await db.into(db.paymentsTable).insert(
        PaymentsTableCompanion.insert(
          paymentNumber: voucherNumber,
          voucherType: 'Transfer',
          purpose: 'Transfer',
          targetAccountId: toCashAccountId,
          paymentMethodId: paymentMethodId,
          cashAccountId: fromCashAccountId,
          currencyId: currencyId,
          exchangeRate: Value(exchangeRate),
          amount: amount,
          baseAmount: baseAmount,
          notes: Value(notes),
        ),
      );

      // قيد التحويل الداخلي:
      // مدين: الصندوق المستلم
      // دائن: الصندوق المسلم
      final journalLines = [
        JournalLineDraft(
          accountId: toCashAccountId,
          debit: amount,
          description: 'استلام تحويل داخلي $voucherNumber: $notes',
        ),
        JournalLineDraft(
          accountId: fromCashAccountId,
          credit: amount,
          description: 'تسليم تحويل داخلي $voucherNumber: $notes',
        ),
      ];

      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'Payment',
        referenceId: voucherId,
        currencyId: currencyId,
        exchangeRate: exchangeRate,
        description: 'قيد تحويل نقدي داخلي $voucherNumber',
        lines: journalLines,
      );

      return voucherId;
    });
  }
}
```

---

## 4. حل الفخ 13: معالجة فروق أسعار الصرف عند سداد الديون (Realized FX Gain/Loss)

إذا باع التاجر لعميل بمبلغ `1,000 ريال سعودي` في يناير بسعر صرف `140 يمني` (قيمة الدين المسجلة في حساب العميل = `140,000 ريال يمني`).
سدد العميل في مارس الـ `1,000 ريال سعودي`، لكن سعر الصرف ارتفع إلى `145 يمني`.
* المبلغ المستلم فعلياً في الصندوق باليمني = `1,000 * 145 = 145,000 يمني`.
* المبلغ المطلوب شطبه من حساب العميل لإغلاق دينه باليمني = `140,000 يمني`.
* الفارق = `5,000 يمني` زيادة لصالح التاجر.
* **كيف يسجل المحرك الصامت القيد؟**
  * `من حـ/ الصندوق (مدين): 145,000 ريال يمني`
  * `إلى حـ/ حساب العميل (دائن): 140,000 ريال يمني`
  * `إلى حـ/ أرباح فروق أسعار صرف FX_GAIN (دائن): 5,000 ريال يمني`
* بهذا يتزن القيد تماماً، ويغلق دين العميل دون أي عجز، وتظهر الأرباح في قائمة الدخل بنزاهة تامة.

---

## 5. جرد الصندوق اليومي وإقفال الكاشير (End of Day X & Z Reports)

في نهاية كل يوم أو وردية كاشير:
1. **التقرير الاستعلامي السري (X-Report):** يحسب النظام آلياً:
   $$\text{النقد المتوقع} = \text{رصيد الافتتاح} + \text{المبيعات النقدية} + \text{سندات القبض} - \text{سندات الصرف}$$
2. **شاشة جرد الكاشير الميداني:** يُطلب من الكاشير إدخال النقد الفعلي الموجود في الدرج بالعد اليدوي (مثلاً: 125,000 ريال).
3. **تقرير الإقفال النهائي (Z-Report):**
   * إذا كان هناك تطابق: يتم إقفال الصندوق بنجاح.
   * إذا كان هناك عجز (مثلاً المتوقع 130,000 والفعلي 125,000):
     * يُخيّر المدير: تحميل العجز على الكاشير (مدين لحساب الموظف/العهدة)، أو اعتباره عجز صندوق تشغيلي (حـ/ عجز صندوق).
     * ينشأ قيد تسوية تلقائي ليصبح رصيد الدفاتر مطابقاً للنقدية الفعلية لليوم التالي.

---

## 6. معايير القبول والرفض للمرحلة 5 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] إصدار سند قبض من عميل يخفض رصيد دين العميل ويزيد رصيد الصندوق المحدد فوراً.
* [ ] إصدار سند صرف لمصروف (مثلاً إيجار) ينشئ قيداً مديناً لحساب المصروف ودائناً للصندوق دون طلب أي توجيه محاسبي من التاجر.
* [ ] التحويل الداخلي بين صندوق وبنك ينقل السيولة بدقة دون المساس بحسابات الإيرادات أو المصروفات.
* [ ] التحقق الصارم من صحة أطراف القيد وتطابق عملة الأساس في جميع السندات.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** صرف مبلغ من الصندوق إذا كان رصيد الصندوق المسجل أقل من المبلغ (إلا إذا تم تفعيل خيار الصرف بالسالب بصلاحية مدير مع تحذير أحمر).
* ❌ **ممنوع منعاً باتاً:** تعديل أو حذف أي سند مالي بعد طباعته وإغلاق وردية الكاشير. (الإلغاء يتم فقط عبر سند عكسي).
* ❌ **ممنوع منعاً باتاً:** قبول سند قبض بمبلغ صفر أو سالب.

---

## 7. حزمة اختبارات الـ Unit Testing للمرحلة 5 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/modules/treasury/treasury_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/modules/treasury/application/treasury_service.dart';

void main() {
  late AppDatabase db;
  late SilentAccountingEngine accountingEngine;
  late TreasuryService treasuryService;

  late String fiscalYearId;
  late String yerCurrencyId;
  late String cashAccountId;
  late String bankAccountId;
  late String paymentMethodId;
  late String expenseAccountId;
  late String customerPartyId;
  late String customerAccountId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    accountingEngine = SilentAccountingEngine(db);
    treasuryService = TreasuryService(
      db: db,
      accountingEngine: accountingEngine,
    );

    yerCurrencyId = await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'YER',
        nameAr: 'ريال يمني',
        symbol: 'ر.ي',
        isBaseCurrency: const Value(true),
      ),
    );

    fiscalYearId = await db.into(db.fiscalYearsTable).insert(
      FiscalYearsTableCompanion.insert(
        yearName: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );

    cashAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '111',
        accountName: 'صندوق المحل',
        accountType: 'Asset',
        normalBalance: 'Debit',
      ),
    );

    bankAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '112',
        accountName: 'حساب بنك الكريمي',
        accountType: 'Asset',
        normalBalance: 'Debit',
      ),
    );

    expenseAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '521',
        accountName: 'مصاريف إيجار وكهرباء',
        accountType: 'Expense',
        normalBalance: 'Debit',
      ),
    );

    paymentMethodId = await db.into(db.paymentMethodsTable).insert(
      PaymentMethodsTableCompanion.insert(
        name: 'كاش',
        type: 'Cash',
        accountId: cashAccountId,
      ),
    );

    customerAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '1131',
        accountName: 'محمد ناصر (عميل)',
        accountType: 'Asset',
        normalBalance: 'Debit',
      ),
    );

    customerPartyId = await db.into(db.partiesTable).insert(
      PartiesTableCompanion.insert(
        name: 'محمد ناصر',
        partyType: 'Customer',
        accountId: customerAccountId,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات الخزينة وسندات القبض والصرف', () {
    test('سند قبض من عميل يجب أن يزيد الصندوق ويخفض حساب العميل بقيد متزن', () async {
      final voucherId = await treasuryService.createReceiptVoucher(
        fiscalYearId: fiscalYearId,
        paymentMethodId: paymentMethodId,
        cashAccountId: cashAccountId,
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        amount: 25000.0,
        partyId: customerPartyId,
        targetAccountId: null,
        referenceInvoiceId: null,
        notes: 'دفعة حساب',
      );

      expect(voucherId, isNotEmpty);

      // التحقق من القيد
      final entry = await (db.select(db.journalEntriesTable)
            ..where((j) => j.referenceId.equals(voucherId)))
          .getSingle();

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entry.id)))
          .get();

      // مدين صندوق 25,000 ودائن عميل 25,000
      expect(lines.first.baseDebit, 25000.0);
      expect(lines.last.baseCredit, 25000.0);
    });

    test('التحويل المالي بين صندوق وبنك ينقل السيولة بقيد متزن', () async {
      final voucherId = await treasuryService.transferFunds(
        fiscalYearId: fiscalYearId,
        fromCashAccountId: cashAccountId,
        toCashAccountId: bankAccountId,
        paymentMethodId: paymentMethodId,
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        amount: 50000.0,
        notes: 'إيداع إيراد اليوم في بنك الكريمي',
      );

      expect(voucherId, isNotEmpty);

      final entry = await (db.select(db.journalEntriesTable)
            ..where((j) => j.referenceId.equals(voucherId)))
          .getSingle();

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entry.id)))
          .get();

      // مدين بنك 50,000 ودائن صندوق 50,000
      expect(lines.first.baseDebit, 50000.0);
      expect(lines.last.baseCredit, 50000.0);
    });
  });
}
```
