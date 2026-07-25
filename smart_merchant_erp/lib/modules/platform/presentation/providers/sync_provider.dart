import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../kernel/sync/coordinator/sync_coordinator.dart';

part 'sync_provider.g.dart';

/// Riverpod provider exposing synchronization state to the UI.
///
/// Responsibilities:
/// - Trigger sync (manual or automatic)
/// - Observe sync state
/// - Expose last sync info
///
/// Must NOT:
/// - Implement HTTP protocol
/// - Calculate revisions
/// - Perform raw SQL
/// - Contain retry algorithms
@Riverpod(keepAlive: true)
class SyncNotifier extends _$SyncNotifier {
  SyncCoordinator? _coordinator;
  StreamSubscription<SyncStatus>? _statusSubscription;

  @override
  SyncState build() {
    ref.onDispose(() {
      _statusSubscription?.cancel();
    });
    return const SyncState.initial();
  }

  /// Initialize with the real sync coordinator after authentication.
  void initialize(SyncCoordinator coordinator) {
    _coordinator = coordinator;
    _statusSubscription?.cancel();
    _statusSubscription = coordinator.statusStream.listen((status) {
      state = state.copyWith(status: status);
    });
  }

  /// Trigger a full bidirectional sync cycle.
  Future<void> syncNow() async {
    final coordinator = _coordinator;
    if (coordinator == null) {
      state = state.copyWith(status: SyncStatus.authenticationRequired);
      return;
    }

    final result = await coordinator.runFullSync();
    state = SyncState(
      status: result.status,
      lastSyncResult: result,
      lastSyncAt: result.timestamp,
    );
  }

  /// Reset sync state (e.g., on logout).
  void reset() {
    _statusSubscription?.cancel();
    _coordinator = null;
    state = const SyncState.initial();
  }
}

/// Immutable sync state for UI consumption.
class SyncState {
  final SyncStatus status;
  final SyncCycleResult? lastSyncResult;
  final DateTime? lastSyncAt;

  const SyncState({required this.status, this.lastSyncResult, this.lastSyncAt});

  const SyncState.initial()
    : status = SyncStatus.idle,
      lastSyncResult = null,
      lastSyncAt = null;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isOffline => status == SyncStatus.offline;
  bool get needsAuth => status == SyncStatus.authenticationRequired;
  bool get isDeviceRevoked => status == SyncStatus.deviceRevoked;

  SyncState copyWith({
    SyncStatus? status,
    SyncCycleResult? lastSyncResult,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncResult: lastSyncResult ?? this.lastSyncResult,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastSyncAt == other.lastSyncAt;

  @override
  int get hashCode => Object.hash(status, lastSyncAt);
}
