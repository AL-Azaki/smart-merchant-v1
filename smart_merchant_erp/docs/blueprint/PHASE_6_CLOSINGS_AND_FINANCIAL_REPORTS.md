# 📦 PHASE 6: الإقفالات المالية، والتقارير، والأرباح والخسائر
## (Period Closings, Financial Statements, Customer Ledgers & P&L Engine)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء محرك كشوف الحسابات التراكمية اللحظية (Running Balance Customer & Supplier Statement).
2. بناء تقرير **الأرباح والخسائر وقائمة الدخل (P&L / Income Statement)** التلقائي: مجمل الربح، المصاريف، وصافي الربح.
3. بناء تقرير **بطاقة حركة الصنف (Item Movement Ledger)** لمتابعة دقة الجرد والتكلفة.
4. بناء ميزان المراجعة المبسط ومطابقة الأستاذ العام.
5. بناء دورة **الإقفال السنوي وقفل الفترات المالية (Year-End Closing)**: تصفير الإيرادات والمصروفات وترحيل صافي الربح إلى الأرباح المبقاة.
6. حزمة اختبارات Unit Testing للتحقق من صحة التقارير والإقفال.

---

## 2. محرك كشف حساب العميل والمورد التراكمي (Running Balance Statement)

كشف الحساب التراكمي هو أهم شاشة يطلبها التاجر عندما يأتي عميل ليسدد دينه:

```dart
class StatementRow {
  final DateTime date;
  final String referenceNumber;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance; // الرصيد التراكمي بعد هذه الحركة

  StatementRow({
    required this.date,
    required this.referenceNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

class FinancialReportsService {
  final AppDatabase db;
  FinancialReportsService(this.db);

  /// استخراج كشف حساب تراكمي لحظي لأي شريك (عميل أو مورد)
  Future<List<StatementRow>> getPartyStatement({
    required String partyId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final party = await (db.select(db.partiesTable)..where((p) => p.id.equals(partyId))).getSingle();
    final accountId = party.accountId;

    // جلب جميع حركات قيود اليومية المرتبطة بهذا الحساب مرتبة زمنياً
    final query = db.select(db.journalEntryLinesTable).join([
      innerJoin(
        db.journalEntriesTable,
        db.journalEntriesTable.id.equalsExp(db.journalEntryLinesTable.journalEntryId),
      ),
    ])
      ..where(db.journalEntryLinesTable.accountId.equals(accountId));

    if (fromDate != null) {
      query.where(db.journalEntriesTable.entryDate.isBiggerOrEqualValue(fromDate));
    }
    if (toDate != null) {
      query.where(db.journalEntriesTable.entryDate.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([OrderingTerm.asc(db.journalEntriesTable.entryDate)]);

    final rows = await query.get();

    double runningBalance = party.openingBalance; // البدء بالرصيد الافتتاحي
    final statement = <StatementRow>[];

    // إضافة سطر الرصيد الافتتاحي إذا وجد
    if (party.openingBalance > 0) {
      statement.add(
        StatementRow(
          date: party.createdAt,
          referenceNumber: 'OPN-BAL',
          description: 'رصيد افتتاحي سابق',
          debit: party.openingBalanceType == 'Debit' ? party.openingBalance : 0.0,
          credit: party.openingBalanceType == 'Credit' ? party.openingBalance : 0.0,
          runningBalance: runningBalance,
        ),
      );
    }

    for (var row in rows) {
      final line = row.readTable(db.journalEntryLinesTable);
      final entry = row.readTable(db.journalEntriesTable);

      // في حسابات العملاء (طبيعتها مدين): الزيادة بالمدين والنقص بالدائن
      if (party.partyType == 'Customer') {
        runningBalance += (line.baseDebit - line.baseCredit);
      } else {
        // في حسابات الموردين (طبيعتها دائن): الزيادة بالدائن والنقص بالمدين
        runningBalance += (line.baseCredit - line.baseDebit);
      }

      runningBalance = PrecisionMath.roundMoney(runningBalance);

      statement.add(
        StatementRow(
          date: entry.entryDate,
          referenceNumber: entry.entryNumber,
          description: line.description ?? entry.description ?? 'حركة مالية',
          debit: line.baseDebit,
          credit: line.baseCredit,
          runningBalance: runningBalance,
        ),
      );
    }

    return statement;
  }
}
```

---

## 3. محرك قائمة الدخل والأرباح والخسائر (Income Statement / P&L)

قائمة الدخل تحسب ربحية المتجر بدقة من واقع قيود الأستاذ العام:

$$\text{إجمالي المبيعات (Revenue)} - \text{تكلفة البضاعة المباعة (COGS)} = \text{مجمل الربح (Gross Profit)}$$
$$\text{مجمل الربح} - \text{المصاريف التشغيلية (Operating Expenses)} + \text{فروق العملة (FX Gain)} = \text{صافي الربح (Net Profit)}$$

```dart
class ProfitAndLossReport {
  final double totalSalesRevenue;
  final double totalCostOfGoodsSold;
  final double grossProfit;
  final double operatingExpenses;
  final double fxNetGainOrLoss;
  final double netProfit;

  ProfitAndLossReport({
    required this.totalSalesRevenue,
    required this.totalCostOfGoodsSold,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.fxNetGainOrLoss,
    required this.netProfit,
  });
}

extension ProfitAndLossExtension on FinancialReportsService {
  Future<ProfitAndLossReport> getProfitAndLoss({
    required String fiscalYearId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final accounts = await db.select(db.chartOfAccountsTable).get();

    double sumForSystemRole(String role) {
      final acc = accounts.where((a) => a.systemRole == role);
      if (acc.isEmpty) return 0.0;
      final accId = acc.first.id;
      // استعلام مجاميع الأستاذ العام لهذا الحساب
      // ...
      return 0.0;
    }

    // استخراج المجاميع اللحظية من جدول أسطر القيود
    final lines = await (db.select(db.journalEntryLinesTable).join([
      innerJoin(
        db.journalEntriesTable,
        db.journalEntriesTable.id.equalsExp(db.journalEntryLinesTable.journalEntryId),
      ),
    ])
      ..where(db.journalEntriesTable.fiscalYearId.equals(fiscalYearId)))
        .get();

    double sales = 0.0;
    double cogs = 0.0;
    double expenses = 0.0;
    double fxGains = 0.0;
    double fxLosses = 0.0;

    for (var r in lines) {
      final line = r.readTable(db.journalEntryLinesTable);
      final acc = accounts.firstWhere((a) => a.id == line.accountId);

      if (acc.systemRole == 'SALES_REVENUE') {
        sales += (line.baseCredit - line.baseDebit);
      } else if (acc.systemRole == 'COGS') {
        cogs += (line.baseDebit - line.baseCredit);
      } else if (acc.accountType == 'Expense' && acc.systemRole != 'COGS') {
        expenses += (line.baseDebit - line.baseCredit);
      } else if (acc.systemRole == 'FX_GAIN') {
        fxGains += (line.baseCredit - line.baseDebit);
      } else if (acc.systemRole == 'FX_LOSS') {
        fxLosses += (line.baseDebit - line.baseCredit);
      }
    }

    sales = PrecisionMath.roundMoney(sales);
    cogs = PrecisionMath.roundMoney(cogs);
    expenses = PrecisionMath.roundMoney(expenses);
    final gross = PrecisionMath.roundMoney(sales - cogs);
    final fxNet = PrecisionMath.roundMoney(fxGains - fxLosses);
    final net = PrecisionMath.roundMoney(gross - expenses + fxNet);

    return ProfitAndLossReport(
      totalSalesRevenue: sales,
      totalCostOfGoodsSold: cogs,
      grossProfit: gross,
      operatingExpenses: expenses,
      fxNetGainOrLoss: fxNet,
      netProfit: net,
    );
  }
}
```

---

## 4. دورة الإقفال السنوي وقفل الفترات (Year-End Closing Engine)

عندما يقرر التاجر إقفال السنة المالية:
1. يتم حساب **صافي الربح النهائي**.
2. يقوم المحرك الآلي بتوليد **قيد إقفال الأرباح والخسائر (Closing Entry)**:
   * يجعل جميع حسابات الإيرادات مدينة بمجاميعها (لتصبح أرصدتها صفراً للسنة الجديدة).
   * يجعل جميع حسابات المصروفات وتكلفة المبيعات دائنة بمجاميعها (لتصبح أرصدتها صفراً).
   * يوجه الفارق (صافي الربح) إلى حساب حقوق الملكية: **حـ/ الأرباح المبقاة (Retained Earnings)**.
3. يتم قفل السنة المالية في جدول `fiscal_years` (`isClosed = true`).
4. تفتح سنة مالية جديدة بأرصدة افتتاحية للأصول والخصوم فقط (المخزون، الصندوق، العملاء، الموردين).

---

## 5. معايير القبول والرفض للمرحلة 6 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] مطابقة كشف الحساب التراكمي للعميل بنسبة 100% مع سندات قبضه وفواتيره الآجلة.
* [ ] مجمل الربح في قائمة الدخل يساوي دائماً: `المبيعات - تكلفة المبيعات`.
* [ ] عند إقفال السنة المالية، تصبح أرصدة المبيعات والمصاريف صفراً للسنة الجديدة دون المساس بأرصدة المخزن أو الصندوق.
* [ ] منع أي عملية تعديل أو إضافة على أي تاريخ يتبع سنة مالية مقفلة.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** إدخال قيد يدوي يلغي توازن ميزان المراجعة.
* ❌ **ممنوع منعاً باتاً:** فتح سنة مالية مقفلة دون صلاحية "المدير العام الأعلى" مع تسجيل سجل تدقيق أمني (Audit Log).
* ❌ **ممنوع منعاً باتاً:** عرض أرقام أرباح تقريبية تخالف سجلات تكلفة المخزون الفعلية.

---

## 6. حزمة اختبارات الـ Unit Testing للمرحلة 6 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/modules/reports/financial_reports_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/modules/reports/application/financial_reports_service.dart';

void main() {
  late AppDatabase db;
  late SilentAccountingEngine accountingEngine;
  late FinancialReportsService reportsService;

  late String fiscalYearId;
  late String yerCurrencyId;
  late String customerPartyId;
  late String customerAccountId;
  late String salesAccountId;
  late String cashAccountId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    accountingEngine = SilentAccountingEngine(db);
    reportsService = FinancialReportsService(db);

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
        accountName: 'الصندوق',
        accountType: 'Asset',
        normalBalance: 'Debit',
      ),
    );

    salesAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '411',
        accountName: 'المبيعات',
        accountType: 'Revenue',
        normalBalance: 'Credit',
        systemRole: const Value('SALES_REVENUE'),
      ),
    );

    customerAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '1131',
        accountName: 'عميل آجل',
        accountType: 'Asset',
        normalBalance: 'Debit',
      ),
    );

    customerPartyId = await db.into(db.partiesTable).insert(
      PartiesTableCompanion.insert(
        name: 'أحمد علي',
        partyType: 'Customer',
        accountId: customerAccountId,
        openingBalance: const Value(10000.0),
        openingBalanceType: const Value('Debit'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات كشف الحساب التراكمي', () {
    test('كشف حساب العميل يجب أن يحسب الرصيد التراكمي بدقة بعد فواتير البيع وسندات القبض', () async {
      // 1. بيع آجل بقيمة 30,000 ريال (يزيد دين العميل)
      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-10',
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        description: 'فاتورة بيع آجلة',
        lines: [
          JournalLineDraft(accountId: customerAccountId, debit: 30000.0),
          JournalLineDraft(accountId: salesAccountId, credit: 30000.0),
        ],
      );

      // 2. سند قبض بقيمة 15,000 ريال (يخفض دين العميل)
      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'Payment',
        referenceId: 'PAY-10',
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        description: 'سداد دفعة نقداً',
        lines: [
          JournalLineDraft(accountId: cashAccountId, debit: 15000.0),
          JournalLineDraft(accountId: customerAccountId, credit: 15000.0),
        ],
      );

      final statement = await reportsService.getPartyStatement(partyId: customerPartyId);

      // المتوقع:
      // سطر 1 (افتتاحي): رصيد 10,000
      // سطر 2 (فاتورة): مدين 30,000 -> رصيد تراكمي 40,000
      // سطر 3 (سند قبض): دائن 15,000 -> رصيد تراكمي نهائي 25,000
      expect(statement.length, 3);
      expect(statement[0].runningBalance, 10000.0);
      expect(statement[1].runningBalance, 40000.0);
      expect(statement[2].runningBalance, 25000.0);
    });
  });
}
```
