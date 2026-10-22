import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/seeders/default_coa_seeder.dart';

part 'session_provider.g.dart';

/// Represents the current authenticated session state.
class SessionState {
  final String? businessId;
  final String? branchId;
  final String? userId;
  final bool? isOffline;

  const SessionState({
    this.businessId,
    this.branchId,
    this.userId,
    this.isOffline = false,
  });

  const SessionState.initial()
    : businessId = null,
      branchId = null,
      userId = null,
      isOffline = false;

  bool get isActive => businessId != null && userId != null;

  SessionState copyWith({
    String? businessId,
    String? branchId,
    String? userId,
    bool? isOffline,
  }) {
    return SessionState(
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionState &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          branchId == other.branchId &&
          userId == other.userId &&
          isOffline == other.isOffline;

  @override
  int get hashCode => Object.hash(businessId, branchId, userId, isOffline);
}

/// The Riverpod session controller.
/// Updates the authoritative [SessionHolder] singleton so that
/// GetIt-resolved Use Cases always see the current context.
///
/// Flow:
///   AuthNotifier.login() -> SessionNotifier.setSession()
///   -> SessionHolder.setSession() -> RuntimeApplicationContext reads SessionHolder
///   -> Use Cases read ApplicationContext
@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  @override
  SessionState build() {
    return const SessionState.initial();
  }

  /// Called after successful authentication to activate the runtime context.
  void setSession({
    required String businessId,
    String? branchId,
    required String userId,
    bool isOffline = false,
  }) {
    // Update the authoritative SessionHolder (single source of truth for GetIt)
    final holder = getIt<SessionHolder>();
    holder.setSession(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    // Update Riverpod state (mirrors the holder for UI reactivity)
    state = SessionState(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
      isOffline: isOffline,
    );

    // Auto-seed and initialize tables, COA, units, categories, fiscal period
    try {
      final db = getIt<AppDatabase>();
      DefaultChartOfAccountsSeeder(db).seedChartOfAccounts(
        businessId: businessId,
        currencyId: 'YER',
      );
    } catch (_) {}
  }

  /// Switch branch within the same business. Immediately reflects in ApplicationContext.
  void switchBranch(String newBranchId) {
    if (!state.isActive) return;

    final holder = getIt<SessionHolder>();
    holder.setSession(
      businessId: state.businessId!,
      branchId: newBranchId,
      userId: state.userId!,
    );

    state = state.copyWith(branchId: newBranchId);
  }

  /// Switch business (e.g., multi-business user). Clears branch to prevent stale context.
  void switchBusiness({required String newBusinessId, String? newBranchId}) {
    if (!state.isActive) return;

    final holder = getIt<SessionHolder>();
    holder.setSession(
      businessId: newBusinessId,
      branchId: newBranchId,
      userId: state.userId!,
    );

    state = SessionState(
      businessId: newBusinessId,
      branchId: newBranchId,
      userId: state.userId,
    );
  }

  /// Clear session on logout. Removes runtime context completely.
  void clearSession() {
    final holder = getIt<SessionHolder>();
    holder.clearSession();

    state = const SessionState.initial();
  }
}
