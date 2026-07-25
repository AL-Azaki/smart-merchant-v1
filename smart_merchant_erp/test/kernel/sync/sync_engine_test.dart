import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/sync/sync_foundation.dart';

class DummyPayload {
  final String name;
  final double amount;

  const DummyPayload(this.name, this.amount);
}

class DummySyncHandler implements SyncPipelineHandler<DummyPayload> {
  @override
  String get entityType => 'DummyInvoice';

  int validationCalls = 0;
  int sendCalls = 0;
  int successHooks = 0;
  int failureHooks = 0;
  bool shouldSucceed = true;
  int statusCodeToReturn = 200;

  @override
  Future<void> validate(SyncQueueItem<DummyPayload> item) async {
    validationCalls++;
  }

  @override
  Future<Map<String, dynamic>> prepareRequest(
    SyncQueueItem<DummyPayload> item,
  ) async {
    return {'name': item.payload.name, 'amount': item.payload.amount};
  }

  @override
  Future<SyncPipelineResponse> sendRequest(
    SyncQueueItem<DummyPayload> item,
    Map<String, dynamic> requestData,
  ) async {
    sendCalls++;
    if (shouldSucceed) {
      return SyncPipelineResponse.success(
        statusCode: statusCodeToReturn,
        remoteId: 'remote_${item.id}',
      );
    } else {
      return SyncPipelineResponse.failure(
        statusCode: statusCodeToReturn,
        message: 'Server validation error',
      );
    }
  }

  @override
  Future<void> onSyncSuccess(
    SyncQueueItem<DummyPayload> item,
    SyncPipelineResponse response,
  ) async {
    successHooks++;
  }

  @override
  Future<void> onSyncFailure(
    SyncQueueItem<DummyPayload> item,
    SyncError error,
  ) async {
    failureHooks++;
  }
}

void main() {
  group('Phase 2.2 — Sync Queue & Background Processing Tests', () {
    late DurableSyncQueueStorage storage;
    late SyncQueueImpl queue;
    late SyncMonitor monitor;
    late SyncUploadPipeline pipeline;
    late DummySyncHandler handler;
    late BackgroundSyncWorker worker;

    setUp(() {
      storage = DurableSyncQueueStorage();
      queue = SyncQueueImpl(storage);
      monitor = SyncMonitor();
      pipeline = SyncUploadPipeline(monitor: monitor);
      handler = DummySyncHandler();
      pipeline.registerHandler(handler);

      worker = BackgroundSyncWorker(
        queue: queue,
        pipeline: pipeline,
        retryPolicy: const SyncRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        monitor: monitor,
      );
    });

    test(
      'SyncQueue must sort pending items strictly by priority descending, then createdAt ascending',
      () async {
        final itemLow = SyncQueueItem<DummyPayload>(
          id: '1',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_1',
          payload: const DummyPayload('Low', 10),
          priority: SyncPriority.low,
          createdAt: DateTime(2026, 7, 18, 10, 0),
        );

        final itemCritical = SyncQueueItem<DummyPayload>(
          id: '2',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_2',
          payload: const DummyPayload('Critical', 100),
          priority: SyncPriority.critical,
          createdAt: DateTime(2026, 7, 18, 10, 5),
        );

        final itemHigh = SyncQueueItem<DummyPayload>(
          id: '3',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_3',
          payload: const DummyPayload('High', 50),
          priority: SyncPriority.high,
          createdAt: DateTime(2026, 7, 18, 10, 2),
        );

        await queue.enqueue(itemLow);
        await queue.enqueue(itemCritical);
        await queue.enqueue(itemHigh);

        final pending = await queue.getPendingItems();
        expect(pending.length, 3);
        expect(pending[0].id, '2'); // critical first
        expect(pending[1].id, '3'); // high second
        expect(pending[2].id, '1'); // low third
      },
    );

    test(
      'Queue persistence survives across storage instances without losing items',
      () async {
        final item = SyncQueueItem<DummyPayload>(
          id: 'persist_item',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_p',
          payload: const DummyPayload('Persistent', 500),
          createdAt: DateTime.now(),
        );

        await queue.enqueue(item);
        expect(await queue.getPendingCount(), 1);

        // Re-instantiate queue using same storage contract
        final reloadedQueue = SyncQueueImpl(storage);
        final reloadedItems = await reloadedQueue.getPendingItems();
        expect(reloadedItems.length, 1);
        expect(reloadedItems.first.id, 'persist_item');
      },
    );

    test(
      'BackgroundSyncWorker processes queue items via pipeline and marks as completed on success',
      () async {
        final item = SyncQueueItem<DummyPayload>(
          id: 'worker_item_1',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_w1',
          payload: const DummyPayload('Worker Test', 250),
          createdAt: DateTime.now(),
        );

        await queue.enqueue(item);
        expect(await queue.getPendingCount(), 1);

        final processedCount = await worker.processPendingQueue();
        expect(processedCount, 1);
        expect(handler.sendCalls, 1);
        expect(handler.successHooks, 1);

        final updatedItem = await queue.getById('worker_item_1');
        expect(updatedItem?.state, SyncQueueItemState.completed);
        expect(updatedItem?.remoteId, 'remote_worker_item_1');
      },
    );

    test(
      'BackgroundSyncWorker increments retry counter on transient failure and respects non-retryable codes',
      () async {
        handler.shouldSucceed = false;
        handler.statusCodeToReturn =
            500; // Transient server error, eligible for retry

        final item = SyncQueueItem<DummyPayload>(
          id: 'fail_item_1',
          entityType: 'DummyInvoice',
          operationType: SyncOperationType.create,
          localId: 'loc_f1',
          payload: const DummyPayload('Fail Test', 10),
          createdAt: DateTime.now(),
        );

        await queue.enqueue(item);
        await worker.processPendingQueue();

        final retryingItem = await queue.getById('fail_item_1');
        expect(retryingItem?.state, SyncQueueItemState.retrying);
        expect(retryingItem?.retryCount, 1);

        // Test permanent rejection (e.g. 422 Unprocessable Entity)
        handler.statusCodeToReturn = 422;
        await worker.processSingleItem('fail_item_1');

        final failedItem = await queue.getById('fail_item_1');
        expect(
          failedItem?.state,
          SyncQueueItemState.failed,
        ); // Permanent failure, no retrying
      },
    );

    test('SyncScheduler triggers worker on connectivity restoration', () async {
      final networkMonitor = NetworkMonitorImpl();
      final scheduler = SyncScheduler(networkMonitor: networkMonitor);
      final triggeredEvents = <SyncScheduleTrigger>[];
      scheduler.onTriggered.listen(triggeredEvents.add);

      networkMonitor.updateStatus(NetworkStatus.offline);
      networkMonitor.updateStatus(NetworkStatus.online);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        triggeredEvents,
        contains(SyncScheduleTrigger.connectivityRestored),
      );

      scheduler.dispose();
      networkMonitor.dispose();
    });
  });
}
