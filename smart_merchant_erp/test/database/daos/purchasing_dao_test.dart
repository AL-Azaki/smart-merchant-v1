import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late PurchasingDao purchasingDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    purchasingDao = PurchasingDao(database);

    // Seed required parent User, Account, Businesses, Branches, Currencies, Units, Products, and Warehouses
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@purchasing.com',
            passwordHash: 'hash',
            firstName: 'Purchasing',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-purchasing-01'),
            ownerId: 'u-owner',
            businessName: 'Purchasing Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-purchasing-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-purchasing-01',
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
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_B1',
            businessId: 'BUS_B',
            branchName: 'Beta Main Branch',
            branchCode: 'BR-B1',
          ),
        );

    await database
        .into(database.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: 'curr-sar',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'SAR',
            decimalPlaces: const drift.Value(2),
            exchangeRate: const drift.Value(1.0),
            isBaseCurrency: const drift.Value(true),
          ),
        );

    await database
        .into(database.warehouses)
        .insert(
          WarehousesCompanion.insert(
            id: 'wh-01',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            warehouseName: 'Main Warehouse Alpha',
            warehouseCode: 'WH-A1',
            isDefault: const drift.Value(true),
          ),
        );

    await database
        .into(database.units)
        .insert(
          UnitsCompanion.insert(
            id: 'unit-pcs',
            businessId: 'BUS_A',
            unitName: 'Pieces',
            unitSymbol: 'PCS',
          ),
        );
    await database
        .into(database.products)
        .insert(
          ProductsCompanion.insert(
            id: 'prod-01',
            businessId: 'BUS_A',
            productCode: 'PRD-01',
            productName: 'Purchased Item One',
          ),
        );
    await database
        .into(database.productUnits)
        .insert(
          ProductUnitsCompanion.insert(
            id: 'pu-01',
            businessId: 'BUS_A',
            productId: 'prod-01',
            unitId: 'unit-pcs',
            isBaseUnit: const drift.Value(true),
            sellingPrice: const drift.Value(150.0),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('PurchasingDao Phase 05 Test Suite -', () {
    test(
      '1. Core CRUD: Suppliers, Invoices, Payables, Entries, Returns',
      () async {
        // 1. Insert Supplier
        final supId = await purchasingDao.insertSupplier(
          const SuppliersCompanion(
            id: drift.Value('sup-01'),
            businessId: drift.Value('BUS_A'),
            supplierName: drift.Value('Global Supplies Co.'),
            contactPerson: drift.Value('Tariq Al-Harbi'),
            phone: drift.Value('+966500000011'),
            creditLimit: drift.Value(50000.0),
            openingBalance: drift.Value(1000.0),
            openingBalanceType: drift.Value('credit'),
          ),
        );
        expect(supId, isPositive);

        final sup = await purchasingDao.getSupplierById('sup-01', 'BUS_A');
        expect(sup, isNotNull);
        expect(sup!.supplierName, equals('Global Supplies Co.'));

        // 2. Record Atomic Purchase Invoice + Items + Supplier Payable + Initial Entry
        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-001',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            supplierId: 'sup-01',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-2026-001',
            currencyId: 'curr-sar',
            subTotal: const drift.Value(1000.0),
            grandTotal: const drift.Value(1000.0),
            baseSubTotal: const drift.Value(1000.0),
            baseGrandTotal: const drift.Value(1000.0),
            status: const drift.Value('Posted'),
            paymentStatus: const drift.Value('Partial'),
            createdBy: 'u-owner',
          ),
          items: [
            PurchaseInvoiceItemsCompanion.insert(
              id: 'pinv-item-001',
              businessId: 'BUS_A',
              purchaseInvoiceId: 'pinv-001',
              productUnitId: 'pu-01',
              warehouseId: 'wh-01',
              quantity: 10.0,
              unitPrice: 100.0,
              lineTotal: 1000.0,
              baseLineTotal: const drift.Value(1000.0),
            ),
          ],
          payable: SupplierPayablesCompanion.insert(
            id: 'spay-001',
            businessId: 'BUS_A',
            supplierId: 'sup-01',
            purchaseInvoiceId: 'pinv-001',
            currencyId: 'curr-sar',
            originalAmount: 1000.0,
            baseOriginalAmount: 1000.0,
            paidAmount: const drift.Value(200.0),
            basePaidAmount: const drift.Value(200.0),
            remainingAmount: 800.0,
            baseRemainingAmount: 800.0,
            status: const drift.Value('Partial'),
            dueDate: drift.Value(DateTime.now().add(const Duration(days: 30))),
          ),
          initialEntry: PayableEntriesCompanion.insert(
            id: 'spay-entry-001',
            businessId: 'BUS_A',
            supplierPayableId: 'spay-001',
            amount: 200.0,
            baseAmount: 200.0,
            entryType: const drift.Value('Payment'),
            createdBy: 'u-owner',
          ),
        );

        final invWithItems = await purchasingDao.getInvoiceWithItemsById(
          'pinv-001',
          'BUS_A',
        );
        expect(invWithItems, isNotNull);
        expect(invWithItems!.invoice.grandTotal, equals(1000.0));
        expect(invWithItems.items.length, equals(1));
        expect(invWithItems.items.first.quantity, equals(10.0));

        final payWithEntries = await purchasingDao.getPayableWithEntriesById(
          'spay-001',
          'BUS_A',
        );
        expect(payWithEntries, isNotNull);
        expect(payWithEntries!.payable.remainingAmount, equals(800.0));
        expect(payWithEntries.entries.length, equals(1));
        expect(payWithEntries.entries.first.amount, equals(200.0));

        // 3. Record Purchase Return with Items
        await purchasingDao.recordReturnWithItems(
          purchaseReturn: PurchaseReturnsCompanion.insert(
            id: 'pret-001',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            purchaseInvoiceId: 'pinv-001',
            returnNumber: 'PRET-2026-001',
            currencyId: 'curr-sar',
            totalAmount: const drift.Value(100.0),
            baseTotalAmount: const drift.Value(100.0),
            status: const drift.Value('Posted'),
            createdBy: 'u-owner',
          ),
          items: [
            PurchaseReturnItemsCompanion.insert(
              id: 'pret-item-001',
              businessId: 'BUS_A',
              purchaseReturnId: 'pret-001',
              purchaseInvoiceItemId: 'pinv-item-001',
              warehouseId: 'wh-01',
              quantity: 1.0,
              unitPrice: 100.0,
              lineTotal: 100.0,
              baseLineTotal: const drift.Value(100.0),
            ),
          ],
        );

        final retWithItems = await purchasingDao.getReturnWithItemsById(
          'pret-001',
          'BUS_A',
        );
        expect(retWithItems, isNotNull);
        expect(
          retWithItems!.purchaseReturn.returnNumber,
          equals('PRET-2026-001'),
        );
        expect(retWithItems.items.length, equals(1));
      },
    );

    test('2. Tenant Scoping Isolation across Businesses', () async {
      await purchasingDao.insertSupplier(
        const SuppliersCompanion(
          id: drift.Value('sup-a'),
          businessId: drift.Value('BUS_A'),
          supplierName: drift.Value('Supplier Alpha'),
        ),
      );
      await purchasingDao.insertSupplier(
        const SuppliersCompanion(
          id: drift.Value('sup-b'),
          businessId: drift.Value('BUS_B'),
          supplierName: drift.Value('Supplier Beta'),
        ),
      );

      final listA = await purchasingDao.listSuppliers(
        const SupplierFilter(businessId: 'BUS_A'),
      );
      final listB = await purchasingDao.listSuppliers(
        const SupplierFilter(businessId: 'BUS_B'),
      );

      expect(listA.length, equals(1));
      expect(listA.first.supplierName, equals('Supplier Alpha'));
      expect(listB.length, equals(1));
      expect(listB.first.supplierName, equals('Supplier Beta'));

      // Empty businessId throws exception
      expect(
        () => purchasingDao.listSuppliers(const SupplierFilter(businessId: '')),
        throwsA(isA<TenantScopingException>()),
      );
    });

    test(
      '3. Branch Scoping Isolation for Purchase Invoices and Returns',
      () async {
        await purchasingDao.insertSupplier(
          const SuppliersCompanion(
            id: drift.Value('sup-br'),
            businessId: drift.Value('BUS_A'),
            supplierName: drift.Value('Branch Supplier'),
          ),
        );

        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-b1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            supplierId: 'sup-br',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-B1',
            currencyId: 'curr-sar',
            createdBy: 'u-owner',
          ),
          items: [],
        );
        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-b2',
            businessId: 'BUS_A',
            branchId: 'BRANCH_2',
            supplierId: 'sup-br',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-B2',
            currencyId: 'curr-sar',
            createdBy: 'u-owner',
          ),
          items: [],
        );

        final invB1 = await purchasingDao.listInvoices(
          const PurchaseInvoiceFilter(
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
          ),
        );
        final invB2 = await purchasingDao.listInvoices(
          const PurchaseInvoiceFilter(
            businessId: 'BUS_A',
            branchId: 'BRANCH_2',
          ),
        );
        final allInv = await purchasingDao.listInvoices(
          const PurchaseInvoiceFilter(businessId: 'BUS_A'),
        );

        expect(invB1.length, equals(1));
        expect(invB1.first.invoiceNumber, equals('PINV-B1'));
        expect(invB2.length, equals(1));
        expect(invB2.first.invoiceNumber, equals('PINV-B2'));
        expect(allInv.length, equals(2));
      },
    );

    test('4. Soft Delete & Restore: Suppliers and Purchase Returns', () async {
      await purchasingDao.insertSupplier(
        const SuppliersCompanion(
          id: drift.Value('sup-soft'),
          businessId: drift.Value('BUS_A'),
          supplierName: drift.Value('Soft Delete Supplier'),
        ),
      );

      var sup = await purchasingDao.getSupplierById('sup-soft', 'BUS_A');
      expect(sup, isNotNull);
      expect(sup!.deletedAt, isNull);

      // Soft delete
      final deleted = await purchasingDao.softDeleteSupplier(
        'sup-soft',
        'BUS_A',
      );
      expect(deleted, isTrue);

      sup = await purchasingDao.getSupplierById('sup-soft', 'BUS_A');
      expect(sup, isNull); // Default excludes deleted

      final supWithDeleted = await purchasingDao.getSupplierById(
        'sup-soft',
        'BUS_A',
        includeDeleted: true,
      );
      expect(supWithDeleted, isNotNull);
      expect(supWithDeleted!.deletedAt, isNotNull);
      expect(supWithDeleted.syncStatus, equals('pending_delete'));

      // Restore
      final restored = await purchasingDao.restoreSupplier('sup-soft', 'BUS_A');
      expect(restored, isTrue);

      sup = await purchasingDao.getSupplierById('sup-soft', 'BUS_A');
      expect(sup, isNotNull);
      expect(sup!.deletedAt, isNull);
      expect(sup.syncStatus, equals('pending_update'));
    });

    test('5. Atomic Transactions & Rollbacks on Constraint Violation', () async {
      await purchasingDao.insertSupplier(
        const SuppliersCompanion(
          id: drift.Value('sup-trans'),
          businessId: drift.Value('BUS_A'),
          supplierName: drift.Value('Transaction Supplier'),
        ),
      );

      // Attempt to record invoice with invalid negative quantity (violates CHECK quantity > 0)
      try {
        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-fail',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            supplierId: 'sup-trans',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-FAIL-01',
            currencyId: 'curr-sar',
            createdBy: 'u-owner',
          ),
          items: [
            PurchaseInvoiceItemsCompanion.insert(
              id: 'pitem-fail',
              businessId: 'BUS_A',
              purchaseInvoiceId: 'pinv-fail',
              productUnitId: 'pu-01',
              warehouseId: 'wh-01',
              quantity: -5.0, // Violates CHECK (quantity > 0)
              unitPrice: 100.0,
              lineTotal: -500.0,
            ),
          ],
        );
        fail('Should have thrown check constraint exception');
      } catch (e) {
        // Transaction rolled back
      }

      final checkInv = await purchasingDao.getInvoiceById('pinv-fail', 'BUS_A');
      expect(
        checkInv,
        isNull,
        reason:
            'Header should have rolled back on item check constraint violation.',
      );
    });

    test(
      '6. Financial Views & Aggregations: Supplier Balance Summary & Payable Entries',
      () async {
        await purchasingDao.insertSupplier(
          const SuppliersCompanion(
            id: drift.Value('sup-fin'),
            businessId: drift.Value('BUS_A'),
            supplierName: drift.Value('Financial Supplier'),
            creditLimit: drift.Value(20000.0),
            openingBalance: drift.Value(2000.0),
            openingBalanceType: drift.Value('credit'),
          ),
        );

        // Create two invoices and payables
        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-fin-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            supplierId: 'sup-fin',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-FIN-1',
            currencyId: 'curr-sar',
            grandTotal: const drift.Value(1000.0),
            createdBy: 'u-owner',
          ),
          items: [],
          payable: SupplierPayablesCompanion.insert(
            id: 'spay-fin-1',
            businessId: 'BUS_A',
            supplierId: 'sup-fin',
            purchaseInvoiceId: 'pinv-fin-1',
            currencyId: 'curr-sar',
            originalAmount: 1000.0,
            baseOriginalAmount: 1000.0,
            remainingAmount: 1000.0,
            baseRemainingAmount: 1000.0,
          ),
        );

        await purchasingDao.recordInvoiceWithItemsAndPayable(
          invoice: PurchaseInvoicesCompanion.insert(
            id: 'pinv-fin-2',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            supplierId: 'sup-fin',
            warehouseId: 'wh-01',
            invoiceNumber: 'PINV-FIN-2',
            currencyId: 'curr-sar',
            grandTotal: const drift.Value(1500.0),
            createdBy: 'u-owner',
          ),
          items: [],
          payable: SupplierPayablesCompanion.insert(
            id: 'spay-fin-2',
            businessId: 'BUS_A',
            supplierId: 'sup-fin',
            purchaseInvoiceId: 'pinv-fin-2',
            currencyId: 'curr-sar',
            originalAmount: 1500.0,
            baseOriginalAmount: 1500.0,
            remainingAmount: 1500.0,
            baseRemainingAmount: 1500.0,
          ),
        );

        // Check balance summary before payment
        var summary = await purchasingDao.getSupplierBalanceSummary(
          'sup-fin',
          'BUS_A',
        );
        expect(summary, isNotNull);
        expect(summary!.totalPayables, equals(2500.0));
        expect(summary.totalPaid, equals(0.0));
        expect(summary.totalRemaining, equals(2500.0));

        // Record a payment entry against the first payable
        await purchasingDao.recordPayableEntry(
          entry: PayableEntriesCompanion.insert(
            id: 'spay-entry-pay-1',
            businessId: 'BUS_A',
            supplierPayableId: 'spay-fin-1',
            amount: 600.0,
            baseAmount: 600.0,
            entryType: const drift.Value('Payment'),
            createdBy: 'u-owner',
          ),
          supplierPayableId: 'spay-fin-1',
          businessId: 'BUS_A',
        );

        summary = await purchasingDao.getSupplierBalanceSummary(
          'sup-fin',
          'BUS_A',
        );
        expect(summary!.totalPayables, equals(2500.0));
        expect(summary.totalPaid, equals(600.0));
        expect(summary.totalRemaining, equals(1900.0));
      },
    );

    test(
      '7. Offline-First Synchronization Helpers across all 7 purchasing tables',
      () async {
        // Suppliers
        final pendingSuppliers = await purchasingDao.getPendingSyncSuppliers(
          'BUS_A',
        );
        final supplierIds = pendingSuppliers.map((s) => s.id).toList();
        if (supplierIds.isNotEmpty) {
          final syncedCount = await purchasingDao.markSuppliersAsSynced(
            supplierIds,
            'BUS_A',
          );
          expect(syncedCount, equals(supplierIds.length));
          final remaining = await purchasingDao.getPendingSyncSuppliers(
            'BUS_A',
          );
          expect(remaining, isEmpty);
        }

        // Purchase Invoices & Items
        final pendingInvoices = await purchasingDao.getPendingSyncInvoices(
          'BUS_A',
        );
        final invoiceIds = pendingInvoices.map((i) => i.id).toList();
        if (invoiceIds.isNotEmpty) {
          await purchasingDao.markInvoicesAsSynced(invoiceIds, 'BUS_A');
          expect(await purchasingDao.getPendingSyncInvoices('BUS_A'), isEmpty);
        }

        final pendingInvoiceItems = await purchasingDao
            .getPendingSyncInvoiceItems('BUS_A');
        final invoiceItemIds = pendingInvoiceItems.map((i) => i.id).toList();
        if (invoiceItemIds.isNotEmpty) {
          await purchasingDao.markInvoiceItemsAsSynced(invoiceItemIds, 'BUS_A');
          expect(
            await purchasingDao.getPendingSyncInvoiceItems('BUS_A'),
            isEmpty,
          );
        }

        // Supplier Payables & Entries
        final pendingPayables = await purchasingDao.getPendingSyncPayables(
          'BUS_A',
        );
        final payableIds = pendingPayables.map((p) => p.id).toList();
        if (payableIds.isNotEmpty) {
          await purchasingDao.markPayablesAsSynced(payableIds, 'BUS_A');
          expect(await purchasingDao.getPendingSyncPayables('BUS_A'), isEmpty);
        }

        final pendingEntries = await purchasingDao.getPendingSyncPayableEntries(
          'BUS_A',
        );
        final entryIds = pendingEntries.map((e) => e.id).toList();
        if (entryIds.isNotEmpty) {
          await purchasingDao.markPayableEntriesAsSynced(entryIds, 'BUS_A');
          expect(
            await purchasingDao.getPendingSyncPayableEntries('BUS_A'),
            isEmpty,
          );
        }

        // Purchase Returns & Items
        final pendingReturns = await purchasingDao.getPendingSyncReturns(
          'BUS_A',
        );
        final returnIds = pendingReturns.map((r) => r.id).toList();
        if (returnIds.isNotEmpty) {
          await purchasingDao.markReturnsAsSynced(returnIds, 'BUS_A');
          expect(await purchasingDao.getPendingSyncReturns('BUS_A'), isEmpty);
        }

        final pendingReturnItems = await purchasingDao
            .getPendingSyncReturnItems('BUS_A');
        final returnItemIds = pendingReturnItems.map((i) => i.id).toList();
        if (returnItemIds.isNotEmpty) {
          await purchasingDao.markReturnItemsAsSynced(returnItemIds, 'BUS_A');
          expect(
            await purchasingDao.getPendingSyncReturnItems('BUS_A'),
            isEmpty,
          );
        }
      },
    );
  });
}
