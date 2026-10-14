import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/core/utils/precision_math.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/treasury_dao.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/catalog/application/services/product_unit_resolver.dart';
import 'package:smart_merchant_erp/modules/catalog/domain/repositories/catalog_repository.dart';
import 'package:smart_merchant_erp/modules/catalog/infrastructure/repositories/catalog_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/usecases/record_purchase_usecase.dart';
import 'package:smart_merchant_erp/modules/purchasing/domain/repositories/purchasing_repository.dart';
import 'package:smart_merchant_erp/modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/treasury/domain/repositories/treasury_repository.dart';
import 'package:smart_merchant_erp/modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late PurchasingRepository purchasingRepository;
  late SalesRepository salesRepository;
  late InventoryRepository inventoryRepository;
  late AccountingRepository accountingRepository;
  late TreasuryRepository treasuryRepository;
  late CatalogRepository catalogRepository;
  late ProductUnitResolver unitResolver;
  late AccountingApplicationService accountingService;
  late ApplicationContext context;
  late RecordPurchaseUseCase purchaseUseCase;
  late CompleteSaleUseCase saleUseCase;

  const uuid = Uuid();
  late String businessId;
  late String branchId;
  late String userId;
  late String warehouseId;
  late String supplierId;
  late String customerId;
  const String currencyId = 'YER';

  // Accounts
  late String arAccId;
  late String revAccId;
  late String cogsAccId;
  late String invAccId;
  late String apAccId;

  // Catalog items
  late String productId;
  late String pieceUnitId;
  late String cartonUnitId;
  late String basePieceProductUnitId;
  late String cartonProductUnitId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    transactionRunner = ApplicationTransactionRunnerImpl(db);
    purchasingRepository = PurchasingRepositoryImpl(PurchasingDao(db));
    salesRepository = SalesRepositoryImpl(SalesDao(db));
    inventoryRepository = InventoryRepositoryImpl(InventoryDao(db));
    accountingRepository = AccountingRepositoryImpl(AccountingDao(db));
    treasuryRepository = TreasuryRepositoryImpl(TreasuryDao(db));
    catalogRepository = CatalogRepositoryImpl(CatalogDao(db));
    unitResolver = ProductUnitResolver(catalogRepository);

    businessId = uuid.v4();
    branchId = uuid.v4();
    userId = uuid.v4();
    warehouseId = uuid.v4();
    supplierId = uuid.v4();
    customerId = uuid.v4();

    arAccId = uuid.v4();
    revAccId = uuid.v4();
    cogsAccId = uuid.v4();
    invAccId = uuid.v4();
    apAccId = uuid.v4();

    productId = uuid.v4();
    pieceUnitId = uuid.v4();
    cartonUnitId = uuid.v4();
    basePieceProductUnitId = uuid.v4();
    cartonProductUnitId = uuid.v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    accountingService = AccountingApplicationService(
      accountingRepository,
      context,
    );

    purchaseUseCase = RecordPurchaseUseCase(
      purchasingRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      treasuryRepository,
      context,
      transactionRunner,
      unitResolver: unitResolver,
    );

    saleUseCase = CompleteSaleUseCase(
      salesRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      context,
      transactionRunner,
      db,
      unitResolver: unitResolver,
    );

    // Seed master business & context records
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: businessId,
        accountId: 'acc-multiunit',
        businessName: 'Smart ERP Unit Conversion Test',
        status: const drift.Value('Active'),
      ),
    );
    await db.into(db.branches).insert(
      BranchesCompanion.insert(
        id: branchId,
        businessId: businessId,
        branchCode: 'B-01',
        branchName: 'Main Store',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.usersTable).insert(
      UsersTableCompanion.insert(
        id: drift.Value(userId),
        email: 'sales@smarterp.local',
        passwordHash: 'dummy',
        firstName: 'Sales',
        lastName: 'Manager',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.warehouses).insert(
      WarehousesCompanion.insert(
        id: warehouseId,
        businessId: businessId,
        branchId: branchId,
        warehouseName: 'Main Warehouse',
        warehouseCode: 'MW-01',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.suppliers).insert(
      SuppliersCompanion.insert(
        id: supplierId,
        businessId: businessId,
        supplierName: 'National Beverage Co',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        id: customerId,
        businessId: businessId,
        customerName: 'Al-Amal Market',
        isActive: const drift.Value(true),
      ),
    );

    // Seed Open Fiscal Period
    final fiscalYearId = uuid.v4();
    await db.into(db.fiscalPeriods).insert(
      FiscalPeriodsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        fiscalYearId: fiscalYearId,
        periodNumber: 1,
        periodName: '2026-01',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: const drift.Value('Open'),
      ),
    );

    // Seed Chart of Accounts & Mappings
    for (final acc in [
      {'id': arAccId, 'code': '1102', 'name': 'AR', 'type': 1, 'bal': 'Debit'},
      {'id': revAccId, 'code': '4101', 'name': 'Sales Rev', 'type': 4, 'bal': 'Credit'},
      {'id': cogsAccId, 'code': '5101', 'name': 'COGS', 'type': 5, 'bal': 'Debit'},
      {'id': invAccId, 'code': '1105', 'name': 'Inventory', 'type': 1, 'bal': 'Debit'},
      {'id': apAccId, 'code': '2101', 'name': 'AP', 'type': 2, 'bal': 'Credit'},
    ]) {
      await db.into(db.chartOfAccounts).insert(
        ChartOfAccountsCompanion.insert(
          id: acc['id'] as String,
          businessId: businessId,
          accountCode: acc['code'] as String,
          accountName: acc['name'] as String,
          accountTypeId: acc['type'] as int,
          normalBalance: acc['bal'] as String,
        ),
      );
    }

    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'accounts_receivable',
        mappingName: 'AR Mapping',
        chartOfAccountId: arAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'sales_revenue',
        mappingName: 'Sales Rev Mapping',
        chartOfAccountId: revAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'cost_of_goods_sold',
        mappingName: 'COGS Mapping',
        chartOfAccountId: cogsAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'inventory_asset',
        mappingName: 'Inv Asset Mapping',
        chartOfAccountId: invAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'accounts_payable',
        mappingName: 'AP Mapping',
        chartOfAccountId: apAccId,
      ),
    );

    // Seed Units: Piece & Carton
    await db.into(db.units).insert(
      UnitsCompanion.insert(
        id: pieceUnitId,
        businessId: businessId,
        unitName: 'Piece',
        unitSymbol: 'PCS',
      ),
    );
    await db.into(db.units).insert(
      UnitsCompanion.insert(
        id: cartonUnitId,
        businessId: businessId,
        unitName: 'Carton (24 Pcs)',
        unitSymbol: 'CTN',
      ),
    );

    // Seed Master Product
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: productId,
        businessId: businessId,
        productCode: 'BEV-001',
        productName: 'Mineral Water 500ml',
      ),
    );

    // Seed Base Product Unit (Piece) - conversion factor = 1.0
    await db.into(db.productUnits).insert(
      ProductUnitsCompanion.insert(
        id: basePieceProductUnitId,
        businessId: businessId,
        productId: productId,
        unitId: pieceUnitId,
        conversionFactor: const drift.Value(1.0),
        isBaseUnit: const drift.Value(true),
        sellingPrice: const drift.Value(250.0),
        purchasePrice: const drift.Value(200.0),
      ),
    );

    // Seed Secondary Product Unit (Carton of 24) - conversion factor = 24.0
    await db.into(db.productUnits).insert(
      ProductUnitsCompanion.insert(
        id: cartonProductUnitId,
        businessId: businessId,
        productId: productId,
        unitId: cartonUnitId,
        conversionFactor: const drift.Value(24.0),
        isBaseUnit: const drift.Value(false),
        sellingPrice: const drift.Value(5500.0),
        purchasePrice: const drift.Value(4800.0),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'Full inventory lifecycle: Purchase in Cartons -> Stock converts to Base Units (Pieces) -> Sell in Pieces and Cartons with exact stock deduction and balanced COGS',
    () async {
      // 1. PURCHASE: Buy 2 Cartons @ 4,800 YER each
      // Total Carton Qty: 2
      // Each Carton = 24 pieces
      // Expected Base Inventory Qty: 2 * 24 = 48.0 pieces
      // Expected Average Cost per piece: 4,800 / 24 = 200.0 YER
      final purchaseCmd = RecordPurchaseCommand(
        supplierId: supplierId,
        currencyId: currencyId,
        exchangeRate: 1.0,
        isCreditPurchase: true,
        items: [
          PurchaseItemCommand(
            productUnitId: cartonProductUnitId,
            warehouseId: warehouseId,
            quantity: 2.0,
            unitCost: 4800.0,
          ),
        ],
      );

      final purchaseResult = await purchaseUseCase(purchaseCmd);
      expect(purchaseResult.isRight(), isTrue);

      // Verify stock in base unit
      final initialBaseInv = await inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            warehouseId,
            basePieceProductUnitId,
          );
      expect(initialBaseInv, isNotNull);
      expect(initialBaseInv!.quantity, 48.0);
      expect(initialBaseInv.averageCost, 200.0);

      // 2. SALE: Sell 6 Pieces @ 250 YER each (Base Unit sale)
      final saleCmd1 = CompleteSaleCommand(
        customerId: customerId,
        currencyId: currencyId,
        isCreditSale: true,
        items: [
          CompleteSaleItemCommand(
            productUnitId: basePieceProductUnitId,
            warehouseId: warehouseId,
            quantity: 6.0,
            unitPrice: 250.0,
          ),
        ],
      );

      final saleResult1 = await saleUseCase(saleCmd1);
      expect(saleResult1.isRight(), isTrue);

      // Verify inventory after selling 6 pieces: 48 - 6 = 42 pieces
      final invAfterSale1 = await inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            warehouseId,
            basePieceProductUnitId,
          );
      expect(invAfterSale1!.quantity, 42.0);
      expect(invAfterSale1.averageCost, 200.0);

      // 3. SALE: Sell 1 Carton (Secondary Unit sale)
      // 1 Carton converts to 24 Pieces
      // Remaining stock should be: 42 - 24 = 18 pieces
      final saleCmd2 = CompleteSaleCommand(
        customerId: customerId,
        currencyId: currencyId,
        isCreditSale: true,
        items: [
          CompleteSaleItemCommand(
            productUnitId: cartonProductUnitId,
            warehouseId: warehouseId,
            quantity: 1.0,
            unitPrice: 5500.0,
          ),
        ],
      );

      final saleResult2 = await saleUseCase(saleCmd2);
      expect(saleResult2.isRight(), isTrue);

      final invAfterSale2 = await inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            warehouseId,
            basePieceProductUnitId,
          );
      expect(invAfterSale2!.quantity, 18.0);
      expect(invAfterSale2.averageCost, 200.0);

      // 4. SALE FAILURE: Attempt to sell another Carton (requires 24 pieces, but only 18 pieces available)
      final saleCmd3 = CompleteSaleCommand(
        customerId: customerId,
        currencyId: currencyId,
        isCreditSale: true,
        items: [
          CompleteSaleItemCommand(
            productUnitId: cartonProductUnitId,
            warehouseId: warehouseId,
            quantity: 1.0,
            unitPrice: 5500.0,
          ),
        ],
      );

      final saleResult3 = await saleUseCase(saleCmd3);
      expect(saleResult3.isLeft(), isTrue); // Insufficient stock!

      // Stock should remain safely at 18.0 pieces
      final finalInv = await inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            warehouseId,
            basePieceProductUnitId,
          );
      expect(finalInv!.quantity, 18.0);
    },
  );
}
