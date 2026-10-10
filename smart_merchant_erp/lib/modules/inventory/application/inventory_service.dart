import 'package:drift/drift.dart';
import '../../../../core/utils/precision_math.dart';
import '../../../../kernel/storage/app_database.dart';

/// InventoryService manages live warehouse stock balances, movements,
/// and automated Moving Weighted Average Cost (MWAC) recalculations.
class InventoryService {
  final AppDatabase db;

  InventoryService(this.db);

  /// Processes stock intake (e.g. Purchase Invoices or Initial Stock).
  /// 
  /// Automatically recalculates the Moving Weighted Average Cost:
  /// NewAvgCost = ((CurrentQty * CurrentCost) + (NewQty * NewPurchasePrice)) / (CurrentQty + NewQty).
  /// 
  /// If current stock is zero or negative, the new purchase price becomes the new average cost directly.
  Future<void> processStockIn({
    required String warehouseId,
    required String productId,
    required double quantityInBaseUnit,
    required double purchasePriceInBaseUnit,
    required String referenceType,
    required String referenceId,
    DateTime? transactionDate,
  }) async {
    if (quantityInBaseUnit <= 0) {
      throw ArgumentError('كمية التوريد المخزني يجب أن تكون أكبر من الصفر');
    }

    final currentInv = await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();

    double newQty = quantityInBaseUnit;
    double newAvgCost = purchasePriceInBaseUnit;

    if (currentInv != null) {
      final currentQty = currentInv.quantityOnHand;
      final currentCost = currentInv.averageCost;

      if (currentQty > 0) {
        // Standard Moving Weighted Average Cost Formula
        final totalOldValue = currentQty * currentCost;
        final totalNewValue = quantityInBaseUnit * purchasePriceInBaseUnit;
        newQty = PrecisionMath.roundQuantity(currentQty + quantityInBaseUnit);
        newAvgCost = PrecisionMath.roundMoney((totalOldValue + totalNewValue) / newQty);
      } else {
        // Recovery from negative or zero stock balance
        newQty = PrecisionMath.roundQuantity(currentQty + quantityInBaseUnit);
        newAvgCost = purchasePriceInBaseUnit;
      }

      await (db.update(db.inventoriesTable)..where((i) => i.id.equals(currentInv.id))).write(
        InventoriesTableCompanion(
          quantityOnHand: Value(newQty),
          averageCost: Value(newAvgCost),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // First intake for this product in this warehouse
      await db.into(db.inventoriesTable).insert(
        InventoriesTableCompanion.insert(
          warehouseId: warehouseId,
          productId: productId,
          quantityOnHand: Value(newQty),
          averageCost: Value(newAvgCost),
        ),
      );
    }

    // Record immutable audit transaction
    await db.into(db.inventoryTransactionsTable).insert(
      InventoryTransactionsTableCompanion.insert(
        warehouseId: warehouseId,
        productId: productId,
        transactionType: 'In',
        quantity: quantityInBaseUnit,
        unitCost: Value(purchasePriceInBaseUnit),
        referenceType: referenceType,
        referenceId: referenceId,
        transactionDate: Value(transactionDate ?? DateTime.now()),
      ),
    );
  }

  /// Processes stock reduction (e.g. Sales Invoices).
  /// 
  /// Does NOT modify the product's average cost.
  /// Deducts quantity and returns the total Cost of Goods Sold (COGS).
  Future<double> processStockOut({
    required String warehouseId,
    required String productId,
    required double quantityInBaseUnit,
    required String referenceType,
    required String referenceId,
    DateTime? transactionDate,
  }) async {
    if (quantityInBaseUnit <= 0) {
      throw ArgumentError('كمية الصرف المخزني يجب أن تكون أكبر من الصفر');
    }

    final currentInv = await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();

    final currentCost = currentInv?.averageCost ?? 0.0;
    final currentQty = currentInv?.quantityOnHand ?? 0.0;
    final newQty = PrecisionMath.roundQuantity(currentQty - quantityInBaseUnit);

    if (currentInv != null) {
      await (db.update(db.inventoriesTable)..where((i) => i.id.equals(currentInv.id))).write(
        InventoriesTableCompanion(
          quantityOnHand: Value(newQty),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // Negative sale of a newly introduced product
      await db.into(db.inventoriesTable).insert(
        InventoriesTableCompanion.insert(
          warehouseId: warehouseId,
          productId: productId,
          quantityOnHand: Value(newQty),
          averageCost: const Value(0.0),
        ),
      );
    }

    // Record immutable audit transaction
    await db.into(db.inventoryTransactionsTable).insert(
      InventoryTransactionsTableCompanion.insert(
        warehouseId: warehouseId,
        productId: productId,
        transactionType: 'Out',
        quantity: quantityInBaseUnit,
        unitCost: Value(currentCost),
        referenceType: referenceType,
        referenceId: referenceId,
        transactionDate: Value(transactionDate ?? DateTime.now()),
      ),
    );

    // Return total COGS
    return PrecisionMath.roundMoney(quantityInBaseUnit * currentCost);
  }

  /// Processes stock reconciliation / physical inventory count adjustments.
  /// 
  /// Overrides the system quantity with the physical count while preserving unit average cost.
  Future<double> processStockAdjustment({
    required String warehouseId,
    required String productId,
    required double actualPhysicalCountInBaseUnit,
    required String referenceId,
    String? reason,
  }) async {
    final currentInv = await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();

    final currentQty = currentInv?.quantityOnHand ?? 0.0;
    final currentCost = currentInv?.averageCost ?? 0.0;
    final varianceQty = PrecisionMath.roundQuantity(actualPhysicalCountInBaseUnit - currentQty);

    if (currentInv != null) {
      await (db.update(db.inventoriesTable)..where((i) => i.id.equals(currentInv.id))).write(
        InventoriesTableCompanion(
          quantityOnHand: Value(actualPhysicalCountInBaseUnit),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await db.into(db.inventoriesTable).insert(
        InventoriesTableCompanion.insert(
          warehouseId: warehouseId,
          productId: productId,
          quantityOnHand: Value(actualPhysicalCountInBaseUnit),
          averageCost: const Value(0.0),
        ),
      );
    }

    // Record adjustment movement
    await db.into(db.inventoryTransactionsTable).insert(
      InventoryTransactionsTableCompanion.insert(
        warehouseId: warehouseId,
        productId: productId,
        transactionType: varianceQty >= 0 ? 'Adjustment' : 'Damage',
        quantity: varianceQty.abs(),
        unitCost: Value(currentCost),
        referenceType: 'StockTake',
        referenceId: referenceId,
      ),
    );

    return PrecisionMath.roundMoney(varianceQty * currentCost);
  }

  /// Returns current stock details for a product in a warehouse.
  Future<InventoryData?> getStock(String warehouseId, String productId) async {
    return await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();
  }
}
