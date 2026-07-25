import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/error/failures.dart';
import '../../application/usecases/post_journal_entry_usecase.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../../../../kernel/storage/app_database.dart' show ChartOfAccount;
import '../../../authentication/presentation/providers/session_provider.dart';

part 'accounting_provider.g.dart';

// --- Accounting Read Providers ---

@riverpod
class ChartOfAccountsNotifier extends _$ChartOfAccountsNotifier {
  @override
  Stream<List<ChartOfAccount>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(accountingRepositoryProvider);
    return repo.watchChartOfAccounts(
      ChartOfAccountFilter(businessId: session.businessId!),
    );
  }
}

// --- Journal Entry Mutation Provider ---

class JournalLineState {
  final String accountId;
  final double debit;
  final double credit;
  final String? description;

  JournalLineState({
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });
}

class JournalState {
  final List<JournalLineState> lines;
  final String description;
  final String referenceNumber;

  // Mutation State
  final bool isSubmitting;
  final String? successJournalId;
  final Failure? error;

  JournalState({
    required this.lines,
    this.description = '',
    this.referenceNumber = '',
    this.isSubmitting = false,
    this.successJournalId,
    this.error,
  });

  factory JournalState.initial() => JournalState(lines: []);

  JournalState copyWith({
    List<JournalLineState>? lines,
    String? description,
    String? referenceNumber,
    bool? isSubmitting,
    String? successJournalId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return JournalState(
      lines: lines ?? this.lines,
      description: description ?? this.description,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successJournalId: clearSuccess
          ? null
          : (successJournalId ?? this.successJournalId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class JournalNotifier extends _$JournalNotifier {
  @override
  JournalState build() {
    return JournalState.initial();
  }

  void addLine({
    required String accountId,
    double debit = 0.0,
    double credit = 0.0,
    String? description,
  }) {
    if (state.isSubmitting) return;

    final currentLines = List<JournalLineState>.from(state.lines);
    currentLines.add(
      JournalLineState(
        accountId: accountId,
        debit: debit,
        credit: credit,
        description: description,
      ),
    );

    state = state.copyWith(
      lines: currentLines,
      clearError: true,
      clearSuccess: true,
    );
  }

  void updateDescription(String description) {
    if (state.isSubmitting) return;
    state = state.copyWith(description: description);
  }

  void updateReference(String referenceNumber) {
    if (state.isSubmitting) return;
    state = state.copyWith(referenceNumber: referenceNumber);
  }

  void clearForm() {
    if (state.isSubmitting) return;
    state = JournalState.initial();
  }

  Future<void> submitJournal({
    required DateTime entryDate,
    required String currencyId,
  }) async {
    if (state.isSubmitting || state.lines.isEmpty) {
      return;
    }

    // Preliminary balance check (though Application Layer enforces this authoritatively)
    final totalDebit = state.lines.fold(0.0, (sum, line) => sum + line.debit);
    final totalCredit = state.lines.fold(0.0, (sum, line) => sum + line.credit);

    if (totalDebit != totalCredit) {
      state = state.copyWith(
        error: const UnexpectedFailure(
          "Journal entry is not balanced. Debits must equal credits.",
        ),
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    final useCase = ref.read(postJournalEntryUseCaseProvider);

    final linesCommand = state.lines
        .map(
          (e) => JournalLineCommand(
            accountId: e.accountId,
            debitAmount: e.debit,
            creditAmount: e.credit,
            description: e.description,
          ),
        )
        .toList();

    final command = PostJournalEntryCommand(
      description: state.description,
      referenceNumber: state.referenceNumber,
      entryDate: entryDate,
      currencyId: currencyId,
      exchangeRate: 1.0,
      lines: linesCommand,
    );

    final result = await useCase(command);

    result.fold(
      (failure) => state = state.copyWith(isSubmitting: false, error: failure),
      (journalId) => state = state.copyWith(
        isSubmitting: false,
        successJournalId: journalId,
      ),
    );
  }
}
