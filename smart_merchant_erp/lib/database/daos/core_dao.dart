import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../../kernel/storage/tables/auth_tables.dart';
import '../tables/core/account_types_table.dart';
import '../tables/core/branches_table.dart';
import '../tables/core/businesses_table.dart';
import '../tables/core/currencies_table.dart';
import '../tables/core/print_settings_table.dart';
import '../tables/core/sequences_table.dart';
import '../tables/core/system_settings_table.dart';
import 'dao_exceptions.dart';

part 'core_dao.g.dart';

/// Filter DTO for [Branches] queries.
class BranchFilter {
  final String businessId;
  final String? branchCode;
  final bool? isActive;
  final bool includeDeleted;

  const BranchFilter({
    required this.businessId,
    this.branchCode,
    this.isActive,
    this.includeDeleted = false,
  });
}

/// Filter DTO for [Businesses] queries.
class BusinessFilter {
  final String? accountId;
  final String? status;
  final bool includeDeleted;

  const BusinessFilter({
    this.accountId,
    this.status,
    this.includeDeleted = false,
  });
}

/// Filter DTO for [Sequences] queries.
class SequenceFilter {
  final String businessId;
  final String? branchId;
  final String? documentType;

  const SequenceFilter({
    required this.businessId,
    this.branchId,
    this.documentType,
  });
}

/// Filter DTO for [SystemSettings] queries.
class SystemSettingFilter {
  final String businessId;
  final String? settingKey;
  final String? settingType;
  final bool? isPublic;

  const SystemSettingFilter({
    required this.businessId,
    this.settingKey,
    this.settingType,
    this.isPublic,
  });
}

/// Module-Driven DAO for Domain: Core (Phase 01).
///
/// Encapsulates pure local database CRUD, queries, streams, multi-tenant scoping,
/// branch scoping, soft-delete rules, and atomic transactional seeding for:
/// [AccountTypes], [Branches], [Businesses], [Currencies], [PrintSettings],
/// [Sequences], and [SystemSettings] (with [AccountsTable] as secondary read access).
@DriftAccessor(
  tables: [
    AccountTypes,
    Branches,
    Businesses,
    Currencies,
    PrintSettings,
    Sequences,
    SystemSettings,
    AccountsTable,
  ],
)
class CoreDao extends DatabaseAccessor<AppDatabase> with _$CoreDaoMixin {
  CoreDao(super.db);

  // ==========================================
  // 1. ACCOUNT TYPES (Global Reference Table)
  // ==========================================

  /// Retrieves an account type classification by primary key ID.
  Future<AccountType?> getAccountTypeById(int id) {
    return (select(
      accountTypes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves an account type classification by its unique slug.
  Future<AccountType?> getAccountTypeBySlug(String slug) {
    return (select(
      accountTypes,
    )..where((tbl) => tbl.slug.equals(slug))).getSingleOrNull();
  }

  /// Lists account type classifications, optionally filtered by active status.
  Future<List<AccountType>> listAccountTypes({bool? isActive}) {
    final query = select(accountTypes);
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    return query.get();
  }

  /// Inserts a new account classification type.
  Future<int> insertAccountType(AccountTypesCompanion accountType) {
    return into(accountTypes).insert(accountType);
  }

  /// Updates an existing account classification type.
  Future<bool> updateAccountType(AccountTypesCompanion accountType) {
    return update(accountTypes).replace(accountType);
  }

  // ==========================================
  // 2. CURRENCIES (Global / Business Preference)
  // ==========================================

  /// Retrieves a currency definition by its primary key ID.
  Future<CurrencyEntity?> getCurrencyById(String id) {
    return (select(
      currencies,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves a currency definition by its unique ISO currency code.
  Future<CurrencyEntity?> getCurrencyByCode(String currencyCode) {
    return (select(
      currencies,
    )..where((tbl) => tbl.currencyCode.equals(currencyCode))).getSingleOrNull();
  }

  /// Retrieves the system base currency.
  Future<CurrencyEntity?> getBaseCurrency() {
    return (select(
      currencies,
    )..where((tbl) => tbl.isBaseCurrency.equals(true))).getSingleOrNull();
  }

  /// Lists currencies, optionally filtered by active status.
  Future<List<CurrencyEntity>> listCurrencies({bool? isActive}) {
    final query = select(currencies);
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    return query.get();
  }

  /// Inserts a new currency definition.
  Future<int> insertCurrency(CurrenciesCompanion currency) {
    return into(currencies).insert(currency);
  }

  /// Updates an existing currency definition.
  Future<bool> updateCurrency(CurrenciesCompanion currency) {
    return update(currencies).replace(currency);
  }

  /// Retrieves pending synchronization records for currencies (`syncStatus != 'synced'`).
  Future<List<CurrencyEntity>> getPendingSyncCurrencies({int limit = 500}) {
    return (select(currencies)
          ..where((tbl) => tbl.syncStatus.isNotValue('synced'))
          ..limit(limit))
        .get();
  }

  /// Marks specified currency IDs as synchronized (`syncStatus = 'synced'`).
  Future<int> markCurrenciesAsSynced(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(currencies)..where((tbl) => tbl.id.isIn(ids))).write(
      const CurrenciesCompanion(syncStatus: Value('synced')),
    );
  }

  // ==========================================
  // 3. BUSINESSES (Primary Tenant Key & Account Scope)
  // ==========================================

  /// Retrieves a business entity by its unique tenant ID.
  /// By default, excludes soft-deleted businesses unless [includeDeleted] is true.
  Future<BusinessEntity?> getBusinessById(
    String id, {
    bool includeDeleted = false,
  }) {
    final query = select(businesses)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists businesses based on typed filter criteria.
  Future<List<BusinessEntity>> listBusinesses(BusinessFilter filter) {
    final query = select(businesses);
    if (filter.accountId != null && filter.accountId!.isNotEmpty) {
      query.where((tbl) => tbl.accountId.equals(filter.accountId!));
    }
    if (filter.status != null && filter.status!.isNotEmpty) {
      query.where((tbl) => tbl.status.equals(filter.status!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  /// Reactive stream watching a business entity by ID. Excludes soft-deleted rows by default.
  Stream<BusinessEntity?> watchBusinessById(
    String id, {
    bool includeDeleted = false,
  }) {
    final query = select(businesses)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watchSingleOrNull();
  }

  /// Reactive stream watching businesses under a specific account ID.
  Stream<List<BusinessEntity>> watchBusinessesByAccountId(
    String accountId, {
    bool includeDeleted = false,
  }) {
    final query = select(businesses)
      ..where((tbl) => tbl.accountId.equals(accountId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watch();
  }

  /// Inserts a new business entity.
  Future<int> insertBusiness(BusinessesCompanion business) {
    return into(businesses).insert(business);
  }

  /// Updates an existing business entity.
  Future<bool> updateBusiness(BusinessesCompanion business) {
    return update(businesses).replace(business);
  }

  /// Soft-deletes a business entity (`deletedAt = currentDateAndTime`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteBusiness(String id, String accountId) {
    if (accountId.trim().isEmpty) {
      throw const TenantScopingException(
        'accountId is required for soft deleting business.',
      );
    }
    return (update(businesses)
          ..where((tbl) => tbl.id.equals(id) & tbl.accountId.equals(accountId)))
        .write(
          BusinessesCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted business (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreBusiness(String id, String accountId) {
    if (accountId.trim().isEmpty) {
      throw const TenantScopingException(
        'accountId is required for restoring business.',
      );
    }
    return (update(businesses)
          ..where((tbl) => tbl.id.equals(id) & tbl.accountId.equals(accountId)))
        .write(
          const BusinessesCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Lists archived (soft-deleted) businesses.
  Future<List<BusinessEntity>> listArchivedBusinesses({String? accountId}) {
    final query = select(businesses)..where((tbl) => tbl.deletedAt.isNotNull());
    if (accountId != null && accountId.isNotEmpty) {
      query.where((tbl) => tbl.accountId.equals(accountId));
    }
    return query.get();
  }

  /// Retrieves pending synchronization businesses (`syncStatus != 'synced'`).
  Future<List<BusinessEntity>> getPendingSyncBusinesses({int limit = 500}) {
    return (select(businesses)
          ..where((tbl) => tbl.syncStatus.isNotValue('synced'))
          ..limit(limit))
        .get();
  }

  /// Marks specified business IDs as synchronized (`syncStatus = 'synced'`).
  Future<int> markBusinessesAsSynced(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(businesses)..where((tbl) => tbl.id.isIn(ids))).write(
      const BusinessesCompanion(syncStatus: Value('synced')),
    );
  }

  // ==========================================
  // 4. BRANCHES (Scoped strictly by businessId)
  // ==========================================

  /// Retrieves a branch by its unique ID within a business.
  Future<BranchEntity?> getBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(branches)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves the default branch for a business.
  Future<BranchEntity?> getDefaultBranch(
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(branches)
      ..where(
        (tbl) => tbl.businessId.equals(businessId) & tbl.isDefault.equals(true),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists branches based on typed filter criteria with strict tenant isolation.
  Future<List<BranchEntity>> listBranches(BranchFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(branches)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.branchCode != null && filter.branchCode!.isNotEmpty) {
      query.where((tbl) => tbl.branchCode.equals(filter.branchCode!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  /// Reactive stream watching a branch by ID within a business.
  Stream<BranchEntity?> watchBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(branches)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watchSingleOrNull();
  }

  /// Reactive stream watching active branches for a business.
  Stream<List<BranchEntity>> watchActiveBranches(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branches)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.isActive.equals(true) &
              tbl.deletedAt.isNull(),
        ))
        .watch();
  }

  /// Inserts a new branch.
  Future<int> insertBranch(BranchesCompanion branch) {
    if (!branch.businessId.present || branch.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertBranch requires businessId to be present.',
      );
    }
    return into(branches).insert(branch);
  }

  /// Updates an existing branch.
  Future<bool> updateBranch(BranchesCompanion branch) {
    if (!branch.businessId.present || branch.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBranch requires businessId to be present.',
      );
    }
    return update(branches).replace(branch);
  }

  /// Soft-deletes a branch (`deletedAt = currentDateAndTime`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteBranch(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(branches)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          BranchesCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted branch (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreBranch(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(branches)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const BranchesCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Lists archived (soft-deleted) branches for a business.
  Future<List<BranchEntity>> listArchivedBranches(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branches)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) & tbl.deletedAt.isNotNull(),
        ))
        .get();
  }

  /// Retrieves pending synchronization branches (`syncStatus != 'synced'`) for a business.
  Future<List<BranchEntity>> getPendingSyncBranches(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branches)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified branch IDs as synchronized (`syncStatus = 'synced'`).
  Future<int> markBranchesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          branches,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const BranchesCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 5. PRINT SETTINGS (businessId Scoped, Optional branchId)
  // ==========================================

  /// Retrieves a print setting by ID within a business.
  Future<PrintSetting?> getPrintSettingById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(printSettings)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves the effective print setting for a business, document type, and optional branch.
  /// Falls back to global business print setting (`branchId isNull`) if branch-specific setting is not found.
  Future<PrintSetting?> getEffectivePrintSetting(
    String businessId,
    String documentType, {
    String? branchId,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (branchId != null && branchId.isNotEmpty) {
      final branchSpecific =
          await (select(printSettings)..where(
                (tbl) =>
                    tbl.businessId.equals(businessId) &
                    tbl.documentType.equals(documentType) &
                    tbl.branchId.equals(branchId),
              ))
              .getSingleOrNull();
      if (branchSpecific != null) {
        return branchSpecific;
      }
    }
    return (select(printSettings)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.documentType.equals(documentType) &
              tbl.branchId.isNull(),
        ))
        .getSingleOrNull();
  }

  /// Lists print settings for a business, optionally filtered by exact branch.
  Future<List<PrintSetting>> listPrintSettings(
    String businessId, {
    String? branchId,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(printSettings)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (branchId != null) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    return query.get();
  }

  /// Reactive stream watching print settings for a business.
  Stream<List<PrintSetting>> watchPrintSettings(
    String businessId, {
    String? branchId,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(printSettings)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (branchId != null) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// Inserts a new print setting.
  Future<int> insertPrintSetting(PrintSettingsCompanion setting) {
    if (!setting.businessId.present ||
        setting.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertPrintSetting requires businessId.',
      );
    }
    return into(printSettings).insert(setting);
  }

  /// Updates an existing print setting.
  Future<bool> updatePrintSetting(PrintSettingsCompanion setting) {
    if (!setting.businessId.present ||
        setting.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updatePrintSetting requires businessId.',
      );
    }
    return update(printSettings).replace(setting);
  }

  /// Hard-deletes a print setting (no deletedAt in schema).
  Future<int> deletePrintSetting(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(printSettings)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization print settings for a business.
  Future<List<PrintSetting>> getPendingSyncPrintSettings(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(printSettings)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified print setting IDs as synchronized.
  Future<int> markPrintSettingsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          printSettings,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const PrintSettingsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 6. SEQUENCES (businessId Scoped, Optional branchId)
  // ==========================================

  /// Retrieves a sequence configuration by ID within a business.
  Future<Sequence?> getSequenceById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(sequences)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a sequence configuration for a business, document type, and optional branch.
  Future<Sequence?> getSequence(
    String businessId,
    String documentType, {
    String? branchId,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(sequences)
      ..where(
        (tbl) =>
            tbl.businessId.equals(businessId) &
            tbl.documentType.equals(documentType),
      );
    if (branchId != null && branchId.isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    } else {
      query.where((tbl) => tbl.branchId.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists sequence configurations based on filter criteria.
  Future<List<Sequence>> listSequences(SequenceFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(sequences)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.documentType != null && filter.documentType!.isNotEmpty) {
      query.where((tbl) => tbl.documentType.equals(filter.documentType!));
    }
    if (filter.branchId != null) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    return query.get();
  }

  /// Reactive stream watching sequences for a business.
  Stream<List<Sequence>> watchSequences(String businessId, {String? branchId}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(sequences)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (branchId != null) {
      query.where((tbl) => tbl.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// Inserts a new sequence configuration.
  Future<int> insertSequence(SequencesCompanion sequence) {
    if (!sequence.businessId.present ||
        sequence.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertSequence requires businessId.');
    }
    return into(sequences).insert(sequence);
  }

  /// Updates an existing sequence configuration.
  Future<bool> updateSequence(SequencesCompanion sequence) {
    if (!sequence.businessId.present ||
        sequence.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateSequence requires businessId.');
    }
    return update(sequences).replace(sequence);
  }

  /// Hard-deletes a sequence configuration (no deletedAt in schema).
  Future<int> deleteSequence(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(sequences)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Atomically increments the sequence counter and returns the formatted document number.
  /// Example return format: `INV-00001-2026`.
  Future<String> incrementAndGetNextSequenceNumber(
    String businessId,
    String documentType, {
    String? branchId,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return transaction(() async {
      Sequence? seq;
      if (branchId != null && branchId.isNotEmpty) {
        seq =
            await (select(sequences)..where(
                  (tbl) =>
                      tbl.businessId.equals(businessId) &
                      tbl.documentType.equals(documentType) &
                      tbl.branchId.equals(branchId),
                ))
                .getSingleOrNull();
      }
      seq ??=
          await (select(sequences)..where(
                (tbl) =>
                    tbl.businessId.equals(businessId) &
                    tbl.documentType.equals(documentType) &
                    tbl.branchId.isNull(),
              ))
              .getSingleOrNull();

      if (seq == null) {
        throw RecordNotFoundException(
          'Sequence not found for businessId: $businessId, documentType: $documentType',
        );
      }

      final int nextValue = seq.currentValue + seq.step;
      final updatedSeq = seq.copyWith(currentValue: nextValue);
      await update(sequences).replace(updatedSeq);

      final prefixStr = seq.prefix ?? '';
      final suffixStr = seq.suffix ?? '';
      final paddedNumber = nextValue.toString().padLeft(seq.padding, '0');
      return '$prefixStr$paddedNumber$suffixStr';
    });
  }

  // ==========================================
  // 7. SYSTEM SETTINGS (businessId Scoped)
  // ==========================================

  /// Retrieves a system setting by primary key ID within a business.
  Future<SystemSetting?> getSystemSettingById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(systemSettings)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a system setting by its unique setting key within a business.
  Future<SystemSetting?> getSystemSettingByKey(
    String businessId,
    String settingKey,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(systemSettings)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) &
              tbl.settingKey.equals(settingKey),
        ))
        .getSingleOrNull();
  }

  /// Lists system settings based on typed filter criteria.
  Future<List<SystemSetting>> listSystemSettings(SystemSettingFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(systemSettings)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.settingKey != null && filter.settingKey!.isNotEmpty) {
      query.where((tbl) => tbl.settingKey.equals(filter.settingKey!));
    }
    if (filter.settingType != null && filter.settingType!.isNotEmpty) {
      query.where((tbl) => tbl.settingType.equals(filter.settingType!));
    }
    if (filter.isPublic != null) {
      query.where((tbl) => tbl.isPublic.equals(filter.isPublic!));
    }
    return query.get();
  }

  /// Reactive stream watching system settings for a business.
  Stream<List<SystemSetting>> watchSystemSettings(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(
      systemSettings,
    )..where((tbl) => tbl.businessId.equals(businessId))).watch();
  }

  /// Inserts a new system setting.
  Future<int> insertSystemSetting(SystemSettingsCompanion setting) {
    if (!setting.businessId.present ||
        setting.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertSystemSetting requires businessId.',
      );
    }
    return into(systemSettings).insert(setting);
  }

  /// Updates an existing system setting.
  Future<bool> updateSystemSetting(SystemSettingsCompanion setting) {
    if (!setting.businessId.present ||
        setting.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateSystemSetting requires businessId.',
      );
    }
    return update(systemSettings).replace(setting);
  }

  /// Hard-deletes a system setting (no deletedAt in schema).
  Future<int> deleteSystemSetting(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(systemSettings)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization system settings for a business.
  Future<List<SystemSetting>> getPendingSyncSystemSettings(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(systemSettings)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified system setting IDs as synchronized.
  Future<int> markSystemSettingsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          systemSettings,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const SystemSettingsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 8. TRANSACTIONAL SEEDING / SETUP
  // ==========================================

  /// Atomically seeds a new business along with its default branch and default numbering sequences.
  Future<void> createBusinessWithDefaults(
    BusinessesCompanion business,
    BranchesCompanion defaultBranch,
    List<SequencesCompanion> defaultSequences,
  ) {
    if (!business.id.present || business.id.value.trim().isEmpty) {
      throw const TenantScopingException(
        'createBusinessWithDefaults requires business.id.',
      );
    }
    return transaction(() async {
      await into(businesses).insert(business);
      await into(branches).insert(defaultBranch);
      for (final seq in defaultSequences) {
        await into(sequences).insert(seq);
      }
    });
  }
}
