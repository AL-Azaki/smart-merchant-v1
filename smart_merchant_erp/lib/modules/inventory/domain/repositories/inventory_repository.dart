import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_transfer_status.dart';
import '../../../../database/enums/stock_count_status.dart';

/// Contract for Inventory domain data operations.
/// Isolates application use cases from Drift ORM and SQLite specifics while
/// preserving multi-tenant (`businessId`), warehouse/branch scoping, offline-sync, and reactive stream semantics.
abstract class InventoryRepository {
  // Warehouses
  Future<Warehouse?> getWarehouseById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Warehouse?> getDefaultWarehouseByBranch(
    String businessId,
    String branchId,
  );
  Future<List<Warehouse>> listWarehouses(WarehouseFilter filter);
  Stream<List<Warehouse>> watchWarehouses(WarehouseFilter filter);
  Stream<Warehouse?> watchWarehouseById(String id, String businessId);
  Future<List<Warehouse>> getArchivedWarehouses(
    String businessId, {
    String? branchId,
  });
  Future<int> insertWarehouse(WarehousesCompanion warehouse);
  Future<bool> updateWarehouse(WarehousesCompanion warehouse);
  Future<int> softDeleteWarehouse(String id, String businessId);
  Future<int> restoreWarehouse(String id, String businessId);
  Future<List<Warehouse>> getPendingSyncWarehouses(
    String businessId, {
    int limit = 500,
  });
  Future<int> markWarehousesAsSynced(List<String> ids, String businessId);

  // Inventories (Stock Balances)
  Future<Inventory?> getInventoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Inventory?> getInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId, {
    bool includeDeleted = false,
  });
  Future<List<Inventory>> listInventories(InventoryFilter filter);
  Stream<List<Inventory>> watchInventories(InventoryFilter filter);
  Stream<Inventory?> watchInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId,
  );
  Future<List<StockBalanceView>> getDetailedStockBalances(
    InventoryFilter filter,
  );
  Future<int> insertInventory(InventoriesCompanion inventory);
  Future<bool> updateInventory(InventoriesCompanion inventory);
  Future<int> softDeleteInventory(String id, String businessId);
  Future<int> restoreInventory(String id, String businessId);
  Future<List<Inventory>> getPendingSyncInventories(
    String businessId, {
    int limit = 500,
  });
  Future<int> markInventoriesAsSynced(List<String> ids, String businessId);

  // Inventory Transactions & Lines
  Future<InventoryTransaction?> getTransactionById(
    String id,
    String businessId,
  );
  Future<InventoryTransactionWithLines?> getTransactionWithLinesById(
    String id,
    String businessId,
  );
  Future<List<InventoryTransaction>> listTransactions(
    InventoryTransactionFilter filter,
  );
  Stream<List<InventoryTransaction>> watchTransactions(
    InventoryTransactionFilter filter,
  );
  Future<List<InventoryTransactionLine>> listTransactionLines(
    String transactionId,
    String businessId,
  );
  Future<void> recordTransactionWithLines({
    required InventoryTransactionsCompanion transaction,
    required List<InventoryTransactionLinesCompanion> lines,
  });
  Future<bool> updateTransactionStatus(
    String id,
    String businessId,
    InventoryTransactionStatus newStatus,
  );
  Future<List<InventoryTransaction>> getPendingSyncTransactions(
    String businessId, {
    int limit = 500,
  });
  Future<int> markTransactionsAsSynced(List<String> ids, String businessId);
  Future<List<InventoryTransactionLine>> getPendingSyncTransactionLines(
    String businessId, {
    int limit = 500,
  });
  Future<int> markTransactionLinesAsSynced(List<String> ids, String businessId);

  // Inventory Transfers & Items
  Future<InventoryTransfer?> getTransferById(String id, String businessId);
  Future<InventoryTransferWithItems?> getTransferWithItemsById(
    String id,
    String businessId,
  );
  Future<List<InventoryTransfer>> listTransfers(InventoryTransferFilter filter);
  Stream<List<InventoryTransfer>> watchTransfers(
    InventoryTransferFilter filter,
  );
  Future<List<InventoryTransferItem>> listTransferItems(
    String transferId,
    String businessId,
  );
  Future<void> recordTransferWithItems({
    required InventoryTransfersCompanion transfer,
    required List<InventoryTransferItemsCompanion> items,
  });
  Future<bool> updateTransferStatus(
    String id,
    String businessId,
    InventoryTransferStatus newStatus,
  );
  Future<List<InventoryTransfer>> getPendingSyncTransfers(
    String businessId, {
    int limit = 500,
  });
  Future<int> markTransfersAsSynced(List<String> ids, String businessId);
  Future<List<InventoryTransferItem>> getPendingSyncTransferItems(
    String businessId, {
    int limit = 500,
  });
  Future<int> markTransferItemsAsSynced(List<String> ids, String businessId);

  // Stock Counts
  Future<void> recordStockCountWithItems({
    required StockCountsCompanion header,
    required List<StockCountItemsCompanion> items,
  });
  Future<StockCount?> getStockCountById(String id, String businessId);
  Future<List<StockCount>> listStockCounts(
    String businessId, {
    String? warehouseId,
    int limit = 50,
    int offset = 0,
  });
  Future<void> updateDraftStockCountWithItems({
    required String id,
    required String businessId,
    required StockCountsCompanion header,
    required List<StockCountItemsCompanion> items,
  });
  Future<int> updateStockCountStatus(
    String id,
    String businessId,
    StockCountStatus status, {
    String? postedBy,
    DateTime? postedAt,
  });
  Future<List<StockCountItem>> getStockCountItems(String stockCountId, String businessId);
}
