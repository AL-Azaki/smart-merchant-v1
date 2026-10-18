import '../services/stock_count_workflow.dart';

class PostStockCountUseCase {
  final StockCountWorkflow _workflow;
  PostStockCountUseCase(this._workflow);
  Future<void> call(String id) => _workflow.correct(id);
}
