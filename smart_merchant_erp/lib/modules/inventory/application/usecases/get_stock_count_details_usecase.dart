import 'package:injectable/injectable.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';

class StockCountDetails {
  final StockCount count;
  final List<StockCountItem> items;

  StockCountDetails({required this.count, required this.items});
}

@injectable
class GetStockCountDetailsUseCase {
  final InventoryRepository _repository;
  final ApplicationContext _context;

  GetStockCountDetailsUseCase(this._repository, this._context);

  Future<StockCountDetails> call(String countId) async {
    final businessId = _context.currentBusinessId;
    if (businessId.isEmpty) {
      throw Exception('Missing application context.');
    }

    final count = await _repository.getStockCountById(countId, businessId);
    if (count == null) {
      throw Exception('Stock Count not found.');
    }

    final items = await _repository.getStockCountItems(countId, businessId);
    return StockCountDetails(count: count, items: items);
  }
}
