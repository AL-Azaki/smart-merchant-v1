import 'package:equatable/equatable.dart';

/// Captures versioning, revision numbers, timestamps, and checksum indicators
/// used to detect changes and concurrency conflicts between local offline records
/// and remote cloud server records.
class SyncVersionMetadata extends Equatable {
  /// Monotonically increasing revision integer (e.g., `1`, `2`, `3`).
  final int versionNumber;

  /// UTC timestamp indicating when this revision was produced locally or on the server.
  final DateTime timestamp;

  /// Optional HTTP `ETag` string returned by the Laravel cloud backend.
  final String? etag;

  /// Cryptographic hash or byte checksum validating payload integrity across network transmission.
  final String? checksum;

  /// Optional vector clock mapping node/device identifiers to their observed logical clocks
  /// for advanced distributed multi-master synchronization.
  final Map<String, int>? vectorClock;

  const SyncVersionMetadata({
    required this.versionNumber,
    required this.timestamp,
    this.etag,
    this.checksum,
    this.vectorClock,
  });

  /// Creates a copy of this version metadata with updated revision attributes.
  SyncVersionMetadata copyWith({
    int? versionNumber,
    DateTime? timestamp,
    String? etag,
    String? checksum,
    Map<String, int>? vectorClock,
  }) {
    return SyncVersionMetadata(
      versionNumber: versionNumber ?? this.versionNumber,
      timestamp: timestamp ?? this.timestamp,
      etag: etag ?? this.etag,
      checksum: checksum ?? this.checksum,
      vectorClock: vectorClock ?? this.vectorClock,
    );
  }

  @override
  List<Object?> get props => [
    versionNumber,
    timestamp,
    etag,
    checksum,
    vectorClock,
  ];
}

/// Represents the outcome of comparing two synchronization version records.
enum VersionComparisonResult {
  /// Both local and remote versions are identical (`versionNumber`, `timestamp`, or `checksum` match).
  equal,

  /// The local record has a higher version or more recent timestamp than the remote server.
  localNewer,

  /// The remote server record has a higher version or more recent timestamp than the local device.
  remoteNewer,

  /// Both local and remote records have diverged concurrently (e.g., modified simultaneously on different devices).
  concurrentConflict,
}

/// Evaluates differences between local and remote version metadata to guide conflict detection and merge decisions.
class VersionComparator {
  /// Compares [local] version metadata against [remote] version metadata.
  VersionComparisonResult compare(
    SyncVersionMetadata local,
    SyncVersionMetadata remote,
  ) {
    // 1. Check strict revision number if both are non-zero
    if (local.versionNumber > 0 && remote.versionNumber > 0) {
      if (local.versionNumber == remote.versionNumber) {
        // If versions match, check checksum or etag for divergence
        if (local.checksum != null &&
            remote.checksum != null &&
            local.checksum != remote.checksum) {
          return VersionComparisonResult.concurrentConflict;
        }
        return VersionComparisonResult.equal;
      }
      if (local.versionNumber > remote.versionNumber) {
        return VersionComparisonResult.localNewer;
      }
      return VersionComparisonResult.remoteNewer;
    }

    // 2. Fallback to physical or logical timestamp comparison with tolerance window (2 seconds)
    final differenceMillis = local.timestamp
        .difference(remote.timestamp)
        .inMilliseconds;
    if (differenceMillis.abs() <= 2000) {
      if (local.checksum != null &&
          remote.checksum != null &&
          local.checksum != remote.checksum) {
        return VersionComparisonResult.concurrentConflict;
      }
      return VersionComparisonResult.equal;
    }

    if (differenceMillis > 2000) {
      return VersionComparisonResult.localNewer;
    }

    return VersionComparisonResult.remoteNewer;
  }
}
