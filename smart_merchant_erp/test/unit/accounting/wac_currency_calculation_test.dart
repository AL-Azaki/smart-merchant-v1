import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/core/utils/precision_math.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
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
import 'package:smart_merchant_erp/modules/treasury/domain/repositories/treasury_repository.dart';
import 'package:smart_merchant_erp/modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late PurchasingRepository purchasingRepository;
  late InventoryRepository inventoryRepository;
  late AccountingRepository accountingRepository;
  late TreasuryRepository treasuryRepository;
  late CatalogRepository catalogRepository;
  late ProductUnitResolver unitResolver;
  late AccountingApplicationService accountingService;
  late ApplicationContext context;
  late RecordPurchaseUseCase useCase;

  const uuid = Uuid();
  late String businessId;
  late String branchId;
  late String userId;
  late String warehouseId;
  late String supplierId;
  const String baseCurrencyId = 'YER';
  const String usdCurrencyId = 'USD';
  late String inventoryAssetAccountId;
  late String accountsPayableAccountId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    transactionRunner = ApplicationTransactionRunnerImpl(db);
    purchasingRepository = PurchasingRepositoryImpl(PurchasingDao(db));
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
    inventoryAssetAccountId = uuid.v4();
    accountsPayableAccountId = uuid.v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    accountingService = AccountingApplicationService(
      accountingRepository,
      context,
    );

    useCase = RecordPurchaseUseCase(
      purchasingRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      treasuryRepository,
      context,
      transactionRunner,
      unitResolver: unitResolver,
    );

    // 1. Seed Business & Branch & User
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: businessId,
        accountId: 'acc-wac-test',
        businessName: 'Smart ERP WAC Test',
        status: const drift.Value('Active'),
      ),
    );
    await db.into(db.branches).insert(
      BranchesCompanion.insert(
        id: branchId,
        businessId: businessId,
        branchCode: 'MAIN',
        branchName: 'Main Branch',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.usersTable).insert(
      UsersTableCompanion.insert(
        id: drift.Value(userId),
        email: 'tester@smarterp.local',
        passwordHash: 'dummy',
        firstName: 'Test',
        lastName: 'Accountant',
        isActive: const drift.Value(true),
      ),
    );

    // 2. Seed Warehouse & Supplier
    await db.into(db.warehouses).insert(
      WarehousesCompanion.insert(
        id: warehouseId,
        businessId: businessId,
        branchId: branchId,
        warehouseName: 'Central Depot',
        warehouseCode: 'CD-01',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.suppliers).insert(
      SuppliersCompanion.insert(
        id: supplierId,
        businessId: businessId,
        supplierName: 'Global Imports Co',
        isActive: const drift.Value(true),
      ),
    );

    // 3. Update USD Exchange Rate for testing
    await (db.update(db.currencies)..where((t) => t.id.equals('USD'))).write(
      const CurrenciesCompanion(exchangeRate: drift.Value(530.0)),
    );

    // 4. Seed Open Fiscal Period
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

    // 5. Seed Chart of Accounts & Mappings
    await db.into(db.chartOfAccounts).insert(
      ChartOfAccountsCompanion.insert(
        id: inventoryAssetAccountId,
        businessId: businessId,
        accountCode: '1105',
        accountName: 'Inventory Asset',
        accountTypeId: 1,
        normalBalance: 'Debit',
      ),
    );
    await db.into(db.chartOfAccounts).insert(
      ChartOfAccountsCompanion.insert(
        id: accountsPayableAccountId,
        businessId: businessId,
        accountCode: '2101',
        accountName: 'Accounts Payable',
        accountTypeId: 2,
        normalBalance: 'Credit',
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'inventory_asset',
        mappingName: 'Inventory Asset Account',
        chartOfAccountId: inventoryAssetAccountId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        mappingKey: 'accounts_payable',
        mappingName: 'Accounts Payable Account',
        chartOfAccountId: accountsPayableAccountId,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'WAC calculation in Base Currency preserves value when purchasing in local currency',
    () async {
      final productId = uuid.v4();
      final unitId = uuid.v4();
      final productUnitId = uuid.v4();

      await db.into(db.units).insert(
        UnitsCompanion.insert(
          id: unitId,
          businessId: businessId,
          unitName: 'Piece',
          unitSymbol: 'PCS',
        ),
      );
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: productId,
          businessId: businessId,
          productCode: 'PROD-001',
          productName: 'Tea El-Arousa',
        ),
      );
      await db.into(db.productUnits).insert(
        ProductUnitsCompanion.insert(
          id: productUnitId,
          businessId: businessId,
          productId: productId,
          unitId: unitId,
          conversionFactor: const drift.Value(1.0),
          isBaseUnit: const drift.Value(true),
          sellingPrice: const drift.Value(1500.0),
          purchasePrice: const drift.Value(1000.0),
        ),
      );

      // Initial Stock: 10 units @ 1000 YER
      await db.into(db.inventories).insert(
        InventoriesCompanion.insert(
          id: uuid.v4(),
          businessId: businessId,
          warehouseId: warehouseId,
          productUnitId: productUnitId,
          quantity: const drift.Value(10.0),
          averageCost: const drift.Value(1000.0),
        ),
      );

      // New Purchase: 10 units @ 1200 YER (local currency, rate = 1.0)
      final command = RecordPurchaseCommand(
        supplierId: supplierId,
        currencyId: baseCurrencyId,
        exchangeRate: 1.0,
        isCreditPurchase: true,
        items: [
          PurchaseItemCommand(
            productUnitId: productUnitId,
            warehouseId: warehouseId,
            quantity: 10.0,
            unitCost: 1200.0,
          ),
        ],
      );

      final result = await useCase(command);
      expect(result.isRight(), isTrue);

      // Verify Inventory Record:
      // Old total: 10 * 1000 = 10,000
      // New incoming: 10 * 1200 = 12,000
      // Total Qty: 20
      // New WAC: 22,000 / 20 = 1100 YER
      final inv = await inventoryRepository.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        productUnitId,
      );
      expect(inv, isNotNull);
      expect(inv!.quantity, 20.0);
      expect(inv.averageCost, 1100.0);

      // Verify Journal Entry is perfectly balanced
      final lines = await db.select(db.journalEntryLines).get();
      expect(lines.length, 2);
      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');

      expect(debitLine.baseAmount, 12000.0);
      expect(creditLine.baseAmount, 12000.0);
      expect(
        PrecisionMath.areBalanced(
          debitLine.baseAmount ?? 0,
          creditLine.baseAmount ?? 0,
        ),
        isTrue,
      );
    },
  );

  test(
    'Multi-currency purchase (USD -> YER) correctly normalizes unit cost into Base Currency WAC',
    () async {
      final productId = uuid.v4();
      final unitId = uuid.v4();
      final productUnitId = uuid.v4();

      await db.into(db.units).insert(
        UnitsCompanion.insert(
          id: unitId,
          businessId: businessId,
          unitName: 'Kilogram',
          unitSymbol: 'KG',
        ),
      );
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          id: productId,
          businessId: businessId,
          productCode: 'PROD-002',
          productName: 'Brazilian Sugar',
        ),
      );
      await db.into(db.productUnits).insert(
        ProductUnitsCompanion.insert(
          id: productUnitId,
          businessId: businessId,
          productId: productId,
          unitId: unitId,
          conversionFactor: const drift.Value(1.0),
          isBaseUnit: const drift.Value(true),
          sellingPrice: const drift.Value(1500.0),
          purchasePrice: const drift.Value(1000.0),
        ),
      );

      // Initial Stock: 10 units @ 1000 YER
      await db.into(db.inventories).insert(
        InventoriesCompanion.insert(
          id: uuid.v4(),
          businessId: businessId,
          warehouseId: warehouseId,
          productUnitId: productUnitId,
          quantity: const drift.Value(10.0),
          averageCost: const drift.Value(1000.0),
        ),
      );

      // Multi-currency Purchase: 10 units @ 2.0 USD (Exchange Rate: 530 YER/USD)
      // Unit cost in base = 2.0 * 530 = 1060 YER
      // Incoming value = 10 * 1060 = 10,600 YER
      // Total value = 10,000 + 10,600 = 20,600 YER
      // Expected new WAC = 20,600 / 20 = 1030.0 YER
      final command = RecordPurchaseCommand(
        supplierId: supplierId,
        currencyId: usdCurrencyId,
        exchangeRate: 530.0,
        isCreditPurchase: true,
        items: [
          PurchaseItemCommand(
            productUnitId: productUnitId,
            warehouseId: warehouseId,
            quantity: 10.0,
            unitCost: 2.0, // in USD
          ),
        ],
      );

      final result = await useCase(command);
      expect(result.isRight(), isTrue);

      final inv = await inventoryRepository.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        productUnitId,
      );
      expect(inv, isNotNull);
      expect(inv!.quantity, 20.0);
      expect(inv.averageCost, 1030.0); // Exactly normalized!

      // Verify Journal Entry Base and Foreign Amounts
      final lines = await db.select(db.journalEntryLines).get();
      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');

      expect(debitLine.foreignAmount, 20.0); // 10 * 2.0 USD
      expect(debitLine.baseAmount, 10600.0); // 20.0 * 530 = 10600 YER
      expect(creditLine.foreignAmount, 20.0);
      expect(creditLine.baseAmount, 10600.0);

      expect(
        PrecisionMath.areBalanced(
          debitLine.baseAmount ?? 0,
          creditLine.baseAmount ?? 0,
        ),
        isTrue,
      );
    },
  );
}
