import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/enums/stock_count_status.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';

class SaveStockCountItemCommand {
  final String productId;
  final String productUnitId;
  final double expectedQuantity;
  final double countedQuantity;
  final double differenceQuantity;

  SaveStockCountItemCommand({
    required this.productId,
    required this.productUnitId,
    required this.expectedQuantity,
    required this.countedQuantity,
    required this.differenceQuantity,
  });
}

class SaveStockCountCommand {
  final String? id; // null if new
  final String warehouseId;
  final String? notes;
  final List<SaveStockCountItemCommand> items;

  SaveStockCountCommand({
    this.id,
    required this.warehouseId,
    this.notes,
    required this.items,
  });
}

class SaveStockCountUseCase {
  final InventoryRepository _repository;
  final ApplicationContext _context;
  final Uuid _uuid = const Uuid();

  SaveStockCountUseCase(this._repository, this._context);

  Future<String> call(SaveStockCountCommand command) async {
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

    final isNew = command.id == null || command.id!.isEmpty;
    final countId = isNew ? _uuid.v4() : command.id!;

    final header = StockCountsCompanion.insert(
      id: countId,
      businessId: businessId!,
      branchId: branchId!,
      warehouseId: command.warehouseId,
      countNumber:
          'SC-${DateTime.now().millisecondsSinceEpoch}', // Basic sequence
      status: const Value(StockCountStatus.draft),
      notes: command.notes != null
          ? Value(command.notes!)
          : const Value.absent(),
      createdBy: userId!,
      createdAt: Value(DateTime.now()),
    );

    final lines = command.items.map((item) {
      return StockCountItemsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId!,
        stockCountId: countId,
        productId: item.productId,
        productUnitId: item.productUnitId,
        expectedQuantity: item.expectedQuantity,
        countedQuantity: item.countedQuantity,
        differenceQuantity: item.differenceQuantity,
        createdAt: Value(DateTime.now()),
      );
    }).toList();

    if (isNew) {
      await _repository.recordStockCountWithItems(header: header, items: lines);
    } else {
      await _repository.updateDraftStockCountWithItems(
        id: countId,
        businessId: businessId,
        header: StockCountsCompanion(
          warehouseId: Value(command.warehouseId),
          notes: command.notes != null
              ? Value(command.notes!)
              : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
        items: lines,
      );
    }

    return countId;
  }
}
