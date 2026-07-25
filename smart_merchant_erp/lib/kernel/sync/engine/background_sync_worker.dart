import 'dart:async';
import '../../network/connectivity/network_monitor.dart';
import '../../network/retry/sync_retry_policy.dart';
import '../queue/sync_queue_contract.dart';
import '../queue/sync_queue_item.dart';
import 'sync_monitor.dart';
import 'sync_scheduler.dart';
import 'sync_upload_pipeline.dart';

/// Contract defining background worker execution and batch processing control.
abstract interface class SyncWorkerContract {
  /// Processes a batch of pending or retrying queue items up to [batchSize].
  /// Returns the number of successfully synchronized items.
  Future<int> processPendingQueue({
    SyncPriority? minPriority,
    int batchSize = 20,
  });

  /// Processes a specific single queue item immediately.
  Future<bool> processSingleItem(String itemId);

  /// Whether the background worker is currently executing an upload cycle.
  bool get isProcessing;
}

/// Generic background worker coordinating offline queue consumption, retry backoff checks,
/// and upload pipeline execution without coupling to module business logic.
class BackgroundSyncWorker implements SyncWorkerContract {
  final SyncQueueContract _queue;
  final SyncUploadPipeline _pipeline;
  final SyncRetryPolicy _retryPolicy;
  final NetworkMonitorContract? _networkMonitor;
  final SyncSchedulerContract? _scheduler;
  final SyncLoggerContract? _monitor;

  StreamSubscription<SyncScheduleTrigger>? _schedulerSubscription;
  bool _processing = false;

  BackgroundSyncWorker({
    required SyncQueueContract queue,
    required SyncUploadPipeline pipeline,
    SyncRetryPolicy retryPolicy = const SyncRetryPolicy(),
    NetworkMonitorContract? networkMonitor,
    SyncSchedulerContract? scheduler,
    SyncLoggerContract? monitor,
  }) : _queue = queue,
       _pipeline = pipeline,
       _retryPolicy = retryPolicy,
       _networkMonitor = networkMonitor,
       _scheduler = scheduler,
       _monitor = monitor {
    _bindScheduler();
  }

  void _bindScheduler() {
    final scheduler = _scheduler;
    if (scheduler == null) {
      return;
    }
    _schedulerSubscription = scheduler.onTriggered.listen((trigger) {
      processPendingQueue();
    });
  }

  @override
  bool get isProcessing => _processing;

  @override
  Future<int> processPendingQueue({
    SyncPriority? minPriority,
    int batchSize = 20,
  }) async {
    if (_processing) {
      return 0;
    }

    final monitor = _networkMonitor;
    if (monitor != null) {
      final netStatus = await monitor.currentStatus;
      if (netStatus == NetworkStatus.offline) {
        return 0;
      }
    }

    _processing = true;
    _monitor?.log(
      SyncLogEvent(
        timestamp: DateTime.now(),
        kind: SyncEventKind.workerStarted,
        message: 'Background worker batch cycle started.',
      ),
    );

    int successCount = 0;

    try {
      final pendingItems = await _queue.getPendingItems(
        minPriority: minPriority,
        limit: batchSize,
      );

      final now = DateTime.now();

      for (final item in pendingItems) {
        // Check exponential backoff delay if item is currently in retrying state
        final lastAttempt = item.lastAttempt;
        if (item.state == SyncQueueItemState.retrying && lastAttempt != null) {
          final requiredDelay = _retryPolicy.calculateNextDelay(
            item.retryCount,
          );
          final elapsed = now.difference(lastAttempt);
          if (elapsed < requiredDelay) {
            continue;
          }
        }

        final success = await _executeItem(item);
        if (success) {
          successCount++;
        }
      }
    } finally {
      _processing = false;
      _monitor?.log(
        SyncLogEvent(
          timestamp: DateTime.now(),
          kind: SyncEventKind.workerCompleted,
          message:
              'Background worker batch cycle completed. Processed $successCount items.',
          details: {'successCount': successCount},
        ),
      );
    }

    return successCount;
  }

  @override
  Future<bool> processSingleItem(String itemId) async {
    final item = await _queue.getById(itemId);
    if (item == null || !item.isReadyForProcessing) {
      return false;
    }
    return _executeItem(item);
  }

  Future<bool> _executeItem(SyncQueueItem<dynamic> item) async {
    // Transition to processing state in durable queue
    await _queue.updateStatus(item.id, SyncQueueItemState.processing);

    final response = await _pipeline.execute(item);

    if (response.success) {
      await _queue.updateStatus(
        item.id,
        SyncQueueItemState.completed,
        remoteId: response.remoteId,
      );
      return true;
    } else {
      final error = SyncError(
        message: response.errorMessage ?? 'Upload rejected by server.',
        statusCode: response.statusCode,
        occurredAt: DateTime.now(),
      );

      final canRetry = _retryPolicy.shouldRetry(
        item.retryCount,
        statusCode: response.statusCode,
        canRetryError: error.canRetry,
      );

      if (canRetry) {
        await _queue.incrementRetry(item.id, error: error);
      } else {
        await _queue.updateStatus(
          item.id,
          SyncQueueItemState.failed,
          error: error,
        );
      }
      return false;
    }
  }

  /// Disposes background worker subscriptions upon application shutdown.
  void dispose() {
    _schedulerSubscription?.cancel();
  }
}
