import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/purchasing_dao.dart';

/// Contract for Purchasing domain data operations.
abstract class PurchasingRepository {
  // Suppliers
  Future<Supplier?> getSupplierById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<Supplier>> listSuppliers(SupplierFilter filter);
  Stream<List<Supplier>> watchSuppliers(SupplierFilter filter);
  Future<int> insertSupplier(SuppliersCompanion companion);
  Future<bool> updateSupplier(SuppliersCompanion companion);
  Future<bool> softDeleteSupplier(String id, String businessId);
  Future<bool> restoreSupplier(String id, String businessId);
  Future<SupplierBalanceSummary?> getSupplierBalanceSummary(
    String supplierId,
    String businessId,
  );
  Future<List<Supplier>> getPendingSyncSuppliers(String businessId);
  Future<int> markSuppliersAsSynced(List<String> ids, String businessId);

  // Purchase Invoices & Payables
  Future<PurchaseInvoice?> getInvoiceById(String id, String businessId);
  Future<PurchaseInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  );
  Future<List<PurchaseInvoice>> listInvoices(PurchaseInvoiceFilter filter);
  Stream<List<PurchaseInvoice>> watchInvoices(PurchaseInvoiceFilter filter);
  Future<void> recordInvoiceWithItemsAndPayable({
    required PurchaseInvoicesCompanion invoice,
    required List<PurchaseInvoiceItemsCompanion> items,
    SupplierPayablesCompanion? payable,
  });
  Future<bool> updateInvoiceStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<SupplierPayable?> getPayableById(String id, String businessId);
  Future<SupplierPayableWithEntries?> getPayableWithEntriesById(
    String id,
    String businessId,
  );
  Future<List<SupplierPayable>> listPayables(SupplierPayableFilter filter);
  Stream<List<SupplierPayable>> watchPayables(SupplierPayableFilter filter);
  Future<void> recordPayableEntry({
    required PayableEntriesCompanion entry,
    required String supplierPayableId,
    required String businessId,
  });
  Future<List<PurchaseInvoice>> getPendingSyncInvoices(String businessId);
  Future<int> markInvoicesAsSynced(List<String> ids, String businessId);
  Future<List<PurchaseInvoiceItem>> getPendingSyncInvoiceItems(
    String businessId,
  );
  Future<int> markInvoiceItemsAsSynced(List<String> ids, String businessId);
  Future<List<SupplierPayable>> getPendingSyncPayables(String businessId);
  Future<int> markPayablesAsSynced(List<String> ids, String businessId);
  Future<List<PayableEntry>> getPendingSyncPayableEntries(String businessId);
  Future<int> markPayableEntriesAsSynced(List<String> ids, String businessId);

  // Purchase Returns
  Future<PurchaseReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<PurchaseReturnWithItems?> getReturnWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<PurchaseReturn>> listReturns(PurchaseReturnFilter filter);
  Stream<List<PurchaseReturn>> watchReturns(PurchaseReturnFilter filter);
  Future<void> recordReturnWithItems({
    required PurchaseReturnsCompanion returnHeader,
    required List<PurchaseReturnItemsCompanion> items,
  });
  Future<bool> updateReturnStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<bool> softDeleteReturn(String id, String businessId);
  Future<bool> restoreReturn(String id, String businessId);
  Future<List<PurchaseReturn>> getPendingSyncReturns(String businessId);
  Future<int> markReturnsAsSynced(List<String> ids, String businessId);
  Future<List<PurchaseReturnItem>> getPendingSyncReturnItems(String businessId);
  Future<int> markReturnItemsAsSynced(List<String> ids, String businessId);
}
