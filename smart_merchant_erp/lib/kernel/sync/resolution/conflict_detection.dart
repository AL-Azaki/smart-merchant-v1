import 'package:equatable/equatable.dart';
import '../../storage/storage_state.dart';
import 'version_management.dart';

/// Categorizes the exact nature of a detected synchronization conflict between
/// local device records and remote Laravel API server records.
enum SyncConflictType {
  /// Both local record and remote server record were updated independently since last sync (`Local Update vs Remote Update`).
  localUpdateRemoteUpdate,

  /// Record was marked soft-deleted locally while simultaneously updated on the server (`Local Delete vs Remote Update`).
  localDeleteRemoteUpdate,

  /// Record was updated locally while simultaneously deleted on the remote server (`Local Update vs Remote Delete`).
  localUpdateRemoteDelete,

  /// Simultaneous modification detected via exact timestamp or ETag collision.
  simultaneousModification,

  /// Record created locally shares unique constraints or idempotency keys with an existing server record (`Duplicate Creation`).
  duplicateCreation,

  /// Expected local or remote counterpart is missing during reconciliation (`Missing Record`).
  missingRecord,

  /// Revision numbers diverged without clear parent-child lineage (`Version Mismatch`).
  versionMismatch,

  /// Physical timestamps diverged across multi-master boundaries (`Timestamp Mismatch`).
  timestampMismatch,

  /// Cryptographic checksum or metadata validation failed (`Metadata Conflict`).
  metadataConflict,
}

/// Immutable representation of a synchronization conflict detected between a local record and its remote cloud counterpart.
///
/// Designed generically to encapsulate conflict states for any ERP domain entity (`T`)
/// while preserving both local and remote payloads for resolution engine decisioning.
class SyncConflict<T> extends Equatable {
  /// Unique identifier of this conflict incident (`UUID v4`).
  final String conflictId;

  /// Name of the entity type (e.g., `'SalesInvoice'`, `'Customer'`).
  final String entityType;

  /// Client-side unique record identifier (`localUuid`).
  final String localId;

  /// Optional server-assigned identifier (`remoteId`).
  final String? remoteId;

  /// Classification of the detected conflict.
  final SyncConflictType conflictType;

  /// The local domain entity payload (`T`) when the conflict occurred.
  final T? localPayload;

  /// The raw remote JSON dictionary returned by the Laravel API server.
  final Map<String, dynamic>? remoteDictionary;

  /// Local version metadata when the conflict was detected.
  final SyncVersionMetadata? localVersion;

  /// Remote server version metadata when the conflict was detected.
  final SyncVersionMetadata? remoteVersion;

  /// Timestamp when the conflict detection engine identified this collision.
  final DateTime detectedAt;

  const SyncConflict({
    required this.conflictId,
    required this.entityType,
    required this.localId,
    required this.conflictType,
    required this.detectedAt,
    this.remoteId,
    this.localPayload,
    this.remoteDictionary,
    this.localVersion,
    this.remoteVersion,
  });

  @override
  List<Object?> get props => [
    conflictId,
    entityType,
    localId,
    remoteId,
    conflictType,
    localPayload,
    remoteDictionary,
    localVersion,
    remoteVersion,
    detectedAt,
  ];
}

/// Reusable conflict detection engine inspecting local lifecycle states, timestamps,
/// and version metadata against remote payloads to identify concurrency collisions.
class SyncConflictDetector {
  final VersionComparator _comparator;

  SyncConflictDetector({VersionComparator? comparator})
    : _comparator = comparator ?? VersionComparator();

  /// Inspects a local record and remote payload to determine if a synchronization conflict exists.
  /// Returns `null` if the records are synchronized or can be cleanly reconciled without conflict.
  SyncConflict<T>? detectConflict<T>({
    required String conflictId,
    required String entityType,
    required String localId,
    required StorageState storageState,
    String? remoteId,
    T? localPayload,
    Map<String, dynamic>? remoteDictionary,
    SyncVersionMetadata? localVersion,
    SyncVersionMetadata? remoteVersion,
  }) {
    final now = DateTime.now();

    // 1. Check Local Delete vs Remote Update
    if (storageState == StorageState.deleted) {
      if (remoteVersion != null && localVersion != null) {
        if (remoteVersion.versionNumber > localVersion.versionNumber ||
            remoteVersion.timestamp.isAfter(
              localVersion.timestamp.add(const Duration(seconds: 2)),
            )) {
          return SyncConflict<T>(
            conflictId: conflictId,
            entityType: entityType,
            localId: localId,
            remoteId: remoteId,
            conflictType: SyncConflictType.localDeleteRemoteUpdate,
            detectedAt: now,
            localPayload: localPayload,
            remoteDictionary: remoteDictionary,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
          );
        }
      }
      return null;
    }

    // 2. Check Local Update vs Remote Delete (or missing remote record during download check)
    if (storageState == StorageState.updated &&
        remoteDictionary == null &&
        remoteId != null) {
      return SyncConflict<T>(
        conflictId: conflictId,
        entityType: entityType,
        localId: localId,
        remoteId: remoteId,
        conflictType: SyncConflictType.localUpdateRemoteDelete,
        detectedAt: now,
        localPayload: localPayload,
        remoteDictionary: remoteDictionary,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
      );
    }

    // 3. Check Local Update vs Remote Update or Version Concurrency
    if (storageState == StorageState.updated ||
        storageState == StorageState.synced) {
      if (localVersion != null && remoteVersion != null) {
        final compResult = _comparator.compare(localVersion, remoteVersion);

        if (compResult == VersionComparisonResult.concurrentConflict) {
          return SyncConflict<T>(
            conflictId: conflictId,
            entityType: entityType,
            localId: localId,
            remoteId: remoteId,
            conflictType: SyncConflictType.simultaneousModification,
            detectedAt: now,
            localPayload: localPayload,
            remoteDictionary: remoteDictionary,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
          );
        }

        // If local record is dirty (updated) AND remote is newer than local's baseline version
        if (storageState == StorageState.updated &&
            compResult == VersionComparisonResult.remoteNewer) {
          return SyncConflict<T>(
            conflictId: conflictId,
            entityType: entityType,
            localId: localId,
            remoteId: remoteId,
            conflictType: SyncConflictType.localUpdateRemoteUpdate,
            detectedAt: now,
            localPayload: localPayload,
            remoteDictionary: remoteDictionary,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
          );
        }
      }
    }

    return null;
  }
}
