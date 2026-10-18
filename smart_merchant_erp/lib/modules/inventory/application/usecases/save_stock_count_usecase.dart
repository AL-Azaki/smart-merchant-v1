import '../services/stock_count_workflow.dart';
import '../../domain/models/stock_count_commands.dart';
export '../../domain/models/stock_count_commands.dart';

class SaveStockCountUseCase {
  final StockCountWorkflow _workflow;
  SaveStockCountUseCase(this._workflow);
  Future<String> call(SaveStockCountCommand command) => _workflow.save(command);
}
