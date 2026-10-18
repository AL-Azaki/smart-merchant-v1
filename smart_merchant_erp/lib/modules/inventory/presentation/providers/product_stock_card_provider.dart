import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../app/di/getit_instance.dart';
import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

class ProductStockMovement {
  final String lineId;
  final String transactionId;
  final DateTime date;
  final InventoryTransactionType type;
  final InventoryMovementDirection direction;
  final InventoryReferenceType? referenceType;
  final String? referenceId;
  final String warehouseId;
  final String warehouseName;
  final String productUnitId;
  final String unitName;
  final double conversionFactor;
  final double quantity;
  final double baseQuantity;
  final double unitCost;
  final double runningBalance;
  final String? notes;

  const ProductStockMovement({
    required this.lineId,
    required this.transactionId,
    required this.date,
    required this.type,
    required this.direction,
    this.referenceType,
    this.referenceId,
    required this.warehouseId,
    required this.warehouseName,
    required this.productUnitId,
    required this.unitName,
    required this.conversionFactor,
    required this.quantity,
    required this.baseQuantity,
    required this.unitCost,
    required this.runningBalance,
    this.notes,
  });
}

class ProductStockCardData {
  final String productId;
  final String productName;
  final String productCode;
  final double currentStock;
  final double totalInbound;
  final double totalOutbound;
  final List<ProductStockMovement> movements;

  const ProductStockCardData({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.currentStock,
    required this.totalInbound,
    required this.totalOutbound,
    required this.movements,
  });
}

final productStockCardProvider = FutureProvider.autoDispose.family<ProductStockCardData, String>(
  (ref, productId) async {
    final session = ref.watch(sessionNotifierProvider);
    final businessId = session.businessId;
    if (businessId == null) {
      return ProductStockCardData(
        productId: productId,
        productName: '',
        productCode: '',
        currentStock: 0,
        totalInbound: 0,
        totalOutbound: 0,
        movements: [],
      );
    }

    final db = getIt<AppDatabase>();

    // 1. Get Product Details
    final product = await (db.select(db.products)
          ..where((p) => p.id.equals(productId) & p.businessId.equals(businessId)))
        .getSingleOrNull();

    if (product == null) {
      return ProductStockCardData(
        productId: productId,
        productName: '',
        productCode: '',
        currentStock: 0,
        totalInbound: 0,
        totalOutbound: 0,
        movements: [],
      );
    }

    // 2. Get Product Units and Unit details
    final productUnitsQuery = await (db.select(db.productUnits).join([
      drift.innerJoin(db.units, db.units.id.equalsExp(db.productUnits.unitId)),
    ])..where(db.productUnits.productId.equals(productId) &
        db.productUnits.businessId.equals(businessId)))
        .get();

    final unitInfoMap = <String, Map<String, dynamic>>{};
    final unitIds = <String>[];
    for (final row in productUnitsQuery) {
      final pu = row.readTable(db.productUnits);
      final u = row.readTable(db.units);
      unitIds.add(pu.id);
      unitInfoMap[pu.id] = {
        'unitName': u.unitName,
        'conversionFactor': pu.conversionFactor,
      };
    }

    if (unitIds.isEmpty) {
      return ProductStockCardData(
        productId: productId,
        productName: product.productName,
        productCode: product.productCode,
        currentStock: 0,
        totalInbound: 0,
        totalOutbound: 0,
        movements: [],
      );
    }

    // 3. Query all transaction lines for these units joined with transaction headers and warehouses
    final linesQuery = db.select(db.inventoryTransactionLines).join([
      drift.innerJoin(
        db.inventoryTransactions,
        db.inventoryTransactions.id.equalsExp(db.inventoryTransactionLines.inventoryTransactionId),
      ),
      drift.leftOuterJoin(
        db.warehouses,
        db.warehouses.id.equalsExp(db.inventoryTransactions.warehouseId),
      ),
    ])
      ..where(
        db.inventoryTransactionLines.businessId.equals(businessId) &
            db.inventoryTransactionLines.productUnitId.isIn(unitIds),
      )
      ..orderBy([
        drift.OrderingTerm(
          expression: db.inventoryTransactions.transactionDate,
          mode: drift.OrderingMode.asc,
        ),
        drift.OrderingTerm(
          expression: db.inventoryTransactions.id,
          mode: drift.OrderingMode.asc,
        ),
      ]);

    final rows = await linesQuery.get();

    // 4. Calculate chronological movements and running balance
    double runningBalance = 0.0;
    double totalInbound = 0.0;
    double totalOutbound = 0.0;

    final List<ProductStockMovement> movements = [];

    for (final row in rows) {
      final line = row.readTable(db.inventoryTransactionLines);
      final tx = row.readTable(db.inventoryTransactions);
      final wh = row.readTableOrNull(db.warehouses);

      final unitInfo = unitInfoMap[line.productUnitId] ?? {
        'unitName': 'قطعة',
        'conversionFactor': 1.0,
      };
      final unitName = unitInfo['unitName'] as String;
      final factor = unitInfo['conversionFactor'] as double;
      final baseQty = line.quantity * factor;

      final isInbound = tx.movementDirection == InventoryMovementDirection.inbound;
      if (isInbound) {
        runningBalance += baseQty;
        totalInbound += baseQty;
      } else {
        runningBalance -= baseQty;
        totalOutbound += baseQty;
      }

      movements.add(ProductStockMovement(
        lineId: line.id,
        transactionId: tx.id,
        date: tx.transactionDate,
        type: tx.transactionType,
        direction: tx.movementDirection,
        referenceType: tx.referenceType,
        referenceId: tx.referenceId,
        warehouseId: tx.warehouseId,
        warehouseName: wh?.warehouseName ?? 'المستودع الرئيسي',
        productUnitId: line.productUnitId,
        unitName: unitName,
        conversionFactor: factor,
        quantity: line.quantity,
        baseQuantity: baseQty,
        unitCost: line.unitCost,
        runningBalance: runningBalance,
        notes: null,
      ));
    }

    return ProductStockCardData(
      productId: productId,
      productName: product.productName,
      productCode: product.productCode,
      currentStock: runningBalance,
      totalInbound: totalInbound,
      totalOutbound: totalOutbound,
      movements: movements.reversed.toList(), // Show newest first in table
    );
  },
);
