import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
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
