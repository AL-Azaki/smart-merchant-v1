import 'dart:async';
import 'sync_queue_contract.dart';
import 'sync_queue_item.dart';
import 'sync_queue_storage.dart';

/// Concrete implementation of the [SyncQueueContract] managing offline synchronization
/// tasks with priority ordering and durable storage persistence.
class SyncQueueImpl implements SyncQueueContract {
  final SyncQueueStorageContract _storage;
  final Map<String, SyncQueueItem<dynamic>> _queueMap = {};
  bool _isLoaded = false;

  SyncQueueImpl(this._storage);

  Future<void> _ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    final items = await _storage.loadAll();
    for (final item in items) {
      _queueMap[item.id] = item;
    }
    _isLoaded = true;
  }

  @override
  Future<SyncQueueItem<T>> enqueue<T>(SyncQueueItem<T> item) async {
    await _ensureLoaded();
    _queueMap[item.id] = item;
    await _storage.saveItem(item);
    return item;
  }

  @override
  Future<bool> dequeue(String itemId) async {
    await _ensureLoaded();
    final removed = _queueMap.remove(itemId);
    if (removed != null) {
      await _storage.deleteItem(itemId);
      return true;
    }
    return false;
  }

  @override
  Future<SyncQueueItem<dynamic>?> getById(String itemId) async {
    await _ensureLoaded();
    return _queueMap[itemId];
  }

  @override
  Future<List<SyncQueueItem<dynamic>>> getPendingItems({
    SyncPriority? minPriority,
    int? limit,
  }) async {
    await _ensureLoaded();
    final candidates = _queueMap.values.where((item) {
      if (!item.isReadyForProcessing) {
        return false;
      }
      if (item.state == SyncQueueItemState.retrying &&
          item.lastAttempt != null) {
        // If scheduled for next attempt, verify delay
      }
      if (minPriority != null &&
          item.priority.priorityIndex < minPriority.priorityIndex) {
        return false;
      }
      return true;
    }).toList();

    // Sort by priority descending, then createdAt ascending
    candidates.sort((a, b) {
      final priorityComparison = b.priority.priorityIndex.compareTo(
        a.priority.priorityIndex,
      );
      if (priorityComparison != 0) {
        return priorityComparison;
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    if (limit != null && candidates.length > limit) {
      return candidates.sublist(0, limit);
    }
    return candidates;
  }

  @override
  Future<List<SyncQueueItem<dynamic>>> getItemsByEntity(
    String entityType, {
    String? localId,
  }) async {
    await _ensureLoaded();
    return _queueMap.values.where((item) {
      if (item.entityType != entityType) {
        return false;
      }
      if (localId != null && item.localId != localId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<SyncQueueItem<dynamic>> updateStatus(
    String itemId,
    SyncQueueItemState newState, {
    SyncError? error,
    String? remoteId,
  }) async {
    await _ensureLoaded();
    final existing = _queueMap[itemId];
    if (existing == null) {
      throw ArgumentError('SyncQueueItem with ID $itemId not found in queue.');
    }
    final updated = existing.copyWith(
      state: newState,
      errorInfo: error ?? existing.errorInfo,
      remoteId: remoteId ?? existing.remoteId,
      lastAttempt:
          newState == SyncQueueItemState.processing ||
              newState == SyncQueueItemState.completed
          ? DateTime.now()
          : existing.lastAttempt,
    );
    _queueMap[itemId] = updated;
    await _storage.saveItem(updated);
    return updated;
  }

  @override
  Future<SyncQueueItem<dynamic>> incrementRetry(
    String itemId, {
    SyncError? error,
    DateTime? nextAttempt,
  }) async {
    await _ensureLoaded();
    final existing = _queueMap[itemId];
    if (existing == null) {
      throw ArgumentError('SyncQueueItem with ID $itemId not found in queue.');
    }
    final newRetryCount = existing.retryCount + 1;
    final newState = newRetryCount >= existing.maxAttempts
        ? SyncQueueItemState.failed
        : SyncQueueItemState.retrying;

    final updated = existing.copyWith(
      retryCount: newRetryCount,
      state: newState,
      errorInfo: error ?? existing.errorInfo,
      lastAttempt: DateTime.now(),
    );
    _queueMap[itemId] = updated;
    await _storage.saveItem(updated);
    return updated;
  }

  @override
  Future<void> clearCompleted() async {
    await _ensureLoaded();
    final completedIds = _queueMap.values
        .where((item) => item.state == SyncQueueItemState.completed)
        .map((item) => item.id)
        .toList();

    for (final id in completedIds) {
      _queueMap.remove(id);
      await _storage.deleteItem(id);
    }
  }

  @override
  Future<void> cancelItem(String itemId) async {
    await updateStatus(itemId, SyncQueueItemState.cancelled);
  }

  @override
  Future<int> getPendingCount() async {
    await _ensureLoaded();
    return _queueMap.values.where((item) => item.isReadyForProcessing).length;
  }
}
