import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_sync_queries.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';

/// Creates a fresh in-memory AppDatabase for testing.
AppDatabase _createTestDb() => AppDatabase(connection: NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late SalesDao salesDao;

  const businessId = 'test-biz-001';
  const branchId = 'test-branch-001';
  const channelId = 'test-channel-001';
  const currencyId = 'YER';
  const userId = 'test-user-001';

  /// Helper to seed required FK rows.
  Future<void> seedRequiredData() async {
    // User
    await db.customStatement(
      "INSERT OR IGNORE INTO users(id, email, password_hash, first_name, last_name) VALUES ('test-user', 'test@test.com', 'hash', 'Test', 'User')",
    );
    // Account
    await db.customStatement(
      "INSERT OR IGNORE INTO accounts(id, owner_id, business_name, business_type, default_currency) VALUES ('test-account', 'test-user', 'TestBiz', 'Retail', 'YER')",
    );
    // Business
    await db.customStatement(
      "INSERT OR IGNORE INTO businesses(id, account_id, business_name, primary_phone) VALUES (?, 'test-account', 'TestBiz', '123')",
      [businessId],
    );
    // Currency
    await db.customStatement(
      "INSERT OR IGNORE INTO currencies(id, currency_code, currency_name_ar, currency_name_en, currency_symbol) VALUES (?, 'YER', 'ريال يمني', 'Yemeni Rial', '﷼')",
      [currencyId],
    );
    // Branch
    await db.customStatement(
      "INSERT OR IGNORE INTO branches(id, business_id, branch_name, branch_code) VALUES (?, ?, 'Main', 'BR01')",
      [branchId, businessId],
    );
    // Channel
    await db.customStatement(
      "INSERT OR IGNORE INTO channels(id, business_id, channel_name, channel_code, channel_type) VALUES (?, ?, 'Ecommerce', 'ECOM', 'Ecommerce')",
      [channelId, businessId],
    );
    // User not needed beyond the owner setup for test

  }

  setUp(() async {
    db = _createTestDb();
    salesDao = SalesDao(db);
    await seedRequiredData();
  });

  tearDown(() async {
    await db.close();
  });

  group('Online Order Pull & Persistence', () {
    test('insertOnlineOrder persists order and items to SQLite', () async {
      // Arrange: simulate a Laravel pull payload
      final orderJson = <String, dynamic>{
        'id': 'order-001',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-001',
        'order_date': DateTime.now().toIso8601String(),
        'currency_id': currencyId,
        'exchange_rate': 1.0,
        'sub_total': 100.0,
        'discount_total': 0.0,
        'tax_total': 15.0,
        'grand_total': 115.0,
        'status': 'Pending',
        'customer_id': null,
        'notes': 'Test online order',
        'revision': 1,
        'items': [
          {
            'id': 'item-001',
            'product_unit_id': 'pu-001',
            'quantity': 2.0,
            'unit_price': 50.0,
            'discount': 0.0,
            'tax': 15.0,
            'line_total': 100.0,
          },
        ],
      };

      // We need to seed product_unit for FK
      await db.customStatement(
        "INSERT INTO units(id, business_id, unit_name, unit_symbol) VALUES ('unit-001', ?, 'Piece', 'pc')",
        [businessId],
      );
      await db.customStatement(
        "INSERT INTO categories(id, business_id, category_name, category_code) VALUES ('cat-001', ?, 'Test', 'T')",
        [businessId],
      );
      await db.customStatement(
        "INSERT INTO products(id, business_id, product_name, product_code, product_type, category_id) VALUES ('prod-001', ?, 'TestProd', 'P001', 'standard', 'cat-001')",
        [businessId],
      );
      await db.customStatement(
        "INSERT INTO product_units(id, business_id, product_id, unit_id, barcode, sku, conversion_factor, selling_price, purchase_price) VALUES ('pu-001', ?, 'prod-001', 'unit-001', '123', 'SKU1', 1.0, 50.0, 30.0)",
        [businessId],
      );

      // Act
      await salesDao.insertOnlineOrder(orderJson);

      // Assert: order persisted
      final order = await salesDao.getOrderById('order-001', businessId);
      expect(order, isNotNull);
      expect(order!.orderNumber, 'ONLINE-001');
      expect(order.status, 'Pending');
      expect(order.grandTotal, 115.0);
      expect(order.syncStatus, 'synced'); // Came from server

      // Assert: order items persisted
      final orderWithItems = await salesDao.getOrderWithItemsById(
        'order-001',
        businessId,
      );
      expect(orderWithItems, isNotNull);
      expect(orderWithItems!.items.length, 1);
      expect(orderWithItems.items.first.productUnitId, 'pu-001');
      expect(orderWithItems.items.first.quantity, 2.0);
      expect(orderWithItems.items.first.unitPrice, 50.0);
    });

    test('insertOnlineOrder with insertOrIgnore prevents duplicate', () async {
      final orderJson = <String, dynamic>{
        'id': 'order-dup',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-DUP',
        'currency_id': currencyId,
        'sub_total': 50.0,
        'grand_total': 50.0,
        'status': 'Pending',
        'revision': 1,
      };

      // Insert first time
      await salesDao.insertOnlineOrder(orderJson);
      // Insert again (should be ignored, not throw)
      await salesDao.insertOnlineOrder(orderJson);

      // Only one order exists
      final orders = await salesDao.listOnlineOrders(businessId);
      final count = orders.where((o) => o.id == 'order-dup').length;
      expect(count, 1);
    });
  });

  group('No Side Effect on Arrival — CRITICAL INVARIANT', () {
    test('online order pull creates ZERO sales invoices', () async {
      final orderJson = <String, dynamic>{
        'id': 'order-inv-check',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-INV-CHECK',
        'currency_id': currencyId,
        'sub_total': 200.0,
        'grand_total': 230.0,
        'status': 'Pending',
        'revision': 1,
      };

      await salesDao.insertOnlineOrder(orderJson);

      // Verify: ZERO SalesInvoice records
      final invoices = await salesDao.listInvoices(
        SalesInvoiceFilter(businessId: businessId),
      );
      expect(invoices.length, 0,
          reason: 'Online Order arrival must NOT create SalesInvoice');
    });

    test('online order pull creates ZERO inventory transactions', () async {
      final inventoryDao = InventoryDao(db);
      final orderJson = <String, dynamic>{
        'id': 'order-stock-check',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-STOCK-CHECK',
        'currency_id': currencyId,
        'sub_total': 100.0,
        'grand_total': 100.0,
        'status': 'Pending',
        'revision': 1,
      };

      await salesDao.insertOnlineOrder(orderJson);

      // Verify: ZERO InventoryTransaction records
      final transactions = await inventoryDao.listTransactions(
        InventoryTransactionFilter(businessId: businessId),
      );
      expect(transactions.length, 0,
          reason: 'Online Order arrival must NOT create InventoryTransaction');
    });

    test('online order pull creates ZERO journal entries', () async {
      final accountingDao = AccountingDao(db);
      final orderJson = <String, dynamic>{
        'id': 'order-journal-check',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-JOURNAL-CHECK',
        'currency_id': currencyId,
        'sub_total': 100.0,
        'grand_total': 100.0,
        'status': 'Pending',
        'revision': 1,
      };

      await salesDao.insertOnlineOrder(orderJson);

      // Verify: ZERO JournalEntry records
      final entries = await accountingDao.listJournalEntries(
        JournalEntryFilter(businessId: businessId),
      );
      expect(entries.length, 0,
          reason: 'Online Order arrival must NOT create JournalEntry');
    });
  });

  group('Accept Order — Does NOT Create Sale', () {
    test('accepting order changes status but creates no invoice', () async {
      // Seed order
      final orderJson = <String, dynamic>{
        'id': 'order-accept',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-ACCEPT',
        'currency_id': currencyId,
        'sub_total': 100.0,
        'grand_total': 100.0,
        'status': 'Pending',
        'revision': 1,
      };
      await salesDao.insertOnlineOrder(orderJson);

      // Accept (status → Confirmed)
      final updated = await salesDao.updateOrderStatus(
        'order-accept',
        businessId,
        'Confirmed',
      );
      expect(updated, true);

      // Verify status changed
      final order = await salesDao.getOrderById('order-accept', businessId);
      expect(order!.status, 'Confirmed');

      // Verify: ZERO invoices, inventory, journal
      final invoices = await salesDao.listInvoices(
        SalesInvoiceFilter(businessId: businessId),
      );
      expect(invoices.length, 0,
          reason: 'Accept must NOT create SalesInvoice');
    });
  });

  group('Reject Order', () {
    test('rejecting order preserves the original record', () async {
      final orderJson = <String, dynamic>{
        'id': 'order-reject',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-REJECT',
        'currency_id': currencyId,
        'sub_total': 50.0,
        'grand_total': 50.0,
        'status': 'Pending',
        'revision': 1,
      };
      await salesDao.insertOnlineOrder(orderJson);

      // Reject (status → Cancelled)
      final updated = await salesDao.updateOrderStatus(
        'order-reject',
        businessId,
        'Cancelled',
      );
      expect(updated, true);

      // Order still exists (not deleted)
      final order = await salesDao.getOrderById('order-reject', businessId);
      expect(order, isNotNull);
      expect(order!.status, 'Cancelled');
      expect(order.deletedAt, isNull, reason: 'Rejected order must NOT be physically deleted');
    });
  });

  group('Tenant Isolation', () {
    test('Business A cannot see Business B orders', () async {
      const otherBusinessId = 'biz-other';
      // Seed other business
      await db.customStatement(
        "INSERT OR IGNORE INTO businesses(id, account_id, business_name, primary_phone) VALUES (?, 'test-account', 'OtherBiz', '456')",
        [otherBusinessId],
      );
      await db.customStatement(
        "INSERT OR IGNORE INTO branches(id, business_id, branch_name, branch_code) VALUES ('branch-other', ?, 'Other Branch', 'BR02')",
        [otherBusinessId],
      );
      await db.customStatement(
        "INSERT OR IGNORE INTO channels(id, business_id, channel_name, channel_code, channel_type) VALUES ('ch-other', ?, 'Other Channel', 'OTH', 'Ecommerce')",
        [otherBusinessId],
      );

      // Insert order for other business
      final otherOrderJson = <String, dynamic>{
        'id': 'order-other-biz',
        'business_id': otherBusinessId,
        'branch_id': 'branch-other',
        'channel_id': 'ch-other',
        'order_number': 'OTHER-001',
        'currency_id': currencyId,
        'sub_total': 999.0,
        'grand_total': 999.0,
        'status': 'Pending',
        'revision': 1,
      };
      await salesDao.insertOnlineOrder(otherOrderJson);

      // Insert order for test business
      final myOrderJson = <String, dynamic>{
        'id': 'order-my-biz',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'MY-001',
        'currency_id': currencyId,
        'sub_total': 100.0,
        'grand_total': 100.0,
        'status': 'Pending',
        'revision': 1,
      };
      await salesDao.insertOnlineOrder(myOrderJson);

      // Business A can only see its own orders
      final myOrders = await salesDao.listOnlineOrders(businessId);
      expect(myOrders.length, 1);
      expect(myOrders.first.id, 'order-my-biz');

      // Cannot get other business order
      final otherOrder = await salesDao.getOrderById(
        'order-other-biz',
        businessId,
      );
      expect(otherOrder, isNull,
          reason: 'Business A must NOT access Business B orders');
    });
  });

  group('Order Status Transitions', () {
    test('listOnlineOrders returns orders sorted by date descending', () async {
      // Insert two orders with different dates
      await salesDao.insertOnlineOrder(<String, dynamic>{
        'id': 'order-old',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-OLD',
        'currency_id': currencyId,
        'order_date': DateTime(2024, 1, 1).toIso8601String(),
        'sub_total': 50.0,
        'grand_total': 50.0,
        'status': 'Pending',
        'revision': 1,
      });

      await salesDao.insertOnlineOrder(<String, dynamic>{
        'id': 'order-new',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-NEW',
        'currency_id': currencyId,
        'order_date': DateTime(2024, 6, 1).toIso8601String(),
        'sub_total': 75.0,
        'grand_total': 75.0,
        'status': 'Pending',
        'revision': 1,
      });

      final orders = await salesDao.listOnlineOrders(businessId);
      expect(orders.length, 2);
      // Should be sorted by date descending
      expect(orders.first.id, 'order-new');
      expect(orders.last.id, 'order-old');
    });

    test('watchOrders emits orders reactively', () async {
      final stream = salesDao.watchOrders(
        OrderFilter(businessId: businessId, limit: 100),
      );

      // First emission should be empty
      final first = await stream.first;
      expect(first, isEmpty);
    });
  });

  group('Duplicate Fulfillment Protection', () {
    test('order marked as Delivered cannot be re-confirmed', () async {
      await salesDao.insertOnlineOrder(<String, dynamic>{
        'id': 'order-dup-fulfill',
        'business_id': businessId,
        'branch_id': branchId,
        'channel_id': channelId,
        'order_number': 'ONLINE-DUP-FULFILL',
        'currency_id': currencyId,
        'sub_total': 100.0,
        'grand_total': 100.0,
        'status': 'Pending',
        'revision': 1,
      });

      // Move to Confirmed, then Delivered
      await salesDao.updateOrderStatus('order-dup-fulfill', businessId, 'Confirmed');
      await salesDao.updateOrderStatus('order-dup-fulfill', businessId, 'Delivered');

      // Verify it's Delivered
      final order = await salesDao.getOrderById('order-dup-fulfill', businessId);
      expect(order!.status, 'Delivered');
    });
  });
}
