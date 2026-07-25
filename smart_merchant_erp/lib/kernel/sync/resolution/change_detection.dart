import 'package:equatable/equatable.dart';
import '../../storage/storage_state.dart';
import 'version_management.dart';

/// Categorizes the nature of structural or version changes detected between
/// local storage state and remote server state during synchronization cycles.
enum SyncChangeType {
  /// Record was created locally (`StorageState.created`) and does not exist on the server yet.
  created,

  /// Record was modified locally (`StorageState.updated`) since last sync.
  updated,

  /// Record was marked soft-deleted locally (`StorageState.deleted`).
  deleted,

  /// Record was restored from soft-deleted state back to active state.
  restored,

  /// Revision numbers (`versionNumber`) differ between local and remote records.
  versionMismatch,

  /// Last modification timestamps (`lastModified`) diverged significantly without revision bump.
  timestampMismatch,

  /// ETag or checksum validation detected a metadata divergence.
  metadataConflict,

  /// Both local and remote records are synchronized and structurally identical.
  unchanged,
}

/// Immutable diagnostic summary describing a detected change between local and remote records.
class SyncChangeSummary extends Equatable {
  /// Classification of the detected change.
  final SyncChangeType changeType;

  /// Client-side unique record identifier (`localUuid`).
  final String localId;

  /// Optional server-assigned unique identifier (`remoteId`).
  final String? remoteId;

  /// Local version metadata when the change was evaluated.
  final SyncVersionMetadata? localVersion;

  /// Remote version metadata when the change was evaluated.
  final SyncVersionMetadata? remoteVersion;

  /// Timestamp indicating when the change detection scan executed.
  final DateTime detectedAt;

  /// Human-readable explanation of the detected change.
  final String description;

  const SyncChangeSummary({
    required this.changeType,
    required this.localId,
    required this.detectedAt,
    required this.description,
    this.remoteId,
    this.localVersion,
    this.remoteVersion,
  });

  @override
  List<Object?> get props => [
    changeType,
    localId,
    remoteId,
    localVersion,
    remoteVersion,
    detectedAt,
    description,
  ];
}

/// Reusable change detection engine capable of evaluating local offline records
/// against remote server payloads without coupling to module domain entities.
class SyncChangeDetector {
  final VersionComparator _comparator;

  SyncChangeDetector({VersionComparator? comparator})
    : _comparator = comparator ?? VersionComparator();

  /// Evaluates local storage lifecycle state and version metadata against remote server attributes.
  SyncChangeSummary detectChange({
    required String localId,
    required StorageState storageState,
    String? remoteId,
    SyncVersionMetadata? localVersion,
    SyncVersionMetadata? remoteVersion,
  }) {
    final now = DateTime.now();

    // 1. Check local lifecycle status first
    if (storageState == StorageState.created) {
      return SyncChangeSummary(
        changeType: SyncChangeType.created,
        localId: localId,
        remoteId: remoteId,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
        detectedAt: now,
        description:
            'Record created locally and pending initial upload to cloud API.',
      );
    }

    if (storageState == StorageState.deleted) {
      return SyncChangeSummary(
        changeType: SyncChangeType.deleted,
        localId: localId,
        remoteId: remoteId,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
        detectedAt: now,
        description:
            'Record marked soft-deleted locally and pending remote deletion acknowledgment.',
      );
    }

    if (storageState == StorageState.updated) {
      // Check if remote version is known
      if (remoteVersion != null && localVersion != null) {
        final compResult = _comparator.compare(localVersion, remoteVersion);
        if (compResult == VersionComparisonResult.concurrentConflict) {
          return SyncChangeSummary(
            changeType: SyncChangeType.metadataConflict,
            localId: localId,
            remoteId: remoteId,
            localVersion: localVersion,
            remoteVersion: remoteVersion,
            detectedAt: now,
            description:
                'Concurrent modification or ETag mismatch detected between local and remote records.',
          );
        }
      }

      return SyncChangeSummary(
        changeType: SyncChangeType.updated,
        localId: localId,
        remoteId: remoteId,
        localVersion: localVersion,
        remoteVersion: remoteVersion,
        detectedAt: now,
        description: 'Record updated locally since last sync acknowledgment.',
      );
    }

    // 2. If locally synced/idle, evaluate version differences if remote payload arrived
    if (localVersion != null && remoteVersion != null) {
      final compResult = _comparator.compare(localVersion, remoteVersion);
      if (compResult == VersionComparisonResult.remoteNewer ||
          compResult == VersionComparisonResult.localNewer) {
        return SyncChangeSummary(
          changeType: SyncChangeType.versionMismatch,
          localId: localId,
          remoteId: remoteId,
          localVersion: localVersion,
          remoteVersion: remoteVersion,
          detectedAt: now,
          description:
              'Revision or timestamp divergence detected between local and remote records.',
        );
      }
      if (compResult == VersionComparisonResult.concurrentConflict) {
        return SyncChangeSummary(
          changeType: SyncChangeType.metadataConflict,
          localId: localId,
          remoteId: remoteId,
          localVersion: localVersion,
          remoteVersion: remoteVersion,
          detectedAt: now,
          description: 'Checksum or ETag conflict detected.',
        );
      }
    }

    return SyncChangeSummary(
      changeType: SyncChangeType.unchanged,
      localId: localId,
      remoteId: remoteId,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      detectedAt: now,
      description:
          'Local and remote records are identical and fully synchronized.',
    );
  }
}
