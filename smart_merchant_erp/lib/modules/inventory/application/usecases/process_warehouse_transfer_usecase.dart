import '../../../../core/utils/precision_math.dart';
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

class ProcessWarehouseTransferUseCase
    implements UseCase<String, ProcessWarehouseTransferCommand> {
  final InventoryRepository _inventoryRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();
  ProcessWarehouseTransferUseCase(
    this._inventoryRepository,
    this._context,
    this._transactionRunner,
    this._db,
  );
  @override
  Future<Either<Failure, String>> call(
    ProcessWarehouseTransferCommand params,
  ) async {
    final businessId = _context.currentBusinessId;
    if (params.items.isEmpty ||
        params.sourceWarehouseId == params.destinationWarehouseId) {
      return const Left(
        ValidationFailure('اختر مستودعين مختلفين ومنتجاً واحداً على الأقل.'),
      );
    }
    final transferId = _uuid.v4(), now = DateTime.now();
    try {
      await _transactionRunner.runInTransaction(() async {
        final source = await _inventoryRepository.getWarehouseById(
          params.sourceWarehouseId,
          businessId,
        );
        final destination = await _inventoryRepository.getWarehouseById(
          params.destinationWarehouseId,
          businessId,
        );
        if (source == null ||
            destination == null ||
            !source.isActive ||
            !destination.isActive ||
            source.businessId != businessId ||
            destination.businessId != businessId) {
          throw const ValidationFailure(
            'اختر مستودعين نشطين مسجلين لهذه المنشأة.',
          );
        }
        final sources = <String, Inventory>{},
            targets = <String, Inventory?>{};
        final totalBaseDeductions = <String, double>{};
        final plannedItems = <({
          ProductUnit unit,
          ProductUnit baseUnit,
          double quantity,
          double baseQuantity,
          double unitCost,
        })>[];

        for (final item in params.items) {
          if (!item.quantity.isFinite || item.quantity <= 0) {
            throw const ValidationFailure('راجع الكميات؛ يجب أن تكون أكبر من الصفر.');
          }
          final quantity = PrecisionMath.roundQty(item.quantity);
          if (quantity <= 0) {
            throw const ValidationFailure('الكمية المحوّلة أقل من دقة المخزون المتاحة.');
          }

          final unit = await (_db.select(_db.productUnits)..where(
                (u) =>
                    u.id.equals(item.productUnitId) &
                    u.businessId.equals(businessId) &
                    u.isActive.equals(true) &
                    u.deletedAt.isNull(),
              )).getSingleOrNull();

          if (unit == null) {
            throw const ValidationFailure('اختر وحدة نشطة لمنتج متاح في هذه المنشأة.');
          }

          // Resolve canonical base unit
          ProductUnit baseUnit = unit;
          double factor = unit.conversionFactor > 0 ? unit.conversionFactor : 1.0;
          if (!unit.isBaseUnit) {
            final allUnits = await (_db.select(_db.productUnits)..where(
                  (u) =>
                      u.productId.equals(unit.productId) &
                      u.businessId.equals(businessId) &
                      u.deletedAt.isNull(),
                )).get();
            baseUnit = allUnits.firstWhere((u) => u.isBaseUnit, orElse: () => unit);
          }

          final product = await (_db.select(_db.products)..where(
                (p) =>
                    p.id.equals(unit.productId) &
                    p.businessId.equals(businessId) &
                    p.isActive.equals(true) &
                    p.deletedAt.isNull(),
              )).getSingleOrNull();

          if (product == null) {
            throw const ValidationFailure('أحد المنتجات غير متاح للتحويل.');
          }

          final baseQuantity = PrecisionMath.roundQty(quantity * factor);
          final demanded = (totalBaseDeductions[baseUnit.id] ?? 0.0) + baseQuantity;

          final stock = sources[baseUnit.id] ??
              await _inventoryRepository.getInventoryByUnitAndWarehouse(
                businessId,
                source.id,
                baseUnit.id,
              );

          if (stock == null || stock.quantity + .000001 < demanded) {
            throw ValidationFailure(
              'الرصيد الحالي للمنتج «${product.productName}» لا يكفي للتحويل. حدّث القائمة وراجع الكمية.',
            );
          }

          sources[baseUnit.id] = stock;
          if (!targets.containsKey(baseUnit.id)) {
            targets[baseUnit.id] = await _inventoryRepository.getInventoryByUnitAndWarehouse(
              businessId,
              destination.id,
              baseUnit.id,
              includeDeleted: true,
            );
          }

          totalBaseDeductions[baseUnit.id] = demanded;
          plannedItems.add((
            unit: unit,
            baseUnit: baseUnit,
            quantity: quantity,
            baseQuantity: baseQuantity,
            unitCost: stock.averageCost * factor,
          ));
        }

        await _inventoryRepository.recordTransferWithItems(
          transfer: InventoryTransfersCompanion.insert(
            id: transferId,
            businessId: businessId,
            transferNumber: 'TR-${now.microsecondsSinceEpoch}',
            transferDate: drift.Value(now),
            fromWarehouseId: source.id,
            toWarehouseId: destination.id,
            status: const drift.Value(InventoryTransferStatus.completed),
            notes: drift.Value(params.notes),
            createdBy: _context.currentUserId,
          ),
          items: [
            for (final p in plannedItems)
              InventoryTransferItemsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                transferId: transferId,
                productUnitId: p.unit.id,
                quantity: p.quantity,
              ),
          ],
        );

        for (final inbound in [false, true]) {
          final txId = _uuid.v4();
          await _inventoryRepository.recordTransactionWithLines(
            transaction: InventoryTransactionsCompanion.insert(
              id: txId,
              businessId: businessId,
              branchId: inbound ? destination.branchId : source.branchId,
              warehouseId: inbound ? destination.id : source.id,
              transactionDate: drift.Value(now),
              transactionType: inbound
                  ? InventoryTransactionType.receipt
                  : InventoryTransactionType.dispatch,
              movementDirection: inbound
                  ? InventoryMovementDirection.inbound
                  : InventoryMovementDirection.outbound,
              referenceType: const drift.Value(InventoryReferenceType.transfer),
              referenceId: drift.Value(transferId),
              status: const drift.Value(InventoryTransactionStatus.posted),
              createdBy: _context.currentUserId,
              postedBy: drift.Value(_context.currentUserId),
              postedAt: drift.Value(now),
            ),
            lines: [
              for (final p in plannedItems)
                InventoryTransactionLinesCompanion.insert(
                  id: _uuid.v4(),
                  businessId: businessId,
                  inventoryTransactionId: txId,
                  productUnitId: p.unit.id,
                  quantity: p.quantity,
                  unitCost: drift.Value(p.unitCost),
                ),
            ],
          );
        }

        for (final e in totalBaseDeductions.entries) {
          final baseUnitId = e.key;
          final baseDeduction = e.value;
          final from = sources[baseUnitId]!, to = targets[baseUnitId];

          await _inventoryRepository.updateInventory(
            from.toCompanion(false).copyWith(
                  quantity: drift.Value(
                    PrecisionMath.roundQty(from.quantity - baseDeduction),
                  ),
                  updatedAt: drift.Value(now),
                  version: drift.Value(from.version + 1),
                  syncStatus: const drift.Value('pending'),
                ),
          );

          final oldQty = to == null || to.deletedAt != null ? 0.0 : to.quantity;
          final oldCost = to == null || to.deletedAt != null ? 0.0 : to.averageCost;
          final total = PrecisionMath.roundQty(oldQty + baseDeduction);
          final average = total > 0
              ? (oldQty * oldCost + baseDeduction * from.averageCost) / total
              : from.averageCost;

          if (to == null) {
            await _inventoryRepository.insertInventory(
              InventoriesCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                warehouseId: destination.id,
                productUnitId: baseUnitId,
                quantity: drift.Value(total),
                averageCost: drift.Value(average),
                createdAt: drift.Value(now),
              ),
            );
          } else {
            await _inventoryRepository.updateInventory(
              to.toCompanion(false).copyWith(
                    quantity: drift.Value(total),
                    averageCost: drift.Value(average),
                    deletedAt: const drift.Value(null),
                    updatedAt: drift.Value(now),
                    version: drift.Value(to.version + 1),
                    syncStatus: const drift.Value('pending'),
                  ),
            );
          }
        }
      });
      return Right(transferId);
    } catch (e) {
      return Left(
        e is Failure
            ? e
            : const UnexpectedFailure(
                'تعذر إتمام التحويل. لم تتغير الأرصدة، أعد المحاولة.',
              ),
      );
    }
  }
}
