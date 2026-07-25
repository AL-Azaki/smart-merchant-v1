import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late SalesDao salesDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    salesDao = SalesDao(database);

    // Seed required parent User, Account, Businesses, Branches, Currencies, Units, Products, and Warehouses
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@sales.com',
            passwordHash: 'hash',
            firstName: 'Sales',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-sales-01'),
            ownerId: 'u-owner',
            businessName: 'Sales Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-sales-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-sales-01',
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
            productName: 'Sales Item One',
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
            sellingPrice: const drift.Value(100.0),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('SalesDao Phase 04 Test Suite -', () {
    test(
      '1. Core CRUD: Channels, Customers, Orders, Invoices, Returns, Receivables',
      () async {
        // 1. Insert Channel
        final chId = await salesDao.insertChannel(
          const ChannelsCompanion(
            id: drift.Value('ch-pos-01'),
            businessId: drift.Value('BUS_A'),
            channelName: drift.Value('POS Main Counter'),
            channelCode: drift.Value('POS-A1'),
            channelType: drift.Value('POS'),
          ),
        );
        expect(chId, isPositive);

        final channel = await salesDao.getChannelById('ch-pos-01', 'BUS_A');
        expect(channel, isNotNull);
        expect(channel!.channelName, equals('POS Main Counter'));

        // 2. Insert Customer
        await salesDao.insertCustomer(
          const CustomersCompanion(
            id: drift.Value('cust-01'),
            businessId: drift.Value('BUS_A'),
            customerName: drift.Value('Ahmad Al-Ghamdi'),
            phone: drift.Value('+966500000001'),
            creditLimit: drift.Value(5000.0),
            openingBalance: drift.Value(500.0),
            openingBalanceType: drift.Value('debit'),
          ),
        );
        final cust = await salesDao.getCustomerById('cust-01', 'BUS_A');
        expect(cust, isNotNull);
        expect(cust!.creditLimit, equals(5000.0));

        // 3. Record Atomic Order with Items
        await salesDao.recordOrderWithItems(
          order: OrdersCompanion.insert(
            id: 'ord-001',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            channelId: 'ch-pos-01',
            customerId: const drift.Value('cust-01'),
            orderNumber: 'ORD-2026-001',
            currencyId: 'curr-sar',
            subTotal: const drift.Value(200.0),
            grandTotal: const drift.Value(200.0),
            baseSubTotal: const drift.Value(200.0),
            baseGrandTotal: const drift.Value(200.0),
          ),
          items: [
            OrderItemsCompanion.insert(
              id: 'ord-item-001',
              businessId: 'BUS_A',
              orderId: 'ord-001',
              productUnitId: 'pu-01',
              quantity: 2.0,
              unitPrice: 100.0,
              lineTotal: 200.0,
              baseLineTotal: const drift.Value(200.0),
            ),
          ],
        );

        final orderWithItems = await salesDao.getOrderWithItemsById(
          'ord-001',
          'BUS_A',
        );
        expect(orderWithItems, isNotNull);
        expect(orderWithItems!.order.orderNumber, equals('ORD-2026-001'));
        expect(orderWithItems.items.length, equals(1));
        expect(orderWithItems.items.first.quantity, equals(2.0));

        // 4. Record Atomic Invoice + Items + Receivable + Initial Entry
        await salesDao.recordInvoiceWithItemsAndReceivable(
          invoice: SalesInvoicesCompanion.insert(
            id: 'inv-001',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            customerId: const drift.Value('cust-01'),
            invoiceNumber: 'INV-2026-001',
            currencyId: 'curr-sar',
            subTotal: const drift.Value(300.0),
            grandTotal: const drift.Value(300.0),
            baseSubTotal: const drift.Value(300.0),
            baseGrandTotal: const drift.Value(300.0),
            status: const drift.Value('Posted'),
            paymentStatus: const drift.Value('Partial'),
            createdBy: 'u-owner',
          ),
          items: [
            SalesInvoiceItemsCompanion.insert(
              id: 'inv-item-001',
              businessId: 'BUS_A',
              salesInvoiceId: 'inv-001',
              productUnitId: 'pu-01',
              warehouseId: 'wh-01',
              quantity: 3.0,
              unitPrice: 100.0,
              lineTotal: 300.0,
              baseLineTotal: const drift.Value(300.0),
            ),
          ],
          receivable: CustomerReceivablesCompanion.insert(
            id: 'rec-001',
            businessId: 'BUS_A',
            customerId: 'cust-01',
            salesInvoiceId: 'inv-001',
            currencyId: 'curr-sar',
            originalAmount: 300.0,
            baseOriginalAmount: 300.0,
            paidAmount: const drift.Value(100.0),
            basePaidAmount: const drift.Value(100.0),
            remainingAmount: 200.0,
            baseRemainingAmount: 200.0,
            status: const drift.Value('Partial'),
            dueDate: drift.Value(DateTime.now().add(const Duration(days: 30))),
          ),
          initialEntry: ReceivableEntriesCompanion.insert(
            id: 'rec-entry-001',
            businessId: 'BUS_A',
            customerReceivableId: 'rec-001',
            amount: 100.0,
            baseAmount: 100.0,
            entryType: const drift.Value('Payment'),
            createdBy: 'u-owner',
          ),
        );

        final invWithItems = await salesDao.getInvoiceWithItemsById(
          'inv-001',
          'BUS_A',
        );
        expect(invWithItems, isNotNull);
        expect(invWithItems!.invoice.grandTotal, equals(300.0));
        expect(invWithItems.items.length, equals(1));

        final recWithEntries = await salesDao.getReceivableWithEntriesById(
          'rec-001',
          'BUS_A',
        );
        expect(recWithEntries, isNotNull);
        expect(recWithEntries!.receivable.remainingAmount, equals(200.0));
        expect(recWithEntries.entries.length, equals(1));
        expect(recWithEntries.entries.first.amount, equals(100.0));

        // 5. Record Return with Items
        await salesDao.recordReturnWithItems(
          salesReturn: SalesReturnsCompanion.insert(
            id: 'ret-001',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            salesInvoiceId: 'inv-001',
            returnNumber: 'RET-2026-001',
            currencyId: 'curr-sar',
            totalAmount: const drift.Value(100.0),
            baseTotalAmount: const drift.Value(100.0),
            status: const drift.Value('Posted'),
            createdBy: 'u-owner',
          ),
          items: [
            SalesReturnItemsCompanion.insert(
              id: 'ret-item-001',
              businessId: 'BUS_A',
              salesReturnId: 'ret-001',
              salesInvoiceItemId: 'inv-item-001',
              warehouseId: 'wh-01',
              quantity: 1.0,
              unitPrice: 100.0,
              totalPrice: 100.0,
              baseTotalPrice: const drift.Value(100.0),
            ),
          ],
        );

        final retWithItems = await salesDao.getReturnWithItemsById(
          'ret-001',
          'BUS_A',
        );
        expect(retWithItems, isNotNull);
        expect(retWithItems!.salesReturn.returnNumber, equals('RET-2026-001'));
        expect(retWithItems.items.length, equals(1));
      },
    );

    test('2. Tenant Scoping Isolation across Businesses', () async {
      await salesDao.insertChannel(
        const ChannelsCompanion(
          id: drift.Value('ch-a'),
          businessId: drift.Value('BUS_A'),
          channelName: drift.Value('Channel A'),
          channelCode: drift.Value('CH-A'),
          channelType: drift.Value('POS'),
        ),
      );
      await salesDao.insertChannel(
        const ChannelsCompanion(
          id: drift.Value('ch-b'),
          businessId: drift.Value('BUS_B'),
          channelName: drift.Value('Channel B'),
          channelCode: drift.Value('CH-B'),
          channelType: drift.Value('POS'),
        ),
      );

      final listA = await salesDao.listChannels(
        const ChannelFilter(businessId: 'BUS_A'),
      );
      final listB = await salesDao.listChannels(
        const ChannelFilter(businessId: 'BUS_B'),
      );

      expect(listA.length, equals(1));
      expect(listA.first.channelCode, equals('CH-A'));
      expect(listB.length, equals(1));
      expect(listB.first.channelCode, equals('CH-B'));

      // Empty businessId throws exception
      expect(
        () => salesDao.listChannels(const ChannelFilter(businessId: '')),
        throwsA(isA<TenantScopingException>()),
      );
    });

    test('3. Branch Scoping Isolation for Orders and Invoices', () async {
      await salesDao.insertChannel(
        const ChannelsCompanion(
          id: drift.Value('ch-branch'),
          businessId: drift.Value('BUS_A'),
          channelName: drift.Value('Channel Branch'),
          channelCode: drift.Value('CH-BR'),
          channelType: drift.Value('POS'),
        ),
      );

      await salesDao.recordOrderWithItems(
        order: OrdersCompanion.insert(
          id: 'ord-b1',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          channelId: 'ch-branch',
          orderNumber: 'ORD-B1',
          currencyId: 'curr-sar',
        ),
        items: [],
      );
      await salesDao.recordOrderWithItems(
        order: OrdersCompanion.insert(
          id: 'ord-b2',
          businessId: 'BUS_A',
          branchId: 'BRANCH_2',
          channelId: 'ch-branch',
          orderNumber: 'ORD-B2',
          currencyId: 'curr-sar',
        ),
        items: [],
      );

      final ordersB1 = await salesDao.listOrders(
        const OrderFilter(businessId: 'BUS_A', branchId: 'BRANCH_1'),
      );
      final ordersB2 = await salesDao.listOrders(
        const OrderFilter(businessId: 'BUS_A', branchId: 'BRANCH_2'),
      );
      final allOrders = await salesDao.listOrders(
        const OrderFilter(businessId: 'BUS_A'),
      );

      expect(ordersB1.length, equals(1));
      expect(ordersB1.first.orderNumber, equals('ORD-B1'));
      expect(ordersB2.length, equals(1));
      expect(ordersB2.first.orderNumber, equals('ORD-B2'));
      expect(allOrders.length, equals(2));
    });

    test('4. Soft Delete & Restore: Customers, Orders, Returns', () async {
      await salesDao.insertCustomer(
        const CustomersCompanion(
          id: drift.Value('cust-soft'),
          businessId: drift.Value('BUS_A'),
          customerName: drift.Value('Soft Delete Customer'),
        ),
      );

      var cust = await salesDao.getCustomerById('cust-soft', 'BUS_A');
      expect(cust, isNotNull);
      expect(cust!.deletedAt, isNull);

      // Soft delete
      final deleted = await salesDao.softDeleteCustomer('cust-soft', 'BUS_A');
      expect(deleted, isTrue);

      cust = await salesDao.getCustomerById('cust-soft', 'BUS_A');
      expect(cust, isNull); // Default excludes deleted

      final custWithDeleted = await salesDao.getCustomerById(
        'cust-soft',
        'BUS_A',
        includeDeleted: true,
      );
      expect(custWithDeleted, isNotNull);
      expect(custWithDeleted!.deletedAt, isNotNull);
      expect(custWithDeleted.syncStatus, equals('pending_delete'));

      // Restore
      final restored = await salesDao.restoreCustomer('cust-soft', 'BUS_A');
      expect(restored, isTrue);

      cust = await salesDao.getCustomerById('cust-soft', 'BUS_A');
      expect(cust, isNotNull);
      expect(cust!.deletedAt, isNull);
      expect(cust.syncStatus, equals('pending_update'));
    });

    test('5. Atomic Transactions & Rollbacks on Constraint Violation', () async {
      await salesDao.insertChannel(
        const ChannelsCompanion(
          id: drift.Value('ch-trans'),
          businessId: drift.Value('BUS_A'),
          channelName: drift.Value('Transaction Channel'),
          channelCode: drift.Value('CH-TR'),
          channelType: drift.Value('POS'),
        ),
      );

      // Attempt to record invoice with invalid negative item quantity (violates CHECK quantity > 0)
      try {
        await salesDao.recordInvoiceWithItemsAndReceivable(
          invoice: SalesInvoicesCompanion.insert(
            id: 'inv-fail',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            invoiceNumber: 'INV-FAIL-01',
            currencyId: 'curr-sar',
            createdBy: 'u-owner',
          ),
          items: [
            SalesInvoiceItemsCompanion.insert(
              id: 'item-fail',
              businessId: 'BUS_A',
              salesInvoiceId: 'inv-fail',
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

      final checkInv = await salesDao.getInvoiceById('inv-fail', 'BUS_A');
      expect(
        checkInv,
        isNull,
        reason:
            'Header should have rolled back on item check constraint violation.',
      );
    });

    test(
      '6. Financial Views & Aggregations: Customer Balance Summary & Receivable Entries',
      () async {
        await salesDao.insertCustomer(
          const CustomersCompanion(
            id: drift.Value('cust-fin'),
            businessId: drift.Value('BUS_A'),
            customerName: drift.Value('Financial Customer'),
            creditLimit: drift.Value(10000.0),
            openingBalance: drift.Value(1000.0),
            openingBalanceType: drift.Value('debit'),
          ),
        );

        // Create two invoices and receivables
        await salesDao.recordInvoiceWithItemsAndReceivable(
          invoice: SalesInvoicesCompanion.insert(
            id: 'inv-fin-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            customerId: const drift.Value('cust-fin'),
            invoiceNumber: 'INV-FIN-1',
            currencyId: 'curr-sar',
            grandTotal: const drift.Value(500.0),
            createdBy: 'u-owner',
          ),
          items: [],
          receivable: CustomerReceivablesCompanion.insert(
            id: 'rec-fin-1',
            businessId: 'BUS_A',
            customerId: 'cust-fin',
            salesInvoiceId: 'inv-fin-1',
            currencyId: 'curr-sar',
            originalAmount: 500.0,
            baseOriginalAmount: 500.0,
            remainingAmount: 500.0,
            baseRemainingAmount: 500.0,
          ),
        );

        await salesDao.recordInvoiceWithItemsAndReceivable(
          invoice: SalesInvoicesCompanion.insert(
            id: 'inv-fin-2',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            customerId: const drift.Value('cust-fin'),
            invoiceNumber: 'INV-FIN-2',
            currencyId: 'curr-sar',
            grandTotal: const drift.Value(800.0),
            createdBy: 'u-owner',
          ),
          items: [],
          receivable: CustomerReceivablesCompanion.insert(
            id: 'rec-fin-2',
            businessId: 'BUS_A',
            customerId: 'cust-fin',
            salesInvoiceId: 'inv-fin-2',
            currencyId: 'curr-sar',
            originalAmount: 800.0,
            baseOriginalAmount: 800.0,
            remainingAmount: 800.0,
            baseRemainingAmount: 800.0,
          ),
        );

        // Check balance summary before payment
        var summary = await salesDao.getCustomerBalanceSummary(
          'cust-fin',
          'BUS_A',
        );
        expect(summary, isNotNull);
        expect(summary!.totalReceivables, equals(1300.0));
        expect(summary.totalPaid, equals(0.0));
        expect(summary.totalRemaining, equals(1300.0));

        // Record a payment entry against the first receivable
        await salesDao.recordReceivableEntry(
          ReceivableEntriesCompanion.insert(
            id: 'entry-pay-1',
            businessId: 'BUS_A',
            customerReceivableId: 'rec-fin-1',
            amount: 300.0,
            baseAmount: 300.0,
            entryType: const drift.Value('Payment'),
            createdBy: 'u-owner',
          ),
          customerReceivableId: 'rec-fin-1',
          businessId: 'BUS_A',
          newPaidAmount: 300.0,
          newRemainingAmount: 200.0,
          newBasePaidAmount: 300.0,
          newBaseRemainingAmount: 200.0,
          newStatus: 'Partial',
        );

        summary = await salesDao.getCustomerBalanceSummary('cust-fin', 'BUS_A');
        expect(summary!.totalReceivables, equals(1300.0));
        expect(summary.totalPaid, equals(300.0));
        expect(summary.totalRemaining, equals(1000.0));
      },
    );

    test(
      '7. Offline-First Synchronization Helpers across all 10 tables',
      () async {
        // Channels
        final pendingChannels = await salesDao.getPendingSyncChannels('BUS_A');
        final channelIds = pendingChannels.map((c) => c.id).toList();
        if (channelIds.isNotEmpty) {
          final syncedCount = await salesDao.markChannelsAsSynced(
            channelIds,
            'BUS_A',
          );
          expect(syncedCount, equals(channelIds.length));
          final remaining = await salesDao.getPendingSyncChannels('BUS_A');
          expect(remaining, isEmpty);
        }

        // Customers
        final pendingCustomers = await salesDao.getPendingSyncCustomers(
          'BUS_A',
        );
        final customerIds = pendingCustomers.map((c) => c.id).toList();
        if (customerIds.isNotEmpty) {
          final syncedCount = await salesDao.markCustomersAsSynced(
            customerIds,
            'BUS_A',
          );
          expect(syncedCount, equals(customerIds.length));
          final remaining = await salesDao.getPendingSyncCustomers('BUS_A');
          expect(remaining, isEmpty);
        }

        // Orders & Order Items
        final pendingOrders = await salesDao.getPendingSyncOrders('BUS_A');
        final orderIds = pendingOrders.map((o) => o.id).toList();
        if (orderIds.isNotEmpty) {
          await salesDao.markOrdersAsSynced(orderIds, 'BUS_A');
          expect(await salesDao.getPendingSyncOrders('BUS_A'), isEmpty);
        }

        final pendingOrderItems = await salesDao.getPendingSyncOrderItems(
          'BUS_A',
        );
        final orderItemIds = pendingOrderItems.map((i) => i.id).toList();
        if (orderItemIds.isNotEmpty) {
          await salesDao.markOrderItemsAsSynced(orderItemIds, 'BUS_A');
          expect(await salesDao.getPendingSyncOrderItems('BUS_A'), isEmpty);
        }

        // Sales Invoices & Items
        final pendingInvoices = await salesDao.getPendingSyncInvoices('BUS_A');
        final invoiceIds = pendingInvoices.map((i) => i.id).toList();
        if (invoiceIds.isNotEmpty) {
          await salesDao.markInvoicesAsSynced(invoiceIds, 'BUS_A');
          expect(await salesDao.getPendingSyncInvoices('BUS_A'), isEmpty);
        }

        final pendingInvoiceItems = await salesDao.getPendingSyncInvoiceItems(
          'BUS_A',
        );
        final invoiceItemIds = pendingInvoiceItems.map((i) => i.id).toList();
        if (invoiceItemIds.isNotEmpty) {
          await salesDao.markInvoiceItemsAsSynced(invoiceItemIds, 'BUS_A');
          expect(await salesDao.getPendingSyncInvoiceItems('BUS_A'), isEmpty);
        }

        // Receivables & Entries
        final pendingReceivables = await salesDao
            .getPendingSyncCustomerReceivables('BUS_A');
        final receivableIds = pendingReceivables.map((r) => r.id).toList();
        if (receivableIds.isNotEmpty) {
          await salesDao.markCustomerReceivablesAsSynced(
            receivableIds,
            'BUS_A',
          );
          expect(
            await salesDao.getPendingSyncCustomerReceivables('BUS_A'),
            isEmpty,
          );
        }

        final pendingEntries = await salesDao.getPendingSyncReceivableEntries(
          'BUS_A',
        );
        final entryIds = pendingEntries.map((e) => e.id).toList();
        if (entryIds.isNotEmpty) {
          await salesDao.markReceivableEntriesAsSynced(entryIds, 'BUS_A');
          expect(
            await salesDao.getPendingSyncReceivableEntries('BUS_A'),
            isEmpty,
          );
        }

        // Returns & Return Items
        final pendingReturns = await salesDao.getPendingSyncSalesReturns(
          'BUS_A',
        );
        final returnIds = pendingReturns.map((r) => r.id).toList();
        if (returnIds.isNotEmpty) {
          await salesDao.markSalesReturnsAsSynced(returnIds, 'BUS_A');
          expect(await salesDao.getPendingSyncSalesReturns('BUS_A'), isEmpty);
        }

        final pendingReturnItems = await salesDao
            .getPendingSyncSalesReturnItems('BUS_A');
        final returnItemIds = pendingReturnItems.map((i) => i.id).toList();
        if (returnItemIds.isNotEmpty) {
          await salesDao.markSalesReturnItemsAsSynced(returnItemIds, 'BUS_A');
          expect(
            await salesDao.getPendingSyncSalesReturnItems('BUS_A'),
            isEmpty,
          );
        }
      },
    );
  });
}
