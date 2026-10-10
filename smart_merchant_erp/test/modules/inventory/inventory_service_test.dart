import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/inventory/application/inventory_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService service;
  late String warehouseId;
  late String pieceUnitId;
  late String productId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = InventoryService(db);

    warehouseId = const Uuid().v4();
    await db.into(db.warehousesTable).insert(
      WarehousesTableCompanion.insert(
        id: Value(warehouseId),
        name: 'المستودع المركزي',
        code: 'WH-MAIN',
        isDefault: const Value(true),
      ),
    );

    pieceUnitId = const Uuid().v4();
    await db.into(db.unitsTable).insert(
      UnitsTableCompanion.insert(
        id: Value(pieceUnitId),
        nameAr: 'حبة',
        code: 'PCS',
      ),
    );

    productId = const Uuid().v4();
    await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(
        id: Value(productId),
        name: 'تونة الغواص 185 جم',
        baseUnitId: pieceUnitId,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryService Moving Weighted Average Cost Tests', () {
    test('حساب المتوسط المرجح المتحرك بشكل تراكمي دقيق عند الشراء المتتالي', () async {
      // 1. الشراء الأول: 10 حبات بسعر 100 ريال
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 10.0,
        purchasePriceInBaseUnit: 100.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-01',
      );

      var stock = await service.getStock(warehouseId, productId);
      expect(stock, isNotNull);
      expect(stock!.quantityOnHand, equals(10.0));
      expect(stock.averageCost, equals(100.0));

      // 2. الشراء الثاني: 10 حبات بسعر 200 ريال
      // المتوقع: (10 * 100 + 10 * 200) / 20 = 3000 / 20 = 150 ريال
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 10.0,
        purchasePriceInBaseUnit: 200.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-02',
      );

      stock = await service.getStock(warehouseId, productId);
      expect(stock!.quantityOnHand, equals(20.0));
      expect(stock.averageCost, equals(150.0));

      // 3. الشراء الثالث: 20 حبة بسعر 300 ريال
      // المتوقع: (20 * 150 + 20 * 300) / 40 = (3000 + 6000) / 40 = 9000 / 40 = 225 ريال
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 20.0,
        purchasePriceInBaseUnit: 300.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-03',
      );

      stock = await service.getStock(warehouseId, productId);
      expect(stock!.quantityOnHand, equals(40.0));
      expect(stock.averageCost, equals(225.0));
    });

    test('حركة البيع تخصم الكمية وتحسب تكلفة البضاعة المباعة مع ثبات متوسط التكلفة', () async {
      // إدخال 40 حبة بمتوسط تكلفة 225
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 40.0,
        purchasePriceInBaseUnit: 225.0,
        referenceType: 'Initial',
        referenceId: 'INIT-01',
      );

      // بيع 15 حبة
      final totalCogs = await service.processStockOut(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 15.0,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-01',
      );

      // تكلفة البضاعة المباعة لـ 15 حبة = 15 * 225 = 3,375 ريال
      expect(totalCogs, equals(3375.0));

      final stock = await service.getStock(warehouseId, productId);
      // المتبقي: 40 - 15 = 25 حبة
      expect(stock!.quantityOnHand, equals(25.0));
      // متوسط التكلفة لا يتغير عند البيع = 225 ريال
      expect(stock.averageCost, equals(225.0));

      // التأكد من تسجيل الحركة في جدول الحركات
      final txs = await db.select(db.inventoryTransactionsTable).get();
      expect(txs.length, equals(2)); // حركة دخول + حركة خروج
      expect(txs.last.transactionType, equals('Out'));
      expect(txs.last.quantity, equals(15.0));
      expect(txs.last.unitCost, equals(225.0));
    });

    test('التعافي المحاسبي السليم عند البيع بالسالب ثم الشراء اللاحق', () async {
      // بيع 5 حبات وصنف المخزن صفر (بيع بالسالب)
      await service.processStockOut(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 5.0,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-NEG-1',
      );

      var stock = await service.getStock(warehouseId, productId);
      expect(stock!.quantityOnHand, equals(-5.0));

      // شراء 10 حبات لاحقة بسعر 400 ريال
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 10.0,
        purchasePriceInBaseUnit: 400.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-REC-1',
      );

      stock = await service.getStock(warehouseId, productId);
      // الرصيد الجديد: -5 + 10 = 5 حبات
      expect(stock!.quantityOnHand, equals(5.0));
      // التكلفة تستقر عند سعر الشراء الجديد (400 ريال) دون انهيار المعادلة
      expect(stock.averageCost, equals(400.0));
    });

    test('تسوية الجرد الفعلي تحدث الرصيد وتثبت الفارق مع ثبات متوسط التكلفة', () async {
      // رصيد سابق 30 حبة بتكلفة 150
      await service.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 30.0,
        purchasePriceInBaseUnit: 150.0,
        referenceType: 'Initial',
        referenceId: 'INIT-01',
      );

      // كشف الجرد الفعلي على الرفوف وجد 27 حبة فقط (عجز 3 حبات تالفة)
      final varianceValue = await service.processStockAdjustment(
        warehouseId: warehouseId,
        productId: productId,
        actualPhysicalCountInBaseUnit: 27.0,
        referenceId: 'AUDIT-2026',
        reason: 'تالف جردي',
      );

      // قيمة العجز: -3 * 150 = -450 ريال
      expect(varianceValue, equals(-450.0));

      final stock = await service.getStock(warehouseId, productId);
      expect(stock!.quantityOnHand, equals(27.0));
      expect(stock.averageCost, equals(150.0));

      final txs = await (db.select(db.inventoryTransactionsTable)
            ..where((t) => t.referenceType.equals('StockTake')))
          .getSingle();
      expect(txs.transactionType, equals('Damage'));
      expect(txs.quantity, equals(3.0));
    });
  });
}
