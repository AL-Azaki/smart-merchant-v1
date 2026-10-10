# 📦 PHASE 2: الكتالوج، المخزون، والوحدات، ومتوسط التكلفة المتحرك
## (Catalog, Unit Engine, Moving Average Costing & Stock Movements)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء محرك الوحدات والتحويلات الذكي (Base Unit + Conversion Factors) مع ربط الباركود والأسعار.
2. إدارة المخزون والمستودعات في Drift مع ضمان حفظ الأرصدة بوحدة الأساس الصغرى حصراً.
3. تطبيق خوارزمية **المتوسط المرجح المتحرك (Moving Weighted Average Cost)** عند الشراء، وخصم التكلفة عند البيع.
4. معالجة معضلة "البيع بالسالب" (Negative Stock Policy) وكيفية معالجة التكلفة تلقائياً دون تدمير الأرباح.
5. بناء دورة الحركات المخزنية والتسويات الجردية والتوالف مع قيودها المحاسبية الآلية.
6. حزمة اختبارات Unit Testing للتحقق من دقة التكلفة والتحويل بين الوحدات.

---

## 2. مخطط جداول Drift للمخزون والكتالوج (`inventory_tables.dart`)

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

// 1. جدول الوحدات العامة (حبة، درزن، كرتون، كجم، متر...)
@DataClassName('UnitData')
class UnitsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get nameAr => text().withLength(min: 1, max: 100).unique()(); // حبة
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();   // PCS, BOX, CTN
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. جدول المنتجات الرئيسي
@DataClassName('ProductData')
class ProductsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get category => text().nullable().withLength(max: 100)();
  TextColumn get sku => text().nullable().withLength(max: 100)();
  TextColumn get imagePath => text().nullable()();
  
  // هل الصنف مخزني (له كمية وتكلفة) أم خدمة/صيانة (ليس له مخزون)؟
  BoolColumn get isStockable => boolean().withDefault(const Constant(true))();
  
  // الوحدة الأساسية الصغرى للمنتج (تخزن الكميات في الداتابيز بهذه الوحدة دائماً)
  TextColumn get baseUnitId => text().references(UnitsTable, #id)();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. جدول وحدات المنتج وأسعارها وباركودها (Product Units & Barcodes)
@DataClassName('ProductUnitData')
class ProductUnitsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get productId => text().references(ProductsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get unitId => text().references(UnitsTable, #id)();
  
  // معامل التحويل إلى وحدة الأساس الصغرى (مثلاً: الكرتون = 24 حبة)
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))(); 
  
  TextColumn get barcode => text().nullable().unique()();
  
  // أسعار البيع والشراء الافتراضية لهذه الوحدة
  RealColumn get salePrice => real().withDefault(const Constant(0.0))();
  RealColumn get minSalePrice => real().withDefault(const Constant(0.0))(); // لمنع الكاشير من البيع بأقل منه
  RealColumn get purchasePrice => real().withDefault(const Constant(0.0))();

  BoolColumn get isDefaultSaleUnit => boolean().withDefault(const Constant(false))();
  BoolColumn get isDefaultPurchaseUnit => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. جدول المستودعات / المخازن
@DataClassName('WarehouseData')
class WarehousesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get code => text().withLength(min: 1, max: 50).unique()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. جدول رصيد المخزون اللحظي ومتوسط التكلفة (Current Inventory Snapshot)
@DataClassName('InventoryData')
class InventoriesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  TextColumn get productId => text().references(ProductsTable, #id)();
  
  // الكمية الحالية مقاسة بوحدة الأساس الصغرى (Base Quantity)
  RealColumn get quantityOnHand => real().withDefault(const Constant(0.0))();
  
  // متوسط التكلفة المرجح الحالي لكل وحدة أساس صغرى (بعملة الأساس المحلية)
  RealColumn get averageCost => real().withDefault(const Constant(0.0))();
  
  RealColumn get alertQuantity => real().withDefault(const Constant(5.0))(); // حد التنبيه لنقص البضاعة
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {warehouseId, productId},
  ];
}

// 6. جدول سجل الحركات المخزنية التفصيلي (Inventory Movement Ledger)
@DataClassName('InventoryTransactionData')
class InventoryTransactionsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  TextColumn get productId => text().references(ProductsTable, #id)();
  
  // نوع الحركة: 'In', 'Out', 'Adjustment', 'Damage', 'Transfer'
  TextColumn get transactionType => text()(); 
  
  // الكمية بوحدة الأساس
  RealColumn get quantity => real()();
  
  // تكلفة وحدة الأساس وقت الحركة
  RealColumn get unitCost => real().withDefault(const Constant(0.0))();
  
  // نوع المرجع: 'SalesInvoice', 'PurchaseInvoice', 'StockTake', 'DamageVoucher'
  TextColumn get referenceType => text()();
  TextColumn get referenceId => text()();
  
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. محرك تحويل الوحدات (Unit Conversion & Pricing Engine)

### 3.1 القاعدة الذهبية: قاعدة بيانات موحدة بوحدة الأساس
* إذا كان المنتج "عصير راني":
  * وحدة الأساس = `حبة` (معامل = 1).
  * وحدة الكرتون = `كرتون` (معامل = 24).
* عند شراء 10 كراتين: يُضاف في جدول `inventories` كمية `10 * 24 = 240 حبة`.
* عند بيع كرتون واحد: يُخصم من جدول `inventories` كمية `1 * 24 = 24 حبة`.
* عند بيع 3 حبات مفردة: يُخصم من جدول `inventories` كمية `3 حبات`.

### 3.2 فئة محول الوحدات (UnitConverter Utility):
```dart
class UnitConverter {
  /// تحويل كمية مدخلة إلى كمية بوحدة الأساس الصغرى
  static double toBaseQuantity({
    required double enteredQuantity,
    required double conversionFactor,
  }) {
    return PrecisionMath.roundMoney(enteredQuantity * conversionFactor, decimals: 3);
  }

  /// تحويل تكلفة وحدة الأساس إلى تكلفة الوحدة الكبرى
  static double toUnitCost({
    required double baseUnitCost,
    required double conversionFactor,
  }) {
    return PrecisionMath.roundMoney(baseUnitCost * conversionFactor, decimals: 2);
  }
}
```

---

## 4. خوارزمية المتوسط المرجح المتحرك (Moving Weighted Average Cost)

### 4.1 معادلة إعادة احتساب التكلفة عند الشراء:
يتم استدعاء هذه المعادلة **فقط** عند استلام فاتورة مشتريات أو إدخال بضاعة:

$$NewAverageCost = \frac{(CurrentQty \times CurrentAvgCost) + (NewQty \times NewPurchasePriceInBaseCurrency)}{CurrentQty + NewQty}$$

### 4.2 الحالات الخاصة والحرجة (Critical Edge Cases):

#### الحالة 1: الرصيد الحالي صفر أو سالب (Zero or Negative Stock)
* إذا كان المخزن به صفر أو `-5 حبات` (تم بيعها قبل إدخال الفاتورة) واشترينا `10 حبات` بسعر `100 ريال`.
* **الحل المعماري:** يصبح متوسط التكلفة الجديد مباشرة هو سعر الشراء الجديد (`100 ريال`)، وتصبح الكمية الجديدة `(-5 + 10) = 5 حبات`.
* لا نضرب الكمية السالبة في التكلفة القديمة لكي لا ينهار الكسر ويتحول متوسط التكلفة إلى قيمة وهمية أو سالبة!

#### الحالة 2: حركة البيع (Sales Movement)
* حركة البيع **لا تغير متوسط التكلفة مطلقاً**!
* يتم خصم الكمية من المخزون، وتُسجل تكلفة البضاعة المباعة (COGS) في القيد المحاسبي بالقيمة: `الكمية المباعة بوحدة الأساس * متوسط التكلفة الحالي`.

---

## 5. خدمة إدارة المخزون الميدانية (InventoryService Implementation)

```dart
class InventoryService {
  final AppDatabase db;
  InventoryService(this.db);

  /// معالجة حركة توريد مخزني وتحديث متوسط التكلفة
  Future<void> processStockIn({
    required String warehouseId,
    required String productId,
    required double quantityInBaseUnit,
    required double purchasePriceInBaseUnit,
    required String referenceType,
    required String referenceId,
  }) async {
    final currentInv = await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();

    double newQty = quantityInBaseUnit;
    double newAvgCost = purchasePriceInBaseUnit;

    if (currentInv != null) {
      final currentQty = currentInv.quantityOnHand;
      final currentCost = currentInv.averageCost;

      if (currentQty > 0) {
        // تطبيق معادلة المتوسط المرجح المتحرك
        final totalOldValue = currentQty * currentCost;
        final totalNewValue = quantityInBaseUnit * purchasePriceInBaseUnit;
        newQty = PrecisionMath.roundMoney(currentQty + quantityInBaseUnit, decimals: 3);
        newAvgCost = PrecisionMath.roundMoney((totalOldValue + totalNewValue) / newQty, decimals: 2);
      } else {
        // إذا كان المخزون سالباً أو صفراً
        newQty = PrecisionMath.roundMoney(currentQty + quantityInBaseUnit, decimals: 3);
        newAvgCost = purchasePriceInBaseUnit;
      }

      await (db.update(db.inventoriesTable)
            ..where((i) => i.id.equals(currentInv.id)))
          .write(
        InventoriesTableCompanion(
          quantityOnHand: Value(newQty),
          averageCost: Value(newAvgCost),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // إدراج صنف جديد في المستودع
      await db.into(db.inventoriesTable).insert(
        InventoriesTableCompanion.insert(
          warehouseId: warehouseId,
          productId: productId,
          quantityOnHand: Value(newQty),
          averageCost: Value(newAvgCost),
        ),
      );
    }

    // تسجيل الحركة في سجل حركات المخزون
    await db.into(db.inventoryTransactionsTable).insert(
      InventoryTransactionsTableCompanion.insert(
        warehouseId: warehouseId,
        productId: productId,
        transactionType: 'In',
        quantity: quantityInBaseUnit,
        unitCost: Value(purchasePriceInBaseUnit),
        referenceType: referenceType,
        referenceId: referenceId,
      ),
    );
  }

  /// معالجة حركة صرف مخزني للبيع
  Future<double> processStockOut({
    required String warehouseId,
    required String productId,
    required double quantityInBaseUnit,
    required String referenceType,
    required String referenceId,
  }) async {
    final currentInv = await (db.select(db.inventoriesTable)
          ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
        .getSingleOrNull();

    final currentCost = currentInv?.averageCost ?? 0.0;
    final currentQty = currentInv?.quantityOnHand ?? 0.0;
    final newQty = PrecisionMath.roundMoney(currentQty - quantityInBaseUnit, decimals: 3);

    if (currentInv != null) {
      await (db.update(db.inventoriesTable)..where((i) => i.id.equals(currentInv.id))).write(
        InventoriesTableCompanion(
          quantityOnHand: Value(newQty),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      // بيع بالسالب لصنف لم يُعرف له رصيد بعد
      await db.into(db.inventoriesTable).insert(
        InventoriesTableCompanion.insert(
          warehouseId: warehouseId,
          productId: productId,
          quantityOnHand: Value(newQty),
          averageCost: const Value(0.0),
        ),
      );
    }

    // تسجيل حركة الخروج
    await db.into(db.inventoryTransactionsTable).insert(
      InventoryTransactionsTableCompanion.insert(
        warehouseId: warehouseId,
        productId: productId,
        transactionType: 'Out',
        quantity: quantityInBaseUnit,
        unitCost: Value(currentCost),
        referenceType: referenceType,
        referenceId: referenceId,
      ),
    );

    // إرجاع إجمالي التكلفة الخارجة لإنشاء قيد تكلفة المبيعات
    return PrecisionMath.roundMoney(quantityInBaseUnit * currentCost, decimals: 2);
  }
}
```

---

## 6. معايير القبول والرفض للمرحلة 2 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] عند إدخال 5 كراتين من صنف (معامل 12)، يسجل رصيد المخزن 60 حبة بدقة.
* [ ] عند بيع 10 حبات، يقل رصيد المخزن إلى 50 حبة دون أي تأثير على متوسط التكلفة.
* [ ] شراء 10 حبات بتكلفة 100، ثم شراء 10 حبات بتكلفة 200 ينتج عنه متوسط تكلفة دقيق = 150 ريال.
* [ ] استدعاء الباركود في الكاشير يُرجع المعرف المحدد للوحدة المرتبطة بذلك الباركود وسعر بيعها الخاص.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** تخزين الكميات في جدول `inventories` بوحدات مختلفة (يجب التوحيد دائماً لوحدة الأساس).
* ❌ **ممنوع منعاً باتاً:** تعديل متوسط التكلفة أثناء فواتير البيع.
* ❌ **ممنوع منعاً باتاً:** حذف صنف مرتبط بحركات مخزنية أو فواتير سابقة (يُعطل فقط `isActive = false`).

---

## 7. حزمة اختبارات الـ Unit Testing للمرحلة 2 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/modules/inventory/inventory_costing_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/inventory/application/inventory_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService inventoryService;
  late String warehouseId;
  late String pieceUnitId;
  late String boxUnitId;
  late String productId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    inventoryService = InventoryService(db);

    warehouseId = await db.into(db.warehousesTable).insert(
      WarehousesTableCompanion.insert(name: 'المستودع الرئيسي', code: 'WH-01'),
    );

    pieceUnitId = await db.into(db.unitsTable).insert(
      UnitsTableCompanion.insert(nameAr: 'حبة', code: 'PCS'),
    );

    boxUnitId = await db.into(db.unitsTable).insert(
      UnitsTableCompanion.insert(nameAr: 'كرتون', code: 'BOX'),
    );

    productId = await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(
        name: 'شاي الكبوس',
        baseUnitId: pieceUnitId,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات متوسط التكلفة المرجح وحركات المخزون', () {
    test('يجب احتساب المتوسط المرجح بشكل رياضي صحيح عند الشراء المتتالي', () async {
      // 1. شراء 10 حبات بسعر 100 ريال
      await inventoryService.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 10.0,
        purchasePriceInBaseUnit: 100.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-01',
      );

      var inv = await (db.select(db.inventoriesTable)
            ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
          .getSingle();

      expect(inv.quantityOnHand, 10.0);
      expect(inv.averageCost, 100.0);

      // 2. شراء 10 حبات إضافية بسعر 200 ريال
      // المتوقع: (10 * 100 + 10 * 200) / 20 = 3000 / 20 = 150 ريال
      await inventoryService.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 10.0,
        purchasePriceInBaseUnit: 200.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-02',
      );

      inv = await (db.select(db.inventoriesTable)
            ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
          .getSingle();

      expect(inv.quantityOnHand, 20.0);
      expect(inv.averageCost, 150.0);
    });

    test('حركة البيع يجب أن تخصم الكمية وتحافظ على متوسط التكلفة دون تغيير', () async {
      // إدخال رصيد 20 حبة بتكلفة 150
      await inventoryService.processStockIn(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 20.0,
        purchasePriceInBaseUnit: 150.0,
        referenceType: 'PurchaseInvoice',
        referenceId: 'PUR-01',
      );

      // بيع 5 حبات
      final cogs = await inventoryService.processStockOut(
        warehouseId: warehouseId,
        productId: productId,
        quantityInBaseUnit: 5.0,
        referenceType: 'SalesInvoice',
        referenceId: 'INV-01',
      );

      // تكلفة البضاعة المباعة لـ 5 حبات = 5 * 150 = 750 ريال
      expect(cogs, 750.0);

      final inv = await (db.select(db.inventoriesTable)
            ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
          .getSingle();

      // المتبقي 15 حبة، ومتوسط التكلفة ما زال 150 ريال
      expect(inv.quantityOnHand, 15.0);
      expect(inv.averageCost, 150.0);
    });
  });
}
```
