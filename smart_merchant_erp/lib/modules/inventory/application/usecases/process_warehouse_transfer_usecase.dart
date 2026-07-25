import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
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
import '../../../../database/enums/inventory_transfer_status.dart';
import '../../domain/repositories/inventory_repository.dart';

class WarehouseTransferItemCommand {
  final String productUnitId;
  final double quantity;

  const WarehouseTransferItemCommand({
    required this.productUnitId,
    required this.quantity,
  });
}

class ProcessWarehouseTransferCommand {
  final String sourceWarehouseId;
  final String destinationWarehouseId;
  final List<WarehouseTransferItemCommand> items;
  final String? notes;

  const ProcessWarehouseTransferCommand({
    required this.sourceWarehouseId,
    required this.destinationWarehouseId,
    required this.items,
    this.notes,
  });
}

@injectable
class ProcessWarehouseTransferUseCase
    implements UseCase<String, ProcessWarehouseTransferCommand> {
  final InventoryRepository _inventoryRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  ProcessWarehouseTransferUseCase(
    this._inventoryRepository,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(
    ProcessWarehouseTransferCommand params,
  ) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for warehouse transfer.'),
      );
    }

    if (params.sourceWarehouseId == params.destinationWarehouseId) {
      return const Left(
        ValidationFailure(
          'Source and destination warehouses cannot be the same.',
        ),
      );
    }

    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Transfer must have at least one item.'),
      );
    }

    // 1. Validate Stock Availability
    for (final item in params.items) {
      if (item.quantity <= 0) {
        return const Left(
          ValidationFailure('Transfer quantity must be greater than 0.'),
        );
      }
      final inventory = await _inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            params.sourceWarehouseId,
            item.productUnitId,
          );
      if (inventory == null || inventory.quantity < item.quantity) {
        return const Left(
          ValidationFailure('Insufficient stock in source warehouse.'),
        );
      }
    }

    // 2. Prepare Transfer Entities
    final transferId = _uuid.v4();
    final transferNumber = 'TR-${DateTime.now().millisecondsSinceEpoch}';
    final transferDate = DateTime.now();

    final transferCompanion = InventoryTransfersCompanion.insert(
      id: transferId,
      businessId: businessId,
      transferNumber: transferNumber,
      transferDate: drift.Value(transferDate),
      fromWarehouseId: params.sourceWarehouseId,
      toWarehouseId: params.destinationWarehouseId,
      status: const drift.Value(InventoryTransferStatus.completed),
      notes: drift.Value(params.notes),
      createdBy: userId,
    );

    final transferItemsCompanions = params.items
        .map<InventoryTransferItemsCompanion>((item) {
          return InventoryTransferItemsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            transferId: transferId,
            productUnitId: item.productUnitId,
            quantity: item.quantity,
          );
        })
        .toList();

    // 3. Prepare Inventory Transactions (Outbound & Inbound)
    final txOutId = _uuid.v4();
    final txOutCompanion = InventoryTransactionsCompanion.insert(
      id: txOutId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.sourceWarehouseId,
      transactionDate: drift.Value(transferDate),
      transactionType: InventoryTransactionType.dispatch,
      movementDirection: InventoryMovementDirection.outbound,
      referenceType: const drift.Value(InventoryReferenceType.transfer),
      referenceId: drift.Value(transferId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final txInId = _uuid.v4();
    final txInCompanion = InventoryTransactionsCompanion.insert(
      id: txInId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.destinationWarehouseId,
      transactionDate: drift.Value(transferDate),
      transactionType: InventoryTransactionType.receipt,
      movementDirection: InventoryMovementDirection.inbound,
      referenceType: const drift.Value(InventoryReferenceType.transfer),
      referenceId: drift.Value(transferId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final txOutLines = params.items.map<InventoryTransactionLinesCompanion>((
      item,
    ) {
      return InventoryTransactionLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        inventoryTransactionId: txOutId,
        productUnitId: item.productUnitId,
        quantity: item.quantity,
      );
    }).toList();

    final txInLines = params.items.map<InventoryTransactionLinesCompanion>((
      item,
    ) {
      return InventoryTransactionLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        inventoryTransactionId: txInId,
        productUnitId: item.productUnitId,
        quantity: item.quantity,
      );
    }).toList();

    // 4. Run Transaction
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Transfer
        await _inventoryRepository.recordTransferWithItems(
          transfer: transferCompanion,
          items: transferItemsCompanions,
        );

        // Record Transfer Out
        await _inventoryRepository.recordTransactionWithLines(
          transaction: txOutCompanion,
          lines: txOutLines,
        );

        // Record Transfer In
        await _inventoryRepository.recordTransactionWithLines(
          transaction: txInCompanion,
          lines: txInLines,
        );
      });
      return Right(transferId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
