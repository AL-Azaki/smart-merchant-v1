import 'dart:async';
import '../../storage/offline_record.dart';
import '../../storage/storage_state.dart';
import '../resolution/conflict_detection.dart';
import '../resolution/conflict_resolution.dart';
import '../resolution/version_management.dart';
import 'sync_monitor.dart';

/// Contract that domain-specific download handlers implement to delegate remote fetch
/// and local SQLite persistence operations through clean architecture DAOs/Repositories.
abstract interface class SyncDownloadHandler<T> {
  /// Name of the entity type (`SalesInvoice`, `Customer`).
  String get entityType;

  /// Fetches the batch of remote records modified on the Laravel server since [since].
  Future<List<Map<String, dynamic>>> fetchRemoteBatch(DateTime? since);

  /// Retrieves the existing local offline record matching [remoteId] or [localId].
  Future<OfflineRecordContract?> getLocalRecordByRemoteOrLocalId(
    String? remoteId,
    String? localId,
  );

  /// Persists the final reconciled payload locally with updated state (`StorageState.synced`) and versioning.
  Future<void> persistResolvedRecord(
    dynamic payload, {
    required String remoteId,
    required int versionNumber,
    required DateTime lastModified,
  });
}

/// Orchestrates the standardized offline-first download processing pipeline:
/// `Receive API Response -> Validate -> Conflict Detection -> Conflict Resolution -> Merge -> Persist Local Storage -> Update Sync Metadata`
class SyncDownloadPipeline {
  final Map<String, SyncDownloadHandler<dynamic>> _handlers = {};
  final SyncConflictDetector _conflictDetector;
  final SyncResolutionPolicyRegistry _policyRegistry;
  final SyncLoggerContract? _monitor;

  SyncDownloadPipeline({
    SyncConflictDetector? conflictDetector,
    SyncResolutionPolicyRegistry? policyRegistry,
    SyncLoggerContract? monitor,
  }) : _conflictDetector = conflictDetector ?? SyncConflictDetector(),
       _policyRegistry = policyRegistry ?? SyncResolutionPolicyRegistry(),
       _monitor = monitor;

  /// Registers a domain download handler for a specific entity type.
  void registerHandler(SyncDownloadHandler<dynamic> handler) {
    _handlers[handler.entityType] = handler;
  }

  /// Executes the download reconciliation pipeline for a specific entity type from [since].
  /// Returns the number of successfully downloaded or reconciled records.
  Future<int> executeCycleForEntity(
    String entityType, {
    DateTime? since,
  }) async {
    final handler = _handlers[entityType];
    if (handler == null) {
      return 0;
    }

    try {
      final remoteRecords = await handler.fetchRemoteBatch(since);
      int processedCount = 0;

      for (final remoteMap in remoteRecords) {
        final remoteId =
            remoteMap['id']?.toString() ?? remoteMap['remoteId']?.toString();
        final localUuid =
            remoteMap['localUuid']?.toString() ??
            remoteMap['localId']?.toString();

        if (remoteId == null && localUuid == null) {
          continue;
        }

        final localRecord = await handler.getLocalRecordByRemoteOrLocalId(
          remoteId,
          localUuid,
        );

        final remoteVersionNum =
            int.tryParse(remoteMap['versionNumber']?.toString() ?? '1') ?? 1;
        final remoteTimestamp =
            DateTime.tryParse(remoteMap['updatedAt']?.toString() ?? '') ??
            DateTime.now();
        final remoteVersion = SyncVersionMetadata(
          versionNumber: remoteVersionNum,
          timestamp: remoteTimestamp,
          etag: remoteMap['etag']?.toString(),
          checksum: remoteMap['checksum']?.toString(),
        );

        if (localRecord == null) {
          // No local counterpart exists: clean download persistence
          await handler.persistResolvedRecord(
            remoteMap,
            remoteId: remoteId ?? localUuid ?? 'unknown',
            versionNumber: remoteVersionNum,
            lastModified: remoteTimestamp,
          );
          processedCount++;
          continue;
        }

        // Local record exists: run conflict detection
        final localVersion = SyncVersionMetadata(
          versionNumber: 1, // Baseline or extracted from metadata table
          timestamp: localRecord.lastModified,
        );

        final conflict = _conflictDetector.detectConflict<dynamic>(
          conflictId: 'conf_${localRecord.localUuid}_$remoteId',
          entityType: entityType,
          localId: localRecord.localUuid,
          storageState: localRecord.storageState,
          remoteId: remoteId,
          localPayload: (localRecord is OfflineRecord)
              ? localRecord.entity
              : null,
          remoteDictionary: remoteMap,
          localVersion: localVersion,
          remoteVersion: remoteVersion,
        );

        if (conflict == null) {
          // Records are synchronized or remote is cleanly newer without local dirtiness
          if (localRecord.storageState == StorageState.synced) {
            await handler.persistResolvedRecord(
              remoteMap,
              remoteId: remoteId ?? localRecord.id,
              versionNumber: remoteVersionNum,
              lastModified: remoteTimestamp,
            );
            processedCount++;
          }
          continue;
        }

        // Conflict identified!
        _monitor?.log(
          SyncLogEvent(
            timestamp: DateTime.now(),
            kind: SyncEventKind.uploadFailed, // or general telemetry
            itemId: localRecord.localUuid,
            entityType: entityType,
            message: 'Conflict detected: ${conflict.conflictType.name}',
          ),
        );

        final strategy = _policyRegistry.getStrategyForEntity(entityType);
        final resolutionResult = await strategy.resolve(conflict);

        if (resolutionResult.isResolved &&
            resolutionResult.requiresLocalUpdate) {
          await handler.persistResolvedRecord(
            resolutionResult.resolvedPayload,
            remoteId: remoteId ?? localRecord.id,
            versionNumber: remoteVersionNum,
            lastModified: remoteTimestamp,
          );
          processedCount++;
        }
      }

      return processedCount;
    } catch (e) {
      _monitor?.log(
        SyncLogEvent(
          timestamp: DateTime.now(),
          kind: SyncEventKind.uploadFailed,
          entityType: entityType,
          message: 'Exception in download pipeline: $e',
        ),
      );
      return 0;
    }
  }
}
