import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../kernel/storage/app_database.dart';
import '../enums/inventory_movement_direction.dart';
import '../enums/inventory_transaction_status.dart';
import '../enums/inventory_transaction_type.dart';

class DemoDataStats {
  final int productsCount;
  final int customersCount;
  final int suppliersCount;

  const DemoDataStats({
    required this.productsCount,
    required this.customersCount,
    required this.suppliersCount,
  });
}

/// Service to generate and wipe rich demo retail data (100 Products, 50 Customers, 50 Suppliers)
/// for the current active merchant business in Flutter ERP.
class DemoDataSeederService {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DemoDataSeederService(this._db);

  /// Fetch counts of products, customers, and suppliers for the specified business
  Future<DemoDataStats> getStats(String businessId) async {
    final products = await (_db.select(_db.products)
          ..where((t) => t.businessId.equals(businessId)))
        .get();

    final customers = await (_db.select(_db.customers)
          ..where((t) => t.businessId.equals(businessId)))
        .get();

    final suppliers = await (_db.select(_db.suppliers)
          ..where((t) => t.businessId.equals(businessId)))
        .get();

    return DemoDataStats(
      productsCount: products.length,
      customersCount: customers.length,
      suppliersCount: suppliers.length,
    );
  }

  /// Seeds 100 realistic Arabic products, 50 customers, and 50 suppliers
  Future<void> seedDemoData({
    required String businessId,
    required String branchId,
    required String userId,
  }) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      const currencyId = 'YER';

      // 0. Ensure currency exists
      await _db.into(_db.currencies).insertOnConflictUpdate(
        CurrenciesCompanion.insert(
          id: currencyId,
          currencyCode: currencyId,
          currencyNameAr: 'ريال يمني',
          currencyNameEn: 'Yemeni Rial',
          currencySymbol: '﷼',
          isBaseCurrency: const Value(true),
          isActive: const Value(true),
        ),
      );

      // 0.1 Ensure user exists safely
      final existingUser = await (_db.select(_db.usersTable)
            ..where((u) => u.id.equals(userId)))
          .getSingleOrNull();

      if (existingUser == null) {
        await _db.into(_db.usersTable).insertOnConflictUpdate(
          UsersTableCompanion.insert(
            id: Value(userId),
            email: 'admin@smartmerchant.com',
            passwordHash: '',
            firstName: 'المدير',
            lastName: 'العام',
            isActive: const Value(true),
          ),
        );
      }

      // 0.2 Ensure account exists in accountsTable
      final accountId = 'account-$businessId';
      await _db.into(_db.accountsTable).insertOnConflictUpdate(
        AccountsTableCompanion.insert(
          id: Value(accountId),
          ownerId: userId,
          businessName: 'المتجر الرئيسي',
          businessType: 'Retail',
          defaultCurrency: currencyId,
        ),
      );

      // 0.3 CRITICAL: Ensure business exists in businesses table to satisfy FK constraints
      await _db.into(_db.businesses).insertOnConflictUpdate(
        BusinessesCompanion.insert(
          id: businessId,
          accountId: accountId,
          businessName: 'المتجر الرئيسي',
          businessType: const Value('Retail'),
          status: const Value('Active'),
        ),
      );

      // 0.4 Ensure branch exists in branches table
      final effectiveBranchId = branchId.isNotEmpty ? branchId : 'branch-$businessId';
      await _db.into(_db.branches).insertOnConflictUpdate(
        BranchesCompanion.insert(
          id: effectiveBranchId,
          businessId: businessId,
          branchName: 'الفرع الرئيسي',
          branchCode: 'MAIN',
          isActive: const Value(true),
        ),
      );

      // 1. Ensure default warehouse exists
      final existingWh = await (_db.select(_db.warehouses)
            ..where((w) => w.businessId.equals(businessId))
            ..limit(1))
          .getSingleOrNull();

      final String whId = existingWh?.id ?? 'wh-demo-$businessId';
      if (existingWh == null) {
        await _db.into(_db.warehouses).insertOnConflictUpdate(
          WarehousesCompanion.insert(
            id: whId,
            businessId: businessId,
            branchId: effectiveBranchId,
            warehouseName: 'المستودع الرئيسي',
            warehouseCode: 'MAIN-WH',
            isDefault: const Value(true),
            isActive: const Value(true),
          ),
        );
      }

      // 2. Categories (Lookup existing by code or name to avoid UNIQUE constraint violations)
      final categoriesData = [
        {'id': 'cat-food', 'name': 'المواد الغذائية والتموينية', 'code': 'FOOD'},
        {'id': 'cat-beverage', 'name': 'المشروبات والعصائر والمياه', 'code': 'BEV'},
        {'id': 'cat-dairy', 'name': 'الألبان والأجبان والبيض', 'code': 'DAIRY'},
        {'id': 'cat-clean', 'name': 'المنظفات والعناية المنزلية', 'code': 'CLEAN'},
        {'id': 'cat-personal', 'name': 'العناية الشخصية ومستحضرات النظافة', 'code': 'CARE'},
        {'id': 'cat-sweets', 'name': 'الحلويات والمقرمشات والبسكويت', 'code': 'SWEET'},
        {'id': 'cat-spices', 'name': 'البهارات والتوابل والملح', 'code': 'SPICE'},
        {'id': 'cat-canned', 'name': 'المعلبات والأغذية المحفوظة', 'code': 'CANNED'},
      ];

      final Map<String, String> resolvedCategoryIds = {};

      for (final cat in categoriesData) {
        final code = cat['code']!;
        final name = cat['name']!;

        final existingCat = await (_db.select(_db.categories)
              ..where((c) =>
                  c.businessId.equals(businessId) &
                  (c.categoryCode.equals(code) | c.categoryName.equals(name))))
            .getSingleOrNull();

        if (existingCat != null) {
          resolvedCategoryIds[cat['id']!] = existingCat.id;
        } else {
          final catId = '${cat['id']}-$businessId';
          await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              id: catId,
              businessId: businessId,
              categoryName: name,
              categoryCode: Value(code),
              isActive: const Value(true),
            ),
            mode: InsertMode.insertOrReplace,
          );
          resolvedCategoryIds[cat['id']!] = catId;
        }
      }

      // 3. Units (Lookup existing by symbol or name to avoid UNIQUE constraint violations)
      final unitsData = [
        {'id': 'unit-pcs', 'name': 'حبة (قطعة)', 'symbol': 'حبة'},
        {'id': 'unit-kg', 'name': 'كيلوجرام', 'symbol': 'كجم'},
        {'id': 'unit-box', 'name': 'كرتون', 'symbol': 'كرتون'},
        {'id': 'unit-ltr', 'name': 'لتر', 'symbol': 'لتر'},
        {'id': 'unit-pack', 'name': 'شدة / عبوة', 'symbol': 'عبوة'},
      ];

      final Map<String, String> resolvedUnitIds = {};

      for (final u in unitsData) {
        final symbol = u['symbol']!;
        final name = u['name']!;

        final existingUnit = await (_db.select(_db.units)
              ..where((unit) =>
                  unit.businessId.equals(businessId) &
                  (unit.unitSymbol.equals(symbol) | unit.unitName.equals(name))))
            .getSingleOrNull();

        if (existingUnit != null) {
          resolvedUnitIds[u['id']!] = existingUnit.id;
        } else {
          final uId = '${u['id']}-$businessId';
          await _db.into(_db.units).insert(
            UnitsCompanion.insert(
              id: uId,
              businessId: businessId,
              unitName: name,
              unitSymbol: symbol,
              isActive: const Value(true),
            ),
            mode: InsertMode.insertOrReplace,
          );
          resolvedUnitIds[u['id']!] = uId;
        }
      }

      // 4. 100 Realistic Retail & Supermarket Products
      final rawProducts = _get100Products();

      for (final p in rawProducts) {
        final pCode = p['code'] as String;
        final catId = resolvedCategoryIds[p['cat'] as String] ?? '${p['cat']}-$businessId';
        final unitId = resolvedUnitIds[p['unit'] as String] ?? '${p['unit']}-$businessId';
        final pName = p['name'] as String;
        final pBarcode = p['barcode'] as String;
        final pPrice = p['price'] as double;
        final pStock = p['stock'] as double;
        final pCost = pPrice * 0.72; // 28% margin

        // Check if product with this code already exists for this business
        final existingProd = await (_db.select(_db.products)
              ..where((prod) =>
                  prod.businessId.equals(businessId) & prod.productCode.equals(pCode)))
            .getSingleOrNull();

        final String pId = existingProd?.id ?? 'prod-$pCode-$businessId';

        if (existingProd != null) {
          await (_db.update(_db.products)..where((prod) => prod.id.equals(pId))).write(
            ProductsCompanion(
              categoryId: Value(catId),
              productName: Value(pName),
              showInStore: const Value(true),
              isActive: const Value(true),
            ),
          );
        } else {
          await _db.into(_db.products).insert(
            ProductsCompanion.insert(
              id: pId,
              businessId: businessId,
              categoryId: Value(catId),
              productType: const Value('standard'),
              productName: pName,
              productCode: pCode,
              showInStore: const Value(true),
              isActive: const Value(true),
            ),
          );
        }

        // Product Unit: check if already exists by (productId, unitId) or barcode or sku
        final existingPu = await (_db.select(_db.productUnits)
              ..where((pu) =>
                  pu.businessId.equals(businessId) &
                  ((pu.productId.equals(pId) & pu.unitId.equals(unitId)) |
                   pu.barcode.equals(pBarcode) |
                   pu.sku.equals('$pCode-BASE'))))
            .getSingleOrNull();

        final String puId = existingPu?.id ?? 'pu-$pId';

        if (existingPu != null) {
          await (_db.update(_db.productUnits)..where((pu) => pu.id.equals(puId))).write(
            ProductUnitsCompanion(
              productId: Value(pId),
              unitId: Value(unitId),
              sku: Value('$pCode-BASE'),
              barcode: Value(pBarcode),
              sellingPrice: Value(pPrice),
              purchasePrice: Value(pCost),
              isActive: const Value(true),
            ),
          );
        } else {
          await _db.into(_db.productUnits).insert(
            ProductUnitsCompanion.insert(
              id: puId,
              businessId: businessId,
              productId: pId,
              unitId: unitId,
              sku: Value('$pCode-BASE'),
              barcode: Value(pBarcode),
              conversionFactor: const Value(1.0),
              isBaseUnit: const Value(true),
              sellingPrice: Value(pPrice),
              purchasePrice: Value(pCost),
              minimumPrice: const Value(0.0),
              isActive: const Value(true),
            ),
          );
        }

        // Inventory Stock
        final existingInv = await (_db.select(_db.inventories)
              ..where((inv) =>
                  inv.businessId.equals(businessId) &
                  inv.warehouseId.equals(whId) &
                  inv.productUnitId.equals(puId)))
            .getSingleOrNull();

        final String invId = existingInv?.id ?? 'inv-$puId';

        if (existingInv != null) {
          await (_db.update(_db.inventories)..where((inv) => inv.id.equals(invId))).write(
            InventoriesCompanion(
              quantity: Value(pStock),
              averageCost: Value(pCost),
            ),
          );
        } else {
          await _db.into(_db.inventories).insert(
            InventoriesCompanion.insert(
              id: invId,
              businessId: businessId,
              warehouseId: whId,
              productUnitId: puId,
              quantity: Value(pStock),
              averageCost: Value(pCost),
            ),
          );
        }

        // Opening Balance Transaction Line
        final txnId = _uuid.v4();
        await _db.into(_db.inventoryTransactions).insert(
          InventoryTransactionsCompanion.insert(
            id: txnId,
            businessId: businessId,
            branchId: effectiveBranchId,
            transactionType: InventoryTransactionType.openingBalance,
            movementDirection: InventoryMovementDirection.inbound,
            transactionDate: Value(now),
            status: const Value(InventoryTransactionStatus.posted),
            warehouseId: whId,
            createdBy: userId,
          ),
          mode: InsertMode.insertOrIgnore,
        );

        await _db.into(_db.inventoryTransactionLines).insert(
          InventoryTransactionLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            inventoryTransactionId: txnId,
            productUnitId: puId,
            quantity: pStock,
            unitCost: Value(pCost),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      // 5. 50 Realistic Arabic Customers
      final rawCustomers = _get50Customers();
      for (int i = 0; i < rawCustomers.length; i++) {
        final c = rawCustomers[i];
        final cId = 'cust-demo-${i + 1}-$businessId';

        await _db.into(_db.customers).insertOnConflictUpdate(
          CustomersCompanion.insert(
            id: cId,
            businessId: businessId,
            customerName: c['name'] as String,
            phone: Value(c['phone'] as String),
            address: Value(c['address'] as String),
            creditLimit: Value(c['credit'] as double),
            isActive: const Value(true),
          ),
        );
      }

      // 6. 50 Realistic Arabic Suppliers
      final rawSuppliers = _get50Suppliers();
      for (int i = 0; i < rawSuppliers.length; i++) {
        final s = rawSuppliers[i];
        final sId = 'sup-demo-${i + 1}-$businessId';

        await _db.into(_db.suppliers).insertOnConflictUpdate(
          SuppliersCompanion.insert(
            id: sId,
            businessId: businessId,
            supplierName: s['name'] as String,
            contactPerson: Value(s['contact'] as String),
            phone: Value(s['phone'] as String),
            supplierAddress: Value(s['address'] as String),
            isActive: const Value(true),
          ),
        );
      }
    });
  }

  /// Wipes only demo data (Products, Product Units, Inventories, Customers, Suppliers)
  /// for the specified business, leaving accounts, currencies, branches, and users intact.
  Future<void> wipeDemoData({required String businessId}) async {
    await _db.transaction(() async {
      // 1. Wipe Inventories for this business
      await (_db.delete(_db.inventories)..where((t) => t.businessId.equals(businessId))).go();

      // 2. Wipe Inventory Transaction Lines & Transactions
      final txns = await (_db.select(_db.inventoryTransactions)..where((t) => t.businessId.equals(businessId))).get();
      for (final txn in txns) {
        await (_db.delete(_db.inventoryTransactionLines)..where((t) => t.inventoryTransactionId.equals(txn.id))).go();
      }
      await (_db.delete(_db.inventoryTransactions)..where((t) => t.businessId.equals(businessId))).go();

      // 3. Wipe Product Units
      await (_db.delete(_db.productUnits)..where((t) => t.businessId.equals(businessId))).go();

      // 4. Wipe Products
      await (_db.delete(_db.products)..where((t) => t.businessId.equals(businessId))).go();

      // 5. Wipe Customers
      await (_db.delete(_db.customers)..where((t) => t.businessId.equals(businessId))).go();

      // 6. Wipe Suppliers
      await (_db.delete(_db.suppliers)..where((t) => t.businessId.equals(businessId))).go();
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Data Providers: 100 Products, 50 Customers, 50 Suppliers
  // ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _get100Products() {
    return [
      // 1-15: Water & Juices & Hot Drinks
      {'code': 'PRD-001', 'name': 'مياه شملان معدنية 750 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 250.0, 'stock': 150.0, 'barcode': '629110010001'},
      {'code': 'PRD-002', 'name': 'مياه حدة نقية 500 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 200.0, 'stock': 180.0, 'barcode': '629110010002'},
      {'code': 'PRD-003', 'name': 'مياه صنعاء صحية 1.5 لتر', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 350.0, 'stock': 100.0, 'barcode': '629110010003'},
      {'code': 'PRD-004', 'name': 'عصير سيزر تفاح طبيعي 1 لتر', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 900.0, 'stock': 50.0, 'barcode': '629110010004'},
      {'code': 'PRD-005', 'name': 'عصير سيزر برتقال وجزر 1 لتر', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 900.0, 'stock': 45.0, 'barcode': '629110010005'},
      {'code': 'PRD-006', 'name': 'عصير راني مانجو حبيبات 250 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 400.0, 'stock': 120.0, 'barcode': '629110010006'},
      {'code': 'PRD-007', 'name': 'عصير راني خوخ حبيبات 250 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 400.0, 'stock': 90.0, 'barcode': '629110010007'},
      {'code': 'PRD-008', 'name': 'مشروب شعير باربيكان تفاح 330 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 650.0, 'stock': 75.0, 'barcode': '629110010008'},
      {'code': 'PRD-009', 'name': 'مشروب شعير باربيكان فراولة 330 مل', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 650.0, 'stock': 60.0, 'barcode': '629110010009'},
      {'code': 'PRD-010', 'name': 'شاي الكبوس أحمر فاخر 227 جم', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 750.0, 'stock': 110.0, 'barcode': '629110010010'},
      {'code': 'PRD-011', 'name': 'شاي الكبوس أحمر فرط 454 جم', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 1450.0, 'stock': 60.0, 'barcode': '629110010011'},
      {'code': 'PRD-012', 'name': 'شاي الربيع إكسبرس 100 كيس', 'cat': 'cat-beverage', 'unit': 'unit-box', 'price': 1400.0, 'stock': 55.0, 'barcode': '629110010012'},
      {'code': 'PRD-013', 'name': 'شاي الربيع أخضر نقي 100 كيس', 'cat': 'cat-beverage', 'unit': 'unit-box', 'price': 1600.0, 'stock': 40.0, 'barcode': '629110010013'},
      {'code': 'PRD-014', 'name': 'بن يمني خولاني محمص ومطحون 250 جم', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 2200.0, 'stock': 40.0, 'barcode': '629110010014'},
      {'code': 'PRD-015', 'name': 'نسكافيه كلاسيك قهوة سريعة 200 جم', 'cat': 'cat-beverage', 'unit': 'unit-pcs', 'price': 3400.0, 'stock': 35.0, 'barcode': '629110010015'},

      // 16-30: Rice, Sugar, Flour & Cooking Oils
      {'code': 'PRD-016', 'name': 'أرز الشعلان بسمتي عنبر 5 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 6800.0, 'stock': 40.0, 'barcode': '629110010016'},
      {'code': 'PRD-017', 'name': 'أرز الشعلان بسمتي عنبر 10 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 13200.0, 'stock': 25.0, 'barcode': '629110010017'},
      {'code': 'PRD-018', 'name': 'أرز الوليمة مزة هندي 5 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 7000.0, 'stock': 35.0, 'barcode': '629110010018'},
      {'code': 'PRD-019', 'name': 'أرز الوليمة مزة هندي 10 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 13800.0, 'stock': 30.0, 'barcode': '629110010019'},
      {'code': 'PRD-020', 'name': 'أرز أبو كاس مزة هندي 5 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 6900.0, 'stock': 25.0, 'barcode': '629110010020'},
      {'code': 'PRD-021', 'name': 'سكر السعيد أبيض نقي 5 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 3800.0, 'stock': 65.0, 'barcode': '629110010021'},
      {'code': 'PRD-022', 'name': 'سكر الأسرة فاخر 1 كجم', 'cat': 'cat-food', 'unit': 'unit-kg', 'price': 850.0, 'stock': 90.0, 'barcode': '629110010022'},
      {'code': 'PRD-023', 'name': 'سكر الأسرة فاخر 5 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 3900.0, 'stock': 45.0, 'barcode': '629110010023'},
      {'code': 'PRD-024', 'name': 'دقيق السعيد فاخر أبيض 10 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 5200.0, 'stock': 50.0, 'barcode': '629110010024'},
      {'code': 'PRD-025', 'name': 'دقيق السعيد أبيض 25 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 12500.0, 'stock': 20.0, 'barcode': '629110010025'},
      {'code': 'PRD-026', 'name': 'دقيق كويتي فاخر متعدد الاستخدام 2 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 1400.0, 'stock': 40.0, 'barcode': '629110010026'},
      {'code': 'PRD-027', 'name': 'زيت عافية ذرة نقي 1.5 لتر', 'cat': 'cat-food', 'unit': 'unit-ltr', 'price': 2900.0, 'stock': 60.0, 'barcode': '629110010027'},
      {'code': 'PRD-028', 'name': 'زيت عافية ذرة نقي 9 لتر', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 16500.0, 'stock': 15.0, 'barcode': '629110010028'},
      {'code': 'PRD-029', 'name': 'زيت صني نباتي للقلي 1.8 لتر', 'cat': 'cat-food', 'unit': 'unit-ltr', 'price': 2400.0, 'stock': 70.0, 'barcode': '629110010029'},
      {'code': 'PRD-030', 'name': 'سمن نباتي مازولا أصلي 1 كجم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 1800.0, 'stock': 45.0, 'barcode': '629110010030'},

      // 31-45: Canned Foods, Pasta & Pulses
      {'code': 'PRD-031', 'name': 'تونة هناء لحم أبيض قطع بالزيت 185 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 950.0, 'stock': 130.0, 'barcode': '629110010031'},
      {'code': 'PRD-032', 'name': 'تونة الغواص خفيف قطع 185 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 800.0, 'stock': 110.0, 'barcode': '629110010032'},
      {'code': 'PRD-033', 'name': 'فول حدائق كاليفورنيا مدمس 400 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 500.0, 'stock': 95.0, 'barcode': '629110010033'},
      {'code': 'PRD-034', 'name': 'فول مدمس لونا بالخلطة السرية 400 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 480.0, 'stock': 85.0, 'barcode': '629110010034'},
      {'code': 'PRD-035', 'name': 'فاصوليا حمراء لونا معلبة 400 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 450.0, 'stock': 90.0, 'barcode': '629110010035'},
      {'code': 'PRD-036', 'name': 'فاصوليا بيضاء حدائق كاليفورنيا 400 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 480.0, 'stock': 70.0, 'barcode': '629110010036'},
      {'code': 'PRD-037', 'name': 'حمص حب لونا مسلوق 400 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 450.0, 'stock': 80.0, 'barcode': '629110010037'},
      {'code': 'PRD-038', 'name': 'معجون طماطم السعودية 135 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 300.0, 'stock': 160.0, 'barcode': '629110010038'},
      {'code': 'PRD-039', 'name': 'معجون طماطم هاينز 135 جم', 'cat': 'cat-canned', 'unit': 'unit-pcs', 'price': 320.0, 'stock': 120.0, 'barcode': '629110010039'},
      {'code': 'PRD-040', 'name': 'مكرونة الوفرة خواتم 400 جم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 350.0, 'stock': 130.0, 'barcode': '629110010040'},
      {'code': 'PRD-041', 'name': 'مكرونة الوفرة اسباجيتي 400 جم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 350.0, 'stock': 140.0, 'barcode': '629110010041'},
      {'code': 'PRD-042', 'name': 'شعيرية الوفرة محمصة 400 جم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 320.0, 'stock': 90.0, 'barcode': '629110010042'},
      {'code': 'PRD-043', 'name': 'عدس أصفر تركي حب 1 كجم', 'cat': 'cat-food', 'unit': 'unit-kg', 'price': 1100.0, 'stock': 50.0, 'barcode': '629110010043'},
      {'code': 'PRD-044', 'name': 'عدس أحمر مجروش 1 كجم', 'cat': 'cat-food', 'unit': 'unit-kg', 'price': 1050.0, 'stock': 55.0, 'barcode': '629110010044'},
      {'code': 'PRD-045', 'name': 'شوفان كويكر أبيض رقائق 500 جم', 'cat': 'cat-food', 'unit': 'unit-pcs', 'price': 1150.0, 'stock': 65.0, 'barcode': '629110010045'},

      // 46-60: Dairy & Refrigerated
      {'code': 'PRD-046', 'name': 'حليب يماني مبخر ممتاز 170 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 450.0, 'stock': 140.0, 'barcode': '629110010046'},
      {'code': 'PRD-047', 'name': 'حليب أبو قوس مبخر كامل الدسم 170 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 500.0, 'stock': 120.0, 'barcode': '629110010047'},
      {'code': 'PRD-048', 'name': 'حليب نيدو مجفف علبة معدنية 900 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 5800.0, 'stock': 35.0, 'barcode': '629110010048'},
      {'code': 'PRD-049', 'name': 'حليب نيدو مجفف كيس اقتصادي 2250 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 13500.0, 'stock': 20.0, 'barcode': '629110010049'},
      {'code': 'PRD-050', 'name': 'حليب المراعي طويل الأجل 1 لتر', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 850.0, 'stock': 70.0, 'barcode': '629110010050'},
      {'code': 'PRD-051', 'name': 'جبنة المراعي شيدر علب 200 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 1100.0, 'stock': 60.0, 'barcode': '629110010051'},
      {'code': 'PRD-052', 'name': 'جبنة كيري مربعات أصلية 12 قطعة', 'cat': 'cat-dairy', 'unit': 'unit-box', 'price': 1600.0, 'stock': 45.0, 'barcode': '629110010052'},
      {'code': 'PRD-053', 'name': 'جبنة كيري مربعات 24 قطعة', 'cat': 'cat-dairy', 'unit': 'unit-box', 'price': 3100.0, 'stock': 30.0, 'barcode': '629110010053'},
      {'code': 'PRD-054', 'name': 'جبنة لافاش كيري مثلثات 8 قطع', 'cat': 'cat-dairy', 'unit': 'unit-box', 'price': 650.0, 'stock': 85.0, 'barcode': '629110010054'},
      {'code': 'PRD-055', 'name': 'جبنة المراعي فيتا بيضاء 500 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 1350.0, 'stock': 40.0, 'barcode': '629110010055'},
      {'code': 'PRD-056', 'name': 'زبادي نادك طازج 170 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 250.0, 'stock': 80.0, 'barcode': '629110010056'},
      {'code': 'PRD-057', 'name': 'زبادي المراعي كامل الدسم 500 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 650.0, 'stock': 40.0, 'barcode': '629110010057'},
      {'code': 'PRD-058', 'name': 'قشطة التاج الذهبي 155 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 600.0, 'stock': 95.0, 'barcode': '629110010058'},
      {'code': 'PRD-059', 'name': 'زبدة لورباك غير مملحة 100 جم', 'cat': 'cat-dairy', 'unit': 'unit-pcs', 'price': 900.0, 'stock': 50.0, 'barcode': '629110010059'},
      {'code': 'PRD-060', 'name': 'طبق بيض مائدة بلدي طازج 30 حبة', 'cat': 'cat-dairy', 'unit': 'unit-box', 'price': 2800.0, 'stock': 45.0, 'barcode': '629110010060'},

      // 61-75: Biscuits, Sweets & Snacks
      {'code': 'PRD-061', 'name': 'بسكويت أبو ولد الأصلي كرتون 24 باكيت', 'cat': 'cat-sweets', 'unit': 'unit-box', 'price': 2200.0, 'stock': 60.0, 'barcode': '629110010061'},
      {'code': 'PRD-062', 'name': 'بسكويت ماري بريك شاي 12 باكيت', 'cat': 'cat-sweets', 'unit': 'unit-pack', 'price': 1200.0, 'stock': 50.0, 'barcode': '629110010062'},
      {'code': 'PRD-063', 'name': 'بسكويت كريك كراك مالح بالجبن', 'cat': 'cat-sweets', 'unit': 'unit-pack', 'price': 1100.0, 'stock': 45.0, 'barcode': '629110010063'},
      {'code': 'PRD-064', 'name': 'ويفر لوكر شوكولاتة بندق 175 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 1150.0, 'stock': 55.0, 'barcode': '629110010064'},
      {'code': 'PRD-065', 'name': 'بسكويت أوريو شوكولاتة أصلي 16 قطعة', 'cat': 'cat-sweets', 'unit': 'unit-pack', 'price': 950.0, 'stock': 70.0, 'barcode': '629110010065'},
      {'code': 'PRD-066', 'name': 'شوكولاتة جلاكسي كنز بالحليب 90 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 750.0, 'stock': 80.0, 'barcode': '629110010066'},
      {'code': 'PRD-067', 'name': 'شوكولاتة سنيكرز بالحليب والفول 50 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 500.0, 'stock': 90.0, 'barcode': '629110010067'},
      {'code': 'PRD-068', 'name': 'شوكولاتة كت كات 4 أصابع 41 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 450.0, 'stock': 100.0, 'barcode': '629110010068'},
      {'code': 'PRD-069', 'name': 'نوتيلا شوكولاتة بندق قابلة للدهن 400 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 2800.0, 'stock': 35.0, 'barcode': '629110010069'},
      {'code': 'PRD-070', 'name': 'شيبس ليز عائلي ملح وخل 160 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 650.0, 'stock': 80.0, 'barcode': '629110010070'},
      {'code': 'PRD-071', 'name': 'شيبس ليز فلفل حار وليمون 160 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 650.0, 'stock': 75.0, 'barcode': '629110010071'},
      {'code': 'PRD-072', 'name': 'شيبس دوريتوس جبنة ناتشو 175 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 700.0, 'stock': 60.0, 'barcode': '629110010072'},
      {'code': 'PRD-073', 'name': 'مكسرات مشكلة الرفاعي إكسترا 300 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 2400.0, 'stock': 30.0, 'barcode': '629110010073'},
      {'code': 'PRD-074', 'name': 'فول سوداني بست مملح محمص 150 جم', 'cat': 'cat-sweets', 'unit': 'unit-pcs', 'price': 600.0, 'stock': 65.0, 'barcode': '629110010074'},
      {'code': 'PRD-075', 'name': 'حلوى مصاص تشوبا تشوبس كيس 50 حبة', 'cat': 'cat-sweets', 'unit': 'unit-box', 'price': 1800.0, 'stock': 40.0, 'barcode': '629110010075'},

      // 76-88: Cleaning & Home Supplies
      {'code': 'PRD-076', 'name': 'مسحوق غسيل تايد أصلي أوتوماتيك 2.5 كجم', 'cat': 'cat-clean', 'unit': 'unit-pcs', 'price': 4200.0, 'stock': 45.0, 'barcode': '629110010076'},
      {'code': 'PRD-077', 'name': 'مسحوق غسيل تايد عادي يدوي 1 كجم', 'cat': 'cat-clean', 'unit': 'unit-pcs', 'price': 1600.0, 'stock': 70.0, 'barcode': '629110010077'},
      {'code': 'PRD-078', 'name': 'مسحوق غسيل أريال بالداوني 2.5 كجم', 'cat': 'cat-clean', 'unit': 'unit-pcs', 'price': 4600.0, 'stock': 35.0, 'barcode': '629110010078'},
      {'code': 'PRD-079', 'name': 'سائل غسيل صحون فيري ليمون 1 لتر', 'cat': 'cat-clean', 'unit': 'unit-ltr', 'price': 1500.0, 'stock': 75.0, 'barcode': '629110010079'},
      {'code': 'PRD-080', 'name': 'سائل جلي بريل تفاح أخضر 1 لتر', 'cat': 'cat-clean', 'unit': 'unit-ltr', 'price': 1400.0, 'stock': 60.0, 'barcode': '629110010080'},
      {'code': 'PRD-081', 'name': 'مبيض ملابس كلوركس أصلي 950 مل', 'cat': 'cat-clean', 'unit': 'unit-pcs', 'price': 750.0, 'stock': 85.0, 'barcode': '629110010081'},
      {'code': 'PRD-082', 'name': 'مطهر ومنظف أرضيات ديتول 1 لتر', 'cat': 'cat-clean', 'unit': 'unit-ltr', 'price': 2200.0, 'stock': 40.0, 'barcode': '629110010082'},
      {'code': 'PRD-083', 'name': 'ملين ملابس داوني نسيم الوادي 1 لتر', 'cat': 'cat-clean', 'unit': 'unit-ltr', 'price': 1800.0, 'stock': 50.0, 'barcode': '629110010083'},
      {'code': 'PRD-084', 'name': 'مناديل فاين كلاسيك 500 منديل مزدوج', 'cat': 'cat-clean', 'unit': 'unit-box', 'price': 650.0, 'stock': 120.0, 'barcode': '629110010084'},
      {'code': 'PRD-085', 'name': 'مناديل مطبخ رول ماكسي فاين 2 رول', 'cat': 'cat-clean', 'unit': 'unit-pack', 'price': 850.0, 'stock': 70.0, 'barcode': '629110010085'},
      {'code': 'PRD-086', 'name': 'أكياس نفايات معطرة شراع 50 جالون', 'cat': 'cat-clean', 'unit': 'unit-pack', 'price': 950.0, 'stock': 65.0, 'barcode': '629110010086'},
      {'code': 'PRD-087', 'name': 'إسفنج جلي صحون فيلدا 3 قطع', 'cat': 'cat-clean', 'unit': 'unit-pack', 'price': 450.0, 'stock': 90.0, 'barcode': '629110010087'},
      {'code': 'PRD-088', 'name': 'معطر جو جليد فريش لافندر 300 مل', 'cat': 'cat-clean', 'unit': 'unit-pcs', 'price': 1100.0, 'stock': 45.0, 'barcode': '629110010088'},

      // 89-100: Personal Care & Spices
      {'code': 'PRD-089', 'name': 'صابون لوكس لمسة ناعمة معطر 120 جم', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 400.0, 'stock': 130.0, 'barcode': '629110010089'},
      {'code': 'PRD-090', 'name': 'صابون ديتول الأصلي حماية 120 جم', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 550.0, 'stock': 100.0, 'barcode': '629110010090'},
      {'code': 'PRD-091', 'name': 'شامبو بانتين علاج ملكي للشعر 400 مل', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 2200.0, 'stock': 45.0, 'barcode': '629110010091'},
      {'code': 'PRD-092', 'name': 'شامبو هيد آند شولدرز ضد القشرة 400 مل', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 2400.0, 'stock': 50.0, 'barcode': '629110010092'},
      {'code': 'PRD-093', 'name': 'معجون أسنان كولجيت حماية من التسوس 100 مل', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 800.0, 'stock': 85.0, 'barcode': '629110010093'},
      {'code': 'PRD-094', 'name': 'معجون أسنان سنسوداين لراحة الحساسية 75 مل', 'cat': 'cat-personal', 'unit': 'unit-pcs', 'price': 1800.0, 'stock': 40.0, 'barcode': '629110010094'},
      {'code': 'PRD-095', 'name': 'بهارات مشكلة يمنية فاخرة مطحونة 200 جم', 'cat': 'cat-spices', 'unit': 'unit-pcs', 'price': 900.0, 'stock': 60.0, 'barcode': '629110010095'},
      {'code': 'PRD-096', 'name': 'كمون مطحون نقي 150 جم', 'cat': 'cat-spices', 'unit': 'unit-pcs', 'price': 700.0, 'stock': 50.0, 'barcode': '629110010096'},
      {'code': 'PRD-097', 'name': 'فلفل أسود حب فاخر 150 جم', 'cat': 'cat-spices', 'unit': 'unit-pcs', 'price': 850.0, 'stock': 45.0, 'barcode': '629110010097'},
      {'code': 'PRD-098', 'name': 'هيل هندي أخضر حبة رقم 1 (100 جم)', 'cat': 'cat-spices', 'unit': 'unit-pcs', 'price': 2500.0, 'stock': 30.0, 'barcode': '629110010098'},
      {'code': 'PRD-099', 'name': 'ملح ساسا ناعم مضاف باليود 700 جم', 'cat': 'cat-spices', 'unit': 'unit-pcs', 'price': 250.0, 'stock': 120.0, 'barcode': '629110010099'},
      {'code': 'PRD-100', 'name': 'مرقة دجاج ماجي مكعبات عبوة 24 مكعب', 'cat': 'cat-spices', 'unit': 'unit-box', 'price': 1250.0, 'stock': 90.0, 'barcode': '629110010100'},
    ];
  }

  List<Map<String, dynamic>> _get50Customers() {
    return [
      {'name': 'محمد عبد الله العولقي', 'phone': '771234501', 'address': 'صنعاء - حي حدة', 'credit': 50000.0},
      {'name': 'خالد أحمد الأهدل', 'phone': '772345602', 'address': 'عدن - المعلا الرئيسي', 'credit': 80000.0},
      {'name': 'طارق فؤاد الشامي', 'phone': '733456703', 'address': 'تعز - جولة الحوبان', 'credit': 40000.0},
      {'name': 'عبد الرحمن يحيى القاضي', 'phone': '774567804', 'address': 'صنعاء - شارع الزبيري', 'credit': 60000.0},
      {'name': 'يوسف عبد العزيز العماري', 'phone': '715678905', 'address': 'إب - الدائري الغربي', 'credit': 35000.0},
      {'name': 'عمر سالم باوزير', 'phone': '776789006', 'address': 'المكلا - حي الديس', 'credit': 90000.0},
      {'name': 'أحمد علي باحارثة', 'phone': '777890107', 'address': 'سيئون - السوق العام', 'credit': 45000.0},
      {'name': 'وليد ناصر الصبيحي', 'phone': '738901208', 'address': 'لحج - الحوطة وسط المدينة', 'credit': 30000.0},
      {'name': 'مصطفى حميد الذماري', 'phone': '779012309', 'address': 'ذمار - المدخل الشمالي', 'credit': 55000.0},
      {'name': 'بشير حسن الهمداني', 'phone': '710123410', 'address': 'صنعاء - الأصبحي', 'credit': 75000.0},
      {'name': 'هند محمد القدسي', 'phone': '771122311', 'address': 'صنعاء - بيت بوس', 'credit': 25000.0},
      {'name': 'فاطمة عبده الشرجبي', 'phone': '732233412', 'address': 'تعز - حي المسبح', 'credit': 20000.0},
      {'name': 'نبيل مجاهد الكبسي', 'phone': '773344513', 'address': 'صنعاء - الروضة', 'credit': 65000.0},
      {'name': 'هاني فضل الضلعي', 'phone': '774455614', 'address': 'صنعاء - الصافية', 'credit': 40000.0},
      {'name': 'عبد الكريم منصور العريقي', 'phone': '715566715', 'address': 'تعز - الحجرية التربة', 'credit': 50000.0},
      {'name': 'ماجد سلطان الحكيمي', 'phone': '771200116', 'address': 'تعز - بير باشا', 'credit': 35000.0},
      {'name': 'عمار ياسر الوادعي', 'phone': '772300217', 'address': 'صنعاء - شملان', 'credit': 60000.0},
      {'name': 'منير عبده الصلوي', 'phone': '733400318', 'address': 'عدن - الشيخ عثمان', 'credit': 45000.0},
      {'name': 'سامي عبد الخالق النجار', 'phone': '774500419', 'address': 'إب - مفرق جبلة', 'credit': 50000.0},
      {'name': 'زكريا إسماعيل المقبلي', 'phone': '715600520', 'address': 'صنعاء - مذبح القديمة', 'credit': 30000.0},
      {'name': 'رامي توفيق الصهيبي', 'phone': '776700621', 'address': 'صنعاء - دار سلم', 'credit': 70000.0},
      {'name': 'فهد عبد ربه المريسي', 'phone': '777800722', 'address': 'الضالع - دمت', 'credit': 40000.0},
      {'name': 'أنور قاسم المقطري', 'phone': '738900823', 'address': 'عدن - المنصورة حي ريمي', 'credit': 55000.0},
      {'name': 'عادل مطهر اليريمي', 'phone': '779000924', 'address': 'إب - يريم الشارع العام', 'credit': 65000.0},
      {'name': 'إبراهيم عبد السلام المفلحي', 'phone': '710100025', 'address': 'لحج - يافع لبعوس', 'credit': 85000.0},
      {'name': 'رضوان صالح الجبري', 'phone': '771133126', 'address': 'صنعاء - سعوان', 'credit': 40000.0},
      {'name': 'كمال حسن السعدي', 'phone': '772244227', 'address': 'المكلا - فوة القديمة', 'credit': 50000.0},
      {'name': 'فؤاد عبد الجبار الدبعي', 'phone': '733355328', 'address': 'تعز - التحرير الأسفل', 'credit': 35000.0},
      {'name': 'جمال محسن العبسي', 'phone': '774466429', 'address': 'صنعاء - هائل سعيد', 'credit': 60000.0},
      {'name': 'توفيق علوي الزريقي', 'phone': '715577530', 'address': 'تعز - الشمايتين', 'credit': 45000.0},
      {'name': 'ناصر محمد حيدرة', 'phone': '776688631', 'address': 'أبين - زنجبار', 'credit': 30000.0},
      {'name': 'معاذ عبد الغني الشوافي', 'phone': '777799732', 'address': 'تعز - عصيفرة', 'credit': 55000.0},
      {'name': 'عصام عبد الوهاب شمسان', 'phone': '738811833', 'address': 'صنعاء - الدائري أمام الجامعة', 'credit': 70000.0},
      {'name': 'لؤي عبد الملك البعداني', 'phone': '779922934', 'address': 'إب - بعدان الشارع العام', 'credit': 40000.0},
      {'name': 'وسيم رشاد الزبيري', 'phone': '710033035', 'address': 'صنعاء - شارع بغداد', 'credit': 50000.0},
      {'name': 'إياد عبد الجليل الصبري', 'phone': '771444136', 'address': 'تعز - صالة', 'credit': 35000.0},
      {'name': 'أشرف نجيب الحسامي', 'phone': '772555237', 'address': 'صنعاء - الحصبة', 'credit': 65000.0},
      {'name': 'حمزة فاروق الشيباني', 'phone': '733666338', 'address': 'تعز - ديلوكس', 'credit': 45000.0},
      {'name': 'بسام سعيد الماوري', 'phone': '774777439', 'address': 'صنعاء - نقم', 'credit': 55000.0},
      {'name': 'غسان عبده الحمادي', 'phone': '715888540', 'address': 'عدن - كريتر السوق الطويل', 'credit': 40000.0},
      {'name': 'مروان عبد الكريم الشميري', 'phone': '776999641', 'address': 'تعز - الروضة', 'credit': 50000.0},
      {'name': 'زياد محفوظ الكاف', 'phone': '777111742', 'address': 'تريم - الغرفة', 'credit': 80000.0},
      {'name': 'رائد عبد القادر بارجاء', 'phone': '738222843', 'address': 'المكلا - باجعمان', 'credit': 45000.0},
      {'name': 'هاشم أحمد بن بريك', 'phone': '779333944', 'address': 'الشحر - الخور', 'credit': 60000.0},
      {'name': 'صلاح سالم بن محفوظ', 'phone': '710444045', 'address': 'سيئون - القرن', 'credit': 90000.0},
      {'name': 'ياسين علي العيدروس', 'phone': '771555146', 'address': 'عدن - خور مكسر', 'credit': 55000.0},
      {'name': 'جلال صالح العمودي', 'phone': '772666247', 'address': 'المكلا - حي السلام', 'credit': 75000.0},
      {'name': 'وضاح فضل الحريري', 'phone': '733777348', 'address': 'الضالع - الحصين', 'credit': 35000.0},
      {'name': 'رمزي شاهر العواضي', 'phone': '774888449', 'address': 'صنعاء - السبعين', 'credit': 65000.0},
      {'name': 'هيثم عبد الله السياني', 'phone': '715999550', 'address': 'إب - السياني وادي بنا', 'credit': 40000.0},
    ];
  }

  List<Map<String, dynamic>> _get50Suppliers() {
    return [
      {'name': 'شركة الأوائل للاستيراد والتوزيع المحدودة', 'contact': 'فؤاد الكبسي', 'phone': '770111222', 'address': 'صنعاء - شارع الستين الغربي'},
      {'name': 'مجموعة هائل سعيد أنعم - قطاع السلع الاستهلاكية', 'contact': 'أحمد عبد الجليل', 'phone': '771222333', 'address': 'تعز - منطقة الحوبان الصناعية'},
      {'name': 'شركة يمن سوفت للتموين والسلع الأساسية', 'contact': 'مروان السقاف', 'phone': '772333444', 'address': 'صنعاء - شارع بغداد الرئيسي'},
      {'name': 'مؤسسة البركة للتجارة العامة والتوزيع', 'contact': 'عبده ناصر الشرعبي', 'phone': '773444555', 'address': 'عدن - مديرية المنصورة'},
      {'name': 'شركة النجم الذهبي لتجارة المواد الغذائية', 'contact': 'سامي الجابري', 'phone': '774555666', 'address': 'المكلا - منطقة روكب الصناعية'},
      {'name': 'وكالة الوفاق السريع للمنظفات والورقيات', 'contact': 'ماجد الوادعي', 'phone': '775666777', 'address': 'صنعاء - تقاطع دار سلم'},
      {'name': 'شركة سبأ الوطنية لتعبئة المياه والمشروبات', 'contact': 'عادل باعباد', 'phone': '776777888', 'address': 'سيئون - المنطقة الصناعية'},
      {'name': 'مؤسسة التيسير لتوريد الألبان والمواد الطازجة', 'contact': 'رشاد المخلافي', 'phone': '777888999', 'address': 'إب - شارع العدين'},
      {'name': 'شركة النهضة لاستيراد الأرز والحبوب الفاخرة', 'contact': 'سليم الشيباني', 'phone': '778999000', 'address': 'الحديدة - ميناء الصليف'},
      {'name': 'مؤسسة الفلاح للزيوت والدهون النباتية', 'contact': 'طارق العمري', 'phone': '779000111', 'address': 'صنعاء - شارع تعز'},
      {'name': 'شركة الشرق الأوسط للمعلبات واللحوم المجمدة', 'contact': 'عمار الصبري', 'phone': '770111333', 'address': 'عدن - المنطقة الحرة كالتكس'},
      {'name': 'وكالة السلام للمشروبات الغازية والعصائر الطبيعية', 'contact': 'معاذ القاضي', 'phone': '771222444', 'address': 'تعز - المطار القديم'},
      {'name': 'شركة الجزيرة للمنتجات الورقية والتغليف السريع', 'contact': 'عبد الحليم باوزير', 'phone': '772333555', 'address': 'المكلا - الديس خلف البريد'},
      {'name': 'مؤسسة الاتحاد لتوريد البن والتوابل والبهارات', 'contact': 'يحيى الخولاني', 'phone': '773444666', 'address': 'صنعاء - باب اليمن سوق الملح'},
      {'name': 'شركة الفجر للحلويات والمكسرات الفاخرة', 'contact': 'هشام اليافعي', 'phone': '774555777', 'address': 'عدن - المعلا الشارع الدائري'},
      {'name': 'مصانع الأمل للمكرونة والنشويات الوطنية', 'contact': 'كمال الحسامي', 'phone': '775666888', 'address': 'تعز - الحوبان خط صنعاء'},
      {'name': 'شركة الرواد للبلاستيك والأكياس الاستهلاكية', 'contact': 'صالح الذماري', 'phone': '776777999', 'address': 'ذمار - حي التعاون'},
      {'name': 'مؤسسة الصفا لتجارة الأجبان ومشتقات الحليب', 'contact': 'توفيق الصنعاني', 'phone': '777888000', 'address': 'صنعاء - شارع الزبيري'},
      {'name': 'شركة القمة لتوزيع المنظفات الصناعية والشامبوهات', 'contact': 'نبيل باحارثة', 'phone': '778999111', 'address': 'سيئون - مفرق بن عيفان'},
      {'name': 'وكالة الخير لتوريد الدقيق والسكر البرازيلي', 'contact': 'بشير الهمداني', 'phone': '779000222', 'address': 'صنعاء - الحصبة شارع مازدا'},
      {'name': 'شركة البحر الأحمر للأسماك والتونة المعلبة', 'contact': 'أنور المخلافي', 'phone': '770111444', 'address': 'الحديدة - الحوك'},
      {'name': 'مؤسسة الأمانة لتجارة الشاي ومستلزمات الضيافة', 'contact': 'عبد الرقيب الكبسي', 'phone': '771222555', 'address': 'صنعاء - شارع مأرب'},
      {'name': 'شركة الخليج لتوزيع الزيوت النباتية الصافية', 'contact': 'جمال العولقي', 'phone': '772333666', 'address': 'شبوة - عتق الشارع العام'},
      {'name': 'وكالة النور لمستحضرات العناية الشخصية والأطفال', 'contact': 'حمزة المقبلي', 'phone': '773444777', 'address': 'إب - شارع الدائري'},
      {'name': 'شركة المجد لتعبئة وتوزيع التمور والحلويات', 'contact': 'رياض العمودي', 'phone': '774555888', 'address': 'حضرموت - القطن السوق القديم'},
      {'name': 'مؤسسة طيبة للمواد التموينية والمخازن المبردة', 'contact': 'فارس الشوافي', 'phone': '775666999', 'address': 'تعز - بير باشا حارة الأمل'},
      {'name': 'شركة الأهرام للبسكويت والصناعات الخفيفة', 'contact': 'منصور العريقي', 'phone': '776777000', 'address': 'صنعاء - حي النهضة'},
      {'name': 'وكالة الفرسان للتوزيع والتسويق السريع للمحلات', 'contact': 'عصام الصهيبي', 'phone': '777888111', 'address': 'صنعاء - مذبح شارع الثلاثين'},
      {'name': 'شركة الريان للمياه النقية والعصائر العائلية', 'contact': 'عمر الجابري', 'phone': '778999222', 'address': 'المكلا - فوة حي الإنشاءات'},
      {'name': 'مؤسسة المروة للبهارات والأعشاب الطبية والعطرية', 'contact': 'عبد الحكيم القدسي', 'phone': '779000333', 'address': 'صنعاء - التحرير'},
      {'name': 'شركة المستقبل لتجارة اللحوم والدواجن المجمدة', 'contact': 'وليد الصبيحي', 'phone': '770111555', 'address': 'لحج - صبر الشارع العام'},
      {'name': 'وكالة السعيد للصابون والمنظفات المنزلية الشاملة', 'contact': 'أيمن الشرجبي', 'phone': '771222666', 'address': 'تعز - شارع 26 سبتمبر'},
      {'name': 'شركة التضامن للمعلبات والأغذية المحفوظة', 'contact': 'وجدي الصلوي', 'phone': '772333777', 'address': 'عدن - خور مكسر حي السعادة'},
      {'name': 'مؤسسة الباشا للحلويات والشوكولاتة المستوردة', 'contact': 'بليغ الوادعي', 'phone': '773444888', 'address': 'صنعاء - حي عصر'},
      {'name': 'شركة دار الغذاء للاستيراد الشامل وسلاسل التموين', 'contact': 'مازن النجار', 'phone': '774555999', 'address': 'إب - شارع المحافظة'},
      {'name': 'وكالة الوسام لتوزيع مستلزمات المخابز والحلويات', 'contact': 'شريف المقطري', 'phone': '775666000', 'address': 'عدن - دار سعد'},
      {'name': 'شركة الفردوس للألبان الطبيعية والأجبان الطازجة', 'contact': 'لبيب اليريمي', 'phone': '776777111', 'address': 'ذمار - خط الحداء'},
      {'name': 'مؤسسة الصادق لتجارة الحبوب والبقوليات والأعلاف', 'contact': 'سلطان المفلحي', 'phone': '777888222', 'address': 'أبين - جعار الشارع الرئيسي'},
      {'name': 'شركة التاج الذهبي للمعلبات والصلصات الفاخرة', 'contact': 'نائف الجبري', 'phone': '778999333', 'address': 'صنعاء - شارع الرقاص'},
      {'name': 'وكالة النخبة لتجارة المنظفات ومواد التعقيم الطبي', 'contact': 'أسامة السعدي', 'phone': '779000444', 'address': 'المكلا - جول مسحة الصناعية'},
      {'name': 'شركة الشروق للمنتجات الغذائية المبتكرة', 'contact': 'غسان الدبعي', 'phone': '770111666', 'address': 'تعز - وادي القاضي'},
      {'name': 'مؤسسة الهدى للأغذية المجففة والمكسرات والكاجو', 'contact': 'وائل العبسي', 'phone': '771222777', 'address': 'صنعاء - شارع صخر'},
      {'name': 'شركة الهلال للمنظفات ومواد التطهير الفندقي', 'contact': 'حاتم الزريقي', 'phone': '772333888', 'address': 'عدن - كريتر شارع أروى'},
      {'name': 'وكالة الأمل لتوزيع العصائر المركزة والمركزات', 'contact': 'مروان باعباد', 'phone': '773444999', 'address': 'سيئون - السحيل'},
      {'name': 'شركة الكريحي للتجارة والتوكيلات الاستهلاكية', 'contact': 'خالد الكريحي', 'phone': '774555000', 'address': 'صنعاء - شارع القيادة'},
      {'name': 'مؤسسة بازرعة للتموين وسلاسل الإمداد الغذائي', 'contact': 'سعيد بازرعة', 'phone': '775666111', 'address': 'عدن - المنصورة المنطقة الصناعية'},
      {'name': 'شركة الغراسي للاستيراد والتسويق التجاري', 'contact': 'محمد الغراسي', 'phone': '776777222', 'address': 'صنعاء - شارع القصر'},
      {'name': 'وكالة الشيباني للتجارة العامة والصناعة', 'contact': 'فيصل الشيباني', 'phone': '777888333', 'address': 'تعز - عقبة منيف'},
      {'name': 'شركة بن شملان للمواد الاستهلاكية والتوزيع', 'contact': 'عبد الله بن شملان', 'phone': '778999444', 'address': 'حضرموت - دوعن صبيخ'},
      {'name': 'مؤسسة الدبعي للحلويات والمثلجات السريعة', 'contact': 'مختار الدبعي', 'phone': '779000555', 'address': 'إب - المثلث الشارع العام'},
    ];
  }
}
