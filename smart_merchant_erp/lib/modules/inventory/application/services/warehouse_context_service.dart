import '../../../../kernel/error/failures.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../../kernel/storage/app_database.dart';

/// Provides application-level resolution for the operational warehouse context.
///
/// Ensures that business and branch constraints are respected before returning
/// the default warehouse for a session.
class WarehouseContextService {
  final InventoryRepository _inventoryRepository;

  const WarehouseContextService(this._inventoryRepository);

  /// Resolves the default operational warehouse for a given business and branch.
  /// Throws a [ValidationFailure] if no valid default warehouse exists for the context.
  Future<Warehouse> resolveDefaultWarehouse(
    String businessId,
    String branchId,
  ) async {
    var warehouse = await _inventoryRepository.getDefaultWarehouseByBranch(
      businessId,
      branchId,
    );

    if (warehouse == null || !warehouse.isActive) {
      // Fallback 1: Any default warehouse for this business
      final defaultWhs = await _inventoryRepository.listWarehouses(
        WarehouseFilter(businessId: businessId, isDefault: true, isActive: true),
      );
      if (defaultWhs.isNotEmpty) {
        warehouse = defaultWhs.first;
      } else {
        // Fallback 2: Any active warehouse for this business
        final anyWhs = await _inventoryRepository.listWarehouses(
          WarehouseFilter(businessId: businessId, isActive: true),
        );
        if (anyWhs.isNotEmpty) {
          warehouse = anyWhs.first;
        }
      }
    }

    if (warehouse == null) {
      throw const ValidationFailure(
        'لم يتم العثور على أي مخزن نشط لهذا النشاط التجاري. يرجى إضافة مخزن من شاشة المخازن أولاً.',
      );
    }

    if (!warehouse.isActive) {
      throw const ValidationFailure(
        'المخزن المحدد غير نشط. يرجى تفعيله من شاشة المخازن.',
      );
    }

    return warehouse;
  }
}
