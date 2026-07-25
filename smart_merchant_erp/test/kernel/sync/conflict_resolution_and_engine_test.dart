import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/offline_record.dart';
import 'package:smart_merchant_erp/kernel/storage/storage_state.dart';
import 'package:smart_merchant_erp/kernel/sync/sync_foundation.dart';

class DummyCustomerPayload {
  final String id;
  final String name;
  final String phone;

  const DummyCustomerPayload(this.id, this.name, this.phone);
}

class DummyCustomerRecord implements OfflineRecordContract {
  @override
  final String id;
  @override
  final String localUuid;
  @override
  final StorageState storageState;
  @override
  final DateTime lastModified;
  @override
  final int schemaVersion;
  @override
  final String? idempotencyKey;

  final DummyCustomerPayload entityPayload;

  const DummyCustomerRecord({
    required this.id,
    required this.localUuid,
    required this.storageState,
    required this.lastModified,
    this.schemaVersion = 1,
    this.idempotencyKey,
    required this.entityPayload,
  });

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'localUuid': localUuid,
    'name': entityPayload.name,
    'phone': entityPayload.phone,
  };
}

class DummyCustomerDownloadHandler
    implements SyncDownloadHandler<DummyCustomerPayload> {
  @override
  String get entityType => 'Customer';

  List<Map<String, dynamic>> remoteBatchToReturn = [];
  Map<String, OfflineRecordContract> localRecordsMap = {};
  List<Map<String, dynamic>> persistedRecords = [];

  @override
  Future<List<Map<String, dynamic>>> fetchRemoteBatch(DateTime? since) async {
    return remoteBatchToReturn;
  }

  @override
  Future<OfflineRecordContract?> getLocalRecordByRemoteOrLocalId(
    String? remoteId,
    String? localId,
  ) async {
    return localRecordsMap[remoteId] ?? localRecordsMap[localId];
  }

  @override
  Future<void> persistResolvedRecord(
    dynamic payload, {
    required String remoteId,
    required int versionNumber,
    required DateTime lastModified,
  }) async {
    persistedRecords.add({
      'remoteId': remoteId,
      'versionNumber': versionNumber,
      'lastModified': lastModified,
      'payload': payload,
    });
  }
}

class DummyWorker implements SyncWorkerContract {
  int processCalls = 0;
  int itemsProcessed = 0;
  bool processingState = false;

  @override
  bool get isProcessing => processingState;

  @override
  Future<int> processPendingQueue({
    SyncPriority? minPriority,
    int batchSize = 20,
  }) async {
    processCalls++;
    return itemsProcessed;
  }

  @override
  Future<bool> processSingleItem(String itemId) async => true;
}

void main() {
  group('Phase 2.3 — Conflict Resolution & Synchronization Engine Tests', () {
    test(
      'VersionComparator correctly identifies equal, newer, and concurrent version metadata',
      () {
        final comparator = VersionComparator();
        final t1 = DateTime(2026, 7, 18, 10, 0, 0);
        final t2 = DateTime(2026, 7, 18, 10, 5, 0);

        final v1 = SyncVersionMetadata(
          versionNumber: 1,
          timestamp: t1,
          checksum: 'abc',
        );
        final v2 = SyncVersionMetadata(
          versionNumber: 2,
          timestamp: t2,
          checksum: 'def',
        );
        final v1Concurrent = SyncVersionMetadata(
          versionNumber: 1,
          timestamp: t1,
          checksum: 'xyz',
        );

        expect(comparator.compare(v1, v1), VersionComparisonResult.equal);
        expect(comparator.compare(v2, v1), VersionComparisonResult.localNewer);
        expect(comparator.compare(v1, v2), VersionComparisonResult.remoteNewer);
        expect(
          comparator.compare(v1, v1Concurrent),
          VersionComparisonResult.concurrentConflict,
        );
      },
    );

    test(
      'SyncChangeDetector classifies created, deleted, updated, and unchanged lifecycle states',
      () {
        final detector = SyncChangeDetector();

        final createdSummary = detector.detectChange(
          localId: 'loc_c',
          storageState: StorageState.created,
        );
        expect(createdSummary.changeType, SyncChangeType.created);

        final deletedSummary = detector.detectChange(
          localId: 'loc_d',
          storageState: StorageState.deleted,
        );
        expect(deletedSummary.changeType, SyncChangeType.deleted);

        final updatedSummary = detector.detectChange(
          localId: 'loc_u',
          storageState: StorageState.updated,
        );
        expect(updatedSummary.changeType, SyncChangeType.updated);
      },
    );

    test(
      'SyncConflictDetector identifies collisions between local updates and remote changes',
      () {
        final conflictDetector = SyncConflictDetector();
        final now = DateTime.now();

        // Local update vs Remote newer revision
        final conflict = conflictDetector.detectConflict<DummyCustomerPayload>(
          conflictId: 'conf_1',
          entityType: 'Customer',
          localId: 'loc_cust_1',
          storageState: StorageState.updated,
          remoteId: 'rem_cust_1',
          localVersion: SyncVersionMetadata(
            versionNumber: 1,
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
          remoteVersion: SyncVersionMetadata(versionNumber: 2, timestamp: now),
          remoteDictionary: {'id': 'rem_cust_1', 'name': 'Updated Remote'},
        );

        expect(conflict, isNotNull);
        expect(
          conflict!.conflictType,
          SyncConflictType.localUpdateRemoteUpdate,
        );
      },
    );

    test(
      'SyncResolutionPolicyRegistry strategies resolve conflicts according to policy rules',
      () async {
        final registry = SyncResolutionPolicyRegistry();
        final now = DateTime.now();

        final conflict = SyncConflict<Map<String, dynamic>>(
          conflictId: 'conf_policy',
          entityType: 'Customer',
          localId: 'loc_1',
          conflictType: SyncConflictType.localUpdateRemoteUpdate,
          detectedAt: now,
          localPayload: {
            'id': 'rem_1',
            'localUuid': 'loc_1',
            'name': 'Local Customer',
            'phone': '111',
          },
          remoteDictionary: {
            'id': 'rem_1',
            'localUuid': 'loc_1',
            'name': 'Remote Customer',
            'phone': '222',
          },
          localVersion: SyncVersionMetadata(
            versionNumber: 1,
            timestamp: now.subtract(const Duration(minutes: 5)),
          ),
          remoteVersion: SyncVersionMetadata(versionNumber: 2, timestamp: now),
        );

        // Client Wins
        final clientWins = ClientWinsStrategy<Map<String, dynamic>>();
        final clientRes = await clientWins.resolve(conflict);
        expect(clientRes.resolvedPayload['name'], 'Local Customer');
        expect(clientRes.requiresRemoteUpdate, true);

        // Server Wins
        final serverWins = ServerWinsStrategy<Map<String, dynamic>>();
        final serverRes = await serverWins.resolve(conflict);
        expect(serverRes.resolvedPayload['name'], 'Remote Customer');
        expect(serverRes.requiresLocalUpdate, true);

        // Merge Strategy
        final mergeStrategy = MergeStrategy<Map<String, dynamic>>();
        registry.registerStrategy('Customer', mergeStrategy);
        final mergeRes = await registry
            .getStrategyForEntity('Customer')
            .resolve(conflict);
        expect(mergeRes.policyApplied, SyncResolutionPolicy.merge);
        expect(
          (mergeRes.resolvedPayload as Map)['id'],
          'rem_1',
        ); // Protected key preserved
      },
    );

    test(
      'SyncMergeEngine combines dictionaries without overwriting protected IDs',
      () {
        final mergeEngine = SyncMergeEngine();
        final localMap = {
          'id': 'rem_id_protected',
          'localUuid': 'loc_uuid_protected',
          'name': 'Local Shop',
          'address': 'Main Street 10',
        };
        final remoteMap = {
          'id': 'hacked_remote_id',
          'localUuid': 'hacked_local_uuid',
          'name': 'Remote Shop',
          'phone': '050000000',
        };

        final merged = mergeEngine.mergeDictionaries(
          localMap: localMap,
          remoteMap: remoteMap,
        );

        expect(
          merged['id'],
          'rem_id_protected',
        ); // Protected identity preserved
        expect(
          merged['localUuid'],
          'loc_uuid_protected',
        ); // Protected localUuid preserved
        expect(merged['phone'], '050000000'); // New remote field merged cleanly
      },
    );

    test(
      'SyncEngineImpl runs bidirectional sync, transitions states, and records history',
      () async {
        final dummyWorker = DummyWorker();
        dummyWorker.itemsProcessed = 3;

        final downloadHandler = DummyCustomerDownloadHandler();
        downloadHandler.remoteBatchToReturn = [
          {
            'id': 'rem_100',
            'localUuid': 'loc_100',
            'name': 'Cloud Customer',
            'phone': '0551234567',
            'versionNumber': '1',
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        final downloadPipeline = SyncDownloadPipeline();
        downloadPipeline.registerHandler(downloadHandler);

        final stateMachine = SyncStateMachine();
        final statesObserved = <SyncStateMachineState>[];
        stateMachine.onStateChanged.listen(statesObserved.add);

        final historyStorage = DurableSyncHistoryStorage();

        final engine = SyncEngineImpl(
          worker: dummyWorker,
          downloadPipeline: downloadPipeline,
          stateMachine: stateMachine,
          historyStorage: historyStorage,
        );

        final record = await engine.runBidirectionalSync(
          entityTypes: ['Customer'],
        );

        await Future.delayed(Duration.zero);
        expect(record.result, true);
        expect(record.uploadCount, 3);
        expect(record.downloadCount, 1);
        expect(downloadHandler.persistedRecords.length, 1);
        expect(statesObserved, contains(SyncStateMachineState.uploading));
        expect(statesObserved, contains(SyncStateMachineState.downloading));
        expect(stateMachine.currentState, SyncStateMachineState.idle);
        expect(statesObserved.last, SyncStateMachineState.idle);

        final history = await historyStorage.getHistory();
        expect(history.length, 1);
        expect(history.first.id, record.id);

        engine.dispose();
      },
    );
  });
}
