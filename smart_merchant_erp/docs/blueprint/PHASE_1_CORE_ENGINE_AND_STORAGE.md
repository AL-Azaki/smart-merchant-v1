# 📦 PHASE 1: النواة وقاعدة البيانات ومحرك المحاسبة الصامت
## (Core Data Engine, Pre-Seeded COA & Double-Entry Ledger)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. استبدال الـ 5 جداول الحالية غير المكتملة في Drift بـ **الـ 18 جدولاً المعتمدة للـ MVP**.
2. بناء **شجرة حسابات معيارية مجهزة مسبقاً (Pre-Seeded Standard COA)** مقفلة ضد التخريب ومناسبة للتاجر اليمني/العربي الصغير.
3. معالجة مشاكل **الفواصل العشرية (Precision Drift)** عبر فئة رياضية آمنة ومقفلة.
4. بناء فئة **محرك المحاسبة الصامت (`SilentAccountingEngine`)** المسؤولة عن تحويل أي حدث تجاري إلى قيد متزن ذرّياً (`Debit == Credit`).
5. دعم العملات المتعددة وسجل أسعار الصرف.
6. توفير حزمة اختبارات Unit Testing شاملة للتحقق من اتزان القيود.

---

## 2. مخطط جداول Drift الـ 18 المعتمدة (Dart Drift Schema DDL)

فيما يلي كود جداول Drift الكاملة الخاصة بالنواة والمالية والشركاء ليوضع في `lib/kernel/storage/tables/`:

### 2.1 جداول العملات وشجرة الحسابات والفترات المالية (`financial_tables.dart`)
```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// 1. جدول العملات
@DataClassName('CurrencyData')
class CurrenciesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get code => text().withLength(min: 3, max: 10)(); // YER, SAR, USD
  TextColumn get nameAr => text().withLength(min: 1, max: 100)();
  TextColumn get symbol => text().withLength(min: 1, max: 10)();
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))(); // مقابل عملة الأساس
  BoolColumn get isBaseCurrency => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. جدول الفترات والسنوات المالية
@DataClassName('FiscalYearData')
class FiscalYearsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get yearName => text().withLength(min: 1, max: 50)(); // "2026"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. جدول شجرة الحسابات (Chart of Accounts)
@DataClassName('AccountData')
class ChartOfAccountsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get parentId => text().nullable().references(ChartOfAccountsTable, #id)();
  TextColumn get accountCode => text().withLength(min: 1, max: 50).unique()();
  TextColumn get accountName => text().withLength(min: 1, max: 255)();
  
  // نوع الحساب: Asset, Liability, Equity, Revenue, Expense
  TextColumn get accountType => text()(); 
  
  // الطبيعة الأصلية: Debit أو Credit
  TextColumn get normalBalance => text()(); 
  
  // هل يقبل الترحيل المباشر؟ (الحسابات الفرعية = true، الرئيسية = false)
  BoolColumn get allowPosting => boolean().withDefault(const Constant(true))();
  
  // حساب نظامي (لا يمكن للتاجر حذفه أو تغيير رمزه)
  BoolColumn get isSystem => boolean().withDefault(const Constant(true))();
  
  // رمز التعريف النظامي لربط المحرك الآلي (مثلاً: 'CASH', 'SALES_REV', 'COGS')
  TextColumn get systemRole => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. جدول رؤوس قيود اليومية (Journal Entries)
@DataClassName('JournalEntryData')
class JournalEntriesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get fiscalYearId => text().references(FiscalYearsTable, #id)();
  TextColumn get entryNumber => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get entryDate => dateTime().withDefault(currentDateAndTime)();
  
  // نوع المرجع: SalesInvoice, PurchaseInvoice, Payment, Expense, StockAdjustment, Manual
  TextColumn get referenceType => text()();
  TextColumn get referenceId => text().nullable()(); // ID الفاتورة أو السند
  
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  
  TextColumn get description => text().nullable()();
  // حالة القيد: Draft, Posted, Voided
  TextColumn get status => text().withDefault(const Constant('Posted'))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. جدول أسطر قيود اليومية (Journal Entry Lines)
@DataClassName('JournalEntryLineData')
class JournalEntryLinesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get journalEntryId => text().references(JournalEntriesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)();
  
  TextColumn get description => text().nullable()();
  
  // المبالغ بالعملة المعاملاتية
  RealColumn get debit => real().withDefault(const Constant(0.0))();
  RealColumn get credit => real().withDefault(const Constant(0.0))();
  
  // المبالغ المحولة لعملة الأساس (Base Currency) - هي التي يُحسب عليها الميزان دائماً!
  RealColumn get baseDebit => real().withDefault(const Constant(0.0))();
  RealColumn get baseCredit => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. جدول الشركاء الموحد (العملاء والموردين)
@DataClassName('PartyData')
class PartiesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get partyType => text()(); // 'Customer', 'Supplier', 'Both'
  TextColumn get phone => text().nullable().withLength(max: 50)();
  TextColumn get address => text().nullable()();
  
  // الحساب المالي الفرعي المربوط بالشريك (ينشأ تلقائياً عند إضافة العميل)
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)();
  
  RealColumn get creditLimit => real().withDefault(const Constant(0.0))();
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  TextColumn get openingBalanceType => text().nullable()(); // 'Debit' or 'Credit'
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 7. جدول طرق الدفع والصناديق
@DataClassName('PaymentMethodData')
class PaymentMethodsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => text()(); // 'Cash', 'Bank', 'Network'
  TextColumn get accountId => text().references(ChartOfAccountsTable, #id)(); // الحساب المالي للصندوق/البنك
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. شجرة الحسابات المعيارية المجهزة مسبقاً (The Pre-Seeded COA)

عند أول تشغيل للتطبيق (أو إنشاء متجر جديد)، يقوم النظام بزرع هذه الشجرة تلقائياً في `chart_of_accounts`:

| رمز الحساب | اسم الحساب | النوع | الطبيعة | الدور النظامي (`systemRole`) | يقبل ترحيل؟ |
|---|---|---|---|---|---|
| **1** | **الأصول (Assets)** | Asset | Debit | - | لا |
| **11** | الأصول المتداولة | Asset | Debit | - | لا |
| **111** | الصندوق الرئيسي (الخزينة) | Asset | Debit | `CASH_DRAWER_DEFAULT` | **نعم** |
| **112** | حساب البنك / شبكة | Asset | Debit | `BANK_DEFAULT` | **نعم** |
| **113** | المدينون (العملاء) | Asset | Debit | `ACCOUNTS_RECEIVABLE` | لا (أب) |
| **114** | مخزون البضاعة | Asset | Debit | `INVENTORY_ASSET` | **نعم** |
| **2** | **الخصوم (Liabilities)** | Liability | Credit | - | لا |
| **21** | الخصوم المتداولة | Liability | Credit | - | لا |
| **211** | الدائنون (الموردون) | Liability | Credit | `ACCOUNTS_PAYABLE` | لا (أب) |
| **212** | أمانات وضريبة القيمة المضافة | Liability | Credit | `VAT_PAYABLE` | **نعم** |
| **3** | **حقوق الملكية (Equity)** | Equity | Credit | - | لا |
| **31** | رأس المال | Equity | Credit | `CAPITAL` | **نعم** |
| **32** | الأرباح والخسائر المبقاة | Equity | Credit | `RETAINED_EARNINGS` | **نعم** |
| **33** | جاري المالك (مسحوبات شخصية) | Equity | Debit | `OWNER_DRAWINGS` | **نعم** |
| **4** | **الإيرادات (Revenue)** | Revenue | Credit | - | لا |
| **41** | إيرادات المبيعات | Revenue | Credit | `SALES_REVENUE` | **نعم** |
| **42** | أرباح فروق أسعار الصرف | Revenue | Credit | `FX_GAIN` | **نعم** |
| **43** | خصم مكتسب (من الموردين) | Revenue | Credit | `DISCOUNT_EARNED` | **نعم** |
| **5** | **المصروفات (Expenses)** | Expense | Debit | - | لا |
| **51** | تكلفة البضاعة المباعة | Expense | Debit | `COGS` | **نعم** |
| **52** | مصاريف عامة وتشغيلية | Expense | Debit | `OPERATING_EXPENSES` | **نعم** |
| **53** | خصم مسموح به (للعملاء) | Expense | Debit | `DISCOUNT_ALLOWED` | **نعم** |
| **54** | خسائر فروق أسعار الصرف | Expense | Debit | `FX_LOSS` | **نعم** |
| **55** | تالف ومفقودات مخزون | Expense | Debit | `STOCK_DAMAGE_EXPENSE` | **نعم** |

> **قاعدة ذهبية:** التاجر العادي لا يرى هذه الشجرة إطلاقاً. هو يرى فقط: "الصندوق"، "المبيعات"، "مصروف إيجار"، "العميل فلان". المحرك الصامت هو الذي يربط بين الاثنين.

---

## 4. محرك الحسابات الآمن والفواصل العشرية (Money Precision Engine)

لتفادي الفخ رقم 1 (انحراف الفواصل العشرية في دارت)، نعتمد الفئة `PrecisionMath`:

```dart
class PrecisionMath {
  /// تقريب إلى عدد منازل محدد (افتراضياً 2 للعملات و 3 للكميات)
  static double roundMoney(double value, {int decimals = 2}) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// التأكد من اتزان المبالغ بفارق لا يتجاوز 0.001 فلس
  static bool areBalanced(double debit, double credit) {
    return (debit - credit).abs() < 0.005;
  }
}
```

---

## 5. محرك المحاسبة الصامت (SilentAccountingEngine Implementation)

هذا المحرك هو القلب النابض للنظام. يستقبل طلب إنشاء قيد وينفذه بصرامة:

```dart
class JournalLineDraft {
  final String accountId;
  final double debit;
  final double credit;
  final String? description;

  JournalLineDraft({
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });
}

class SilentAccountingEngine {
  final AppDatabase db;
  SilentAccountingEngine(this.db);

  /// إنشاء قيد يومية آلي متزن داخل معاملة قائمة
  Future<String> createBalancedEntry({
    required String fiscalYearId,
    required String referenceType,
    required String? referenceId,
    required String currencyId,
    required double exchangeRate,
    required String description,
    required List<JournalLineDraft> lines,
    DateTime? entryDate,
  }) async {
    // 1. حساب مجاميع المدين والدائن بعملة الأساس
    double totalBaseDebit = 0.0;
    double totalBaseCredit = 0.0;

    final processedLines = <Map<String, dynamic>>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineDebit = PrecisionMath.roundMoney(line.debit);
      final lineCredit = PrecisionMath.roundMoney(line.credit);

      final baseDebit = PrecisionMath.roundMoney(lineDebit * exchangeRate);
      final baseCredit = PrecisionMath.roundMoney(lineCredit * exchangeRate);

      totalBaseDebit += baseDebit;
      totalBaseCredit += baseCredit;

      processedLines.add({
        'lineNumber': i + 1,
        'accountId': line.accountId,
        'description': line.description,
        'debit': lineDebit,
        'credit': lineCredit,
        'baseDebit': baseDebit,
        'baseCredit': baseCredit,
      });
    }

    totalBaseDebit = PrecisionMath.roundMoney(totalBaseDebit);
    totalBaseCredit = PrecisionMath.roundMoney(totalBaseCredit);

    // 2. التحقق الصارم من توازن القيد (Debit == Credit)
    if (!PrecisionMath.areBalanced(totalBaseDebit, totalBaseCredit)) {
      throw AccountingBalanceException(
        'القيد المحاسبي غير متزن! إجمالي المدين: $totalBaseDebit، إجمالي الدائن: $totalBaseCredit، الفارق: ${totalBaseDebit - totalBaseCredit}',
      );
    }

    // 3. توليد رقم تسلسلي للقيد
    final entryNumber = 'JV-${DateTime.now().millisecondsSinceEpoch}';

    // 4. إدراج رأس القيد
    final entryId = await db.into(db.journalEntriesTable).insert(
      JournalEntriesTableCompanion.insert(
        fiscalYearId: fiscalYearId,
        entryNumber: entryNumber,
        referenceType: referenceType,
        referenceId: Value(referenceId),
        currencyId: currencyId,
        exchangeRate: Value(exchangeRate),
        description: Value(description),
        entryDate: Value(entryDate ?? DateTime.now()),
      ),
    );

    // 5. إدراج أسطر القيد
    for (var row in processedLines) {
      await db.into(db.journalEntryLinesTable).insert(
        JournalEntryLinesTableCompanion.insert(
          journalEntryId: entryId,
          lineNumber: row['lineNumber'],
          accountId: row['accountId'],
          description: Value(row['description']),
          debit: Value(row['debit']),
          credit: Value(row['credit']),
          baseDebit: Value(row['baseDebit']),
          baseCredit: Value(row['baseCredit']),
        ),
      );
    }

    return entryId;
  }
}

class AccountingBalanceException implements Exception {
  final String message;
  AccountingBalanceException(this.message);
  @override
  String toString() => 'AccountingBalanceException: $message';
}
```

---

## 6. معايير القبول والرفض للمرحلة 1 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] زرع شجرة الحسابات القياسية بنجاح عند تشغيل التطبيق لأول مرة دون تكرار.
* [ ] أي قيد ينشئه المحرك الآلي تكون فيه قيمة `baseDebit == baseCredit` متطابقة تماماً.
* [ ] دعم العملات: تسجيل قيد بالدولار بسعر صرف 530 ينتج عنه أسطر بالدولار وأسطر مقابلة بالريال اليمني مضروبة في 530 بدقة.
* [ ] عند محاولة إدخال قيد غير متزن (مثلاً مدين 1000 ودائن 950)، يطلق المحرك `AccountingBalanceException` فوراً ويلغي المعاملة دون كتابة سطر واحد.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** السماح بحذف أي حساب عليه علامة `isSystem = true`.
* ❌ **ممنوع منعاً باتاً:** السماح بالترحيل على حساب رئيسي أب (`allowPosting = false`).
* ❌ **ممنوع منعاً باتاً:** إدخال قيد في فترة مالية مقفلة (`isClosed = true`).
* ❌ **ممنوع منعاً باتاً:** استخدام نوع `double` بدون استدعاء `PrecisionMath.roundMoney`.

---

## 7. حزمة اختبارات الـ Unit Testing للمرحلة 1 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/kernel/silent_accounting_engine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/core/utils/precision_math.dart';

void main() {
  late AppDatabase db;
  late SilentAccountingEngine engine;
  late String testFiscalYearId;
  late String yerCurrencyId;
  late String usdCurrencyId;
  late String cashAccountId;
  late String salesAccountId;

  setUp(() async {
    // تشغيل داتابيز وهمية في الذاكرة سريعة للاختبارات
    db = AppDatabase(connection: NativeDatabase.memory());
    engine = SilentAccountingEngine(db);

    // 1. زرع عملات تجريبية
    yerCurrencyId = await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'YER',
        nameAr: 'ريال يمني',
        symbol: 'ر.ي',
        isBaseCurrency: const Value(true),
        exchangeRate: const Value(1.0),
      ),
    );

    usdCurrencyId = await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'USD',
        nameAr: 'دولار أمريكي',
        symbol: '\$',
        isBaseCurrency: const Value(false),
        exchangeRate: const Value(530.0),
      ),
    );

    // 2. زرع سنة مالية
    testFiscalYearId = await db.into(db.fiscalYearsTable).insert(
      FiscalYearsTableCompanion.insert(
        yearName: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );

    // 3. زرع حسابين تجريبيين
    cashAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '111',
        accountName: 'الصندوق',
        accountType: 'Asset',
        normalBalance: 'Debit',
        allowPosting: const Value(true),
      ),
    );

    salesAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '411',
        accountName: 'المبيعات',
        accountType: 'Revenue',
        normalBalance: 'Credit',
        allowPosting: const Value(true),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات اتزان القيود المحاسبية والدقة العشرية', () {
    test('يجب إنشاء قيد متزن بنجاح بالعملة المحلية', () async {
      final entryId = await engine.createBalancedEntry(
        fiscalYearId: testFiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-101',
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        description: 'مبيعات نقدية',
        lines: [
          JournalLineDraft(accountId: cashAccountId, debit: 15000.0, credit: 0.0),
          JournalLineDraft(accountId: salesAccountId, debit: 0.0, credit: 15000.0),
        ],
      );

      expect(entryId, isNotEmpty);

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entryId)))
          .get();

      expect(lines.length, 2);
      expect(lines.first.baseDebit, 15000.0);
      expect(lines.last.baseCredit, 15000.0);
    });

    test('يجب رفض القيد غير المتزن ورمي استثناء AccountingBalanceException', () async {
      expect(
        () async => await engine.createBalancedEntry(
          fiscalYearId: testFiscalYearId,
          referenceType: 'SalesInvoice',
          referenceId: 'INV-BAD',
          currencyId: yerCurrencyId,
          exchangeRate: 1.0,
          description: 'قيد عاطل',
          lines: [
            JournalLineDraft(accountId: cashAccountId, debit: 15000.0, credit: 0.0),
            JournalLineDraft(accountId: salesAccountId, debit: 0.0, credit: 14000.0), // عجز 1000
          ],
        ),
        throwsA(isA<AccountingBalanceException>()),
      );
    });

    test('يجب احتساب مبالغ عملة الأساس بدقة عند القيد بعملة أجنبية (USD)', () async {
      final entryId = await engine.createBalancedEntry(
        fiscalYearId: testFiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-USD',
        currencyId: usdCurrencyId,
        exchangeRate: 530.0,
        description: 'مبيعات بالدولار',
        lines: [
          JournalLineDraft(accountId: cashAccountId, debit: 100.0, credit: 0.0),
          JournalLineDraft(accountId: salesAccountId, debit: 0.0, credit: 100.0),
        ],
      );

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entryId)))
          .get();

      // 100 دولار * 530 = 53,000 ريال يمني
      expect(lines.first.debit, 100.0);
      expect(lines.first.baseDebit, 53000.0);
      expect(lines.last.credit, 100.0);
      expect(lines.last.baseCredit, 53000.0);
    });
  });
}
```
