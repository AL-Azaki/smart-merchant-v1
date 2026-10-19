import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Single cash/bank account movement line.
class CashFlowAccountItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String category;
  final double openingBalance;
  final double totalInflow;
  final double totalOutflow;
  final double closingBalance;

  const CashFlowAccountItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.category,
    required this.openingBalance,
    required this.totalInflow,
    required this.totalOutflow,
    required this.closingBalance,
  });
}

/// Activity item under Operating, Investing, or Financing cash flows.
class CashFlowActivityItem {
  final String title;
  final double amount;
  final bool isInflow;

  const CashFlowActivityItem({
    required this.title,
    required this.amount,
    required this.isInflow,
  });
}

/// Official Cash Flow Statement (قائمة التدفق المالي / النقدي).
class CashFlowReport {
  final DateTime? startDate;
  final DateTime? endDate;

  // 1. الأرصدة الافتتاحية والختامية
  final double openingCashBalance;
  final double closingCashBalance;
  final double netChangeInCash;

  // 2. التدفقات النقدية التشغيلية
  final List<CashFlowActivityItem> operatingActivities;
  final double netOperatingCashFlow;

  // 3. التدفقات النقدية الاستثمارية
  final List<CashFlowActivityItem> investingActivities;
  final double netInvestingCashFlow;

  // 4. التدفقات النقدية التمويلية
  final List<CashFlowActivityItem> financingActivities;
  final double netFinancingCashFlow;

  // 5. تفاصيل حسابات النقدية والبنوك
  final List<CashFlowAccountItem> cashAccounts;

  const CashFlowReport({
    this.startDate,
    this.endDate,
    required this.openingCashBalance,
    required this.closingCashBalance,
    required this.netChangeInCash,
    required this.operatingActivities,
    required this.netOperatingCashFlow,
    required this.investingActivities,
    required this.netInvestingCashFlow,
    required this.financingActivities,
    required this.netFinancingCashFlow,
    required this.cashAccounts,
  });
}

/// Domain engine compiling official Cash Flow Statement (قائمة التدفقات النقدية).
class CashFlowService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  CashFlowService(this._accountingRepository, this._context);

  Future<CashFlowReport> generateCashFlow({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;

    // 1. Identify all Cash and Bank accounts
    final allAccounts = await _accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, isActive: true),
    );
    final accountMap = {for (final a in allAccounts) a.id: a};

    final cashAccountsList = allAccounts.where((a) {
      if (!a.allowPosting) return false;
      final cat = a.accountCategory?.toLowerCase() ?? '';
      final code = a.accountCode;
      final name = a.accountName;
      return a.accountTypeId == 1 &&
          (cat == 'cash' ||
              cat == 'bank' ||
              cat == 'digitalwallet' ||
              code.startsWith('111') ||
              name.contains('صندوق') ||
              name.contains('بنك') ||
              name.contains('خزينة') ||
              name.contains('نقد'));
    }).toList();

    final cashAccountIds = cashAccountsList.map((a) => a.id).toSet();

    // 2. Calculate Opening Balances (before startDate)
    final Map<String, double> openingBalances = {};
    double totalOpeningCash = 0.0;

    if (startDate != null) {
      final priorLines = await _accountingRepository.getJournalLinesForReporting(
        businessId: businessId,
        endDate: startDate.subtract(const Duration(milliseconds: 1)),
        status: 'Posted',
      );

      for (final item in priorLines) {
        final accId = item.line.chartOfAccountId;
        if (cashAccountIds.contains(accId)) {
          final amt = item.line.baseAmount;
          if (item.line.type == 'Debit') {
            openingBalances[accId] = (openingBalances[accId] ?? 0.0) + amt;
          } else {
            openingBalances[accId] = (openingBalances[accId] ?? 0.0) - amt;
          }
        }
      }

      for (final accId in cashAccountIds) {
        totalOpeningCash += openingBalances[accId] ?? 0.0;
      }
    }

    // 3. Fetch period journal lines
    final periodLines = await _accountingRepository.getJournalLinesForReporting(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      status: 'Posted',
    );

    // Group journal lines by journal entry ID
    final Map<String, List<JournalLineWithEntry>> entryGroups = {};
    for (final line in periodLines) {
      entryGroups.putIfAbsent(line.line.journalEntryId, () => []).add(line);
    }

    final Map<String, double> inflowsMap = {};
    final Map<String, double> outflowsMap = {};

    double operatingInflows = 0.0;
    double operatingOutflows = 0.0;
    double investingInflows = 0.0;
    double investingOutflows = 0.0;
    double financingInflows = 0.0;
    double financingOutflows = 0.0;

    // Track detailed breakdown
    double customerCollections = 0.0;
    double directSalesCash = 0.0;
    double supplierPayments = 0.0;
    double operatingExpensesCash = 0.0;
    double otherOperatingCash = 0.0;

    double fixedAssetsPurchased = 0.0;
    double fixedAssetsSold = 0.0;

    double capitalInflow = 0.0;
    double ownerDrawings = 0.0;
    double loansMovement = 0.0;

    for (final entryLines in entryGroups.values) {
      // Find cash lines in this entry
      final cashLinesInEntry = entryLines.where((l) => cashAccountIds.contains(l.line.chartOfAccountId)).toList();
      if (cashLinesInEntry.isEmpty) continue;

      // Find non-cash counter lines
      final counterLines = entryLines.where((l) => !cashAccountIds.contains(l.line.chartOfAccountId)).toList();

      for (final cLine in cashLinesInEntry) {
        final accId = cLine.line.chartOfAccountId;
        final isDebit = cLine.line.type == 'Debit';
        final amount = cLine.line.baseAmount;

        if (isDebit) {
          inflowsMap[accId] = (inflowsMap[accId] ?? 0.0) + amount;
        } else {
          outflowsMap[accId] = (outflowsMap[accId] ?? 0.0) + amount;
        }

        // Analyze counter lines to classify activity
        if (counterLines.isNotEmpty) {
          // Weight per counter line
          final totalCounterAmt = counterLines.fold<double>(0.0, (sum, l) => sum + l.line.baseAmount);
          for (final counter in counterLines) {
            final share = totalCounterAmt > 0 ? (counter.line.baseAmount / totalCounterAmt) * amount : amount;
            final counterAcc = accountMap[counter.line.chartOfAccountId];
            final typeId = counterAcc?.accountTypeId ?? 0;
            final code = counterAcc?.accountCode ?? '';

            if (isDebit) {
              // Cash INFLOW
              if (typeId == 4) {
                // Direct Cash Revenue
                directSalesCash += share;
                operatingInflows += share;
              } else if (code.startsWith('112') || (counterAcc?.accountCategory == 'Receivable')) {
                // Customer Receivables Collection
                customerCollections += share;
                operatingInflows += share;
              } else if (code.startsWith('12') || (counterAcc?.accountCategory?.contains('Fixed') ?? false)) {
                // Sale of Fixed Assets
                fixedAssetsSold += share;
                investingInflows += share;
              } else if (typeId == 3) {
                // Capital contribution
                capitalInflow += share;
                financingInflows += share;
              } else if (code.startsWith('22')) {
                // Long term loan received
                loansMovement += share;
                financingInflows += share;
              } else {
                otherOperatingCash += share;
                operatingInflows += share;
              }
            } else {
              // Cash OUTFLOW
              if (typeId == 5) {
                // Operating Expenses
                operatingExpensesCash += share;
                operatingOutflows += share;
              } else if (code.startsWith('211') || (counterAcc?.accountCategory == 'Payable')) {
                // Supplier Payments
                supplierPayments += share;
                operatingOutflows += share;
              } else if (code.startsWith('12') || (counterAcc?.accountCategory?.contains('Fixed') ?? false)) {
                // Purchase of Fixed Assets
                fixedAssetsPurchased += share;
                investingOutflows += share;
              } else if (typeId == 3) {
                // Owner Drawings
                ownerDrawings += share;
                financingOutflows += share;
              } else if (code.startsWith('22')) {
                // Loan repayment
                loansMovement += share;
                financingOutflows += share;
              } else {
                operatingExpensesCash += share;
                operatingOutflows += share;
              }
            }
          }
        }
      }
    }

    final List<CashFlowActivityItem> operatingActivities = [
      if (directSalesCash > 0)
        CashFlowActivityItem(title: 'المقبوضات النقدية من المبيعات الفورية', amount: directSalesCash, isInflow: true),
      if (customerCollections > 0)
        CashFlowActivityItem(title: 'المتحصلات النقدية من حسابات العملاء والمدينين', amount: customerCollections, isInflow: true),
      if (supplierPayments > 0)
        CashFlowActivityItem(title: 'المدفوعات النقدية للموردين والمشتريات', amount: supplierPayments, isInflow: false),
      if (operatingExpensesCash > 0)
        CashFlowActivityItem(title: 'المدفوعات النقدية للمصروفات التشغيلية والعمومية', amount: operatingExpensesCash, isInflow: false),
      if (otherOperatingCash > 0)
        CashFlowActivityItem(title: 'مقبوضات تشغيلية أخرى', amount: otherOperatingCash, isInflow: true),
    ];

    final List<CashFlowActivityItem> investingActivities = [
      if (fixedAssetsPurchased > 0)
        CashFlowActivityItem(title: 'شراء أصول ثابتة ومعدات تشغيلية', amount: fixedAssetsPurchased, isInflow: false),
      if (fixedAssetsSold > 0)
        CashFlowActivityItem(title: 'متحصلات بيع أصول ثابتة وموجودات', amount: fixedAssetsSold, isInflow: true),
    ];

    final List<CashFlowActivityItem> financingActivities = [
      if (capitalInflow > 0)
        CashFlowActivityItem(title: 'زيادات وإيداعات في رأس المال وحقوق الملكية', amount: capitalInflow, isInflow: true),
      if (ownerDrawings > 0)
        CashFlowActivityItem(title: 'مسحوبات الشركاء والمالكين', amount: ownerDrawings, isInflow: false),
      if (loansMovement > 0)
        CashFlowActivityItem(title: 'حركات القروض والتمويلات المصرفية', amount: loansMovement, isInflow: true),
    ];

    final netOperating = PrecisionMath.roundMoney(operatingInflows - operatingOutflows);
    final netInvesting = PrecisionMath.roundMoney(investingInflows - investingOutflows);
    final netFinancing = PrecisionMath.roundMoney(financingInflows - financingOutflows);
    final netChange = PrecisionMath.roundMoney(netOperating + netInvesting + netFinancing);
    final closingTotal = PrecisionMath.roundMoney(totalOpeningCash + netChange);

    // Build cash accounts summary
    final List<CashFlowAccountItem> cashAccounts = cashAccountsList.map((a) {
      final op = PrecisionMath.roundMoney(openingBalances[a.id] ?? 0.0);
      final inf = PrecisionMath.roundMoney(inflowsMap[a.id] ?? 0.0);
      final outf = PrecisionMath.roundMoney(outflowsMap[a.id] ?? 0.0);
      final cl = PrecisionMath.roundMoney(op + inf - outf);
      return CashFlowAccountItem(
        accountId: a.id,
        accountCode: a.accountCode,
        accountName: a.accountName,
        category: a.accountCategory ?? (a.accountCode.startsWith('11101') ? 'الصناديق' : 'البنوك'),
        openingBalance: op,
        totalInflow: inf,
        totalOutflow: outf,
        closingBalance: cl,
      );
    }).toList();

    return CashFlowReport(
      startDate: startDate,
      endDate: endDate,
      openingCashBalance: PrecisionMath.roundMoney(totalOpeningCash),
      closingCashBalance: closingTotal,
      netChangeInCash: netChange,
      operatingActivities: operatingActivities,
      netOperatingCashFlow: netOperating,
      investingActivities: investingActivities,
      netInvestingCashFlow: netInvesting,
      financingActivities: financingActivities,
      netFinancingCashFlow: netFinancing,
      cashAccounts: cashAccounts,
    );
  }
}
