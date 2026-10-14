import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Single item within a Profit & Loss category.
class ProfitLossCategoryItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final double amount;

  const ProfitLossCategoryItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.amount,
  });
}

/// Official Income Statement / Profit & Loss Report structure.
class ProfitLossReport {
  final List<ProfitLossCategoryItem> revenueItems;
  final double totalRevenue;
  final List<ProfitLossCategoryItem> cogsItems;
  final double totalCogs;
  final double grossProfit;
  final List<ProfitLossCategoryItem> expenseItems;
  final double totalExpenses;
  final double netProfit;

  const ProfitLossReport({
    required this.revenueItems,
    required this.totalRevenue,
    required this.cogsItems,
    required this.totalCogs,
    required this.grossProfit,
    required this.expenseItems,
    required this.totalExpenses,
    required this.netProfit,
  });
}

/// Domain engine compiling official Income Statement (Profit & Loss / P&L) reports.
class ProfitLossService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  ProfitLossService(this._accountingRepository, this._context);

  Future<ProfitLossReport> generateProfitLoss({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch all accounts
    final accounts = await _accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, isActive: true),
    );
    final accountMap = {for (final a in accounts) a.id: a};

    // 2. Fetch all posted journal lines
    final linesWithEntries = await _accountingRepository.getJournalLinesForReporting(
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      status: 'Posted',
    );

    // 3. Aggregate debits and credits per account
    final Map<String, double> debitsMap = {};
    final Map<String, double> creditsMap = {};

    for (final item in linesWithEntries) {
      final accId = item.line.chartOfAccountId;
      final amount = item.line.baseAmount;
      if (item.line.type == 'Debit') {
        debitsMap[accId] = (debitsMap[accId] ?? 0.0) + amount;
      } else if (item.line.type == 'Credit') {
        creditsMap[accId] = (creditsMap[accId] ?? 0.0) + amount;
      }
    }

    final List<ProfitLossCategoryItem> revenueItems = [];
    final List<ProfitLossCategoryItem> cogsItems = [];
    final List<ProfitLossCategoryItem> expenseItems = [];

    double totalRevenue = 0.0;
    double totalCogs = 0.0;
    double totalExpenses = 0.0;

    for (final acc in accounts) {
      if (!acc.allowPosting) continue;

      final deb = debitsMap[acc.id] ?? 0.0;
      final cred = creditsMap[acc.id] ?? 0.0;

      // Revenue Accounts (Class 4): Normal Balance = Credit (Credit - Debit)
      if (acc.accountTypeId == 4) {
        final netRev = PrecisionMath.roundMoney(cred - deb);
        if (netRev != 0.0) {
          totalRevenue += netRev;
          revenueItems.add(
            ProfitLossCategoryItem(
              accountId: acc.id,
              accountCode: acc.accountCode,
              accountName: acc.accountName,
              amount: netRev,
            ),
          );
        }
      }

      // Expense Accounts (Class 5): Normal Balance = Debit (Debit - Credit)
      if (acc.accountTypeId == 5) {
        final netExp = PrecisionMath.roundMoney(deb - cred);
        if (netExp != 0.0) {
          // Check if it's COGS (account code starts with '51' or category is 'COGS')
          final isCogs = acc.accountCode.startsWith('51') ||
              (acc.accountCategory?.toLowerCase() == 'cogs') ||
              acc.accountCode == '51';

          if (isCogs) {
            totalCogs += netExp;
            cogsItems.add(
              ProfitLossCategoryItem(
                accountId: acc.id,
                accountCode: acc.accountCode,
                accountName: acc.accountName,
                amount: netExp,
              ),
            );
          } else {
            totalExpenses += netExp;
            expenseItems.add(
              ProfitLossCategoryItem(
                accountId: acc.id,
                accountCode: acc.accountCode,
                accountName: acc.accountName,
                amount: netExp,
              ),
            );
          }
        }
      }
    }

    revenueItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    cogsItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    expenseItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));

    totalRevenue = PrecisionMath.roundMoney(totalRevenue);
    totalCogs = PrecisionMath.roundMoney(totalCogs);
    totalExpenses = PrecisionMath.roundMoney(totalExpenses);

    final grossProfit = PrecisionMath.roundMoney(totalRevenue - totalCogs);
    final netProfit = PrecisionMath.roundMoney(grossProfit - totalExpenses);

    return ProfitLossReport(
      revenueItems: revenueItems,
      totalRevenue: totalRevenue,
      cogsItems: cogsItems,
      totalCogs: totalCogs,
      grossProfit: grossProfit,
      expenseItems: expenseItems,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }
}
