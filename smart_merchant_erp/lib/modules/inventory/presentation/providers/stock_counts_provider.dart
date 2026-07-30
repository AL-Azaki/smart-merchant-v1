import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../application/usecases/get_stock_counts_usecase.dart';
import '../../application/usecases/get_stock_count_details_usecase.dart';
import '../../application/usecases/save_stock_count_usecase.dart';
import '../../application/usecases/post_stock_count_usecase.dart';

final stockCountsNotifierProvider = AutoDisposeStreamNotifierProvider<StockCountsNotifier, List<StockCount>>(() => StockCountsNotifier());

class StockCountsNotifier extends AutoDisposeStreamNotifier<List<StockCount>> {
  late final GetStockCountsUseCase _getCountsUseCase;
  late final GetStockCountDetailsUseCase _getDetailsUseCase;
  late final SaveStockCountUseCase _saveUseCase;
  late final PostStockCountUseCase _postUseCase;

  @override
  Stream<List<StockCount>> build() async* {
    _getCountsUseCase = getIt<GetStockCountsUseCase>();
    _getDetailsUseCase = getIt<GetStockCountDetailsUseCase>();
    _saveUseCase = getIt<SaveStockCountUseCase>();
    _postUseCase = getIt<PostStockCountUseCase>();
    yield await _fetchCounts();
  }

  Future<List<StockCount>> _fetchCounts() async {
    return _getCountsUseCase();
  }

  Future<void> refreshCounts() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchCounts());
  }

  Future<StockCountDetails> getDetails(String id) async {
    return _getDetailsUseCase(id);
  }

  Future<String> saveDraft(SaveStockCountCommand command) async {
    final id = await _saveUseCase(command);
    await refreshCounts();
    return id;
  }

  Future<void> postCount(String id) async {
    await _postUseCase(id);
    await refreshCounts();
  }
}
