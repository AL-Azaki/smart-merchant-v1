import 'dart:async';
import 'package:uuid/uuid.dart';

import '../../../app/config/api_client.dart';
import '../../../app/config/app_environment.dart';
import '../../storage/secure_storage/secure_storage_contract.dart';
import '../api/sync_remote_api_client.dart';
import '../dto/sync_dtos.dart';
import '../mapping/sync_entity_map.dart';
import '../mapping/revision_mapper.dart';
import '../../network/retry/sync_retry_policy.dart';
import '../../storage/app_database.dart';
import '../../../database/daos/catalog_dao.dart';
import '../../../database/daos/inventory_dao.dart';
import '../../../database/daos/sales_dao.dart';
import '../../../database/daos/catalog_sync_queries.dart';
import '../../../database/daos/inventory_sync_queries.dart';
import '../../../database/daos/sales_sync_queries.dart';

/// Sync state exposed via Riverpod.
enum SyncStatus {
  idle,
  syncing,
  success,
  offline,
  partialFailure,
  authenticationRequired,
  deviceRevoked,
  failure,
}

/// Structured sync failure providing classification for retry/escalation.
class SyncFailureInfo {
  final ApiExceptionType type;
  final String message;
  final String? entityType;
  final int? statusCode;

  const SyncFailureInfo({
    required this.type,
    required this.message,
    this.entityType,
    this.statusCode,
  });
}

/// Result of a sync cycle.
class SyncCycleResult {
  final SyncStatus status;
  final int pushedCount;
  final int pulledCount;
  final int ackedCount;
  final List<SyncFailureInfo> failures;
  final DateTime timestamp;

  const SyncCycleResult({
    required this.status,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.ackedCount = 0,
    this.failures = const [],
    required this.timestamp,
  });
}

/// The central Sync Coordinator orchestrating Push, Pull, and ACK with the real Laravel API.
///
/// Design constraints:
/// - SYNC FAILURE != ERP OPERATION FAILURE (offline-first)
/// - Push is non-destructive: failed push does not rollback local data
/// - Pull cursor is committed only AFTER successful local persistence
/// - Online Orders are NOT auto-converted to Sales Invoices
/// - Inventory projections are derived from authoritative SQLite state
/// - Bounded retry with exponential backoff
/// - Idempotency keys are stable per logical operation
/// - Revoked device → sync stops, local data preserved
class SyncCoordinator {
  final SyncRemoteApiClient _apiClient;
  final SecureStorageContract _secureStorage;
  final AppDatabase _db;
  final CatalogDao _catalogDao;
  final InventoryDao _inventoryDao;
  final SalesDao _salesDao;
  final SyncRetryPolicy _retryPolicy;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.idle;

  SyncCoordinator({
    required SyncRemoteApiClient apiClient,
    required SecureStorageContract secureStorage,
    required AppDatabase db,
    required CatalogDao catalogDao,
    required InventoryDao inventoryDao,
    required SalesDao salesDao,
    SyncRetryPolicy? retryPolicy,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage,
       _db = db,
       _catalogDao = catalogDao,
       _inventoryDao = inventoryDao,
       _salesDao = salesDao,
       _retryPolicy = retryPolicy ?? const SyncRetryPolicy();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  // ══════════════════════════════════════════════════════════
  // FULL BIDIRECTIONAL SYNC
  // ══════════════════════════════════════════════════════════

  /// Runs a complete sync cycle: Push all pending → Pull orders → ACK.
  /// Returns a structured result. Never throws — failures are classified.
  Future<SyncCycleResult> runFullSync() async {
    if (_currentStatus == SyncStatus.syncing) {
      return SyncCycleResult(
        status: SyncStatus.idle,
        timestamp: DateTime.now(),
      );
    }

    // QA SYNC SAFETY GUARD
    if (AppEnvironment.isQaBypassEnabled) {
      if (AppEnvironment.current.envName == 'production' || 
          AppEnvironment.current.baseUrl.contains('api.smartmerchant.app')) {
        return SyncCycleResult(
          status: SyncStatus.offline, // Fake offline to prevent sync
          failures: const [
            SyncFailureInfo(
              type: ApiExceptionType.unauthorized,
              message: 'SYNC BLOCKED: Cannot sync QA data to production environment.',
            )
          ],
          timestamp: DateTime.now(),
        );
      }
    }

    _setStatus(SyncStatus.syncing);
    final failures = <SyncFailureInfo>[];
    int totalPushed = 0;
    int totalPulled = 0;
    int totalAcked = 0;

    try {
      // ─── PUSH ───
      for (final entity in SyncEntityMap.pushOrder) {
        try {
          final count = await _pushEntity(entity);
          totalPushed += count;
        } on ApiException catch (e) {
          if (_handleAuthOrDeviceError(e)) return _buildResult(e, failures);
          failures.add(
            SyncFailureInfo(
              type: e.type,
              message: e.message,
              entityType: entity,
              statusCode: e.statusCode,
            ),
          );
        }
      }

      // ─── PULL ───
      try {
        final pullResult = await _pullOrders();
        totalPulled = pullResult.$1;
        totalAcked = pullResult.$2;
      } on ApiException catch (e) {
        if (_handleAuthOrDeviceError(e)) return _buildResult(e, failures);
        failures.add(
          SyncFailureInfo(
            type: e.type,
            message: e.message,
            entityType: 'orders',
            statusCode: e.statusCode,
          ),
        );
      }

      final status = failures.isEmpty
          ? SyncStatus.success
          : SyncStatus.partialFailure;
      _setStatus(status);

      // Persist last sync timestamp
      await _secureStorage.write(
        StorageKeys.lastSyncTimestamp,
        DateTime.now().toUtc().toIso8601String(),
      );

      return SyncCycleResult(
        status: status,
        pushedCount: totalPushed,
        pulledCount: totalPulled,
        ackedCount: totalAcked,
        failures: failures,
        timestamp: DateTime.now(),
      );
    } on ApiException catch (e) {
      _handleAuthOrDeviceError(e);
      return _buildResult(e, failures);
    } catch (e) {
      _setStatus(SyncStatus.failure);
      return SyncCycleResult(
        status: SyncStatus.failure,
        failures: [
          SyncFailureInfo(
            type: ApiExceptionType.unknown,
            message: e.toString(),
          ),
        ],
        timestamp: DateTime.now(),
      );
    }
  }

  bool _handleAuthOrDeviceError(ApiException e) {
    if (e.type == ApiExceptionType.unauthorized) {
      _setStatus(SyncStatus.authenticationRequired);
      return true;
    }
    if (e.type == ApiExceptionType.deviceRevoked) {
      _setStatus(SyncStatus.deviceRevoked);
      return true;
    }
    if (e.type == ApiExceptionType.noNetwork) {
      _setStatus(SyncStatus.offline);
      return true;
    }
    return false;
  }

  SyncCycleResult _buildResult(ApiException e, List<SyncFailureInfo> failures) {
    final status = e.type == ApiExceptionType.unauthorized
        ? SyncStatus.authenticationRequired
        : e.type == ApiExceptionType.deviceRevoked
        ? SyncStatus.deviceRevoked
        : e.type == ApiExceptionType.noNetwork
        ? SyncStatus.offline
        : SyncStatus.failure;
    _setStatus(status);
    return SyncCycleResult(
      status: status,
      failures: [
        ...failures,
        SyncFailureInfo(
          type: e.type,
          message: e.message,
          statusCode: e.statusCode,
        ),
      ],
      timestamp: DateTime.now(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PUSH — Flutter → Laravel
  // ══════════════════════════════════════════════════════════

  /// Pushes pending records for a single entity type. Returns count of successfully pushed items.
  Future<int> _pushEntity(String entity) async {
    final items = await _getPendingPushItems(entity);
    if (items.isEmpty) return 0;

    // Batch in chunks of 50 to avoid overwhelming the API
    int totalApplied = 0;
    for (var i = 0; i < items.length; i += 50) {
      final batch = items.sublist(i, (i + 50).clamp(0, items.length));
      final request = PushSyncRequestDto(entity: entity, items: batch);
      final response = await _apiClient.push(request);

      for (final result in response.results) {
        if (result.isApplied || result.isIdempotent) {
          await _markSynced(entity, result.id);
          totalApplied++;
        } else if (result.isStale) {
          // Stale revision — do not retry forever. Mark as synced to prevent infinite loop.
          // The server already has a newer version. Flutter's local data is still authoritative
          // for local operations; the server projection is acceptably ahead.
          await _markSynced(entity, result.id);
        }
        // 'rejected' / 'error' — leave as pending for next sync cycle
      }
    }
    return totalApplied;
  }

  /// Queries pending push items for a given entity from SQLite.
  Future<List<Map<String, dynamic>>> _getPendingPushItems(String entity) async {
    switch (entity) {
      case 'categories':
        return _queryPendingCategories();
      case 'brands':
        return _queryPendingBrands();
      case 'units':
        return _queryPendingUnits();
      case 'products':
        return _queryPendingProducts();
      case 'product_units':
        return _queryPendingProductUnits();
      case 'product_images':
        return _queryPendingProductImages();
      case 'inventory_projections':
        return _queryInventoryProjections();
      default:
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> _queryPendingCategories() async {
    final rows = await _catalogDao.listPendingSyncCategories();
    return rows
        .map(
          (c) => {
            'id': c.id,
            'category_name': c.categoryName,
            'category_code': c.categoryCode,
            'parent_id': c.parentId,
            'description': c.description,
            'image_path': c.imagePath,
            'sort_order': c.sortOrder,
            'is_active': c.isActive,
            'revision': RevisionMapper.toServerRevision(c.version),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryPendingBrands() async {
    final rows = await _catalogDao.listPendingSyncBrands();
    return rows
        .map(
          (b) => {
            'id': b.id,
            'brand_name': b.brandName,
            'description': b.description,
            'is_active': b.isActive,
            'revision': RevisionMapper.toServerRevision(b.version),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryPendingUnits() async {
    final rows = await _catalogDao.listPendingSyncUnits();
    return rows
        .map(
          (u) => {
            'id': u.id,
            'unit_name': u.unitName,
            'unit_code': u.unitSymbol,
            'is_active': u.isActive,
            'revision': RevisionMapper.toServerRevision(u.version),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryPendingProducts() async {
    final rows = await _catalogDao.listPendingSyncProducts();
    return rows
        .map(
          (p) => {
            'id': p.id,
            'product_code': p.productCode,
            'product_name': p.productName,
            'product_type': p.productType,
            'category_id': p.categoryId,
            'brand_id': p.brandId,
            'description': p.description,
            'is_active': p.isActive,
            'revision': RevisionMapper.toServerRevision(p.version),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryPendingProductUnits() async {
    final rows = await _catalogDao.listPendingSyncProductUnits();
    return rows
        .map(
          (pu) => {
            'id': pu.id,
            'product_id': pu.productId,
            'unit_id': pu.unitId,
            'barcode': pu.barcode,
            'sku': pu.sku,
            'is_base_unit': pu.isBaseUnit,
            'conversion_factor': pu.conversionFactor,
            'selling_price': pu.sellingPrice,
            'cost_price': pu.purchasePrice,
            'is_active': pu.isActive,
            'revision': RevisionMapper.toServerRevision(pu.version),
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _queryPendingProductImages() async {
    final rows = await _catalogDao.listPendingSyncProductImages();
    return rows
        .map(
          (pi) => {
            'id': pi.id,
            'product_id': pi.productId,
            'image_url': pi.imagePath,
            'is_primary': pi.isPrimary,
            'revision': RevisionMapper.toServerRevision(pi.version),
          },
        )
        .toList();
  }

  /// Derives inventory availability projections from the authoritative SQLite inventory state.
  /// This is a PROJECTION — we do not push the inventory ledger, only current quantities.
  Future<List<Map<String, dynamic>>> _queryInventoryProjections() async {
    final rows = await _inventoryDao.listPendingSyncInventories();
    return rows
        .map(
          (inv) => {
            'id': inv.id,
            'product_unit_id': inv.productUnitId,
            'branch_id': inv
                .warehouseId, // Maps warehouse to branch context for Laravel projection
            'quantity': inv.quantity,
            'revision': RevisionMapper.toServerRevision(inv.version),
          },
        )
        .toList();
  }

  /// Marks a record as synced after successful push.
  Future<void> _markSynced(String entity, String id) async {
    switch (entity) {
      case 'categories':
        await _catalogDao.markCategorySynced(id);
      case 'brands':
        await _catalogDao.markBrandSynced(id);
      case 'units':
        await _catalogDao.markUnitSynced(id);
      case 'products':
        await _catalogDao.markProductSynced(id);
      case 'product_units':
        await _catalogDao.markProductUnitSynced(id);
      case 'product_images':
        await _catalogDao.markProductImageSynced(id);
      case 'inventory_projections':
        await _inventoryDao.markInventorySynced(id);
    }
  }

  // ══════════════════════════════════════════════════════════
  // PULL — Laravel → Flutter (Online Orders)
  // ══════════════════════════════════════════════════════════

  /// Pulls Online Orders incrementally from cursor. Returns (pulled, acked).
  /// CRITICAL: Cursor is only advanced AFTER successful local persistence.
  /// CRITICAL: Pulling an order does NOT create a SalesInvoice, deduct inventory, or create accounting entries.
  Future<(int, int)> _pullOrders() async {
    final cursorStr = await _secureStorage.read(StorageKeys.lastPullCursor);
    int cursor = int.tryParse(cursorStr ?? '0') ?? 0;
    int totalPulled = 0;
    int totalAcked = 0;

    bool hasMore = true;
    while (hasMore) {
      final request = PullSyncRequestDto(
        entity: 'orders',
        cursor: cursor,
        limit: 50,
      );
      final response = await _apiClient.pull(request);

      if (!response.hasItems) {
        hasMore = false;
        break;
      }

      // Persist all pulled orders in a single transaction
      final persistedItems = <AckItemDto>[];

      await _db.transaction(() async {
        for (final orderJson in response.items) {
          final orderId = orderJson['id']?.toString();
          if (orderId == null) continue;

          final businessId = orderJson['business_id']?.toString() ?? '';
          final revision = orderJson['revision'] as int? ?? 1;

          // Duplicate protection: check if order already exists
          final existing = await _salesDao.getOrderById(orderId, businessId);
          if (existing != null) {
            // Already persisted — still ACK to prevent re-delivery
            persistedItems.add(AckItemDto(id: orderId, revision: revision));
            continue;
          }

          // Persist the Online Order locally (WITHOUT creating SalesInvoice/Inventory/Accounting)
          await _salesDao.insertOnlineOrder(orderJson);
          persistedItems.add(AckItemDto(id: orderId, revision: revision));
          totalPulled++;
        }
      });

      // Commit cursor ONLY after transaction succeeds
      cursor = response.nextCursor;
      await _secureStorage.write(StorageKeys.lastPullCursor, cursor.toString());

      // ACK after successful persistence
      if (persistedItems.isNotEmpty) {
        final idempotencyKey = _generateIdempotencyKey('ack_orders', cursor);
        final ackRequest = AckSyncRequestDto(
          entity: 'orders',
          idempotencyKey: idempotencyKey,
          items: persistedItems,
        );

        try {
          await _apiClient.ack(ackRequest);
          totalAcked += persistedItems.length;
        } on ApiException {
          // ACK failure is non-fatal — orders are safely persisted locally.
          // Next sync cycle will re-ACK with the same idempotency key (safe replay).
        }
      }

      // If we got fewer than limit, we've reached the end
      if (response.items.length < 50) {
        hasMore = false;
      }
    }

    return (totalPulled, totalAcked);
  }

  // ══════════════════════════════════════════════════════════
  // IDEMPOTENCY
  // ══════════════════════════════════════════════════════════

  /// Generates a stable idempotency key for a logical operation.
  /// The same key is reused on retry for the same logical batch.
  String _generateIdempotencyKey(String operation, int cursor) {
    return '${operation}_cursor_$cursor';
  }

  // ══════════════════════════════════════════════════════════
  // RETRY
  // ══════════════════════════════════════════════════════════

  /// Runs a sync operation with bounded exponential backoff retry.
  Future<T> withRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } on ApiException catch (e) {
        attempt++;
        if (!_retryPolicy.shouldRetry(attempt, statusCode: e.statusCode)) {
          rethrow;
        }
        final delay = _retryPolicy.calculateNextDelay(attempt);
        await Future.delayed(delay);
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════

  void dispose() {
    _statusController.close();
  }
}
