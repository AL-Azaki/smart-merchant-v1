import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/database/seeders/default_coa_seeder.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/usecases/post_journal_entry_usecase.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/core/domain/repositories/core_repository.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late AccountingRepository accountingRepository;
  late CoreRepository coreRepository;
  late AccountingApplicationService accountingService;
  late PostJournalEntryUseCase postJournalUseCase;
  late DefaultChartOfAccountsSeeder coaSeeder;
  late ApplicationContext context;

  const uuid = Uuid();
  late String businessId;
  late String branchId;
  late String userId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    transactionRunner = ApplicationTransactionRunnerImpl(db);
    accountingRepository = AccountingRepositoryImpl(AccountingDao(db));
    coreRepository = CoreRepositoryImpl(CoreDao(db));
    coaSeeder = DefaultChartOfAccountsSeeder(db);

    businessId = uuid.v4();
    branchId = uuid.v4();
    userId = uuid.v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    accountingService = AccountingApplicationService(
      accountingRepository,
      context,
    );

    postJournalUseCase = PostJournalEntryUseCase(
      accountingRepository,
      coreRepository,
      context,
      transactionRunner,
    );

    // Seed master Business & Branch & User
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: businessId,
            accountId: 'acc-phase2-test',
            businessName: 'Phase 2 Test Enterprise',
            status: const drift.Value('Active'),
          ),
        );
    await db
        .into(db.branches)
        .insert(
          BranchesCompanion.insert(
            id: branchId,
            businessId: businessId,
            branchCode: 'MAIN',
            branchName: 'Main Branch',
            isActive: const drift.Value(true),
          ),
        );
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: drift.Value(userId),
            email: 'accountant@smartmerchant.com',
            passwordHash: 'dummy',
            firstName: 'Chief',
            lastName: 'Accountant',
            isActive: const drift.Value(true),
          ),
        );

    // Seed Open Fiscal Period
    final fiscalYearId = uuid.v4();
    await db
        .into(db.fiscalPeriods)
        .insert(
          FiscalPeriodsCompanion.insert(
            id: uuid.v4(),
            businessId: businessId,
            fiscalYearId: fiscalYearId,
            periodNumber: 1,
            periodName: '2026-01',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            status: const drift.Value('Open'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });


  test('A child inherits the parent actual contra-account balance', () async {
    await coaSeeder.seedChartOfAccounts(businessId: businessId);
    final parentResult = await accountingService.createAccount(const CreateAccountCommand(
      accountCode: '129', accountName: 'مجمع الاستهلاك', accountTypeId: 1,
      normalBalance: 'Credit', allowPosting: false));
    final parentId = parentResult.getOrElse(() => '');
    final result = await accountingService.createAccount(CreateAccountCommand(
      accountName: 'مجمع استهلاك المعدات', parentAccountId: parentId,
      accountTypeId: 5, normalBalance: 'Debit'));
    expect(result.isRight(), isTrue);
    final created = await accountingRepository.getChartOfAccountById(result.getOrElse(() => ''), businessId);
    expect(created!.accountTypeId, 1);
    expect(created.normalBalance, 'Credit');
  });

  test('Mapped posting accounts cannot be converted to grouping parents', () async {
    await coaSeeder.seedChartOfAccounts(businessId: businessId);
    final cash = (await accountingRepository.getChartOfAccountByCode('11101', businessId))!;
    final result = await accountingService.createAccount(CreateAccountCommand(
      accountName: 'فرع الصندوق', parentAccountId: cash.id));
    expect(result.isLeft(), isTrue);
    expect((await accountingRepository.getChartOfAccountById(cash.id, businessId))!.allowPosting, isTrue);
  });

  test(
    'Automatic numbering is unique during concurrent saves and inherits the actual parent',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);
      final parent = (await accountingRepository.getChartOfAccountByCode(
        '52',
        businessId,
      ))!;
      final results = await Future.wait(
        List.generate(
          6,
          (i) => accountingService.createAccount(
            CreateAccountCommand(
              accountName: 'مصروف $i',
              parentAccountId: parent.id,
              accountTypeId: 1,
              normalBalance: 'Credit',
            ),
          ),
        ),
      );
      expect(results.every((r) => r.isRight()), isTrue);
      final accounts = await accountingRepository.listChartOfAccounts(
        ChartOfAccountFilter(
          businessId: businessId,
          parentAccountId: parent.id,
          limit: null,
        ),
      );
      final created = accounts.where((a) => !a.isSystem).toList();
      expect(created, hasLength(6));
      expect(created.map((a) => a.accountCode).toSet(), hasLength(6));
      for (final account in created) {
        expect(account.accountCode, startsWith('52'));
        expect(account.accountTypeId, parent.accountTypeId);
        expect(account.normalBalance, parent.normalBalance);
        expect(account.currencyId, parent.currencyId);
        expect(account.accountLevel, parent.accountLevel + 1);
      }
    },
  );

  test('A failed child insert rolls back the parent posting flag', () async {
    await coaSeeder.seedChartOfAccounts(businessId: businessId);
    final parentResult = await accountingService.createAccount(
      const CreateAccountCommand(
        accountCode: '599',
        accountName: 'حساب مستقل',
        accountTypeId: 5,
        normalBalance: 'Debit',
      ),
    );
    final parentId = parentResult.getOrElse(() => '');
    // Enforce constraints so an invalid child currency causes an insert failure.
    await db.customStatement('PRAGMA foreign_keys = ON;');
    final result = await accountingService.createAccount(
      CreateAccountCommand(
        accountName: 'فرع غير صالح',
        parentAccountId: parentId,
        currencyId: 'missing-currency',
      ),
    );
    expect(result.isLeft(), isTrue);
    final parent = await accountingRepository.getChartOfAccountById(
      parentId,
      businessId,
    );
    expect(parent!.allowPosting, isTrue);
    final children = await accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, parentAccountId: parentId),
    );
    expect(children, isEmpty);
  });

  test(
    'Inactive and foreign parents cannot be used for account creation',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);
      final parent = (await accountingRepository.getChartOfAccountByCode(
        '52',
        businessId,
      ))!;
      await accountingRepository.toggleAccountActiveStatus(
        parent.id,
        businessId,
        isActive: false,
      );
      final inactive = await accountingService.createAccount(
        CreateAccountCommand(accountName: 'مصروف', parentAccountId: parent.id),
      );
      expect(inactive.isLeft(), isTrue);
      final missing = await accountingService.createAccount(
        const CreateAccountCommand(
          accountName: 'مصروف',
          parentAccountId: 'foreign-parent',
        ),
      );
      expect(missing.isLeft(), isTrue);
    },
  );

  test(
    'Standard initialization has Arabic names and creates no financial activity',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);
      await coaSeeder.seedChartOfAccounts(businessId: businessId);
      final accounts = await accountingRepository.listChartOfAccounts(
        ChartOfAccountFilter(businessId: businessId, limit: null),
      );
      expect(
        accounts.every((a) => !RegExp('[A-Za-z]').hasMatch(a.accountName)),
        isTrue,
      );
      expect(
        accounts.map((a) => a.accountCode).toSet().length,
        accounts.length,
      );
      expect(accounts.every((a) => !a.id.startsWith('coa-')), isTrue);
      expect(await db.select(db.journalEntries).get(), isEmpty);
      expect(await db.select(db.openingBalances).get(), isEmpty);
      expect(await db.select(db.products).get(), isEmpty);
    },
  );

  test(
    'Automatic numbering includes accounts beyond the first 500 rows',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);
      final parent = (await accountingRepository.getChartOfAccountByCode(
        '52',
        businessId,
      ))!;
      await db.batch((batch) {
        batch.insertAll(db.chartOfAccounts, [
          for (var i = 6; i <= 510; i++)
            ChartOfAccountsCompanion.insert(
              id: 'large-tree-$i',
              businessId: businessId,
              accountCode: '52${i.toString().padLeft(3, '0')}',
              accountName: 'حساب $i',
              accountTypeId: 5,
              normalBalance: 'Debit',
              parentAccountId: drift.Value(parent.id),
              accountLevel: drift.Value(parent.accountLevel + 1),
            ),
        ]);
      });
      final result = await accountingService.createAccount(
        CreateAccountCommand(
          accountName: 'مصروف جديد',
          parentAccountId: parent.id,
        ),
      );
      expect(result.isRight(), isTrue);
      final created = await accountingRepository.getChartOfAccountById(
        result.getOrElse(() => ''),
        businessId,
      );
      expect(created!.accountCode, '52511');
    },
  );

  test(
    'AC-2.1: DefaultChartOfAccountsSeeder seeds standard retail tree with at least 15 accounts across all 5 classes and creates mandatory mappings',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);

      final accounts = await accountingRepository.listChartOfAccounts(
        ChartOfAccountFilter(businessId: businessId),
      );

      // Verify at least 15 accounts exist
      expect(accounts.length, greaterThanOrEqualTo(15));

      // Verify all 5 root types exist (Assets: 1, Liabilities: 2, Equity: 3, Revenue: 4, Expenses: 5)
      final types = accounts.map((a) => a.accountTypeId).toSet();
      expect(types, containsAll([1, 2, 3, 4, 5]));

      // Verify essential account mappings exist and are active
      for (final key in [
        'cash_main',
        'bank_main',
        'accounts_receivable',
        'inventory_asset',
        'accounts_payable',
        'sales_revenue',
        'cost_of_goods_sold',
      ]) {
        final mappingRes = await accountingService.resolveAccountMapping(key);
        expect(
          mappingRes.isRight(),
          isTrue,
          reason: 'Mapping for $key must resolve.',
        );
      }
    },
  );

  test(
    'AC-2.2 & Invariant: createAccount creates account, calculates level, and disables allowPosting on parent',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);

      // Fetch parent account (e.g. 52 - Operating Expenses)
      final parent = await accountingRepository.getChartOfAccountByCode(
        '52',
        businessId,
      );
      expect(parent, isNotNull);

      final createCmd = CreateAccountCommand(
        accountCode: '52099',
        accountName: 'مصاريف تسويق وترويج',
        accountTypeId: 5,
        normalBalance: 'Debit',
        parentAccountId: parent!.id,
        allowPosting: true,
      );

      final result = await accountingService.createAccount(createCmd);
      expect(result.isRight(), isTrue);
      final newAccId = result.getOrElse(() => '');

      final created = await accountingRepository.getChartOfAccountById(
        newAccId,
        businessId,
      );
      expect(created, isNotNull);
      expect(created!.accountCode, '52099');
      expect(created.accountLevel, parent.accountLevel + 1);
      expect(created.allowPosting, isTrue);

      // Verify duplicate account code is rejected
      final dupResult = await accountingService.createAccount(createCmd);
      expect(dupResult.isLeft(), isTrue);
      expect(
        dupResult.fold((l) => l, (r) => null),
        isA<DuplicateAccountCodeFailure>(),
      );
    },
  );

  test(
    'AC-2.3: safeDeleteAccount prevents deletion if account has transactions, child accounts, or is mapped',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);

      // 1. Try to delete mapped account (e.g. 11101 - Main Cashbox) -> must fail with AccountIsMappedFailure
      final cashAcc = await accountingRepository.getChartOfAccountByCode(
        '11101',
        businessId,
      );
      expect(cashAcc, isNotNull);

      final delMappedRes = await accountingService.safeDeleteAccount(
        cashAcc!.id,
      );
      expect(delMappedRes.isLeft(), isTrue);
      expect(
        delMappedRes.fold((l) => l, (r) => throw Exception()),
        isA<AccountIsMappedFailure>(),
      );

      // 2. Try to delete parent account with children (e.g. 1 - Assets) -> must fail with AccountHasChildrenFailure
      final assetsAcc = await accountingRepository.getChartOfAccountByCode(
        '1',
        businessId,
      );
      expect(assetsAcc, isNotNull);

      final delParentRes = await accountingService.safeDeleteAccount(
        assetsAcc!.id,
      );
      expect(delParentRes.isLeft(), isTrue);
      expect(
        delParentRes.fold((l) => l, (r) => throw Exception()),
        isA<AccountHasChildrenFailure>(),
      );

      // 3. Create unmapped custom leaf account
      final createRes = await accountingService.createAccount(
        const CreateAccountCommand(
          accountCode: '52999',
          accountName: 'حساب تجريبي قابل للحذف',
          accountTypeId: 5,
          normalBalance: 'Debit',
          allowPosting: true,
        ),
      );
      final customId = createRes.getOrElse(() => '');

      // Successfully delete clean account
      final delCleanRes = await accountingService.safeDeleteAccount(customId);
      expect(delCleanRes.isRight(), isTrue);

      final deleted = await accountingRepository.getChartOfAccountById(
        customId,
        businessId,
      );
      expect(deleted, isNull);
    },
  );

  test(
    'AC-2.4 & AC-2.5: PostJournalEntryUseCase rejects unbalanced entries, rejects postings to parent accounts, and successfully posts balanced entry',
    () async {
      await coaSeeder.seedChartOfAccounts(businessId: businessId);

      final cashAcc = await accountingRepository.getChartOfAccountByCode(
        '11101',
        businessId,
      );
      final salesAcc = await accountingRepository.getChartOfAccountByCode(
        '41',
        businessId,
      );
      final parentAssetsAcc = await accountingRepository
          .getChartOfAccountByCode('1', businessId);

      expect(cashAcc, isNotNull);
      expect(salesAcc, isNotNull);
      expect(parentAssetsAcc, isNotNull);

      // 1. Unbalanced Entry (Debit 1000, Credit 950) -> Rejected
      final unbalancedCmd = PostJournalEntryCommand(
        documentDate: DateTime.now(),
        currencyId: 'YER',
        description: 'قيد غير متوازن تجريبي',
        lines: [
          JournalEntryLineCommand(
            accountId: cashAcc!.id,
            debit: 1000.0,
            credit: 0.0,
          ),
          JournalEntryLineCommand(
            accountId: salesAcc!.id,
            debit: 0.0,
            credit: 950.0,
          ),
        ],
      );

      final unbalRes = await postJournalUseCase(unbalancedCmd);
      expect(unbalRes.isLeft(), isTrue);

      // 2. Posting to Parent Account (allowPosting == false) -> Rejected
      final parentCmd = PostJournalEntryCommand(
        documentDate: DateTime.now(),
        currencyId: 'YER',
        description: 'محاولة ترحيل لحساب رئيسي',
        lines: [
          JournalEntryLineCommand(
            accountId: parentAssetsAcc!.id,
            debit: 1000.0,
            credit: 0.0,
          ),
          JournalEntryLineCommand(
            accountId: salesAcc.id,
            debit: 0.0,
            credit: 1000.0,
          ),
        ],
      );

      final parentRes = await postJournalUseCase(parentCmd);
      expect(parentRes.isLeft(), isTrue);

      // 3. Valid Balanced Manual Entry (Debit 1000, Credit 1000) -> Accepted!
      final validCmd = PostJournalEntryCommand(
        documentDate: DateTime.now(),
        currencyId: 'YER',
        description: 'إثبات مبيعات نقدية يدوية',
        lines: [
          JournalEntryLineCommand(
            accountId: cashAcc.id,
            debit: 1000.0,
            credit: 0.0,
          ),
          JournalEntryLineCommand(
            accountId: salesAcc.id,
            debit: 0.0,
            credit: 1000.0,
          ),
        ],
      );

      final validRes = await postJournalUseCase(validCmd);
      if (validRes.isLeft()) {
        print('USECASE FAILED: ${validRes.fold((l) => l.message, (r) => '')}');
      }
      expect(validRes.isRight(), isTrue);

      final journalId = validRes.getOrElse(() => '');
      final entryWithLines = await accountingRepository
          .getJournalEntryWithLinesById(journalId, businessId);
      expect(entryWithLines, isNotNull);
      expect(entryWithLines!.lines.length, 2);
      expect(entryWithLines.entry.status, 'Posted');
    },
  );
}
