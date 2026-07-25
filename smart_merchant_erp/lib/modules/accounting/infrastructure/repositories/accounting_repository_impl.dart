import 'package:injectable/injectable.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/accounting_dao.dart';

@LazySingleton(as: AccountingRepository)
class AccountingRepositoryImpl implements AccountingRepository {
  final AccountingDao _dao;

  AccountingRepositoryImpl(this._dao);

  // Chart of Accounts
  @override
  Future<ChartOfAccount?> getChartOfAccountById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getChartOfAccountById(id, businessId),
    );
  }

  @override
  Future<ChartOfAccount?> getChartOfAccountByCode(
    String accountCode,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getChartOfAccountByCode(accountCode, businessId),
    );
  }

  @override
  Future<List<ChartOfAccount>> listChartOfAccounts(
    ChartOfAccountFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listChartOfAccounts(filter));
  }

  @override
  Stream<List<ChartOfAccount>> watchChartOfAccounts(
    ChartOfAccountFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchChartOfAccounts(filter));
  }

  @override
  Future<List<ChartOfAccountNode>> getChartOfAccountsTree(
    String businessId, {
    String? parentAccountId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getChartOfAccountsTree(
        businessId,
        rootParentAccountId: parentAccountId,
      ),
    );
  }

  @override
  Future<int> insertChartOfAccount(ChartOfAccountsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertChartOfAccount(companion));
  }

  @override
  Future<bool> updateChartOfAccount(ChartOfAccountsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateChartOfAccount(companion));
  }

  @override
  Future<bool> toggleAccountActiveStatus(
    String id,
    String businessId, {
    required bool isActive,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.toggleAccountActiveStatus(id, businessId, isActive),
    );
  }

  @override
  Future<List<ChartOfAccount>> getPendingSyncChartOfAccounts(
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncChartOfAccounts(businessId),
    );
  }

  @override
  Future<int> markChartOfAccountsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markChartOfAccountsAsSynced(ids, businessId),
    );
  }

  // Fiscal Years
  @override
  Future<FiscalYear?> getFiscalYearById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getFiscalYearById(id, businessId),
    );
  }

  @override
  Future<List<FiscalYear>> listFiscalYears(FiscalYearFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listFiscalYears(filter));
  }

  @override
  Stream<List<FiscalYear>> watchFiscalYears(FiscalYearFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchFiscalYears(filter));
  }

  @override
  Future<int> insertFiscalYear(FiscalYearsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertFiscalYear(companion));
  }

  @override
  Future<bool> updateFiscalYear(FiscalYearsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateFiscalYear(companion));
  }

  // Fiscal Periods
  @override
  Future<FiscalPeriod?> getFiscalPeriodById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getFiscalPeriodById(id, businessId),
    );
  }

  @override
  Future<List<FiscalPeriod>> listFiscalPeriods(FiscalPeriodFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listFiscalPeriods(filter));
  }

  @override
  Stream<List<FiscalPeriod>> watchFiscalPeriods(FiscalPeriodFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchFiscalPeriods(filter));
  }

  @override
  Future<int> insertFiscalPeriod(FiscalPeriodsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertFiscalPeriod(companion));
  }

  @override
  Future<bool> updateFiscalPeriod(FiscalPeriodsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateFiscalPeriod(companion));
  }

  // Accounting Periods
  @override
  Future<AccountingPeriod?> getAccountingPeriodById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getAccountingPeriodById(id, businessId),
    );
  }

  @override
  Future<List<AccountingPeriod>> listAccountingPeriods(
    AccountingPeriodFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listAccountingPeriods(filter));
  }

  @override
  Stream<List<AccountingPeriod>> watchAccountingPeriods(
    AccountingPeriodFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchAccountingPeriods(filter),
    );
  }

  @override
  Future<int> insertAccountingPeriod(AccountingPeriodsCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.insertAccountingPeriod(companion),
    );
  }

  @override
  Future<bool> updateAccountingPeriod(AccountingPeriodsCompanion companion) {
    return RepositoryErrorGuard.run(
      () => _dao.updateAccountingPeriod(companion),
    );
  }

  @override
  Future<bool> updateAccountingPeriodStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateAccountingPeriodStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<bool> checkPeriodLocked(String businessId, DateTime date) {
    return RepositoryErrorGuard.run(
      () => _dao.checkPeriodLocked(businessId, date),
    );
  }

  // Journal Entries
  @override
  Future<JournalEntry?> getJournalEntryById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getJournalEntryById(id, businessId),
    );
  }

  @override
  Future<JournalEntryWithLines?> getJournalEntryWithLinesById(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getJournalEntryWithLinesById(id, businessId),
    );
  }

  @override
  Future<List<JournalEntry>> listJournalEntries(JournalEntryFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listJournalEntries(filter));
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntries(JournalEntryFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchJournalEntries(filter));
  }

  @override
  Future<void> postJournalEntryWithLines({
    required JournalEntriesCompanion entry,
    required List<JournalEntryLinesCompanion> lines,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.postJournalEntryWithLines(entry, lines),
    );
  }

  @override
  Future<bool> updateJournalEntryStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateJournalEntryStatus(id, businessId, newStatus),
    );
  }

  // Opening Balances
  @override
  Future<OpeningBalance?> getOpeningBalanceById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getOpeningBalanceById(id, businessId),
    );
  }

  @override
  Future<List<OpeningBalance>> listOpeningBalances(
    OpeningBalanceFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listOpeningBalances(filter));
  }

  @override
  Stream<List<OpeningBalance>> watchOpeningBalances(
    OpeningBalanceFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchOpeningBalances(filter));
  }

  @override
  Future<int> recordOpeningBalance(OpeningBalancesCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.recordOpeningBalance(companion));
  }

  @override
  Future<void> recordOpeningBalances(
    List<OpeningBalancesCompanion> companions,
  ) {
    // Extract businessId from the first companion; guard ensures non-empty businessId
    final businessId =
        companions.isNotEmpty && companions.first.businessId.present
        ? companions.first.businessId.value
        : '';
    return RepositoryErrorGuard.run(
      () => _dao.recordOpeningBalances(companions, businessId),
    );
  }

  // Account Mappings
  @override
  Future<AccountMapping?> getAccountMappingById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getAccountMappingById(id, businessId),
    );
  }

  @override
  Future<AccountMapping?> getAccountMappingByKey(
    String mappingKey,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getAccountMappingByKey(mappingKey, businessId),
    );
  }

  @override
  Future<List<AccountMapping>> listAccountMappings(
    AccountMappingFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listAccountMappings(filter));
  }

  @override
  Stream<List<AccountMapping>> watchAccountMappings(
    AccountMappingFilter filter,
  ) {
    return RepositoryErrorGuard.guardStream(_dao.watchAccountMappings(filter));
  }

  @override
  Future<int> insertAccountMapping(AccountMappingsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertAccountMapping(companion));
  }

  @override
  Future<bool> updateAccountMapping(AccountMappingsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateAccountMapping(companion));
  }

  // Payment Terms
  @override
  Future<PaymentTermEntity?> getPaymentTermById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getPaymentTermById(id, businessId),
    );
  }

  @override
  Future<List<PaymentTermEntity>> listPaymentTerms(PaymentTermFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listPaymentTerms(filter));
  }

  @override
  Stream<List<PaymentTermEntity>> watchPaymentTerms(PaymentTermFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchPaymentTerms(filter));
  }

  @override
  Future<int> insertPaymentTerm(PaymentTermsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertPaymentTerm(companion));
  }

  @override
  Future<bool> updatePaymentTerm(PaymentTermsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updatePaymentTerm(companion));
  }

  @override
  Future<bool> togglePaymentTermActiveStatus(
    String id,
    String businessId, {
    required bool isActive,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.togglePaymentTermActiveStatus(id, businessId, isActive),
    );
  }
}
