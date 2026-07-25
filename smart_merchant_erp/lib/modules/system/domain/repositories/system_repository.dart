import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/system_dao.dart';

/// Contract for System utilities domain data operations.
/// Covers activity logs, attachments, exchange rates, expense categories and expenses.
abstract class SystemRepository {
  // Activity Logs
  Future<int> insertActivityLog(ActivityLogsCompanion companion);
  Future<ActivityLog?> getActivityLogById(String id, String businessId);
  Future<List<ActivityLog>> listActivityLogs(ActivityLogFilter filter);
  Stream<List<ActivityLog>> watchActivityLogs(ActivityLogFilter filter);
  Future<List<ActivityLog>> getPendingSyncActivityLogs(String businessId);
  Future<bool> markActivityLogAsSynced(String id, String businessId);

  // Attachments
  Future<int> insertAttachment(AttachmentsCompanion companion);
  Future<Attachment?> getAttachmentById(String id, String businessId);
  Future<List<Attachment>> listAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  );
  Stream<List<Attachment>> watchAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  );
  Future<bool> deleteAttachment(String id, String businessId);
  Future<List<Attachment>> getPendingSyncAttachments(String businessId);
  Future<bool> markAttachmentAsSynced(String id, String businessId);

  // Exchange Rates
  Future<int> insertExchangeRate(ExchangeRatesCompanion companion);
  Future<bool> updateExchangeRate(ExchangeRatesCompanion companion);
  Future<ExchangeRate?> getExchangeRateById(String id, String businessId);
  Future<ExchangeRate?> getLatestExchangeRate({
    required String businessId,
    required String sourceCurrencyId,
    required String targetCurrencyId,
  });
  Future<List<ExchangeRate>> listExchangeRates(ExchangeRateFilter filter);
  Stream<List<ExchangeRate>> watchExchangeRates(ExchangeRateFilter filter);
  Future<List<ExchangeRate>> getPendingSyncExchangeRates(String businessId);
  Future<bool> markExchangeRateAsSynced(String id, String businessId);

  // Expense Categories
  Future<int> insertExpenseCategory(ExpenseCategoriesCompanion companion);
  Future<bool> updateExpenseCategory(ExpenseCategoriesCompanion companion);
  Future<ExpenseCategory?> getExpenseCategoryById(String id, String businessId);
  Future<ExpenseCategory?> getExpenseCategoryByName(
    String categoryName,
    String businessId,
  );
  Future<List<ExpenseCategory>> listExpenseCategories(
    ExpenseCategoryFilter filter,
  );
  Stream<List<ExpenseCategory>> watchExpenseCategories(
    ExpenseCategoryFilter filter,
  );
  Future<List<ExpenseCategory>> getPendingSyncExpenseCategories(
    String businessId,
  );
  Future<bool> markExpenseCategoryAsSynced(String id, String businessId);

  // Expenses
  Future<int> insertExpense(ExpensesCompanion companion);
  Future<bool> updateExpense(ExpensesCompanion companion);
  Future<bool> updateExpenseStatus(
    String id,
    String businessId,
    String newStatus, {
    required String updatedBy,
  });
  Future<Expense?> getExpenseById(String id, String businessId);
  Future<Expense?> getExpenseByNumber(String expenseNumber, String businessId);
  Future<ExpenseWithDetails?> getExpenseWithDetails(
    String id,
    String businessId,
  );
  Future<List<Expense>> listExpenses(ExpenseFilter filter);
  Stream<List<Expense>> watchExpenses(ExpenseFilter filter);
  Stream<Expense?> watchExpenseById(String id, String businessId);
  Future<int> softDeleteExpense(String id, String businessId);
  Future<int> restoreExpense(String id, String businessId);
  Future<void> insertExpenseWithAttachments(
    ExpensesCompanion expense,
    List<AttachmentsCompanion> attachments,
  );
  Future<List<Expense>> getPendingSyncExpenses(String businessId);
  Future<bool> markExpenseAsSynced(String id, String businessId);
}
