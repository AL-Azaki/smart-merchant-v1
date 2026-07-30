import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/app/di/getit_instance.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_merchant_erp/modules/treasury/domain/repositories/treasury_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';
import 'package:smart_merchant_erp/database/daos/treasury_dao.dart';
import 'package:drift/drift.dart' as drift;

// To perform real database transaction checks, we use a real in-memory SQLite database
void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late SalesRepository salesRepository;
  late InventoryRepository inventoryRepository;
  late AccountingRepository accountingRepository;
  late TreasuryRepository treasuryRepository;
  late AccountingApplicationService accountingService;
  late ApplicationContext context;
  late String warehouseId;
  late String productUnitId;
  late String customerId;
  late String currencyId;
  late String businessId;
  late CompleteSaleUseCase useCase;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    transactionRunner = ApplicationTransactionRunnerImpl(db);
    salesRepository = SalesRepositoryImpl(SalesDao(db));
    inventoryRepository = InventoryRepositoryImpl(InventoryDao(db));
    accountingRepository = AccountingRepositoryImpl(AccountingDao(db));
    treasuryRepository = TreasuryRepositoryImpl(TreasuryDao(db));

    // Seed required master data for foreign keys to pass
    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();
    currencyId = const Uuid().v4();
    warehouseId = const Uuid().v4();
    productUnitId = const Uuid().v4();
    customerId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );
    accountingService = AccountingApplicationService(
      accountingRepository,
      context,
    );

    final coreRepository = CoreRepositoryImpl(CoreDao(db));

    useCase = CompleteSaleUseCase(
      salesRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      context,
      transactionRunner,
      db,
    );

        // Seed Currency
    await db.into(db.currencies).insert(
      CurrenciesCompanion.insert(
        id: currencyId,
        currencyCode: 'TST',
        currencyNameAr: 'Test',
        currencyNameEn: 'Test',
        currencySymbol: 'T',
        isActive: const drift.Value(true),
      )
    );
    

    
    
    // Seed Customer
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        id: customerId,
        businessId: businessId,
        customerName: 'Test Customer',
        isActive: const drift.Value(true),
      )
    );
    // Seed Context Data
    await db.into(db.accountsTable).insert(
      AccountsTableCompanion.insert(
        id: const drift.Value('acc-test'),
        ownerId: 'test-user',
        businessName: 'Test Account',
        businessType: 'test',
        defaultCurrency: 'YER',
      )
    );
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: businessId,
        accountId: 'acc-test',
        businessName: 'Test Biz',
        status: const drift.Value('Active'),
      )
    );
    await db.into(db.usersTable).insert(
      UsersTableCompanion.insert(
        id: drift.Value(context.currentUserId),
        email: 'test@example.com',
        passwordHash: 'hash',
        firstName: 'Test',
        lastName: 'User',
        isActive: const drift.Value(true),
      )
    );
    await db.into(db.branches).insert(
      BranchesCompanion.insert(
        id: context.currentBranchId!,
        businessId: businessId,
        branchCode: 'TB-01',
        branchName: 'Test Branch',
        isActive: const drift.Value(true),
      )
    );

    
    // Seed Warehouse
    await db.into(db.warehouses).insert(
      WarehousesCompanion.insert(
        id: warehouseId,
        businessId: businessId,
        branchId: context.currentBranchId!,
        warehouseName: 'Test Warehouse',
        warehouseCode: 'WH-01',
        isActive: const drift.Value(true),
      )
    );
    // Seed Initial Inventory
    await db
        .into(db.inventories)
        .insert(
          InventoriesCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            warehouseId: warehouseId,
            productUnitId: productUnitId,
            quantity: drift.Value(100.0),
            averageCost: drift.Value(10.0),
          ),
        );

    // Seed Fiscal Period
    final yearId = const Uuid().v4();
    final periodId = const Uuid().v4();
    await db
        .into(db.fiscalPeriods)
        .insert(
          FiscalPeriodsCompanion.insert(
            id: periodId,
            businessId: businessId,
            fiscalYearId: yearId,
            periodNumber: 1,
            periodName: 'P1',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            status: const drift.Value('Open'),
          ),
        );

    // Seed Mappings & Accounts
    final arAccId = const Uuid().v4();
    final revAccId = const Uuid().v4();
    final cogsAccId = const Uuid().v4();
    final invAccId = const Uuid().v4();

    for (var accId in [arAccId, revAccId, cogsAccId, invAccId]) {
      await db
          .into(db.chartOfAccounts)
          .insert(
            ChartOfAccountsCompanion.insert(
              id: accId,
              businessId: businessId,
              accountCode: 'A-$accId',
              accountName: 'Acc',
              accountTypeId: 1,
              normalBalance: 'Debit',
            ),
          );
    }

    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            mappingKey: 'accounts_receivable',
            mappingName: 'AR',
            chartOfAccountId: arAccId,
          ),
        );
    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            mappingKey: 'sales_revenue',
            mappingName: 'Rev',
            chartOfAccountId: revAccId,
          ),
        );
    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            mappingKey: 'cost_of_goods_sold',
            mappingName: 'COGS',
            chartOfAccountId: cogsAccId,
          ),
        );
    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            mappingKey: 'inventory_asset',
            mappingName: 'Inv',
            chartOfAccountId: invAccId,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'CompleteSaleUseCase - Valid Sale successfully commits all records',
    () async {
      final command = CompleteSaleCommand(
        customerId: customerId,
        currencyId: currencyId,
        isCreditSale: true,
        items: [
          CompleteSaleItemCommand(
            productUnitId: productUnitId,
            warehouseId: warehouseId,
            quantity: 2.0,
            unitPrice: 50.0,
          ),
        ],
      );

      final result = await useCase(command);

      if (result.isLeft()) {
        result.fold((l) => print('Use Case Failed: ${l.message}'), (r) => null);
      }
      expect(result.isRight(), isTrue);

      // Verify Invoice exists
      final invoices = await db.select(db.salesInvoices).get();
      expect(invoices.length, 1);
      expect(invoices.first.subTotal, 100.0);

      // Verify Inventory Transaction exists
      final txs = await db.select(db.inventoryTransactions).get();
      expect(txs.length, 1);

      // Verify Journal Entry exists
      final journals = await db.select(db.journalEntries).get();
      expect(journals.length, 1);
    },
  );

  test('CompleteSaleUseCase - Rollback on Journal Posting Failure', () async {
    // To force a failure during journal posting, we can delete the fiscal period
    await db.delete(db.fiscalPeriods).go();

    final command = CompleteSaleCommand(
      customerId: customerId,
      currencyId: currencyId,
      isCreditSale: true,
      items: [
        CompleteSaleItemCommand(
          productUnitId: productUnitId,
          warehouseId: warehouseId,
          quantity: 2.0,
          unitPrice: 50.0,
        ),
      ],
    );

    final result = await useCase(command);

    expect(result.isLeft(), isTrue);

    // Prove NO partial records
    final invoices = await db.select(db.salesInvoices).get();
    expect(invoices.isEmpty, isTrue, reason: 'Invoice must rollback');

    final txs = await db.select(db.inventoryTransactions).get();
    expect(txs.isEmpty, isTrue, reason: 'Inventory Transaction must rollback');

    final receivables = await db.select(db.customerReceivables).get();
    expect(receivables.isEmpty, isTrue, reason: 'Receivable must rollback');

    final journals = await db.select(db.journalEntries).get();
    expect(journals.isEmpty, isTrue, reason: 'Journal must rollback');
  });

  test('CompleteSaleUseCase - Insufficient Stock Blocks Sale', () async {
    final command = CompleteSaleCommand(
      customerId: customerId,
      currencyId: currencyId,
      isCreditSale: true,
      items: [
        CompleteSaleItemCommand(
          productUnitId: productUnitId,
          warehouseId: warehouseId,
          quantity: 500.0, // Stock is 100
          unitPrice: 50.0,
        ),
      ],
    );

    final result = await useCase(command);
    expect(result.isLeft(), isTrue);

    // Verify ZERO partial state
    final invoices = await db.select(db.salesInvoices).get();
    expect(invoices.isEmpty, isTrue);
  });
}
