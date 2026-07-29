import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../../kernel/storage/tables/auth_tables.dart';
import '../tables/system/activity_logs_table.dart';
import '../tables/system/attachments_table.dart';
import '../tables/system/exchange_rates_table.dart';
import '../tables/system/expense_categories_table.dart';
import '../tables/system/expenses_table.dart';
import '../tables/system/archive_documents_table.dart';
import '../tables/core/branches_table.dart';
import '../tables/accounting/chart_of_accounts_table.dart';
import '../tables/treasury/payment_methods_table.dart';
import 'dao_exceptions.dart';

part 'system_dao.g.dart';

/// Filter DTO for [ActivityLogs] queries.
class ActivityLogFilter {
  final String businessId;
  final String? userId;
  final String? entityType;
  final String? entityId;
  final String? action;
  final int limit;
  final int offset;

  const ActivityLogFilter({
    required this.businessId,
    this.userId,
    this.entityType,
    this.entityId,
    this.action,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Filter DTO for [ExchangeRates] queries.
class ExchangeRateFilter {
  final String businessId;
  final String? sourceCurrencyId;
  final String? targetCurrencyId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;
  final int offset;

  const ExchangeRateFilter({
    required this.businessId,
    this.sourceCurrencyId,
    this.targetCurrencyId,
    this.fromDate,
    this.toDate,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Filter DTO for [ExpenseCategories] queries.
class ExpenseCategoryFilter {
  final String businessId;
  final String? chartOfAccountId;
  final bool? isActive;
  final String? searchQuery;
  final int limit;
  final int offset;

  const ExpenseCategoryFilter({
    required this.businessId,
    this.chartOfAccountId,
    this.isActive,
    this.searchQuery,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Filter DTO for [Expenses] queries.
class ExpenseFilter {
  final String businessId;
  final String? branchId;
  final String? expenseCategoryId;
  final String? paymentMethodId;
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includeSoftDeleted;
  final int limit;
  final int offset;

  const ExpenseFilter({
    required this.businessId,
    this.branchId,
    this.expenseCategoryId,
    this.paymentMethodId,
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.includeSoftDeleted = false,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining an [Expense] with its category, payment method, and attachments.
class ExpenseWithDetails {
  final Expense expense;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final List<Attachment> attachments;

  const ExpenseWithDetails({
    required this.expense,
    required this.category,
    required this.paymentMethod,
    required this.attachments,
  });
}

/// Filter DTO for [ArchiveDocuments] queries.
class ArchiveDocumentFilter {
  final String businessId;
  final String? category;
  final String? searchQuery;
  final bool? isExpired;
  final int limit;
  final int offset;

  const ArchiveDocumentFilter({
    required this.businessId,
    this.category,
    this.searchQuery,
    this.isExpired,
    this.limit = 100,
    this.offset = 0,
  });
}


@DriftAccessor(
  tables: [
    ActivityLogs,
    Attachments,
    ExchangeRates,
    ExpenseCategories,
    Expenses,
    UsersTable,
    Branches,
    ChartOfAccounts,
    PaymentMethods,
    ArchiveDocuments,
  ],
)
class SystemDao extends DatabaseAccessor<AppDatabase> with _$SystemDaoMixin {
  SystemDao(super.db);

  // ============================================================================
  // TENANT & SCOPE VALIDATION HELPERS
  // ============================================================================

  void _validateTenantScope(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
  }

  // ============================================================================
  // 1. ACTIVITY LOGS (APPEND-ONLY AUDIT TRAILS)
  // ============================================================================

  /// Inserts a new append-only [ActivityLog] record.
  /// Throws [TenantScopingException] if [businessId] is missing/empty.
  Future<int> insertActivityLog(ActivityLogsCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(activityLogs).insert(companion);
  }

  /// Retrieves a single [ActivityLog] by [id] and [businessId].
  Future<ActivityLog?> getActivityLogById(String id, String businessId) async {
    _validateTenantScope(businessId);
    return (select(activityLogs)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists [ActivityLog] records matching the filter criteria.
  Future<List<ActivityLog>> listActivityLogs(ActivityLogFilter filter) async {
    _validateTenantScope(filter.businessId);
    final query = select(activityLogs)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final userId = filter.userId;
    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }
    final entityType = filter.entityType;
    if (entityType != null) {
      query.where((tbl) => tbl.entityType.equals(entityType));
    }
    final entityId = filter.entityId;
    if (entityId != null) {
      query.where((tbl) => tbl.entityId.equals(entityId));
    }
    final action = filter.action;
    if (action != null) {
      query.where((tbl) => tbl.action.equals(action));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Watches [ActivityLog] records matching the filter criteria.
  Stream<List<ActivityLog>> watchActivityLogs(ActivityLogFilter filter) {
    _validateTenantScope(filter.businessId);
    final query = select(activityLogs)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final userId = filter.userId;
    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId));
    }
    final entityType = filter.entityType;
    if (entityType != null) {
      query.where((tbl) => tbl.entityType.equals(entityType));
    }
    final entityId = filter.entityId;
    if (entityId != null) {
      query.where((tbl) => tbl.entityId.equals(entityId));
    }
    final action = filter.action;
    if (action != null) {
      query.where((tbl) => tbl.action.equals(action));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Retrieves pending sync [ActivityLog] records.
  Future<List<ActivityLog>> getPendingSyncActivityLogs(
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(activityLogs)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [ActivityLog] record as synced.
  Future<bool> markActivityLogAsSynced(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (update(activityLogs)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(const ActivityLogsCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  // ============================================================================
  // 2. POLYMORPHIC ATTACHMENTS
  // ============================================================================

  /// Inserts a new polymorphic [Attachment] record.
  Future<int> insertAttachment(AttachmentsCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(attachments).insert(companion);
  }

  /// Retrieves a single [Attachment] by [id] and [businessId].
  Future<Attachment?> getAttachmentById(String id, String businessId) async {
    _validateTenantScope(businessId);
    return (select(attachments)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists all [Attachment] records linked to a specific entity ([entityType], [entityId]).
  Future<List<Attachment>> listAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(attachments)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.entityType.equals(entityType) &
                tbl.entityId.equals(entityId),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.uploadDate)]))
        .get();
  }

  /// Watches all [Attachment] records linked to a specific entity.
  Stream<List<Attachment>> watchAttachmentsByEntity(
    String entityType,
    String entityId,
    String businessId,
  ) {
    _validateTenantScope(businessId);
    return (select(attachments)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.entityType.equals(entityType) &
                tbl.entityId.equals(entityId),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.uploadDate)]))
        .watch();
  }

  /// Deletes an [Attachment] record by [id] and [businessId].
  Future<bool> deleteAttachment(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (delete(attachments)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .go();
    return count > 0;
  }

  /// Retrieves pending sync [Attachment] records.
  Future<List<Attachment>> getPendingSyncAttachments(String businessId) async {
    _validateTenantScope(businessId);
    return (select(attachments)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [Attachment] record as synced.
  Future<bool> markAttachmentAsSynced(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (update(attachments)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(const AttachmentsCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  // ============================================================================
  // 3. EXCHANGE RATES
  // ============================================================================

  /// Inserts a new [ExchangeRate] record.
  Future<int> insertExchangeRate(ExchangeRatesCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(exchangeRates).insert(companion);
  }

  /// Updates an existing [ExchangeRate] record.
  Future<bool> updateExchangeRate(ExchangeRatesCompanion companion) async {
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getExchangeRateById(id, businessId);
    if (existing == null) {
      return false;
    }

    final updatedCompanion = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: Value(
        existing.syncStatus == 'pending_insert'
            ? 'pending_insert'
            : 'pending_update',
      ),
      updatedAt: Value(DateTime.now()),
    );

    final count =
        await (update(exchangeRates)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(updatedCompanion);
    return count > 0;
  }

  /// Retrieves a single [ExchangeRate] by [id] and [businessId].
  Future<ExchangeRate?> getExchangeRateById(
    String id,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(exchangeRates)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves the latest [ExchangeRate] effective on or before [asOfDate].
  Future<ExchangeRate?> getLatestExchangeRate({
    required String businessId,
    required String sourceCurrencyId,
    required String targetCurrencyId,
    DateTime? asOfDate,
  }) async {
    _validateTenantScope(businessId);
    final targetDate = asOfDate ?? DateTime.now();
    return (select(exchangeRates)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.sourceCurrencyId.equals(sourceCurrencyId) &
                tbl.targetCurrencyId.equals(targetCurrencyId) &
                tbl.effectiveDate.isSmallerOrEqualValue(targetDate),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.effectiveDate,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Lists [ExchangeRate] records matching the filter criteria.
  Future<List<ExchangeRate>> listExchangeRates(
    ExchangeRateFilter filter,
  ) async {
    _validateTenantScope(filter.businessId);
    final query = select(exchangeRates)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final sourceCurrencyId = filter.sourceCurrencyId;
    if (sourceCurrencyId != null) {
      query.where((tbl) => tbl.sourceCurrencyId.equals(sourceCurrencyId));
    }
    final targetCurrencyId = filter.targetCurrencyId;
    if (targetCurrencyId != null) {
      query.where((tbl) => tbl.targetCurrencyId.equals(targetCurrencyId));
    }
    final fromDate = filter.fromDate;
    if (fromDate != null) {
      query.where((tbl) => tbl.effectiveDate.isBiggerOrEqualValue(fromDate));
    }
    final toDate = filter.toDate;
    if (toDate != null) {
      query.where((tbl) => tbl.effectiveDate.isSmallerOrEqualValue(toDate));
    }

    query
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.effectiveDate,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Watches [ExchangeRate] records matching the filter criteria.
  Stream<List<ExchangeRate>> watchExchangeRates(ExchangeRateFilter filter) {
    _validateTenantScope(filter.businessId);
    final query = select(exchangeRates)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final sourceCurrencyId = filter.sourceCurrencyId;
    if (sourceCurrencyId != null) {
      query.where((tbl) => tbl.sourceCurrencyId.equals(sourceCurrencyId));
    }
    final targetCurrencyId = filter.targetCurrencyId;
    if (targetCurrencyId != null) {
      query.where((tbl) => tbl.targetCurrencyId.equals(targetCurrencyId));
    }
    final fromDate = filter.fromDate;
    if (fromDate != null) {
      query.where((tbl) => tbl.effectiveDate.isBiggerOrEqualValue(fromDate));
    }
    final toDate = filter.toDate;
    if (toDate != null) {
      query.where((tbl) => tbl.effectiveDate.isSmallerOrEqualValue(toDate));
    }

    query
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.effectiveDate,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Retrieves pending sync [ExchangeRate] records.
  Future<List<ExchangeRate>> getPendingSyncExchangeRates(
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(exchangeRates)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [ExchangeRate] record as synced.
  Future<bool> markExchangeRateAsSynced(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (update(exchangeRates)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(const ExchangeRatesCompanion(syncStatus: Value('synced')));
    return count > 0;
  }

  // ============================================================================
  // 4. EXPENSE CATEGORIES
  // ============================================================================

  /// Inserts a new [ExpenseCategory] record.
  Future<int> insertExpenseCategory(
    ExpenseCategoriesCompanion companion,
  ) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(expenseCategories).insert(companion);
  }

  /// Updates an existing [ExpenseCategory] record.
  Future<bool> updateExpenseCategory(
    ExpenseCategoriesCompanion companion,
  ) async {
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getExpenseCategoryById(id, businessId);
    if (existing == null) {
      return false;
    }

    final updatedCompanion = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: Value(
        existing.syncStatus == 'pending_insert'
            ? 'pending_insert'
            : 'pending_update',
      ),
    );

    final count =
        await (update(expenseCategories)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(updatedCompanion);
    return count > 0;
  }

  /// Retrieves a single [ExpenseCategory] by [id] and [businessId].
  Future<ExpenseCategory?> getExpenseCategoryById(
    String id,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(expenseCategories)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a single [ExpenseCategory] by [categoryName] and [businessId].
  Future<ExpenseCategory?> getExpenseCategoryByName(
    String categoryName,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(expenseCategories)..where(
          (tbl) =>
              tbl.categoryName.equals(categoryName) &
              tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists [ExpenseCategory] records matching the filter criteria.
  Future<List<ExpenseCategory>> listExpenseCategories(
    ExpenseCategoryFilter filter,
  ) async {
    _validateTenantScope(filter.businessId);
    final query = select(expenseCategories)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final chartOfAccountId = filter.chartOfAccountId;
    if (chartOfAccountId != null) {
      query.where((tbl) => tbl.chartOfAccountId.equals(chartOfAccountId));
    }
    final isActive = filter.isActive;
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    final searchQuery = filter.searchQuery;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query.where(
        (tbl) => tbl.categoryName.like(term) | tbl.description.like(term),
      );
    }

    query
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.categoryName)])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Watches [ExpenseCategory] records matching the filter criteria.
  Stream<List<ExpenseCategory>> watchExpenseCategories(
    ExpenseCategoryFilter filter,
  ) {
    _validateTenantScope(filter.businessId);
    final query = select(expenseCategories)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final chartOfAccountId = filter.chartOfAccountId;
    if (chartOfAccountId != null) {
      query.where((tbl) => tbl.chartOfAccountId.equals(chartOfAccountId));
    }
    final isActive = filter.isActive;
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    final searchQuery = filter.searchQuery;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query.where(
        (tbl) => tbl.categoryName.like(term) | tbl.description.like(term),
      );
    }

    query
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.categoryName)])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Retrieves pending sync [ExpenseCategory] records.
  Future<List<ExpenseCategory>> getPendingSyncExpenseCategories(
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(expenseCategories)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [ExpenseCategory] record as synced.
  Future<bool> markExpenseCategoryAsSynced(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (update(expenseCategories)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(
              const ExpenseCategoriesCompanion(syncStatus: Value('synced')),
            );
    return count > 0;
  }

  // ============================================================================
  // 5. EXPENSES (ATOMIC PERSISTENCE & LIFECYCLE)
  // ============================================================================

  /// Inserts a new [Expense] record.
  Future<int> insertExpense(ExpensesCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(expenses).insert(companion);
  }

  /// Updates an existing [Expense] record.
  Future<bool> updateExpense(ExpensesCompanion companion) async {
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getExpenseById(id, businessId);
    if (existing == null) {
      return false;
    }

    final updatedCompanion = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: Value(
        existing.syncStatus == 'pending_insert'
            ? 'pending_insert'
            : 'pending_update',
      ),
      updatedAt: Value(DateTime.now()),
    );

    final count =
        await (update(expenses)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(updatedCompanion);
    return count > 0;
  }

  /// Updates the status of an [Expense] record.
  Future<bool> updateExpenseStatus(
    String id,
    String businessId,
    String newStatus, {
    required String updatedBy,
  }) async {
    _validateTenantScope(businessId);
    final existing = await getExpenseById(id, businessId);
    if (existing == null) {
      return false;
    }

    final count =
        await (update(expenses)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(
              ExpensesCompanion(
                status: Value(newStatus),
                version: Value(existing.version + 1),
                syncStatus: Value(
                  existing.syncStatus == 'pending_insert'
                      ? 'pending_insert'
                      : 'pending_update',
                ),
                updatedAt: Value(DateTime.now()),
              ),
            );
    return count > 0;
  }

  /// Retrieves a single [Expense] by [id] and [businessId].
  Future<Expense?> getExpenseById(String id, String businessId) async {
    _validateTenantScope(businessId);
    return (select(expenses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a single [Expense] by [expenseNumber] and [businessId].
  Future<Expense?> getExpenseByNumber(
    String expenseNumber,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(expenses)..where(
          (tbl) =>
              tbl.expenseNumber.equals(expenseNumber) &
              tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a composite [ExpenseWithDetails] joined with category, payment method, and attachments.
  Future<ExpenseWithDetails?> getExpenseWithDetails(
    String id,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    final exp = await getExpenseById(id, businessId);
    if (exp == null) {
      return null;
    }

    final cat =
        await (select(expenseCategories)..where(
              (tbl) =>
                  tbl.id.equals(exp.expenseCategoryId) &
                  tbl.businessId.equals(businessId),
            ))
            .getSingleOrNull();
    final pm =
        await (select(paymentMethods)..where(
              (tbl) =>
                  tbl.id.equals(exp.paymentMethodId) &
                  tbl.businessId.equals(businessId),
            ))
            .getSingleOrNull();
    final atts = await listAttachmentsByEntity('Expense', exp.id, businessId);

    return ExpenseWithDetails(
      expense: exp,
      category: cat!,
      paymentMethod: pm!,
      attachments: atts,
    );
  }

  // ============================================================================
  // 6. ARCHIVE DOCUMENTS
  // ============================================================================

  /// Inserts a new [ArchiveDocument] record.
  Future<int> insertArchiveDocument(ArchiveDocumentsCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);
    return into(archiveDocuments).insert(companion);
  }

  /// Retrieves a single [ArchiveDocument] by [id] and [businessId].
  Future<ArchiveDocument?> getArchiveDocumentById(String id, String businessId) async {
    _validateTenantScope(businessId);
    return (select(archiveDocuments)..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId))).getSingleOrNull();
  }

  /// Updates an existing [ArchiveDocument].
  Future<bool> updateArchiveDocument(ArchiveDocumentsCompanion companion) async {
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getArchiveDocumentById(id, businessId);
    if (existing == null) {
      return false;
    }

    final updatedCompanion = companion.copyWith(
      version: Value(existing.version + 1),
      syncStatus: Value(
        existing.syncStatus == 'pending_insert'
            ? 'pending_insert'
            : 'pending_update',
      ),
      updatedAt: Value(DateTime.now()),
    );

    final count = await (update(archiveDocuments)..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId))).write(updatedCompanion);
    return count > 0;
  }

  /// Deletes an [ArchiveDocument].
  Future<bool> deleteArchiveDocument(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count = await (delete(archiveDocuments)..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId))).go();
    return count > 0;
  }

  /// Watches [ArchiveDocument] records matching the filter criteria.
  Stream<List<ArchiveDocument>> watchArchiveDocuments(ArchiveDocumentFilter filter) {
    _validateTenantScope(filter.businessId);
    final query = select(archiveDocuments)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    final category = filter.category;
    if (category != null && category != 'all') {
      query.where((tbl) => tbl.category.equals(category));
    }
    
    final isExpired = filter.isExpired;
    if (isExpired != null) {
      if (isExpired) {
        query.where((tbl) => tbl.expiryDate.isSmallerOrEqualValue(DateTime.now()));
      } else {
        query.where((tbl) => tbl.expiryDate.isNull() | tbl.expiryDate.isBiggerThanValue(DateTime.now()));
      }
    }

    final searchQuery = filter.searchQuery;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query.where((tbl) => tbl.title.like(term) | tbl.refNumber.like(term));
    }

    query
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.issueDate, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Lists [Expense] records matching the filter criteria.
  Future<List<Expense>> listExpenses(ExpenseFilter filter) async {
    _validateTenantScope(filter.businessId);
    final query = select(expenses)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (!filter.includeSoftDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    final branchId = filter.branchId;
    if (branchId != null) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    final expenseCategoryId = filter.expenseCategoryId;
    if (expenseCategoryId != null) {
      query.where((tbl) => tbl.expenseCategoryId.equals(expenseCategoryId));
    }
    final paymentMethodId = filter.paymentMethodId;
    if (paymentMethodId != null) {
      query.where((tbl) => tbl.paymentMethodId.equals(paymentMethodId));
    }
    final status = filter.status;
    if (status != null) {
      query.where((tbl) => tbl.status.equals(status));
    }
    final startDate = filter.startDate;
    if (startDate != null) {
      query.where((tbl) => tbl.expenseDate.isBiggerOrEqualValue(startDate));
    }
    final endDate = filter.endDate;
    if (endDate != null) {
      query.where((tbl) => tbl.expenseDate.isSmallerOrEqualValue(endDate));
    }
    final searchQuery = filter.searchQuery;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query.where((tbl) => tbl.expenseNumber.like(term) | tbl.notes.like(term));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.expenseDate, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.get();
  }

  /// Watches [Expense] records matching the filter criteria.
  Stream<List<Expense>> watchExpenses(ExpenseFilter filter) {
    _validateTenantScope(filter.businessId);
    final query = select(expenses)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (!filter.includeSoftDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    final branchId = filter.branchId;
    if (branchId != null) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    final expenseCategoryId = filter.expenseCategoryId;
    if (expenseCategoryId != null) {
      query.where((tbl) => tbl.expenseCategoryId.equals(expenseCategoryId));
    }
    final paymentMethodId = filter.paymentMethodId;
    if (paymentMethodId != null) {
      query.where((tbl) => tbl.paymentMethodId.equals(paymentMethodId));
    }
    final status = filter.status;
    if (status != null) {
      query.where((tbl) => tbl.status.equals(status));
    }
    final startDate = filter.startDate;
    if (startDate != null) {
      query.where((tbl) => tbl.expenseDate.isBiggerOrEqualValue(startDate));
    }
    final endDate = filter.endDate;
    if (endDate != null) {
      query.where((tbl) => tbl.expenseDate.isSmallerOrEqualValue(endDate));
    }
    final searchQuery = filter.searchQuery;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      query.where((tbl) => tbl.expenseNumber.like(term) | tbl.notes.like(term));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.expenseDate, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: filter.offset);

    return query.watch();
  }

  /// Watches a single [Expense] by [id] and [businessId].
  Stream<Expense?> watchExpenseById(String id, String businessId) {
    _validateTenantScope(businessId);
    return (select(expenses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .watchSingleOrNull();
  }

  /// Soft deletes an [Expense] record by setting [deletedAt].
  Future<int> softDeleteExpense(String id, String businessId) async {
    _validateTenantScope(businessId);
    final existing = await getExpenseById(id, businessId);
    if (existing == null) {
      return 0;
    }

    return (update(expenses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          ExpensesCompanion(
            deletedAt: Value(DateTime.now()),
            version: Value(existing.version + 1),
            syncStatus: Value(
              existing.syncStatus == 'pending_insert'
                  ? 'pending_insert'
                  : 'pending_update',
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Restores a soft-deleted [Expense] record by clearing [deletedAt].
  Future<int> restoreExpense(String id, String businessId) async {
    _validateTenantScope(businessId);
    final existing = await getExpenseById(id, businessId);
    if (existing == null) {
      return 0;
    }

    return (update(expenses)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          ExpensesCompanion(
            deletedAt: const Value(null),
            version: Value(existing.version + 1),
            syncStatus: Value(
              existing.syncStatus == 'pending_insert'
                  ? 'pending_insert'
                  : 'pending_update',
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Atomically inserts an [Expense] along with its linked polymorphic [Attachment] records.
  /// Throws [TenantScopingException] if any attachment's [businessId] or [entityId]/[entityType] mismatches.
  Future<void> insertExpenseWithAttachments(
    ExpensesCompanion expenseCompanion,
    List<AttachmentsCompanion> attachmentCompanions,
  ) async {
    final businessId = expenseCompanion.businessId.value;
    _validateTenantScope(businessId);
    final expenseId = expenseCompanion.id.value;

    return transaction(() async {
      for (final att in attachmentCompanions) {
        if (att.businessId.value != businessId ||
            att.entityId.value != expenseId ||
            att.entityType.value != 'Expense') {
          throw const TenantScopingException();
        }
      }

      await into(expenses).insert(expenseCompanion);
      for (final att in attachmentCompanions) {
        await into(attachments).insert(att);
      }
    });
  }

  /// Retrieves pending sync [Expense] records.
  Future<List<Expense>> getPendingSyncExpenses(String businessId) async {
    _validateTenantScope(businessId);
    return (select(expenses)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.syncStatus.isNotValue('synced'),
        ))
        .get();
  }

  /// Marks an [Expense] record as synced.
  Future<bool> markExpenseAsSynced(String id, String businessId) async {
    _validateTenantScope(businessId);
    final count =
        await (update(expenses)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(const ExpensesCompanion(syncStatus: Value('synced')));
    return count > 0;
  }
}
