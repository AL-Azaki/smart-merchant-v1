import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_sync_queries.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/inventory/application/services/warehouse_context_service.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/modules/sales/application/services/online_order_service.dart';
import 'package:smart_merchant_erp/modules/authentication/presentation/providers/session_provider.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/pos_provider.dart';
import 'package:smart_merchant_erp/app/di/getit_providers.dart';

void main() {
  late AppDatabase db;
  late SalesDao salesDao;
  late InventoryDao inventoryDao;
  late AccountingDao accountingDao;
  late SalesRepository salesRepository;
  late InventoryRepository inventoryRepository;
  late AccountingRepository accountingRepository;
  late AccountingApplicationService accountingService;
  late ApplicationTransactionRunner transactionRunner;
  late SessionHolder sessionHolder;
  late RuntimeApplicationContext appContext;
  late OnlineOrderService onlineOrderService;
  late CompleteSaleUseCase completeSaleUseCase;
  late ProviderContainer container;

  // Constants matching our Laravel test business & setup
  const businessId = '01a1519a-41b9-70b5-9cb8-5d781bfe063a';
  const branchId = '01a1519a-41bb-70a6-8625-c7c33d0ed19e';
  const channelId = '01a1519a-41bc-728c-977d-c0afdd034dd9';
  const currencyId = 'YER';
  const warehouseId = '01a1519a-wh-test-001';
  const userId = 'u-e2e-cashier-001';
  const productUnitId = '77a3d067-6db9-4ccd-b5f2-8f6d812ce7f6';
  const productId = 'a1261ae2-e191-448e-87b6-ddb6596a1699';

  Future<double> getStock() async {
    final rows = await db.customSelect(
      'SELECT quantity FROM inventories WHERE business_id = ? AND warehouse_id = ? AND product_unit_id = ?',
      variables: [
        drift.Variable.withString(businessId),
        drift.Variable.withString(warehouseId),
        drift.Variable.withString(productUnitId),
      ],
    ).get();
    if (rows.isEmpty) return 0.0;
    return rows.first.read<double>('quantity');
  }

  setUp(() async {
    GetIt.I.reset();

    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    salesDao = SalesDao(db);
    inventoryDao = InventoryDao(db);
    accountingDao = AccountingDao(db);

    salesRepository = SalesRepositoryImpl(salesDao);
    inventoryRepository = InventoryRepositoryImpl(inventoryDao);
    accountingRepository = AccountingRepositoryImpl(accountingDao);
    transactionRunner = ApplicationTransactionRunnerImpl(db);

    sessionHolder = SessionHolder();
    sessionHolder.setSession(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    appContext = RuntimeApplicationContext(sessionHolder);

    onlineOrderService = OnlineOrderService(salesRepository, appContext);
    accountingService = AccountingApplicationService(accountingRepository, appContext);

    completeSaleUseCase = CompleteSaleUseCase(
      salesRepository,
      inventoryRepository,
      accountingRepository,
      accountingService,
      appContext,
      transactionRunner,
      db,
    );

    GetIt.I.registerSingleton<SessionHolder>(sessionHolder);
    GetIt.I.registerSingleton<ApplicationContext>(appContext);
    GetIt.I.registerSingleton<SalesRepository>(salesRepository);
    GetIt.I.registerSingleton<InventoryRepository>(inventoryRepository);
    GetIt.I.registerSingleton<AccountingRepository>(accountingRepository);
    GetIt.I.registerSingleton<WarehouseContextService>(WarehouseContextService(inventoryRepository));
    GetIt.I.registerSingleton<OnlineOrderService>(onlineOrderService);
    GetIt.I.registerSingleton<CompleteSaleUseCase>(completeSaleUseCase);

    // Seed master data required by foreign keys and warehouse context
    await db.customStatement(
      "INSERT OR IGNORE INTO businesses(id, account_id, business_name, primary_phone) VALUES (?, 'acc-01', 'TEST Business E2E', '967770000111')",
      [businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO branches(id, business_id, branch_name, branch_code) VALUES (?, ?, 'Online Branch Test', 'ONLINE-01')",
      [branchId, businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO channels(id, business_id, channel_name, channel_code, channel_type) VALUES (?, ?, 'Online Store', 'ONLINE-STORE-01', 'Ecommerce')",
      [channelId, businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO currencies(id, currency_code, currency_name_ar, currency_name_en, currency_symbol) VALUES (?, 'YER', 'ريال يمني', 'Yemeni Rial', '﷼')",
      [currencyId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO warehouses(id, business_id, branch_id, warehouse_name, warehouse_code, is_active) VALUES (?, ?, ?, 'Main Warehouse', 'WH-MAIN', 1)",
      [warehouseId, businessId, branchId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO users(id, email, password_hash, first_name, last_name) VALUES (?, 'cashier@example.com', 'hash', 'Cashier', 'E2E')",
      [userId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO units(id, business_id, unit_name, unit_symbol) VALUES ('unit-piece', ?, 'حبة', 'حبة')",
      [businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO categories(id, business_id, category_name, category_code) VALUES ('cat-test', ?, 'فئة الاختبار التكاملي', 'CAT-01')",
      [businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO products(id, business_id, product_name, product_code, product_type, category_id) VALUES (?, ?, 'منتج الاختبار التكاملي', 'PRD-01', 'standard', 'cat-test')",
      [productId, businessId],
    );
    await db.customStatement(
      "INSERT OR IGNORE INTO product_units(id, business_id, product_id, unit_id, barcode, sku, conversion_factor, selling_price, purchase_price) VALUES (?, ?, ?, 'unit-piece', '123456', 'SKU-01', 1.0, 1500.0, 1000.0)",
      [productUnitId, businessId, productId],
    );

    // Initial stock: 100 units in warehouse
    await db.customStatement(
      "INSERT OR REPLACE INTO inventories(id, business_id, warehouse_id, product_unit_id, quantity, average_cost) VALUES ('inv-001', ?, ?, ?, 100.0, 1000.0)",
      [businessId, warehouseId, productUnitId],
    );

    // Seed accounting data for CompleteSaleUseCase
    final yearId = const Uuid().v4();
    final periodId = const Uuid().v4();
    await db.into(db.fiscalPeriods).insert(
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
      await db.into(db.chartOfAccounts).insert(
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

    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: const Uuid().v4(),
        businessId: businessId,
        mappingKey: 'accounts_receivable',
        mappingName: 'AR',
        chartOfAccountId: arAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: const Uuid().v4(),
        businessId: businessId,
        mappingKey: 'sales_revenue',
        mappingName: 'Rev',
        chartOfAccountId: revAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: const Uuid().v4(),
        businessId: businessId,
        mappingKey: 'cost_of_goods_sold',
        mappingName: 'COGS',
        chartOfAccountId: cogsAccId,
      ),
    );
    await db.into(db.accountMappings).insert(
      AccountMappingsCompanion.insert(
        id: const Uuid().v4(),
        businessId: businessId,
        mappingKey: 'inventory_asset',
        mappingName: 'Inv',
        chartOfAccountId: invAccId,
      ),
    );

    // Setup Riverpod container
    container = ProviderContainer();
    container.read(sessionNotifierProvider.notifier).setSession(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );
  });

  tearDown(() async {
    try {
      container.dispose();
    } catch (_) {}
    await db.close();
  });

  group('Phase 6 E2E Operational Order Flow', () {
    test('Pull order from Laravel payload -> SQLite insert -> Accept -> POS Convert -> Single Invoice -> Delivered', () async {
      // 1. Arrange: Exact Laravel pull payload for order ORD-6AD5685C9DCFA
      final pulledOrderJson = <String, dynamic>{
        'id': '01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ORD-6AD5685C9DCFA',
        'order_date': DateTime.now().toIso8601String(),
        'currency_id': currencyId,
        'exchange_rate': 1.0,
        'sub_total': 3000.0,
        'discount_total': 0.0,
        'tax_total': 0.0,
        'grand_total': 3000.0,
        'status': 'Pending',
        'customer_id': null,
        'notes': 'E2E TEST ONLY - Customer: عميل اختبار تكاملي (770000222), City: مدينة اختبار, Address: شارع الاختبار 101',
        'revision': 1,
        'items': [
          {
            'id': '01a1519f-a9f1-70d0-b9a4-dd5fdb1e7647',
            'product_unit_id': productUnitId,
            'quantity': 2.0,
            'unit_price': 1500.0,
            'discount': 0.0,
            'tax': 0.0,
            'line_total': 3000.0,
          }
        ],
      };

      // 2. Act: Insert into SQLite via SalesDao
      await salesDao.insertOnlineOrder(pulledOrderJson);

      // Verify order exists locally in SQLite
      final localOrder = await salesDao.getOrderById('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646', businessId);
      expect(localOrder, isNotNull);
      expect(localOrder!.orderNumber, 'ORD-6AD5685C9DCFA');
      expect(localOrder.grandTotal, 3000.0);
      expect(localOrder.status, 'Pending');
      expect(localOrder.syncStatus, 'synced');

      final orderWithItems = await salesDao.getOrderWithItemsById('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646', businessId);
      expect(orderWithItems, isNotNull);
      expect(orderWithItems!.items.length, 1);
      expect(orderWithItems.items.first.productUnitId, productUnitId);
      expect(orderWithItems.items.first.quantity, 2.0);
      expect(orderWithItems.items.first.unitPrice, 1500.0);
      expect(orderWithItems.items.first.lineTotal, 3000.0);

      // 3. Verify INVARIANT: ZERO invoices, inventory transactions, or journals created on pull
      final invoicesBefore = await salesDao.listInvoices(SalesInvoiceFilter(businessId: businessId));
      expect(invoicesBefore.length, 0, reason: 'Pull must not create invoices');

      final stockBefore = await getStock();
      expect(stockBefore, 100.0, reason: 'Pull must not deduct inventory');

      // 4. Duplicate Pull Prevention
      await salesDao.insertOnlineOrder(pulledOrderJson);
      final allOrders = await salesDao.listOnlineOrders(businessId);
      expect(allOrders.length, 1, reason: 'Duplicate pull must be ignored by insertOrIgnore');

      // 5. Cashier Reviews & Accepts Order via OnlineOrderService
      final acceptResult = await onlineOrderService.acceptOrder('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646');
      expect(acceptResult.isRight(), true);

      final acceptedOrder = await salesDao.getOrderById('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646', businessId);
      expect(acceptedOrder!.status, 'Confirmed');

      // Keep PosNotifier alive across async steps
      final sub = container.listen(posNotifierProvider, (_, __) {});

      // 6. Load Accepted Order into POS
      final posNotifier = container.read(posNotifierProvider.notifier);
      final reloadedOrderWithItems = await salesDao.getOrderWithItemsById('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646', businessId);
      await posNotifier.loadFromOnlineOrder(reloadedOrderWithItems!);

      final posStateAfterLoad = container.read(posNotifierProvider);
      expect(posStateAfterLoad.sourceOrderId, '01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646');
      expect(posStateAfterLoad.cart.length, 1);
      expect(posStateAfterLoad.cart.first.unitPrice, 1500.0, reason: 'POS cart must preserve historical order price');
      expect(posStateAfterLoad.cart.first.quantity, 2.0);
      expect(posStateAfterLoad.totals.grandTotal, 3000.0);

      // 7. Complete POS Sale
      await posNotifier.submitSale(
        cashReceived: 3000.0,
        paymentMethodId: 'CASH',
      );
      // Wait for inner async callback in result.fold to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final posStateAfterSubmit = container.read(posNotifierProvider);
      expect(posStateAfterSubmit.error, isNull);
      expect(posStateAfterSubmit.successInvoiceId, isNotNull, reason: 'Sale must succeed and produce an invoice ID');
      final invoiceId = posStateAfterSubmit.successInvoiceId!;

      // Verify POS Cart is cleared after sale
      expect(posStateAfterSubmit.cart, isEmpty);

      // 8. Verify SQLite Data:
      // (a) Single invoice created
      final invoicesAfter = await salesDao.listInvoices(SalesInvoiceFilter(businessId: businessId));
      expect(invoicesAfter.length, 1, reason: 'Exactly ONE sales invoice created');
      expect(invoicesAfter.first.id, invoiceId);
      expect(invoicesAfter.first.grandTotal, 3000.0);

      // (b) Order status moved to 'Delivered'
      final finalizedOrder = await salesDao.getOrderById('01a1519f-a9f1-70d0-b9a4-dd5fdb1e7646', businessId);
      expect(finalizedOrder!.status, 'Delivered', reason: 'Order status must be Delivered after successful POS sale');

      // (c) Inventory deducted: 100 - 2 = 98 units
      final stockAfter = await getStock();
      expect(stockAfter, 98.0, reason: 'Inventory must be deducted by 2 units');

      // 9. Attempt Second Conversion (CRITICAL INVARIANT: Double-fulfillment prevention)
      // Attempt to load the delivered order again
      await posNotifier.loadFromOnlineOrder(
        OrderWithItems(order: finalizedOrder, items: reloadedOrderWithItems.items),
      );
      final posStateAfterSecondAttempt = container.read(posNotifierProvider);
      expect(posStateAfterSecondAttempt.error, isNotNull, reason: 'Second load attempt must fail');
      final errorStr = posStateAfterSecondAttempt.error.toString();
      expect(
        errorStr.contains('Delivered') ||
        errorStr.contains('مكتمل بالفعل') ||
        errorStr.contains('Confirmed'),
        true,
        reason: 'Attempting to re-load a Delivered order must be blocked',
      );

      // Verify still only 1 invoice and stock remains 98
      final finalInvoices = await salesDao.listInvoices(SalesInvoiceFilter(businessId: businessId));
      expect(finalInvoices.length, 1, reason: 'No duplicate invoice created on second attempt');

      final finalStock = await getStock();
      expect(finalStock, 98.0, reason: 'No duplicate inventory deduction');
    });

    test('Tenant Isolation: Orders belonging to Business B cannot be read or processed by Business A', () async {
      const otherBusinessId = '01a1519a-41b9-70b5-9cb8-OTHER-BIZ';

      // Insert order for Other Business
      await db.customStatement(
        "INSERT OR IGNORE INTO businesses(id, account_id, business_name, primary_phone) VALUES (?, 'acc-02', 'Other Store', '967770000999')",
        [otherBusinessId],
      );
      await db.customStatement(
        "INSERT OR IGNORE INTO branches(id, business_id, branch_name, branch_code) VALUES ('branch-b', ?, 'Branch B', 'B-01')",
        [otherBusinessId],
      );
      await db.customStatement(
        "INSERT OR IGNORE INTO channels(id, business_id, channel_name, channel_code, channel_type) VALUES ('channel-b', ?, 'Store B', 'ECOM-B', 'Ecommerce')",
        [otherBusinessId],
      );

      final otherOrderJson = <String, dynamic>{
        'id': 'order-from-biz-b',
        'business_id': otherBusinessId,
        'branch_id': 'branch-b',
        'channel_id': 'channel-b',
        'order_number': 'ORD-BIZ-B-001',
        'order_date': DateTime.now().toIso8601String(),
        'currency_id': currencyId,
        'sub_total': 5000.0,
        'grand_total': 5000.0,
        'status': 'Pending',
        'revision': 1,
        'items': [],
      };

      await salesDao.insertOnlineOrder(otherOrderJson);

      // Business A queries
      final orderForBizA = await salesDao.getOrderById('order-from-biz-b', businessId);
      expect(orderForBizA, isNull, reason: 'Business A must not access Business B order');

      final listForBizA = await salesDao.listOnlineOrders(businessId);
      expect(listForBizA.any((o) => o.id == 'order-from-biz-b'), false);

      // Attempt to accept Business B's order using Business A context
      final acceptResult = await onlineOrderService.acceptOrder('order-from-biz-b');
      expect(acceptResult.isLeft(), true, reason: 'Cannot accept another business order');
    });
  });
}
