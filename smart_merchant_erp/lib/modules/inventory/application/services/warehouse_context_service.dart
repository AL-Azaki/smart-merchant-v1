import 'package:injectable/injectable.dart';
import '../../../../kernel/error/failures.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../../kernel/storage/app_database.dart';

/// Provides application-level resolution for the operational warehouse context.
///
/// Ensures that business and branch constraints are respected before returning
/// the default warehouse for a session.
@lazySingleton
class WarehouseContextService {
  final InventoryRepository _inventoryRepository;

  const WarehouseContextService(this._inventoryRepository);

  /// Resolves the default operational warehouse for a given business and branch.
  /// Throws a [ValidationFailure] if no valid default warehouse exists for the context.
  Future<Warehouse> resolveDefaultWarehouse(
    String businessId,
    String branchId,
  ) async {
    final warehouse = await _inventoryRepository.getDefaultWarehouseByBranch(
      businessId,
      branchId,
    );

    if (warehouse == null) {
      throw const ValidationFailure(
        'No default operational warehouse found for the current branch.',
      );
    }

    if (!warehouse.isActive) {
      throw const ValidationFailure(
        'The default warehouse for this branch is inactive.',
      );
    }

    return warehouse;
  }
}
