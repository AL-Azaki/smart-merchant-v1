import 'package:drift/drift.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';

/// Item representation in the Inventory Reports (تقرير مخزني للأصناف).
class StockReportItem {
  final String inventoryId;
  final String productCode;
  final String productName;
  final String unitName;
  final String warehouseId;
  final String warehouseName;
  final double quantity;
  final double costPrice;
  final double totalCost;
  final double sellingPrice;
  final double totalSelling;
  final double expectedProfit;
  final double alertQuantity;
  final bool isLowStock;
  final DateTime? updatedAt;

  const StockReportItem({
    required this.inventoryId,
    required this.productCode,
    required this.productName,
    required this.unitName,
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
    required this.costPrice,
    required this.totalCost,
    required this.sellingPrice,
    required this.totalSelling,
    required this.expectedProfit,
    required this.alertQuantity,
    required this.isLowStock,
    this.updatedAt,
  });
}

/// Overall compilation and summary metrics of the inventory report.
class InventoryReportSummary {
  final List<StockReportItem> items;
  final int totalItemsCount;
  final double totalQuantity;
  final double totalCostValue;
  final double totalSellingValue;
  final double totalExpectedProfit;
  final int lowStockCount;
  final String selectedWarehouseName;
  final String reportTypeName;
  final String dateFilterTitle;
  final DateTime generatedAt;

  const InventoryReportSummary({
    required this.items,
    required this.totalItemsCount,
    required this.totalQuantity,
    required this.totalCostValue,
    required this.totalSellingValue,
    required this.totalExpectedProfit,
    required this.lowStockCount,
    required this.selectedWarehouseName,
    required this.reportTypeName,
    required this.dateFilterTitle,
    required this.generatedAt,
  });
}

/// Engine responsible for compiling live inventory reports from Drift SQLite.
class InventoryReportsService {
  final AppDatabase _db;
  final ApplicationContext _context;

  InventoryReportsService(this._db, this._context);

  /// Compiles stock inventory report with flexible filters.
  Future<InventoryReportSummary> generateReport({
    String? warehouseId,
    String reportType = 'availableStock', // availableStock, lowStock, negativeStock, allItems
    DateTime? startDate,
    DateTime? endDate,
    String? dateFilterLabel,
    String? searchQuery,
  }) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch Warehouses map
    final warehousesList = await (_db.select(_db.warehouses)
          ..where((w) => w.businessId.equals(businessId) & w.deletedAt.isNull()))
        .get();
    final warehouseMap = {for (final w in warehousesList) w.id: w.warehouseName};

    String selectedWarehouseName = 'جميع المخازن';
    if (warehouseId != null && warehouseId != 'all' && warehouseMap.containsKey(warehouseId)) {
      selectedWarehouseName = warehouseMap[warehouseId]!;
    }

    // 2. Fetch Units map
    final unitsList = await (_db.select(_db.units)
          ..where((u) => u.businessId.equals(businessId) & u.deletedAt.isNull()))
        .get();
    final unitMap = {for (final u in unitsList) u.id: u.unitName};

    // 3. Build query joining productUnits + products, with leftOuterJoin on inventories
    final query = _db.select(_db.productUnits).join([
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.productUnits.productId),
      ),
      leftOuterJoin(
        _db.inventories,
        _db.inventories.productUnitId.equalsExp(_db.productUnits.id) &
            (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all'
                ? _db.inventories.warehouseId.equals(warehouseId)
                : const Constant(true)) &
            _db.inventories.deletedAt.isNull(),
      ),
    ]);

    query.where(_db.productUnits.businessId.equals(businessId));
    query.where(_db.productUnits.deletedAt.isNull());
    query.where(_db.products.deletedAt.isNull());

    // Filter by date range on inventory updates if specified
    if (startDate != null) {
      query.where(_db.inventories.updatedAt.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query.where(_db.inventories.updatedAt.isSmallerOrEqualValue(endOfDay));
    }

    final rows = await query.get();
    final items = <StockReportItem>[];

    double sumQuantity = 0.0;
    double sumCost = 0.0;
    double sumSelling = 0.0;
    int lowCount = 0;

    final queryClean = searchQuery?.trim().toLowerCase() ?? '';

    for (final row in rows) {
      final unit = row.readTable(_db.productUnits);
      final prod = row.readTable(_db.products);
      final inv = row.readTableOrNull(_db.inventories);

      final pCode = (unit.sku != null && unit.sku!.trim().isNotEmpty)
          ? unit.sku!
          : prod.productCode;
      final pName = prod.productName;
      final uName = unitMap[unit.unitId] ?? 'حبة';
      final wName = inv != null ? (warehouseMap[inv.warehouseId] ?? selectedWarehouseName) : selectedWarehouseName;
      final wId = inv?.warehouseId ?? (warehouseId ?? '');
      final invId = inv?.id ?? unit.id;

      // Search query filtering
      if (queryClean.isNotEmpty) {
        final matchCode = pCode.toLowerCase().contains(queryClean);
        final matchName = pName.toLowerCase().contains(queryClean);
        final matchBarcode = (unit.barcode ?? '').toLowerCase().contains(queryClean);
        if (!matchCode && !matchName && !matchBarcode) {
          continue;
        }
      }

      final qty = inv?.quantity ?? 0.0;
      final alertQty = inv?.alertQuantity ?? 0.0;
      final isLow = alertQty > 0 && qty <= alertQty;

      // 1. تقرير الكميات المتوفرة (الكمية > 0)
      if (reportType == 'availableStock' && qty <= 0) {
        continue;
      }
      // 2. تقرير الكميات الغير متوفرة (الكمية <= 0 / نافدة من المخزن)
      else if (reportType == 'unavailableStock' && qty > 0) {
        continue;
      }
      // 3. تقرير النواقص وحد الطلب
      else if (reportType == 'lowStock' && !isLow) {
        continue;
      }
      // 4. تقرير الأصناف السالبة
      else if (reportType == 'negativeStock' && qty >= 0) {
        continue;
      }

      final cost = (inv != null && inv.averageCost > 0) ? inv.averageCost : unit.purchasePrice;
      final selling = unit.sellingPrice > 0 ? unit.sellingPrice : unit.purchasePrice;
      final totalC = qty * cost;
      final totalS = qty * selling;
      final profit = totalS - totalC;

      if (isLow) {
        lowCount++;
      }
      sumQuantity += qty;
      sumCost += totalC;
      sumSelling += totalS;

      items.add(StockReportItem(
        inventoryId: invId,
        productCode: pCode,
        productName: pName,
        unitName: uName,
        warehouseId: wId,
        warehouseName: wName,
        quantity: qty,
        costPrice: cost,
        totalCost: totalC,
        sellingPrice: selling,
        totalSelling: totalS,
        expectedProfit: profit,
        alertQuantity: alertQty,
        isLowStock: isLow,
        updatedAt: inv?.updatedAt,
      ));
    }

    // Sort items by product code / name
    items.sort((a, b) => a.productCode.compareTo(b.productCode));

    String reportTitle = 'تقرير مخزني - الكميات المتوفرة';
    if (reportType == 'unavailableStock') {
      reportTitle = 'تقرير مخزني - الكميات الغير متوفرة (النافدة)';
    } else if (reportType == 'availableStock') {
      reportTitle = 'تقرير مخزني - الكميات المتوفرة';
    } else if (reportType == 'lowStock') {
      reportTitle = 'تقرير مخزني - النواقص وحد الطلب';
    } else if (reportType == 'negativeStock') {
      reportTitle = 'تقرير مخزني - الأصناف ذات الرصيد السالب';
    } else if (reportType == 'allItems') {
      reportTitle = 'تقرير مخزني - الجرد الشامل لكافة الأصناف';
    }

    return InventoryReportSummary(
      items: items,
      totalItemsCount: items.length,
      totalQuantity: sumQuantity,
      totalCostValue: sumCost,
      totalSellingValue: sumSelling,
      totalExpectedProfit: sumSelling - sumCost,
      lowStockCount: lowCount,
      selectedWarehouseName: selectedWarehouseName,
      reportTypeName: reportTitle,
      dateFilterTitle: dateFilterLabel ?? 'جميع الفترات',
      generatedAt: DateTime.now(),
    );
  }
}
