import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/account_statement_service.dart';
import '../../application/services/balance_sheet_service.dart';
import '../../application/services/cash_flow_service.dart';
import '../../application/services/profit_loss_service.dart';
import '../../application/services/trial_balance_service.dart';
import '../../domain/repositories/accounting_repository.dart';

part 'accounting_provider.g.dart';

@riverpod
class ChartOfAccountsNotifier extends _$ChartOfAccountsNotifier {
  @override
  Stream<List<ChartOfAccount>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      return const Stream.empty();
    }

    final repo = ref.watch(accountingRepositoryProvider);

    return repo.watchChartOfAccounts(
      ChartOfAccountFilter(businessId: session.businessId!, limit: null),
    );
  }
}

@riverpod
class JournalEntriesNotifier extends _$JournalEntriesNotifier {
  @override
  Stream<List<JournalEntry>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      return const Stream.empty();
    }

    final repo = ref.watch(accountingRepositoryProvider);

    return repo.watchJournalEntries(
      JournalEntryFilter(businessId: session.businessId!),
    );
  }
}

@riverpod
Future<JournalEntryWithLines?> journalEntryDetails(
  JournalEntryDetailsRef ref,
  String journalEntryId,
) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive || session.businessId == null) return null;

  final repo = ref.watch(accountingRepositoryProvider);
  return repo.getJournalEntryWithLinesById(journalEntryId, session.businessId!);
}

@riverpod
Future<TrialBalanceReport> trialBalanceReport(
  TrialBalanceReportRef ref, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive || session.businessId == null) {
    return const TrialBalanceReport(
      items: [],
      grandTotalDebit: 0,
      grandTotalCredit: 0,
      grandNetDebit: 0,
      grandNetCredit: 0,
      isBalanced: true,
    );
  }
  final service = getIt<TrialBalanceService>();
  return service.generateTrialBalance(startDate: startDate, endDate: endDate);
}

@riverpod
Future<ProfitLossReport> profitLossReport(
  ProfitLossReportRef ref, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive || session.businessId == null) {
    return const ProfitLossReport(
      revenueItems: [],
      totalRevenue: 0,
      cogsItems: [],
      totalCogs: 0,
      grossProfit: 0,
      expenseItems: [],
      totalExpenses: 0,
      netProfit: 0,
    );
  }
  final service = getIt<ProfitLossService>();
  return service.generateProfitLoss(startDate: startDate, endDate: endDate);
}

@riverpod
Future<AccountStatementReport?> accountStatementReport(
  AccountStatementReportRef ref, {
  required String accountId,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive || session.businessId == null) return null;
  final service = getIt<AccountStatementService>();
  return service.generateStatement(
    accountId: accountId,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Real-time Balance Sheet Report Provider (الميزانية العمومية)
final balanceSheetReportProvider =
    FutureProvider.autoDispose.family<BalanceSheetReport, DateTime?>(
  (ref, asOfDate) async {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      return BalanceSheetReport(
        asOfDate: asOfDate ?? DateTime.now(),
        currentAssets: const [],
        totalCurrentAssets: 0,
        nonCurrentAssets: const [],
        totalNonCurrentAssets: 0,
        totalAssets: 0,
        currentLiabilities: const [],
        totalCurrentLiabilities: 0,
        nonCurrentLiabilities: const [],
        totalNonCurrentLiabilities: 0,
        totalLiabilities: 0,
        equityItems: const [],
        currentPeriodNetProfit: 0,
        totalEquity: 0,
        totalLiabilitiesAndEquity: 0,
        isBalanced: true,
      );
    }
    final service = getIt<BalanceSheetService>();
    return service.generateBalanceSheet(asOfDate: asOfDate);
  },
);

/// Real-time Cash Flow Statement Provider (قائمة التدفق المالي / النقدي)
final cashFlowReportProvider =
    FutureProvider.autoDispose.family<CashFlowReport, ({DateTime? startDate, DateTime? endDate})>(
  (ref, dates) async {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      return const CashFlowReport(
        openingCashBalance: 0,
        closingCashBalance: 0,
        netChangeInCash: 0,
        operatingActivities: [],
        netOperatingCashFlow: 0,
        investingActivities: [],
        netInvestingCashFlow: 0,
        financingActivities: [],
        netFinancingCashFlow: 0,
        cashAccounts: [],
      );
    }
    final service = getIt<CashFlowService>();
    return service.generateCashFlow(
      startDate: dates.startDate,
      endDate: dates.endDate,
    );
  },
);

