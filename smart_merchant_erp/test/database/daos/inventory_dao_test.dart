import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';
import 'package:smart_merchant_erp/database/enums/inventory_movement_direction.dart';
import 'package:smart_merchant_erp/database/enums/inventory_reference_type.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_status.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_type.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transfer_status.dart';

void main() {
  late AppDatabase database;
  late InventoryDao inventoryDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    inventoryDao = InventoryDao(database);

    // Seed required parent User, Account, Businesses, Branches, and Catalog items for foreign keys
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@inventory.com',
            passwordHash: 'hash',
            firstName: 'Inventory',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-inv-01'),
            ownerId: 'u-owner',
            businessName: 'Inventory Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-inv-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-inv-01',
            businessName: 'Business Beta',
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_1',
            businessId: 'BUS_A',
            branchName: 'Main Branch Alpha',
            branchCode: 'BR-A1',
            isDefault: const drift.Value(true),
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_2',
            businessId: 'BUS_A',
            branchName: 'Sub Branch Alpha',
            branchCode: 'BR-A2',
          ),
        );

    // Seed basic unit, product, and product unit for inventory items
    await database
        .into(database.units)
        .insert(
          UnitsCompanion.insert(
            id: 'unit-box',
            businessId: 'BUS_A',
            unitName: 'Box',
            unitSymbol: 'BX',
          ),
        );
    await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            id: 'prod-01',
            businessId: 'BUS_A',
            productCode: 'PRD-01',
            productName: 'Sample Product One',
          ),
        );
    await database
        .into(database.productUnits)
        .insert(
          ProductUnitsCompanion.insert(
            id: 'pu-box-01',
            businessId: 'BUS_A',
            productId: 'prod-01',
            unitId: 'unit-box',
            isBaseUnit: const drift.Value(true),
            sellingPrice: const drift.Value(100.0),
          ),
        );
    await database
        .into(database.productVariants)
        .insert(
          ProductVariantsCompanion.insert(
            id: 'var-color-blue',
            businessId: 'BUS_A',
            productUnitId: 'pu-box-01',
            variantName: 'Color',
            variantValue: 'Blue',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('InventoryDao Phase 03 Test Suite -', () {
    test(
      '1. Warehouses CRUD, Branch & Tenant Scoping, Soft Delete & Restore',
      () async {
        const whId = 'wh-main-01';
        await inventoryDao.insertWarehouse(
          WarehousesCompanion.insert(
            id: whId,
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            warehouseName: 'Main Alpha Warehouse',
            warehouseCode: 'WH-01',
            isDefault: const drift.Value(true),
          ),
        );

        // Fetch by ID
        final fetched = await inventoryDao.getWarehouseById(whId, 'BUS_A');
        expect(fetched, isNotNull);
        expect(fetched!.warehouseName, equals('Main Alpha Warehouse'));

        // Default warehouse by branch
        final defaultWh = await inventoryDao.getDefaultWarehouseByBranch(
          'BUS_A',
          'BRANCH_1',
        );
        expect(defaultWh, isNotNull);
        expect(defaultWh!.id, equals(whId));

        // List with filter
        final list = await inventoryDao.listWarehouses(
          const WarehouseFilter(businessId: 'BUS_A', branchId: 'BRANCH_1'),
        );
        expect(list.length, equals(1));

        // Soft delete & check exclusion
        await inventoryDao.softDeleteWarehouse(whId, 'BUS_A');
        expect(await inventoryDao.getWarehouseById(whId, 'BUS_A'), isNull);
        expect(
          await inventoryDao.getWarehouseById(
            whId,
            'BUS_A',
            includeDeleted: true,
          ),
          isNotNull,
        );

        final archived = await inventoryDao.getArchivedWarehouses('BUS_A');
        expect(archived.length, equals(1));
        expect(archived.first.syncStatus, equals('pending_delete'));

        // Restore
        await inventoryDao.restoreWarehouse(whId, 'BUS_A');
        final restored = await inventoryDao.getWarehouseById(whId, 'BUS_A');
        expect(restored, isNotNull);
        expect(restored!.syncStatus, equals('pending_update'));
      },
    );

    test(
      '2. Inventories Stock Balance CRUD, Low Stock Query, and Detailed StockBalanceView',
      () async {
        const whId = 'wh-stock-01';
        await inventoryDao.insertWarehouse(
          WarehousesCompanion.insert(
            id: whId,
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            warehouseName: 'Stock Warehouse',
            warehouseCode: 'WH-STK',
          ),
        );

        const invId = 'inv-01';
        await inventoryDao.insertInventory(
          InventoriesCompanion.insert(
            id: invId,
            businessId: 'BUS_A',
            warehouseId: whId,
            productUnitId: 'pu-box-01',
            quantity: const drift.Value(5.0),
            alertQuantity: const drift.Value(
              10.0,
            ), // Alert limit > current quantity
          ),
        );

        final fetched = await inventoryDao.getInventoryById(invId, 'BUS_A');
        expect(fetched, isNotNull);
        expect(fetched!.quantity, equals(5.0));

        final byUnitWh = await inventoryDao.getInventoryByUnitAndWarehouse(
          'BUS_A',
          whId,
          'pu-box-01',
        );
        expect(byUnitWh, isNotNull);
        expect(byUnitWh!.id, equals(invId));

        // Low stock query verification
        final lowStockList = await inventoryDao.listInventories(
          const InventoryFilter(businessId: 'BUS_A', lowStockOnly: true),
        );
        expect(lowStockList.length, equals(1));
        expect(lowStockList.first.id, equals(invId));

        // Detailed StockBalanceView joining Inventory with ProductUnit, Product, and Variants
        final detailedViews = await inventoryDao.getDetailedStockBalances(
          const InventoryFilter(businessId: 'BUS_A'),
        );
        expect(detailedViews.length, equals(1));
        final view = detailedViews.first;
        expect(view.inventory.id, equals(invId));
        expect(view.productUnit.id, equals('pu-box-01'));
        expect(view.product.productName, equals('Sample Product One'));
        expect(view.variants.length, equals(1));
        expect(view.variants.first.variantValue, equals('Blue'));
      },
    );

    test(
      '3. Inventory Transactions Atomic Seeding with Lines & Status Updates',
      () async {
        const whId = 'wh-txn-01';
        await inventoryDao.insertWarehouse(
          WarehousesCompanion.insert(
            id: whId,
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            warehouseName: 'Txn Warehouse',
            warehouseCode: 'WH-TXN',
          ),
        );

        final txnCompanion = InventoryTransactionsCompanion.insert(
          id: 'txn-100',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          warehouseId: whId,
          transactionType: InventoryTransactionType.receipt,
          movementDirection: InventoryMovementDirection.inbound,
          status: const drift.Value(InventoryTransactionStatus.draft),
          createdBy: 'u-owner',
        );

        final linesCompanion = <InventoryTransactionLinesCompanion>[
          InventoryTransactionLinesCompanion.insert(
            id: 'line-101',
            businessId: 'BUS_A',
            inventoryTransactionId: 'txn-100',
            productUnitId: 'pu-box-01',
            quantity: 50.0,
            unitCost: const drift.Value(80.0),
            lineNumber: const drift.Value(1),
          ),
        ];

        // Record transaction atomically
        await inventoryDao.recordTransactionWithLines(
          transaction: txnCompanion,
          lines: linesCompanion,
        );

        final fetchedWithLines = await inventoryDao.getTransactionWithLinesById(
          'txn-100',
          'BUS_A',
        );
        expect(fetchedWithLines, isNotNull);
        expect(
          fetchedWithLines!.transaction.transactionType,
          equals(InventoryTransactionType.receipt),
        );
        expect(fetchedWithLines.lines.length, equals(1));
        expect(fetchedWithLines.lines.first.quantity, equals(50.0));

        // Update status to posted
        final updated = await inventoryDao.updateTransactionStatus(
          'txn-100',
          'BUS_A',
          InventoryTransactionStatus.posted,
          postedBy: 'u-owner',
          postedAt: DateTime.now(),
        );
        expect(updated, isTrue);

        final afterUpdate = await inventoryDao.getTransactionById(
          'txn-100',
          'BUS_A',
        );
        expect(afterUpdate!.status, equals(InventoryTransactionStatus.posted));
        expect(afterUpdate.postedBy, equals('u-owner'));

        // Test Rollback on invalid child FK
        final invalidTxn = InventoryTransactionsCompanion.insert(
          id: 'txn-rollback-200',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          warehouseId: whId,
          transactionType: InventoryTransactionType.adjustmentIn,
          movementDirection: InventoryMovementDirection.inbound,
          createdBy: 'u-owner',
        );
        final invalidLines = <InventoryTransactionLinesCompanion>[
          InventoryTransactionLinesCompanion.insert(
            id: 'line-invalid',
            businessId: 'BUS_A',
            inventoryTransactionId: 'txn-rollback-200',
            productUnitId: 'non-existent-pu-999', // Will trigger FK violation
            quantity: 10.0,
            unitCost: const drift.Value(10.0),
          ),
        ];

        expect(
          () async => await inventoryDao.recordTransactionWithLines(
            transaction: invalidTxn,
            lines: invalidLines,
          ),
          throwsA(isA<sqlite.SqliteException>()),
        );

        expect(
          await inventoryDao.getTransactionById('txn-rollback-200', 'BUS_A'),
          isNull,
        );
      },
    );

    test(
      '4. Inventory Transfers Atomic Seeding with Items & Status Updates',
      () async {
        const whFrom = 'wh-from';
        const whTo = 'wh-to';
        await inventoryDao.insertWarehouse(
          WarehousesCompanion.insert(
            id: whFrom,
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            warehouseName: 'Source WH',
            warehouseCode: 'WH-SRC',
          ),
        );
        await inventoryDao.insertWarehouse(
          WarehousesCompanion.insert(
            id: whTo,
            businessId: 'BUS_A',
            branchId: 'BRANCH_2',
            warehouseName: 'Dest WH',
            warehouseCode: 'WH-DST',
          ),
        );

        final transferCompanion = InventoryTransfersCompanion.insert(
          id: 'trf-500',
          businessId: 'BUS_A',
          fromWarehouseId: whFrom,
          toWarehouseId: whTo,
          transferNumber: 'TRF-500',
          status: const drift.Value(InventoryTransferStatus.pending),
          createdBy: 'u-owner',
        );

        final itemsCompanion = <InventoryTransferItemsCompanion>[
          InventoryTransferItemsCompanion.insert(
            id: 'item-501',
            businessId: 'BUS_A',
            transferId: 'trf-500',
            productUnitId: 'pu-box-01',
            quantity: 20.0,
          ),
        ];

        await inventoryDao.recordTransferWithItems(
          transfer: transferCompanion,
          items: itemsCompanion,
        );

        final fetchedWithItems = await inventoryDao.getTransferWithItemsById(
          'trf-500',
          'BUS_A',
        );
        expect(fetchedWithItems, isNotNull);
        expect(fetchedWithItems!.transfer.fromWarehouseId, equals(whFrom));
        expect(fetchedWithItems.items.length, equals(1));
        expect(fetchedWithItems.items.first.quantity, equals(20.0));

        // Update status
        final statusUpdated = await inventoryDao.updateTransferStatus(
          'trf-500',
          'BUS_A',
          InventoryTransferStatus.completed,
        );
        expect(statusUpdated, isTrue);

        final afterUpdate = await inventoryDao.getTransferById(
          'trf-500',
          'BUS_A',
        );
        expect(afterUpdate!.status, equals(InventoryTransferStatus.completed));
      },
    );

    test(
      '5. Strict Tenant Scoping Exception Verification across methods',
      () async {
        expect(
          () async => await inventoryDao.getWarehouseById('wh-main-01', ''),
          throwsA(isA<TenantScopingException>()),
        );
        expect(
          () async => await inventoryDao.listInventories(
            const InventoryFilter(businessId: '  '),
          ),
          throwsA(isA<TenantScopingException>()),
        );
        expect(
          () async => await inventoryDao.listTransactions(
            const InventoryTransactionFilter(businessId: ''),
          ),
          throwsA(isA<TenantScopingException>()),
        );
        expect(
          () async => await inventoryDao.listTransfers(
            const InventoryTransferFilter(businessId: ''),
          ),
          throwsA(isA<TenantScopingException>()),
        );
      },
    );

    test('6. Offline-First Synchronization Tracking Helpers', () async {
      const whId = 'wh-sync-test';
      await inventoryDao.insertWarehouse(
        WarehousesCompanion.insert(
          id: whId,
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          warehouseName: 'Sync WH',
          warehouseCode: 'WH-SYNC',
          syncStatus: const drift.Value('pending'),
        ),
      );

      final pendingWh = await inventoryDao.getPendingSyncWarehouses('BUS_A');
      expect(pendingWh.any((w) => w.id == whId), isTrue);

      await inventoryDao.markWarehousesAsSynced([whId], 'BUS_A');
      final afterMark = await inventoryDao.getPendingSyncWarehouses('BUS_A');
      expect(afterMark.any((w) => w.id == whId), isFalse);

      final fetchedWh = await inventoryDao.getWarehouseById(whId, 'BUS_A');
      expect(fetchedWh!.syncStatus, equals('synced'));
    });
  });
}
