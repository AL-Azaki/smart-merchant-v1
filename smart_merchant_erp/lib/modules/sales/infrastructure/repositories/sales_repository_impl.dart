import 'package:injectable/injectable.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/sales_dao.dart';

@LazySingleton(as: SalesRepository)
class SalesRepositoryImpl implements SalesRepository {
  final SalesDao _dao;

  SalesRepositoryImpl(this._dao);

  // Channels
  @override
  Future<ChannelEntity?> getChannelById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getChannelById(id, businessId));
  }

  @override
  Future<List<ChannelEntity>> listChannels(ChannelFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listChannels(filter));
  }

  @override
  Stream<List<ChannelEntity>> watchChannels(ChannelFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchChannels(filter));
  }

  @override
  Future<int> insertChannel(ChannelsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertChannel(companion));
  }

  @override
  Future<bool> updateChannel(ChannelsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateChannel(companion));
  }

  @override
  Future<List<ChannelEntity>> getPendingSyncChannels(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncChannels(businessId),
    );
  }

  @override
  Future<int> markChannelsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markChannelsAsSynced(ids, businessId),
    );
  }

  // Customers
  @override
  Future<Customer?> getCustomerById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getCustomerById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<List<Customer>> listCustomers(CustomerFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listCustomers(filter));
  }

  @override
  Stream<List<Customer>> watchCustomers(CustomerFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchCustomers(filter));
  }

  @override
  Future<int> insertCustomer(CustomersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertCustomer(companion));
  }

  @override
  Future<bool> updateCustomer(CustomersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateCustomer(companion));
  }

  @override
  Future<bool> softDeleteCustomer(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteCustomer(id, businessId),
    );
  }

  @override
  Future<bool> restoreCustomer(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreCustomer(id, businessId));
  }

  @override
  Future<CustomerBalanceSummary?> getCustomerBalanceSummary(
    String customerId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getCustomerBalanceSummary(customerId, businessId),
    );
  }

  @override
  Future<List<Customer>> getPendingSyncCustomers(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncCustomers(businessId),
    );
  }

  @override
  Future<int> markCustomersAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markCustomersAsSynced(ids, businessId),
    );
  }

  // Orders
  @override
  Future<OrderEntity?> getOrderById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getOrderById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<OrderWithItems?> getOrderWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getOrderWithItemsById(
        id,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<OrderEntity>> listOrders(OrderFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listOrders(filter));
  }

  @override
  Stream<List<OrderEntity>> watchOrders(OrderFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchOrders(filter));
  }

  @override
  Future<void> recordOrderWithItems({
    required OrdersCompanion order,
    required List<OrderItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordOrderWithItems(order: order, items: items),
    );
  }

  @override
  Future<bool> updateOrderStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateOrderStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<bool> softDeleteOrder(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.softDeleteOrder(id, businessId));
  }

  @override
  Future<bool> restoreOrder(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreOrder(id, businessId));
  }

  @override
  Future<List<OrderEntity>> getPendingSyncOrders(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncOrders(businessId),
    );
  }

  @override
  Future<int> markOrdersAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markOrdersAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<OrderItemEntity>> getPendingSyncOrderItems(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncOrderItems(businessId),
    );
  }

  @override
  Future<int> markOrderItemsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markOrderItemsAsSynced(ids, businessId),
    );
  }

  // Invoices & Receivables
  @override
  Future<SalesInvoice?> getInvoiceById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getInvoiceById(id, businessId));
  }

  @override
  Future<SalesInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getInvoiceWithItemsById(id, businessId),
    );
  }

  @override
  Future<List<SalesInvoice>> listInvoices(SalesInvoiceFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listInvoices(filter));
  }

  @override
  Stream<List<SalesInvoice>> watchInvoices(SalesInvoiceFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchInvoices(filter));
  }

  @override
  Future<void> recordInvoiceWithItemsAndReceivable({
    required SalesInvoicesCompanion invoice,
    required List<SalesInvoiceItemsCompanion> items,
    CustomerReceivablesCompanion? receivable,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordInvoiceWithItemsAndReceivable(
        invoice: invoice,
        items: items,
        receivable: receivable,
      ),
    );
  }

  @override
  Future<bool> updateInvoiceStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateInvoiceStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<bool> updateInvoicePaymentStatus(
    String id,
    String businessId,
    String newPaymentStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateInvoicePaymentStatus(id, businessId, newPaymentStatus),
    );
  }

  @override
  Future<CustomerReceivable?> getReceivableById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getReceivableById(id, businessId),
    );
  }

  @override
  Future<CustomerReceivableWithEntries?> getReceivableWithEntriesById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getReceivableWithEntriesById(id, businessId),
    );
  }

  @override
  Future<List<CustomerReceivable>> listReceivables(
    CustomerReceivableFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listReceivables(filter));
  }

  @override
  Stream<List<CustomerReceivable>> watchReceivables(
    CustomerReceivableFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchReceivables(filter));
  }

  @override
  Future<void> recordReceivableEntry(
    ReceivableEntriesCompanion entry, {
    required String customerReceivableId,
    required String businessId,
    required double newPaidAmount,
    required double newRemainingAmount,
    required double newBasePaidAmount,
    required double newBaseRemainingAmount,
    required String newStatus,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordReceivableEntry(
        entry,
        customerReceivableId: customerReceivableId,
        businessId: businessId,
        newPaidAmount: newPaidAmount,
        newRemainingAmount: newRemainingAmount,
        newBasePaidAmount: newBasePaidAmount,
        newBaseRemainingAmount: newBaseRemainingAmount,
        newStatus: newStatus,
      ),
    );
  }

  @override
  Future<List<SalesInvoice>> getPendingSyncInvoices(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncInvoices(businessId),
    );
  }

  @override
  Future<int> markInvoicesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markInvoicesAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<SalesInvoiceItem>> getPendingSyncInvoiceItems(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncInvoiceItems(businessId),
    );
  }

  @override
  Future<int> markInvoiceItemsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markInvoiceItemsAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<CustomerReceivable>> getPendingSyncCustomerReceivables(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncCustomerReceivables(businessId),
    );
  }

  @override
  Future<int> markCustomerReceivablesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markCustomerReceivablesAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<ReceivableEntry>> getPendingSyncReceivableEntries(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncReceivableEntries(businessId),
    );
  }

  @override
  Future<int> markReceivableEntriesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markReceivableEntriesAsSynced(ids, businessId),
    );
  }

  // Sales Returns
  @override
  Future<SalesReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getReturnById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<SalesReturnWithItems?> getReturnWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getReturnWithItemsById(
        id,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<SalesReturn>> listReturns(SalesReturnFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listReturns(filter));
  }

  @override
  Stream<List<SalesReturn>> watchReturns(SalesReturnFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchReturns(filter));
  }

  @override
  Future<void> recordReturnWithItems({
    required SalesReturnsCompanion salesReturn,
    required List<SalesReturnItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordReturnWithItems(salesReturn: salesReturn, items: items),
    );
  }

  @override
  Future<bool> updateReturnStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateReturnStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<bool> softDeleteReturn(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteReturn(id, businessId),
    );
  }

  @override
  Future<bool> restoreReturn(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreReturn(id, businessId));
  }

  @override
  Future<List<SalesReturn>> getPendingSyncSalesReturns(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncSalesReturns(businessId),
    );
  }

  @override
  Future<int> markSalesReturnsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markSalesReturnsAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<SalesReturnItem>> getPendingSyncSalesReturnItems(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncSalesReturnItems(businessId),
    );
  }

  @override
  Future<int> markSalesReturnItemsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markSalesReturnItemsAsSynced(ids, businessId),
    );
  }
}
