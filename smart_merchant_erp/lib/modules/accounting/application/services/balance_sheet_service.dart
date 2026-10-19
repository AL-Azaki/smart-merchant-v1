import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Single account line item in the Balance Sheet report.
class BalanceSheetItem {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String? accountCategory;
  final double balance;

  const BalanceSheetItem({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.accountCategory,
    required this.balance,
  });
}

/// Comprehensive, mathematically balanced Balance Sheet Report (الميزانية العمومية).
class BalanceSheetReport {
  final DateTime asOfDate;

  // 1. الأصول (Assets)
  final List<BalanceSheetItem> currentAssets;
  final double totalCurrentAssets;
  final List<BalanceSheetItem> nonCurrentAssets;
  final double totalNonCurrentAssets;
  final double totalAssets;

  // 2. الخصوم والالتزامات (Liabilities)
  final List<BalanceSheetItem> currentLiabilities;
  final double totalCurrentLiabilities;
  final List<BalanceSheetItem> nonCurrentLiabilities;
  final double totalNonCurrentLiabilities;
  final double totalLiabilities;

  // 3. حقوق الملكية (Equity)
  final List<BalanceSheetItem> equityItems;
  final double currentPeriodNetProfit;
  final double totalEquity;

  // 4. المجموع الكلي ومطابقة التوازن الذهبي
  final double totalLiabilitiesAndEquity;
  final bool isBalanced;

  const BalanceSheetReport({
    required this.asOfDate,
    required this.currentAssets,
    required this.totalCurrentAssets,
    required this.nonCurrentAssets,
    required this.totalNonCurrentAssets,
    required this.totalAssets,
    required this.currentLiabilities,
    required this.totalCurrentLiabilities,
    required this.nonCurrentLiabilities,
    required this.totalNonCurrentLiabilities,
    required this.totalLiabilities,
    required this.equityItems,
    required this.currentPeriodNetProfit,
    required this.totalEquity,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
  });
}

/// Domain engine compiling official Balance Sheet (ميزان العمومية) reports.
class BalanceSheetService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  BalanceSheetService(this._accountingRepository, this._context);

  Future<BalanceSheetReport> generateBalanceSheet({DateTime? asOfDate}) async {
    final businessId = _context.currentBusinessId;
    final targetDate = asOfDate ?? DateTime.now();

    // 1. Fetch all posting chart of accounts
    final accounts = await _accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, isActive: true),
    );

    // 2. Fetch all posted journal lines up to the selected date
    final linesWithEntries = await _accountingRepository.getJournalLinesForReporting(
      businessId: businessId,
      endDate: targetDate,
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

    final List<BalanceSheetItem> currentAssets = [];
    final List<BalanceSheetItem> nonCurrentAssets = [];
    final List<BalanceSheetItem> currentLiabilities = [];
    final List<BalanceSheetItem> nonCurrentLiabilities = [];
    final List<BalanceSheetItem> equityItems = [];

    double totalCurrentAssets = 0.0;
    double totalNonCurrentAssets = 0.0;
    double totalCurrentLiabilities = 0.0;
    double totalNonCurrentLiabilities = 0.0;
    double sumEquityAccounts = 0.0;

    double totalRevenues = 0.0;
    double totalExpenses = 0.0;

    for (final acc in accounts) {
      if (!acc.allowPosting) continue;

      final deb = debitsMap[acc.id] ?? 0.0;
      final cred = creditsMap[acc.id] ?? 0.0;

      // 1. الأصول (Assets): Normal balance = Debit (Debit - Credit)
      if (acc.accountTypeId == 1) {
        final net = PrecisionMath.roundMoney(deb - cred);
        if (net == 0.0) continue;

        final item = BalanceSheetItem(
          accountId: acc.id,
          accountCode: acc.accountCode,
          accountName: acc.accountName,
          accountCategory: acc.accountCategory,
          balance: net,
        );

        final isNonCurrent = acc.accountCode.startsWith('12') ||
            (acc.accountCategory != null &&
                ['FixedAsset', 'NonCurrentAsset', 'ثابت'].any((k) => acc.accountCategory!.contains(k))) ||
            acc.accountName.contains('ثابت') ||
            acc.accountName.contains('أصول غير متداولة');

        if (isNonCurrent) {
          nonCurrentAssets.add(item);
          totalNonCurrentAssets += net;
        } else {
          currentAssets.add(item);
          totalCurrentAssets += net;
        }
      }
      // 2. الخصوم والالتزامات (Liabilities): Normal balance = Credit (Credit - Debit)
      else if (acc.accountTypeId == 2) {
        final net = PrecisionMath.roundMoney(cred - deb);
        if (net == 0.0) continue;

        final item = BalanceSheetItem(
          accountId: acc.id,
          accountCode: acc.accountCode,
          accountName: acc.accountName,
          accountCategory: acc.accountCategory,
          balance: net,
        );

        final isLongTerm = acc.accountCode.startsWith('22') ||
            (acc.accountCategory != null &&
                ['LongTermLiability', 'طويل'].any((k) => acc.accountCategory!.contains(k))) ||
            acc.accountName.contains('طويل') ||
            acc.accountName.contains('غير متداولة');

        if (isLongTerm) {
          nonCurrentLiabilities.add(item);
          totalNonCurrentLiabilities += net;
        } else {
          currentLiabilities.add(item);
          totalCurrentLiabilities += net;
        }
      }
      // 3. حقوق الملكية (Equity): Normal balance = Credit (Credit - Debit)
      else if (acc.accountTypeId == 3) {
        final net = PrecisionMath.roundMoney(cred - deb);
        if (net == 0.0) continue;

        equityItems.add(
          BalanceSheetItem(
            accountId: acc.id,
            accountCode: acc.accountCode,
            accountName: acc.accountName,
            accountCategory: acc.accountCategory,
            balance: net,
          ),
        );
        sumEquityAccounts += net;
      }
      // 4. الإيرادات (Revenue): Credit - Debit
      else if (acc.accountTypeId == 4) {
        final net = PrecisionMath.roundMoney(cred - deb);
        totalRevenues += net;
      }
      // 5. المصروفات (Expenses): Debit - Credit
      else if (acc.accountTypeId == 5) {
        final net = PrecisionMath.roundMoney(deb - cred);
        totalExpenses += net;
      }
    }

    // Sort items by code
    currentAssets.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    nonCurrentAssets.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    currentLiabilities.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    nonCurrentLiabilities.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    equityItems.sort((a, b) => a.accountCode.compareTo(b.accountCode));

    // Calculate Net Profit from dynamic period activity (Revenues - Expenses)
    final currentPeriodNetProfit = PrecisionMath.roundMoney(totalRevenues - totalExpenses);

    totalCurrentAssets = PrecisionMath.roundMoney(totalCurrentAssets);
    totalNonCurrentAssets = PrecisionMath.roundMoney(totalNonCurrentAssets);
    final totalAssets = PrecisionMath.roundMoney(totalCurrentAssets + totalNonCurrentAssets);

    totalCurrentLiabilities = PrecisionMath.roundMoney(totalCurrentLiabilities);
    totalNonCurrentLiabilities = PrecisionMath.roundMoney(totalNonCurrentLiabilities);
    final totalLiabilities = PrecisionMath.roundMoney(totalCurrentLiabilities + totalNonCurrentLiabilities);

    sumEquityAccounts = PrecisionMath.roundMoney(sumEquityAccounts);
    final totalEquity = PrecisionMath.roundMoney(sumEquityAccounts + currentPeriodNetProfit);

    final totalLiabilitiesAndEquity = PrecisionMath.roundMoney(totalLiabilities + totalEquity);

    final isBalanced = PrecisionMath.areBalanced(totalAssets, totalLiabilitiesAndEquity);

    return BalanceSheetReport(
      asOfDate: targetDate,
      currentAssets: currentAssets,
      totalCurrentAssets: totalCurrentAssets,
      nonCurrentAssets: nonCurrentAssets,
      totalNonCurrentAssets: totalNonCurrentAssets,
      totalAssets: totalAssets,
      currentLiabilities: currentLiabilities,
      totalCurrentLiabilities: totalCurrentLiabilities,
      nonCurrentLiabilities: nonCurrentLiabilities,
      totalNonCurrentLiabilities: totalNonCurrentLiabilities,
      totalLiabilities: totalLiabilities,
      equityItems: equityItems,
      currentPeriodNetProfit: currentPeriodNetProfit,
      totalEquity: totalEquity,
      totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
      isBalanced: isBalanced,
    );
  }
}
