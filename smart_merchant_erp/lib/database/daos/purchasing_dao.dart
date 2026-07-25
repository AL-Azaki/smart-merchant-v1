import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/catalog/products_table.dart';
import '../tables/catalog/product_units_table.dart';
import '../tables/catalog/product_variants_table.dart';
import '../tables/core/branches_table.dart';
import '../tables/inventory/warehouses_table.dart';
import '../tables/purchasing/payable_entries_table.dart';
import '../tables/purchasing/purchase_invoice_items_table.dart';
import '../tables/purchasing/purchase_invoices_table.dart';
import '../tables/purchasing/purchase_return_items_table.dart';
import '../tables/purchasing/purchase_returns_table.dart';
import '../tables/purchasing/supplier_payables_table.dart';
import '../tables/purchasing/suppliers_table.dart';
import 'dao_exceptions.dart';

part 'purchasing_dao.g.dart';

/// Filter DTO for [Suppliers] queries.
class SupplierFilter {
  final String businessId;
  final bool? isActive;
  final bool includeDeleted;
  final String? searchQuery;
  final int limit;
  final int offset;

  const SupplierFilter({
    required this.businessId,
    this.isActive,
    this.includeDeleted = false,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [PurchaseInvoices] queries.
class PurchaseInvoiceFilter {
  final String businessId;
  final String? branchId;
  final String? supplierId;
  final String? status;
  final String? paymentStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const PurchaseInvoiceFilter({
    required this.businessId,
    this.branchId,
    this.supplierId,
    this.status,
    this.paymentStatus,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [PurchaseInvoice] with its [PurchaseInvoiceItem]s.
class PurchaseInvoiceWithItems {
  final PurchaseInvoice invoice;
  final List<PurchaseInvoiceItem> items;

  const PurchaseInvoiceWithItems({required this.invoice, required this.items});
}

/// Filter DTO for [PurchaseReturns] queries.
class PurchaseReturnFilter {
  final String businessId;
  final String? branchId;
  final String? purchaseInvoiceId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeDeleted;
  final int limit;
  final int offset;

  const PurchaseReturnFilter({
    required this.businessId,
    this.branchId,
    this.purchaseInvoiceId,
    this.status,
    this.startDate,
    this.endDate,
    this.includeDeleted = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [PurchaseReturn] with its [PurchaseReturnItem]s.
class PurchaseReturnWithItems {
  final PurchaseReturn purchaseReturn;
  final List<PurchaseReturnItem> items;

  const PurchaseReturnWithItems({
    required this.purchaseReturn,
    required this.items,
  });
}

/// Filter DTO for [SupplierPayables] queries.
class SupplierPayableFilter {
  final String businessId;
  final String? supplierId;
  final String? purchaseInvoiceId;
  final String? status;
  final bool onlyOverdue;
  final int limit;
  final int offset;

  const SupplierPayableFilter({
    required this.businessId,
    this.supplierId,
    this.purchaseInvoiceId,
    this.status,
    this.onlyOverdue = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [SupplierPayable] with its [PayableEntry]s.
class SupplierPayableWithEntries {
  final SupplierPayable payable;
  final List<PayableEntry> entries;

  const SupplierPayableWithEntries({
    required this.payable,
    required this.entries,
  });
}

/// Summary DTO for supplier financial position and status.
class SupplierBalanceSummary {
  final String supplierId;
  final String supplierName;
  final double creditLimit;
  final double openingBalance;
  final double totalPayables;
  final double totalPaid;
  final double totalRemaining;
  final String? openingBalanceType;

  const SupplierBalanceSummary({
    required this.supplierId,
    required this.supplierName,
    required this.creditLimit,
    required this.openingBalance,
    required this.totalPayables,
    required this.totalPaid,
    required this.totalRemaining,
    this.openingBalanceType,
  });
}

/// Module-Driven DAO for Domain: Purchasing & Suppliers (Phase 05).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), branch scoping (`branchId`), soft-delete rules (`deletedAt`),
/// and atomic transactional persistence for:
/// [Suppliers], [SupplierPayables], [PayableEntries], [PurchaseInvoices], [PurchaseInvoiceItems],
/// [PurchaseReturns], and [PurchaseReturnItems].
@DriftAccessor(
  tables: [
    Suppliers,
    SupplierPayables,
    PayableEntries,
    PurchaseInvoices,
    PurchaseInvoiceItems,
    PurchaseReturns,
    PurchaseReturnItems,
    Products,
    ProductVariants,
    ProductUnits,
    Branches,
    Warehouses,
  ],
)
class PurchasingDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasingDaoMixin {
  PurchasingDao(super.db);

  // ============================================================================
  // 1. SUPPLIERS OPERATIONS (Tenant Scoped, Soft Delete Support)
  // ============================================================================

  /// Retrieves a supplier by ID within a business.
  Future<Supplier?> getSupplierById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getSupplierById requires businessId.',
      );
    }
    final query = select(suppliers)
      ..where((s) => s.id.equals(id) & s.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((s) => s.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists suppliers matching the provided filter with pagination.
  Future<List<Supplier>> listSuppliers(SupplierFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listSuppliers requires businessId.');
    }
    final query = select(suppliers)
      ..where((s) => s.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((s) => s.deletedAt.isNull());
    }
    if (filter.isActive != null) {
      query.where((s) => s.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim().toLowerCase()}%';
      query.where(
        (s) =>
            s.supplierName.lower().like(q) |
            s.phone.lower().like(q) |
            s.contactPerson.lower().like(q),
      );
    }
    query.orderBy([(s) => OrderingTerm(expression: s.supplierName)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of suppliers matching the provided filter.
  Stream<List<Supplier>> watchSuppliers(SupplierFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchSuppliers requires businessId.');
    }
    final query = select(suppliers)
      ..where((s) => s.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((s) => s.deletedAt.isNull());
    }
    if (filter.isActive != null) {
      query.where((s) => s.isActive.equals(filter.isActive!));
    }
    query.orderBy([(s) => OrderingTerm(expression: s.supplierName)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new supplier.
  Future<int> insertSupplier(SuppliersCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertSupplier requires businessId.');
    }
    return into(suppliers).insert(companion);
  }

  /// Updates an existing supplier.
  Future<bool> updateSupplier(SuppliersCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateSupplier requires id and businessId.',
      );
    }
    return (update(suppliers)..where(
          (s) =>
              s.id.equals(companion.id.value) &
              s.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Soft deletes a supplier by setting `deletedAt` and `syncStatus = 'pending_delete'`.
  Future<bool> softDeleteSupplier(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteSupplier requires businessId.',
      );
    }
    return (update(suppliers)..where(
          (s) =>
              s.id.equals(id) &
              s.businessId.equals(businessId) &
              s.deletedAt.isNull(),
        ))
        .write(
          SuppliersCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            isActive: const Value(false),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted supplier.
  Future<bool> restoreSupplier(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'restoreSupplier requires businessId.',
      );
    }
    return (update(suppliers)..where(
          (s) =>
              s.id.equals(id) &
              s.businessId.equals(businessId) &
              s.deletedAt.isNotNull(),
        ))
        .write(
          SuppliersCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Calculates and returns financial balance summary for a supplier.
  Future<SupplierBalanceSummary?> getSupplierBalanceSummary(
    String supplierId,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getSupplierBalanceSummary requires businessId.',
      );
    }
    final supplier = await getSupplierById(supplierId, businessId);
    if (supplier == null) {
      return null;
    }

    final payablesList =
        await (select(supplierPayables)..where(
              (p) =>
                  p.supplierId.equals(supplierId) &
                  p.businessId.equals(businessId),
            ))
            .get();

    double totalPayables = 0.0;
    double totalPaid = 0.0;
    double totalRemaining = 0.0;

    for (final p in payablesList) {
      totalPayables += p.originalAmount;
      totalPaid += p.paidAmount;
      totalRemaining += p.remainingAmount;
    }

    return SupplierBalanceSummary(
      supplierId: supplier.id,
      supplierName: supplier.supplierName,
      creditLimit: supplier.creditLimit,
      openingBalance: supplier.openingBalance,
      openingBalanceType: supplier.openingBalanceType,
      totalPayables: totalPayables,
      totalPaid: totalPaid,
      totalRemaining: totalRemaining,
    );
  }

  // ============================================================================
  // 2. PURCHASE INVOICES & ITEMS OPERATIONS (Tenant & Branch Scoped, Atomic)
  // ============================================================================

  /// Retrieves a purchase invoice by ID.
  Future<PurchaseInvoice?> getInvoiceById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getInvoiceById requires businessId.');
    }
    return (select(purchaseInvoices)
          ..where((i) => i.id.equals(id) & i.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a purchase invoice along with its invoice line items.
  Future<PurchaseInvoiceWithItems?> getInvoiceWithItemsById(
    String id,
    String businessId,
  ) async {
    final invoice = await getInvoiceById(id, businessId);
    if (invoice == null) {
      return null;
    }

    final items =
        await (select(purchaseInvoiceItems)..where(
              (i) =>
                  i.purchaseInvoiceId.equals(id) &
                  i.businessId.equals(businessId),
            ))
            .get();

    return PurchaseInvoiceWithItems(invoice: invoice, items: items);
  }

  /// Lists purchase invoices matching the provided filter with pagination.
  Future<List<PurchaseInvoice>> listInvoices(PurchaseInvoiceFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listInvoices requires businessId.');
    }
    final query = select(purchaseInvoices)
      ..where((i) => i.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((i) => i.branchId.equals(filter.branchId!));
    }
    if (filter.supplierId != null && filter.supplierId!.trim().isNotEmpty) {
      query.where((i) => i.supplierId.equals(filter.supplierId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((i) => i.status.equals(filter.status!));
    }
    if (filter.paymentStatus != null &&
        filter.paymentStatus!.trim().isNotEmpty) {
      query.where((i) => i.paymentStatus.equals(filter.paymentStatus!));
    }
    if (filter.startDate != null) {
      query.where(
        (i) => i.purchaseDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where((i) => i.purchaseDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (i) => OrderingTerm(expression: i.purchaseDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of purchase invoices matching the provided filter.
  Stream<List<PurchaseInvoice>> watchInvoices(PurchaseInvoiceFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchInvoices requires businessId.');
    }
    final query = select(purchaseInvoices)
      ..where((i) => i.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((i) => i.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((i) => i.status.equals(filter.status!));
    }
    query.orderBy([
      (i) => OrderingTerm(expression: i.purchaseDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically records a purchase invoice, all its line items, and optional supplier payable record
  /// plus initial payment allocation entry inside a single database transaction.
  Future<void> recordInvoiceWithItemsAndPayable({
    required PurchaseInvoicesCompanion invoice,
    required List<PurchaseInvoiceItemsCompanion> items,
    SupplierPayablesCompanion? payable,
    PayableEntriesCompanion? initialEntry,
  }) async {
    if (!invoice.businessId.present ||
        invoice.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordInvoiceWithItemsAndPayable requires businessId on invoice.',
      );
    }
    final busId = invoice.businessId.value;

    await transaction(() async {
      await into(purchaseInvoices).insert(invoice);

      for (final item in items) {
        if (!item.businessId.present || item.businessId.value != busId) {
          throw const TenantScopingException(
            'All invoice items must match invoice businessId.',
          );
        }
        await into(purchaseInvoiceItems).insert(item);
      }

      if (payable != null) {
        if (!payable.businessId.present || payable.businessId.value != busId) {
          throw const TenantScopingException(
            'Payable businessId must match invoice businessId.',
          );
        }
        await into(supplierPayables).insert(payable);

        if (initialEntry != null) {
          if (!initialEntry.businessId.present ||
              initialEntry.businessId.value != busId) {
            throw const TenantScopingException(
              'Payable entry businessId must match invoice businessId.',
            );
          }
          await into(payableEntries).insert(initialEntry);
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
    return (update(purchaseInvoices)
          ..where((i) => i.id.equals(id) & i.businessId.equals(businessId)))
        .write(
          PurchaseInvoicesCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 3. SUPPLIER PAYABLES & PAYABLE ENTRIES OPERATIONS (Tenant Scoped, Atomic)
  // ============================================================================

  /// Retrieves a supplier payable by ID within a business.
  Future<SupplierPayable?> getPayableById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getPayableById requires businessId.');
    }
    return (select(supplierPayables)
          ..where((p) => p.id.equals(id) & p.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a supplier payable along with all of its payable allocation entries.
  Future<SupplierPayableWithEntries?> getPayableWithEntriesById(
    String id,
    String businessId,
  ) async {
    final payable = await getPayableById(id, businessId);
    if (payable == null) {
      return null;
    }

    final entries =
        await (select(payableEntries)..where(
              (e) =>
                  e.supplierPayableId.equals(id) &
                  e.businessId.equals(businessId),
            ))
            .get();

    return SupplierPayableWithEntries(payable: payable, entries: entries);
  }

  /// Lists supplier payables matching the provided filter with pagination.
  Future<List<SupplierPayable>> listPayables(SupplierPayableFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listPayables requires businessId.');
    }
    final query = select(supplierPayables)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.supplierId != null && filter.supplierId!.trim().isNotEmpty) {
      query.where((p) => p.supplierId.equals(filter.supplierId!));
    }
    if (filter.purchaseInvoiceId != null &&
        filter.purchaseInvoiceId!.trim().isNotEmpty) {
      query.where((p) => p.purchaseInvoiceId.equals(filter.purchaseInvoiceId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    if (filter.onlyOverdue) {
      final now = DateTime.now();
      query.where(
        (p) =>
            p.dueDate.isNotNull() &
            p.dueDate.isSmallerOrEqualValue(now) &
            p.status.isNotIn(['Paid']),
      );
    }

    query.orderBy([(p) => OrderingTerm(expression: p.dueDate)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of supplier payables matching the provided filter.
  Stream<List<SupplierPayable>> watchPayables(SupplierPayableFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchPayables requires businessId.');
    }
    final query = select(supplierPayables)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.supplierId != null && filter.supplierId!.trim().isNotEmpty) {
      query.where((p) => p.supplierId.equals(filter.supplierId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.dueDate)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically records a payment or adjustment entry against a supplier payable and updates
  /// `paidAmount`, `remainingAmount`, and settlement status (`Partial` / `Paid`) synchronously.
  Future<void> recordPayableEntry({
    required PayableEntriesCompanion entry,
    required String supplierPayableId,
    required String businessId,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'recordPayableEntry requires businessId.',
      );
    }
    if (!entry.businessId.present || entry.businessId.value != businessId) {
      throw const TenantScopingException(
        'Entry businessId must match the parent payable businessId.',
      );
    }

    await transaction(() async {
      final payable =
          await (select(supplierPayables)..where(
                (p) =>
                    p.id.equals(supplierPayableId) &
                    p.businessId.equals(businessId),
              ))
              .getSingleOrNull();

      if (payable == null) {
        throw const RecordNotFoundException(
          'Target supplier payable not found for payment allocation.',
        );
      }

      await into(payableEntries).insert(entry);

      final newPaidAmount = payable.paidAmount + entry.amount.value;
      final newBasePaidAmount = payable.basePaidAmount + entry.baseAmount.value;
      final newRemaining = payable.originalAmount - newPaidAmount;
      final newBaseRemaining = payable.baseOriginalAmount - newBasePaidAmount;

      final newStatus = newRemaining <= 0.001 ? 'Paid' : 'Partial';

      await (update(supplierPayables)..where(
            (p) =>
                p.id.equals(supplierPayableId) &
                p.businessId.equals(businessId),
          ))
          .write(
            SupplierPayablesCompanion(
              paidAmount: Value(newPaidAmount),
              basePaidAmount: Value(newBasePaidAmount),
              remainingAmount: Value(newRemaining < 0 ? 0.0 : newRemaining),
              baseRemainingAmount: Value(
                newBaseRemaining < 0 ? 0.0 : newBaseRemaining,
              ),
              status: Value(newStatus),
              lastPaymentDate: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              syncStatus: const Value('pending_update'),
            ),
          );
    });
  }

  // ============================================================================
  // 4. PURCHASE RETURNS & ITEMS OPERATIONS (Tenant & Branch Scoped, Soft Delete)
  // ============================================================================

  /// Retrieves a purchase return by ID within a business.
  Future<PurchaseReturn?> getReturnById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getReturnById requires businessId.');
    }
    final query = select(purchaseReturns)
      ..where((r) => r.id.equals(id) & r.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a purchase return along with all of its returned items.
  Future<PurchaseReturnWithItems?> getReturnWithItemsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) async {
    final purchaseReturn = await getReturnById(
      id,
      businessId,
      includeDeleted: includeDeleted,
    );
    if (purchaseReturn == null) {
      return null;
    }

    final items =
        await (select(purchaseReturnItems)..where(
              (i) =>
                  i.purchaseReturnId.equals(id) &
                  i.businessId.equals(businessId),
            ))
            .get();

    return PurchaseReturnWithItems(
      purchaseReturn: purchaseReturn,
      items: items,
    );
  }

  /// Lists purchase returns matching the provided filter with pagination.
  Future<List<PurchaseReturn>> listReturns(PurchaseReturnFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listReturns requires businessId.');
    }
    final query = select(purchaseReturns)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((r) => r.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((r) => r.branchId.equals(filter.branchId!));
    }
    if (filter.purchaseInvoiceId != null &&
        filter.purchaseInvoiceId!.trim().isNotEmpty) {
      query.where((r) => r.purchaseInvoiceId.equals(filter.purchaseInvoiceId!));
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

  /// Reactive stream of purchase returns matching the provided filter.
  Stream<List<PurchaseReturn>> watchReturns(PurchaseReturnFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchReturns requires businessId.');
    }
    final query = select(purchaseReturns)
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

  /// Atomically records a purchase return along with all of its returned line items inside a database transaction.
  Future<void> recordReturnWithItems({
    required PurchaseReturnsCompanion purchaseReturn,
    required List<PurchaseReturnItemsCompanion> items,
  }) async {
    if (!purchaseReturn.businessId.present ||
        purchaseReturn.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordReturnWithItems requires businessId on purchaseReturn.',
      );
    }
    final busId = purchaseReturn.businessId.value;

    await transaction(() async {
      await into(purchaseReturns).insert(purchaseReturn);

      for (final item in items) {
        if (!item.businessId.present || item.businessId.value != busId) {
          throw const TenantScopingException(
            'All return items must match return businessId.',
          );
        }
        await into(purchaseReturnItems).insert(item);
      }
    });
  }

  /// Updates the lifecycle status of a purchase return (`Draft`, `Posted`, `Reversed`).
  Future<bool> updateReturnStatus(String id, String businessId, String status) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateReturnStatus requires businessId.',
      );
    }
    return (update(purchaseReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNull(),
        ))
        .write(
          PurchaseReturnsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Soft deletes a purchase return.
  Future<bool> softDeleteReturn(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeleteReturn requires businessId.',
      );
    }
    return (update(purchaseReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNull(),
        ))
        .write(
          PurchaseReturnsCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted purchase return.
  Future<bool> restoreReturn(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('restoreReturn requires businessId.');
    }
    return (update(purchaseReturns)..where(
          (r) =>
              r.id.equals(id) &
              r.businessId.equals(businessId) &
              r.deletedAt.isNotNull(),
        ))
        .write(
          PurchaseReturnsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 5. OFFLINE-FIRST SYNCHRONIZATION HELPERS (All 7 Purchasing Tables)
  // ============================================================================

  /// Returns all suppliers pending synchronization.
  Future<List<Supplier>> getPendingSyncSuppliers(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncSuppliers requires businessId.',
      );
    }
    return (select(suppliers)..where(
          (s) =>
              s.businessId.equals(businessId) &
              s.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified suppliers as synced.
  Future<int> markSuppliersAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markSuppliersAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(suppliers)
          ..where((s) => s.id.isIn(ids) & s.businessId.equals(businessId)))
        .write(const SuppliersCompanion(syncStatus: Value('synced')));
  }

  /// Returns all purchase invoices pending synchronization.
  Future<List<PurchaseInvoice>> getPendingSyncInvoices(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncInvoices requires businessId.',
      );
    }
    return (select(purchaseInvoices)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified purchase invoices as synced.
  Future<int> markInvoicesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markInvoicesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(purchaseInvoices)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const PurchaseInvoicesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all purchase invoice items pending synchronization.
  Future<List<PurchaseInvoiceItem>> getPendingSyncInvoiceItems(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncInvoiceItems requires businessId.',
      );
    }
    return (select(purchaseInvoiceItems)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified purchase invoice items as synced.
  Future<int> markInvoiceItemsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markInvoiceItemsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
      purchaseInvoiceItems,
    )..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId))).write(
      const PurchaseInvoiceItemsCompanion(syncStatus: Value('synced')),
    );
  }

  /// Returns all supplier payables pending synchronization.
  Future<List<SupplierPayable>> getPendingSyncPayables(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPayables requires businessId.',
      );
    }
    return (select(supplierPayables)..where(
          (p) =>
              p.businessId.equals(businessId) &
              p.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified supplier payables as synced.
  Future<int> markPayablesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markPayablesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(supplierPayables)
          ..where((p) => p.id.isIn(ids) & p.businessId.equals(businessId)))
        .write(const SupplierPayablesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all payable entries pending synchronization.
  Future<List<PayableEntry>> getPendingSyncPayableEntries(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPayableEntries requires businessId.',
      );
    }
    return (select(payableEntries)..where(
          (e) =>
              e.businessId.equals(businessId) &
              e.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified payable entries as synced.
  Future<int> markPayableEntriesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markPayableEntriesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(payableEntries)
          ..where((e) => e.id.isIn(ids) & e.businessId.equals(businessId)))
        .write(const PayableEntriesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all purchase returns pending synchronization.
  Future<List<PurchaseReturn>> getPendingSyncReturns(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncReturns requires businessId.',
      );
    }
    return (select(purchaseReturns)..where(
          (r) =>
              r.businessId.equals(businessId) &
              r.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified purchase returns as synced.
  Future<int> markReturnsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markReturnsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(purchaseReturns)
          ..where((r) => r.id.isIn(ids) & r.businessId.equals(businessId)))
        .write(const PurchaseReturnsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all purchase return items pending synchronization.
  Future<List<PurchaseReturnItem>> getPendingSyncReturnItems(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncReturnItems requires businessId.',
      );
    }
    return (select(purchaseReturnItems)..where(
          (i) =>
              i.businessId.equals(businessId) &
              i.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified purchase return items as synced.
  Future<int> markReturnItemsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markReturnItemsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(purchaseReturnItems)
          ..where((i) => i.id.isIn(ids) & i.businessId.equals(businessId)))
        .write(const PurchaseReturnItemsCompanion(syncStatus: Value('synced')));
  }
}
