import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/core/usecase.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
import '../../domain/repositories/inventory_repository.dart';

class StockAdjustmentItemCommand {
  final String productUnitId;
  final double countedQuantity;
  final double expectedQuantity;
  final double difference;

  const StockAdjustmentItemCommand({
    required this.productUnitId,
    required this.countedQuantity,
    required this.expectedQuantity,
    required this.difference,
  });
}

class ProcessStockAdjustmentCommand {
  final String warehouseId;
  final List<StockAdjustmentItemCommand> items;
  final String? notes;

  const ProcessStockAdjustmentCommand({
    required this.warehouseId,
    required this.items,
    this.notes,
  });
}

class ProcessStockAdjustmentUseCase
    implements UseCase<String, ProcessStockAdjustmentCommand> {
  final InventoryRepository _inventoryRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  ProcessStockAdjustmentUseCase(
    this._inventoryRepository,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(
    ProcessStockAdjustmentCommand params,
  ) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for stock adjustment.'),
      );
    }

    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Adjustment must have at least one item.'),
      );
    }

    final txId = _uuid.v4();
    final adjustmentDate = DateTime.now();

    final inwardItems = params.items.where((i) => i.difference > 0).toList();
    final outwardItems = params.items.where((i) => i.difference < 0).toList();

    try {
      await _transactionRunner.runInTransaction(() async {
        if (inwardItems.isNotEmpty) {
          final txInId = _uuid.v4();
          final txInCompanion = InventoryTransactionsCompanion.insert(
            id: txInId,
            businessId: businessId,
            branchId: branchId,
            warehouseId: params.warehouseId,
            transactionDate: drift.Value(adjustmentDate),
            transactionType: InventoryTransactionType.adjustmentIn,
            movementDirection: InventoryMovementDirection.inbound,
            referenceType: const drift.Value(InventoryReferenceType.adjustment),
            referenceId: const drift.Value(''),
            status: const drift.Value(InventoryTransactionStatus.posted),
            createdBy: userId,
          );

          final txInLines = inwardItems.map((item) {
            return InventoryTransactionLinesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              inventoryTransactionId: txInId,
              productUnitId: item.productUnitId,
              quantity: item.difference,
            );
          }).toList();

          await _inventoryRepository.recordTransactionWithLines(
            transaction: txInCompanion,
            lines: txInLines,
          );
        }

        if (outwardItems.isNotEmpty) {
          final txOutId = _uuid.v4();
          final txOutCompanion = InventoryTransactionsCompanion.insert(
            id: txOutId,
            businessId: businessId,
            branchId: branchId,
            warehouseId: params.warehouseId,
            transactionDate: drift.Value(adjustmentDate),
            transactionType: InventoryTransactionType.adjustmentOut,
            movementDirection: InventoryMovementDirection.outbound,
            referenceType: const drift.Value(InventoryReferenceType.adjustment),
            referenceId: const drift.Value(''),
            status: const drift.Value(InventoryTransactionStatus.posted),
            createdBy: userId,
          );

          final txOutLines = outwardItems.map((item) {
            return InventoryTransactionLinesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              inventoryTransactionId: txOutId,
              productUnitId: item.productUnitId,
              quantity: item.difference.abs(),
            );
          }).toList();

          await _inventoryRepository.recordTransactionWithLines(
            transaction: txOutCompanion,
            lines: txOutLines,
          );
        }

        // Update actual stock quantities
        for (final item in params.items) {
          final inventory = await _inventoryRepository
              .getInventoryByUnitAndWarehouse(
                businessId,
                params.warehouseId,
                item.productUnitId,
              );
          if (inventory != null) {
            await _inventoryRepository.updateInventory(
              inventory
                  .toCompanion(false)
                  .copyWith(quantity: drift.Value(item.countedQuantity)),
            );
          } else {
            await _inventoryRepository.insertInventory(
              InventoriesCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                warehouseId: params.warehouseId,
                productUnitId: item.productUnitId,
                quantity: drift.Value(item.countedQuantity),
              ),
            );
          }
        }
      });
      return Right(txId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
