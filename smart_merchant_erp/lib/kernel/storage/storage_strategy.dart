import 'package:equatable/equatable.dart';

/// Categorizes the architectural purpose and retention requirements of local data across
/// all modules of the Smart Merchant ERP system.
enum StorageStrategy {
  /// Core reference entities such as Customers, Products, Categories, and Units.
  /// Rarely deleted; updated via background delta sync.
  masterData,

  /// Core financial and operational transactions such as Sales Invoices, Receipts, and Stock adjustments.
  /// Requires permanent persistence and strict offline-first durability.
  transactionalData,

  /// System operational configuration such as device settings, printer profiles, and UI layout preferences.
  configurationData,

  /// Short-lived temporary storage such as product search history or transient filter selections.
  temporaryCache,

  /// System tracking info such as schema versions, last sync timestamps, and migration logs.
  applicationMetadata,

  /// Active user authentication state, RBAC permissions, and tokens.
  userSession,

  /// Enterprise fiscal rules, branch currency settings, and tax policies (ZATCA mandates).
  businessSettings,
}

/// Centralized storage policy governing persistence guarantees, expiration rules, and
/// deletion protections for local data across all ERP modules.
class StoragePolicy extends Equatable {
  /// Whether this data must be retained on disk permanently until explicit sync confirmation or legal archiving.
  final bool requiresPermanentPersistence;

  /// Whether this data is allowed to expire and be automatically purged by maintenance routines.
  final bool canExpire;

  /// Optional duration after which the data is considered stale or eligible for eviction.
  final Duration? expirationDuration;

  /// Whether automatic cleanup jobs or cache eviction algorithms are strictly forbidden from deleting this record.
  final bool preventAutomaticDeletion;

  /// Whether this data must always be stored locally (Offline-First mandatory).
  final bool mustBeStoredLocally;

  /// The overarching classification strategy governing this policy.
  final StorageStrategy strategy;

  const StoragePolicy({
    required this.strategy,
    this.requiresPermanentPersistence = false,
    this.canExpire = false,
    this.expirationDuration,
    this.preventAutomaticDeletion = false,
    this.mustBeStoredLocally = true,
  });

  /// Standard policy for Master Data (Customers, Products, Categories).
  /// Must be stored locally, protected from automatic deletion, and retained until delta sync updates.
  factory StoragePolicy.masterData() => const StoragePolicy(
    strategy: StorageStrategy.masterData,
    requiresPermanentPersistence: true,
    preventAutomaticDeletion: true,
  );

  /// Standard policy for Transactional Data (Invoices, Ledger Entries).
  /// Permanent persistence required, strict local storage, absolute protection from auto deletion.
  factory StoragePolicy.transactionalData() => const StoragePolicy(
    strategy: StorageStrategy.transactionalData,
    requiresPermanentPersistence: true,
    preventAutomaticDeletion: true,
  );

  /// Standard policy for Configuration and Business Settings.
  factory StoragePolicy.configurationData({
    StorageStrategy? strategyOverride,
  }) => StoragePolicy(
    strategy: strategyOverride ?? StorageStrategy.configurationData,
    requiresPermanentPersistence: true,
    preventAutomaticDeletion: true,
  );

  /// Standard policy for User Sessions.
  factory StoragePolicy.userSession({Duration? sessionTimeout}) =>
      StoragePolicy(
        strategy: StorageStrategy.userSession,
        canExpire: sessionTimeout != null,
        expirationDuration: sessionTimeout,
      );

  /// Standard policy for Temporary and Reference Caches.
  factory StoragePolicy.temporaryCache({
    Duration expiration = const Duration(hours: 12),
  }) => StoragePolicy(
    strategy: StorageStrategy.temporaryCache,
    canExpire: true,
    expirationDuration: expiration,
    mustBeStoredLocally: false,
  );

  /// Standard policy for Application Metadata.
  factory StoragePolicy.metadata() => const StoragePolicy(
    strategy: StorageStrategy.applicationMetadata,
    requiresPermanentPersistence: true,
    preventAutomaticDeletion: true,
  );

  @override
  List<Object?> get props => [
    strategy,
    requiresPermanentPersistence,
    canExpire,
    expirationDuration,
    preventAutomaticDeletion,
    mustBeStoredLocally,
  ];
}
