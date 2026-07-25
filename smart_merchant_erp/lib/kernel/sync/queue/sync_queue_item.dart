import 'package:equatable/equatable.dart';

/// Defines the nature of the offline operation queued for cloud synchronization.
enum SyncOperationType {
  /// Creating a new record on the remote server (`POST`).
  create,

  /// Updating an existing record on the remote server (`PUT`/`PATCH`).
  update,

  /// Physically deleting a record on the remote server (`DELETE`).
  delete,

  /// Marking a record as soft-deleted (`PATCH status = deleted`).
  softDelete,

  /// Restoring a soft-deleted record back to active (`PATCH status = active`).
  restore,

  /// Custom domain-specific action (e.g., closing a POS shift or batch posting).
  custom,
}

/// Priority levels governing the order in which queued operations are processed
/// by the background synchronization worker.
enum SyncPriority {
  /// Highest priority; processed immediately before any other items (e.g., shifts, critical payments).
  critical,

  /// High priority; processed right after critical items (e.g., sales invoices, customer receipts).
  high,

  /// Standard operational priority (e.g., stock adjustments, customer profile updates).
  normal,

  /// Low priority; processed during background idle time (e.g., analytics logs, UI settings).
  low,
}

/// Extension providing integer ordering values for [SyncPriority].
extension SyncPriorityX on SyncPriority {
  /// Returns numerical priority where higher number means higher urgency.
  int get priorityIndex {
    switch (this) {
      case SyncPriority.critical:
        return 4;
      case SyncPriority.high:
        return 3;
      case SyncPriority.normal:
        return 2;
      case SyncPriority.low:
        return 1;
    }
  }
}

/// Lifecycle states of a queued synchronization item inside the [SyncQueueContract].
enum SyncQueueItemState {
  /// Queued and waiting for processing conditions (connectivity, scheduled trigger).
  pending,

  /// Temporarily waiting due to dependencies or rate limiting.
  waiting,

  /// Currently being transmitted or processed by the upload pipeline.
  processing,

  /// Successfully acknowledged and processed by the remote Laravel API (`200 OK`).
  completed,

  /// Encountered a failure during upload or validation.
  failed,

  /// Scheduled for retry after a transient or recoverable network failure.
  retrying,

  /// Explicitly cancelled by the user or system before completion.
  cancelled,

  /// Expired because maximum retention or retry limits were exceeded.
  expired,
}

/// Encapsulates structured error details associated with a failed synchronization attempt.
class SyncError extends Equatable {
  /// Readable error message explaining why the upload failed.
  final String message;

  /// Optional HTTP status code returned by the Laravel API (e.g., `401`, `422`, `500`).
  final int? statusCode;

  /// Timestamp indicating when the error occurred.
  final DateTime occurredAt;

  /// Whether this error is transient and eligible for retry based on the retry policy.
  final bool canRetry;

  const SyncError({
    required this.message,
    required this.occurredAt,
    this.statusCode,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, statusCode, occurredAt, canRetry];
}

/// Immutable representation of a single synchronization task inside the offline-first queue.
///
/// Designed generically to carry metadata and payloads for any ERP entity (`T`)
/// across Sales, Inventory, Customers, Accounting, or HR without coupling to domain rules.
class SyncQueueItem<T> extends Equatable {
  /// Unique identifier of this queue entry (`UUID v4`).
  final String id;

  /// Name of the entity type (e.g., `'SalesInvoice'`, `'InventoryAdjustment'`, `'Customer'`).
  final String entityType;

  /// The operation to execute (`create`, `update`, `delete`, `softDelete`, `restore`, `custom`).
  final SyncOperationType operationType;

  /// Client-side unique identifier (`localUuid`) generated when the record was created offline.
  final String localId;

  /// Optional server-assigned identifier (`remoteId`) if already known from prior syncs.
  final String? remoteId;

  /// The serialized or domain payload representing the data to upload or synchronize.
  final T payload;

  /// Execution priority influencing the processing order.
  final SyncPriority priority;

  /// Timestamp when this item was enqueued locally.
  final DateTime createdAt;

  /// Number of attempts executed so far for this queue item.
  final int retryCount;

  /// Maximum allowed attempts before marking this item as permanently failed or expired.
  final int maxAttempts;

  /// Timestamp of the last execution attempt.
  final DateTime? lastAttempt;

  /// Current processing state (`pending`, `processing`, `completed`, etc.).
  final SyncQueueItemState state;

  /// Structured error information if the last attempt encountered an issue.
  final SyncError? errorInfo;

  /// Idempotency key guaranteeing strict deduplication on the remote Laravel API.
  final String? idempotencyKey;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.localId,
    required this.payload,
    required this.createdAt,
    this.priority = SyncPriority.normal,
    this.remoteId,
    this.retryCount = 0,
    this.maxAttempts = 5,
    this.lastAttempt,
    this.state = SyncQueueItemState.pending,
    this.errorInfo,
    this.idempotencyKey,
  });

  /// Whether this item is ready and eligible to be picked up by the background sync worker.
  bool get isReadyForProcessing =>
      state == SyncQueueItemState.pending ||
      state == SyncQueueItemState.retrying;

  /// Whether this item has exceeded its maximum retry budget.
  bool get isMaxRetriesExceeded => retryCount >= maxAttempts;

  /// Creates an updated copy of this queue item.
  SyncQueueItem<T> copyWith({
    String? id,
    String? entityType,
    SyncOperationType? operationType,
    String? localId,
    String? remoteId,
    T? payload,
    SyncPriority? priority,
    DateTime? createdAt,
    int? retryCount,
    int? maxAttempts,
    DateTime? lastAttempt,
    SyncQueueItemState? state,
    SyncError? errorInfo,
    String? idempotencyKey,
  }) {
    return SyncQueueItem<T>(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      state: state ?? this.state,
      errorInfo: errorInfo ?? this.errorInfo,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    entityType,
    operationType,
    localId,
    remoteId,
    payload,
    priority,
    createdAt,
    retryCount,
    maxAttempts,
    lastAttempt,
    state,
    errorInfo,
    idempotencyKey,
  ];
}
