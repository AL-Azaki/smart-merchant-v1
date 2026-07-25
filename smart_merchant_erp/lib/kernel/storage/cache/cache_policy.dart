import 'package:equatable/equatable.dart';

/// Classifies the caching behavior and retention boundaries for cached resources
/// across all modules of the Smart Merchant ERP system.
enum CacheType {
  /// Permanent local cache (e.g., downloaded master catalogs, localized fiscal rules) that persists across restarts.
  permanent,

  /// Session-scoped cache (e.g., current branch context, cashier permissions) cleared upon logout.
  session,

  /// Transient temporary cache (e.g., API response buffers, recent product queries) evicted after duration.
  temporary,

  /// Reference data cache (e.g., country codes, unit conversion rates) updated periodically.
  reference,

  /// Metadata cache (e.g., sync status indicators, last fetch timestamps).
  metadata,
}

/// Metadata governing cache freshness, versioning, and validation checks.
class StorageMetadata extends Equatable {
  /// Timestamp indicating when the item or batch was last written to cache.
  final DateTime lastUpdated;

  /// Optional ETag or hash from the remote server for conditional validation without redownloading.
  final String? etag;

  /// Schema or contract version of the stored data structure.
  final int schemaVersion;

  /// Optional checksum ensuring data integrity during local read/write cycles.
  final String? checksum;

  const StorageMetadata({
    required this.lastUpdated,
    this.etag,
    this.schemaVersion = 1,
    this.checksum,
  });

  /// Whether the cache has exceeded [expirationDuration] given a current reference time.
  bool isExpired(Duration? expirationDuration, [DateTime? currentTime]) {
    if (expirationDuration == null) {
      return false;
    }
    final now = currentTime ?? DateTime.now();
    return now.difference(lastUpdated) > expirationDuration;
  }

  @override
  List<Object?> get props => [lastUpdated, etag, schemaVersion, checksum];
}

/// Centralized caching policy governing expiration, refresh, and invalidation rules
/// without implementing network synchronization directly.
class CachePolicy extends Equatable {
  /// The structural cache classification.
  final CacheType type;

  /// Maximum duration the cache remains valid before requiring refresh.
  final Duration? maxAge;

  /// Whether stale cache can be served gracefully if refreshing fails or device is offline.
  final bool serveStaleIfOffline;

  /// Whether cache must be explicitly invalidated upon specific domain events or updates.
  final bool requireEventDrivenInvalidation;

  const CachePolicy({
    required this.type,
    this.maxAge,
    this.serveStaleIfOffline = true,
    this.requireEventDrivenInvalidation = false,
  });

  /// Standard policy for Permanent Cache.
  factory CachePolicy.permanent() => const CachePolicy(
    type: CacheType.permanent,
    requireEventDrivenInvalidation: true,
  );

  /// Standard policy for Session Cache.
  factory CachePolicy.session({Duration? timeout}) => CachePolicy(
    type: CacheType.session,
    maxAge: timeout,
    serveStaleIfOffline: false,
    requireEventDrivenInvalidation: true,
  );

  /// Standard policy for Temporary Cache.
  factory CachePolicy.temporary({
    Duration duration = const Duration(minutes: 30),
  }) => CachePolicy(type: CacheType.temporary, maxAge: duration);

  /// Standard policy for Reference Data.
  factory CachePolicy.reference({
    Duration duration = const Duration(days: 7),
  }) => CachePolicy(type: CacheType.reference, maxAge: duration);

  @override
  List<Object?> get props => [
    type,
    maxAge,
    serveStaleIfOffline,
    requireEventDrivenInvalidation,
  ];
}

/// Base contract for any concrete caching implementation across the kernel or modules.
abstract interface class CacheProvider {
  Future<T?> get<T>(String key);
  Future<void> put<T>(
    String key,
    T value, {
    CachePolicy? policy,
    StorageMetadata? metadata,
  });
  Future<void> invalidate(String key);
  Future<void> clearType(CacheType type);
  Future<void> clearAll();
}
