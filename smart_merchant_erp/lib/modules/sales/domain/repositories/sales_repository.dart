import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';

/// Contract for Sales domain data operations.
/// Isolates application use cases from Drift ORM and SQLite specifics while
/// preserving multi-tenant (`businessId`), customer receivable ledger, and reactive stream semantics.
abstract class SalesRepository {
  // Channels
  Future<ChannelEntity?> getChannelById(String id, String businessId);
  Future<List<ChannelEntity>> listChannels(ChannelFilter filter);
  Stream<List<ChannelEntity>> watchChannels(ChannelFilter filter);
  Future<int> insertChannel(ChannelsCompanion companion);
  Future<bool> updateChannel(ChannelsCompanion companion);
  Future<List<ChannelEntity>> getPendingSyncChannels(String businessId);
  Future<int> markChannelsAsSynced(List<String> ids, String businessId);

  // Customers
  Future<Customer?> getCustomerById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<Customer>> listCustomers(CustomerFilter filter);
  Stream<List<Customer>> watchCustomers(CustomerFilter filter);
  Future<int> insertCustomer(CustomersCompanion companion);
  Future<bool> updateCustomer(CustomersCompanion companion);
  Future<bool> softDeleteCustomer(String id, String businessId);
  Future<bool> restoreCustomer(String id, String businessId);
  Future<CustomerBalanceSummary?> getCustomerBalanceSummary(
    String customerId,
    String businessId,
  );
  Future<List<Customer>> getPendingSyncCustomers(String businessId);
  Future<int> markCustomersAsSynced(List<String> ids, String businessId);

  // Orders
  Future<OrderEntity?> getOrderById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<OrderWithItems?> getOrderWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<OrderEntity>> listOrders(OrderFilter filter);
  Stream<List<OrderEntity>> watchOrders(OrderFilter filter);
  Future<void> recordOrderWithItems({
    required OrdersCompanion order,
    required List<OrderItemsCompanion> items,
  });
  Future<bool> updateOrderStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<bool> softDeleteOrder(String id, String businessId);
  Future<bool> restoreOrder(String id, String businessId);
  Future<List<OrderEntity>> getPendingSyncOrders(String businessId);
  Future<int> markOrdersAsSynced(List<String> ids, String businessId);
  Future<List<OrderItemEntity>> getPendingSyncOrderItems(String businessId);
  Future<int> markOrderItemsAsSynced(List<String> ids, String businessId);

  // Invoices & Receivables
  Future<SalesInvoice?> getInvoiceById(String id, String businessId);
  Future<SalesInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  );
  Future<List<SalesInvoice>> listInvoices(SalesInvoiceFilter filter);
  Stream<List<SalesInvoice>> watchInvoices(SalesInvoiceFilter filter);
  Future<void> recordInvoiceWithItemsAndReceivable({
    required SalesInvoicesCompanion invoice,
    required List<SalesInvoiceItemsCompanion> items,
    CustomerReceivablesCompanion? receivable,
  });
  Future<bool> updateInvoiceStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<bool> updateInvoicePaymentStatus(
    String id,
    String businessId,
    String newPaymentStatus,
  );
  Future<CustomerReceivable?> getReceivableById(String id, String businessId);
  Future<CustomerReceivableWithEntries?> getReceivableWithEntriesById(
    String id,
    String businessId,
  );
  Future<List<CustomerReceivable>> listReceivables(
    CustomerReceivableFilter filter,
  );
  Stream<List<CustomerReceivable>> watchReceivables(
    CustomerReceivableFilter filter,
  );
  Future<void> recordReceivableEntry(
    ReceivableEntriesCompanion entry, {
    required String customerReceivableId,
    required String businessId,
    required double newPaidAmount,
    required double newRemainingAmount,
    required double newBasePaidAmount,
    required double newBaseRemainingAmount,
    required String newStatus,
  });
  Future<List<SalesInvoice>> getPendingSyncInvoices(String businessId);
  Future<int> markInvoicesAsSynced(List<String> ids, String businessId);
  Future<List<SalesInvoiceItem>> getPendingSyncInvoiceItems(String businessId);
  Future<int> markInvoiceItemsAsSynced(List<String> ids, String businessId);
  Future<List<CustomerReceivable>> getPendingSyncCustomerReceivables(
    String businessId,
  );
  Future<int> markCustomerReceivablesAsSynced(
    List<String> ids,
    String businessId,
  );
  Future<List<ReceivableEntry>> getPendingSyncReceivableEntries(
    String businessId,
  );
  Future<int> markReceivableEntriesAsSynced(
    List<String> ids,
    String businessId,
  );

  // Sales Returns
  Future<SalesReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<SalesReturnWithItems?> getReturnWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<SalesReturn>> listReturns(SalesReturnFilter filter);
  Stream<List<SalesReturn>> watchReturns(SalesReturnFilter filter);
  Future<void> recordReturnWithItems({
    required SalesReturnsCompanion salesReturn,
    required List<SalesReturnItemsCompanion> items,
  });
  Future<bool> updateReturnStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<bool> softDeleteReturn(String id, String businessId);
  Future<bool> restoreReturn(String id, String businessId);
  Future<List<SalesReturn>> getPendingSyncSalesReturns(String businessId);
  Future<int> markSalesReturnsAsSynced(List<String> ids, String businessId);
  Future<List<SalesReturnItem>> getPendingSyncSalesReturnItems(
    String businessId,
  );
  Future<int> markSalesReturnItemsAsSynced(List<String> ids, String businessId);
}
