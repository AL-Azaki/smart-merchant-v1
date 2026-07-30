import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/enums/stock_count_status.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'process_stock_adjustment_usecase.dart';

class PostStockCountUseCase {
  final InventoryRepository _repository;
  final ApplicationContext _context;
  final ProcessStockAdjustmentUseCase _processStockAdjustmentUseCase;
  final ApplicationTransactionRunner _transactionRunner;

  PostStockCountUseCase(
    this._repository,
    this._context,
    this._processStockAdjustmentUseCase,
    this._transactionRunner,
  );

  Future<void> call(String stockCountId) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (businessId == null ||
        businessId.isEmpty ||
        branchId == null ||
        branchId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      throw Exception('Missing application context.');
    }

    await _transactionRunner.runInTransaction(() async {
      final count = await _repository.getStockCountById(
        stockCountId,
        businessId,
      );
      if (count == null) {
        throw Exception('Stock Count not found.');
      }

      if (count.status != StockCountStatus.draft) {
        throw Exception('Only Draft stock counts can be posted.');
      }

      final items = await _repository.getStockCountItems(
        stockCountId,
        businessId,
      );
      if (items.isEmpty) {
        throw Exception('Cannot post an empty stock count.');
      }

      // We only want to adjust items that actually have a difference.
      final differenceItems = items
          .where((i) => i.differenceQuantity != 0)
          .toList();

      if (differenceItems.isNotEmpty) {
        final adjustmentItems = differenceItems.map((i) {
          return StockAdjustmentItemCommand(
            productUnitId: i.productUnitId,
            countedQuantity: i.countedQuantity,
            expectedQuantity: i.expectedQuantity,
            difference: i.differenceQuantity,
          );
        }).toList();

        final adjustmentCommand = ProcessStockAdjustmentCommand(
          warehouseId: count.warehouseId,
          items: adjustmentItems,
          notes: 'تسوية آلية من جرد المستودع رقم ${count.countNumber}',
        );

        final result = await _processStockAdjustmentUseCase(adjustmentCommand);

        result.fold(
          (failure) =>
              throw Exception('فشل في إنشاء تسوية الجرد: ${failure.message}'),
          (txId) => null, // success
        );
      }

      // Mark the count as posted
      await _repository.updateStockCountStatus(
        stockCountId,
        businessId,
        StockCountStatus.posted,
        postedBy: userId,
        postedAt: DateTime.now(),
      );
    });
  }
}
