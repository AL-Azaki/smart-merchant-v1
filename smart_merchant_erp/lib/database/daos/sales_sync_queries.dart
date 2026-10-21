import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../kernel/storage/app_database.dart';
import 'sales_dao.dart';

const _uuid = Uuid();

/// Extension methods on [SalesDao] providing sync-specific queries
/// for the Sales domain — specifically Online Order persistence from pull.
extension SalesSyncQueries on SalesDao {
  /// Persists a pulled Online Order into the local `orders` and `order_items` tables.
  ///
  /// CRITICAL INVARIANT: This does NOT create SalesInvoice, InventoryTransaction,
  /// JournalEntry, Payment, or Receivable. It is purely an incoming order record.
  Future<void> insertOnlineOrder(Map<String, dynamic> json) async {
    final orderId = json['id']?.toString() ?? _uuid.v4();
    final businessId = json['business_id']?.toString() ?? '';
    final branchId = json['branch_id']?.toString() ?? '';
    final channelId = json['channel_id']?.toString() ?? '';
    final orderNumber =
        json['order_number']?.toString() ??
        'ONLINE-${DateTime.now().millisecondsSinceEpoch}';

    // Parse order date
    DateTime? orderDate;
    if (json['order_date'] != null) {
      orderDate = DateTime.tryParse(json['order_date'].toString());
    }
    orderDate ??= DateTime.now();

    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val == null) return defaultVal;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? defaultVal;
    }

    int parseInt(dynamic val, [int defaultVal = 1]) {
      if (val == null) return defaultVal;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? defaultVal;
    }

    final currencyId = json['currency_id']?.toString() ?? '';
    final exchangeRate = parseDouble(json['exchange_rate'], 1.0);
    final subTotal = parseDouble(json['sub_total'], 0.0);
    final discountTotal = parseDouble(json['discount_total'], 0.0);
    final taxTotal = parseDouble(json['tax_total'], 0.0);
    final grandTotal = parseDouble(json['grand_total'], 0.0);
    final status = json['status']?.toString() ?? 'Pending';
    final customerId = json['customer_id']?.toString();
    final notes = json['notes']?.toString();
    final revision = parseInt(json['revision'], 1);

    // Resolve currencyId: must exist in local currencies table
    String resolvedCurrencyId = currencyId;
    final existingCurr = await (attachedDatabase.select(attachedDatabase.currencies)
          ..where((c) => c.id.equals(resolvedCurrencyId)))
        .getSingleOrNull();
    if (existingCurr == null) {
      // Fallback to base currency or first available currency locally
      final baseCurr = await (attachedDatabase.select(attachedDatabase.currencies)
            ..where((c) => c.isBaseCurrency.equals(true)))
          .getSingleOrNull()
          ?? await (attachedDatabase.select(attachedDatabase.currencies)..limit(1)).getSingleOrNull();
      if (baseCurr != null) {
        resolvedCurrencyId = baseCurr.id;
      }
    }

    // Ensure the channel exists locally to satisfy FK (business_id, channel_id)
    if (channelId.isNotEmpty) {
      final existingChannel = await (select(channels)
            ..where((c) => c.businessId.equals(businessId) & c.id.equals(channelId)))
          .getSingleOrNull();
      if (existingChannel == null) {
        await into(channels).insert(
          ChannelsCompanion.insert(
            id: channelId,
            businessId: businessId,
            channelName: 'Online Store',
            channelCode: 'ONLINE-STORE-01',
            channelType: 'Ecommerce',
            isActive: const Value(true),
            syncStatus: const Value('synced'),
            version: const Value(1),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }

    await into(orders).insert(
      OrdersCompanion.insert(
        id: orderId,
        businessId: businessId,
        branchId: branchId,
        channelId: channelId,
        orderNumber: orderNumber,
        orderDate: Value(orderDate),
        currencyId: resolvedCurrencyId,
        exchangeRate: Value(exchangeRate),
        subTotal: Value(subTotal),
        discountTotal: Value(discountTotal),
        taxTotal: Value(taxTotal),
        grandTotal: Value(grandTotal),
        status: Value(status),
        customerId: Value(customerId),
        notes: Value(notes),
        syncStatus: const Value('synced'), // Came from server, already synced
        version: Value(revision),
      ),
      mode: InsertMode.insertOrIgnore, // Duplicate protection
    );

    // Insert order items if present
    final items = json['items'] ?? json['order_items'];
    if (items is List) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final itemId = item['id']?.toString() ?? _uuid.v4();
          final productUnitId = item['product_unit_id']?.toString() ?? '';
          final quantity = parseDouble(item['quantity'], 0.0);
          final unitPrice = parseDouble(item['unit_price'], 0.0);
          final discount = parseDouble(item['discount'], 0.0);
          final tax = parseDouble(item['tax'], 0.0);
          final lineTotal = item['line_total'] != null
              ? parseDouble(item['line_total'], quantity * unitPrice)
              : (quantity * unitPrice);

          await into(orderItems).insert(
            OrderItemsCompanion.insert(
              id: itemId,
              businessId: businessId,
              orderId: orderId,
              productUnitId: productUnitId,
              quantity: quantity,
              unitPrice: unitPrice,
              discount: Value(discount),
              tax: Value(tax),
              lineTotal: lineTotal,
              syncStatus: const Value('synced'),
              version: Value(revision),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    }
  }

  /// Lists Online Orders available for the cashier inbox.
  Future<List<OrderEntity>> listOnlineOrders(String businessId) {
    return (select(orders)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.orderDate)]))
        .get();
  }
}
