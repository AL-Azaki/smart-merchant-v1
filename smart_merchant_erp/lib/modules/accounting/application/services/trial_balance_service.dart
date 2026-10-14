import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Single account row in the Trial Balance report.
class TrialBalanceItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String? accountCategory;
  final int accountTypeId;
  final double totalDebit;
  final double totalCredit;
  final double netDebit;
  final double netCredit;

  const TrialBalanceItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.accountCategory,
    required this.accountTypeId,
    required this.totalDebit,
    required this.totalCredit,
    required this.netDebit,
    required this.netCredit,
  });
}

/// Comprehensive Trial Balance report with golden arithmetic validation.
class TrialBalanceReport {
  final List<TrialBalanceItem> items;
  final double grandTotalDebit;
  final double grandTotalCredit;
  final double grandNetDebit;
  final double grandNetCredit;
  final bool isBalanced;

  const TrialBalanceReport({
    required this.items,
    required this.grandTotalDebit,
    required this.grandTotalCredit,
    required this.grandNetDebit,
    required this.grandNetCredit,
    required this.isBalanced,
  });
}

/// Domain engine that compiles real-time, high-precision Trial Balance reports.
class TrialBalanceService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  TrialBalanceService(this._accountingRepository, this._context);

  Future<TrialBalanceReport> generateTrialBalance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch all posting chart of accounts
    final accounts = await _accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, isActive: true),
    );
    final postingAccounts = accounts.where((a) => a.allowPosting).toList();

    // 2. Fetch all posted journal lines within scope
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

    // 4. Construct line items
    final List<TrialBalanceItem> items = [];
    double grandTotalDebit = 0.0;
    double grandTotalCredit = 0.0;
    double grandNetDebit = 0.0;
    double grandNetCredit = 0.0;

    for (final acc in postingAccounts) {
      final totalDeb = PrecisionMath.roundMoney(debitsMap[acc.id] ?? 0.0);
      final totalCred = PrecisionMath.roundMoney(creditsMap[acc.id] ?? 0.0);

      // Only include accounts with activity, or include all posting accounts
      if (totalDeb == 0.0 && totalCred == 0.0) continue;

      double netDeb = 0.0;
      double netCred = 0.0;

      if (totalDeb > totalCred) {
        netDeb = PrecisionMath.roundMoney(totalDeb - totalCred);
      } else if (totalCred > totalDeb) {
        netCred = PrecisionMath.roundMoney(totalCred - totalDeb);
      }

      grandTotalDebit += totalDeb;
      grandTotalCredit += totalCred;
      grandNetDebit += netDeb;
      grandNetCredit += netCred;

      items.add(
        TrialBalanceItem(
          accountId: acc.id,
          accountCode: acc.accountCode,
          accountName: acc.accountName,
          accountCategory: acc.accountCategory,
          accountTypeId: acc.accountTypeId,
          totalDebit: totalDeb,
          totalCredit: totalCred,
          netDebit: netDeb,
          netCredit: netCred,
        ),
      );
    }

    // Sort items by account code
    items.sort((a, b) => a.accountCode.compareTo(b.accountCode));

    grandTotalDebit = PrecisionMath.roundMoney(grandTotalDebit);
    grandTotalCredit = PrecisionMath.roundMoney(grandTotalCredit);
    grandNetDebit = PrecisionMath.roundMoney(grandNetDebit);
    grandNetCredit = PrecisionMath.roundMoney(grandNetCredit);

    final isBalanced = PrecisionMath.areBalanced(grandTotalDebit, grandTotalCredit) &&
        PrecisionMath.areBalanced(grandNetDebit, grandNetCredit);

    return TrialBalanceReport(
      items: items,
      grandTotalDebit: grandTotalDebit,
      grandTotalCredit: grandTotalCredit,
      grandNetDebit: grandNetDebit,
      grandNetCredit: grandNetCredit,
      isBalanced: isBalanced,
    );
  }
}
