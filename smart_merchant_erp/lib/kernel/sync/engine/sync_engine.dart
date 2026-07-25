import 'dart:async';
import '../../network/connectivity/network_monitor.dart';
import '../queue/sync_queue_contract.dart';
import 'background_sync_worker.dart';
import 'sync_download_pipeline.dart';
import 'sync_history.dart';
import 'sync_monitor.dart';
import 'sync_state_machine.dart';

/// Central contract governing enterprise bidirectional synchronization between
/// local offline storage and remote Laravel API servers.
abstract interface class SyncEngineContract {
  /// Executes a full bidirectional synchronization cycle (uploading pending queue, then downloading remote updates).
  Future<SyncHistoryRecord> runBidirectionalSync({
    List<String>? entityTypes,
    DateTime? since,
  });

  /// Executes an upload-only synchronization cycle processing the local pending queue.
  Future<int> runUploadQueue();

  /// Executes a download-only synchronization cycle fetching and reconciling remote updates.
  Future<int> runDownloadCycle({List<String>? entityTypes, DateTime? since});

  /// Stream emitting real-time operational state transitions of the engine.
  Stream<SyncStateMachineState> get stateStream;

  /// Stream emitting high-level synchronization events.
  Stream<SyncEngineEvent> get eventStream;
}

/// Concrete implementation of [SyncEngineContract] coordinating upload workers,
/// download pipelines, conflict resolution, state transitions, and historical telemetry.
class SyncEngineImpl implements SyncEngineContract {
  final SyncWorkerContract _worker;
  final SyncDownloadPipeline _downloadPipeline;
  final SyncStateMachine _stateMachine;
  final SyncHistoryStorageContract _historyStorage;
  final NetworkMonitorContract? _networkMonitor;
  final SyncQueueContract? _queue;
  final SyncLoggerContract? _monitor;

  final StreamController<SyncEngineEvent> _eventController =
      StreamController<SyncEngineEvent>.broadcast();

  SyncEngineImpl({
    required SyncWorkerContract worker,
    required SyncDownloadPipeline downloadPipeline,
    SyncStateMachine? stateMachine,
    SyncHistoryStorageContract? historyStorage,
    NetworkMonitorContract? networkMonitor,
    SyncQueueContract? queue,
    SyncLoggerContract? monitor,
  }) : _worker = worker,
       _downloadPipeline = downloadPipeline,
       _stateMachine = stateMachine ?? SyncStateMachine(),
       _historyStorage = historyStorage ?? DurableSyncHistoryStorage(),
       _networkMonitor = networkMonitor,
       _queue = queue,
       _monitor = monitor;

  @override
  Stream<SyncStateMachineState> get stateStream => _stateMachine.onStateChanged;

  @override
  Stream<SyncEngineEvent> get eventStream => _eventController.stream;

  void _emitEvent(
    SyncEngineEventKind kind,
    String message, {
    String? entityType,
    Map<String, dynamic>? details,
  }) {
    final event = SyncEngineEvent(
      kind: kind,
      timestamp: DateTime.now(),
      message: message,
      entityType: entityType,
      details: details,
    );
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
    _monitor?.log(
      SyncLogEvent(
        timestamp: event.timestamp,
        kind: _mapToMonitorKind(kind),
        message: message,
        entityType: entityType,
        details: details,
      ),
    );
  }

  SyncEventKind _mapToMonitorKind(SyncEngineEventKind kind) {
    switch (kind) {
      case SyncEngineEventKind.syncStarted:
        return SyncEventKind.workerStarted;
      case SyncEngineEventKind.syncCompleted:
        return SyncEventKind.workerCompleted;
      case SyncEngineEventKind.syncFailed:
        return SyncEventKind.uploadFailed;
      case SyncEngineEventKind.conflictDetected:
      case SyncEngineEventKind.conflictResolved:
        return SyncEventKind.retryExecuted;
      case SyncEngineEventKind.downloadCompleted:
        return SyncEventKind.workerCompleted;
      case SyncEngineEventKind.uploadCompleted:
        return SyncEventKind.uploadCompleted;
      case SyncEngineEventKind.queueEmpty:
        return SyncEventKind.workerCompleted;
    }
  }

  @override
  Future<int> runUploadQueue() async {
    if (_stateMachine.currentState != SyncStateMachineState.idle) {
      return 0;
    }

    _stateMachine.transitionTo(SyncStateMachineState.preparing);
    _emitEvent(SyncEngineEventKind.syncStarted, 'Starting upload queue cycle.');

    final monitor = _networkMonitor;
    if (monitor != null) {
      final status = await monitor.currentStatus;
      if (status == NetworkStatus.offline) {
        _stateMachine.transitionTo(SyncStateMachineState.idle);
        _emitEvent(
          SyncEngineEventKind.syncFailed,
          'Upload cycle aborted: device is offline.',
        );
        return 0;
      }
    }

    _stateMachine.transitionTo(SyncStateMachineState.uploading);

    try {
      final uploadCount = await _worker.processPendingQueue();
      _stateMachine.transitionTo(SyncStateMachineState.completed);
      _emitEvent(
        SyncEngineEventKind.uploadCompleted,
        'Upload cycle completed successfully. Uploaded $uploadCount items.',
        details: {'uploadCount': uploadCount},
      );
      _stateMachine.transitionTo(SyncStateMachineState.idle);
      return uploadCount;
    } catch (e) {
      _stateMachine.transitionTo(SyncStateMachineState.failed);
      _emitEvent(
        SyncEngineEventKind.syncFailed,
        'Upload cycle failed with exception: $e',
      );
      _stateMachine.transitionTo(SyncStateMachineState.idle);
      return 0;
    }
  }

  @override
  Future<int> runDownloadCycle({
    List<String>? entityTypes,
    DateTime? since,
  }) async {
    if (_stateMachine.currentState != SyncStateMachineState.idle) {
      return 0;
    }

    _stateMachine.transitionTo(SyncStateMachineState.preparing);
    _emitEvent(SyncEngineEventKind.syncStarted, 'Starting download cycle.');

    final monitor = _networkMonitor;
    if (monitor != null) {
      final status = await monitor.currentStatus;
      if (status == NetworkStatus.offline) {
        _stateMachine.transitionTo(SyncStateMachineState.idle);
        _emitEvent(
          SyncEngineEventKind.syncFailed,
          'Download cycle aborted: device is offline.',
        );
        return 0;
      }
    }

    _stateMachine.transitionTo(SyncStateMachineState.downloading);

    final targetEntities =
        entityTypes ??
        ['SalesInvoice', 'Customer', 'Product', 'InventoryAdjustment'];
    int totalDownloaded = 0;

    try {
      for (final entityType in targetEntities) {
        _stateMachine.transitionTo(SyncStateMachineState.comparing);
        final count = await _downloadPipeline.executeCycleForEntity(
          entityType,
          since: since,
        );
        totalDownloaded += count;
      }

      _stateMachine.transitionTo(SyncStateMachineState.completed);
      _emitEvent(
        SyncEngineEventKind.downloadCompleted,
        'Download cycle completed successfully. Downloaded $totalDownloaded records.',
        details: {'downloadCount': totalDownloaded},
      );
      _stateMachine.transitionTo(SyncStateMachineState.idle);
      return totalDownloaded;
    } catch (e) {
      _stateMachine.transitionTo(SyncStateMachineState.failed);
      _emitEvent(
        SyncEngineEventKind.syncFailed,
        'Download cycle failed with exception: $e',
      );
      _stateMachine.transitionTo(SyncStateMachineState.idle);
      return 0;
    }
  }

  @override
  Future<SyncHistoryRecord> runBidirectionalSync({
    List<String>? entityTypes,
    DateTime? since,
  }) async {
    if (_stateMachine.currentState != SyncStateMachineState.idle) {
      throw StateError(
        'SyncEngine is already active (${_stateMachine.currentState.name}).',
      );
    }

    final startTime = DateTime.now();
    _stateMachine.transitionTo(SyncStateMachineState.preparing);
    _emitEvent(
      SyncEngineEventKind.syncStarted,
      'Starting bidirectional synchronization cycle.',
    );

    final monitor = _networkMonitor;
    if (monitor != null) {
      final status = await monitor.currentStatus;
      if (status == NetworkStatus.offline) {
        _stateMachine.transitionTo(SyncStateMachineState.idle);
        final abortRecord = SyncHistoryRecord(
          id: 'hist_${startTime.millisecondsSinceEpoch}',
          startedAt: startTime,
          finishedAt: DateTime.now(),
          uploadCount: 0,
          downloadCount: 0,
          resolvedConflicts: 0,
          failedConflicts: 0,
          duration: DateTime.now().difference(startTime),
          result: false,
          errorMessage: 'Device offline at synchronization start.',
        );
        await _historyStorage.saveRecord(abortRecord);
        _emitEvent(SyncEngineEventKind.syncFailed, abortRecord.errorMessage!);
        return abortRecord;
      }
    }

    int uploadCount = 0;
    int downloadCount = 0;
    bool overallSuccess = true;
    String? errorSummary;

    try {
      // Step 1: Upload Pending Local Queue
      _stateMachine.transitionTo(SyncStateMachineState.uploading);
      uploadCount = await _worker.processPendingQueue();

      final queue = _queue;
      if (queue != null) {
        final remaining = await queue.getPendingCount();
        if (remaining == 0) {
          _emitEvent(
            SyncEngineEventKind.queueEmpty,
            'Local queue is now completely empty.',
          );
        }
      }

      // Step 2: Download Remote Server Updates & Reconcile Conflicts
      _stateMachine.transitionTo(SyncStateMachineState.downloading);
      final targetEntities =
          entityTypes ??
          ['SalesInvoice', 'Customer', 'Product', 'InventoryAdjustment'];

      for (final entityType in targetEntities) {
        _stateMachine.transitionTo(SyncStateMachineState.comparing);
        final count = await _downloadPipeline.executeCycleForEntity(
          entityType,
          since: since,
        );
        downloadCount += count;
      }

      _stateMachine.transitionTo(SyncStateMachineState.completed);
      _emitEvent(
        SyncEngineEventKind.syncCompleted,
        'Bidirectional sync finished successfully (Uploaded: $uploadCount, Downloaded: $downloadCount).',
        details: {'uploadCount': uploadCount, 'downloadCount': downloadCount},
      );
    } catch (e) {
      overallSuccess = false;
      errorSummary = e.toString();
      _stateMachine.transitionTo(SyncStateMachineState.failed);
      _emitEvent(
        SyncEngineEventKind.syncFailed,
        'Bidirectional sync failed: $errorSummary',
      );
    } finally {
      _stateMachine.transitionTo(SyncStateMachineState.idle);
    }

    final finishedTime = DateTime.now();
    final record = SyncHistoryRecord(
      id: 'hist_${startTime.millisecondsSinceEpoch}',
      startedAt: startTime,
      finishedAt: finishedTime,
      uploadCount: uploadCount,
      downloadCount: downloadCount,
      resolvedConflicts: 0, // Tracked and enriched by resolution handlers
      failedConflicts: 0,
      duration: finishedTime.difference(startTime),
      result: overallSuccess,
      errorMessage: errorSummary,
    );

    await _historyStorage.saveRecord(record);
    return record;
  }

  /// Disposes synchronization engine broadcast controllers and state machines upon shutdown.
  void dispose() {
    _eventController.close();
    _stateMachine.dispose();
  }
}
