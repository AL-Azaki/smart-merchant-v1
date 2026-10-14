import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/account_statement_service.dart';
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
      ChartOfAccountFilter(businessId: session.businessId!),
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

