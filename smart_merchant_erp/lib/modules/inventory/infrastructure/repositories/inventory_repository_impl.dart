import 'package:injectable/injectable.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_transfer_status.dart';
import '../../../../database/enums/stock_count_status.dart';

@LazySingleton(as: InventoryRepository)
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryDao _dao;

  InventoryRepositoryImpl(this._dao);

  // Warehouses
  @override
  Future<Warehouse?> getWarehouseById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getWarehouseById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Warehouse?> getDefaultWarehouseByBranch(
    String businessId,
    String branchId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getDefaultWarehouseByBranch(businessId, branchId),
    );
  }

  @override
  Future<List<Warehouse>> listWarehouses(WarehouseFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listWarehouses(filter));
  }

  @override
  Stream<List<Warehouse>> watchWarehouses(WarehouseFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchWarehouses(filter));
  }

  @override
  Stream<Warehouse?> watchWarehouseById(String id, String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchWarehouseById(id, businessId),
    );
  }

  @override
  Future<List<Warehouse>> getArchivedWarehouses(
    String businessId, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getArchivedWarehouses(businessId, branchId: branchId),
    );
  }

  @override
  Future<int> insertWarehouse(WarehousesCompanion warehouse) {
    return RepositoryErrorGuard.run(() => _dao.insertWarehouse(warehouse));
  }

  @override
  Future<bool> updateWarehouse(WarehousesCompanion warehouse) {
    return RepositoryErrorGuard.run(() => _dao.updateWarehouse(warehouse));
  }

  @override
  Future<int> softDeleteWarehouse(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteWarehouse(id, businessId),
    );
  }

  @override
  Future<int> restoreWarehouse(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.restoreWarehouse(id, businessId),
    );
  }

  @override
  Future<List<Warehouse>> getPendingSyncWarehouses(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncWarehouses(businessId, limit: limit),
    );
  }

  @override
  Future<int> markWarehousesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markWarehousesAsSynced(ids, businessId),
    );
  }

  // Inventories (Stock Balances)
  @override
  Future<Inventory?> getInventoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getInventoryById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Inventory?> getInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        productUnitId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<Inventory>> listInventories(InventoryFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listInventories(filter));
  }

  @override
  Stream<List<Inventory>> watchInventories(InventoryFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchInventories(filter));
  }

  @override
  Stream<Inventory?> watchInventoryByUnitAndWarehouse(
    String businessId,
    String warehouseId,
    String productUnitId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        productUnitId,
      ),
    );
  }

  @override
  Future<List<StockBalanceView>> getDetailedStockBalances(
    InventoryFilter filter,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getDetailedStockBalances(filter),
    );
  }

  @override
  Future<int> insertInventory(InventoriesCompanion inventory) {
    return RepositoryErrorGuard.run(() => _dao.insertInventory(inventory));
  }

  @override
  Future<bool> updateInventory(InventoriesCompanion inventory) {
    return RepositoryErrorGuard.run(() => _dao.updateInventory(inventory));
  }

  @override
  Future<int> softDeleteInventory(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteInventory(id, businessId),
    );
  }

  @override
  Future<int> restoreInventory(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.restoreInventory(id, businessId),
    );
  }

  @override
  Future<List<Inventory>> getPendingSyncInventories(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncInventories(businessId, limit: limit),
    );
  }

  @override
  Future<int> markInventoriesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markInventoriesAsSynced(ids, businessId),
    );
  }

  // Inventory Transactions & Lines
  @override
  Future<InventoryTransaction?> getTransactionById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getTransactionById(id, businessId),
    );
  }

  @override
  Future<InventoryTransactionWithLines?> getTransactionWithLinesById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getTransactionWithLinesById(id, businessId),
    );
  }

  @override
  Future<List<InventoryTransaction>> listTransactions(
    InventoryTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listTransactions(filter));
  }

  @override
  Stream<List<InventoryTransaction>> watchTransactions(
    InventoryTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchTransactions(filter));
  }

  @override
  Future<List<InventoryTransactionLine>> listTransactionLines(
    String transactionId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listTransactionLines(transactionId, businessId),
    );
  }

  @override
  Future<void> recordTransactionWithLines({
    required InventoryTransactionsCompanion transaction,
    required List<InventoryTransactionLinesCompanion> lines,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordTransactionWithLines(
        transaction: transaction,
        lines: lines,
      ),
    );
  }

  @override
  Future<bool> updateTransactionStatus(
    String id,
    String businessId,
    InventoryTransactionStatus newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateTransactionStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<List<InventoryTransaction>> getPendingSyncTransactions(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncTransactions(businessId, limit: limit),
    );
  }

  @override
  Future<int> markTransactionsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markTransactionsAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<InventoryTransactionLine>> getPendingSyncTransactionLines(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncTransactionLines(businessId, limit: limit),
    );
  }

  @override
  Future<int> markTransactionLinesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markTransactionLinesAsSynced(ids, businessId),
    );
  }

  // Inventory Transfers & Items
  @override
  Future<InventoryTransfer?> getTransferById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getTransferById(id, businessId));
  }

  @override
  Future<InventoryTransferWithItems?> getTransferWithItemsById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getTransferWithItemsById(id, businessId),
    );
  }

  @override
  Future<List<InventoryTransfer>> listTransfers(
    InventoryTransferFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listTransfers(filter));
  }

  @override
  Stream<List<InventoryTransfer>> watchTransfers(
    InventoryTransferFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchTransfers(filter));
  }

  @override
  Future<List<InventoryTransferItem>> listTransferItems(
    String transferId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listTransferItems(transferId, businessId),
    );
  }

  @override
  Future<void> recordTransferWithItems({
    required InventoryTransfersCompanion transfer,
    required List<InventoryTransferItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordTransferWithItems(transfer: transfer, items: items),
    );
  }

  @override
  Future<bool> updateTransferStatus(
    String id,
    String businessId,
    InventoryTransferStatus newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateTransferStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<List<InventoryTransfer>> getPendingSyncTransfers(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncTransfers(businessId, limit: limit),
    );
  }

  @override
  Future<int> markTransfersAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markTransfersAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<InventoryTransferItem>> getPendingSyncTransferItems(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncTransferItems(businessId, limit: limit),
    );
  }

  @override
  Future<int> markTransferItemsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markTransferItemsAsSynced(ids, businessId),
    );
  }

  // Stock Counts
  @override
  Future<void> recordStockCountWithItems({
    required StockCountsCompanion header,
    required List<StockCountItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordStockCountWithItems(header, items),
    );
  }

  @override
  Future<StockCount?> getStockCountById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getStockCountById(id, businessId),
    );
  }

  @override
  Future<List<StockCount>> listStockCounts(
    String businessId, {
    String? warehouseId,
    int limit = 50,
    int offset = 0,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.listStockCounts(businessId, warehouseId: warehouseId, limit: limit, offset: offset),
    );
  }

  @override
  Future<void> updateDraftStockCountWithItems({
    required String id,
    required String businessId,
    required StockCountsCompanion header,
    required List<StockCountItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.updateDraftStockCountWithItems(id, businessId, header, items),
    );
  }

  @override
  Future<int> updateStockCountStatus(
    String id,
    String businessId,
    StockCountStatus status, {
    String? postedBy,
    DateTime? postedAt,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.updateStockCountStatus(id, businessId, status, postedBy: postedBy, postedAt: postedAt),
    );
  }

  @override
  Future<List<StockCountItem>> getStockCountItems(String stockCountId, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getStockCountItems(stockCountId, businessId),
    );
  }
}
