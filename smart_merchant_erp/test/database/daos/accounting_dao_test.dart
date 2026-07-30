import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late AccountingDao accountingDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    accountingDao = AccountingDao(database);

    // Seed required parent User, Account, Businesses, Branches, Currencies, and AccountTypes
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@accounting.com',
            passwordHash: 'hash',
            firstName: 'Accounting',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-accounting-01'),
            ownerId: 'u-owner',
            businessName: 'Accounting Account',
            businessType: 'Enterprise',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-accounting-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-accounting-01',
            businessName: 'Business Beta',
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_1',
            businessId: 'BUS_A',
            branchName: 'Main Branch Alpha',
            branchCode: 'BR-A1',
            isDefault: const drift.Value(true),
          ),
        );
    

    // Seed AccountTypes
    await database
        .into(database.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: const drift.Value(1),
            nameEn: 'Assets',
            nameAr: 'الأصول',
            slug: 'assets',
          ),
        );
    await database
        .into(database.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: const drift.Value(2),
            nameEn: 'Liabilities',
            nameAr: 'الخصوم',
            slug: 'liabilities',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('AccountingDao Phase 06 Test Suite -', () {
    test(
      '1. Core CRUD: ChartOfAccounts, FiscalYears, FiscalPeriods, AccountingPeriods, AccountMappings, PaymentTerms',
      () async {
        // 1. ChartOfAccounts
        final coaId = await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('coa-01'),
            businessId: drift.Value('BUS_A'),
            accountCode: drift.Value('1000'),
            accountName: drift.Value('Cash on Hand'),
            accountTypeId: drift.Value(1),
            normalBalance: drift.Value('Debit'),
            accountLevel: drift.Value(1),
            allowPosting: drift.Value(true),
          ),
        );
        expect(coaId, isPositive);

        final coa = await accountingDao.getChartOfAccountById(
          'coa-01',
          'BUS_A',
        );
        expect(coa, isNotNull);
        expect(coa!.accountCode, equals('1000'));
        expect(coa.accountName, equals('Cash on Hand'));

        final coaByCode = await accountingDao.getChartOfAccountByCode(
          '1000',
          'BUS_A',
        );
        expect(coaByCode, isNotNull);
        expect(coaByCode!.id, equals('coa-01'));

        await accountingDao.toggleAccountActiveStatus('coa-01', 'BUS_A', false);
        final coaInactive = await accountingDao.getChartOfAccountById(
          'coa-01',
          'BUS_A',
        );
        expect(coaInactive!.isActive, isFalse);
        expect(coaInactive.syncStatus, equals('pending_update'));

        // 2. FiscalYears
        await accountingDao.insertFiscalYear(
          FiscalYearsCompanion.insert(
            id: 'fy-2026',
            businessId: 'BUS_A',
            fiscalYearCode: 'FY2026',
            fiscalYearName: 'Fiscal Year 2026',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            status: const drift.Value('Open'),
          ),
        );
        final fy = await accountingDao.getFiscalYearById('fy-2026', 'BUS_A');
        expect(fy, isNotNull);
        expect(fy!.fiscalYearCode, equals('FY2026'));

        // 3. FiscalPeriods
        await accountingDao.insertFiscalPeriod(
          FiscalPeriodsCompanion.insert(
            id: 'fp-2026-q1',
            businessId: 'BUS_A',
            fiscalYearId: 'fy-2026',
            periodNumber: 1,
            periodName: 'Q1 2026',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 3, 31),
            status: const drift.Value('Open'),
          ),
        );
        final fp = await accountingDao.getFiscalPeriodById(
          'fp-2026-q1',
          'BUS_A',
        );
        expect(fp, isNotNull);
        expect(fp!.periodName, equals('Q1 2026'));

        // 4. AccountingPeriods
        await accountingDao.insertAccountingPeriod(
          AccountingPeriodsCompanion.insert(
            id: 'ap-2026-01',
            businessId: 'BUS_A',
            fiscalYearId: 'fy-2026',
            periodNumber: 1,
            periodName: 'January 2026',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 31),
            status: const drift.Value('Open'),
          ),
        );
        final ap = await accountingDao.getAccountingPeriodById(
          'ap-2026-01',
          'BUS_A',
        );
        expect(ap, isNotNull);
        expect(ap!.status, equals('Open'));

        await accountingDao.updateAccountingPeriodStatus(
          'ap-2026-01',
          'BUS_A',
          'Closed',
          closedBy: 'u-owner',
        );
        final apClosed = await accountingDao.getAccountingPeriodById(
          'ap-2026-01',
          'BUS_A',
        );
        expect(apClosed!.status, equals('Closed'));
        expect(apClosed.closedBy, equals('u-owner'));
        expect(apClosed.closedAt, isNotNull);

        // 5. AccountMappings
        await accountingDao.insertAccountMapping(
          const AccountMappingsCompanion(
            id: drift.Value('map-sales'),
            businessId: drift.Value('BUS_A'),
            mappingKey: drift.Value('SALES_REVENUE_ACCOUNT'),
            mappingName: drift.Value('Default Sales Revenue Account'),
            chartOfAccountId: drift.Value('coa-01'),
          ),
        );
        final map = await accountingDao.getAccountMappingByKey(
          'SALES_REVENUE_ACCOUNT',
          'BUS_A',
        );
        expect(map, isNotNull);
        expect(map!.chartOfAccountId, equals('coa-01'));

        // 6. PaymentTerms
        await accountingDao.insertPaymentTerm(
          const PaymentTermsCompanion(
            id: drift.Value('term-30'),
            businessId: drift.Value('BUS_A'),
            termName: drift.Value('Net 30 Days'),
            daysToDue: drift.Value(30),
          ),
        );
        final term = await accountingDao.getPaymentTermById('term-30', 'BUS_A');
        expect(term, isNotNull);
        expect(term!.daysToDue, equals(30));
      },
    );

    test(
      '2. Required Test: Hierarchical Chart of Accounts Tree Queries',
      () async {
        // Create root asset account
        await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('root-assets'),
            businessId: drift.Value('BUS_A'),
            accountCode: drift.Value('1'),
            accountName: drift.Value('Assets'),
            accountTypeId: drift.Value(1),
            normalBalance: drift.Value('Debit'),
            accountLevel: drift.Value(1),
            allowPosting: drift.Value(false),
          ),
        );

        // Create level 2 child account
        await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('ch-current-assets'),
            businessId: drift.Value('BUS_A'),
            parentAccountId: drift.Value('root-assets'),
            accountCode: drift.Value('11'),
            accountName: drift.Value('Current Assets'),
            accountTypeId: drift.Value(1),
            normalBalance: drift.Value('Debit'),
            accountLevel: drift.Value(2),
            allowPosting: drift.Value(false),
          ),
        );

        // Create level 3 posting child account
        await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('ch-cash'),
            businessId: drift.Value('BUS_A'),
            parentAccountId: drift.Value('ch-current-assets'),
            accountCode: drift.Value('1101'),
            accountName: drift.Value('Cash and Bank'),
            accountTypeId: drift.Value(1),
            normalBalance: drift.Value('Debit'),
            accountLevel: drift.Value(3),
            allowPosting: drift.Value(true),
          ),
        );

        final tree = await accountingDao.getChartOfAccountsTree('BUS_A');
        expect(tree.length, equals(1));
        expect(tree.first.account.accountName, equals('Assets'));
        expect(tree.first.children.length, equals(1));
        expect(
          tree.first.children.first.account.accountName,
          equals('Current Assets'),
        );
        expect(tree.first.children.first.children.length, equals(1));
        expect(
          tree.first.children.first.children.first.account.accountName,
          equals('Cash and Bank'),
        );
      },
    );

    test(
      '3. Required Test: Atomic Balanced Journal Entry + Lines Persistence & Rollback',
      () async {
        await accountingDao.insertFiscalYear(
          FiscalYearsCompanion.insert(
            id: 'fy-2026',
            businessId: 'BUS_A',
            fiscalYearCode: 'FY2026',
            fiscalYearName: 'Fiscal Year 2026',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
          ),
        );
        await accountingDao.insertFiscalPeriod(
          FiscalPeriodsCompanion.insert(
            id: 'fp-2026-q1',
            businessId: 'BUS_A',
            fiscalYearId: 'fy-2026',
            periodNumber: 1,
            periodName: 'Q1 2026',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 3, 31),
          ),
        );

        await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('acc-debit'),
            businessId: drift.Value('BUS_A'),
            accountCode: drift.Value('101'),
            accountName: drift.Value('Debit Account'),
            accountTypeId: drift.Value(1),
            normalBalance: drift.Value('Debit'),
          ),
        );
        await accountingDao.insertChartOfAccount(
          const ChartOfAccountsCompanion(
            id: drift.Value('acc-credit'),
            businessId: drift.Value('BUS_A'),
            accountCode: drift.Value('201'),
            accountName: drift.Value('Credit Account'),
            accountTypeId: drift.Value(2),
            normalBalance: drift.Value('Credit'),
          ),
        );

        // 1. Post a balanced journal entry (Debits == Credits)
        await accountingDao.postJournalEntryWithLines(
          JournalEntriesCompanion.insert(
            id: 'je-balanced',
            businessId: 'BUS_A',
            fiscalYearId: 'fy-2026',
            fiscalPeriodId: 'fp-2026-q1',
            journalNumber: 'JE-001',
            documentDate: DateTime(2026, 5, 10),
            journalType: 'Manual',
            documentType: 'Manual',
            currencyId: 'SAR',
            status: const drift.Value('Posted'),
            createdBy: 'u-owner',
          ),
          [
            JournalEntryLinesCompanion.insert(
              id: 'line-d1',
              businessId: 'BUS_A',
              journalEntryId: 'je-balanced',
              lineNumber: 1,
              chartOfAccountId: 'acc-debit',
              currencyId: 'SAR',
              type: 'Debit',
              baseAmount: const drift.Value(1500.0),
            ),
            JournalEntryLinesCompanion.insert(
              id: 'line-c1',
              businessId: 'BUS_A',
              journalEntryId: 'je-balanced',
              lineNumber: 2,
              chartOfAccountId: 'acc-credit',
              currencyId: 'SAR',
              type: 'Credit',
              baseAmount: const drift.Value(1500.0),
            ),
          ],
        );

        final result = await accountingDao.getJournalEntryWithLinesById(
          'je-balanced',
          'BUS_A',
        );
        expect(result, isNotNull);
        expect(result!.entry.journalNumber, equals('JE-001'));
        expect(result.lines.length, equals(2));

        // 2. Attempt to post an UNBALANCED journal entry (Debits != Credits) -> throws exception & rolls back
        try {
          await accountingDao.postJournalEntryWithLines(
            JournalEntriesCompanion.insert(
              id: 'je-unbalanced',
              businessId: 'BUS_A',
              fiscalYearId: 'fy-2026',
              fiscalPeriodId: 'fp-2026-q1',
              journalNumber: 'JE-002',
              documentDate: DateTime(2026, 5, 11),
              journalType: 'Manual',
              documentType: 'Manual',
              currencyId: 'SAR',
              createdBy: 'u-owner',
            ),
            [
              JournalEntryLinesCompanion.insert(
                id: 'line-d2',
                businessId: 'BUS_A',
                journalEntryId: 'je-unbalanced',
                lineNumber: 1,
                chartOfAccountId: 'acc-debit',
                currencyId: 'SAR',
                type: 'Debit',
                baseAmount: const drift.Value(1000.0),
              ),
              JournalEntryLinesCompanion.insert(
                id: 'line-c2',
                businessId: 'BUS_A',
                journalEntryId: 'je-unbalanced',
                lineNumber: 2,
                chartOfAccountId: 'acc-credit',
                currencyId: 'SAR',
                type: 'Credit',
                baseAmount: const drift.Value(800.0), // Unbalanced!
              ),
            ],
          );
          fail('Should have thrown BalancedJournalRequiredException');
        } catch (e) {
          expect(e, isA<BalancedJournalRequiredException>());
        }

        final failedEntry = await accountingDao.getJournalEntryById(
          'je-unbalanced',
          'BUS_A',
        );
        expect(
          failedEntry,
          isNull,
          reason:
              'Unbalanced journal entry should not be persisted in database.',
        );
      },
    );

    test('4. Required Test: Fiscal Period Lock Query Verification', () async {
      await accountingDao.insertFiscalYear(
        FiscalYearsCompanion.insert(
          id: 'fy-2026',
          businessId: 'BUS_A',
          fiscalYearCode: 'FY2026',
          fiscalYearName: 'Fiscal Year 2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );

      // Insert an AccountingPeriod for June 2026 with status Locked
      await accountingDao.insertAccountingPeriod(
        AccountingPeriodsCompanion.insert(
          id: 'ap-2026-06',
          businessId: 'BUS_A',
          fiscalYearId: 'fy-2026',
          periodNumber: 6,
          periodName: 'June 2026',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 30),
          status: const drift.Value('Locked'),
        ),
      );

      // Insert an AccountingPeriod for August 2026 with status Open
      await accountingDao.insertAccountingPeriod(
        AccountingPeriodsCompanion.insert(
          id: 'ap-2026-08',
          businessId: 'BUS_A',
          fiscalYearId: 'fy-2026',
          periodNumber: 8,
          periodName: 'August 2026',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 31),
          status: const drift.Value('Open'),
        ),
      );

      // Verify June 15, 2026 is locked
      final isJuneLocked = await accountingDao.checkPeriodLocked(
        'BUS_A',
        DateTime(2026, 6, 15),
      );
      expect(isJuneLocked, isTrue);

      // Verify August 15, 2026 is NOT locked
      final isAugustLocked = await accountingDao.checkPeriodLocked(
        'BUS_A',
        DateTime(2026, 8, 15),
      );
      expect(isAugustLocked, isFalse);
    });

    test('5. Opening Balances Batch Recording & Queries', () async {
      await accountingDao.insertFiscalYear(
        FiscalYearsCompanion.insert(
          id: 'fy-2026',
          businessId: 'BUS_A',
          fiscalYearCode: 'FY2026',
          fiscalYearName: 'Fiscal Year 2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );

      await accountingDao.insertChartOfAccount(
        const ChartOfAccountsCompanion(
          id: drift.Value('coa-ob1'),
          businessId: drift.Value('BUS_A'),
          accountCode: drift.Value('1001'),
          accountName: drift.Value('Bank Account A'),
          accountTypeId: drift.Value(1),
          normalBalance: drift.Value('Debit'),
        ),
      );
      await accountingDao.insertChartOfAccount(
        const ChartOfAccountsCompanion(
          id: drift.Value('coa-ob2'),
          businessId: drift.Value('BUS_A'),
          accountCode: drift.Value('2001'),
          accountName: drift.Value('Capital Account'),
          accountTypeId: drift.Value(2),
          normalBalance: drift.Value('Credit'),
        ),
      );

      await accountingDao.recordOpeningBalances([
        OpeningBalancesCompanion.insert(
          id: 'ob-1',
          businessId: 'BUS_A',
          fiscalYearId: 'fy-2026',
          chartOfAccountId: 'coa-ob1',
          currencyId: 'SAR',
          debitAmount: const drift.Value(50000.0),
          baseDebitAmount: const drift.Value(50000.0),
          createdBy: 'u-owner',
        ),
        OpeningBalancesCompanion.insert(
          id: 'ob-2',
          businessId: 'BUS_A',
          fiscalYearId: 'fy-2026',
          chartOfAccountId: 'coa-ob2',
          currencyId: 'SAR',
          creditAmount: const drift.Value(50000.0),
          baseCreditAmount: const drift.Value(50000.0),
          createdBy: 'u-owner',
        ),
      ], 'BUS_A');

      final list = await accountingDao.listOpeningBalances(
        const OpeningBalanceFilter(
          businessId: 'BUS_A',
          fiscalYearId: 'fy-2026',
        ),
      );
      expect(list.length, equals(2));
    });

    test('6. Tenant Scoping Isolation across Businesses', () async {
      await accountingDao.insertChartOfAccount(
        const ChartOfAccountsCompanion(
          id: drift.Value('coa-bus-a'),
          businessId: drift.Value('BUS_A'),
          accountCode: drift.Value('9001'),
          accountName: drift.Value('Alpha Account'),
          accountTypeId: drift.Value(1),
          normalBalance: drift.Value('Debit'),
        ),
      );
      await accountingDao.insertChartOfAccount(
        const ChartOfAccountsCompanion(
          id: drift.Value('coa-bus-b'),
          businessId: drift.Value('BUS_B'),
          accountCode: drift.Value('9001'),
          accountName: drift.Value('Beta Account'),
          accountTypeId: drift.Value(1),
          normalBalance: drift.Value('Debit'),
        ),
      );

      final listA = await accountingDao.listChartOfAccounts(
        const ChartOfAccountFilter(businessId: 'BUS_A'),
      );
      final listB = await accountingDao.listChartOfAccounts(
        const ChartOfAccountFilter(businessId: 'BUS_B'),
      );

      expect(listA.length, equals(1));
      expect(listA.first.accountName, equals('Alpha Account'));
      expect(listB.length, equals(1));
      expect(listB.first.accountName, equals('Beta Account'));

      // Empty businessId throws TenantScopingException
      expect(
        () => accountingDao.listChartOfAccounts(
          const ChartOfAccountFilter(businessId: ''),
        ),
        throwsA(isA<TenantScopingException>()),
      );
    });

    test(
      '7. Offline-First Synchronization Helpers across all 9 Accounting tables',
      () async {
        // ChartOfAccounts
        final pendingAccounts = await accountingDao
            .getPendingSyncChartOfAccounts('BUS_A');
        final accountIds = pendingAccounts.map((a) => a.id).toList();
        if (accountIds.isNotEmpty) {
          await accountingDao.markChartOfAccountsAsSynced(accountIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncChartOfAccounts('BUS_A'),
            isEmpty,
          );
        }

        // FiscalYears
        final pendingYears = await accountingDao.getPendingSyncFiscalYears(
          'BUS_A',
        );
        final yearIds = pendingYears.map((y) => y.id).toList();
        if (yearIds.isNotEmpty) {
          await accountingDao.markFiscalYearsAsSynced(yearIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncFiscalYears('BUS_A'),
            isEmpty,
          );
        }

        // FiscalPeriods
        final pendingFiscalPeriods = await accountingDao
            .getPendingSyncFiscalPeriods('BUS_A');
        final fiscalPeriodIds = pendingFiscalPeriods.map((p) => p.id).toList();
        if (fiscalPeriodIds.isNotEmpty) {
          await accountingDao.markFiscalPeriodsAsSynced(
            fiscalPeriodIds,
            'BUS_A',
          );
          expect(
            await accountingDao.getPendingSyncFiscalPeriods('BUS_A'),
            isEmpty,
          );
        }

        // AccountingPeriods
        final pendingAccountingPeriods = await accountingDao
            .getPendingSyncAccountingPeriods('BUS_A');
        final accountingPeriodIds = pendingAccountingPeriods
            .map((p) => p.id)
            .toList();
        if (accountingPeriodIds.isNotEmpty) {
          await accountingDao.markAccountingPeriodsAsSynced(
            accountingPeriodIds,
            'BUS_A',
          );
          expect(
            await accountingDao.getPendingSyncAccountingPeriods('BUS_A'),
            isEmpty,
          );
        }

        // JournalEntries & Lines
        final pendingJournalEntries = await accountingDao
            .getPendingSyncJournalEntries('BUS_A');
        final journalIds = pendingJournalEntries.map((j) => j.id).toList();
        if (journalIds.isNotEmpty) {
          await accountingDao.markJournalEntriesAsSynced(journalIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncJournalEntries('BUS_A'),
            isEmpty,
          );
        }

        final pendingJournalLines = await accountingDao
            .getPendingSyncJournalEntryLines('BUS_A');
        final lineIds = pendingJournalLines.map((l) => l.id).toList();
        if (lineIds.isNotEmpty) {
          await accountingDao.markJournalEntryLinesAsSynced(lineIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncJournalEntryLines('BUS_A'),
            isEmpty,
          );
        }

        // OpeningBalances
        final pendingOpeningBalances = await accountingDao
            .getPendingSyncOpeningBalances('BUS_A');
        final balanceIds = pendingOpeningBalances.map((b) => b.id).toList();
        if (balanceIds.isNotEmpty) {
          await accountingDao.markOpeningBalancesAsSynced(balanceIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncOpeningBalances('BUS_A'),
            isEmpty,
          );
        }

        // AccountMappings
        final pendingMappings = await accountingDao
            .getPendingSyncAccountMappings('BUS_A');
        final mappingIds = pendingMappings.map((m) => m.id).toList();
        if (mappingIds.isNotEmpty) {
          await accountingDao.markAccountMappingsAsSynced(mappingIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncAccountMappings('BUS_A'),
            isEmpty,
          );
        }

        // PaymentTerms
        final pendingTerms = await accountingDao.getPendingSyncPaymentTerms(
          'BUS_A',
        );
        final termIds = pendingTerms.map((t) => t.id).toList();
        if (termIds.isNotEmpty) {
          await accountingDao.markPaymentTermsAsSynced(termIds, 'BUS_A');
          expect(
            await accountingDao.getPendingSyncPaymentTerms('BUS_A'),
            isEmpty,
          );
        }
      },
    );
  });
}
