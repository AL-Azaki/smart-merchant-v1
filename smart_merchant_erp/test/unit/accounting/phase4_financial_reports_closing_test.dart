import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/kernel/storage/app_database.dart' hide Unit;
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/database/seeders/default_coa_seeder.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/trial_balance_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/profit_loss_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/account_statement_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/usecases/post_journal_entry_usecase.dart';
import 'package:smart_merchant_erp/modules/accounting/application/usecases/year_end_closing_usecase.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AccountingDao accountingDao;
  late CoreDao coreDao;
  late AccountingRepositoryImpl accountingRepo;
  late CoreRepositoryImpl coreRepo;
  late StaticApplicationContext appContext;
  late ApplicationTransactionRunner transactionRunner;
  late AccountingApplicationService accountingService;
  late PostJournalEntryUseCase postJournalUseCase;
  late TrialBalanceService trialBalanceService;
  late ProfitLossService profitLossService;
  late AccountStatementService statementService;
  late YearEndClosingUseCase yearEndClosingUseCase;

  const testBusinessId = 'biz-phase4-test';
  const testUserId = 'user-phase4-test';
  const uuid = Uuid();

  late String fiscalYearId;
  late String fiscalPeriodId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    accountingDao = AccountingDao(db);
    coreDao = CoreDao(db);
    accountingRepo = AccountingRepositoryImpl(accountingDao);
    coreRepo = CoreRepositoryImpl(coreDao);
    transactionRunner = ApplicationTransactionRunnerImpl(db);

    appContext = const StaticApplicationContext(
      businessId: testBusinessId,
      branchId: 'branch-phase4-test',
      userId: testUserId,
    );

    accountingService = AccountingApplicationService(accountingRepo, appContext);
    postJournalUseCase = PostJournalEntryUseCase(
      accountingRepo,
      coreRepo,
      appContext,
      transactionRunner,
    );
    trialBalanceService = TrialBalanceService(accountingRepo, appContext);
    profitLossService = ProfitLossService(accountingRepo, appContext);
    statementService = AccountStatementService(accountingRepo, appContext);
    yearEndClosingUseCase = YearEndClosingUseCase(
      accountingRepo,
      accountingService,
      appContext,
      transactionRunner,
    );

    // 1. Seed Business
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: testBusinessId,
        accountId: 'acc-p4-test',
        businessName: 'Phase 4 Reporting Enterprise',
        status: const drift.Value('Active'),
      ),
    );

    // 2. Seed Fiscal Year and Period
    fiscalYearId = 'fy-2026';
    await db.into(db.fiscalYears).insert(
      FiscalYearsCompanion.insert(
        id: fiscalYearId,
        businessId: testBusinessId,
        fiscalYearCode: 'FY-2026',
        fiscalYearName: 'السنة المالية 2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: const drift.Value('Open'),
      ),
    );

    fiscalPeriodId = 'fp-2026-01';
    await db.into(db.fiscalPeriods).insert(
      FiscalPeriodsCompanion.insert(
        id: fiscalPeriodId,
        businessId: testBusinessId,
        fiscalYearId: fiscalYearId,
        periodName: 'فترة يناير 2026',
        periodNumber: 1,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        status: const drift.Value('Open'),
      ),
    );

    // 3. Seed Default Chart of Accounts
    final coaSeeder = DefaultChartOfAccountsSeeder(db);
    await coaSeeder.seedChartOfAccounts(businessId: testBusinessId);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4: Financial Reports Engine & Period Closing Suite', () {
    test('AC-4.1: AccountStatementService builds accurate chronological statement with opening balance and running balances', () async {
      final cashAccount = (await accountingDao.getChartOfAccountByCode('11101', testBusinessId))!;
      final arAccount = (await accountingDao.getChartOfAccountByCode('11201', testBusinessId))!;

      // Day 1: Debit Cash 10,000 / Credit AR 10,000
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 2),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 10000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: arAccount.id, debit: 0.0, credit: 10000.0),
          ],
        ),
      );

      // Day 5: Debit Cash 5,000 / Credit AR 5,000
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 5000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: arAccount.id, debit: 0.0, credit: 5000.0),
          ],
        ),
      );

      // Generate Statement for Cash starting from Day 4 (Jan 5)
      final statement = await statementService.generateStatement(
        accountId: cashAccount.id,
        startDate: DateTime(2026, 1, 5),
      );

      expect(statement, isNotNull);
      expect(statement!.openingBalance, equals(10000.0));
      expect(statement.lines.length, equals(1));
      expect(statement.lines.first.debit, equals(5000.0));
      expect(statement.lines.first.runningBalance, equals(15000.0));
      expect(statement.closingBalance, equals(15000.0));
    });

    test('AC-4.2: TrialBalanceService maintains golden balance invariant (Sum Debit == Sum Credit)', () async {
      final cashAccount = (await accountingDao.getChartOfAccountByCode('11101', testBusinessId))!;
      final salesAccount = (await accountingDao.getChartOfAccountByCode('41', testBusinessId))!;
      final rentAccount = (await accountingDao.getChartOfAccountByCode('52001', testBusinessId))!;

      // 1. Sale: Debit Cash 50,000 / Credit Sales 50,000
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 5),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 50000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: salesAccount.id, debit: 0.0, credit: 50000.0),
          ],
        ),
      );

      // 2. Rent Expense: Debit Rent 15,000 / Credit Cash 15,000
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: rentAccount.id, debit: 15000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 0.0, credit: 15000.0),
          ],
        ),
      );

      final report = await trialBalanceService.generateTrialBalance();

      expect(report.isBalanced, isTrue);
      expect(report.grandTotalDebit, equals(65000.0));
      expect(report.grandTotalCredit, equals(65000.0));
      expect(report.grandNetDebit, equals(report.grandNetCredit));
    });

    test('AC-4.3: ProfitLossService calculates Gross Profit, COGS, and Net Operating Profit accurately', () async {
      final cashAccount = (await accountingDao.getChartOfAccountByCode('11101', testBusinessId))!;
      final salesAccount = (await accountingDao.getChartOfAccountByCode('41', testBusinessId))!;
      final cogsAccount = (await accountingDao.getChartOfAccountByCode('51', testBusinessId))!;
      final invAccount = (await accountingDao.getChartOfAccountByCode('11301', testBusinessId))!;
      final rentAccount = (await accountingDao.getChartOfAccountByCode('52001', testBusinessId))!;

      // Revenue: 100,000 YER
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 100000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: salesAccount.id, debit: 0.0, credit: 100000.0),
          ],
        ),
      );

      // COGS: 60,000 YER
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cogsAccount.id, debit: 60000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: invAccount.id, debit: 0.0, credit: 60000.0),
          ],
        ),
      );

      // Operating Expense (Rent): 15,000 YER
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 15),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: rentAccount.id, debit: 15000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 0.0, credit: 15000.0),
          ],
        ),
      );

      final pnl = await profitLossService.generateProfitLoss();

      expect(pnl.totalRevenue, equals(100000.0));
      expect(pnl.totalCogs, equals(60000.0));
      expect(pnl.grossProfit, equals(40000.0)); // 100k - 60k
      expect(pnl.totalExpenses, equals(15000.0));
      expect(pnl.netProfit, equals(25000.0)); // 40k - 15k
    });

    test('AC-4.4: Period Lock Guardrail rejects transactions dated in closed periods', () async {
      final cashAccount = (await accountingDao.getChartOfAccountByCode('11101', testBusinessId))!;
      final salesAccount = (await accountingDao.getChartOfAccountByCode('41', testBusinessId))!;

      // Close the period
      await db.update(db.fiscalPeriods).write(
        const FiscalPeriodsCompanion(status: drift.Value('Closed')),
      );

      // Attempt to post entry into closed period
      final result = await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 15),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 5000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: salesAccount.id, debit: 0.0, credit: 5000.0),
          ],
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('مغلقة')),
        (_) => fail('Should have rejected posting in closed period'),
      );
    });

    test('AC-4.5: YearEndClosingUseCase zeroes Revenue & Expenses and transfers net profit to Retained Earnings', () async {
      final cashAccount = (await accountingDao.getChartOfAccountByCode('11101', testBusinessId))!;
      final salesAccount = (await accountingDao.getChartOfAccountByCode('41', testBusinessId))!;
      final rentAccount = (await accountingDao.getChartOfAccountByCode('52001', testBusinessId))!;
      final retainedAccount = (await accountingDao.getChartOfAccountByCode('32', testBusinessId))!;

      // 1. Post Revenue: 80,000 YER
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 80000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: salesAccount.id, debit: 0.0, credit: 80000.0),
          ],
        ),
      );

      // 2. Post Expense: 30,000 YER
      await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime(2026, 1, 15),
          journalType: 'Manual',
          currencyId: 'YER',
          lines: [
            JournalEntryLineCommand(accountId: rentAccount.id, debit: 30000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 0.0, credit: 30000.0),
          ],
        ),
      );

      // Execute Year-End Closing
      final closeResult = await yearEndClosingUseCase(
        YearEndClosingCommand(
          fiscalYearId: fiscalYearId,
          closingDate: DateTime(2026, 12, 31),
        ),
      );

      expect(closeResult.isRight(), isTrue);

      // Verify that Trial Balance shows net zero on Revenue & Expenses, and Retained Earnings has +50,000 credit
      final trialBalance = await trialBalanceService.generateTrialBalance();
      expect(trialBalance.isBalanced, isTrue);

      // Sales account net balance must be zero
      final salesItem = trialBalance.items.firstWhere((i) => i.accountId == salesAccount.id);
      expect(salesItem.netDebit, equals(0.0));
      expect(salesItem.netCredit, equals(0.0));

      // Rent account net balance must be zero
      final rentItem = trialBalance.items.firstWhere((i) => i.accountId == rentAccount.id);
      expect(rentItem.netDebit, equals(0.0));
      expect(rentItem.netCredit, equals(0.0));

      // Retained Earnings item must have 50,000 YER net credit
      final retainedItem = trialBalance.items.firstWhere((i) => i.accountId == retainedAccount.id);
      expect(retainedItem.netCredit, equals(50000.0));

      // Fiscal Year status must be 'Closed'
      final fy = await accountingDao.getFiscalYearById(fiscalYearId, testBusinessId);
      expect(fy!.status, equals('Closed'));
    });

    test('AC-4.6: YearEndClosingUseCase rejects execution if Draft journal entries exist', () async {
      // Insert a Draft journal entry
      await db.into(db.journalEntries).insert(
        JournalEntriesCompanion.insert(
          id: uuid.v4(),
          businessId: testBusinessId,
          fiscalYearId: fiscalYearId,
          fiscalPeriodId: fiscalPeriodId,
          journalNumber: 'JE-DRAFT-01',
          documentDate: DateTime(2026, 1, 10),
          journalType: 'Manual',
          documentType: 'Manual',
          currencyId: 'YER',
          createdBy: testUserId,
          status: const drift.Value('Draft'),
        ),
      );

      final result = await yearEndClosingUseCase(
        YearEndClosingCommand(
          fiscalYearId: fiscalYearId,
          closingDate: DateTime(2026, 12, 31),
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, contains('مسودة')),
        (_) => fail('Should have rejected closing due to draft entries'),
      );
    });
  });
}
