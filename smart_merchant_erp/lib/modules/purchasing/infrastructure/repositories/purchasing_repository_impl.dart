import 'package:injectable/injectable.dart';
import '../../domain/repositories/purchasing_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/purchasing_dao.dart';

@LazySingleton(as: PurchasingRepository)
class PurchasingRepositoryImpl implements PurchasingRepository {
  final PurchasingDao _dao;

  PurchasingRepositoryImpl(this._dao);

  // Suppliers
  @override
  Future<Supplier?> getSupplierById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getSupplierById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<List<Supplier>> listSuppliers(SupplierFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listSuppliers(filter));
  }

  @override
  Stream<List<Supplier>> watchSuppliers(SupplierFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchSuppliers(filter));
  }

  @override
  Future<int> insertSupplier(SuppliersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertSupplier(companion));
  }

  @override
  Future<bool> updateSupplier(SuppliersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateSupplier(companion));
  }

  @override
  Future<bool> softDeleteSupplier(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteSupplier(id, businessId),
    );
  }

  @override
  Future<bool> restoreSupplier(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreSupplier(id, businessId));
  }

  @override
  Future<SupplierBalanceSummary?> getSupplierBalanceSummary(
    String supplierId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getSupplierBalanceSummary(supplierId, businessId),
    );
  }

  @override
  Future<List<Supplier>> getPendingSyncSuppliers(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncSuppliers(businessId),
    );
  }

  @override
  Future<int> markSuppliersAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markSuppliersAsSynced(ids, businessId),
    );
  }

  // Purchase Invoices & Payables
  @override
  Future<PurchaseInvoice?> getInvoiceById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getInvoiceById(id, businessId));
  }

  @override
  Future<PurchaseInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getInvoiceWithItemsById(id, businessId),
    );
  }

  @override
  Future<List<PurchaseInvoice>> listInvoices(PurchaseInvoiceFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listInvoices(filter));
  }

  @override
  Stream<List<PurchaseInvoice>> watchInvoices(PurchaseInvoiceFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchInvoices(filter));
  }

  @override
  Future<void> recordInvoiceWithItemsAndPayable({
    required PurchaseInvoicesCompanion invoice,
    required List<PurchaseInvoiceItemsCompanion> items,
    SupplierPayablesCompanion? payable,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordInvoiceWithItemsAndPayable(
        invoice: invoice,
        items: items,
        payable: payable,
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
  Future<SupplierPayable?> getPayableById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getPayableById(id, businessId));
  }

  @override
  Future<SupplierPayableWithEntries?> getPayableWithEntriesById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPayableWithEntriesById(id, businessId),
    );
  }

  @override
  Future<List<SupplierPayable>> listPayables(SupplierPayableFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listPayables(filter));
  }

  @override
  Stream<List<SupplierPayable>> watchPayables(SupplierPayableFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchPayables(filter));
  }

  @override
  Future<void> recordPayableEntry({
    required PayableEntriesCompanion entry,
    required String supplierPayableId,
    required String businessId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordPayableEntry(
        entry: entry,
        supplierPayableId: supplierPayableId,
        businessId: businessId,
      ),
    );
  }

  @override
  Future<List<PurchaseInvoice>> getPendingSyncInvoices(String businessId) {
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
  Future<List<PurchaseInvoiceItem>> getPendingSyncInvoiceItems(
    String businessId,
  ) {
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
  Future<List<SupplierPayable>> getPendingSyncPayables(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncPayables(businessId),
    );
  }

  @override
  Future<int> markPayablesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markPayablesAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<PayableEntry>> getPendingSyncPayableEntries(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncPayableEntries(businessId),
    );
  }

  @override
  Future<int> markPayableEntriesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markPayableEntriesAsSynced(ids, businessId),
    );
  }

  // Purchase Returns
  @override
  Future<PurchaseReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getReturnById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<PurchaseReturnWithItems?> getReturnWithItemsById(
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
  Future<List<PurchaseReturn>> listReturns(PurchaseReturnFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listReturns(filter));
  }

  @override
  Stream<List<PurchaseReturn>> watchReturns(PurchaseReturnFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchReturns(filter));
  }

  @override
  Future<void> recordReturnWithItems({
    required PurchaseReturnsCompanion returnHeader,
    required List<PurchaseReturnItemsCompanion> items,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordReturnWithItems(
        purchaseReturn: returnHeader,
        items: items,
      ),
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
  Future<List<PurchaseReturn>> getPendingSyncReturns(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncReturns(businessId),
    );
  }

  @override
  Future<int> markReturnsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markReturnsAsSynced(ids, businessId),
    );
  }

  @override
  Future<List<PurchaseReturnItem>> getPendingSyncReturnItems(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncReturnItems(businessId),
    );
  }

  @override
  Future<int> markReturnItemsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markReturnItemsAsSynced(ids, businessId),
    );
  }
}
