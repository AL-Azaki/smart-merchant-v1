import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/app/di/getit_providers.dart';
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
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/session_provider.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/pos_provider.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late SalesRepository salesRepository;
  late InventoryRepository inventoryRepository;
  late AccountingRepository accountingRepository;
  late AccountingApplicationService accountingService;
  late SessionHolder sessionHolder;
  late String warehouseId;
  late String productUnitId;
  late String customerId;
  late String currencyId;
  late String businessId;
  late CompleteSaleUseCase useCase;

  setUp(() async {
    GetIt.I.reset();

    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    transactionRunner = ApplicationTransactionRunnerImpl(db);
    salesRepository = SalesRepositoryImpl(SalesDao(db));
    inventoryRepository = InventoryRepositoryImpl(InventoryDao(db));
    accountingRepository = AccountingRepositoryImpl(AccountingDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();
    currencyId = const Uuid().v4();
    warehouseId = const Uuid().v4();
    productUnitId = const Uuid().v4();
    customerId = const Uuid().v4();

    sessionHolder = SessionHolder();
    sessionHolder.setSession(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    final context = RuntimeApplicationContext(sessionHolder);

    GetIt.I.registerSingleton<SessionHolder>(sessionHolder);
    GetIt.I.registerSingleton<ApplicationContext>(context);

    accountingService = AccountingApplicationService(
      accountingRepository,
      context,
    );

    useCase = CompleteSaleUseCase(
      salesRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      context,
      transactionRunner,
    );

    // Register UseCase in GetIt so getit_providers can resolve it
    GetIt.I.registerSingleton<CompleteSaleUseCase>(useCase);

    // Seed master data
    await db
        .into(db.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: currencyId,
            currencyCode: 'USD',
            currencyNameAr: 'USD',
            currencyNameEn: 'USD',
            currencySymbol: '\$',
            decimalPlaces: drift.Value(2),
          ),
        );
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
    'FULL INTEGRATION: Riverpod PosNotifier -> GetIt CompleteSaleUseCase -> Repositories -> DAOs -> SQLite',
    () async {
      // 1. Setup Riverpod Container
      final container = ProviderContainer();

      // 2. Simulate User Interaction (UI -> Notifier)
      final posNotifier = container.read(posNotifierProvider.notifier);

      // User sets customer
      posNotifier.setCustomer(customerId, 'Test Customer');

      // User adds product (maps to seeded productUnitId)
      // By default PosNotifier uses 'p1' if id is missing, but our test will pass productUnitId directly
      posNotifier.addProduct(
        id: productUnitId,
        name: 'Real Product',
        price: 50.0,
      );

      // User submits sale
      // Note: The application layer CompleteSaleUseCase requires warehouseId for items.
      // PosNotifier currently hardcodes 'WH_MAIN' or similar in submitSale if not provided.
      // Let's modify PosNotifier's submitSale in our mind, wait no, let's look at PosNotifier.
      // I rewrote PosNotifier. Let's seed WH_MAIN so it succeeds.
      await db
          .into(db.warehouses)
          .insert(
            WarehousesCompanion.insert(
              id: 'WH-DEFAULT',
              businessId: businessId,
              branchId: const Uuid().v4(),
              warehouseCode: 'WH01',
              warehouseName: 'Main',
            ),
          );
      // Since we seeded Inventory with warehouseId (random UUID) earlier, we must seed WH-DEFAULT inventory too, or just use the random one if posNotifier allows it.
      // Let's seed WH-DEFAULT inventory
      await db
          .into(db.inventories)
          .insert(
            InventoriesCompanion.insert(
              id: const Uuid().v4(),
              businessId: businessId,
              warehouseId: 'WH-DEFAULT',
              productUnitId: productUnitId,
              quantity: drift.Value(100.0),
              averageCost: drift.Value(10.0),
            ),
          );

      await posNotifier.submitSale(cashReceived: 50.0, paymentMethodId: 'CASH');

      // 3. Verify Riverpod State
      final state = container.read(posNotifierProvider);
      expect(state.error, isNull, reason: 'Sale should succeed without error');
      expect(
        state.successInvoiceId,
        isNotNull,
        reason: 'Sale must return successInvoiceId',
      );

      // 4. Verify SQLite Database (DAOs -> ORM)
      final invoices = await db.select(db.salesInvoices).get();
      expect(invoices.length, 1, reason: 'Invoice must be saved to DB');
      expect(invoices.first.id, state.successInvoiceId);

      final txs = await db.select(db.inventoryTransactions).get();
      expect(txs.length, 1, reason: 'Inventory must be updated');

      final journals = await db.select(db.journalEntries).get();
      expect(journals.length, 1, reason: 'Accounting journal must be posted');
    },
  );
}
