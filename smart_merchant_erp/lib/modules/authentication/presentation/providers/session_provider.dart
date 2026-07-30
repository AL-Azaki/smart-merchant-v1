import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../database/seeders/qa_data_seeder.dart';

part 'session_provider.g.dart';

/// Represents the current authenticated session state.
class SessionState {
  final String? businessId;
  final String? branchId;
  final String? userId;

  const SessionState({this.businessId, this.branchId, this.userId});

  const SessionState.initial()
    : businessId = null,
      branchId = null,
      userId = null;

  bool get isActive => businessId != null && userId != null;

  SessionState copyWith({
    String? businessId,
    String? branchId,
    String? userId,
  }) {
    return SessionState(
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionState &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          branchId == other.branchId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(businessId, branchId, userId);
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
    );

    if (kDebugMode) {
      _seedQaData(businessId, branchId ?? 'default-branch', userId);
    }
  }

  Future<void> _seedQaData(
    String businessId,
    String branchId,
    String userId,
  ) async {
    try {
      final db = getIt<AppDatabase>();
      final seeder = QaDataSeeder(db);
      await seeder.seedAll(
        businessId: businessId,
        branchId: branchId,
        userId: userId,
        accountId: 'qa-account-$businessId',
      );
      debugPrint('QA Data Seeded Successfully for Tenant: $businessId');
    } catch (e) {
      debugPrint('Failed to seed QA data: $e');
    }
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
