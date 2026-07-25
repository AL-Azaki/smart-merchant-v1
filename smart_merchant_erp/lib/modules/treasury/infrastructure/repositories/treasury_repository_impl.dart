import 'package:injectable/injectable.dart';
import '../../domain/repositories/treasury_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/treasury_dao.dart';

@LazySingleton(as: TreasuryRepository)
class TreasuryRepositoryImpl implements TreasuryRepository {
  final TreasuryDao _dao;

  TreasuryRepositoryImpl(this._dao);

  // Bank Accounts
  @override
  Future<BankAccount?> getBankAccountById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getBankAccountById(id, businessId),
    );
  }

  @override
  Future<List<BankAccount>> listBankAccounts(BankAccountFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listBankAccounts(filter));
  }

  @override
  Stream<List<BankAccount>> watchBankAccounts(BankAccountFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchBankAccounts(filter));
  }

  @override
  Stream<BankAccount?> watchBankAccountById(String id, String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBankAccountById(id, businessId),
    );
  }

  @override
  Future<int> insertBankAccount(BankAccountsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertBankAccount(companion));
  }

  @override
  Future<bool> updateBankAccount(BankAccountsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateBankAccount(companion));
  }

  @override
  Future<bool> updateBankAccountBalance(
    String id,
    String businessId,
    double newBalance,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateBankAccountBalance(id, businessId, newBalance),
    );
  }

  @override
  Future<List<BankAccount>> getPendingSyncBankAccounts(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncBankAccounts(businessId),
    );
  }

  @override
  Future<int> markBankAccountsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markBankAccountsAsSynced(ids, businessId),
    );
  }

  // Bank Transactions
  @override
  Future<BankTransaction?> getBankTransactionById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getBankTransactionById(id, businessId),
    );
  }

  @override
  Future<List<BankTransaction>> listBankTransactions(
    BankTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listBankTransactions(filter));
  }

  @override
  Stream<List<BankTransaction>> watchBankTransactions(
    BankTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchBankTransactions(filter));
  }

  @override
  Future<int> insertBankTransaction(BankTransactionsCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.insertBankTransaction(companion),
    );
  }

  @override
  Future<bool> updateBankTransactionReconciliationStatus(
    String id,
    String businessId,
    String status,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateBankTransactionReconciliationStatus(
        id,
        businessId,
        status,
      ),
    );
  }

  // Cash Registers
  @override
  Future<CashRegister?> getCashRegisterById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getCashRegisterById(id, businessId),
    );
  }

  @override
  Future<List<CashRegister>> listCashRegisters(CashRegisterFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listCashRegisters(filter));
  }

  @override
  Stream<List<CashRegister>> watchCashRegisters(CashRegisterFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchCashRegisters(filter));
  }

  @override
  Stream<CashRegister?> watchCashRegisterById(String id, String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchCashRegisterById(id, businessId),
    );
  }

  @override
  Future<int> insertCashRegister(CashRegistersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertCashRegister(companion));
  }

  @override
  Future<bool> updateCashRegister(CashRegistersCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateCashRegister(companion));
  }

  @override
  Future<bool> updateCashRegisterStatus(
    String id,
    String businessId,
    String status,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateCashRegisterStatus(id, businessId, status),
    );
  }

  @override
  Future<bool> updateCashRegisterBalance(
    String id,
    String businessId,
    double newBalance,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateCashRegisterBalance(id, businessId, newBalance),
    );
  }

  // Cash Transactions
  @override
  Future<CashTransaction?> getCashTransactionById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getCashTransactionById(id, businessId),
    );
  }

  @override
  Future<List<CashTransaction>> listCashTransactions(
    CashTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listCashTransactions(filter));
  }

  @override
  Stream<List<CashTransaction>> watchCashTransactions(
    CashTransactionFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchCashTransactions(filter));
  }

  @override
  Future<int> insertCashTransaction(CashTransactionsCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.insertCashTransaction(companion),
    );
  }

  // Payment Methods
  @override
  Future<PaymentMethod?> getPaymentMethodById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPaymentMethodById(id, businessId),
    );
  }

  @override
  Future<PaymentMethod?> getPaymentMethodByCode(
    String methodCode,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPaymentMethodByCode(methodCode, businessId),
    );
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.listPaymentMethods(
        businessId,
        isActive: isActive,
        paymentType: paymentType,
      ),
    );
  }

  @override
  Stream<List<PaymentMethod>> watchPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchPaymentMethods(
        businessId,
        isActive: isActive,
        paymentType: paymentType,
      ),
    );
  }

  @override
  Future<int> insertPaymentMethod(PaymentMethodsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertPaymentMethod(companion));
  }

  @override
  Future<bool> updatePaymentMethod(PaymentMethodsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updatePaymentMethod(companion));
  }

  // Payments & Allocations
  @override
  Future<Payment?> getPaymentById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPaymentById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<PaymentWithAllocations?> getPaymentWithAllocationsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPaymentWithAllocationsById(
        id,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<Payment>> listPayments(PaymentFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listPayments(filter));
  }

  @override
  Stream<List<Payment>> watchPayments(PaymentFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchPayments(filter));
  }

  @override
  Future<int> insertPayment(PaymentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertPayment(companion));
  }

  @override
  Future<List<PaymentAllocation>> listPaymentAllocations(
    String paymentId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listPaymentAllocations(paymentId, businessId),
    );
  }

  @override
  Future<void> recordPaymentWithAllocationsAndTransactions({
    required PaymentsCompanion payment,
    required List<PaymentAllocationsCompanion> allocations,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordPaymentWithAllocationsAndTransactions(
        payment: payment,
        allocations: allocations,
      ),
    );
  }

  @override
  Future<bool> updatePaymentStatus(
    String id,
    String businessId,
    String status, {
    String? postedBy,
    String? reversedBy,
    String? reversalReason,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.updatePaymentStatus(
        id,
        businessId,
        status,
        postedBy: postedBy,
        reversedBy: reversedBy,
        reversalReason: reversalReason,
      ),
    );
  }

  @override
  Future<bool> softDeletePayment(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeletePayment(id, businessId),
    );
  }

  @override
  Future<bool> restorePayment(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restorePayment(id, businessId));
  }

  // Bank Reconciliations
  @override
  Future<BankReconciliation?> getBankReconciliationById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getBankReconciliationById(id, businessId),
    );
  }

  @override
  Future<BankReconciliationWithLines?> getBankReconciliationWithLinesById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getBankReconciliationWithLinesById(id, businessId),
    );
  }

  @override
  Future<List<BankReconciliation>> listBankReconciliations(
    BankReconciliationFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listBankReconciliations(filter));
  }

  @override
  Stream<List<BankReconciliation>> watchBankReconciliations(
    BankReconciliationFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBankReconciliations(filter),
    );
  }

  @override
  Stream<List<BankReconciliation>> watchPendingReconciliations(
    String businessId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchPendingReconciliations(businessId),
    );
  }

  @override
  Future<void> recordBankReconciliationWithLines({
    required BankReconciliationsCompanion reconciliation,
    required List<BankReconciliationLinesCompanion> lines,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.recordBankReconciliationWithLines(
        reconciliation: reconciliation,
        lines: lines,
      ),
    );
  }

  @override
  Future<bool> updateBankReconciliationStatus(
    String id,
    String businessId,
    String status,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateBankReconciliationStatus(id, businessId, status),
    );
  }

  @override
  Future<bool> updateBankReconciliationLineCleared(
    String lineId,
    String businessId,
    bool isCleared,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateBankReconciliationLineCleared(
        lineId,
        businessId,
        isCleared,
      ),
    );
  }
}
