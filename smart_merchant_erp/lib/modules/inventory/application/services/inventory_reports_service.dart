import 'package:drift/drift.dart';
import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
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

/// Movement line representation in the Stock Movement Ledger (حركة المخزون / الصنف).
class StockMovementItem {
  final String id;
  final DateTime date;
  final String productCode;
  final String productName;
  final String unitName;
  final String movementType;
  final String referenceNumber;
  final String partyName;
  final double inQty;
  final double outQty;
  final double runningBalance;
  final String warehouseName;

  const StockMovementItem({
    required this.id,
    required this.date,
    required this.productCode,
    required this.productName,
    required this.unitName,
    required this.movementType,
    required this.referenceNumber,
    required this.partyName,
    required this.inQty,
    required this.outQty,
    required this.runningBalance,
    required this.warehouseName,
  });
}

/// Summary metrics and chronological entries for the Stock Movement Ledger.
class StockMovementReportSummary {
  final List<StockMovementItem> movements;
  final double openingBalance;
  final double totalIn;
  final double totalOut;
  final double netMovement;
  final double closingBalance;
  final String selectedWarehouseName;
  final String selectedProductName;
  final String dateFilterTitle;
  final DateTime generatedAt;

  const StockMovementReportSummary({
    required this.movements,
    required this.openingBalance,
    required this.totalIn,
    required this.totalOut,
    required this.netMovement,
    required this.closingBalance,
    required this.selectedWarehouseName,
    required this.selectedProductName,
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

  /// Retrieves list of products associated with a specific warehouse (or all products).
  Future<List<({String id, String name, String code})>> getWarehouseProducts({
    String? warehouseId,
  }) async {
    final businessId = _context.currentBusinessId;
    final query = _db.select(_db.productUnits).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.productUnits.productId)),
      if (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all')
        innerJoin(
          _db.inventories,
          _db.inventories.productUnitId.equalsExp(_db.productUnits.id) &
              _db.inventories.warehouseId.equals(warehouseId) &
              _db.inventories.deletedAt.isNull(),
        ),
    ]);

    query.where(_db.productUnits.businessId.equals(businessId));
    query.where(_db.productUnits.deletedAt.isNull());
    query.where(_db.products.deletedAt.isNull());

    final rows = await query.get();
    final seen = <String>{};
    final result = <({String id, String name, String code})>[];

    for (final row in rows) {
      final p = row.readTable(_db.products);
      if (seen.add(p.id)) {
        result.add((id: p.id, name: p.productName, code: p.productCode));
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Generates the Stock Movement Ledger with chronological running balance.
  Future<StockMovementReportSummary> generateMovementReport({
    String? warehouseId,
    String? productId,
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

    // 3. Determine selected product name
    String selectedProductName = 'جميع الأصناف';
    if (productId != null && productId != 'all' && productId.isNotEmpty) {
      final prod = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (prod != null) {
        selectedProductName = '${prod.productName} (${prod.productCode})';
      }
    }

    // 4. Query all posted inventory transactions & lines
    final query = _db.select(_db.inventoryTransactions).join([
      innerJoin(
        _db.inventoryTransactionLines,
        _db.inventoryTransactionLines.inventoryTransactionId.equalsExp(_db.inventoryTransactions.id),
      ),
      innerJoin(
        _db.productUnits,
        _db.productUnits.id.equalsExp(_db.inventoryTransactionLines.productUnitId),
      ),
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.productUnits.productId),
      ),
    ]);

    query.where(_db.inventoryTransactions.businessId.equals(businessId));
    query.where(_db.inventoryTransactions.status.equals(InventoryTransactionStatus.posted.value));

    if (warehouseId != null && warehouseId.isNotEmpty && warehouseId != 'all') {
      query.where(_db.inventoryTransactions.warehouseId.equals(warehouseId));
    }

    if (productId != null && productId.isNotEmpty && productId != 'all') {
      query.where(_db.products.id.equals(productId));
    }

    query.orderBy([
      OrderingTerm(expression: _db.inventoryTransactions.transactionDate, mode: OrderingMode.asc),
      OrderingTerm(expression: _db.inventoryTransactionLines.lineNumber, mode: OrderingMode.asc),
    ]);

    final rows = await query.get();

    // 5. Pre-fetch reference entities for fast party resolution
    final salesIds = <String>{};
    final purchaseIds = <String>{};
    final transferIds = <String>{};
    final salesReturnIds = <String>{};
    final purchaseReturnIds = <String>{};

    for (final r in rows) {
      final tx = r.readTable(_db.inventoryTransactions);
      final refId = tx.referenceId;
      if (refId == null || refId.isEmpty) {
        continue;
      }
      final refType = tx.referenceType;
      if (refType == InventoryReferenceType.salesInvoice) {
        salesIds.add(refId);
      } else if (refType == InventoryReferenceType.purchaseInvoice) {
        purchaseIds.add(refId);
      } else if (refType == InventoryReferenceType.transfer) {
        transferIds.add(refId);
      } else if (refType == InventoryReferenceType.salesReturn) {
        salesReturnIds.add(refId);
      } else if (refType == InventoryReferenceType.purchaseReturn) {
        purchaseReturnIds.add(refId);
      }
    }

    // Map sales invoices -> customer name & invoice number
    final salesMap = <String, ({String invoiceNumber, String customerName})>{};
    if (salesIds.isNotEmpty) {
      final sRows = await (_db.select(_db.salesInvoices).join([
        leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesInvoices.customerId)),
      ])..where(_db.salesInvoices.id.isIn(salesIds))).get();

      for (final sr in sRows) {
        final inv = sr.readTable(_db.salesInvoices);
        final cust = sr.readTableOrNull(_db.customers);
        salesMap[inv.id] = (
          invoiceNumber: inv.invoiceNumber,
          customerName: cust?.customerName ?? 'عميل نقدي / عام',
        );
      }
    }

    // Map purchase invoices -> supplier name & invoice number
    final purchaseMap = <String, ({String invoiceNumber, String supplierName})>{};
    if (purchaseIds.isNotEmpty) {
      final pRows = await (_db.select(_db.purchaseInvoices).join([
        leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchaseInvoices.supplierId)),
      ])..where(_db.purchaseInvoices.id.isIn(purchaseIds))).get();

      for (final pr in pRows) {
        final inv = pr.readTable(_db.purchaseInvoices);
        final sup = pr.readTableOrNull(_db.suppliers);
        purchaseMap[inv.id] = (
          invoiceNumber: inv.invoiceNumber,
          supplierName: sup?.supplierName ?? 'مورد غير محدد',
        );
      }
    }

    // Map transfers -> transfer number & warehouses
    final transferMap = <String, ({String transferNumber, String fromWarehouse, String toWarehouse})>{};
    if (transferIds.isNotEmpty) {
      final tRows = await (_db.select(_db.inventoryTransfers)
            ..where((t) => t.id.isIn(transferIds)))
          .get();

      for (final tr in tRows) {
        final fromName = warehouseMap[tr.fromWarehouseId] ?? 'مخزن المصدر';
        final toName = warehouseMap[tr.toWarehouseId] ?? 'مخزن الوجهة';
        transferMap[tr.id] = (
          transferNumber: tr.transferNumber,
          fromWarehouse: fromName,
          toWarehouse: toName,
        );
      }
    }

    // Map sales returns -> return number & customer name
    final salesReturnMap = <String, ({String returnNumber, String customerName})>{};
    if (salesReturnIds.isNotEmpty) {
      final srRows = await (_db.select(_db.salesReturns).join([
        innerJoin(_db.salesInvoices, _db.salesInvoices.id.equalsExp(_db.salesReturns.salesInvoiceId)),
        leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.salesInvoices.customerId)),
      ])..where(_db.salesReturns.id.isIn(salesReturnIds))).get();

      for (final srr in srRows) {
        final ret = srr.readTable(_db.salesReturns);
        final cust = srr.readTableOrNull(_db.customers);
        salesReturnMap[ret.id] = (
          returnNumber: ret.returnNumber,
          customerName: cust?.customerName ?? 'عميل',
        );
      }
    }

    // Map purchase returns -> return number & supplier name
    final purchaseReturnMap = <String, ({String returnNumber, String supplierName})>{};
    if (purchaseReturnIds.isNotEmpty) {
      final prRows = await (_db.select(_db.purchaseReturns).join([
        innerJoin(_db.purchaseInvoices, _db.purchaseInvoices.id.equalsExp(_db.purchaseReturns.purchaseInvoiceId)),
        leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.purchaseInvoices.supplierId)),
      ])..where(_db.purchaseReturns.id.isIn(purchaseReturnIds))).get();

      for (final prr in prRows) {
        final ret = prr.readTable(_db.purchaseReturns);
        final sup = prr.readTableOrNull(_db.suppliers);
        purchaseReturnMap[ret.id] = (
          returnNumber: ret.returnNumber,
          supplierName: sup?.supplierName ?? 'مورد',
        );
      }
    }

    // 6. Chronological calculation
    double runningBalance = 0.0;
    double openingBalance = 0.0;
    double periodIn = 0.0;
    double periodOut = 0.0;
    final filteredMovements = <StockMovementItem>[];

    final queryClean = searchQuery?.trim().toLowerCase() ?? '';
    final endOfDay = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        : null;

    for (final row in rows) {
      final tx = row.readTable(_db.inventoryTransactions);
      final line = row.readTable(_db.inventoryTransactionLines);
      final unit = row.readTable(_db.productUnits);
      final prod = row.readTable(_db.products);

      final pCode = (unit.sku != null && unit.sku!.trim().isNotEmpty) ? unit.sku! : prod.productCode;
      final pName = prod.productName;
      final uName = unitMap[unit.unitId] ?? 'حبة';
      final wName = warehouseMap[tx.warehouseId] ?? selectedWarehouseName;

      final isInbound = tx.movementDirection == InventoryMovementDirection.inbound;
      final inQty = isInbound ? line.quantity : 0.0;
      final outQty = !isInbound ? line.quantity : 0.0;

      String movementTypeLabel = 'حركة مخزنية';
      String refNum = tx.referenceId ?? '';
      String party = '-';

      if (tx.referenceType == InventoryReferenceType.salesInvoice) {
        movementTypeLabel = 'فاتورة مبيعات';
        final info = salesMap[tx.referenceId];
        if (info != null) {
          refNum = info.invoiceNumber;
          party = 'العميل: ${info.customerName}';
        }
      } else if (tx.referenceType == InventoryReferenceType.purchaseInvoice) {
        movementTypeLabel = 'فاتورة مشتريات';
        final info = purchaseMap[tx.referenceId];
        if (info != null) {
          refNum = info.invoiceNumber;
          party = 'المورد: ${info.supplierName}';
        }
      } else if (tx.referenceType == InventoryReferenceType.salesReturn) {
        movementTypeLabel = 'مرتجع مبيعات';
        final info = salesReturnMap[tx.referenceId];
        if (info != null) {
          refNum = info.returnNumber;
          party = 'العميل: ${info.customerName}';
        }
      } else if (tx.referenceType == InventoryReferenceType.purchaseReturn) {
        movementTypeLabel = 'مرتجع مشتريات';
        final info = purchaseReturnMap[tx.referenceId];
        if (info != null) {
          refNum = info.returnNumber;
          party = 'المورد: ${info.supplierName}';
        }
      } else if (tx.referenceType == InventoryReferenceType.transfer) {
        final info = transferMap[tx.referenceId];
        if (isInbound) {
          movementTypeLabel = 'تحويل مخزني (وارد)';
          party = 'وارد من: ${info?.fromWarehouse ?? "مخزن آخر"}';
        } else {
          movementTypeLabel = 'تحويل مخزني (صادر)';
          party = 'محول إلى: ${info?.toWarehouse ?? "مخزن آخر"}';
        }
        if (info != null) refNum = info.transferNumber;
      } else if (tx.transactionType == InventoryTransactionType.adjustmentIn) {
        movementTypeLabel = 'تسوية جردية (إضافة)';
        party = 'تسوية جردية';
      } else if (tx.transactionType == InventoryTransactionType.adjustmentOut) {
        movementTypeLabel = 'تسوية جردية (عجز)';
        party = 'تسوية جردية';
      } else if (tx.transactionType == InventoryTransactionType.openingBalance) {
        movementTypeLabel = 'رصيد افتتاحي';
        party = 'رصيد بداية المدة';
      }

      final txDate = tx.transactionDate;

      // Opening balance calculation for dates prior to startDate
      if (startDate != null && txDate.isBefore(startDate)) {
        runningBalance += (inQty - outQty);
        openingBalance = runningBalance;
        continue;
      }

      if (endOfDay != null && txDate.isAfter(endOfDay)) {
        continue;
      }

      runningBalance += (inQty - outQty);
      periodIn += inQty;
      periodOut += outQty;

      if (queryClean.isNotEmpty) {
        final matchP = pName.toLowerCase().contains(queryClean) || pCode.toLowerCase().contains(queryClean);
        final matchRef = refNum.toLowerCase().contains(queryClean);
        final matchParty = party.toLowerCase().contains(queryClean);
        final matchType = movementTypeLabel.toLowerCase().contains(queryClean);
        if (!matchP && !matchRef && !matchParty && !matchType) {
          continue;
        }
      }

      filteredMovements.add(StockMovementItem(
        id: '${tx.id}_${line.id}',
        date: txDate,
        productCode: pCode,
        productName: pName,
        unitName: uName,
        movementType: movementTypeLabel,
        referenceNumber: refNum,
        partyName: party,
        inQty: inQty,
        outQty: outQty,
        runningBalance: runningBalance,
        warehouseName: wName,
      ));
    }

    return StockMovementReportSummary(
      movements: filteredMovements,
      openingBalance: openingBalance,
      totalIn: periodIn,
      totalOut: periodOut,
      netMovement: periodIn - periodOut,
      closingBalance: runningBalance,
      selectedWarehouseName: selectedWarehouseName,
      selectedProductName: selectedProductName,
      dateFilterTitle: dateFilterLabel ?? 'جميع الفترات',
      generatedAt: DateTime.now(),
    );
  }
}
