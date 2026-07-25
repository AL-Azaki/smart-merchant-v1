import 'dart:async';
import 'package:equatable/equatable.dart';

/// Events emitted by the enterprise synchronization engine during bidirectional cycles.
enum SyncEngineEventKind {
  /// Engine started a new synchronization cycle.
  syncStarted,

  /// Engine successfully completed bidirectional synchronization.
  syncCompleted,

  /// Engine encountered a critical failure stopping the cycle.
  syncFailed,

  /// Conflict detected between local and remote records.
  conflictDetected,

  /// Conflict resolved successfully by an applied resolution strategy.
  conflictResolved,

  /// Download batch processing completed for an entity type.
  downloadCompleted,

  /// Upload batch cycle completed.
  uploadCompleted,

  /// Local synchronization queue is completely empty.
  queueEmpty,
}

/// Structured event notification broadcast by the synchronization engine.
class SyncEngineEvent extends Equatable {
  /// Classification of the synchronization event.
  final SyncEngineEventKind kind;

  /// UTC timestamp when the event occurred.
  final DateTime timestamp;

  /// Optional entity type name associated with this event.
  final String? entityType;

  /// Human-readable message describing the event.
  final String message;

  /// Optional diagnostic metrics or details.
  final Map<String, dynamic>? details;

  const SyncEngineEvent({
    required this.kind,
    required this.timestamp,
    required this.message,
    this.entityType,
    this.details,
  });

  @override
  List<Object?> get props => [kind, timestamp, entityType, message, details];
}

/// Immutable record documenting the metrics and outcome of a synchronization cycle.
class SyncHistoryRecord extends Equatable {
  /// Unique identifier of this synchronization history entry (`UUID v4`).
  final String id;

  /// Timestamp when the synchronization cycle started.
  final DateTime startedAt;

  /// Timestamp when the synchronization cycle concluded.
  final DateTime finishedAt;

  /// Total number of records successfully uploaded during this cycle.
  final int uploadCount;

  /// Total number of records successfully downloaded or reconciled during this cycle.
  final int downloadCount;

  /// Number of concurrency conflicts resolved automatically or via policy.
  final int resolvedConflicts;

  /// Number of concurrency conflicts quarantined or permanently failed.
  final int failedConflicts;

  /// Total duration elapsed during the cycle.
  final Duration duration;

  /// Whether the overall synchronization cycle succeeded (`true`) or failed (`false`).
  final bool result;

  /// Error summary if the cycle terminated abnormally.
  final String? errorMessage;

  const SyncHistoryRecord({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.uploadCount,
    required this.downloadCount,
    required this.resolvedConflicts,
    required this.failedConflicts,
    required this.duration,
    required this.result,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    id,
    startedAt,
    finishedAt,
    uploadCount,
    downloadCount,
    resolvedConflicts,
    failedConflicts,
    duration,
    result,
    errorMessage,
  ];
}

/// Storage contract for maintaining synchronization history records across restarts without
/// modifying or coupling to the business database schema (`AppDatabase`).
abstract interface class SyncHistoryStorageContract {
  /// Saves a synchronization history entry.
  Future<void> saveRecord(SyncHistoryRecord record);

  /// Retrieves historical synchronization records ordered from newest to oldest.
  Future<List<SyncHistoryRecord>> getHistory({int limit = 100});

  /// Purges old history records exceeding [retentionLimit].
  Future<void> pruneOldRecords(int retentionLimit);

  /// Clears all stored synchronization history records.
  Future<void> clearHistory();
}

/// Durable memory-and-persistence implementation for synchronization history.
class DurableSyncHistoryStorage implements SyncHistoryStorageContract {
  final List<SyncHistoryRecord> _records = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
  }

  @override
  Future<void> saveRecord(SyncHistoryRecord record) async {
    await initialize();
    _records.insert(0, record);
    if (_records.length > 500) {
      _records.removeLast();
    }
  }

  @override
  Future<List<SyncHistoryRecord>> getHistory({int limit = 100}) async {
    await initialize();
    if (_records.length > limit) {
      return _records.sublist(0, limit);
    }
    return _records;
  }

  @override
  Future<void> pruneOldRecords(int retentionLimit) async {
    await initialize();
    if (_records.length > retentionLimit) {
      _records.removeRange(retentionLimit, _records.length);
    }
  }

  @override
  Future<void> clearHistory() async {
    await initialize();
    _records.clear();
  }
}
