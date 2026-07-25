import 'dart:async';
import 'package:equatable/equatable.dart';

/// Categorizes the structural events occurring within the offline synchronization engine.
enum SyncEventKind {
  /// A new item was enqueued locally.
  queueCreated,

  /// Background worker initiated transmission of a queued item to the remote server.
  uploadStarted,

  /// Remote server acknowledged upload success (`200 OK`).
  uploadCompleted,

  /// Transmission or validation encountered a failure.
  uploadFailed,

  /// A failed item was scheduled for execution under the exponential backoff policy.
  retryExecuted,

  /// Queued operation was explicitly cancelled before upload.
  queueCancelled,

  /// Background worker batch processing cycle started.
  workerStarted,

  /// Background worker batch processing cycle finished.
  workerCompleted,
}

/// Immutable structured log entry capturing a synchronization event.
class SyncLogEvent extends Equatable {
  /// Timestamp when the synchronization event occurred.
  final DateTime timestamp;

  /// Classification of the event.
  final SyncEventKind kind;

  /// Optional queue item identifier associated with this event.
  final String? itemId;

  /// Optional entity type name (e.g., `'SalesInvoice'`).
  final String? entityType;

  /// Human-readable description of what happened during the event.
  final String message;

  /// Optional diagnostic key-value details or stack traces for debugging.
  final Map<String, dynamic>? details;

  const SyncLogEvent({
    required this.timestamp,
    required this.kind,
    required this.message,
    this.itemId,
    this.entityType,
    this.details,
  });

  @override
  List<Object?> get props => [
    timestamp,
    kind,
    itemId,
    entityType,
    message,
    details,
  ];
}

/// Base contract for any concrete synchronization logging and telemetry monitoring service.
abstract interface class SyncLoggerContract {
  /// Records a new synchronization event into the telemetry pipeline.
  void log(SyncLogEvent event);

  /// Stream emitting real-time synchronization events for dashboard monitoring or QA inspection.
  Stream<SyncLogEvent> get eventStream;

  /// Returns the historical list of recorded synchronization events.
  List<SyncLogEvent> getHistory({SyncEventKind? kindFilter, int? limit});
}

/// Centralized telemetry monitoring and logging implementation for the offline sync engine.
class SyncMonitor implements SyncLoggerContract {
  final StreamController<SyncLogEvent> _eventController =
      StreamController<SyncLogEvent>.broadcast();
  final List<SyncLogEvent> _history = [];
  final int maxHistoryEntries;

  SyncMonitor({this.maxHistoryEntries = 500});

  @override
  void log(SyncLogEvent event) {
    _history.insert(0, event);
    if (_history.length > maxHistoryEntries) {
      _history.removeLast();
    }
    _eventController.add(event);
  }

  @override
  Stream<SyncLogEvent> get eventStream => _eventController.stream;

  @override
  List<SyncLogEvent> getHistory({SyncEventKind? kindFilter, int? limit}) {
    final filtered = _history.where((e) {
      if (kindFilter != null && e.kind != kindFilter) {
        return false;
      }
      return true;
    }).toList();

    if (limit != null && filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  /// Disposes broadcast stream resources.
  void dispose() {
    _eventController.close();
  }
}
