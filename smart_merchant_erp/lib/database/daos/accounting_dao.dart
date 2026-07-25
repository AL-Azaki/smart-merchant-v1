import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/accounting/account_mappings_table.dart';
import '../tables/accounting/accounting_periods_table.dart';
import '../tables/accounting/chart_of_accounts_table.dart';
import '../tables/accounting/fiscal_periods_table.dart';
import '../tables/accounting/fiscal_years_table.dart';
import '../tables/accounting/journal_entries_table.dart';
import '../tables/accounting/journal_entry_lines_table.dart';
import '../tables/accounting/opening_balances_table.dart';
import '../tables/accounting/payment_terms_table.dart';
import '../tables/core/businesses_table.dart';
import '../tables/core/branches_table.dart';
import 'dao_exceptions.dart';

part 'accounting_dao.g.dart';

/// Filter DTO for [ChartOfAccounts] queries.
class ChartOfAccountFilter {
  final String businessId;
  final String? parentAccountId;
  final String? accountCode;
  final int? accountTypeId;
  final String? accountCategory;
  final bool? isActive;
  final bool? isSystem;
  final String? searchQuery;
  final int limit;
  final int offset;

  const ChartOfAccountFilter({
    required this.businessId,
    this.parentAccountId,
    this.accountCode,
    this.accountTypeId,
    this.accountCategory,
    this.isActive,
    this.isSystem,
    this.searchQuery,
    this.limit = 500,
    this.offset = 0,
  });
}

/// Node representation for hierarchical Chart of Accounts tree structures.
class ChartOfAccountNode {
  final ChartOfAccount account;
  final List<ChartOfAccountNode> children;

  const ChartOfAccountNode({required this.account, required this.children});
}

/// Filter DTO for [FiscalYears] queries.
class FiscalYearFilter {
  final String businessId;
  final String? status;
  final int limit;
  final int offset;

  const FiscalYearFilter({
    required this.businessId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [FiscalPeriods] queries.
class FiscalPeriodFilter {
  final String businessId;
  final String? fiscalYearId;
  final String? status;
  final int limit;
  final int offset;

  const FiscalPeriodFilter({
    required this.businessId,
    this.fiscalYearId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [AccountingPeriods] queries.
class AccountingPeriodFilter {
  final String businessId;
  final String? fiscalYearId;
  final String? status;
  final int limit;
  final int offset;

  const AccountingPeriodFilter({
    required this.businessId,
    this.fiscalYearId,
    this.status,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [JournalEntries] queries.
class JournalEntryFilter {
  final String businessId;
  final String? fiscalYearId;
  final String? fiscalPeriodId;
  final String? journalType;
  final String? documentType;
  final String? documentId;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const JournalEntryFilter({
    required this.businessId,
    this.fiscalYearId,
    this.fiscalPeriodId,
    this.journalType,
    this.documentType,
    this.documentId,
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Composite DTO combining a [JournalEntry] with all of its [JournalEntryLine]s.
class JournalEntryWithLines {
  final JournalEntry entry;
  final List<JournalEntryLine> lines;

  const JournalEntryWithLines({required this.entry, required this.lines});
}

/// Filter DTO for [OpeningBalances] queries.
class OpeningBalanceFilter {
  final String businessId;
  final String? fiscalYearId;
  final String? chartOfAccountId;
  final int limit;
  final int offset;

  const OpeningBalanceFilter({
    required this.businessId,
    this.fiscalYearId,
    this.chartOfAccountId,
    this.limit = 200,
    this.offset = 0,
  });
}

/// Filter DTO for [AccountMappings] queries.
class AccountMappingFilter {
  final String businessId;
  final String? mappingKey;
  final bool? isActive;
  final int limit;
  final int offset;

  const AccountMappingFilter({
    required this.businessId,
    this.mappingKey,
    this.isActive,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Filter DTO for [PaymentTerms] queries.
class PaymentTermFilter {
  final String businessId;
  final bool? isActive;
  final String? searchQuery;
  final int limit;
  final int offset;

  const PaymentTermFilter({
    required this.businessId,
    this.isActive,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Module-Driven DAO for Domain: Accounting & General Ledger (Phase 06).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), hierarchical Chart of Accounts operations,
/// atomic balanced journal entry persistence, and offline synchronization across all 9 tables:
/// [ChartOfAccounts], [FiscalYears], [FiscalPeriods], [AccountingPeriods],
/// [JournalEntries], [JournalEntryLines], [OpeningBalances], [AccountMappings], and [PaymentTerms].
@DriftAccessor(
  tables: [
    AccountMappings,
    AccountingPeriods,
    ChartOfAccounts,
    FiscalPeriods,
    FiscalYears,
    JournalEntries,
    JournalEntryLines,
    OpeningBalances,
    PaymentTerms,
    Businesses,
    Branches,
  ],
)
class AccountingDao extends DatabaseAccessor<AppDatabase>
    with _$AccountingDaoMixin {
  AccountingDao(super.db);

  // ============================================================================
  // 1. CHART OF ACCOUNTS OPERATIONS (Tenant Scoped, Hierarchical Tree)
  // ============================================================================

  /// Retrieves a chart of account record by ID within a business.
  Future<ChartOfAccount?> getChartOfAccountById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getChartOfAccountById requires businessId.',
      );
    }
    return (select(chartOfAccounts)
          ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a chart of account record by unique account code within a business.
  Future<ChartOfAccount?> getChartOfAccountByCode(
    String accountCode,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getChartOfAccountByCode requires businessId.',
      );
    }
    return (select(chartOfAccounts)..where(
          (a) =>
              a.accountCode.equals(accountCode) &
              a.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists chart of accounts matching the provided filter with pagination.
  Future<List<ChartOfAccount>> listChartOfAccounts(
    ChartOfAccountFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listChartOfAccounts requires businessId.',
      );
    }
    final query = select(chartOfAccounts)
      ..where((a) => a.businessId.equals(filter.businessId));

    if (filter.parentAccountId != null) {
      query.where((a) => a.parentAccountId.equals(filter.parentAccountId!));
    }
    if (filter.accountCode != null && filter.accountCode!.trim().isNotEmpty) {
      query.where((a) => a.accountCode.equals(filter.accountCode!));
    }
    if (filter.accountTypeId != null) {
      query.where((a) => a.accountTypeId.equals(filter.accountTypeId!));
    }
    if (filter.accountCategory != null &&
        filter.accountCategory!.trim().isNotEmpty) {
      query.where((a) => a.accountCategory.equals(filter.accountCategory!));
    }
    if (filter.isActive != null) {
      query.where((a) => a.isActive.equals(filter.isActive!));
    }
    if (filter.isSystem != null) {
      query.where((a) => a.isSystem.equals(filter.isSystem!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim().toLowerCase()}%';
      query.where(
        (a) => a.accountCode.lower().like(q) | a.accountName.lower().like(q),
      );
    }

    query.orderBy([(a) => OrderingTerm(expression: a.accountCode)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of chart of accounts matching the provided filter.
  Stream<List<ChartOfAccount>> watchChartOfAccounts(
    ChartOfAccountFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchChartOfAccounts requires businessId.',
      );
    }
    final query = select(chartOfAccounts)
      ..where((a) => a.businessId.equals(filter.businessId));

    if (filter.parentAccountId != null) {
      query.where((a) => a.parentAccountId.equals(filter.parentAccountId!));
    }
    if (filter.accountTypeId != null) {
      query.where((a) => a.accountTypeId.equals(filter.accountTypeId!));
    }
    if (filter.isActive != null) {
      query.where((a) => a.isActive.equals(filter.isActive!));
    }
    query.orderBy([(a) => OrderingTerm(expression: a.accountCode)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Builds and returns the complete hierarchical Chart of Accounts tree structure
  /// starting from [rootParentAccountId] (or from root accounts where `parentAccountId` is null).
  Future<List<ChartOfAccountNode>> getChartOfAccountsTree(
    String businessId, {
    String? rootParentAccountId,
    bool onlyActive = true,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getChartOfAccountsTree requires businessId.',
      );
    }

    final filter = ChartOfAccountFilter(
      businessId: businessId,
      isActive: onlyActive ? true : null,
      limit: 10000,
    );
    final allAccounts = await listChartOfAccounts(filter);

    final Map<String?, List<ChartOfAccount>> parentToChildren = {};
    for (final account in allAccounts) {
      parentToChildren
          .putIfAbsent(account.parentAccountId, () => [])
          .add(account);
    }

    List<ChartOfAccountNode> buildTree(String? parentId) {
      final children = parentToChildren[parentId] ?? [];
      return children.map((account) {
        return ChartOfAccountNode(
          account: account,
          children: buildTree(account.id),
        );
      }).toList();
    }

    return buildTree(rootParentAccountId);
  }

  /// Inserts a new chart of account record.
  Future<int> insertChartOfAccount(ChartOfAccountsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertChartOfAccount requires businessId.',
      );
    }
    return into(chartOfAccounts).insert(companion);
  }

  /// Updates an existing chart of account record.
  Future<bool> updateChartOfAccount(ChartOfAccountsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateChartOfAccount requires id and businessId.',
      );
    }
    return (update(chartOfAccounts)..where(
          (a) =>
              a.id.equals(companion.id.value) &
              a.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Toggles operational active status of a chart of account record.
  Future<bool> toggleAccountActiveStatus(
    String id,
    String businessId,
    bool isActive,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'toggleAccountActiveStatus requires businessId.',
      );
    }
    return (update(chartOfAccounts)
          ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
        .write(
          ChartOfAccountsCompanion(
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 2. FISCAL YEARS & PERIODS OPERATIONS (Tenant Scoped, Status Management)
  // ============================================================================

  /// Retrieves a fiscal year by ID within a business.
  Future<FiscalYear?> getFiscalYearById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getFiscalYearById requires businessId.',
      );
    }
    return (select(fiscalYears)
          ..where((y) => y.id.equals(id) & y.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists fiscal years matching the provided filter.
  Future<List<FiscalYear>> listFiscalYears(FiscalYearFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listFiscalYears requires businessId.',
      );
    }
    final query = select(fiscalYears)
      ..where((y) => y.businessId.equals(filter.businessId));

    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((y) => y.status.equals(filter.status!));
    }
    query.orderBy([
      (y) => OrderingTerm(expression: y.startDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of fiscal years matching the provided filter.
  Stream<List<FiscalYear>> watchFiscalYears(FiscalYearFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchFiscalYears requires businessId.',
      );
    }
    final query = select(fiscalYears)
      ..where((y) => y.businessId.equals(filter.businessId));

    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((y) => y.status.equals(filter.status!));
    }
    query.orderBy([
      (y) => OrderingTerm(expression: y.startDate, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new fiscal year.
  Future<int> insertFiscalYear(FiscalYearsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertFiscalYear requires businessId.',
      );
    }
    return into(fiscalYears).insert(companion);
  }

  /// Updates an existing fiscal year.
  Future<bool> updateFiscalYear(FiscalYearsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateFiscalYear requires id and businessId.',
      );
    }
    return (update(fiscalYears)..where(
          (y) =>
              y.id.equals(companion.id.value) &
              y.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Retrieves a fiscal period by ID within a business.
  Future<FiscalPeriod?> getFiscalPeriodById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getFiscalPeriodById requires businessId.',
      );
    }
    return (select(fiscalPeriods)
          ..where((p) => p.id.equals(id) & p.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists fiscal periods matching the provided filter.
  Future<List<FiscalPeriod>> listFiscalPeriods(FiscalPeriodFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listFiscalPeriods requires businessId.',
      );
    }
    final query = select(fiscalPeriods)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((p) => p.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.periodNumber)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of fiscal periods matching the provided filter.
  Stream<List<FiscalPeriod>> watchFiscalPeriods(FiscalPeriodFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchFiscalPeriods requires businessId.',
      );
    }
    final query = select(fiscalPeriods)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((p) => p.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.periodNumber)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new fiscal period.
  Future<int> insertFiscalPeriod(FiscalPeriodsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertFiscalPeriod requires businessId.',
      );
    }
    return into(fiscalPeriods).insert(companion);
  }

  /// Updates an existing fiscal period.
  Future<bool> updateFiscalPeriod(FiscalPeriodsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateFiscalPeriod requires id and businessId.',
      );
    }
    return (update(fiscalPeriods)..where(
          (p) =>
              p.id.equals(companion.id.value) &
              p.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 3. ACCOUNTING PERIODS & LOCK VERIFICATION (Tenant Scoped)
  // ============================================================================

  /// Retrieves an accounting period by ID within a business.
  Future<AccountingPeriod?> getAccountingPeriodById(
    String id,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getAccountingPeriodById requires businessId.',
      );
    }
    return (select(accountingPeriods)
          ..where((p) => p.id.equals(id) & p.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists accounting periods matching the provided filter.
  Future<List<AccountingPeriod>> listAccountingPeriods(
    AccountingPeriodFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listAccountingPeriods requires businessId.',
      );
    }
    final query = select(accountingPeriods)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((p) => p.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.periodNumber)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of accounting periods matching the provided filter.
  Stream<List<AccountingPeriod>> watchAccountingPeriods(
    AccountingPeriodFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchAccountingPeriods requires businessId.',
      );
    }
    final query = select(accountingPeriods)
      ..where((p) => p.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((p) => p.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((p) => p.status.equals(filter.status!));
    }
    query.orderBy([(p) => OrderingTerm(expression: p.periodNumber)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new accounting period.
  Future<int> insertAccountingPeriod(AccountingPeriodsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertAccountingPeriod requires businessId.',
      );
    }
    return into(accountingPeriods).insert(companion);
  }

  /// Updates an existing accounting period.
  Future<bool> updateAccountingPeriod(AccountingPeriodsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateAccountingPeriod requires id and businessId.',
      );
    }
    return (update(accountingPeriods)..where(
          (p) =>
              p.id.equals(companion.id.value) &
              p.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Updates accounting period closing status (`Open`, `Closed`, `Locked`).
  Future<bool> updateAccountingPeriodStatus(
    String id,
    String businessId,
    String status, {
    String? closedBy,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateAccountingPeriodStatus requires businessId.',
      );
    }
    final companion = AccountingPeriodsCompanion(
      status: Value(status),
      closedBy: closedBy != null ? Value(closedBy) : const Value.absent(),
      closedAt: status != 'Open' ? Value(DateTime.now()) : const Value(null),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending_update'),
    );
    return (update(accountingPeriods)
          ..where((p) => p.id.equals(id) & p.businessId.equals(businessId)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Checks if the accounting period or fiscal period covering [date] for [businessId]
  /// is locked or closed (`status in ('Closed', 'Locked')`).
  Future<bool> checkPeriodLocked(String businessId, DateTime date) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'checkPeriodLocked requires businessId.',
      );
    }

    final period =
        await (select(accountingPeriods)..where(
              (p) =>
                  p.businessId.equals(businessId) &
                  p.startDate.isSmallerOrEqualValue(date) &
                  p.endDate.isBiggerOrEqualValue(date) &
                  p.status.isIn(['Closed', 'Locked']),
            ))
            .getSingleOrNull();

    if (period != null) {
      return true;
    }

    final fiscal =
        await (select(fiscalPeriods)..where(
              (f) =>
                  f.businessId.equals(businessId) &
                  f.startDate.isSmallerOrEqualValue(date) &
                  f.endDate.isBiggerOrEqualValue(date) &
                  f.status.equals('Closed'),
            ))
            .getSingleOrNull();

    return fiscal != null;
  }

  // ============================================================================
  // 4. JOURNAL ENTRIES & LINES OPERATIONS (Tenant Scoped, Atomic, Balanced)
  // ============================================================================

  /// Retrieves a journal entry header by ID within a business.
  Future<JournalEntry?> getJournalEntryById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getJournalEntryById requires businessId.',
      );
    }
    return (select(journalEntries)
          ..where((j) => j.id.equals(id) & j.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves a journal entry header along with all of its debit/credit line items.
  Future<JournalEntryWithLines?> getJournalEntryWithLinesById(
    String id,
    String businessId,
  ) async {
    final entry = await getJournalEntryById(id, businessId);
    if (entry == null) {
      return null;
    }

    final lines =
        await (select(journalEntryLines)..where(
              (l) =>
                  l.journalEntryId.equals(id) & l.businessId.equals(businessId),
            ))
            .get();

    return JournalEntryWithLines(entry: entry, lines: lines);
  }

  /// Lists journal entries matching the provided filter with pagination.
  Future<List<JournalEntry>> listJournalEntries(JournalEntryFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listJournalEntries requires businessId.',
      );
    }
    final query = select(journalEntries)
      ..where((j) => j.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((j) => j.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.fiscalPeriodId != null &&
        filter.fiscalPeriodId!.trim().isNotEmpty) {
      query.where((j) => j.fiscalPeriodId.equals(filter.fiscalPeriodId!));
    }
    if (filter.journalType != null && filter.journalType!.trim().isNotEmpty) {
      query.where((j) => j.journalType.equals(filter.journalType!));
    }
    if (filter.documentType != null && filter.documentType!.trim().isNotEmpty) {
      query.where((j) => j.documentType.equals(filter.documentType!));
    }
    if (filter.documentId != null && filter.documentId!.trim().isNotEmpty) {
      query.where((j) => j.documentId.equals(filter.documentId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((j) => j.status.equals(filter.status!));
    }
    if (filter.startDate != null) {
      query.where(
        (j) => j.documentDate.isBiggerOrEqualValue(filter.startDate!),
      );
    }
    if (filter.endDate != null) {
      query.where((j) => j.documentDate.isSmallerOrEqualValue(filter.endDate!));
    }

    query.orderBy([
      (j) => OrderingTerm(expression: j.documentDate, mode: OrderingMode.desc),
      (j) => OrderingTerm(expression: j.id, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of journal entries matching the provided filter.
  Stream<List<JournalEntry>> watchJournalEntries(JournalEntryFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchJournalEntries requires businessId.',
      );
    }
    final query = select(journalEntries)
      ..where((j) => j.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((j) => j.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.journalType != null && filter.journalType!.trim().isNotEmpty) {
      query.where((j) => j.journalType.equals(filter.journalType!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((j) => j.status.equals(filter.status!));
    }
    query.orderBy([
      (j) => OrderingTerm(expression: j.documentDate, mode: OrderingMode.desc),
      (j) => OrderingTerm(expression: j.id, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Atomically posts a journal entry header and all of its debit/credit lines inside a single
  /// database transaction after strictly enforcing double-entry balancing (`Debits == Credits`).
  Future<void> postJournalEntryWithLines(
    JournalEntriesCompanion entry,
    List<JournalEntryLinesCompanion> lines,
  ) async {
    if (!entry.businessId.present || entry.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'postJournalEntryWithLines requires businessId on entry.',
      );
    }
    if (lines.isEmpty) {
      throw const BalancedJournalRequiredException(
        'Journal entry must contain at least two debit/credit lines.',
      );
    }
    final busId = entry.businessId.value;

    double totalDebits = 0.0;
    double totalCredits = 0.0;

    for (final line in lines) {
      if (!line.businessId.present || line.businessId.value != busId) {
        throw const TenantScopingException(
          'All journal entry lines must match entry businessId.',
        );
      }
      if (!line.type.present) {
        throw const BalancedJournalRequiredException(
          'Journal entry lines must specify type (Debit or Credit).',
        );
      }
      final type = line.type.value;
      final amount = line.baseAmount.present ? line.baseAmount.value : 0.0;

      if (type == 'Debit') {
        totalDebits += amount;
      } else if (type == 'Credit') {
        totalCredits += amount;
      }
    }

    if ((totalDebits - totalCredits).abs() > 0.001) {
      throw const BalancedJournalRequiredException();
    }

    await transaction(() async {
      await into(journalEntries).insert(entry);
      for (final line in lines) {
        await into(journalEntryLines).insert(line);
      }
    });
  }

  /// Updates journal entry status (`Draft`, `Posted`, `Reversed`).
  Future<bool> updateJournalEntryStatus(
    String id,
    String businessId,
    String status, {
    String? postedBy,
    String? reversedBy,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'updateJournalEntryStatus requires businessId.',
      );
    }
    final companion = JournalEntriesCompanion(
      status: Value(status),
      postedBy: postedBy != null ? Value(postedBy) : const Value.absent(),
      postedAt: status == 'Posted'
          ? Value(DateTime.now())
          : const Value.absent(),
      reversedBy: reversedBy != null ? Value(reversedBy) : const Value.absent(),
      reversedAt: status == 'Reversed'
          ? Value(DateTime.now())
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      syncStatus: const Value('pending_update'),
    );
    return (update(journalEntries)
          ..where((j) => j.id.equals(id) & j.businessId.equals(businessId)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 5. OPENING BALANCES OPERATIONS (Tenant Scoped, Atomic Batch)
  // ============================================================================

  /// Retrieves an opening balance record by ID within a business.
  Future<OpeningBalance?> getOpeningBalanceById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getOpeningBalanceById requires businessId.',
      );
    }
    return (select(openingBalances)
          ..where((b) => b.id.equals(id) & b.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists opening balances matching the provided filter.
  Future<List<OpeningBalance>> listOpeningBalances(
    OpeningBalanceFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listOpeningBalances requires businessId.',
      );
    }
    final query = select(openingBalances)
      ..where((b) => b.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((b) => b.fiscalYearId.equals(filter.fiscalYearId!));
    }
    if (filter.chartOfAccountId != null &&
        filter.chartOfAccountId!.trim().isNotEmpty) {
      query.where((b) => b.chartOfAccountId.equals(filter.chartOfAccountId!));
    }
    query.orderBy([
      (b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of opening balances matching the provided filter.
  Stream<List<OpeningBalance>> watchOpeningBalances(
    OpeningBalanceFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchOpeningBalances requires businessId.',
      );
    }
    final query = select(openingBalances)
      ..where((b) => b.businessId.equals(filter.businessId));

    if (filter.fiscalYearId != null && filter.fiscalYearId!.trim().isNotEmpty) {
      query.where((b) => b.fiscalYearId.equals(filter.fiscalYearId!));
    }
    query.orderBy([
      (b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc),
    ]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a single opening balance record.
  Future<int> recordOpeningBalance(OpeningBalancesCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'recordOpeningBalance requires businessId.',
      );
    }
    return into(openingBalances).insert(companion);
  }

  /// Atomically records a batch of opening balances inside a single transaction.
  Future<void> recordOpeningBalances(
    List<OpeningBalancesCompanion> balances,
    String businessId,
  ) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'recordOpeningBalances requires businessId.',
      );
    }
    await transaction(() async {
      for (final companion in balances) {
        if (!companion.businessId.present ||
            companion.businessId.value != businessId) {
          throw const TenantScopingException(
            'All opening balances must match target businessId.',
          );
        }
        await into(openingBalances).insert(companion);
      }
    });
  }

  // ============================================================================
  // 6. ACCOUNT MAPPINGS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves an account mapping rule by ID within a business.
  Future<AccountMapping?> getAccountMappingById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getAccountMappingById requires businessId.',
      );
    }
    return (select(accountMappings)
          ..where((m) => m.id.equals(id) & m.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Retrieves an account mapping rule by its unique system key within a business.
  Future<AccountMapping?> getAccountMappingByKey(
    String mappingKey,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getAccountMappingByKey requires businessId.',
      );
    }
    return (select(accountMappings)..where(
          (m) =>
              m.mappingKey.equals(mappingKey) & m.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists account mappings matching the provided filter.
  Future<List<AccountMapping>> listAccountMappings(
    AccountMappingFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listAccountMappings requires businessId.',
      );
    }
    final query = select(accountMappings)
      ..where((m) => m.businessId.equals(filter.businessId));

    if (filter.mappingKey != null && filter.mappingKey!.trim().isNotEmpty) {
      query.where((m) => m.mappingKey.equals(filter.mappingKey!));
    }
    if (filter.isActive != null) {
      query.where((m) => m.isActive.equals(filter.isActive!));
    }
    query.orderBy([(m) => OrderingTerm(expression: m.mappingKey)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of account mappings matching the provided filter.
  Stream<List<AccountMapping>> watchAccountMappings(
    AccountMappingFilter filter,
  ) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchAccountMappings requires businessId.',
      );
    }
    final query = select(accountMappings)
      ..where((m) => m.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((m) => m.isActive.equals(filter.isActive!));
    }
    query.orderBy([(m) => OrderingTerm(expression: m.mappingKey)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new account mapping rule.
  Future<int> insertAccountMapping(AccountMappingsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertAccountMapping requires businessId.',
      );
    }
    return into(accountMappings).insert(companion);
  }

  /// Updates an existing account mapping rule.
  Future<bool> updateAccountMapping(AccountMappingsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateAccountMapping requires id and businessId.',
      );
    }
    return (update(accountMappings)..where(
          (m) =>
              m.id.equals(companion.id.value) &
              m.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 7. PAYMENT TERMS OPERATIONS (Tenant Scoped)
  // ============================================================================

  /// Retrieves a payment term by ID within a business.
  Future<PaymentTermEntity?> getPaymentTermById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPaymentTermById requires businessId.',
      );
    }
    return (select(paymentTerms)
          ..where((t) => t.id.equals(id) & t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Lists payment terms matching the provided filter.
  Future<List<PaymentTermEntity>> listPaymentTerms(PaymentTermFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'listPaymentTerms requires businessId.',
      );
    }
    final query = select(paymentTerms)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((t) => t.isActive.equals(filter.isActive!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim().toLowerCase()}%';
      query.where((t) => t.termName.lower().like(q));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.daysToDue)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.get();
  }

  /// Reactive stream of payment terms matching the provided filter.
  Stream<List<PaymentTermEntity>> watchPaymentTerms(PaymentTermFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'watchPaymentTerms requires businessId.',
      );
    }
    final query = select(paymentTerms)
      ..where((t) => t.businessId.equals(filter.businessId));

    if (filter.isActive != null) {
      query.where((t) => t.isActive.equals(filter.isActive!));
    }
    query.orderBy([(t) => OrderingTerm(expression: t.daysToDue)]);
    query.limit(filter.limit, offset: filter.offset);
    return query.watch();
  }

  /// Inserts a new payment term.
  Future<int> insertPaymentTerm(PaymentTermsCompanion companion) {
    if (!companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertPaymentTerm requires businessId.',
      );
    }
    return into(paymentTerms).insert(companion);
  }

  /// Updates an existing payment term.
  Future<bool> updatePaymentTerm(PaymentTermsCompanion companion) {
    if (!companion.id.present ||
        !companion.businessId.present ||
        companion.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updatePaymentTerm requires id and businessId.',
      );
    }
    return (update(paymentTerms)..where(
          (t) =>
              t.id.equals(companion.id.value) &
              t.businessId.equals(companion.businessId.value),
        ))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Toggles operational active status of a payment term.
  Future<bool> togglePaymentTermActiveStatus(
    String id,
    String businessId,
    bool isActive,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'togglePaymentTermActiveStatus requires businessId.',
      );
    }
    return (update(paymentTerms)
          ..where((t) => t.id.equals(id) & t.businessId.equals(businessId)))
        .write(
          PaymentTermsCompanion(
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_update'),
          ),
        )
        .then((rows) => rows > 0);
  }

  // ============================================================================
  // 8. OFFLINE-FIRST SYNCHRONIZATION HELPERS (All 9 Accounting Tables)
  // ============================================================================

  /// Returns all chart of accounts pending synchronization.
  Future<List<ChartOfAccount>> getPendingSyncChartOfAccounts(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncChartOfAccounts requires businessId.',
      );
    }
    return (select(chartOfAccounts)..where(
          (a) =>
              a.businessId.equals(businessId) &
              a.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified chart of accounts as synced.
  Future<int> markChartOfAccountsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markChartOfAccountsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(chartOfAccounts)
          ..where((a) => a.id.isIn(ids) & a.businessId.equals(businessId)))
        .write(const ChartOfAccountsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all fiscal years pending synchronization.
  Future<List<FiscalYear>> getPendingSyncFiscalYears(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncFiscalYears requires businessId.',
      );
    }
    return (select(fiscalYears)..where(
          (y) =>
              y.businessId.equals(businessId) &
              y.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified fiscal years as synced.
  Future<int> markFiscalYearsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markFiscalYearsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(fiscalYears)
          ..where((y) => y.id.isIn(ids) & y.businessId.equals(businessId)))
        .write(const FiscalYearsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all fiscal periods pending synchronization.
  Future<List<FiscalPeriod>> getPendingSyncFiscalPeriods(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncFiscalPeriods requires businessId.',
      );
    }
    return (select(fiscalPeriods)..where(
          (p) =>
              p.businessId.equals(businessId) &
              p.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified fiscal periods as synced.
  Future<int> markFiscalPeriodsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markFiscalPeriodsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(fiscalPeriods)
          ..where((p) => p.id.isIn(ids) & p.businessId.equals(businessId)))
        .write(const FiscalPeriodsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all accounting periods pending synchronization.
  Future<List<AccountingPeriod>> getPendingSyncAccountingPeriods(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncAccountingPeriods requires businessId.',
      );
    }
    return (select(accountingPeriods)..where(
          (p) =>
              p.businessId.equals(businessId) &
              p.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified accounting periods as synced.
  Future<int> markAccountingPeriodsAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markAccountingPeriodsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(accountingPeriods)
          ..where((p) => p.id.isIn(ids) & p.businessId.equals(businessId)))
        .write(const AccountingPeriodsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all journal entries pending synchronization.
  Future<List<JournalEntry>> getPendingSyncJournalEntries(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncJournalEntries requires businessId.',
      );
    }
    return (select(journalEntries)..where(
          (j) =>
              j.businessId.equals(businessId) &
              j.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified journal entries as synced.
  Future<int> markJournalEntriesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markJournalEntriesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(journalEntries)
          ..where((j) => j.id.isIn(ids) & j.businessId.equals(businessId)))
        .write(const JournalEntriesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all journal entry lines pending synchronization.
  Future<List<JournalEntryLine>> getPendingSyncJournalEntryLines(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncJournalEntryLines requires businessId.',
      );
    }
    return (select(journalEntryLines)..where(
          (l) =>
              l.businessId.equals(businessId) &
              l.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified journal entry lines as synced.
  Future<int> markJournalEntryLinesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markJournalEntryLinesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(journalEntryLines)
          ..where((l) => l.id.isIn(ids) & l.businessId.equals(businessId)))
        .write(const JournalEntryLinesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all opening balances pending synchronization.
  Future<List<OpeningBalance>> getPendingSyncOpeningBalances(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncOpeningBalances requires businessId.',
      );
    }
    return (select(openingBalances)..where(
          (b) =>
              b.businessId.equals(businessId) &
              b.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified opening balances as synced.
  Future<int> markOpeningBalancesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markOpeningBalancesAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(openingBalances)
          ..where((b) => b.id.isIn(ids) & b.businessId.equals(businessId)))
        .write(const OpeningBalancesCompanion(syncStatus: Value('synced')));
  }

  /// Returns all account mappings pending synchronization.
  Future<List<AccountMapping>> getPendingSyncAccountMappings(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncAccountMappings requires businessId.',
      );
    }
    return (select(accountMappings)..where(
          (m) =>
              m.businessId.equals(businessId) &
              m.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified account mappings as synced.
  Future<int> markAccountMappingsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markAccountMappingsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(accountMappings)
          ..where((m) => m.id.isIn(ids) & m.businessId.equals(businessId)))
        .write(const AccountMappingsCompanion(syncStatus: Value('synced')));
  }

  /// Returns all payment terms pending synchronization.
  Future<List<PaymentTermEntity>> getPendingSyncPaymentTerms(
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'getPendingSyncPaymentTerms requires businessId.',
      );
    }
    return (select(paymentTerms)..where(
          (t) =>
              t.businessId.equals(businessId) &
              t.syncStatus.isNotIn(['synced']),
        ))
        .get();
  }

  /// Marks specified payment terms as synced.
  Future<int> markPaymentTermsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException(
        'markPaymentTermsAsSynced requires businessId.',
      );
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(paymentTerms)
          ..where((t) => t.id.isIn(ids) & t.businessId.equals(businessId)))
        .write(const PaymentTermsCompanion(syncStatus: Value('synced')));
  }
}
