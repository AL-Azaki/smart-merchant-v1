import 'package:injectable/injectable.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';

@injectable
class GetStockCountsUseCase {
  final InventoryRepository _repository;
  final ApplicationContext _context;

  GetStockCountsUseCase(this._repository, this._context);

  Future<List<StockCount>> call({String? warehouseId, int limit = 50, int offset = 0}) async {
    final businessId = _context.currentBusinessId;
    if (businessId.isEmpty) {
      throw Exception('Missing application context.');
    }

    return _repository.listStockCounts(
      businessId,
      warehouseId: warehouseId,
      limit: limit,
      offset: offset,
    );
  }
}
