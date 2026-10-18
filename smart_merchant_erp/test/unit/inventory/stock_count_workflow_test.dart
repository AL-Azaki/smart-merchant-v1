import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/enums/stock_count_status.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/usecases/post_journal_entry_usecase.dart';
import 'package:smart_merchant_erp/modules/inventory/application/services/stock_count_workflow.dart';
import 'package:smart_merchant_erp/modules/inventory/application/usecases/save_stock_count_usecase.dart';
import 'package:smart_merchant_erp/modules/inventory/application/usecases/process_warehouse_transfer_usecase.dart';

class InventoryTestFixture {
  late AppDatabase db;
  late StockCountWorkflow workflow;
  late ProcessWarehouseTransferUseCase transfer;
  Future<void> open({d.QueryExecutor? connection}) async {
    db = AppDatabase(connection: connection ?? NativeDatabase.memory());
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const d.Value('user'),
            email: 'inventory@example.test',
            passwordHash: 'hash',
            firstName: 'اختبار',
            lastName: 'المخزن',
          ),
        );
    await db
        .into(db.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const d.Value('account'),
            ownerId: 'user',
            businessName: 'اختبار',
            businessType: 'Retail',
            defaultCurrency: 'YER',
          ),
        );
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'biz',
            accountId: 'account',
            businessName: 'متجر',
          ),
        );
    await db
        .into(db.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'branch',
            businessId: 'biz',
            branchCode: 'B',
            branchName: 'فرع',
          ),
        );
    for (final id in ['wh', 'target']) {
      await db
          .into(db.warehouses)
          .insert(
            WarehousesCompanion.insert(
              id: id,
              businessId: 'biz',
              branchId: 'branch',
              warehouseName: id,
              warehouseCode: id,
            ),
          );
    }
    await db
        .into(db.units)
        .insert(
          UnitsCompanion.insert(
            id: 'piece',
            businessId: 'biz',
            unitName: 'حبة',
            unitSymbol: 'pc',
          ),
        );
    for (final entry in [
      ('a', 20.0, 10.0),
      ('b', 30.0, 20.0),
      ('c', 0.0, 5.0),
    ]) {
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: entry.$1,
              businessId: 'biz',
              productCode: entry.$1,
              productName: 'منتج ${entry.$1}',
            ),
          );
      await db
          .into(db.productUnits)
          .insert(
            ProductUnitsCompanion.insert(
              id: 'u${entry.$1}',
              businessId: 'biz',
              productId: entry.$1,
              unitId: 'piece',
              purchasePrice: d.Value(entry.$3),
              isBaseUnit: const d.Value(true),
            ),
          );
      if (entry.$2 > 0) {
        await db
            .into(db.inventories)
            .insert(
              InventoriesCompanion.insert(
                id: entry.$1,
                businessId: 'biz',
                warehouseId: 'wh',
                productUnitId: 'u${entry.$1}',
                quantity: d.Value(entry.$2),
                averageCost: d.Value(entry.$3),
              ),
            );
      }
    }
    for (final type in [(1, 'Assets'), (4, 'Revenue'), (5, 'Expenses')]) {
      await db
          .into(db.accountTypes)
          .insert(
            AccountTypesCompanion.insert(
              id: d.Value(type.$1),
              nameEn: type.$2,
              nameAr: type.$2,
              slug: type.$2,
            ),
          );
    }
    for (final a in [
      ('asset', '1', 1, false, null),
      ('inv', '101', 1, true, 'asset'),
      ('expense', '5', 5, false, null),
      ('loss', '501', 5, true, 'expense'),
      ('revenue', '4', 4, false, null),
      ('gain', '401', 4, true, 'revenue'),
    ]) {
      await db
          .into(db.chartOfAccounts)
          .insert(
            ChartOfAccountsCompanion.insert(
              id: a.$1,
              businessId: 'biz',
              accountCode: a.$2,
              accountName: a.$1,
              accountTypeId: a.$3,
              normalBalance: a.$3 == 4 ? 'Credit' : 'Debit',
              parentAccountId: d.Value(a.$5),
              allowPosting: d.Value(a.$4),
              accountLevel: d.Value(a.$5 == null ? 1 : 2),
            ),
          );
    }
    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: 'inventory-map',
            businessId: 'biz',
            mappingKey: 'inventory_asset',
            mappingName: 'المخزون',
            chartOfAccountId: 'inv',
          ),
        );
    final year = DateTime.now().year;
    await db
        .into(db.fiscalYears)
        .insert(
          FiscalYearsCompanion.insert(
            id: 'year',
            businessId: 'biz',
            fiscalYearCode: '$year',
            fiscalYearName: '$year',
            startDate: DateTime(year),
            endDate: DateTime(year, 12, 31),
          ),
        );
    await db
        .into(db.fiscalPeriods)
        .insert(
          FiscalPeriodsCompanion.insert(
            id: 'period',
            businessId: 'biz',
            fiscalYearId: 'year',
            periodNumber: 1,
            periodName: 'السنة',
            startDate: DateTime(year),
            endDate: DateTime(year, 12, 31),
          ),
        );
    const context = StaticApplicationContext(
      businessId: 'biz',
      branchId: 'branch',
      userId: 'user',
    );
    final accounting = AccountingRepositoryImpl(AccountingDao(db)),
        runner = ApplicationTransactionRunnerImpl(db);
    workflow = StockCountWorkflow(
      db,
      context,
      AccountingApplicationService(accounting, context),
      PostJournalEntryUseCase(
        accounting,
        CoreRepositoryImpl(CoreDao(db)),
        context,
        runner,
      ),
    );
    transfer = ProcessWarehouseTransferUseCase(
      InventoryRepositoryImpl(InventoryDao(db)),
      context,
      runner,
      db,
    );
  }

  SaveStockCountItemCommand line(String id, double expected, double physical) =>
      SaveStockCountItemCommand(
        productId: id,
        productUnitId: 'u$id',
        expectedQuantity: expected,
        countedQuantity: physical,
        differenceQuantity: 999,
      );
  Future<String> save(List<SaveStockCountItemCommand> lines) =>
      workflow.save(SaveStockCountCommand(warehouseId: 'wh', items: lines));
  Future<double> quantity(String unit, [String warehouse = 'wh']) async =>
      (await (db.select(db.inventories)..where(
                (i) =>
                    i.productUnitId.equals(unit) &
                    i.warehouseId.equals(warehouse),
              ))
              .getSingleOrNull())
          ?.quantity ??
      0;
  Future<void> balanced() async {
    for (final entry in await db.select(db.journalEntries).get()) {
      final lines = await (db.select(
        db.journalEntryLines,
      )..where((l) => l.journalEntryId.equals(entry.id))).get();
      final debit = lines
              .where((l) => l.type == 'Debit')
              .fold(0.0, (v, l) => v + l.baseAmount),
          credit = lines
              .where((l) => l.type == 'Credit')
              .fold(0.0, (v, l) => v + l.baseAmount);
      expect(debit, closeTo(credit, .00001));
      expect(debit, greaterThan(0));
    }
  }
}

void main() {
  late InventoryTestFixture f;
  setUp(() async {
    f = InventoryTestFixture();
    await f.open();
  });
  tearDown(() async {
    await f.db.close();
  });
  test(
    'Version five migration preserves historical counts without inventing financial coverage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'inventory-migration-',
      );
      final file = File('${directory.path}/inventory.sqlite');
      final old = InventoryTestFixture();
      await old.open(connection: NativeDatabase(file));
      await old.db
          .into(old.db.stockCounts)
          .insert(
            StockCountsCompanion.insert(
              id: 'legacy',
              businessId: 'biz',
              branchId: 'branch',
              warehouseId: 'wh',
              countNumber: 'OLD-1',
              createdBy: 'user',
              status: const d.Value(StockCountStatus.posted),
            ),
          );
      await old.db
          .into(old.db.stockCountItems)
          .insert(
            StockCountItemsCompanion.insert(
              id: 'legacy-line',
              businessId: 'biz',
              stockCountId: 'legacy',
              productId: 'a',
              productUnitId: 'ua',
              expectedQuantity: 20,
              countedQuantity: 15,
              differenceQuantity: -5,
            ),
          );
      for (final column in [
        'financial_status',
        'financial_journal_id',
        'settlement_journal_id',
        'financial_settled_at',
      ]) {
        await old.db.customStatement(
          'ALTER TABLE stock_counts DROP COLUMN $column',
        );
      }
      await old.db.customStatement(
        'ALTER TABLE stock_count_items DROP COLUMN unit_cost',
      );
      await old.db.customStatement('PRAGMA user_version = 5');
      await old.db.close();
      final upgraded = AppDatabase(connection: NativeDatabase(file));
      try {
        final count = await (upgraded.select(
          upgraded.stockCounts,
        )..where((c) => c.id.equals('legacy'))).getSingle();
        expect(count.status, StockCountStatus.posted);
        expect(count.financialStatus, 'Legacy');
        expect(count.financialJournalId, isNull);
        final line = await upgraded
            .select(upgraded.stockCountItems)
            .getSingle();
        expect(line.countedQuantity, 15);
        expect(line.unitCost, 0);
        expect(await upgraded.select(upgraded.journalEntries).get(), isEmpty);
        expect(await upgraded.select(upgraded.products).get(), hasLength(3));
      } finally {
        await upgraded.close();
        await file.delete();
        await directory.delete();
      }
    },
  );

  test('Cancelled drafts remain auditable and cannot move inventory', () async {
    final id = await f.save([f.line('a', 20, 15)]);
    await f.workflow.cancelDraft(id);
    final doc = await f.workflow.load(id);
    expect(doc.count.status, StockCountStatus.cancelled);
    expect(doc.items, hasLength(1));
    expect(await f.quantity('ua'), 20);
    await expectLater(
      f.workflow.correct(id),
      throwsA(isA<InventoryWorkflowException>()),
    );
    expect(await f.db.select(f.db.journalEntries).get(), isEmpty);
  });
  test(
    'Allocation uses the frozen correction cost after subsequent purchases',
    () async {
      final id = await f.save([f.line('a', 20, 15)]);
      await f.workflow.correct(id);
      await (f.db.update(f.db.inventories)..where((i) => i.id.equals('a')))
          .write(const InventoriesCompanion(averageCost: d.Value(999)));
      await f.workflow.settle(id, lossAccountId: 'loss');
      final lines = await (f.db.select(
        f.db.journalEntryLines,
      )..where((l) => l.chartOfAccountId.equals('loss'))).get();
      expect(lines.single.baseAmount, 50);
      await expectLater(
        f.workflow.cancelDraft(id),
        throwsA(isA<InventoryWorkflowException>()),
      );
    },
  );
  test('Closed year blocks correction even if a period remains open', () async {
    final id = await f.save([f.line('a', 20, 15)]);
    await f.db
        .update(f.db.fiscalYears)
        .write(const FiscalYearsCompanion(status: d.Value('Closed')));
    await expectLater(
      f.workflow.correct(id),
      throwsA(isA<InventoryWorkflowException>()),
    );
    expect(await f.quantity('ua'), 20);
  });
  test(
    'Counts from another branch or business cannot be opened or posted',
    () async {
      final id = await f.save([f.line('a', 20, 15)]);
      for (final context in [
        const StaticApplicationContext(
          businessId: 'other',
          branchId: 'branch',
          userId: 'user',
        ),
        const StaticApplicationContext(
          businessId: 'biz',
          branchId: 'other',
          userId: 'user',
        ),
      ]) {
        final scoped = StockCountWorkflow(
          f.db,
          context,
          f.workflow.accounts,
          f.workflow.postJournal,
        );
        await expectLater(
          scoped.load(id),
          throwsA(isA<InventoryWorkflowException>()),
        );
        await expectLater(
          scoped.correct(id),
          throwsA(isA<InventoryWorkflowException>()),
        );
        expect(await scoped.watchCounts().first, isEmpty);
      }
    },
  );

  test(
    'Two shortages correct stock once, hold gross value, then settle losses without moving stock',
    () async {
      final id = await f.save([f.line('a', 20, 15), f.line('b', 30, 25)]);
      expect(await f.quantity('ua'), 20);
      expect(await f.db.select(f.db.journalEntries).get(), isEmpty);
      expect((await f.workflow.load(id)).shortage, 150);
      await f.workflow.correct(id);
      final doc = await f.workflow.load(id);
      expect(doc.count.financialStatus, 'Pending');
      expect(doc.count.financialJournalId, isNotNull);
      expect(doc.shortage, 150);
      expect(await f.quantity('ua'), 15);
      expect(await f.quantity('ub'), 25);
      expect(
        (await f.db.select(f.db.inventoryTransactionLines).get()).map(
          (l) => l.quantity,
        ),
        [5, 5],
      );
      expect(
        (await f.db.select(f.db.journalEntryLines).get()).any(
          (l) => l.chartOfAccountId == 'loss',
        ),
        isFalse,
      );
      await f.workflow.settle(id, lossAccountId: 'loss');
      expect((await f.workflow.load(id)).count.financialStatus, 'Settled');
      expect(await f.quantity('ua'), 15);
      await expectLater(
        f.workflow.correct(id),
        throwsA(isA<InventoryWorkflowException>()),
      );
      await expectLater(
        f.workflow.settle(id, lossAccountId: 'loss'),
        throwsA(isA<InventoryWorkflowException>()),
      );
      expect(await f.db.select(f.db.journalEntries).get(), hasLength(2));
      await f.balanced();
    },
  );
  test(
    'Equal quantity surplus and shortage remain separate at their own costs',
    () async {
      final id = await f.save([f.line('a', 20, 25), f.line('b', 30, 25)]);
      await f.workflow.correct(id);
      final doc = await f.workflow.load(id);
      expect(doc.shortage, 100);
      expect(doc.surplus, 50);
      expect(await f.db.select(f.db.journalEntryLines).get(), hasLength(4));
      await f.workflow.settle(id, lossAccountId: 'loss', gainAccountId: 'gain');
      await f.balanced();
    },
  );
  test(
    'Employee allocation creates a receivable, never a salary deduction',
    () async {
      await f.db
          .into(f.db.employees)
          .insert(
            EmployeesCompanion.insert(
              id: 'employee',
              businessId: 'biz',
              employeeCode: 'E1',
              firstName: 'أحمد',
              lastName: 'علي',
              hireDate: DateTime(2026),
              currencyId: 'YER',
            ),
          );
      final id = await f.save([f.line('a', 20, 15)]);
      await f.workflow.correct(id);
      await f.workflow.settle(id, employeeId: 'employee');
      final mapping =
          await (f.db.select(f.db.accountMappings)..where(
                (m) => m.mappingKey.equals('stock_count_employee_employee'),
              ))
              .getSingle();
      final employeeAccount = await (f.db.select(
        f.db.chartOfAccounts,
      )..where((a) => a.id.equals(mapping.chartOfAccountId))).getSingle();
      expect(employeeAccount.accountTypeId, 1);
      expect(employeeAccount.accountName, contains('أحمد'));
      expect(await f.db.select(f.db.cashTransactions).get(), isEmpty);
      await f.balanced();
    },
  );
  test('Stale stock aborts all quantities, movements and journals', () async {
    final id = await f.save([f.line('a', 20, 15), f.line('b', 30, 25)]);
    await (f.db.update(f.db.inventories)..where((i) => i.id.equals('b'))).write(
      const InventoriesCompanion(quantity: d.Value(29)),
    );
    await expectLater(
      f.workflow.correct(id),
      throwsA(isA<InventoryWorkflowException>()),
    );
    expect(await f.quantity('ua'), 20);
    expect(await f.quantity('ub'), 29);
    expect(await f.db.select(f.db.inventoryTransactions).get(), isEmpty);
    expect(await f.db.select(f.db.journalEntries).get(), isEmpty);
    expect((await f.workflow.load(id)).count.status, StockCountStatus.draft);
  });
  test(
    'Closed financial period rolls back temporary account and correction',
    () async {
      final id = await f.save([f.line('a', 20, 15)]);
      await f.db
          .update(f.db.fiscalPeriods)
          .write(const FiscalPeriodsCompanion(status: d.Value('Closed')));
      await expectLater(
        f.workflow.correct(id),
        throwsA(isA<InventoryWorkflowException>()),
      );
      expect(await f.quantity('ua'), 20);
      expect(await f.db.select(f.db.inventoryTransactions).get(), isEmpty);
      expect(
        (await f.db.select(f.db.accountMappings).get()).any(
          (m) => m.mappingKey == 'stock_count_clearing',
        ),
        isFalse,
      );
    },
  );
  test(
    'Explicit zero, unstocked products and zero-difference counts are handled',
    () async {
      final id = await f.save([f.line('a', 20, 0), f.line('c', 0, 7)]);
      await f.workflow.correct(id);
      expect(await f.quantity('ua'), 0);
      expect(await f.quantity('uc'), 7);
      expect((await f.workflow.load(id)).surplus, 35);
      final same = await f.save([f.line('b', 30, 30)]);
      await f.workflow.correct(same);
      expect(
        (await f.workflow.load(same)).count.financialStatus,
        'NotRequired',
      );
      expect(await f.db.select(f.db.journalEntries).get(), hasLength(1));
      await f.balanced();
    },
  );
  test('Repeated concurrent approval commits only one correction', () async {
    final id = await f.save([f.line('a', 20, 15)]);
    final results = await Future.wait([
      for (var i = 0; i < 2; i++)
        f.workflow
            .correct(id)
            .then((_) => true)
            .catchError((Object _) => false),
    ]);
    expect(results.where((v) => v), hasLength(1));
    expect(await f.quantity('ua'), 15);
    expect(await f.db.select(f.db.journalEntries).get(), hasLength(1));
  });
  test(
    'Invalid quantities and duplicate or foreign units cannot create drafts',
    () async {
      for (final lines in [
        [f.line('a', 20, -1)],
        [f.line('a', 20, double.nan)],
        [f.line('a', 20, 15), f.line('a', 20, 15)],
        [f.line('foreign', 20, 15)],
      ]) {
        await expectLater(
          f.save(lines),
          throwsA(isA<InventoryWorkflowException>()),
        );
      }
      expect(await f.db.select(f.db.stockCounts).get(), isEmpty);
    },
  );
  test(
    'Draft updates retain the number, clear notes and recompute differences',
    () async {
      final id = await f.save([f.line('a', 20, 15)]),
          number = (await f.workflow.load(id)).count.countNumber;
      await f.workflow.save(
        SaveStockCountCommand(
          id: id,
          warehouseId: 'wh',
          items: [f.line('a', 20, 17)],
        ),
      );
      final doc = await f.workflow.load(id);
      expect(doc.count.countNumber, number);
      expect(doc.items.single.differenceQuantity, -3);
    },
  );
  test(
    'Transfers change both balances and preserve weighted inventory cost',
    () async {
      await f.db
          .into(f.db.inventories)
          .insert(
            InventoriesCompanion.insert(
              id: 'target-stock',
              businessId: 'biz',
              warehouseId: 'target',
              productUnitId: 'ua',
              quantity: const d.Value(10),
              averageCost: const d.Value(20),
            ),
          );
      final result = await f.transfer(
        const ProcessWarehouseTransferCommand(
          sourceWarehouseId: 'wh',
          destinationWarehouseId: 'target',
          items: [
            WarehouseTransferItemCommand(productUnitId: 'ua', quantity: 5),
          ],
        ),
      );
      expect(result.isRight(), isTrue);
      expect(await f.quantity('ua'), 15);
      expect(await f.quantity('ua', 'target'), 15);
      final stock = await (f.db.select(
        f.db.inventories,
      )..where((s) => s.id.equals('target-stock'))).getSingle();
      expect(stock.averageCost, closeTo(250 / 15, .00001));
      final lines = await f.db.select(f.db.inventoryTransactionLines).get();
      expect(lines, hasLength(2));
      expect(lines.every((l) => l.unitCost == 10 && l.quantity == 5), isTrue);
    },
  );
  test(
    'Invalid transfer never moves partial stock or creates documents',
    () async {
      final result = await f.transfer(
        const ProcessWarehouseTransferCommand(
          sourceWarehouseId: 'wh',
          destinationWarehouseId: 'target',
          items: [
            WarehouseTransferItemCommand(productUnitId: 'ua', quantity: 5),
            WarehouseTransferItemCommand(productUnitId: 'ub', quantity: 999),
          ],
        ),
      );
      expect(result.isLeft(), isTrue);
      expect(await f.quantity('ua'), 20);
      expect(await f.quantity('ua', 'target'), 0);
      expect(await f.db.select(f.db.inventoryTransfers).get(), isEmpty);
    },
  );
}
