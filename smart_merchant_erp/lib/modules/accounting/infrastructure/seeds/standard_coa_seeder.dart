import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/storage/app_database.dart';

/// StandardCoaSeeder ensures that every merchant store starts with a complete,
/// legally sound, pre-seeded chart of accounts, base currencies, and default payment methods.
/// 
/// It checks if accounts are already seeded to prevent duplicate inserts on restart.
class StandardCoaSeeder {
  final AppDatabase db;

  StandardCoaSeeder(this.db);

  Future<void> seedAll() async {
    await seedCurrencies();
    await seedFiscalYear();
    await seedChartOfAccounts();
    await seedDefaultPaymentMethods();
  }

  Future<void> seedCurrencies() async {
    final existing = await db.select(db.currenciesTable).get();
    if (existing.isNotEmpty) return;

    await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'YER',
        nameAr: 'ريال يمني',
        symbol: 'ر.ي',
        decimalPlaces: const Value(2),
        exchangeRate: const Value(1.0),
        isBaseCurrency: const Value(true),
      ),
    );

    await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'SAR',
        nameAr: 'ريال سعودي',
        symbol: 'ر.س',
        decimalPlaces: const Value(2),
        exchangeRate: const Value(140.0),
        isBaseCurrency: const Value(false),
      ),
    );

    await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'USD',
        nameAr: 'دولار أمريكي',
        symbol: '\$',
        decimalPlaces: const Value(2),
        exchangeRate: const Value(530.0),
        isBaseCurrency: const Value(false),
      ),
    );
  }

  Future<void> seedFiscalYear() async {
    final existing = await db.select(db.fiscalYearsTable).get();
    if (existing.isNotEmpty) return;

    final currentYear = DateTime.now().year;
    await db.into(db.fiscalYearsTable).insert(
      FiscalYearsTableCompanion.insert(
        yearName: currentYear.toString(),
        startDate: DateTime(currentYear, 1, 1),
        endDate: DateTime(currentYear, 12, 31, 23, 59, 59),
        isClosed: const Value(false),
      ),
    );
  }

  Future<void> seedChartOfAccounts() async {
    final existing = await db.select(db.chartOfAccountsTable).get();
    if (existing.isNotEmpty) return;

    // Structure definition: code, name, type, normalBalance, allowPosting, systemRole, parentCode
    final accounts = [
      // 1. Assets
      _AccountSeed('1', 'الأصول', 'Asset', 'Debit', false, null, null),
      _AccountSeed('11', 'الأصول المتداولة', 'Asset', 'Debit', false, null, '1'),
      _AccountSeed('111', 'الصندوق الرئيسي (الخزينة)', 'Asset', 'Debit', true, 'CASH_DRAWER_DEFAULT', '11'),
      _AccountSeed('112', 'حساب البنك / شبكة', 'Asset', 'Debit', true, 'BANK_DEFAULT', '11'),
      _AccountSeed('113', 'المدينون (العملاء)', 'Asset', 'Debit', false, 'ACCOUNTS_RECEIVABLE', '11'),
      _AccountSeed('114', 'مخزون البضاعة', 'Asset', 'Debit', true, 'INVENTORY_ASSET', '11'),

      // 2. Liabilities
      _AccountSeed('2', 'الخصوم والالتزامات', 'Liability', 'Credit', false, null, null),
      _AccountSeed('21', 'الخصوم المتداولة', 'Liability', 'Credit', false, null, '2'),
      _AccountSeed('211', 'الدائنون (الموردون)', 'Liability', 'Credit', false, 'ACCOUNTS_PAYABLE', '21'),
      _AccountSeed('212', 'أمانات وضريبة القيمة المضافة', 'Liability', 'Credit', true, 'VAT_PAYABLE', '21'),

      // 3. Equity
      _AccountSeed('3', 'حقوق الملكية', 'Equity', 'Credit', false, null, null),
      _AccountSeed('31', 'رأس المال', 'Equity', 'Credit', true, 'CAPITAL', '3'),
      _AccountSeed('32', 'الأرباح والخسائر المبقاة', 'Equity', 'Credit', true, 'RETAINED_EARNINGS', '3'),
      _AccountSeed('33', 'جاري المالك (مسحوبات شخصية)', 'Equity', 'Debit', true, 'OWNER_DRAWINGS', '3'),

      // 4. Revenue
      _AccountSeed('4', 'الإيرادات', 'Revenue', 'Credit', false, null, null),
      _AccountSeed('41', 'إيرادات المبيعات', 'Revenue', 'Credit', true, 'SALES_REVENUE', '4'),
      _AccountSeed('42', 'أرباح فروق أسعار الصرف', 'Revenue', 'Credit', true, 'FX_GAIN', '4'),
      _AccountSeed('43', 'خصم مكتسب (من الموردين)', 'Revenue', 'Credit', true, 'DISCOUNT_EARNED', '4'),

      // 5. Expenses
      _AccountSeed('5', 'المصروفات', 'Expense', 'Debit', false, null, null),
      _AccountSeed('51', 'تكلفة البضاعة المباعة', 'Expense', 'Debit', true, 'COGS', '5'),
      _AccountSeed('52', 'مصاريف عامة وتشغيلية', 'Expense', 'Debit', true, 'OPERATING_EXPENSES', '5'),
      _AccountSeed('53', 'خصم مسموح به (للعملاء)', 'Expense', 'Debit', true, 'DISCOUNT_ALLOWED', '5'),
      _AccountSeed('54', 'خسائر فروق أسعار الصرف', 'Expense', 'Debit', true, 'FX_LOSS', '5'),
      _AccountSeed('55', 'تالف ومفقودات مخزون', 'Expense', 'Debit', true, 'STOCK_DAMAGE_EXPENSE', '5'),
    ];

    final insertedIds = <String, String>{};

    for (var acc in accounts) {
      String? parentId;
      if (acc.parentCode != null) {
        parentId = insertedIds[acc.parentCode];
      }

      final accountId = const Uuid().v4();
      await db.into(db.chartOfAccountsTable).insert(
        ChartOfAccountsTableCompanion.insert(
          id: Value(accountId),
          accountCode: acc.code,
          accountName: acc.name,
          accountType: acc.type,
          normalBalance: acc.normalBalance,
          allowPosting: Value(acc.allowPosting),
          isSystem: const Value(true),
          systemRole: Value(acc.systemRole),
          parentId: Value(parentId),
        ),
      );

      insertedIds[acc.code] = accountId;
    }
  }

  Future<void> seedDefaultPaymentMethods() async {
    final existing = await db.select(db.paymentMethodsTable).get();
    if (existing.isNotEmpty) return;

    final accounts = await db.select(db.chartOfAccountsTable).get();
    final cashAccount = accounts.firstWhere((a) => a.systemRole == 'CASH_DRAWER_DEFAULT');
    final bankAccount = accounts.firstWhere((a) => a.systemRole == 'BANK_DEFAULT');

    await db.into(db.paymentMethodsTable).insert(
      PaymentMethodsTableCompanion.insert(
        name: 'نقد كاش',
        type: 'Cash',
        accountId: cashAccount.id,
        isDefault: const Value(true),
      ),
    );

    await db.into(db.paymentMethodsTable).insert(
      PaymentMethodsTableCompanion.insert(
        name: 'بنك / شبكة إلكترونية',
        type: 'Bank',
        accountId: bankAccount.id,
        isDefault: const Value(false),
      ),
    );
  }
}

class _AccountSeed {
  final String code;
  final String name;
  final String type;
  final String normalBalance;
  final bool allowPosting;
  final String? systemRole;
  final String? parentCode;

  _AccountSeed(
    this.code,
    this.name,
    this.type,
    this.normalBalance,
    this.allowPosting,
    this.systemRole,
    this.parentCode,
  );
}
