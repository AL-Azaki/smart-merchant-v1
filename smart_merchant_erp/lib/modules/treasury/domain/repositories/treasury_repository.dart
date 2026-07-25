import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/treasury_dao.dart';

/// Contract for Treasury & Financial Operations domain data operations.
abstract class TreasuryRepository {
  // Bank Accounts
  Future<BankAccount?> getBankAccountById(String id, String businessId);
  Future<List<BankAccount>> listBankAccounts(BankAccountFilter filter);
  Stream<List<BankAccount>> watchBankAccounts(BankAccountFilter filter);
  Stream<BankAccount?> watchBankAccountById(String id, String businessId);
  Future<int> insertBankAccount(BankAccountsCompanion companion);
  Future<bool> updateBankAccount(BankAccountsCompanion companion);
  Future<bool> updateBankAccountBalance(
    String id,
    String businessId,
    double newBalance,
  );
  Future<List<BankAccount>> getPendingSyncBankAccounts(String businessId);
  Future<int> markBankAccountsAsSynced(List<String> ids, String businessId);

  // Bank Transactions
  Future<BankTransaction?> getBankTransactionById(String id, String businessId);
  Future<List<BankTransaction>> listBankTransactions(
    BankTransactionFilter filter,
  );
  Stream<List<BankTransaction>> watchBankTransactions(
    BankTransactionFilter filter,
  );
  Future<int> insertBankTransaction(BankTransactionsCompanion companion);
  Future<bool> updateBankTransactionReconciliationStatus(
    String id,
    String businessId,
    String status,
  );

  // Cash Registers
  Future<CashRegister?> getCashRegisterById(String id, String businessId);
  Future<List<CashRegister>> listCashRegisters(CashRegisterFilter filter);
  Stream<List<CashRegister>> watchCashRegisters(CashRegisterFilter filter);
  Stream<CashRegister?> watchCashRegisterById(String id, String businessId);
  Future<int> insertCashRegister(CashRegistersCompanion companion);
  Future<bool> updateCashRegister(CashRegistersCompanion companion);
  Future<bool> updateCashRegisterStatus(
    String id,
    String businessId,
    String status,
  );
  Future<bool> updateCashRegisterBalance(
    String id,
    String businessId,
    double newBalance,
  );

  // Cash Transactions
  Future<CashTransaction?> getCashTransactionById(String id, String businessId);
  Future<List<CashTransaction>> listCashTransactions(
    CashTransactionFilter filter,
  );
  Stream<List<CashTransaction>> watchCashTransactions(
    CashTransactionFilter filter,
  );
  Future<int> insertCashTransaction(CashTransactionsCompanion companion);

  // Payment Methods
  Future<PaymentMethod?> getPaymentMethodById(String id, String businessId);
  Future<PaymentMethod?> getPaymentMethodByCode(
    String methodCode,
    String businessId,
  );
  Future<List<PaymentMethod>> listPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  });
  Stream<List<PaymentMethod>> watchPaymentMethods(
    String businessId, {
    bool? isActive,
    String? paymentType,
  });
  Future<int> insertPaymentMethod(PaymentMethodsCompanion companion);
  Future<bool> updatePaymentMethod(PaymentMethodsCompanion companion);

  // Payments & Allocations
  Future<Payment?> getPaymentById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<PaymentWithAllocations?> getPaymentWithAllocationsById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<Payment>> listPayments(PaymentFilter filter);
  Stream<List<Payment>> watchPayments(PaymentFilter filter);
  Future<int> insertPayment(PaymentsCompanion companion);
  Future<List<PaymentAllocation>> listPaymentAllocations(
    String paymentId,
    String businessId,
  );
  Future<void> recordPaymentWithAllocationsAndTransactions({
    required PaymentsCompanion payment,
    required List<PaymentAllocationsCompanion> allocations,
  });
  Future<bool> updatePaymentStatus(
    String id,
    String businessId,
    String status, {
    String? postedBy,
    String? reversedBy,
    String? reversalReason,
  });
  Future<bool> softDeletePayment(String id, String businessId);
  Future<bool> restorePayment(String id, String businessId);

  // Bank Reconciliations
  Future<BankReconciliation?> getBankReconciliationById(
    String id,
    String businessId,
  );
  Future<BankReconciliationWithLines?> getBankReconciliationWithLinesById(
    String id,
    String businessId,
  );
  Future<List<BankReconciliation>> listBankReconciliations(
    BankReconciliationFilter filter,
  );
  Stream<List<BankReconciliation>> watchBankReconciliations(
    BankReconciliationFilter filter,
  );
  Stream<List<BankReconciliation>> watchPendingReconciliations(
    String businessId,
  );
  Future<void> recordBankReconciliationWithLines({
    required BankReconciliationsCompanion reconciliation,
    required List<BankReconciliationLinesCompanion> lines,
  });
  Future<bool> updateBankReconciliationStatus(
    String id,
    String businessId,
    String status,
  );
  Future<bool> updateBankReconciliationLineCleared(
    String lineId,
    String businessId,
    bool isCleared,
  );
}
