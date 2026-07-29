import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../enums/inventory_movement_direction.dart';
import '../enums/inventory_reference_type.dart';
import '../enums/inventory_transaction_status.dart';
import '../enums/inventory_transaction_type.dart';
import '../enums/inventory_transfer_status.dart';
import '../enums/stock_count_status.dart';
import '../tables/catalog/products_table.dart';
import '../tables/catalog/product_units_table.dart';
import '../tables/catalog/product_variants_table.dart';
import '../tables/core/branches_table.dart';
import '../tables/inventory/inventories_table.dart';
import '../tables/inventory/inventory_transaction_lines_table.dart';
import '../tables/inventory/inventory_transactions_table.dart';
import '../tables/inventory/inventory_transfer_items_table.dart';
import '../tables/inventory/inventory_transfers_table.dart';
import '../tables/inventory/stock_counts_table.dart';
import '../tables/inventory/stock_count_items_table.dart';
import '../tables/inventory/warehouses_table.dart';
import 'dao_exceptions.dart';

part 'inventory_dao.g.dart';

/// Filter DTO for [Warehouses] queries.
class WarehouseFilter {
  final String businessId;
  final String? branchId;
  final bool? isActive;
  final bool? isDefault;
  final bool includeDeleted;
  final String? searchQuery;

  const WarehouseFilter({
    required this.businessId,
    this.branchId,
    this.isActive,
    this.isDefault,
    this.includeDeleted = false,
    this.searchQuery,
  });
}

/// Filter DTO for [Inventories] queries.
class InventoryFilter {
  final String businessId;
  final String? warehouseId;
  final String? productUnitId;
  final bool lowStockOnly;
  final bool includeDeleted;

  const InventoryFilter({
    required this.businessId,
    this.warehouseId,
    this.productUnitId,
    this.lowStockOnly = false,
    this.includeDeleted = false,
  });
}

/// Filter DTO for [InventoryTransactions] queries.
class InventoryTransactionFilter {
  final String businessId;
  final String? branchId;
  final String? warehouseId;
  final InventoryTransactionType? transactionType;
  final InventoryMovementDirection? movementDirection;
  final InventoryTransactionStatus? status;
  final InventoryReferenceType? referenceType;
  final String? referenceId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const InventoryTransactionFilter({
    required this.businessId,
    this.branchId,
    this.warehouseId,
    this.transactionType,
    this.movementDirection,
    this.status,
    this.referenceType,
    this.referenceId,
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
  });
}

/// Filter DTO for [InventoryTransfers] queries.
class InventoryTransferFilter {
  final String businessId;
  final String? fromWarehouseId;
  final String? toWarehouseId;
  final InventoryTransferStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const InventoryTransferFilter({
    required this.businessId,
    this.fromWarehouseId,
    this.toWarehouseId,
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 20,
    this.offset = 0,
  });
}

/// Composite DTO combining an [InventoryTransaction] with its [InventoryTransactionLine]s.
class InventoryTransactionWithLines {
  final InventoryTransaction transaction;
  final List<InventoryTransactionLine> lines;

  const InventoryTransactionWithLines({
    required this.transaction,
    required this.lines,
  });
}

/// Composite DTO combining an [InventoryTransfer] with its [InventoryTransferItem]s.
class InventoryTransferWithItems {
  final InventoryTransfer transfer;
  final List<InventoryTransferItem> items;

  const InventoryTransferWithItems({
    required this.transfer,
    required this.items,
  });
}

/// Detailed composite view joining [Inventory] with [ProductUnit], [Product], and associated [ProductVariant]s.
class StockBalanceView {
  final Inventory inventory;
  final ProductUnit productUnit;
  final Product product;
  final List<ProductVariant> variants;

  const StockBalanceView({
    required this.inventory,
    required this.productUnit,
    required this.product,
    this.variants = const [],
  });
}

/// Module-Driven DAO for Domain: Inventory (Phase 03).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), branch/warehouse scoping, soft-delete rules (`deletedAt`),
/// and atomic transactional persistence for:
/// [Warehouses], [Inventories], [InventoryTransactions], [InventoryTransactionLines],
/// [InventoryTransfers], and [InventoryTransferItems].
@DriftAccessor(
  tables: [
    Warehouses,
    Inventories,
    InventoryTransactions,
    InventoryTransactionLines,
    InventoryTransfers,
    InventoryTransferItems,
    StockCounts,
    StockCountItems,
    Products,
    ProductVariants,
    ProductUnits,
    Branches,
  ],
)
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // ============================================================================
  // 1. WAREHOUSES OPERATIONS (Tenant & Branch Scoped, Soft Delete Support)
  // ============================================================================

  /// Retrieves a warehouse by ID within a business.
  Future<Warehouse?> getWarehouseById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getWarehouseById requires businessId.',
      );
    }
    final query = select(warehouses)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves the default active warehouse for a specific branch.
  Future<Warehouse?> getDefaultWarehouseByBranch(
    String businessId,
    String branchId,
  ) {
    if (businessId.trim().isEmpty || branchId.trim().isEmpty) {
      throw const TenantScopingException(
        'getDefaultWarehouseByBranch requires businessId and branchId.',
      );
    }
    return (select(warehouses)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.branchId.equals(branchId) &
              tbl.isDefault.equals(true) &
              tbl.isActive.equals(true) &
              tbl.deletedAt.isNull(),
        ))
        .getSingleOrNull();
  }

  /// Lists warehouses based on the provided filter.
  Future<List<Warehouse>> listWarehouses(WarehouseFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listWarehouses requires businessId.');
    }
    final query = select(warehouses)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (filter.isDefault != null) {
      query.where((tbl) => tbl.isDefault.equals(filter.isDefault!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where(
        (tbl) => tbl.warehouseName.like(q) | tbl.warehouseCode.like(q),
      );
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.warehouseName)]);
    return query.get();
  }

  /// Reactive stream watching warehouses matching the filter.
  Stream<List<Warehouse>> watchWarehouses(WarehouseFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchWarehouses requires businessId.',
      );
    }
    final query = select(warehouses)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (filter.isDefault != null) {
      query.where((tbl) => tbl.isDefault.equals(filter.isDefault!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where(
        (tbl) => tbl.warehouseName.like(q) | tbl.warehouseCode.like(q),
      );
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.warehouseName)]);
    return query.watch();
  }

  /// Reactive stream watching a single warehouse by ID.
  Stream<Warehouse?> watchWarehouseById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchWarehouseById requires businessId.',
      );
    }
    return (select(warehouses)..where(
          (tbl) =>
              tbl.id.equals(id) &
              tbl.businessId.equals(businessId) &
              tbl.deletedAt.isNull(),
        ))
        .watchSingleOrNull();
  }

  /// Lists soft-deleted (archived) warehouses for a business.
  Future<List<Warehouse>> getArchivedWarehouses(
    String businessId, {
    String? branchId,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getArchivedWarehouses requires businessId.',
      );
    }
    final query = select(warehouses)
      ..where(
        (tbl) => tbl.businessId.equals(businessId) & tbl.deletedAt.isNotNull(),
      );
    if (branchId != null && branchId.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.warehouseName)]);
    return query.get();
  }

  /// Inserts a new warehouse.
  Future<int> insertWarehouse(WarehousesCompanion warehouse) {
    if (!warehouse.businessId.present ||
        warehouse.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertWarehouse requires businessId.',
      );
    }
    return into(warehouses).insert(warehouse);
  }

  /// Updates an existing warehouse.
  Future<bool> updateWarehouse(WarehousesCompanion warehouse) {
    if (!warehouse.businessId.present ||
        warehouse.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateWarehouse requires businessId.',
      );
    }
    return update(warehouses).replace(warehouse);
  }

  /// Soft-deletes a warehouse (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteWarehouse(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteWarehouse requires businessId.',
      );
    }
    return (update(warehouses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          WarehousesCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted warehouse (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreWarehouse(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'restoreWarehouse requires businessId.',
      );
    }
    return (update(warehouses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const WarehousesCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Retrieves pending synchronization warehouses for a business.
  Future<List<Warehouse>> getPendingSyncWarehouses(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(warehouses)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified warehouse IDs as synchronized.
  Future<int> markWarehousesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          warehouses,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const WarehousesCompanion(syncStatus: Value('synced')));
  }

  // ============================================================================
  // 2. INVENTORIES OPERATIONS (Tenant & Warehouse Scoped, Soft Delete Support)
  // ============================================================================

  /// Retrieves an inventory balance record by ID within a business.
  Future<Inventory?> getInventoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getInventoryById requires businessId.',
      );
    }
    final query = select(inventories)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves the inventory stock record for a specific product unit inside a warehouse.
  Future<Inventory?> getInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty ||
        warehouseId.trim().isEmpty ||
        productUnitId.trim().isEmpty) {
      throw const TenantScopingException(
        'getInventoryByUnitAndWarehouse requires businessId, warehouseId, and productUnitId.',
      );
    }
    final query = select(inventories)
      ..where(
        (tbl) =>
            tbl.businessId.equals(businessId) &
            tbl.warehouseId.equals(warehouseId) &
            tbl.productUnitId.equals(productUnitId),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists inventories matching the filter.
  Future<List<Inventory>> listInventories(InventoryFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listInventories requires businessId.',
      );
    }
    final query = select(inventories)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.warehouseId != null && filter.warehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.warehouseId.equals(filter.warehouseId!));
    }
    if (filter.productUnitId != null &&
        filter.productUnitId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.productUnitId.equals(filter.productUnitId!));
    }
    if (filter.lowStockOnly) {
      query.where(
        (tbl) =>
            tbl.quantity.isSmallerOrEqual(tbl.alertQuantity) &
            tbl.alertQuantity.isBiggerThanValue(0.0),
      );
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  /// Reactive stream watching inventories matching the filter.
  Stream<List<Inventory>> watchInventories(InventoryFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchInventories requires businessId.',
      );
    }
    final query = select(inventories)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.warehouseId != null && filter.warehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.warehouseId.equals(filter.warehouseId!));
    }
    if (filter.productUnitId != null &&
        filter.productUnitId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.productUnitId.equals(filter.productUnitId!));
    }
    if (filter.lowStockOnly) {
      query.where(
        (tbl) =>
            tbl.quantity.isSmallerOrEqual(tbl.alertQuantity) &
            tbl.alertQuantity.isBiggerThanValue(0.0),
      );
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watch();
  }

  /// Reactive stream watching a specific inventory balance by unit and warehouse.
  Stream<Inventory?> watchInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId,
  ) {
    if (businessId.trim().isEmpty ||
        warehouseId.trim().isEmpty ||
        productUnitId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchInventoryByUnitAndWarehouse requires businessId, warehouseId, and productUnitId.',
      );
    }
    return (select(inventories)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.warehouseId.equals(warehouseId) &
              tbl.productUnitId.equals(productUnitId) &
              tbl.deletedAt.isNull(),
        ))
        .watchSingleOrNull();
  }

  /// Retrieves a detailed joined view of stock levels alongside product, unit, and variant definitions.
  Future<List<StockBalanceView>> getDetailedStockBalances(
    InventoryFilter filter,
  ) async {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getDetailedStockBalances requires businessId.',
      );
    }
    final query = select(inventories).join([
      innerJoin(
        productUnits,
        productUnits.id.equalsExp(inventories.productUnitId),
      ),
      innerJoin(products, products.id.equalsExp(productUnits.productId)),
    ]);

    query.where(inventories.businessId.equals(filter.businessId));
    if (filter.warehouseId != null && filter.warehouseId!.trim().isNotEmpty) {
      query.where(inventories.warehouseId.equals(filter.warehouseId!));
    }
    if (filter.productUnitId != null &&
        filter.productUnitId!.trim().isNotEmpty) {
      query.where(inventories.productUnitId.equals(filter.productUnitId!));
    }
    if (filter.lowStockOnly) {
      query.where(
        inventories.quantity.isSmallerOrEqual(inventories.alertQuantity) &
            inventories.alertQuantity.isBiggerThanValue(0.0),
      );
    }
    if (!filter.includeDeleted) {
      query.where(
        inventories.deletedAt.isNull() &
            productUnits.deletedAt.isNull() &
            products.deletedAt.isNull(),
      );
    }

    final rows = await query.get();
    final results = <StockBalanceView>[];

    for (final row in rows) {
      final inv = row.readTable(inventories);
      final unit = row.readTable(productUnits);
      final prod = row.readTable(products);

      final variantsList =
          await (select(productVariants)..where(
                (tbl) =>
                    tbl.productUnitId.equals(unit.id) &
                    tbl.businessId.equals(filter.businessId),
              ))
              .get();

      results.add(
        StockBalanceView(
          inventory: inv,
          productUnit: unit,
          product: prod,
          variants: variantsList,
        ),
      );
    }
    return results;
  }

  /// Inserts a new inventory stock record.
  Future<int> insertInventory(InventoriesCompanion inventory) {
    if (!inventory.businessId.present ||
        inventory.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertInventory requires businessId.',
      );
    }
    return into(inventories).insert(inventory);
  }

  /// Updates an existing inventory stock record.
  Future<bool> updateInventory(InventoriesCompanion inventory) {
    if (!inventory.businessId.present ||
        inventory.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateInventory requires businessId.',
      );
    }
    return update(inventories).replace(inventory);
  }

  /// Soft-deletes an inventory record (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteInventory(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteInventory requires businessId.',
      );
    }
    return (update(inventories)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          InventoriesCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted inventory record (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreInventory(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'restoreInventory requires businessId.',
      );
    }
    return (update(inventories)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const InventoriesCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Retrieves pending synchronization inventories for a business.
  Future<List<Inventory>> getPendingSyncInventories(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(inventories)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified inventory IDs as synchronized.
  Future<int> markInventoriesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          inventories,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const InventoriesCompanion(syncStatus: Value('synced')));
  }

  // ============================================================================
  // 3. INVENTORY TRANSACTIONS OPERATIONS (Immutable Headers & Lines, Atomic Persistence)
  // ============================================================================

  /// Retrieves an inventory transaction header by ID within a business.
  Future<InventoryTransaction?> getTransactionById(
    String id,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getTransactionById requires businessId.',
      );
    }
    return (select(inventoryTransactions)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves an inventory transaction header along with all its associated line items.
  Future<InventoryTransactionWithLines?> getTransactionWithLinesById(
    String id,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getTransactionWithLinesById requires businessId.',
      );
    }
    final txn = await getTransactionById(id, businessId);
    if (txn == null) {
      return null;
    }

    final lines =
        await (select(inventoryTransactionLines)
              ..where(
                (tbl) =>
                    tbl.inventoryTransactionId.equals(id) &
                    tbl.businessId.equals(businessId),
              )
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.lineNumber)]))
            .get();

    return InventoryTransactionWithLines(transaction: txn, lines: lines);
  }

  /// Lists inventory transactions matching the filter, enforcing hard limit cap and deterministic ordering.
  Future<List<InventoryTransaction>> listTransactions(
    InventoryTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listTransactions requires businessId.',
      );
    }
    final query = select(inventoryTransactions)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.warehouseId != null && filter.warehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.warehouseId.equals(filter.warehouseId!));
    }
    if (filter.transactionType != null) {
      query.where(
        (tbl) => tbl.transactionType.equals(filter.transactionType!.value),
      );
    }
    if (filter.movementDirection != null) {
      query.where(
        (tbl) => tbl.movementDirection.equals(filter.movementDirection!.value),
      );
    }
    if (filter.status != null) {
      query.where((tbl) => tbl.status.equals(filter.status!.value));
    }
    if (filter.referenceType != null) {
      query.where(
        (tbl) => tbl.referenceType.equals(filter.referenceType!.value),
      );
    }
    if (filter.referenceId != null && filter.referenceId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.referenceId.equals(filter.referenceId!));
    }
    if (filter.startDate != null) {
      query.where(
        (tbl) => tbl.transactionDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where(
        (tbl) => tbl.transactionDate.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    final effectiveLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 20 : filter.limit);
    final effectiveOffset = filter.offset < 0 ? 0 : filter.offset;

    query.limit(effectiveLimit, offset: effectiveOffset);
    query.orderBy([
      (tbl) => OrderingTerm(
        expression: tbl.transactionDate,
        mode: OrderingMode.desc,
      ),
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Reactive stream watching inventory transactions matching the filter.
  Stream<List<InventoryTransaction>> watchTransactions(
    InventoryTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchTransactions requires businessId.',
      );
    }
    final query = select(inventoryTransactions)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.warehouseId != null && filter.warehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.warehouseId.equals(filter.warehouseId!));
    }
    if (filter.transactionType != null) {
      query.where(
        (tbl) => tbl.transactionType.equals(filter.transactionType!.value),
      );
    }
    if (filter.movementDirection != null) {
      query.where(
        (tbl) => tbl.movementDirection.equals(filter.movementDirection!.value),
      );
    }
    if (filter.status != null) {
      query.where((tbl) => tbl.status.equals(filter.status!.value));
    }
    if (filter.referenceType != null) {
      query.where(
        (tbl) => tbl.referenceType.equals(filter.referenceType!.value),
      );
    }
    if (filter.referenceId != null && filter.referenceId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.referenceId.equals(filter.referenceId!));
    }
    if (filter.startDate != null) {
      query.where(
        (tbl) => tbl.transactionDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where(
        (tbl) => tbl.transactionDate.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    final effectiveLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 20 : filter.limit);
    final effectiveOffset = filter.offset < 0 ? 0 : filter.offset;

    query.limit(effectiveLimit, offset: effectiveOffset);
    query.orderBy([
      (tbl) => OrderingTerm(
        expression: tbl.transactionDate,
        mode: OrderingMode.desc,
      ),
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  /// Lists all transaction lines for a specific inventory transaction within a business.
  Future<List<InventoryTransactionLine>> listTransactionLines(
    String transactionId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || transactionId.trim().isEmpty) {
      throw const TenantScopingException(
        'listTransactionLines requires businessId and transactionId.',
      );
    }
    return (select(inventoryTransactionLines)
          ..where(
            (tbl) =>
                tbl.inventoryTransactionId.equals(transactionId) &
                tbl.businessId.equals(businessId),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.lineNumber)]))
        .get();
  }

  /// Atomically persists an inventory transaction header and its associated lines inside a single database transaction.
  /// If any child insertion fails constraint verification, the entire transaction rolls back cleanly.
  Future<void> recordTransactionWithLines({
    required InventoryTransactionsCompanion transaction,
    required List<InventoryTransactionLinesCompanion> lines,
  }) {
    if (!transaction.businessId.present ||
        transaction.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordTransactionWithLines requires transaction.businessId.',
      );
    }
    if (lines.isEmpty) {
      throw ArgumentError(
        'recordTransactionWithLines requires at least one transaction line.',
      );
    }
    for (final l in lines) {
      if (!l.businessId.present || l.businessId.value.trim().isEmpty) {
        throw const TenantScopingException(
          'recordTransactionWithLines requires businessId on every line.',
        );
      }
    }

    return super.transaction(() async {
      await into(inventoryTransactions).insert(transaction);
      for (final line in lines) {
        await into(inventoryTransactionLines).insert(line);
      }
    });
  }

  /// Updates the workflow status (`status`) and optional posting/reversing audit fields of an existing transaction.
  Future<bool> updateTransactionStatus(
    String id,
    String businessId,
    InventoryTransactionStatus newStatus, {
    String? postedBy,
    DateTime? postedAt,
    String? reversedBy,
    DateTime? reversedAt,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateTransactionStatus requires businessId.',
      );
    }
    final companion = InventoryTransactionsCompanion(
      status: Value(newStatus),
      syncStatus: const Value('pending_update'),
      postedBy: postedBy != null ? Value(postedBy) : const Value.absent(),
      postedAt: postedAt != null ? Value(postedAt) : const Value.absent(),
      reversedBy: reversedBy != null ? Value(reversedBy) : const Value.absent(),
      reversedAt: reversedAt != null ? Value(reversedAt) : const Value.absent(),
    );
    return (update(inventoryTransactions)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Retrieves pending synchronization inventory transactions for a business.
  Future<List<InventoryTransaction>> getPendingSyncTransactions(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(inventoryTransactions)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified inventory transaction IDs as synchronized.
  Future<int> markTransactionsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          inventoryTransactions,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(
          const InventoryTransactionsCompanion(syncStatus: Value('synced')),
        );
  }

  /// Retrieves pending synchronization inventory transaction lines for a business.
  Future<List<InventoryTransactionLine>> getPendingSyncTransactionLines(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(inventoryTransactionLines)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified inventory transaction line IDs as synchronized.
  Future<int> markTransactionLinesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          inventoryTransactionLines,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(
          const InventoryTransactionLinesCompanion(syncStatus: Value('synced')),
        );
  }

  // ============================================================================
  // 4. INVENTORY TRANSFERS OPERATIONS (Immutable Headers & Items, Atomic Persistence)
  // ============================================================================

  /// Retrieves an inventory transfer header by ID within a business.
  Future<InventoryTransfer?> getTransferById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getTransferById requires businessId.',
      );
    }
    return (select(inventoryTransfers)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves an inventory transfer header along with all its transferred items.
  Future<InventoryTransferWithItems?> getTransferWithItemsById(
    String id,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getTransferWithItemsById requires businessId.',
      );
    }
    final transfer = await getTransferById(id, businessId);
    if (transfer == null) {
      return null;
    }

    final items =
        await (select(inventoryTransferItems)..where(
              (tbl) =>
                  tbl.transferId.equals(id) & tbl.businessId.equals(businessId),
            ))
            .get();

    return InventoryTransferWithItems(transfer: transfer, items: items);
  }

  /// Lists inventory transfers matching the filter, enforcing hard limit cap and deterministic ordering.
  Future<List<InventoryTransfer>> listTransfers(
    InventoryTransferFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listTransfers requires businessId.');
    }
    final query = select(inventoryTransfers)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.fromWarehouseId != null &&
        filter.fromWarehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.fromWarehouseId.equals(filter.fromWarehouseId!));
    }
    if (filter.toWarehouseId != null &&
        filter.toWarehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.toWarehouseId.equals(filter.toWarehouseId!));
    }
    if (filter.status != null) {
      query.where((tbl) => tbl.status.equals(filter.status!.value));
    }
    if (filter.startDate != null) {
      query.where(
        (tbl) => tbl.transferDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where(
        (tbl) => tbl.transferDate.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    final effectiveLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 20 : filter.limit);
    final effectiveOffset = filter.offset < 0 ? 0 : filter.offset;

    query.limit(effectiveLimit, offset: effectiveOffset);
    query.orderBy([
      (tbl) =>
          OrderingTerm(expression: tbl.transferDate, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Reactive stream watching inventory transfers matching the filter.
  Stream<List<InventoryTransfer>> watchTransfers(
    InventoryTransferFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchTransfers requires businessId.');
    }
    final query = select(inventoryTransfers)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.fromWarehouseId != null &&
        filter.fromWarehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.fromWarehouseId.equals(filter.fromWarehouseId!));
    }
    if (filter.toWarehouseId != null &&
        filter.toWarehouseId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.toWarehouseId.equals(filter.toWarehouseId!));
    }
    if (filter.status != null) {
      query.where((tbl) => tbl.status.equals(filter.status!.value));
    }
    if (filter.startDate != null) {
      query.where(
        (tbl) => tbl.transferDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where(
        (tbl) => tbl.transferDate.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    final effectiveLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 20 : filter.limit);
    final effectiveOffset = filter.offset < 0 ? 0 : filter.offset;

    query.limit(effectiveLimit, offset: effectiveOffset);
    query.orderBy([
      (tbl) =>
          OrderingTerm(expression: tbl.transferDate, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  /// Lists all transfer items for a specific inventory transfer within a business.
  Future<List<InventoryTransferItem>> listTransferItems(
    String transferId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || transferId.trim().isEmpty) {
      throw const TenantScopingException(
        'listTransferItems requires businessId and transferId.',
      );
    }
    return (select(inventoryTransferItems)..where(
          (tbl) =>
              tbl.transferId.equals(transferId) &
              tbl.businessId.equals(businessId),
        ))
        .get();
  }

  /// Atomically persists an inventory transfer header and its associated item records inside a single database transaction.
  /// If any item insertion fails constraint verification, the entire transaction rolls back cleanly.
  Future<void> recordTransferWithItems({
    required InventoryTransfersCompanion transfer,
    required List<InventoryTransferItemsCompanion> items,
  }) {
    if (!transfer.businessId.present ||
        transfer.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordTransferWithItems requires transfer.businessId.',
      );
    }
    if (items.isEmpty) {
      throw ArgumentError(
        'recordTransferWithItems requires at least one transfer item.',
      );
    }
    for (final item in items) {
      if (!item.businessId.present || item.businessId.value.trim().isEmpty) {
        throw const TenantScopingException(
          'recordTransferWithItems requires businessId on every item.',
        );
      }
    }

    return super.transaction(() async {
      await into(inventoryTransfers).insert(transfer);
      for (final item in items) {
        await into(inventoryTransferItems).insert(item);
      }
    });
  }

  /// Updates the workflow status (`status`) of an existing transfer.
  Future<bool> updateTransferStatus(
    String id,
    String businessId,
    InventoryTransferStatus newStatus,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateTransferStatus requires businessId.',
      );
    }
    final companion = InventoryTransfersCompanion(
      status: Value(newStatus),
      syncStatus: const Value('pending_update'),
    );
    return (update(inventoryTransfers)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Retrieves pending synchronization inventory transfers for a business.
  Future<List<InventoryTransfer>> getPendingSyncTransfers(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(inventoryTransfers)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified inventory transfer IDs as synchronized.
  Future<int> markTransfersAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          inventoryTransfers,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const InventoryTransfersCompanion(syncStatus: Value('synced')));
  }

  /// Retrieves pending synchronization inventory transfer items for a business.
  Future<List<InventoryTransferItem>> getPendingSyncTransferItems(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(inventoryTransferItems)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified inventory transfer item IDs as synchronized.
  Future<int> markTransferItemsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          inventoryTransferItems,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(
          const InventoryTransferItemsCompanion(syncStatus: Value('synced')),
        );
  }

  // ============================================================================
  // 6. STOCK COUNTS (Physical Inventory Sessions)
  // ============================================================================

  /// Creates a new Draft Stock Count along with its line items within a transaction.
  Future<void> recordStockCountWithItems(
    StockCountsCompanion header,
    List<StockCountItemsCompanion> lines,
  ) {
    return transaction(() async {
      await into(stockCounts).insert(header);
      for (final line in lines) {
        await into(stockCountItems).insert(line);
      }
    });
  }

  /// Retrieves a specific Stock Count by ID.
  Future<StockCount?> getStockCountById(String id, String businessId) {
    return (select(stockCounts)
          ..where(
            (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
          ))
        .getSingleOrNull();
  }

  /// Lists all stock counts for a specific warehouse (or all warehouses if null).
  Future<List<StockCount>> listStockCounts(
    String businessId, {
    String? warehouseId,
    int limit = 50,
    int offset = 0,
  }) {
    final query = select(stockCounts)
      ..where((tbl) => tbl.businessId.equals(businessId))
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.countDate,
              mode: OrderingMode.desc,
            ),
      ])
      ..limit(limit, offset: offset);

    if (warehouseId != null) {
      query.where((tbl) => tbl.warehouseId.equals(warehouseId));
    }

    return query.get();
  }

  /// Updates the status of a Stock Count (e.g. from Draft to Posted).
  Future<int> updateStockCountStatus(
    String id,
    String businessId,
    StockCountStatus status, {
    String? postedBy,
    DateTime? postedAt,
  }) {
    return (update(stockCounts)
          ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId)))
        .write(
      StockCountsCompanion(
        status: Value(status),
        postedBy: postedBy != null ? Value(postedBy) : const Value.absent(),
        postedAt: postedAt != null ? Value(postedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Updates an entire Stock Count Draft (header + items).
  Future<void> updateDraftStockCountWithItems(
    String id,
    String businessId,
    StockCountsCompanion header,
    List<StockCountItemsCompanion> lines,
  ) {
    return transaction(() async {
      // Ensure it's in Draft state
      final current = await getStockCountById(id, businessId);
      if (current == null || current.status != StockCountStatus.draft) {
        throw Exception('Cannot update stock count unless it is in Draft status.');
      }

      await (update(stockCounts)..where((tbl) => tbl.id.equals(id))).write(header);

      // Delete existing lines
      await (delete(stockCountItems)..where((tbl) => tbl.stockCountId.equals(id))).go();

      // Insert new lines
      for (final line in lines) {
        await into(stockCountItems).insert(line);
      }
    });
  }

  /// Retrieves all items for a specific Stock Count.
  Future<List<StockCountItem>> getStockCountItems(String stockCountId, String businessId) {
    return (select(stockCountItems)
          ..where((tbl) => tbl.stockCountId.equals(stockCountId) & tbl.businessId.equals(businessId)))
        .get();
  }
}
