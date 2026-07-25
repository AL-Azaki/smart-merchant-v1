import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/core_dao.dart';

/// Contract for Core Foundation domain data operations.
/// Isolates application use cases from Drift ORM and SQLite specifics while
/// preserving multi-tenant (`businessId`), branch (`branchId`), offline-sync, and reactive stream semantics.
abstract class CoreRepository {
  // Account Types
  Future<AccountType?> getAccountTypeById(int id);
  Future<AccountType?> getAccountTypeBySlug(String slug);
  Future<List<AccountType>> listAccountTypes({bool? isActive});
  Future<int> insertAccountType(AccountTypesCompanion accountType);
  Future<bool> updateAccountType(AccountTypesCompanion accountType);

  // Currencies
  Future<CurrencyEntity?> getCurrencyById(String id);
  Future<CurrencyEntity?> getCurrencyByCode(String currencyCode);
  Future<CurrencyEntity?> getBaseCurrency();
  Future<List<CurrencyEntity>> listCurrencies({bool? isActive});
  Future<int> insertCurrency(CurrenciesCompanion currency);
  Future<bool> updateCurrency(CurrenciesCompanion currency);
  Future<List<CurrencyEntity>> getPendingSyncCurrencies({int limit = 500});
  Future<int> markCurrenciesAsSynced(List<String> ids);

  // Businesses
  Future<BusinessEntity?> getBusinessById(
    String id, {
    bool includeDeleted = false,
  });
  Future<List<BusinessEntity>> listBusinesses(BusinessFilter filter);
  Stream<BusinessEntity?> watchBusinessById(
    String id, {
    bool includeDeleted = false,
  });
  Stream<List<BusinessEntity>> watchBusinessesByAccountId(
    String accountId, {
    bool includeDeleted = false,
  });
  Future<int> insertBusiness(BusinessesCompanion business);
  Future<bool> updateBusiness(BusinessesCompanion business);
  Future<int> softDeleteBusiness(String id, String accountId);
  Future<int> restoreBusiness(String id, String accountId);
  Future<List<BusinessEntity>> listArchivedBusinesses({String? accountId});
  Future<List<BusinessEntity>> getPendingSyncBusinesses({int limit = 500});
  Future<int> markBusinessesAsSynced(List<String> ids);

  // Branches
  Future<BranchEntity?> getBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<BranchEntity?> getDefaultBranch(
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<BranchEntity>> listBranches(BranchFilter filter);
  Stream<BranchEntity?> watchBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Stream<List<BranchEntity>> watchActiveBranches(String businessId);
  Future<int> insertBranch(BranchesCompanion branch);
  Future<bool> updateBranch(BranchesCompanion branch);
  Future<int> softDeleteBranch(String id, String businessId);
  Future<int> restoreBranch(String id, String businessId);
  Future<List<BranchEntity>> listArchivedBranches(String businessId);
  Future<List<BranchEntity>> getPendingSyncBranches(
    String businessId, {
    int limit = 500,
  });
  Future<int> markBranchesAsSynced(List<String> ids, String businessId);

  // Print Settings
  Future<PrintSetting?> getPrintSettingById(String id, String businessId);
  Future<PrintSetting?> getEffectivePrintSetting(
    String businessId,
    String documentType, {
    String? branchId,
  });
  Future<List<PrintSetting>> listPrintSettings(
    String businessId, {
    String? branchId,
  });
  Stream<List<PrintSetting>> watchPrintSettings(
    String businessId, {
    String? branchId,
  });
  Future<int> insertPrintSetting(PrintSettingsCompanion setting);
  Future<bool> updatePrintSetting(PrintSettingsCompanion setting);
  Future<int> deletePrintSetting(String id, String businessId);
  Future<List<PrintSetting>> getPendingSyncPrintSettings(
    String businessId, {
    int limit = 500,
  });
  Future<int> markPrintSettingsAsSynced(List<String> ids, String businessId);

  // Sequences
  Future<Sequence?> getSequenceById(String id, String businessId);
  Future<Sequence?> getSequence(
    String businessId,
    String documentType, {
    String? branchId,
  });
  Future<List<Sequence>> listSequences(SequenceFilter filter);
  Stream<List<Sequence>> watchSequences(String businessId, {String? branchId});
  Future<int> insertSequence(SequencesCompanion sequence);
  Future<bool> updateSequence(SequencesCompanion sequence);
  Future<int> deleteSequence(String id, String businessId);
  Future<String> incrementAndGetNextSequenceNumber(
    String businessId,
    String documentType, {
    String? branchId,
  });

  // System Settings
  Future<SystemSetting?> getSystemSettingById(String id, String businessId);
  Future<SystemSetting?> getSystemSettingByKey(
    String businessId,
    String settingKey,
  );
  Future<List<SystemSetting>> listSystemSettings(SystemSettingFilter filter);
  Stream<List<SystemSetting>> watchSystemSettings(String businessId);
  Future<int> insertSystemSetting(SystemSettingsCompanion setting);
  Future<bool> updateSystemSetting(SystemSettingsCompanion setting);
  Future<int> deleteSystemSetting(String id, String businessId);
  Future<List<SystemSetting>> getPendingSyncSystemSettings(
    String businessId, {
    int limit = 500,
  });
  Future<int> markSystemSettingsAsSynced(List<String> ids, String businessId);

  // Transactional Setup
  Future<void> createBusinessWithDefaults(
    BusinessesCompanion business,
    BranchesCompanion defaultBranch,
    List<SequencesCompanion> defaultSequences,
  );
}
