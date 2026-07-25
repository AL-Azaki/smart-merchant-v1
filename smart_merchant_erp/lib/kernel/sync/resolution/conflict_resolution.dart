import 'dart:async';
import 'package:equatable/equatable.dart';
import 'conflict_detection.dart';
import 'merge_engine.dart';

/// Enumeration of standardized conflict resolution policies supported across the ERP system.
enum SyncResolutionPolicy {
  /// Always discard remote server changes and enforce the local client record (`Client Wins`).
  clientWins,

  /// Always discard local client changes and overwrite with the remote server record (`Server Wins`).
  serverWins,

  /// Compare modification timestamps (`timestamp` / `lastModified`) and select the most recent record (`LWW`).
  lastWriteWins,

  /// Perform a field-level dictionary merge combining non-conflicting attributes (`Merge`).
  merge,

  /// Quarantine the conflicting record for manual intervention by a branch manager or auditor (`Manual`).
  manualResolution,

  /// Delegate resolution to a domain-registered custom strategy (`Custom`).
  customPolicy,
}

/// Encapsulates the outcome of executing a conflict resolution strategy against a [SyncConflict].
class SyncResolutionResult<T> extends Equatable {
  /// The final reconciled payload (`T` or dictionary) after resolution.
  final dynamic resolvedPayload;

  /// The policy strategy that produced this resolution.
  final SyncResolutionPolicy policyApplied;

  /// Whether the resolved payload needs to be uploaded back to the cloud server.
  final bool requiresRemoteUpdate;

  /// Whether the resolved payload needs to be persisted locally to SQLite storage.
  final bool requiresLocalUpdate;

  /// Whether the conflict is considered fully resolved or quarantined for manual handling.
  final bool isResolved;

  /// Human-readable explanation of why this resolution decision was reached.
  final String resolutionNotes;

  const SyncResolutionResult({
    required this.resolvedPayload,
    required this.policyApplied,
    required this.requiresRemoteUpdate,
    required this.requiresLocalUpdate,
    required this.isResolved,
    required this.resolutionNotes,
  });

  @override
  List<Object?> get props => [
    resolvedPayload,
    policyApplied,
    requiresRemoteUpdate,
    requiresLocalUpdate,
    isResolved,
    resolutionNotes,
  ];
}

/// Reusable contract for concrete conflict resolution strategies.
abstract interface class SyncResolutionStrategy<T> {
  /// The policy identifier associated with this strategy.
  SyncResolutionPolicy get policy;

  /// Resolves the provided synchronization conflict.
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict);
}

/// Enforces [SyncResolutionPolicy.clientWins] by preserving local state and scheduling cloud upload.
class ClientWinsStrategy<T> implements SyncResolutionStrategy<T> {
  @override
  SyncResolutionPolicy get policy => SyncResolutionPolicy.clientWins;

  @override
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict) async {
    return SyncResolutionResult<T>(
      resolvedPayload: conflict.localPayload,
      policyApplied: policy,
      requiresRemoteUpdate: true,
      requiresLocalUpdate: false,
      isResolved: true,
      resolutionNotes:
          'ClientWins policy applied: local payload preserved over remote changes.',
    );
  }
}

/// Enforces [SyncResolutionPolicy.serverWins] by overwriting local state with the remote dictionary.
class ServerWinsStrategy<T> implements SyncResolutionStrategy<T> {
  @override
  SyncResolutionPolicy get policy => SyncResolutionPolicy.serverWins;

  @override
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict) async {
    return SyncResolutionResult<T>(
      resolvedPayload: conflict.remoteDictionary,
      policyApplied: policy,
      requiresRemoteUpdate: false,
      requiresLocalUpdate: true,
      isResolved: true,
      resolutionNotes:
          'ServerWins policy applied: remote dictionary selected over local state.',
    );
  }
}

/// Enforces [SyncResolutionPolicy.lastWriteWins] based on physical version timestamps.
class LastWriteWinsStrategy<T> implements SyncResolutionStrategy<T> {
  @override
  SyncResolutionPolicy get policy => SyncResolutionPolicy.lastWriteWins;

  @override
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict) async {
    final localTime = conflict.localVersion?.timestamp ?? conflict.detectedAt;
    final remoteTime = conflict.remoteVersion?.timestamp ?? conflict.detectedAt;

    if (localTime.isAfter(remoteTime)) {
      return SyncResolutionResult<T>(
        resolvedPayload: conflict.localPayload,
        policyApplied: policy,
        requiresRemoteUpdate: true,
        requiresLocalUpdate: false,
        isResolved: true,
        resolutionNotes:
            'LastWriteWins applied: local timestamp ($localTime) is newer than remote ($remoteTime).',
      );
    } else {
      return SyncResolutionResult<T>(
        resolvedPayload: conflict.remoteDictionary,
        policyApplied: policy,
        requiresRemoteUpdate: false,
        requiresLocalUpdate: true,
        isResolved: true,
        resolutionNotes:
            'LastWriteWins applied: remote timestamp ($remoteTime) is newer or equal to local ($localTime).',
      );
    }
  }
}

/// Enforces [SyncResolutionPolicy.merge] using the [SyncMergeEngine] to combine dictionaries.
class MergeStrategy<T> implements SyncResolutionStrategy<T> {
  final SyncMergeEngine _mergeEngine;

  MergeStrategy({SyncMergeEngine? mergeEngine})
    : _mergeEngine = mergeEngine ?? SyncMergeEngine();

  @override
  SyncResolutionPolicy get policy => SyncResolutionPolicy.merge;

  @override
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict) async {
    final localMap = conflict.localPayload is Map<String, dynamic>
        ? conflict.localPayload as Map<String, dynamic>
        : <String, dynamic>{};
    final remoteMap = conflict.remoteDictionary ?? <String, dynamic>{};

    final merged = _mergeEngine.mergeDictionaries(
      localMap: localMap,
      remoteMap: remoteMap,
    );

    return SyncResolutionResult<T>(
      resolvedPayload: merged,
      policyApplied: policy,
      requiresRemoteUpdate: true,
      requiresLocalUpdate: true,
      isResolved: true,
      resolutionNotes:
          'MergeStrategy applied: field-level dictionary merge completed.',
    );
  }
}

/// Enforces [SyncResolutionPolicy.manualResolution] by quarantining the conflict without overwriting.
class ManualResolutionStrategy<T> implements SyncResolutionStrategy<T> {
  @override
  SyncResolutionPolicy get policy => SyncResolutionPolicy.manualResolution;

  @override
  Future<SyncResolutionResult<T>> resolve(SyncConflict<T> conflict) async {
    return SyncResolutionResult<T>(
      resolvedPayload: conflict.localPayload,
      policyApplied: policy,
      requiresRemoteUpdate: false,
      requiresLocalUpdate: false,
      isResolved: false,
      resolutionNotes:
          'ManualResolution policy applied: conflict quarantined for auditor review.',
    );
  }
}

/// Central registry allowing configuration of specific conflict resolution policies per entity type.
class SyncResolutionPolicyRegistry {
  final Map<String, SyncResolutionStrategy<dynamic>> _entityStrategies = {};
  SyncResolutionStrategy<dynamic> _defaultStrategy =
      ServerWinsStrategy<dynamic>();

  /// Sets the default fallback strategy used across entity types.
  void setDefaultStrategy(SyncResolutionStrategy<dynamic> strategy) {
    _defaultStrategy = strategy;
  }

  /// Registers a specific resolution strategy for a given entity type (`SalesInvoice`, `Customer`).
  void registerStrategy(
    String entityType,
    SyncResolutionStrategy<dynamic> strategy,
  ) {
    _entityStrategies[entityType] = strategy;
  }

  /// Retrieves the resolution strategy configured for the specified entity type.
  SyncResolutionStrategy<dynamic> getStrategyForEntity(String entityType) {
    return _entityStrategies[entityType] ?? _defaultStrategy;
  }
}
