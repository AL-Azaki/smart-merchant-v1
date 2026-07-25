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

    final currencyId = json['currency_id']?.toString() ?? '';
    final exchangeRate = (json['exchange_rate'] as num?)?.toDouble() ?? 1.0;
    final subTotal = (json['sub_total'] as num?)?.toDouble() ?? 0.0;
    final discountTotal = (json['discount_total'] as num?)?.toDouble() ?? 0.0;
    final taxTotal = (json['tax_total'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = (json['grand_total'] as num?)?.toDouble() ?? 0.0;
    final status = json['status']?.toString() ?? 'Pending';
    final customerId = json['customer_id']?.toString();
    final notes = json['notes']?.toString();
    final revision = json['revision'] as int? ?? 1;

    await into(orders).insert(
      OrdersCompanion.insert(
        id: orderId,
        businessId: businessId,
        branchId: branchId,
        channelId: channelId,
        orderNumber: orderNumber,
        orderDate: Value(orderDate),
        currencyId: currencyId,
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
          final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
          final discount = (item['discount'] as num?)?.toDouble() ?? 0.0;
          final tax = (item['tax'] as num?)?.toDouble() ?? 0.0;
          final lineTotal =
              (item['line_total'] as num?)?.toDouble() ??
              (quantity * unitPrice);

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
