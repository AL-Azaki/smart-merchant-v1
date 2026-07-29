import 'package:injectable/injectable.dart';
import '../../domain/repositories/system_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/system_dao.dart';

@LazySingleton(as: SystemRepository)
class SystemRepositoryImpl implements SystemRepository {
  final SystemDao _dao;

  SystemRepositoryImpl(this._dao);

  // Activity Logs
  @override
  Future<int> insertActivityLog(ActivityLogsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertActivityLog(companion));
  }

  @override
  Future<ActivityLog?> getActivityLogById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getActivityLogById(id, businessId),
    );
  }

  @override
  Future<List<ActivityLog>> listActivityLogs(ActivityLogFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listActivityLogs(filter));
  }

  @override
  Stream<List<ActivityLog>> watchActivityLogs(ActivityLogFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchActivityLogs(filter));
  }

  @override
  Future<List<ActivityLog>> getPendingSyncActivityLogs(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncActivityLogs(businessId),
    );
  }

  @override
  Future<bool> markActivityLogAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markActivityLogAsSynced(id, businessId),
    );
  }

  // Attachments
  @override
  Future<int> insertAttachment(AttachmentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertAttachment(companion));
  }

  @override
  Future<Attachment?> getAttachmentById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getAttachmentById(id, businessId),
    );
  }

  @override
  Future<List<Attachment>> listAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listAttachmentsByEntity(entityType, entityId, businessId),
    );
  }

  @override
  Stream<List<Attachment>> watchAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchAttachmentsByEntity(entityType, entityId, businessId),
    );
  }

  @override
  Future<bool> deleteAttachment(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteAttachment(id, businessId),
    );
  }

  @override
  Future<List<Attachment>> getPendingSyncAttachments(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncAttachments(businessId),
    );
  }

  @override
  Future<bool> markAttachmentAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markAttachmentAsSynced(id, businessId),
    );
  }

  // Exchange Rates
  @override
  Future<int> insertExchangeRate(ExchangeRatesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertExchangeRate(companion));
  }

  @override
  Future<bool> updateExchangeRate(ExchangeRatesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateExchangeRate(companion));
  }

  @override
  Future<ExchangeRate?> getExchangeRateById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getExchangeRateById(id, businessId),
    );
  }

  @override
  Future<ExchangeRate?> getLatestExchangeRate({
    required String businessId,
    required String sourceCurrencyId,
    required String targetCurrencyId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getLatestExchangeRate(
        businessId: businessId,
        sourceCurrencyId: sourceCurrencyId,
        targetCurrencyId: targetCurrencyId,
      ),
    );
  }

  @override
  Future<List<ExchangeRate>> listExchangeRates(ExchangeRateFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listExchangeRates(filter));
  }

  @override
  Stream<List<ExchangeRate>> watchExchangeRates(ExchangeRateFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchExchangeRates(filter));
  }

  @override
  Future<List<ExchangeRate>> getPendingSyncExchangeRates(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncExchangeRates(businessId),
    );
  }

  @override
  Future<bool> markExchangeRateAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markExchangeRateAsSynced(id, businessId),
    );
  }

  // Expense Categories
  @override
  Future<int> insertExpenseCategory(ExpenseCategoriesCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.insertExpenseCategory(companion),
    );
  }

  @override
  Future<bool> updateExpenseCategory(ExpenseCategoriesCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.updateExpenseCategory(companion),
    );
  }

  @override
  Future<ExpenseCategory?> getExpenseCategoryById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getExpenseCategoryById(id, businessId),
    );
  }

  @override
  Future<ExpenseCategory?> getExpenseCategoryByName(
    String categoryName,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getExpenseCategoryByName(categoryName, businessId),
    );
  }

  @override
  Future<List<ExpenseCategory>> listExpenseCategories(
    ExpenseCategoryFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listExpenseCategories(filter));
  }

  @override
  Stream<List<ExpenseCategory>> watchExpenseCategories(
    ExpenseCategoryFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchExpenseCategories(filter),
    );
  }

  @override
  Future<List<ExpenseCategory>> getPendingSyncExpenseCategories(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncExpenseCategories(businessId),
    );
  }

  @override
  Future<bool> markExpenseCategoryAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markExpenseCategoryAsSynced(id, businessId),
    );
  }

  // Expenses
  @override
  Future<int> insertExpense(ExpensesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertExpense(companion));
  }

  @override
  Future<bool> updateExpense(ExpensesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateExpense(companion));
  }

  @override
  Future<bool> updateExpenseStatus(
    String id,
    String businessId,
    String newStatus, {
    required String updatedBy,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.updateExpenseStatus(
        id,
        businessId,
        newStatus,
        updatedBy: updatedBy,
      ),
    );
  }

  @override
  Future<Expense?> getExpenseById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getExpenseById(id, businessId));
  }

  @override
  Future<Expense?> getExpenseByNumber(String expenseNumber, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getExpenseByNumber(expenseNumber, businessId),
    );
  }

  @override
  Future<ExpenseWithDetails?> getExpenseWithDetails(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getExpenseWithDetails(id, businessId),
    );
  }

  @override
  Future<List<Expense>> listExpenses(ExpenseFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listExpenses(filter));
  }

  @override
  Stream<List<Expense>> watchExpenses(ExpenseFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchExpenses(filter));
  }

  @override
  Stream<Expense?> watchExpenseById(String id, String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchExpenseById(id, businessId),
    );
  }

  @override
  Future<int> softDeleteExpense(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteExpense(id, businessId),
    );
  }

  @override
  Future<int> restoreExpense(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreExpense(id, businessId));
  }

  @override
  Future<void> insertExpenseWithAttachments(
    ExpensesCompanion expense,
    List<AttachmentsCompanion> attachments,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.insertExpenseWithAttachments(expense, attachments),
    );
  }

  @override
  Future<List<Expense>> getPendingSyncExpenses(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncExpenses(businessId),
    );
  }

  @override
  Future<bool> markExpenseAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markExpenseAsSynced(id, businessId),
    );
  }

  // Archive Documents
  @override
  Future<int> insertArchiveDocument(ArchiveDocumentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertArchiveDocument(companion));
  }

  @override
  Future<bool> updateArchiveDocument(ArchiveDocumentsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateArchiveDocument(companion));
  }

  @override
  Future<ArchiveDocument?> getArchiveDocumentById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getArchiveDocumentById(id, businessId));
  }

  @override
  Stream<List<ArchiveDocument>> watchArchiveDocuments(ArchiveDocumentFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchArchiveDocuments(filter));
  }

  @override
  Future<bool> deleteArchiveDocument(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteArchiveDocument(id, businessId));
  }
}
