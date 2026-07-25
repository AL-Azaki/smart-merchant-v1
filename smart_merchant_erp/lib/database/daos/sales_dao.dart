import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/catalog/products_table.dart';
import '../tables/catalog/product_units_table.dart';
import '../tables/catalog/product_variants_table.dart';
import '../tables/core/branches_table.dart';
import '../tables/inventory/warehouses_table.dart';
import '../tables/sales/channels_table.dart';
import '../tables/sales/customer_receivables_table.dart';
import '../tables/sales/customers_table.dart';
import '../tables/sales/order_items_table.dart';
import '../tables/sales/orders_table.dart';
import '../tables/sales/receivable_entries_table.dart';
import '../tables/sales/sales_invoice_items_table.dart';
import '../tables/sales/sales_invoices_table.dart';
import '../tables/sales/sales_return_items_table.dart';
import '../tables/sales/sales_returns_table.dart';
import 'dao_exceptions.dart';

part 'sales_dao.g.dart';

/// Filter DTO for [Channels] queries.
class ChannelFilter {
  final String businessId;
  final bool? isActive;
  final String? channelType;
  final String? searchQuery;

  const ChannelFilter({
    required this.businessId,
    this.isActive,
    this.channelType,
    this.searchQuery,
  });
}

/// Filter DTO for [Customers] queries.
class CustomerFilter {
  final String businessId;
  final bool? isActive;
  final bool includeDeleted;
  final String? searchQuery;
  final int limit;
  final int offset;

  const CustomerFilter({
    required this.businessId,
    this.isActive,
    this.includeDeleted = false,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [Orders] queries.
class OrderFilter {
  final String businessId;
  final String? branchId;
  final String? customerId;
  final String? channelId;
  final String? status;
  final String? paymentStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeDeleted;
  final int limit;
  final int offset;

  const OrderFilter({
    required this.businessId,
    this.branchId,
    this.customerId,
    this.channelId,
    this.status,
    this.paymentStatus,
    this.startDate,
    this.endDate,
    this.includeDeleted = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining an [OrderEntity] with its [OrderItemEntity]s.
class OrderWithItems {
  final OrderEntity order;
  final List<OrderItemEntity> items;

  const OrderWithItems({required this.order, required this.items});
}

/// Filter DTO for [SalesInvoices] queries.
class SalesInvoiceFilter {
  final String businessId;
  final String? branchId;
  final String? customerId;
  final String? status;
  final String? paymentStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const SalesInvoiceFilter({
    required this.businessId,
    this.branchId,
    this.customerId,
    this.status,
    this.paymentStatus,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [SalesInvoice] with its [SalesInvoiceItem]s.
class SalesInvoiceWithItems {
  final SalesInvoice invoice;
  final List<SalesInvoiceItem> items;

  const SalesInvoiceWithItems({required this.invoice, required this.items});
}

/// Filter DTO for [SalesReturns] queries.
class SalesReturnFilter {
  final String businessId;
  final String? branchId;
  final String? salesInvoiceId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeDeleted;
  final int limit;
  final int offset;

  const SalesReturnFilter({
    required this.businessId,
    this.branchId,
    this.salesInvoiceId,
    this.status,
    this.startDate,
    this.endDate,
    this.includeDeleted = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [SalesReturn] with its [SalesReturnItem]s.
class SalesReturnWithItems {
  final SalesReturn salesReturn;
  final List<SalesReturnItem> items;

  const SalesReturnWithItems({required this.salesReturn, required this.items});
}

/// Filter DTO for [CustomerReceivables] queries.
class CustomerReceivableFilter {
  final String businessId;
  final String? customerId;
  final String? salesInvoiceId;
  final String? status;
  final bool onlyOverdue;
  final int limit;
  final int offset;

  const CustomerReceivableFilter({
    required this.businessId,
    this.customerId,
    this.salesInvoiceId,
    this.status,
    this.onlyOverdue = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [CustomerReceivable] with its [ReceivableEntry]s.
class CustomerReceivableWithEntries {
  final CustomerReceivable receivable;
  final List<ReceivableEntry> entries;

  const CustomerReceivableWithEntries({
    required this.receivable,
    required this.entries,
  });
}

/// Summary DTO for customer financial balance and status.
class CustomerBalanceSummary {
  final String customerId;
  final String customerName;
  final double creditLimit;
  final double openingBalance;
  final double totalReceivables;
  final double totalPaid;
  final double totalRemaining;
  final String? openingBalanceType;

  const CustomerBalanceSummary({
    required this.customerId,
    required this.customerName,
    required this.creditLimit,
    required this.openingBalance,
    required this.totalReceivables,
    required this.totalPaid,
    required this.totalRemaining,
    this.openingBalanceType,
  });
}

/// Module-Driven DAO for Domain: Sales & Customers (Phase 04).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), branch scoping (`branchId`), soft-delete rules (`deletedAt`),
/// and atomic transactional persistence for:
/// [Channels], [Customers], [CustomerReceivables], [Orders], [OrderItems],
/// [SalesInvoices], [SalesInvoiceItems], [ReceivableEntries], [SalesReturns], and [SalesReturnItems].
@DriftAccessor(
  tables: [
    Channels,
    CustomerReceivables,
    Customers,
    OrderItems,
    Orders,
    ReceivableEntries,
    SalesInvoiceItems,
    SalesInvoices,
    SalesReturnItems,
    SalesReturns,
    Products,
    ProductVariants,
    ProductUnits,
    Branches,
    Warehouses,
  ],
)
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  // ============================================================================
  // 1. CHANNELS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a channel by ID within a business.
  Future<ChannelEntity?> getChannelById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getChannelById requires businessId.');
    }
    return (select(channels)
          ..where((c) => c.id.equals(id) & c.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists channels matching the provided filter.
  Future<List<ChannelEntity>> listChannels(ChannelFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listChannels requires businessId.');
    }
    final query = select(channels)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((c) => c.isActive.equals(filter.isActive!));
    }
    if (filter.channelType != null && filter.channelType!.trim().isNotEmpty) {
      query.where((c) => c.channelType.equals(filter.channelType!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim().toLowerCase()}%';
      query.where(
        (c) => c.channelName.lower().like(q) | c.channelCode.lower().like(q),
      );
    }
    query.orderBy([(c) => OrderingTerm(expression: c.channelName)]);
    return query.get();
  }

  /// Reactive stream of channels matching the provided filter.
  Stream<List<ChannelEntity>> watchChannels(ChannelFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchChannels requires businessId.');
    }
    final query = select(channels)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((c) => c.isActive.equals(filter.isActive!));
    }
    if (filter.channelType != null && filter.channelType!.trim().isNotEmpty) {
      query.where((c) => c.channelType.equals(filter.channelType!));
    }
    query.orderBy([(c) => OrderingTerm(expression: c.channelName)]);
    return query.watch();
  }

  /// Inserts a new channel.
  Future<int> insertChannel(ChannelsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertChannel requires businessId.');
    }
    return into(channels).insert(companion);
  }

  /// Updates an existing channel.
  Future<bool> updateChannel(ChannelsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateChannel requires id and businessId.',
      );
    }
    return (update(channels)..where(
          (c) =>
              c.id.equals(companion.id.value) &
              c.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 2. CUSTOMERS OPERATIONS (Tenant Scoped, Soft Delete Support)
  // ============================================================================

  /// Retrieves a customer by ID within a business.
  Future<Customer?> getCustomerById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getCustomerById requires businessId.',
      );
    }
    final query = select(customers)
      ..where((c) => c.id.equals(id) & c.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((c) => c.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists customers matching the provided filter with pagination.
  Future<List<Customer>> listCustomers(CustomerFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listCustomers requires businessId.');
    }
    final query = select(customers)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((c) => c.deletedAt.isNull());
    }
    if (filter.isActive != null) {
      query.where((c) => c.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim().toLowerCase()}%';
      query.where(
        (c) =>
            c.customerName.lower().like(q) |
            c.phone.lower().like(q) |
            c.email.lower().like(q),
      );
    }
    query.orderBy([(c) => OrderingTerm(expression: c.customerName)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of customers matching the provided filter.
  Stream<List<Customer>> watchCustomers(CustomerFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchCustomers requires businessId.');
    }
    final query = select(customers)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((c) => c.deletedAt.isNull());
    }
    if (filter.isActive != null) {
      query.where((c) => c.isActive.equals(filter.isActive!));
    }
    query.orderBy([(c) => OrderingTerm(expression: c.customerName)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new customer.
  Future<int> insertCustomer(CustomersCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertCustomer requires businessId.');
    }
    return into(customers).insert(companion);
  }

  /// Updates an existing customer.
  Future<bool> updateCustomer(CustomersCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateCustomer requires id and businessId.',
      );
    }
    return (update(customers)..where(
          (c) =>
              c.id.equals(companion.id.value) &
              c.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Soft deletes a customer by setting `deletedAt` and `syncStatus = 'pending_delete'`.
  Future<bool> softDeleteCustomer(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteCustomer requires businessId.',
      );
    }
    return (update(customers)..where(
          (c) =>
              c.id.equals(id) &
              c.businessId.equals(businessId) &
              c.deletedAt.isNull(),
        ))
        .write(
          CustomersCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            isActive: const Value(false),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted customer.
  Future<bool> restoreCustomer(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'restoreCustomer requires businessId.',
      );
    }
    return (update(customers)..where(
          (c) =>
              c.id.equals(id) &
              c.businessId.equals(businessId) &
              c.deletedAt.isNotNull(),
        ))
        .write(
          CustomersCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Calculates and returns financial balance summary for a customer.
  Future<CustomerBalanceSummary?> getCustomerBalanceSummary(
    String customerId,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getCustomerBalanceSummary requires businessId.',
      );
    }
    final customer = await getCustomerById(customerId, businessId);
    if (customer == null) {
      return null;
    }

    final receivablesList =
        await (select(customerReceivables)..where(
              (r) =>
                  r.customerId.equals(customerId) &
                  r.businessId.equals(businessId),
            ))
            .get();

    double totalReceivables = 0.0;
    double totalPaid = 0.0;
    double totalRemaining = 0.0;

    for (final r in receivablesList) {
      totalReceivables += r.originalAmount;
      totalPaid += r.paidAmount;
      totalRemaining += r.remainingAmount;
    }

    return CustomerBalanceSummary(
      customerId: customer.id,
      customerName: customer.customerName,
      creditLimit: customer.creditLimit,
      openingBalance: customer.openingBalance,
      openingBalanceType: customer.openingBalanceType,
      totalReceivables: totalReceivables,
      totalPaid: totalPaid,
      totalRemaining: totalRemaining,
    );
  }

  // ============================================================================
  // 3. ORDERS & ORDER ITEMS OPERATIONS (Tenant & Branch Scoped, Atomic Seeding)
  // ============================================================================

  /// Retrieves an order by ID.
  Future<OrderEntity?> getOrderById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getOrderById requires businessId.');
    }
    final query = select(orders)
      ..where((o) => o.id.equals(id) & o.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((o) => o.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves an order along with all of its order line items.
  Future<OrderWithItems?> getOrderWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) async {
    final order = await getOrderById(
      id,
      businessId,
      includeDeleted: includeDeleted,
    );
    if (order == null) {
      return null;
    }

    final items =
        await (select(orderItems)..where(
              (i) => i.orderId.equals(id) & i.businessId.equals(businessId),
            ))
            .get();

    return OrderWithItems(order: order, items: items);
  }

  /// Lists orders matching the provided filter with pagination.
  Future<List<OrderEntity>> listOrders(OrderFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listOrders requires businessId.');
    }
    final query = select(orders)
      ..where((o) => o.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((o) => o.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((o) => o.branchId.equals(filter.branchId!));
    }
    if (filter.customerId != null && filter.customerId!.trim().isNotEmpty) {
      query.where((o) => o.customerId.equals(filter.customerId!));
    }
    if (filter.channelId != null && filter.channelId!.trim().isNotEmpty) {
      query.where((o) => o.channelId.equals(filter.channelId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((o) => o.status.equals(filter.status!));
    }
    if (filter.paymentStatus != null &&
        filter.paymentStatus!.trim().isNotEmpty) {
      query.where((o) => o.paymentStatus.equals(filter.paymentStatus!));
    }
    if (filter.startDate != null) {
      query.where((o) => o.orderDate.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((o) => o.orderDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (o) => OrderingTerm(expression: o.orderDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of orders matching the provided filter.
  Stream<List<OrderEntity>> watchOrders(OrderFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchOrders requires businessId.');
    }
    final query = select(orders)
      ..where((o) => o.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((o) => o.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((o) => o.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((o) => o.status.equals(filter.status!));
    }
    query.orderBy([
      (o) => OrderingTerm(expression: o.orderDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically records a sales order along with all of its line items inside a database transaction.
  /// If any line item fails FK or CHECK constraints, the entire order rolls back.
  Future<void> recordOrderWithItems({
    required OrdersCompanion order,
    required List<OrderItemsCompanion> items,
  }) async {
    if (!order.businessId.present || order.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordOrderWithItems requires businessId on order.',
      );
    }
    final busId = order.businessId.value;

    await transaction(() async {
      await into(orders).insert(order);

      for (final item in items) {
        if (!item.businessId.present || item.businessId.value != busId) {
          throw const TenantScopingException(
            'All order items must match order businessId.',
          );
        }
        await into(orderItems).insert(item);
      }
    });
  }

  /// Updates the status of an order (`Pending`, `Confirmed`, `Shipped`, `Delivered`, `Cancelled`).
  Future<bool> updateOrderStatus(String id, String businessId, String status) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateOrderStatus requires businessId.',
      );
    }
    return (update(orders)..where(
          (o) =>
              o.id.equals(id) &
              o.businessId.equals(businessId) &
              o.deletedAt.isNull(),
        ))
        .write(
          OrdersCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft deletes an order.
  Future<bool> softDeleteOrder(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteOrder requires businessId.',
      );
    }
    return (update(orders)..where(
          (o) =>
              o.id.equals(id) &
              o.businessId.equals(businessId) &
              o.deletedAt.isNull(),
        ))
        .write(
          OrdersCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted order.
  Future<bool> restoreOrder(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('restoreOrder requires businessId.');
    }
    return (update(orders)..where(
          (o) =>
              o.id.equals(id) &
              o.businessId.equals(businessId) &
              o.deletedAt.isNotNull(),
        ))
        .write(
          OrdersCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 4. SALES INVOICES & INVOICE ITEMS OPERATIONS (Tenant & Branch Scoped, Atomic)
  // ============================================================================

  /// Retrieves a sales invoice by ID.
  Future<SalesInvoice?> getInvoiceById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getInvoiceById requires businessId.');
    }
    return (select(salesInvoices)
          ..where((i) => i.id.equals(id) & i.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a sales invoice along with its invoice line items.
  Future<SalesInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  ) async {
    final invoice = await getInvoiceById(id, businessId);
    if (invoice == null) {
      return null;
    }

    final items =
        await (select(salesInvoiceItems)..where(
              (i) =>
                  i.salesInvoiceId.equals(id) & i.businessId.equals(businessId),
            ))
            .get();

    return SalesInvoiceWithItems(invoice: invoice, items: items);
  }

  /// Lists sales invoices matching the provided filter with pagination.
  Future<List<SalesInvoice>> listInvoices(SalesInvoiceFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listInvoices requires businessId.');
    }
    final query = select(salesInvoices)
      ..where((i) => i.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((i) => i.branchId.equals(filter.branchId!));
    }
    if (filter.customerId != null && filter.customerId!.trim().isNotEmpty) {
      query.where((i) => i.customerId.equals(filter.customerId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((i) => i.status.equals(filter.status!));
    }
    if (filter.paymentStatus != null &&
        filter.paymentStatus!.trim().isNotEmpty) {
      query.where((i) => i.paymentStatus.equals(filter.paymentStatus!));
    }
    if (filter.startDate != null) {
      query.where((i) => i.invoiceDate.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((i) => i.invoiceDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (i) => OrderingTerm(expression: i.invoiceDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of sales invoices matching the provided filter.
  Stream<List<SalesInvoice>> watchInvoices(SalesInvoiceFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchInvoices requires businessId.');
    }
    final query = select(salesInvoices)
      ..where((i) => i.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((i) => i.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((i) => i.status.equals(filter.status!));
    }
    query.orderBy([
      (i) => OrderingTerm(expression: i.invoiceDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically records a sales invoice, all its line items, and optional customer receivable record
  /// plus initial payment allocation entry inside a single database transaction.
  Future<void> recordInvoiceWithItemsAndReceivable({
    required SalesInvoicesCompanion invoice,
    required List<SalesInvoiceItemsCompanion> items,
    CustomerReceivablesCompanion? receivable,
    ReceivableEntriesCompanion? initialEntry,
  }) async {
    if (!invoice.businessId.present ||
        invoice.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordInvoiceWithItemsAndReceivable requires businessId on invoice.',
      );
    }
    final busId = invoice.businessId.value;

    await transaction(() async {
      await into(salesInvoices).insert(invoice);

      for (final item in items) {
        if (!item.businessId.present || item.businessId.value != busId) {
          throw const TenantScopingException(
            'All invoice items must match invoice businessId.',
          );
        }
        await into(salesInvoiceItems).insert(item);
      }

      if (receivable != null) {
        if (!receivable.businessId.present ||
            receivable.businessId.value != busId) {
          throw const TenantScopingException(
            'Receivable businessId must match invoice businessId.',
          );
        }
        await into(customerReceivables).insert(receivable);

        if (initialEntry != null) {
          if (!initialEntry.businessId.present ||
              initialEntry.businessId.value != busId) {
            throw const TenantScopingException(
              'Receivable entry businessId must match invoice businessId.',
            );
          }
          await into(receivableEntries).insert(initialEntry);
        }
      }
    });
  }

  /// Updates lifecycle status (`Draft`, `Posted`, `Reversed`) of an invoice.
  Future<bool> updateInvoiceStatus(
    String id,
    String businessId,
    String status,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateInvoiceStatus requires businessId.',
      );
    }
    return (update(salesInvoices)
          ..where((i) => i.id.equals(id) & i.businessId.equals(businessId)))
        .write(
          SalesInvoicesCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Updates payment status (`Unpaid`, `Partial`, `Paid`) of an invoice.
  Future<bool> updateInvoicePaymentStatus(
    String id,
    String businessId,
    String paymentStatus,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateInvoicePaymentStatus requires businessId.',
      );
    }
    return (update(salesInvoices)
          ..where((i) => i.id.equals(id) & i.businessId.equals(businessId)))
        .write(
          SalesInvoicesCompanion(
            paymentStatus: Value(paymentStatus),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 5. CUSTOMER RECEIVABLES & RECEIVABLE ENTRIES OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a customer receivable record by ID.
  Future<CustomerReceivable?> getReceivableById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getReceivableById requires businessId.',
      );
    }
    return (select(customerReceivables)
          ..where((r) => r.id.equals(id) & r.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a customer receivable along with its detailed payment entry history.
  Future<CustomerReceivableWithEntries?> getReceivableWithEntriesById(
    String id,
    String businessId,
  ) async {
    final receivable = await getReceivableById(id, businessId);
    if (receivable == null) {
      return null;
    }

    final entries =
        await (select(receivableEntries)..where(
              (e) =>
                  e.customerReceivableId.equals(id) &
                  e.businessId.equals(businessId),
            ))
            .get();

    return CustomerReceivableWithEntries(
      receivable: receivable,
      entries: entries,
    );
  }

  /// Lists customer receivables matching the provided filter.
  Future<List<CustomerReceivable>> listReceivables(
    CustomerReceivableFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listReceivables requires businessId.',
      );
    }
    final query = select(customerReceivables)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (filter.customerId != null && filter.customerId!.trim().isNotEmpty) {
      query.where((r) => r.customerId.equals(filter.customerId!));
    }
    if (filter.salesInvoiceId != null &&
        filter.salesInvoiceId!.trim().isNotEmpty) {
      query.where((r) => r.salesInvoiceId.equals(filter.salesInvoiceId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    if (filter.onlyOverdue) {
      query.where(
        (r) =>
            r.dueDate.isSmallerOrEqualValue(DateTime.now()) &
            r.status.isNotIn(['Paid']),
      );
    }

    query.orderBy([(r) => OrderingTerm(expression: r.dueDate)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of customer receivables matching the provided filter.
  Stream<List<CustomerReceivable>> watchReceivables(
    CustomerReceivableFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchReceivables requires businessId.',
      );
    }
    final query = select(customerReceivables)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (filter.customerId != null && filter.customerId!.trim().isNotEmpty) {
      query.where((r) => r.customerId.equals(filter.customerId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    query.orderBy([(r) => OrderingTerm(expression: r.dueDate)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically inserts a new receivable entry (`Payment`, `Adjustment`, `WriteOff`) and updates
  /// the paid amount, remaining amount, and settlement status on the parent `CustomerReceivable`.
  Future<void> recordReceivableEntry(
    ReceivableEntriesCompanion entry, {
    required String customerReceivableId,
    required String businessId,
    required double newPaidAmount,
    required double newRemainingAmount,
    required double newBasePaidAmount,
    required double newBaseRemainingAmount,
    required String newStatus,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'recordReceivableEntry requires businessId.',
      );
    }
    if (!entry.businessId.present || entry.businessId.value != businessId) {
      throw const TenantScopingException(
        'entry.businessId must match businessId.',
      );
    }

    await transaction(() async {
      await into(receivableEntries).insert(entry);

      final updatedRows =
          await (update(customerReceivables)..where(
                (r) =>
                    r.id.equals(customerReceivableId) &
                    r.businessId.equals(businessId),
              ))
              .write(
                CustomerReceivablesCompanion(
                  paidAmount: Value(newPaidAmount),
                  remainingAmount: Value(newRemainingAmount),
                  basePaidAmount: Value(newBasePaidAmount),
                  baseRemainingAmount: Value(newBaseRemainingAmount),
                  status: Value(newStatus),
                  lastPaymentDate: Value(DateTime.now()),
                  updatedAt: Value(DateTime.now()),
                  syncStatus: const Value('pending_update'),
                ),
              );

      if (updatedRows == 0) {
        throw ArgumentError('Target customer receivable not found for update.');
      }
    });
  }

  // ============================================================================
  // 6. SALES RETURNS & RETURN ITEMS OPERATIONS (Tenant & Branch Scoped, Atomic)
  // ============================================================================

  /// Retrieves a sales return header by ID.
  Future<SalesReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getReturnById requires businessId.');
    }
    final query = select(salesReturns)
      ..where((r) => r.id.equals(id) & r.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a sales return along with all of its returned line items.
  Future<SalesReturnWithItems?> getReturnWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) async {
    final salesReturn = await getReturnById(
      id,
      businessId,
      includeDeleted: includeDeleted,
    );
    if (salesReturn == null) {
      return null;
    }

    final items =
        await (select(salesReturnItems)..where(
              (i) =>
                  i.salesReturnId.equals(id) & i.businessId.equals(businessId),
            ))
            .get();

    return SalesReturnWithItems(salesReturn: salesReturn, items: items);
  }

  /// Lists sales returns matching the provided filter with pagination.
  Future<List<SalesReturn>> listReturns(SalesReturnFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listReturns requires businessId.');
    }
    final query = select(salesReturns)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((r) => r.branchId.equals(filter.branchId!));
    }
    if (filter.salesInvoiceId != null &&
        filter.salesInvoiceId!.trim().isNotEmpty) {
      query.where((r) => r.salesInvoiceId.equals(filter.salesInvoiceId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    if (filter.startDate != null) {
      query.where((r) => r.returnDate.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((r) => r.returnDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (r) => OrderingTerm(expression: r.returnDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of sales returns matching the provided filter.
  Stream<List<SalesReturn>> watchReturns(SalesReturnFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchReturns requires businessId.');
    }
    final query = select(salesReturns)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((r) => r.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    query.orderBy([
      (r) => OrderingTerm(expression: r.returnDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically records a sales return header along with all of its returned items inside a single database transaction.
  Future<void> recordReturnWithItems({
    required SalesReturnsCompanion salesReturn,
    required List<SalesReturnItemsCompanion> items,
  }) async {
    if (!salesReturn.businessId.present ||
        salesReturn.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordReturnWithItems requires businessId on salesReturn.',
      );
    }
    final busId = salesReturn.businessId.value;

    await transaction(() async {
      await into(salesReturns).insert(salesReturn);

      for (final item in items) {
        if (!item.businessId.present || item.businessId.value != busId) {
          throw const TenantScopingException(
            'All return items must match return businessId.',
          );
        }
        await into(salesReturnItems).insert(item);
      }
    });
  }

  /// Updates lifecycle status (`Draft`, `Posted`, `Reversed`) of a sales return.
  Future<bool> updateReturnStatus(String id, String businessId, String status) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateReturnStatus requires businessId.',
      );
    }
    return (update(salesReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNull(),
        ))
        .write(
          SalesReturnsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft deletes a sales return.
  Future<bool> softDeleteReturn(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteReturn requires businessId.',
      );
    }
    return (update(salesReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNull(),
        ))
        .write(
          SalesReturnsCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted sales return.
  Future<bool> restoreReturn(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('restoreReturn requires businessId.');
    }
    return (update(salesReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNotNull(),
        ))
        .write(
          SalesReturnsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 7. OFFLINE-FIRST SYNCHRONIZATION HELPERS (All 10 Sales Domain Tables)
  // ============================================================================

  /// Returns all channels pending synchronization.
  Future<List<ChannelEntity>> getPendingSyncChannels(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncChannels requires businessId.',
      );
    }
    return (select(channels)..where(
          (c) =>
              c.businessId.equals(businessId) &
              c.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified channels as synced.
  Future<int> markChannelsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markChannelsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(channels)
          ..where((c) => c.id.isIn(ids) & c.businessId.equals(businessId)))
        .write(const ChannelsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all customers pending synchronization.
  Future<List<Customer>> getPendingSyncCustomers(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncCustomers requires businessId.',
      );
    }
    return (select(customers)..where(
          (c) =>
              c.businessId.equals(businessId) &
              c.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified customers as synced.
  Future<int> markCustomersAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markCustomersAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(customers)
          ..where((c) => c.id.isIn(ids) & c.businessId.equals(businessId)))
        .write(const CustomersCompanion(syncStatus: Value('synced')));
  }

  /// Returns all orders pending synchronization.
  Future<List<OrderEntity>> getPendingSyncOrders(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncOrders requires businessId.',
      );
    }
    return (select(orders)..where(
          (o) =>
              o.businessId.equals(businessId) &
              o.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified orders as synced.
  Future<int> markOrdersAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markOrdersAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(orders)
          ..where((o) => o.id.isIn(ids) & o.businessId.equals(businessId)))
        .write(const OrdersCompanion(syncStatus: Value('synced')));
  }

  /// Returns all order items pending synchronization.
  Future<List<OrderItemEntity>> getPendingSyncOrderItems(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncOrderItems requires businessId.',
      );
    }
    return (select(orderItems)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified order items as synced.
  Future<int> markOrderItemsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markOrderItemsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(orderItems)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const OrderItemsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all sales invoices pending synchronization.
  Future<List<SalesInvoice>> getPendingSyncInvoices(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncInvoices requires businessId.',
      );
    }
    return (select(salesInvoices)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified sales invoices as synced.
  Future<int> markInvoicesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markInvoicesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(salesInvoices)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const SalesInvoicesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all sales invoice items pending synchronization.
  Future<List<SalesInvoiceItem>> getPendingSyncInvoiceItems(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncInvoiceItems requires businessId.',
      );
    }
    return (select(salesInvoiceItems)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified sales invoice items as synced.
  Future<int> markInvoiceItemsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markInvoiceItemsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(salesInvoiceItems)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const SalesInvoiceItemsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all customer receivables pending synchronization.
  Future<List<CustomerReceivable>> getPendingSyncCustomerReceivables(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncCustomerReceivables requires businessId.',
      );
    }
    return (select(customerReceivables)..where(
          (r) =>
              r.businessId.equals(businessId) &
              r.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified customer receivables as synced.
  Future<int> markCustomerReceivablesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markCustomerReceivablesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(customerReceivables)
          ..where((r) => r.id.isIn(ids) & r.businessId.equals(businessId)))
        .write(const CustomerReceivablesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all receivable entries pending synchronization.
  Future<List<ReceivableEntry>> getPendingSyncReceivableEntries(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncReceivableEntries requires businessId.',
      );
    }
    return (select(receivableEntries)..where(
          (e) =>
              e.businessId.equals(businessId) &
              e.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified receivable entries as synced.
  Future<int> markReceivableEntriesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markReceivableEntriesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(receivableEntries)
          ..where((e) => e.id.isIn(ids) & e.businessId.equals(businessId)))
        .write(const ReceivableEntriesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all sales returns pending synchronization.
  Future<List<SalesReturn>> getPendingSyncSalesReturns(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncSalesReturns requires businessId.',
      );
    }
    return (select(salesReturns)..where(
          (r) =>
              r.businessId.equals(businessId) &
              r.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified sales returns as synced.
  Future<int> markSalesReturnsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markSalesReturnsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(salesReturns)
          ..where((r) => r.id.isIn(ids) & r.businessId.equals(businessId)))
        .write(const SalesReturnsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all sales return items pending synchronization.
  Future<List<SalesReturnItem>> getPendingSyncSalesReturnItems(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncSalesReturnItems requires businessId.',
      );
    }
    return (select(salesReturnItems)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified sales return items as synced.
  Future<int> markSalesReturnItemsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markSalesReturnItemsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(salesReturnItems)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const SalesReturnItemsCompanion(syncStatus: Value('synced')));
  }
}
