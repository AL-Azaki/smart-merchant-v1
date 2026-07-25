import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/accounting/chart_of_accounts_table.dart';
import '../tables/purchasing/payable_entries_table.dart';
import '../tables/purchasing/purchase_invoices_table.dart';
import '../tables/purchasing/supplier_payables_table.dart';
import '../tables/sales/customer_receivables_table.dart';
import '../tables/sales/receivable_entries_table.dart';
import '../tables/sales/sales_invoices_table.dart';
import '../tables/treasury/bank_accounts_table.dart';
import '../tables/treasury/bank_reconciliation_lines_table.dart';
import '../tables/treasury/bank_reconciliations_table.dart';
import '../tables/treasury/bank_transactions_table.dart';
import '../tables/treasury/cash_registers_table.dart';
import '../tables/treasury/cash_transactions_table.dart';
import '../tables/treasury/payment_allocations_table.dart';
import '../tables/treasury/payment_methods_table.dart';
import '../tables/treasury/payments_table.dart';
import 'dao_exceptions.dart';

part 'treasury_dao.g.dart';

/// Filter DTO for [BankAccounts] queries.
class BankAccountFilter {
  final String businessId;
  final String? branchId;
  final String? currencyId;
  final String? status;
  final bool? isDefault;

  const BankAccountFilter({
    required this.businessId,
    this.branchId,
    this.currencyId,
    this.status,
    this.isDefault,
  });
}

/// Filter DTO for [BankTransactions] queries.
class BankTransactionFilter {
  final String businessId;
  final String? bankAccountId;
  final String? transactionType;
  final String? direction;
  final String? reconciliationStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const BankTransactionFilter({
    required this.businessId,
    this.bankAccountId,
    this.transactionType,
    this.direction,
    this.reconciliationStatus,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [CashRegisters] queries.
class CashRegisterFilter {
  final String businessId;
  final String? branchId;
  final String? currencyId;
  final String? status;

  const CashRegisterFilter({
    required this.businessId,
    this.branchId,
    this.currencyId,
    this.status,
  });
}

/// Filter DTO for [CashTransactions] queries.
class CashTransactionFilter {
  final String businessId;
  final String? cashRegisterId;
  final String? transactionType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const CashTransactionFilter({
    required this.businessId,
    this.cashRegisterId,
    this.transactionType,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [Payments] queries.
class PaymentFilter {
  final String businessId;
  final String? branchId;
  final String? paymentMethodId;
  final String? chartOfAccountId;
  final String? paymentType;
  final String? contactType;
  final String? contactId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeDeleted;
  final int limit;
  final int offset;

  const PaymentFilter({
    required this.businessId,
    this.branchId,
    this.paymentMethodId,
    this.chartOfAccountId,
    this.paymentType,
    this.contactType,
    this.contactId,
    this.status,
    this.startDate,
    this.endDate,
    this.includeDeleted = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [Payment] with its [PaymentAllocation]s.
class PaymentWithAllocations {
  final Payment payment;
  final List<PaymentAllocation> allocations;

  const PaymentWithAllocations({
    required this.payment,
    required this.allocations,
  });
}

/// Filter DTO for [BankReconciliations] queries.
class BankReconciliationFilter {
  final String businessId;
  final String? chartOfAccountId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const BankReconciliationFilter({
    required this.businessId,
    this.chartOfAccountId,
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [BankReconciliation] with its [BankReconciliationLine]s.
class BankReconciliationWithLines {
  final BankReconciliation reconciliation;
  final List<BankReconciliationLine> lines;

  const BankReconciliationWithLines({
    required this.reconciliation,
    required this.lines,
  });
}

/// Module-Driven DAO for Domain: Treasury & Financial Operations (Phase 07).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), branch scoping (`branchId`), soft-delete rules (`deletedAt`),
/// and atomic transactional persistence for:
/// [BankAccounts], [BankReconciliationLines], [BankReconciliations], [BankTransactions],
/// [CashRegisters], [CashTransactions], [PaymentAllocations], [PaymentMethods], and [Payments].
@DriftAccessor(
  tables: [
    BankAccounts,
    BankReconciliationLines,
    BankReconciliations,
    BankTransactions,
    CashRegisters,
    CashTransactions,
    PaymentAllocations,
    PaymentMethods,
    Payments,
    CustomerReceivables,
    ReceivableEntries,
    SupplierPayables,
    PayableEntries,
    SalesInvoices,
    PurchaseInvoices,
    ChartOfAccounts,
  ],
)
class TreasuryDao extends DatabaseAccessor<AppDatabase>
    with _$TreasuryDaoMixin {
  TreasuryDao(super.db);

  // ============================================================================
  // 1. BANK ACCOUNTS OPERATIONS (Tenant & Branch Scoped)
  // ============================================================================

  /// Retrieves a bank account by ID within a business.
  Future<BankAccount?> getBankAccountById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getBankAccountById requires businessId.',
      );
    }
    return (select(bankAccounts)
          ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists bank accounts matching the provided filter.
  Future<List<BankAccount>> listBankAccounts(BankAccountFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listBankAccounts requires businessId.',
      );
    }
    final query = select(bankAccounts)
      ..where((a) => a.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where(
        (a) => a.branchId.equals(filter.branchId!) | a.branchId.isNull(),
      );
    }
    if (filter.currencyId != null && filter.currencyId!.trim().isNotEmpty) {
      query.where((a) => a.currencyId.equals(filter.currencyId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((a) => a.status.equals(filter.status!));
    }
    if (filter.isDefault != null) {
      query.where((a) => a.isDefault.equals(filter.isDefault!));
    }
    query.orderBy([(a) => OrderingTerm(expression: a.bankName)]);
    return query.get();
  }

  /// Reactive stream of bank accounts matching the provided filter.
  Stream<List<BankAccount>> watchBankAccounts(BankAccountFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchBankAccounts requires businessId.',
      );
    }
    final query = select(bankAccounts)
      ..where((a) => a.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where(
        (a) => a.branchId.equals(filter.branchId!) | a.branchId.isNull(),
      );
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((a) => a.status.equals(filter.status!));
    }
    query.orderBy([(a) => OrderingTerm(expression: a.bankName)]);
    return query.watch();
  }

  /// Reactive stream of a single bank account balance/details by ID within a business.
  Stream<BankAccount?> watchBankAccountById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchBankAccountById requires businessId.',
      );
    }
    return (select(bankAccounts)
          ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
        .watchSingleOrNull();
  }

  /// Inserts a new bank account record.
  Future<int> insertBankAccount(BankAccountsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertBankAccount requires businessId.',
      );
    }
    return into(bankAccounts).insert(companion);
  }

  /// Updates an existing bank account record.
  Future<bool> updateBankAccount(BankAccountsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBankAccount requires id and businessId.',
      );
    }
    return (update(bankAccounts)..where(
          (a) =>
              a.id.equals(companion.id.value) &
              a.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Updates the current balance of a bank account.
  Future<bool> updateBankAccountBalance(
    String id,
    String businessId,
    double newBalance,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBankAccountBalance requires businessId.',
      );
    }
    return (update(bankAccounts)
          ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
        .write(
          BankAccountsCompanion(
            currentBalance: Value(newBalance),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 2. BANK TRANSACTIONS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a bank transaction by ID within a business.
  Future<BankTransaction?> getBankTransactionById(
    String id,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getBankTransactionById requires businessId.',
      );
    }
    return (select(bankTransactions)
          ..where((t) => t.id.equals(id) & t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists bank transactions matching the provided filter with pagination.
  Future<List<BankTransaction>> listBankTransactions(
    BankTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listBankTransactions requires businessId.',
      );
    }
    final query = select(bankTransactions)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.bankAccountId != null &&
        filter.bankAccountId!.trim().isNotEmpty) {
      query.where((t) => t.bankAccountId.equals(filter.bankAccountId!));
    }
    if (filter.transactionType != null &&
        filter.transactionType!.trim().isNotEmpty) {
      query.where((t) => t.transactionType.equals(filter.transactionType!));
    }
    if (filter.direction != null && filter.direction!.trim().isNotEmpty) {
      query.where((t) => t.direction.equals(filter.direction!));
    }
    if (filter.reconciliationStatus != null &&
        filter.reconciliationStatus!.trim().isNotEmpty) {
      query.where(
        (t) => t.reconciliationStatus.equals(filter.reconciliationStatus!),
      );
    }
    if (filter.startDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of bank transactions matching the provided filter.
  Stream<List<BankTransaction>> watchBankTransactions(
    BankTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchBankTransactions requires businessId.',
      );
    }
    final query = select(bankTransactions)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.bankAccountId != null &&
        filter.bankAccountId!.trim().isNotEmpty) {
      query.where((t) => t.bankAccountId.equals(filter.bankAccountId!));
    }
    if (filter.reconciliationStatus != null &&
        filter.reconciliationStatus!.trim().isNotEmpty) {
      query.where(
        (t) => t.reconciliationStatus.equals(filter.reconciliationStatus!),
      );
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new bank transaction record.
  Future<int> insertBankTransaction(BankTransactionsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertBankTransaction requires businessId.',
      );
    }
    return into(bankTransactions).insert(companion);
  }

  /// Updates the reconciliation status of a bank transaction.
  Future<bool> updateBankTransactionReconciliationStatus(
    String id,
    String businessId,
    String status,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBankTransactionReconciliationStatus requires businessId.',
      );
    }
    return (update(bankTransactions)
          ..where((t) => t.id.equals(id) & t.businessId.equals(businessId)))
        .write(
          BankTransactionsCompanion(
            reconciliationStatus: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 3. CASH REGISTERS & CASH TRANSACTIONS OPERATIONS (Tenant & Branch Scoped)
  // ============================================================================

  /// Retrieves a cash register by ID within a business.
  Future<CashRegister?> getCashRegisterById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getCashRegisterById requires businessId.',
      );
    }
    return (select(cashRegisters)
          ..where((c) => c.id.equals(id) & c.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists cash registers matching the provided filter.
  Future<List<CashRegister>> listCashRegisters(CashRegisterFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listCashRegisters requires businessId.',
      );
    }
    final query = select(cashRegisters)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((c) => c.branchId.equals(filter.branchId!));
    }
    if (filter.currencyId != null && filter.currencyId!.trim().isNotEmpty) {
      query.where((c) => c.currencyId.equals(filter.currencyId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((c) => c.status.equals(filter.status!));
    }
    query.orderBy([(c) => OrderingTerm(expression: c.registerName)]);
    return query.get();
  }

  /// Reactive stream of cash registers matching the provided filter.
  Stream<List<CashRegister>> watchCashRegisters(CashRegisterFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchCashRegisters requires businessId.',
      );
    }
    final query = select(cashRegisters)
      ..where((c) => c.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((c) => c.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((c) => c.status.equals(filter.status!));
    }
    query.orderBy([(c) => OrderingTerm(expression: c.registerName)]);
    return query.watch();
  }

  /// Reactive stream watching a single cash register balance/details by ID.
  Stream<CashRegister?> watchCashRegisterById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchCashRegisterById requires businessId.',
      );
    }
    return (select(cashRegisters)
          ..where((c) => c.id.equals(id) & c.businessId.equals(businessId)))
        .watchSingleOrNull();
  }

  /// Inserts a new cash register.
  Future<int> insertCashRegister(CashRegistersCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertCashRegister requires businessId.',
      );
    }
    return into(cashRegisters).insert(companion);
  }

  /// Updates an existing cash register.
  Future<bool> updateCashRegister(CashRegistersCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateCashRegister requires id and businessId.',
      );
    }
    return (update(cashRegisters)..where(
          (c) =>
              c.id.equals(companion.id.value) &
              c.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Updates the shift status (`Open` or `Closed`) of a cash register.
  Future<bool> updateCashRegisterStatus(
    String id,
    String businessId,
    String status,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateCashRegisterStatus requires businessId.',
      );
    }
    return (update(cashRegisters)
          ..where((c) => c.id.equals(id) & c.businessId.equals(businessId)))
        .write(
          CashRegistersCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Updates the current balance of a cash register.
  Future<bool> updateCashRegisterBalance(
    String id,
    String businessId,
    double newBalance,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateCashRegisterBalance requires businessId.',
      );
    }
    return (update(cashRegisters)
          ..where((c) => c.id.equals(id) & c.businessId.equals(businessId)))
        .write(
          CashRegistersCompanion(
            currentBalance: Value(newBalance),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Retrieves a cash transaction by ID within a business.
  Future<CashTransaction?> getCashTransactionById(
    String id,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getCashTransactionById requires businessId.',
      );
    }
    return (select(cashTransactions)
          ..where((t) => t.id.equals(id) & t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists cash transactions matching the provided filter with pagination.
  Future<List<CashTransaction>> listCashTransactions(
    CashTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listCashTransactions requires businessId.',
      );
    }
    final query = select(cashTransactions)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.cashRegisterId != null &&
        filter.cashRegisterId!.trim().isNotEmpty) {
      query.where((t) => t.cashRegisterId.equals(filter.cashRegisterId!));
    }
    if (filter.transactionType != null &&
        filter.transactionType!.trim().isNotEmpty) {
      query.where((t) => t.transactionType.equals(filter.transactionType!));
    }
    if (filter.startDate != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of cash transactions matching the provided filter.
  Stream<List<CashTransaction>> watchCashTransactions(
    CashTransactionFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchCashTransactions requires businessId.',
      );
    }
    final query = select(cashTransactions)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.cashRegisterId != null &&
        filter.cashRegisterId!.trim().isNotEmpty) {
      query.where((t) => t.cashRegisterId.equals(filter.cashRegisterId!));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new cash transaction record.
  Future<int> insertCashTransaction(CashTransactionsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertCashTransaction requires businessId.',
      );
    }
    return into(cashTransactions).insert(companion);
  }

  // ============================================================================
  // 4. PAYMENT METHODS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a payment method by ID within a business.
  Future<PaymentMethod?> getPaymentMethodById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPaymentMethodById requires businessId.',
      );
    }
    return (select(paymentMethods)
          ..where((m) => m.id.equals(id) & m.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a payment method by method code within a business.
  Future<PaymentMethod?> getPaymentMethodByCode(
    String methodCode,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPaymentMethodByCode requires businessId.',
      );
    }
    return (select(paymentMethods)..where(
          (m) =>
              m.methodCode.equals(methodCode) & m.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists payment methods within a business.
  Future<List<PaymentMethod>> listPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listPaymentMethods requires businessId.',
      );
    }
    final query = select(paymentMethods)
      ..where((m) => m.businessId.equals(businessId));

    if (isActive != null) {
      query.where((m) => m.isActive.equals(isActive));
    }
    if (paymentType != null && paymentType.trim().isNotEmpty) {
      query.where((m) => m.paymentType.equals(paymentType));
    }
    query.orderBy([(m) => OrderingTerm(expression: m.methodName)]);
    return query.get();
  }

  /// Reactive stream of payment methods within a business.
  Stream<List<PaymentMethod>> watchPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchPaymentMethods requires businessId.',
      );
    }
    final query = select(paymentMethods)
      ..where((m) => m.businessId.equals(businessId));

    if (isActive != null) {
      query.where((m) => m.isActive.equals(isActive));
    }
    if (paymentType != null && paymentType.trim().isNotEmpty) {
      query.where((m) => m.paymentType.equals(paymentType));
    }
    query.orderBy([(m) => OrderingTerm(expression: m.methodName)]);
    return query.watch();
  }

  /// Inserts a new payment method.
  Future<int> insertPaymentMethod(PaymentMethodsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertPaymentMethod requires businessId.',
      );
    }
    return into(paymentMethods).insert(companion);
  }

  /// Updates an existing payment method.
  Future<bool> updatePaymentMethod(PaymentMethodsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updatePaymentMethod requires id and businessId.',
      );
    }
    return (update(paymentMethods)..where(
          (m) =>
              m.id.equals(companion.id.value) &
              m.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 5. PAYMENTS & ALLOCATIONS OPERATIONS (Tenant & Branch Scoped, Soft Delete)
  // ============================================================================

  /// Retrieves a payment voucher by ID within a business.
  Future<Payment?> getPaymentById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('getPaymentById requires businessId.');
    }
    final query = select(payments)
      ..where((p) => p.id.equals(id) & p.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((p) => p.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a payment voucher along with all of its allocations.
  Future<PaymentWithAllocations?> getPaymentWithAllocationsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) async {
    final payment = await getPaymentById(
      id,
      businessId,
      includeDeleted: includeDeleted,
    );
    if (payment == null) {
      return null;
    }

    final allocationsList =
        await (select(paymentAllocations)..where(
              (a) => a.paymentId.equals(id) & a.businessId.equals(businessId),
            ))
            .get();

    return PaymentWithAllocations(
      payment: payment,
      allocations: allocationsList,
    );
  }

  /// Lists payment vouchers matching the provided filter with pagination.
  Future<List<Payment>> listPayments(PaymentFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('listPayments requires businessId.');
    }
    final query = select(payments)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((p) => p.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((p) => p.branchId.equals(filter.branchId!));
    }
    if (filter.paymentMethodId != null &&
        filter.paymentMethodId!.trim().isNotEmpty) {
      query.where((p) => p.paymentMethodId.equals(filter.paymentMethodId!));
    }
    if (filter.chartOfAccountId != null &&
        filter.chartOfAccountId!.trim().isNotEmpty) {
      query.where((p) => p.chartOfAccountId.equals(filter.chartOfAccountId!));
    }
    if (filter.paymentType != null && filter.paymentType!.trim().isNotEmpty) {
      query.where((p) => p.paymentType.equals(filter.paymentType!));
    }
    if (filter.contactType != null && filter.contactType!.trim().isNotEmpty) {
      query.where((p) => p.contactType.equals(filter.contactType!));
    }
    if (filter.contactId != null && filter.contactId!.trim().isNotEmpty) {
      query.where((p) => p.contactId.equals(filter.contactId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    if (filter.startDate != null) {
      query.where((p) => p.paymentDate.isBiggerOrEqualValue(filter.startDate!));
    }
    if (filter.endDate != null) {
      query.where((p) => p.paymentDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of payment vouchers matching the provided filter.
  Stream<List<Payment>> watchPayments(PaymentFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException('watchPayments requires businessId.');
    }
    final query = select(payments)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (!filter.includeDeleted) {
      query.where((p) => p.deletedAt.isNull());
    }
    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((p) => p.branchId.equals(filter.branchId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([
      (p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a simple payment record without allocations.
  Future<int> insertPayment(PaymentsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertPayment requires businessId.');
    }
    return into(payments).insert(companion);
  }

  /// Lists allocations for a specific payment ID.
  Future<List<PaymentAllocation>> listPaymentAllocations(
    String paymentId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listPaymentAllocations requires businessId.',
      );
    }
    return (select(paymentAllocations)..where(
          (a) =>
              a.paymentId.equals(paymentId) & a.businessId.equals(businessId),
        ))
        .get();
  }

  /// Atomically records a payment voucher, all of its payment allocations, and any associated
  /// cash register transaction or bank account transaction inside a single database transaction.
  /// Also updates target customer receivable or supplier payable balances if requested.
  Future<void> recordPaymentWithAllocationsAndTransactions({
    required PaymentsCompanion payment,
    required List<PaymentAllocationsCompanion> allocations,
    BankTransactionsCompanion? bankTransaction,
    CashTransactionsCompanion? cashTransaction,
    bool updateReceivablesOrPayables = true,
  }) async {
    if (!payment.businessId.present ||
        payment.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordPaymentWithAllocationsAndTransactions requires businessId on payment.',
      );
    }
    final busId = payment.businessId.value;

    await transaction(() async {
      // 1. Insert payment header
      await into(payments).insert(payment);

      // 2. Insert allocations and optionally settle customer/supplier balances
      for (final allocation in allocations) {
        if (!allocation.businessId.present ||
            allocation.businessId.value != busId) {
          throw const TenantScopingException(
            'All payment allocations must match payment businessId.',
          );
        }
        await into(paymentAllocations).insert(allocation);

        if (updateReceivablesOrPayables) {
          final docType = allocation.documentType.value;
          final docId = allocation.documentId.value;
          final allocAmount = allocation.amount.value;

          if (docType == 'CustomerReceivable' ||
              docType == 'SalesInvoice' ||
              docType == 'Invoice') {
            CustomerReceivable? rec;
            if (docType == 'CustomerReceivable') {
              rec =
                  await (select(customerReceivables)..where(
                        (r) => r.id.equals(docId) & r.businessId.equals(busId),
                      ))
                      .getSingleOrNull();
            } else {
              rec =
                  await (select(customerReceivables)..where(
                        (r) =>
                            r.salesInvoiceId.equals(docId) &
                            r.businessId.equals(busId),
                      ))
                      .getSingleOrNull();
            }

            if (rec != null) {
              final nonNullRec = rec;
              final recId = nonNullRec.id;
              final newPaid = nonNullRec.paidAmount + allocAmount;
              final newRemaining = nonNullRec.originalAmount - newPaid;
              final newStatus = newRemaining <= 0.001 ? 'Paid' : 'Partial';

              await (update(customerReceivables)..where(
                    (r) => r.id.equals(recId) & r.businessId.equals(busId),
                  ))
                  .write(
                    CustomerReceivablesCompanion(
                      paidAmount: Value(newPaid),
                      remainingAmount: Value(newRemaining),
                      status: Value(newStatus),
                      lastPaymentDate: Value(DateTime.now()),
                      updatedAt: Value(DateTime.now()),
                      syncStatus: const Value('pending_update'),
                    ),
                  );

              await into(receivableEntries).insert(
                ReceivableEntriesCompanion.insert(
                  id: '${recId}_entry_${DateTime.now().microsecondsSinceEpoch}',
                  businessId: busId,
                  customerReceivableId: recId,
                  paymentId: Value(payment.id.value),
                  paymentAllocationId: Value(allocation.id.value),
                  amount: allocAmount,
                  baseAmount: allocAmount,
                  entryType: const Value('Payment'),
                  createdBy: allocation.createdBy.value,
                ),
              );
            }
          } else if (docType == 'SupplierPayable' ||
              docType == 'PurchaseInvoice') {
            SupplierPayable? pay;
            if (docType == 'SupplierPayable') {
              pay =
                  await (select(supplierPayables)..where(
                        (p) => p.id.equals(docId) & p.businessId.equals(busId),
                      ))
                      .getSingleOrNull();
            } else {
              pay =
                  await (select(supplierPayables)..where(
                        (p) =>
                            p.purchaseInvoiceId.equals(docId) &
                            p.businessId.equals(busId),
                      ))
                      .getSingleOrNull();
            }

            if (pay != null) {
              final nonNullPay = pay;
              final payId = nonNullPay.id;
              final newPaid = nonNullPay.paidAmount + allocAmount;
              final newRemaining = nonNullPay.originalAmount - newPaid;
              final newStatus = newRemaining <= 0.001 ? 'Paid' : 'Partial';

              await (update(supplierPayables)..where(
                    (p) => p.id.equals(payId) & p.businessId.equals(busId),
                  ))
                  .write(
                    SupplierPayablesCompanion(
                      paidAmount: Value(newPaid),
                      remainingAmount: Value(newRemaining),
                      status: Value(newStatus),
                      lastPaymentDate: Value(DateTime.now()),
                      updatedAt: Value(DateTime.now()),
                      syncStatus: const Value('pending_update'),
                    ),
                  );

              await into(payableEntries).insert(
                PayableEntriesCompanion.insert(
                  id: '${payId}_entry_${DateTime.now().microsecondsSinceEpoch}',
                  businessId: busId,
                  supplierPayableId: payId,
                  paymentId: Value(payment.id.value),
                  paymentAllocationId: Value(allocation.id.value),
                  amount: allocAmount,
                  baseAmount: allocAmount,
                  entryType: const Value('Payment'),
                  createdBy: allocation.createdBy.value,
                ),
              );
            }
          }
        }
      }

      // 3. Insert Bank Transaction if provided and adjust bank account balance
      if (bankTransaction != null) {
        if (!bankTransaction.businessId.present ||
            bankTransaction.businessId.value != busId) {
          throw const TenantScopingException(
            'bankTransaction businessId must match payment businessId.',
          );
        }
        await into(bankTransactions).insert(bankTransaction);

        if (bankTransaction.bankAccountId.present) {
          final accId = bankTransaction.bankAccountId.value;
          final acc = await getBankAccountById(accId, busId);
          if (acc != null) {
            final transAmount = bankTransaction.amount.value;
            final transType = bankTransaction.transactionType.value;
            final isDeposit =
                transType == 'Deposit' ||
                transType == 'Interest' ||
                (payment.paymentType.value == 'Receipt');
            final newBal = isDeposit
                ? acc.currentBalance + transAmount
                : acc.currentBalance - transAmount;
            await updateBankAccountBalance(accId, busId, newBal);
          }
        }
      }

      // 4. Insert Cash Transaction if provided and adjust cash register balance
      if (cashTransaction != null) {
        if (!cashTransaction.businessId.present ||
            cashTransaction.businessId.value != busId) {
          throw const TenantScopingException(
            'cashTransaction businessId must match payment businessId.',
          );
        }
        await into(cashTransactions).insert(cashTransaction);

        if (cashTransaction.cashRegisterId.present) {
          final regId = cashTransaction.cashRegisterId.value;
          final reg = await getCashRegisterById(regId, busId);
          if (reg != null) {
            final transAmount = cashTransaction.amount.value;
            final transType = cashTransaction.transactionType.value;
            final isReceipt =
                transType == 'Deposit' ||
                transType == 'Receipt' ||
                (payment.paymentType.value == 'Receipt');
            final newBal = isReceipt
                ? reg.currentBalance + transAmount
                : reg.currentBalance - transAmount;
            await updateCashRegisterBalance(regId, busId, newBal);
          }
        }
      }
    });
  }

  /// Updates the status of a payment voucher (`Draft`, `Posted`, `Reversed`).
  Future<bool> updatePaymentStatus(
    String id,
    String businessId,
    String status, {
    String? postedBy,
    String? reversedBy,
    String? reversalReason,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updatePaymentStatus requires businessId.',
      );
    }
    final companion = PaymentsCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending_update'),
    );

    return (update(payments)..where(
          (p) =>
              p.id.equals(id) &
              p.businessId.equals(businessId) &
              p.deletedAt.isNull(),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Soft deletes a payment voucher by setting `deletedAt` and `syncStatus = 'pending_delete'`.
  Future<bool> softDeletePayment(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'softDeletePayment requires businessId.',
      );
    }
    return (update(payments)..where(
          (p) =>
              p.id.equals(id) &
              p.businessId.equals(businessId) &
              p.deletedAt.isNull(),
        ))
        .write(
          PaymentsCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Restores a soft-deleted payment voucher.
  Future<bool> restorePayment(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException('restorePayment requires businessId.');
    }
    return (update(payments)..where(
          (p) =>
              p.id.equals(id) &
              p.businessId.equals(businessId) &
              p.deletedAt.isNotNull(),
        ))
        .write(
          PaymentsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 6. BANK RECONCILIATIONS & LINES OPERATIONS (Tenant Scoped, Atomic)
  // ============================================================================

  /// Retrieves a bank reconciliation header by ID within a business.
  Future<BankReconciliation?> getBankReconciliationById(
    String id,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getBankReconciliationById requires businessId.',
      );
    }
    return (select(bankReconciliations)
          ..where((r) => r.id.equals(id) & r.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a bank reconciliation along with all of its check items (lines).
  Future<BankReconciliationWithLines?> getBankReconciliationWithLinesById(
    String id,
    String businessId,
  ) async {
    final reconciliation = await getBankReconciliationById(id, businessId);
    if (reconciliation == null) {
      return null;
    }

    final linesList =
        await (select(bankReconciliationLines)..where(
              (l) =>
                  l.bankReconciliationId.equals(id) &
                  l.businessId.equals(businessId),
            ))
            .get();

    return BankReconciliationWithLines(
      reconciliation: reconciliation,
      lines: linesList,
    );
  }

  /// Lists bank reconciliations matching the provided filter with pagination.
  Future<List<BankReconciliation>> listBankReconciliations(
    BankReconciliationFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listBankReconciliations requires businessId.',
      );
    }
    final query = select(bankReconciliations)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (filter.chartOfAccountId != null &&
        filter.chartOfAccountId!.trim().isNotEmpty) {
      query.where((r) => r.chartOfAccountId.equals(filter.chartOfAccountId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    if (filter.startDate != null) {
      query.where(
        (r) => r.statementDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where(
        (r) => r.statementDate.isSmallerOrEqualValue(filter.endDate!),
      );
    }

    query.orderBy([
      (r) => OrderingTerm(expression: r.statementDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of bank reconciliations matching the provided filter.
  Stream<List<BankReconciliation>> watchBankReconciliations(
    BankReconciliationFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchBankReconciliations requires businessId.',
      );
    }
    final query = select(bankReconciliations)
      ..where((r) => r.businessId.equals(filter.businessId));

    if (filter.chartOfAccountId != null &&
        filter.chartOfAccountId!.trim().isNotEmpty) {
      query.where((r) => r.chartOfAccountId.equals(filter.chartOfAccountId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((r) => r.status.equals(filter.status!));
    }
    query.orderBy([
      (r) => OrderingTerm(expression: r.statementDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Reactive stream watching pending bank reconciliations (status == `Draft`).
  Stream<List<BankReconciliation>> watchPendingReconciliations(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchPendingReconciliations requires businessId.',
      );
    }
    return (select(bankReconciliations)
          ..where(
            (r) => r.businessId.equals(businessId) & r.status.equals('Draft'),
          )
          ..orderBy([
            (r) => OrderingTerm(
              expression: r.statementDate,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  /// Atomically records a bank reconciliation header along with its check items inside a transaction.
  Future<void> recordBankReconciliationWithLines({
    required BankReconciliationsCompanion reconciliation,
    required List<BankReconciliationLinesCompanion> lines,
  }) async {
    if (!reconciliation.businessId.present ||
        reconciliation.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordBankReconciliationWithLines requires businessId on reconciliation.',
      );
    }
    final busId = reconciliation.businessId.value;

    await transaction(() async {
      await into(bankReconciliations).insert(reconciliation);

      for (final line in lines) {
        if (!line.businessId.present || line.businessId.value != busId) {
          throw const TenantScopingException(
            'All reconciliation lines must match reconciliation businessId.',
          );
        }
        await into(bankReconciliationLines).insert(line);
      }
    });
  }

  /// Updates the status (`Draft` or `Completed`) of a bank reconciliation.
  Future<bool> updateBankReconciliationStatus(
    String id,
    String businessId,
    String status,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBankReconciliationStatus requires businessId.',
      );
    }
    return (update(bankReconciliations)
          ..where((r) => r.id.equals(id) & r.businessId.equals(businessId)))
        .write(
          BankReconciliationsCompanion(
            status: Value(status),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Updates the `isCleared` boolean flag on a specific bank reconciliation line.
  Future<bool> updateBankReconciliationLineCleared(
    String lineId,
    String businessId,
    bool isCleared,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBankReconciliationLineCleared requires businessId.',
      );
    }
    return (update(bankReconciliationLines)
          ..where((l) => l.id.equals(lineId) & l.businessId.equals(businessId)))
        .write(
          BankReconciliationLinesCompanion(
            isCleared: Value(isCleared),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 7. OFFLINE-FIRST SYNCHRONIZATION METADATA HELPERS across all 9 tables
  // ============================================================================

  // --- BankAccounts Sync ---
  Future<List<BankAccount>> getPendingSyncBankAccounts(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncBankAccounts requires businessId.',
      );
    }
    return (select(bankAccounts)..where(
          (a) =>
              a.businessId.equals(businessId) &
              a.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markBankAccountsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(bankAccounts)
          ..where((a) => a.id.isIn(ids) & a.businessId.equals(businessId)))
        .write(const BankAccountsCompanion(syncStatus: Value('synced')));
  }

  // --- BankReconciliationLines Sync ---
  Future<List<BankReconciliationLine>> getPendingSyncBankReconciliationLines(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncBankReconciliationLines requires businessId.',
      );
    }
    return (select(bankReconciliationLines)..where(
          (l) =>
              l.businessId.equals(businessId) &
              l.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markBankReconciliationLinesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
      bankReconciliationLines,
    )..where((l) => l.id.isIn(ids) & l.businessId.equals(businessId))).write(
      const BankReconciliationLinesCompanion(syncStatus: Value('synced')),
    );
  }

  // --- BankReconciliations Sync ---
  Future<List<BankReconciliation>> getPendingSyncBankReconciliations(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncBankReconciliations requires businessId.',
      );
    }
    return (select(bankReconciliations)..where(
          (r) =>
              r.businessId.equals(businessId) &
              r.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markBankReconciliationsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(bankReconciliations)
          ..where((r) => r.id.isIn(ids) & r.businessId.equals(businessId)))
        .write(const BankReconciliationsCompanion(syncStatus: Value('synced')));
  }

  // --- BankTransactions Sync ---
  Future<List<BankTransaction>> getPendingSyncBankTransactions(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncBankTransactions requires businessId.',
      );
    }
    return (select(bankTransactions)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markBankTransactionsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(bankTransactions)
          ..where((t) => t.id.isIn(ids) & t.businessId.equals(businessId)))
        .write(const BankTransactionsCompanion(syncStatus: Value('synced')));
  }

  // --- CashRegisters Sync ---
  Future<List<CashRegister>> getPendingSyncCashRegisters(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncCashRegisters requires businessId.',
      );
    }
    return (select(cashRegisters)..where(
          (c) =>
              c.businessId.equals(businessId) &
              c.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markCashRegistersAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(cashRegisters)
          ..where((c) => c.id.isIn(ids) & c.businessId.equals(businessId)))
        .write(const CashRegistersCompanion(syncStatus: Value('synced')));
  }

  // --- CashTransactions Sync ---
  Future<List<CashTransaction>> getPendingSyncCashTransactions(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncCashTransactions requires businessId.',
      );
    }
    return (select(cashTransactions)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markCashTransactionsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(cashTransactions)
          ..where((t) => t.id.isIn(ids) & t.businessId.equals(businessId)))
        .write(const CashTransactionsCompanion(syncStatus: Value('synced')));
  }

  // --- PaymentAllocations Sync ---
  Future<List<PaymentAllocation>> getPendingSyncPaymentAllocations(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPaymentAllocations requires businessId.',
      );
    }
    return (select(paymentAllocations)..where(
          (a) =>
              a.businessId.equals(businessId) &
              a.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markPaymentAllocationsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(paymentAllocations)
          ..where((a) => a.id.isIn(ids) & a.businessId.equals(businessId)))
        .write(const PaymentAllocationsCompanion(syncStatus: Value('synced')));
  }

  // --- PaymentMethods Sync ---
  Future<List<PaymentMethod>> getPendingSyncPaymentMethods(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPaymentMethods requires businessId.',
      );
    }
    return (select(paymentMethods)..where(
          (m) =>
              m.businessId.equals(businessId) &
              m.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  Future<int> markPaymentMethodsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(paymentMethods)
          ..where((m) => m.id.isIn(ids) & m.businessId.equals(businessId)))
        .write(const PaymentMethodsCompanion(syncStatus: Value('synced')));
  }

  // --- Payments Sync ---
  Future<List<Payment>> getPendingSyncPayments(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPayments requires businessId.',
      );
    }
    return (select(payments)..where(
          (p) =>
              p.businessId.equals(businessId) &
              p.syncStatus.isNotValue('synced') &
              p.deletedAt.isNull(),
        ))
        .get();
  }

  Future<int> markPaymentsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty || ids.isEmpty) {
      return Future.value(0);
    }
    return (update(payments)
          ..where((p) => p.id.isIn(ids) & p.businessId.equals(businessId)))
        .write(const PaymentsCompanion(syncStatus: Value('synced')));
  }
}
