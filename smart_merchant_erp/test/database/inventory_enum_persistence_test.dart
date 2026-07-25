import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_type.dart';
import 'package:smart_merchant_erp/database/enums/inventory_movement_direction.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transaction_status.dart';
import 'package:smart_merchant_erp/database/enums/inventory_reference_type.dart';
import 'package:smart_merchant_erp/database/enums/inventory_transfer_status.dart';
import 'package:smart_merchant_erp/database/converters/inventory_transaction_type_converter.dart';
import 'package:smart_merchant_erp/database/converters/inventory_movement_direction_converter.dart';
import 'package:smart_merchant_erp/database/converters/inventory_transaction_status_converter.dart';
import 'package:smart_merchant_erp/database/converters/inventory_reference_type_converter.dart';
import 'package:smart_merchant_erp/database/converters/inventory_transfer_status_converter.dart';

/// Permanent Regression & Round-Trip Verification Suite for Inventory Enums.
///
/// Verifies alignment between:
/// 1. Dart Enums & Drift TypeConverters (`lib/database/enums/`, `lib/database/converters/`)
/// 2. SQLite CHECK Constraints (`inventory_transactions_table.dart`, `inventory_transfers_table.dart`)
/// 3. Authoritative SQLite Enums Specification (`docs/sqlite_schema/SQLite_Enums_Specification.md`)
void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());

    // Verify foreign keys are enabled
    final result = await database
        .customSelect('PRAGMA foreign_keys;')
        .getSingle();
    expect(
      result.data.values.first,
      equals(1),
      reason: 'Foreign keys must be active',
    );

    // Insert required parent entities to satisfy FK constraints during inventory inserts
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('user-setup-01'),
            email: 'admin@merchant.com',
            passwordHash: 'hashed_pw',
            firstName: 'System',
            lastName: 'Admin',
          ),
        );

    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-setup-01'),
            ownerId: 'user-setup-01',
            businessName: 'Admin Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );

    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'biz-setup-01',
            accountId: 'acc-setup-01',
            businessName: 'Smart Merchant Test Biz',
          ),
        );

    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'branch-setup-01',
            businessId: 'biz-setup-01',
            branchName: 'Main Branch',
            branchCode: 'BR-01',
          ),
        );

    await database
        .into(database.warehouses)
        .insert(
          WarehousesCompanion.insert(
            id: 'wh-setup-01',
            businessId: 'biz-setup-01',
            branchId: 'branch-setup-01',
            warehouseName: 'Main Warehouse',
            warehouseCode: 'WH-01',
          ),
        );

    await database
        .into(database.warehouses)
        .insert(
          WarehousesCompanion.insert(
            id: 'wh-setup-02',
            businessId: 'biz-setup-01',
            branchId: 'branch-setup-01',
            warehouseName: 'Secondary Warehouse',
            warehouseCode: 'WH-02',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('1. TypeConverter Round-Trip Verification (`toSql` / `fromSql`) -', () {
    test(
      'InventoryTransactionTypeConverter round-trips all canonical values',
      () {
        const converter = InventoryTransactionTypeConverter();
        const expectedMapping = {
          InventoryTransactionType.receipt: 'Receipt',
          InventoryTransactionType.dispatch: 'Dispatch',
          InventoryTransactionType.adjustmentIn: 'Adjustment In',
          InventoryTransactionType.adjustmentOut: 'Adjustment Out',
          InventoryTransactionType.openingBalance: 'Opening Balance',
        };

        for (final entry in expectedMapping.entries) {
          final toSqlResult = converter.toSql(entry.key);
          expect(toSqlResult, equals(entry.value));
          final fromSqlResult = converter.fromSql(entry.value);
          expect(fromSqlResult, equals(entry.key));
        }
      },
    );

    test(
      'InventoryMovementDirectionConverter round-trips all canonical values',
      () {
        const converter = InventoryMovementDirectionConverter();
        const expectedMapping = {
          InventoryMovementDirection.inbound: 'IN',
          InventoryMovementDirection.outbound: 'OUT',
        };

        for (final entry in expectedMapping.entries) {
          final toSqlResult = converter.toSql(entry.key);
          expect(toSqlResult, equals(entry.value));
          final fromSqlResult = converter.fromSql(entry.value);
          expect(fromSqlResult, equals(entry.key));
        }
      },
    );

    test(
      'InventoryTransactionStatusConverter round-trips all canonical values',
      () {
        const converter = InventoryTransactionStatusConverter();
        const expectedMapping = {
          InventoryTransactionStatus.draft: 'Draft',
          InventoryTransactionStatus.posted: 'Posted',
          InventoryTransactionStatus.reversed: 'Reversed',
        };

        for (final entry in expectedMapping.entries) {
          final toSqlResult = converter.toSql(entry.key);
          expect(toSqlResult, equals(entry.value));
          final fromSqlResult = converter.fromSql(entry.value);
          expect(fromSqlResult, equals(entry.key));
        }
      },
    );

    test(
      'InventoryReferenceTypeConverter round-trips all canonical values',
      () {
        const converter = InventoryReferenceTypeConverter();
        const expectedMapping = {
          InventoryReferenceType.salesInvoice: 'SalesInvoice',
          InventoryReferenceType.salesReturn: 'SalesReturn',
          InventoryReferenceType.purchaseInvoice: 'PurchaseInvoice',
          InventoryReferenceType.purchaseReturn: 'PurchaseReturn',
          InventoryReferenceType.transfer: 'Transfer',
          InventoryReferenceType.adjustment: 'Adjustment',
        };

        for (final entry in expectedMapping.entries) {
          final toSqlResult = converter.toSql(entry.key);
          expect(toSqlResult, equals(entry.value));
          final fromSqlResult = converter.fromSql(entry.value);
          expect(fromSqlResult, equals(entry.key));
        }
      },
    );

    test(
      'InventoryTransferStatusConverter round-trips all canonical values',
      () {
        const converter = InventoryTransferStatusConverter();
        const expectedMapping = {
          InventoryTransferStatus.pending: 'Pending',
          InventoryTransferStatus.completed: 'Completed',
          InventoryTransferStatus.cancelled: 'Cancelled',
        };

        for (final entry in expectedMapping.entries) {
          final toSqlResult = converter.toSql(entry.key);
          expect(toSqlResult, equals(entry.value));
          final fromSqlResult = converter.fromSql(entry.value);
          expect(fromSqlResult, equals(entry.key));
        }
      },
    );
  });

  group('2. SQLite Database INSERT Verification (Zero CHECK Constraint Failures) -', () {
    test(
      'Every InventoryTransactionType value inserts cleanly into inventory_transactions',
      () async {
        int idx = 1;
        for (final txType in InventoryTransactionType.values) {
          final id = 'tx-type-test-$idx';
          await database
              .into(database.inventoryTransactions)
              .insert(
                InventoryTransactionsCompanion.insert(
                  id: id,
                  businessId: 'biz-setup-01',
                  branchId: 'branch-setup-01',
                  warehouseId: 'wh-setup-01',
                  transactionType: txType,
                  movementDirection: InventoryMovementDirection.inbound,
                  status: drift.Value(InventoryTransactionStatus.draft),
                  createdBy: 'user-setup-01',
                ),
              );

          final fetched = await (database.select(
            database.inventoryTransactions,
          )..where((tbl) => tbl.id.equals(id))).getSingle();
          expect(fetched.transactionType, equals(txType));
          idx++;
        }
      },
    );

    test(
      'Every InventoryMovementDirection value inserts cleanly into inventory_transactions',
      () async {
        int idx = 1;
        for (final direction in InventoryMovementDirection.values) {
          final id = 'tx-dir-test-$idx';
          await database
              .into(database.inventoryTransactions)
              .insert(
                InventoryTransactionsCompanion.insert(
                  id: id,
                  businessId: 'biz-setup-01',
                  branchId: 'branch-setup-01',
                  warehouseId: 'wh-setup-01',
                  transactionType: InventoryTransactionType.receipt,
                  movementDirection: direction,
                  status: drift.Value(InventoryTransactionStatus.draft),
                  createdBy: 'user-setup-01',
                ),
              );

          final fetched = await (database.select(
            database.inventoryTransactions,
          )..where((tbl) => tbl.id.equals(id))).getSingle();
          expect(fetched.movementDirection, equals(direction));
          idx++;
        }
      },
    );

    test(
      'Every InventoryTransactionStatus value inserts cleanly into inventory_transactions',
      () async {
        int idx = 1;
        for (final status in InventoryTransactionStatus.values) {
          final id = 'tx-status-test-$idx';
          await database
              .into(database.inventoryTransactions)
              .insert(
                InventoryTransactionsCompanion.insert(
                  id: id,
                  businessId: 'biz-setup-01',
                  branchId: 'branch-setup-01',
                  warehouseId: 'wh-setup-01',
                  transactionType: InventoryTransactionType.receipt,
                  movementDirection: InventoryMovementDirection.inbound,
                  status: drift.Value(status),
                  createdBy: 'user-setup-01',
                ),
              );

          final fetched = await (database.select(
            database.inventoryTransactions,
          )..where((tbl) => tbl.id.equals(id))).getSingle();
          expect(fetched.status, equals(status));
          idx++;
        }
      },
    );

    test(
      'Every InventoryReferenceType value (plus null) inserts cleanly into inventory_transactions',
      () async {
        int idx = 1;
        final refTypes = [...InventoryReferenceType.values, null];
        for (final refType in refTypes) {
          final id = 'tx-ref-test-$idx';
          await database
              .into(database.inventoryTransactions)
              .insert(
                InventoryTransactionsCompanion.insert(
                  id: id,
                  businessId: 'biz-setup-01',
                  branchId: 'branch-setup-01',
                  warehouseId: 'wh-setup-01',
                  transactionType: InventoryTransactionType.receipt,
                  movementDirection: InventoryMovementDirection.inbound,
                  status: drift.Value(InventoryTransactionStatus.draft),
                  referenceType: drift.Value(refType),
                  createdBy: 'user-setup-01',
                ),
              );

          final fetched = await (database.select(
            database.inventoryTransactions,
          )..where((tbl) => tbl.id.equals(id))).getSingle();
          expect(fetched.referenceType, equals(refType));
          idx++;
        }
      },
    );

    test(
      'Every InventoryTransferStatus value inserts cleanly into inventory_transfers',
      () async {
        int idx = 1;
        for (final status in InventoryTransferStatus.values) {
          final id = 'tr-status-test-$idx';
          await database
              .into(database.inventoryTransfers)
              .insert(
                InventoryTransfersCompanion.insert(
                  id: id,
                  businessId: 'biz-setup-01',
                  fromWarehouseId: 'wh-setup-01',
                  toWarehouseId: 'wh-setup-02',
                  transferNumber: 'TR-00$idx',
                  status: drift.Value(status),
                  createdBy: 'user-setup-01',
                ),
              );

          final fetched = await (database.select(
            database.inventoryTransfers,
          )..where((tbl) => tbl.id.equals(id))).getSingle();
          expect(fetched.status, equals(status));
          idx++;
        }
      },
    );
  });

  group(
    '3. Negative Verification (CHECK Constraints MUST Reject Invalid Strings) -',
    () {
      test(
        'Invalid transaction_type string throws CHECK constraint failed',
        () async {
          expect(
            () async => await database.customInsert(
              'INSERT INTO inventory_transactions (id, business_id, branch_id, warehouse_id, transaction_type, movement_direction, status, created_by, transaction_date) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
              variables: [
                drift.Variable.withString('invalid-tx-type'),
                drift.Variable.withString('biz-setup-01'),
                drift.Variable.withString('branch-setup-01'),
                drift.Variable.withString('wh-setup-01'),
                drift.Variable.withString(
                  'InvalidTransactionType',
                ), // Invalid value
                drift.Variable.withString('IN'),
                drift.Variable.withString('Draft'),
                drift.Variable.withString('user-setup-01'),
              ],
            ),
            throwsA(
              isA<sqlite.SqliteException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains('check constraint failed'),
              ),
            ),
          );
        },
      );

      test(
        'Invalid movement_direction string throws CHECK constraint failed',
        () async {
          expect(
            () async => await database.customInsert(
              'INSERT INTO inventory_transactions (id, business_id, branch_id, warehouse_id, transaction_type, movement_direction, status, created_by, transaction_date) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
              variables: [
                drift.Variable.withString('invalid-dir'),
                drift.Variable.withString('biz-setup-01'),
                drift.Variable.withString('branch-setup-01'),
                drift.Variable.withString('wh-setup-01'),
                drift.Variable.withString('Receipt'),
                drift.Variable.withString('SIDEWAYS'), // Invalid value
                drift.Variable.withString('Draft'),
                drift.Variable.withString('user-setup-01'),
              ],
            ),
            throwsA(
              isA<sqlite.SqliteException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains('check constraint failed'),
              ),
            ),
          );
        },
      );

      test(
        'Invalid inventory_transactions.status string throws CHECK constraint failed',
        () async {
          expect(
            () async => await database.customInsert(
              'INSERT INTO inventory_transactions (id, business_id, branch_id, warehouse_id, transaction_type, movement_direction, status, created_by, transaction_date) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
              variables: [
                drift.Variable.withString('invalid-status-tx'),
                drift.Variable.withString('biz-setup-01'),
                drift.Variable.withString('branch-setup-01'),
                drift.Variable.withString('wh-setup-01'),
                drift.Variable.withString('Receipt'),
                drift.Variable.withString('IN'),
                drift.Variable.withString(
                  'completed',
                ), // Old/invalid lowercase value
                drift.Variable.withString('user-setup-01'),
              ],
            ),
            throwsA(
              isA<sqlite.SqliteException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains('check constraint failed'),
              ),
            ),
          );
        },
      );

      test(
        'Invalid reference_type string throws CHECK constraint failed',
        () async {
          expect(
            () async => await database.customInsert(
              'INSERT INTO inventory_transactions (id, business_id, branch_id, warehouse_id, transaction_type, movement_direction, status, reference_type, created_by, transaction_date) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
              variables: [
                drift.Variable.withString('invalid-ref'),
                drift.Variable.withString('biz-setup-01'),
                drift.Variable.withString('branch-setup-01'),
                drift.Variable.withString('wh-setup-01'),
                drift.Variable.withString('Receipt'),
                drift.Variable.withString('IN'),
                drift.Variable.withString('Draft'),
                drift.Variable.withString('InvalidReference'), // Invalid value
                drift.Variable.withString('user-setup-01'),
              ],
            ),
            throwsA(
              isA<sqlite.SqliteException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains('check constraint failed'),
              ),
            ),
          );
        },
      );

      test(
        'Invalid inventory_transfers.status string throws CHECK constraint failed',
        () async {
          expect(
            () async => await database.customInsert(
              'INSERT INTO inventory_transfers (id, business_id, from_warehouse_id, to_warehouse_id, transfer_number, status, created_by, transfer_date) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)',
              variables: [
                drift.Variable.withString('invalid-status-tr'),
                drift.Variable.withString('biz-setup-01'),
                drift.Variable.withString('wh-setup-01'),
                drift.Variable.withString('wh-setup-02'),
                drift.Variable.withString('TR-INV'),
                drift.Variable.withString(
                  'inTransit',
                ), // Old/invalid camelCase value
                drift.Variable.withString('user-setup-01'),
              ],
            ),
            throwsA(
              isA<sqlite.SqliteException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains('check constraint failed'),
              ),
            ),
          );
        },
      );
    },
  );
}
