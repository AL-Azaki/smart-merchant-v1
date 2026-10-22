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
    final customerName = json['customer_name']?.toString();
    final customerPhone = json['customer_phone']?.toString();
    final shippingAddress = json['shipping_address']?.toString();
    final customerNotes = json['customer_notes']?.toString();
    final rawNotes = json['notes']?.toString();

    final notesParts = <String>[];
    if (customerName != null && customerName.isNotEmpty) {
      notesParts.add('العميل: $customerName');
    }
    if (customerPhone != null && customerPhone.isNotEmpty) {
      notesParts.add('الهاتف: $customerPhone');
    }
    if (shippingAddress != null && shippingAddress.isNotEmpty) {
      notesParts.add('العنوان: $shippingAddress');
    }
    if (customerNotes != null && customerNotes.isNotEmpty) {
      notesParts.add('ملاحظات العميل: $customerNotes');
    }
    if (rawNotes != null && rawNotes.isNotEmpty && !notesParts.contains(rawNotes)) {
      notesParts.add(rawNotes);
    }

    final notes = notesParts.isNotEmpty ? notesParts.join(' | ') : null;
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

    // Resolve branchId: must exist in local branches table
    String resolvedBranchId = branchId;
    final existingBranch = await (attachedDatabase.select(attachedDatabase.branches)
          ..where((b) => b.businessId.equals(businessId) & b.id.equals(resolvedBranchId)))
        .getSingleOrNull();
    if (existingBranch == null) {
      final firstBranch = await (attachedDatabase.select(attachedDatabase.branches)
            ..where((b) => b.businessId.equals(businessId))
            ..limit(1))
          .getSingleOrNull();
      if (firstBranch != null) {
        resolvedBranchId = firstBranch.id;
      } else {
        // Fallback: create branch locally if missing
        await into(branches).insert(
          BranchesCompanion.insert(
            id: resolvedBranchId.isNotEmpty ? resolvedBranchId : _uuid.v4(),
            businessId: businessId,
            branchName: 'الفرع الرئيسي',
            branchCode: 'MAIN',
            isActive: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        resolvedBranchId = resolvedBranchId.isNotEmpty ? resolvedBranchId : firstBranch?.id ?? '';
      }
    }

    // Ensure the channel exists locally to satisfy FK (business_id, channel_id)
    String resolvedChannelId = channelId.isNotEmpty ? channelId : 'online-channel';
    final existingChannel = await (select(channels)
          ..where((c) => c.businessId.equals(businessId) & c.id.equals(resolvedChannelId)))
        .getSingleOrNull();
    if (existingChannel == null) {
      await into(channels).insert(
        ChannelsCompanion.insert(
          id: resolvedChannelId,
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

    await into(orders).insert(
      OrdersCompanion.insert(
        id: orderId,
        businessId: businessId,
        branchId: resolvedBranchId,
        channelId: resolvedChannelId,
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
      mode: InsertMode.insertOrReplace,
    );

    // Insert order items if present
    final items = json['items'] ?? json['order_items'];
    if (items is List) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          try {
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
              mode: InsertMode.insertOrReplace,
            );
          } catch (e) {
            // Log line item failure without dropping the entire order header
          }
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
