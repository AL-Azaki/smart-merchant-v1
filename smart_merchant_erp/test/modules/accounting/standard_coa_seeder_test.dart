import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/seeds/standard_coa_seeder.dart';

void main() {
  late AppDatabase db;
  late StandardCoaSeeder seeder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    seeder = StandardCoaSeeder(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('StandardCoaSeeder Master Seed Tests', () {
    test('يجب زراعة شجرة الحسابات والعملات وطرق الدفع بنجاح في المرة الأولى', () async {
      await seeder.seedAll();

      // 1. التحقق من العملات
      final currencies = await db.select(db.currenciesTable).get();
      expect(currencies.length, equals(3));
      final baseCurrency = currencies.firstWhere((c) => c.isBaseCurrency);
      expect(baseCurrency.code, equals('YER'));

      // 2. التحقق من السنة المالية
      final fiscalYears = await db.select(db.fiscalYearsTable).get();
      expect(fiscalYears.length, equals(1));
      expect(fiscalYears.first.isClosed, isFalse);

      // 3. التحقق من شجرة الحسابات (24 حساباً قياسياً)
      final accounts = await db.select(db.chartOfAccountsTable).get();
      expect(accounts.length, equals(24));

      // التحقق من وجود الحسابات النظامية المحورية
      final cashAccount = accounts.firstWhere((a) => a.systemRole == 'CASH_DRAWER_DEFAULT');
      expect(cashAccount.accountCode, equals('111'));
      expect(cashAccount.accountType, equals('Asset'));
      expect(cashAccount.allowPosting, isTrue);

      final salesAccount = accounts.firstWhere((a) => a.systemRole == 'SALES_REVENUE');
      expect(salesAccount.accountCode, equals('41'));
      expect(salesAccount.normalBalance, equals('Credit'));

      final cogsAccount = accounts.firstWhere((a) => a.systemRole == 'COGS');
      expect(cogsAccount.accountCode, equals('51'));

      final inventoryAccount = accounts.firstWhere((a) => a.systemRole == 'INVENTORY_ASSET');
      expect(inventoryAccount.accountCode, equals('114'));

      // 4. التحقق من طرق الدفع الافتراضية
      final paymentMethods = await db.select(db.paymentMethodsTable).get();
      expect(paymentMethods.length, equals(2));
      final defaultCash = paymentMethods.firstWhere((m) => m.isDefault);
      expect(defaultCash.type, equals('Cash'));
      expect(defaultCash.accountId, equals(cashAccount.id));
    });

    test('إعادة تشغيل seeder.seedAll() لا يجب أن تكرر السجلات (Idempotency Test)', () async {
      // تشغيل مرتين متتاليتين
      await seeder.seedAll();
      await seeder.seedAll();

      final currencies = await db.select(db.currenciesTable).get();
      expect(currencies.length, equals(3)); // لم تتضاعف إلى 6

      final accounts = await db.select(db.chartOfAccountsTable).get();
      expect(accounts.length, equals(24)); // لم تتضاعف إلى 48
    });
  });
}
