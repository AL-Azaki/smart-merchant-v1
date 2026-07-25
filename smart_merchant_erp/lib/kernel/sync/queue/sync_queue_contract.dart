import 'sync_queue_item.dart';

/// Reusable contract defining operations for managing and querying offline synchronization tasks
/// across all modules of the Smart Merchant ERP system.
///
/// Ensures strict Clean Architecture compliance by keeping queue management generic and decoupled
/// from module-specific business rules or accounting formulas.
abstract interface class SyncQueueContract {
  /// Enqueues a new synchronization task into the queue.
  Future<SyncQueueItem<T>> enqueue<T>(SyncQueueItem<T> item);

  /// Removes a synchronization task from the queue once finalized or cancelled.
  Future<bool> dequeue(String itemId);

  /// Retrieves a queued synchronization item by its unique queue identifier (`id`).
  Future<SyncQueueItem<dynamic>?> getById(String itemId);

  /// Retrieves all pending or retrying queue items ordered by [SyncPriority] descending and [createdAt] ascending.
  /// Optionally filtered by minimum priority (`minPriority`) or bounded by (`limit`).
  Future<List<SyncQueueItem<dynamic>>> getPendingItems({
    SyncPriority? minPriority,
    int? limit,
  });

  /// Retrieves all queued synchronization items belonging to a specific entity type (`SalesInvoice`, `Customer`),
  /// optionally filtered by local record ID (`localId`).
  Future<List<SyncQueueItem<dynamic>>> getItemsByEntity(
    String entityType, {
    String? localId,
  });

  /// Updates the processing state and error details of an existing queue item.
  Future<SyncQueueItem<dynamic>> updateStatus(
    String itemId,
    SyncQueueItemState newState, {
    SyncError? error,
    String? remoteId,
  });

  /// Increments the retry counter and records the error from a failed upload attempt.
  /// Automatically transitions the state to [SyncQueueItemState.retrying] or [SyncQueueItemState.failed] if max attempts exceeded.
  Future<SyncQueueItem<dynamic>> incrementRetry(
    String itemId, {
    SyncError? error,
    DateTime? nextAttempt,
  });

  /// Purges all successfully completed synchronization items from queue storage.
  Future<void> clearCompleted();

  /// Explicitly cancels a queued operation (`SyncQueueItemState.cancelled`).
  Future<void> cancelItem(String itemId);

  /// Returns the total count of pending or retrying synchronization tasks currently queued.
  Future<int> getPendingCount();
}
