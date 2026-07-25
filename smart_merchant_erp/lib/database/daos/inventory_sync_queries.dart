import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import 'inventory_dao.dart';

/// Extension methods on [InventoryDao] providing sync-specific queries
/// for the Inventory domain.
extension InventorySyncQueries on InventoryDao {
  /// Lists inventory records that have pending sync status.
  /// These represent the authoritative local stock quantities to be projected to Laravel.
  Future<List<Inventory>> listPendingSyncInventories() {
    return (select(
      inventories,
    )..where((t) => t.syncStatus.equals('pending'))).get();
  }

  /// Marks an inventory record as synced after successful push of its projection.
  Future<void> markInventorySynced(String id) {
    return (update(inventories)..where((t) => t.id.equals(id))).write(
      const InventoriesCompanion(syncStatus: Value('synced')),
    );
  }
}
