import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/accounting_dao.dart';

/// Contract for Accounting & General Ledger domain data operations.
abstract class AccountingRepository {
  // Chart of Accounts
  Future<ChartOfAccount?> getChartOfAccountById(String id, String businessId);
  Future<ChartOfAccount?> getChartOfAccountByCode(
    String accountCode,
    String businessId,
  );
  Future<List<ChartOfAccount>> listChartOfAccounts(ChartOfAccountFilter filter);
  Stream<List<ChartOfAccount>> watchChartOfAccounts(
    ChartOfAccountFilter filter,
  );
  Future<List<ChartOfAccountNode>> getChartOfAccountsTree(
    String businessId, {
    String? parentAccountId,
  });
  Future<int> insertChartOfAccount(ChartOfAccountsCompanion companion);
  Future<bool> updateChartOfAccount(ChartOfAccountsCompanion companion);
  Future<bool> toggleAccountActiveStatus(
    String id,
    String businessId, {
    required bool isActive,
  });
  Future<List<ChartOfAccount>> getPendingSyncChartOfAccounts(String businessId);
  Future<int> markChartOfAccountsAsSynced(List<String> ids, String businessId);

  // Fiscal Years
  Future<FiscalYear?> getFiscalYearById(String id, String businessId);
  Future<List<FiscalYear>> listFiscalYears(FiscalYearFilter filter);
  Stream<List<FiscalYear>> watchFiscalYears(FiscalYearFilter filter);
  Future<int> insertFiscalYear(FiscalYearsCompanion companion);
  Future<bool> updateFiscalYear(FiscalYearsCompanion companion);

  // Fiscal Periods
  Future<FiscalPeriod?> getFiscalPeriodById(String id, String businessId);
  Future<List<FiscalPeriod>> listFiscalPeriods(FiscalPeriodFilter filter);
  Stream<List<FiscalPeriod>> watchFiscalPeriods(FiscalPeriodFilter filter);
  Future<int> insertFiscalPeriod(FiscalPeriodsCompanion companion);
  Future<bool> updateFiscalPeriod(FiscalPeriodsCompanion companion);

  // Accounting Periods
  Future<AccountingPeriod?> getAccountingPeriodById(
    String id,
    String businessId,
  );
  Future<List<AccountingPeriod>> listAccountingPeriods(
    AccountingPeriodFilter filter,
  );
  Stream<List<AccountingPeriod>> watchAccountingPeriods(
    AccountingPeriodFilter filter,
  );
  Future<int> insertAccountingPeriod(AccountingPeriodsCompanion companion);
  Future<bool> updateAccountingPeriod(AccountingPeriodsCompanion companion);
  Future<bool> updateAccountingPeriodStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<bool> checkPeriodLocked(String businessId, DateTime date);

  // Journal Entries
  Future<JournalEntry?> getJournalEntryById(String id, String businessId);
  Future<JournalEntryWithLines?> getJournalEntryWithLinesById(
    String id,
    String businessId,
  );
  Future<List<JournalEntry>> listJournalEntries(JournalEntryFilter filter);
  Stream<List<JournalEntry>> watchJournalEntries(JournalEntryFilter filter);
  Future<void> postJournalEntryWithLines({
    required JournalEntriesCompanion entry,
    required List<JournalEntryLinesCompanion> lines,
  });
  Future<bool> updateJournalEntryStatus(
    String id,
    String businessId,
    String newStatus,
  );

  // Opening Balances
  Future<OpeningBalance?> getOpeningBalanceById(String id, String businessId);
  Future<List<OpeningBalance>> listOpeningBalances(OpeningBalanceFilter filter);
  Stream<List<OpeningBalance>> watchOpeningBalances(
    OpeningBalanceFilter filter,
  );
  Future<int> recordOpeningBalance(OpeningBalancesCompanion companion);
  Future<void> recordOpeningBalances(List<OpeningBalancesCompanion> companions);

  // Account Mappings
  Future<AccountMapping?> getAccountMappingById(String id, String businessId);
  Future<AccountMapping?> getAccountMappingByKey(
    String mappingKey,
    String businessId,
  );
  Future<List<AccountMapping>> listAccountMappings(AccountMappingFilter filter);
  Stream<List<AccountMapping>> watchAccountMappings(
    AccountMappingFilter filter,
  );
  Future<int> insertAccountMapping(AccountMappingsCompanion companion);
  Future<bool> updateAccountMapping(AccountMappingsCompanion companion);

  // Payment Terms
  Future<PaymentTermEntity?> getPaymentTermById(String id, String businessId);
  Future<List<PaymentTermEntity>> listPaymentTerms(PaymentTermFilter filter);
  Stream<List<PaymentTermEntity>> watchPaymentTerms(PaymentTermFilter filter);
  Future<int> insertPaymentTerm(PaymentTermsCompanion companion);
  Future<bool> updatePaymentTerm(PaymentTermsCompanion companion);
  Future<bool> togglePaymentTermActiveStatus(
    String id,
    String businessId, {
    required bool isActive,
  });
}
