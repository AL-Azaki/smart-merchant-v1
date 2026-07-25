import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/kernel/error/repository_exceptions.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_type.dart';
import 'package:smart_merchant_erp/database/enums/inventory_movement_direction.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_status.dart';

void main() {
  late AppDatabase db;
  late InventoryDao dao;
  late InventoryRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    dao = InventoryDao(db);
    repository = InventoryRepositoryImpl(dao);

    // Seed parent user, account, business, and branch for foreign key constraints
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-1'),
            email: 'owner@smartmerchant.com',
            passwordHash: 'hash',
            firstName: 'Owner',
            lastName: 'User',
          ),
        );
    await db
        .into(db.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-1'),
            ownerId: 'u-1',
            businessName: 'Smart Store',
            businessType: 'Retail',
            defaultCurrency: 'YER',
          ),
        );
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'biz-1',
            accountId: 'acc-1',
            businessName: 'Smart Merchant Corp',
          ),
        );
    await db
        .into(db.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'branch-1',
            businessId: 'biz-1',
            branchCode: 'MAIN',
            branchName: 'Main HQ',
            isDefault: const drift.Value(true),
          ),
        );

    // Seed product catalog dependencies for stock/transaction tests
    await db
        .into(db.units)
        .insert(
          UnitsCompanion.insert(
            id: 'unit-1',
            businessId: 'biz-1',
            unitName: 'Piece',
            unitSymbol: 'PC',
          ),
        );
    await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            id: 'prod-1',
            businessId: 'biz-1',
            productCode: 'P001',
            productName: 'Sample Product',
          ),
        );
    await db
        .into(db.productUnits)
        .insert(
          ProductUnitsCompanion.insert(
            id: 'pu-1',
            businessId: 'biz-1',
            productId: 'prod-1',
            unitId: 'unit-1',
            isBaseUnit: const drift.Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('InventoryRepository Unit Suite', () {
    test('1. Warehouse and Stock Balance (Inventory) Operations', () async {
      await repository.insertWarehouse(
        WarehousesCompanion.insert(
          id: 'wh-1',
          businessId: 'biz-1',
          branchId: 'branch-1',
          warehouseName: 'Main Warehouse',
          warehouseCode: 'WH-MAIN',
          isDefault: const drift.Value(true),
        ),
      );
      final wh = await repository.getDefaultWarehouseByBranch(
        'biz-1',
        'branch-1',
      );
      expect(wh?.warehouseCode, 'WH-MAIN');

      await repository.insertInventory(
        InventoriesCompanion.insert(
          id: 'inv-1',
          businessId: 'biz-1',
          warehouseId: 'wh-1',
          productUnitId: 'pu-1',
          quantity: const drift.Value(50.0),
          averageCost: const drift.Value(10.0),
        ),
      );
      final stock = await repository.getInventoryByUnitAndWarehouse(
        'biz-1',
        'wh-1',
        'pu-1',
      );
      expect(stock?.quantity, 50.0);
      expect(stock?.averageCost, 10.0);
    });

    test('2. Transactional Recording of Stock Movements (Receipt)', () async {
      await repository.insertWarehouse(
        WarehousesCompanion.insert(
          id: 'wh-1',
          businessId: 'biz-1',
          branchId: 'branch-1',
          warehouseName: 'Main Warehouse',
          warehouseCode: 'WH-MAIN',
        ),
      );

      await repository.recordTransactionWithLines(
        transaction: InventoryTransactionsCompanion.insert(
          id: 'txn-1',
          businessId: 'biz-1',
          branchId: 'branch-1',
          warehouseId: 'wh-1',
          transactionType: InventoryTransactionType.receipt,
          movementDirection: InventoryMovementDirection.inbound,
          status: const drift.Value(InventoryTransactionStatus.posted),
          createdBy: 'u-1',
        ),
        lines: [
          InventoryTransactionLinesCompanion.insert(
            id: 'txnl-1',
            businessId: 'biz-1',
            inventoryTransactionId: 'txn-1',
            productUnitId: 'pu-1',
            quantity: 20.0,
            unitCost: const drift.Value(15.0),
          ),
        ],
      );

      final txn = await repository.getTransactionById('txn-1', 'biz-1');
      expect(txn?.transactionType, InventoryTransactionType.receipt);
      expect(txn?.movementDirection, InventoryMovementDirection.inbound);

      final lines = await repository.listTransactionLines('txn-1', 'biz-1');
      expect(lines.length, 1);
      expect(lines.first.quantity, 20.0);
      expect(lines.first.unitCost, 15.0);
    });

    test(
      '3. RepositoryErrorGuard intercepting TenantScopingException',
      () async {
        expect(
          () => repository.insertWarehouse(
            WarehousesCompanion.insert(
              id: 'wh-invalid',
              businessId: '', // Invalid empty businessId
              branchId: 'branch-1',
              warehouseName: 'Invalid WH',
              warehouseCode: 'ERR',
            ),
          ),
          throwsA(
            isA<RepositoryTenantScopeException>().having(
              (e) => e.toFailure(),
              'toFailure',
              isA<TenantScopeFailure>(),
            ),
          ),
        );
      },
    );
  });
}
