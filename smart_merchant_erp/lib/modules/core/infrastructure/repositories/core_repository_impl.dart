import 'package:injectable/injectable.dart';
import '../../domain/repositories/core_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/core_dao.dart';

@LazySingleton(as: CoreRepository)
class CoreRepositoryImpl implements CoreRepository {
  final CoreDao _dao;

  CoreRepositoryImpl(this._dao);

  // Account Types
  @override
  Future<AccountType?> getAccountTypeById(int id) {
    return RepositoryErrorGuard.run(() => _dao.getAccountTypeById(id));
  }

  @override
  Future<AccountType?> getAccountTypeBySlug(String slug) {
    return RepositoryErrorGuard.run(() => _dao.getAccountTypeBySlug(slug));
  }

  @override
  Future<List<AccountType>> listAccountTypes({bool? isActive}) {
    return RepositoryErrorGuard.run(
      () => _dao.listAccountTypes(isActive: isActive),
    );
  }

  @override
  Future<int> insertAccountType(AccountTypesCompanion accountType) {
    return RepositoryErrorGuard.run(() => _dao.insertAccountType(accountType));
  }

  @override
  Future<bool> updateAccountType(AccountTypesCompanion accountType) {
    return RepositoryErrorGuard.run(() => _dao.updateAccountType(accountType));
  }

  // Currencies
  @override
  Future<CurrencyEntity?> getCurrencyById(String id) {
    return RepositoryErrorGuard.run(() => _dao.getCurrencyById(id));
  }

  @override
  Future<CurrencyEntity?> getCurrencyByCode(String currencyCode) {
    return RepositoryErrorGuard.run(() => _dao.getCurrencyByCode(currencyCode));
  }

  @override
  Future<CurrencyEntity?> getBaseCurrency() {
    return RepositoryErrorGuard.run(() => _dao.getBaseCurrency());
  }

  @override
  Future<List<CurrencyEntity>> listCurrencies({bool? isActive}) {
    return RepositoryErrorGuard.run(
      () => _dao.listCurrencies(isActive: isActive),
    );
  }

  @override
  Future<int> insertCurrency(CurrenciesCompanion currency) {
    return RepositoryErrorGuard.run(() => _dao.insertCurrency(currency));
  }

  @override
  Future<bool> updateCurrency(CurrenciesCompanion currency) {
    return RepositoryErrorGuard.run(() => _dao.updateCurrency(currency));
  }

  @override
  Future<List<CurrencyEntity>> getPendingSyncCurrencies({int limit = 500}) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncCurrencies(limit: limit),
    );
  }

  @override
  Future<int> markCurrenciesAsSynced(List<String> ids) {
    return RepositoryErrorGuard.run(() => _dao.markCurrenciesAsSynced(ids));
  }

  // Businesses
  @override
  Future<BusinessEntity?> getBusinessById(
    String id, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getBusinessById(id, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<List<BusinessEntity>> listBusinesses(BusinessFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listBusinesses(filter));
  }

  @override
  Stream<BusinessEntity?> watchBusinessById(
    String id, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBusinessById(id, includeDeleted: includeDeleted),
    );
  }

  @override
  Stream<List<BusinessEntity>> watchBusinessesByAccountId(
    String accountId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBusinessesByAccountId(
        accountId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<int> insertBusiness(BusinessesCompanion business) {
    return RepositoryErrorGuard.run(() => _dao.insertBusiness(business));
  }

  @override
  Future<bool> updateBusiness(BusinessesCompanion business) {
    return RepositoryErrorGuard.run(() => _dao.updateBusiness(business));
  }

  @override
  Future<int> softDeleteBusiness(String id, String accountId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteBusiness(id, accountId),
    );
  }

  @override
  Future<int> restoreBusiness(String id, String accountId) {
    return RepositoryErrorGuard.run(() => _dao.restoreBusiness(id, accountId));
  }

  @override
  Future<List<BusinessEntity>> listArchivedBusinesses({String? accountId}) {
    return RepositoryErrorGuard.run(
      () => _dao.listArchivedBusinesses(accountId: accountId),
    );
  }

  @override
  Future<List<BusinessEntity>> getPendingSyncBusinesses({int limit = 500}) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncBusinesses(limit: limit),
    );
  }

  @override
  Future<int> markBusinessesAsSynced(List<String> ids) {
    return RepositoryErrorGuard.run(() => _dao.markBusinessesAsSynced(ids));
  }

  // Branches
  @override
  Future<BranchEntity?> getBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getBranchById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<BranchEntity?> getDefaultBranch(
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getDefaultBranch(businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<List<BranchEntity>> listBranches(BranchFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listBranches(filter));
  }

  @override
  Stream<BranchEntity?> watchBranchById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBranchById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Stream<List<BranchEntity>> watchActiveBranches(String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchActiveBranches(businessId),
    );
  }

  @override
  Future<int> insertBranch(BranchesCompanion branch) {
    return RepositoryErrorGuard.run(() => _dao.insertBranch(branch));
  }

  @override
  Future<bool> updateBranch(BranchesCompanion branch) {
    return RepositoryErrorGuard.run(() => _dao.updateBranch(branch));
  }

  @override
  Future<int> softDeleteBranch(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteBranch(id, businessId),
    );
  }

  @override
  Future<int> restoreBranch(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreBranch(id, businessId));
  }

  @override
  Future<List<BranchEntity>> listArchivedBranches(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.listArchivedBranches(businessId),
    );
  }

  @override
  Future<List<BranchEntity>> getPendingSyncBranches(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncBranches(businessId, limit: limit),
    );
  }

  @override
  Future<int> markBranchesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markBranchesAsSynced(ids, businessId),
    );
  }

  // Print Settings
  @override
  Future<PrintSetting?> getPrintSettingById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPrintSettingById(id, businessId),
    );
  }

  @override
  Future<PrintSetting?> getEffectivePrintSetting(
    String businessId,
    String documentType, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getEffectivePrintSetting(
        businessId,
        documentType,
        branchId: branchId,
      ),
    );
  }

  @override
  Future<List<PrintSetting>> listPrintSettings(
    String businessId, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.listPrintSettings(businessId, branchId: branchId),
    );
  }

  @override
  Stream<List<PrintSetting>> watchPrintSettings(
    String businessId, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchPrintSettings(businessId, branchId: branchId),
    );
  }

  @override
  Future<int> insertPrintSetting(PrintSettingsCompanion setting) {
    return RepositoryErrorGuard.run(() => _dao.insertPrintSetting(setting));
  }

  @override
  Future<bool> updatePrintSetting(PrintSettingsCompanion setting) {
    return RepositoryErrorGuard.run(() => _dao.updatePrintSetting(setting));
  }

  @override
  Future<int> deletePrintSetting(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.deletePrintSetting(id, businessId),
    );
  }

  @override
  Future<List<PrintSetting>> getPendingSyncPrintSettings(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncPrintSettings(businessId, limit: limit),
    );
  }

  @override
  Future<int> markPrintSettingsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markPrintSettingsAsSynced(ids, businessId),
    );
  }

  // Sequences
  @override
  Future<Sequence?> getSequenceById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getSequenceById(id, businessId));
  }

  @override
  Future<Sequence?> getSequence(
    String businessId,
    String documentType, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getSequence(businessId, documentType, branchId: branchId),
    );
  }

  @override
  Future<List<Sequence>> listSequences(SequenceFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listSequences(filter));
  }

  @override
  Stream<List<Sequence>> watchSequences(String businessId, {String? branchId}) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchSequences(businessId, branchId: branchId),
    );
  }

  @override
  Future<int> insertSequence(SequencesCompanion sequence) {
    return RepositoryErrorGuard.run(() => _dao.insertSequence(sequence));
  }

  @override
  Future<bool> updateSequence(SequencesCompanion sequence) {
    return RepositoryErrorGuard.run(() => _dao.updateSequence(sequence));
  }

  @override
  Future<int> deleteSequence(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteSequence(id, businessId));
  }

  @override
  Future<String> incrementAndGetNextSequenceNumber(
    String businessId,
    String documentType, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.incrementAndGetNextSequenceNumber(
        businessId,
        documentType,
        branchId: branchId,
      ),
    );
  }

  // System Settings
  @override
  Future<SystemSetting?> getSystemSettingById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getSystemSettingById(id, businessId),
    );
  }

  @override
  Future<SystemSetting?> getSystemSettingByKey(
    String businessId,
    String settingKey,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getSystemSettingByKey(businessId, settingKey),
    );
  }

  @override
  Future<List<SystemSetting>> listSystemSettings(SystemSettingFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listSystemSettings(filter));
  }

  @override
  Stream<List<SystemSetting>> watchSystemSettings(String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchSystemSettings(businessId),
    );
  }

  @override
  Future<int> insertSystemSetting(SystemSettingsCompanion setting) {
    return RepositoryErrorGuard.run(() => _dao.insertSystemSetting(setting));
  }

  @override
  Future<bool> updateSystemSetting(SystemSettingsCompanion setting) {
    return RepositoryErrorGuard.run(() => _dao.updateSystemSetting(setting));
  }

  @override
  Future<int> deleteSystemSetting(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteSystemSetting(id, businessId),
    );
  }

  @override
  Future<List<SystemSetting>> getPendingSyncSystemSettings(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncSystemSettings(businessId, limit: limit),
    );
  }

  @override
  Future<int> markSystemSettingsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markSystemSettingsAsSynced(ids, businessId),
    );
  }

  // Transactional Setup
  @override
  Future<void> createBusinessWithDefaults(
    BusinessesCompanion business,
    BranchesCompanion defaultBranch,
    List<SequencesCompanion> defaultSequences,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.createBusinessWithDefaults(
        business,
        defaultBranch,
        defaultSequences,
      ),
    );
  }
}
