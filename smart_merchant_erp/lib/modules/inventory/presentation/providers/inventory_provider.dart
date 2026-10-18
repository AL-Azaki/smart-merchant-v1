import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'stock_counts_provider.dart';

final activeWarehousesProvider = FutureProvider.autoDispose<List<Warehouse>>(
  (ref) => _activeWarehouses(ref),
);

Future<List<Warehouse>> _activeWarehouses(Ref ref) async {
  ref.watch(sessionNotifierProvider);
  final repo = getIt<InventoryRepository>();
  final context = getIt<ApplicationContext>();
  final filter = WarehouseFilter(
    businessId: context.currentBusinessId,
    isActive: true,
  );
  return await repo.listWarehouses(filter);
}

final warehousesStreamProvider =
    StreamProvider.autoDispose<List<Warehouse>>((ref) {
  ref.watch(sessionNotifierProvider);
  final repo = getIt<InventoryRepository>();
  final context = getIt<ApplicationContext>();
  final businessId = context.currentBusinessId;
  if (businessId.isEmpty) {
    return const Stream.empty();
  }
  return repo.watchWarehouses(WarehouseFilter(businessId: businessId));
});

final warehouseStockBalancesProvider = FutureProvider.autoDispose
    .family<List<StockBalanceView>, String>(
      (ref, warehouseId) => _warehouseStockBalances(ref, warehouseId),
    );

Future<List<StockBalanceView>> _warehouseStockBalances(
  Ref ref,
  String warehouseId,
) async {
  ref.watch(sessionNotifierProvider);
  final repo = getIt<InventoryRepository>();
  final context = getIt<ApplicationContext>();
  final filter = InventoryFilter(
    businessId: context.currentBusinessId,
    warehouseId: warehouseId,
  );
  return await repo.getDetailedStockBalances(filter);
}

final stockAdjustmentsListProvider =
    StreamProvider.autoDispose<List<InventoryTransaction>>(
      (ref) => ref.watch(stockCountWorkflowProvider).watchAdjustments(),
    );
final warehouseTransfersStreamProvider =
    StreamProvider.autoDispose<List<InventoryTransfer>>(
      (ref) => ref.watch(stockCountWorkflowProvider).watchTransfers(),
    );
