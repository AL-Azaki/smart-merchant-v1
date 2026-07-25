import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/system_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late SystemDao systemDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    systemDao = SystemDao(database);

    // 1. Seed required Foundation & Core parent tables
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@system.com',
            passwordHash: 'hash',
            firstName: 'System',
            lastName: 'Admin',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-sys-01'),
            ownerId: 'u-owner',
            businessName: 'System Administration Enterprise',
            businessType: 'Enterprise',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-sys-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-sys-01',
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
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_2',
            businessId: 'BUS_A',
            branchName: 'Sub Branch Alpha',
            branchCode: 'BR-A2',
            isDefault: const drift.Value(false),
          ),
        );
    await database
        .into(database.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: 'curr-sar',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'SAR',
            decimalPlaces: const drift.Value(2),
            exchangeRate: const drift.Value(1.0),
            isBaseCurrency: const drift.Value(true),
          ),
        );
    await database
        .into(database.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: 'curr-usd',
            currencyCode: 'USD',
            currencyNameAr: 'دولار أمريكي',
            currencyNameEn: 'US Dollar',
            currencySymbol: '\$',
            decimalPlaces: const drift.Value(2),
            exchangeRate: const drift.Value(3.75),
            isBaseCurrency: const drift.Value(false),
          ),
        );

    // 2. Seed AccountTypes & ChartOfAccounts for ExpenseCategories and PaymentMethods
    await database
        .into(database.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: const drift.Value(1),
            nameEn: 'Expenses',
            nameAr: 'المصروفات',
            slug: 'expenses',
          ),
        );
    await database
        .into(database.chartOfAccounts)
        .insert(
          ChartOfAccountsCompanion.insert(
            id: 'coa-exp-01',
            businessId: 'BUS_A',
            accountCode: '5010',
            accountName: 'Operating Expenses',
            accountTypeId: 1,
            normalBalance: 'Debit',
          ),
        );
    await database
        .into(database.paymentMethods)
        .insert(
          PaymentMethodsCompanion.insert(
            id: 'pm-cash-01',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-exp-01',
            methodCode: 'CASH-01',
            methodName: 'Petty Cash',
            paymentType: 'Cash',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  // ============================================================================
  // GROUP 1: ACTIVITY LOGS — APPEND-ONLY AUDIT TRAILS & TENANT SCOPING
  // ============================================================================
  group(
    'Group 1: ActivityLogs — Append-Only Audit Trails & Tenant Scoping',
    () {
      test(
        'inserts activity log and retrieves via id and list filtering',
        () async {
          await systemDao.insertActivityLog(
            ActivityLogsCompanion.insert(
              id: 'log-001',
              businessId: 'BUS_A',
              userId: const drift.Value('u-owner'),
              action: 'create',
              entityType: 'Invoice',
              entityId: const drift.Value('inv-101'),
              details: const drift.Value('{"total": 150.00}'),
              ipAddress: const drift.Value('192.168.1.100'),
            ),
          );

          final log = await systemDao.getActivityLogById('log-001', 'BUS_A');
          expect(log, isNotNull);
          expect(log!.action, equals('create'));
          expect(log.entityType, equals('Invoice'));
          expect(log.details, equals('{"total": 150.00}'));

          // Filter by action and entityType
          final list = await systemDao.listActivityLogs(
            const ActivityLogFilter(
              businessId: 'BUS_A',
              action: 'create',
              entityType: 'Invoice',
            ),
          );
          expect(list.length, equals(1));
          expect(list.first.id, equals('log-001'));
        },
      );

      test(
        'enforces strict tenant isolation between BUS_A and BUS_B logs',
        () async {
          await systemDao.insertActivityLog(
            ActivityLogsCompanion.insert(
              id: 'log-bus-a',
              businessId: 'BUS_A',
              action: 'create',
              entityType: 'Expense',
            ),
          );
          await systemDao.insertActivityLog(
            ActivityLogsCompanion.insert(
              id: 'log-bus-b',
              businessId: 'BUS_B',
              action: 'create',
              entityType: 'Expense',
            ),
          );

          final listA = await systemDao.listActivityLogs(
            const ActivityLogFilter(businessId: 'BUS_A'),
          );
          expect(listA.length, equals(1));
          expect(listA.first.id, equals('log-bus-a'));

          final listB = await systemDao.listActivityLogs(
            const ActivityLogFilter(businessId: 'BUS_B'),
          );
          expect(listB.length, equals(1));
          expect(listB.first.id, equals('log-bus-b'));
        },
      );

      test('throws TenantScopingException when businessId is empty', () async {
        expect(
          () => systemDao.insertActivityLog(
            ActivityLogsCompanion.insert(
              id: 'log-empty',
              businessId: '',
              action: 'create',
              entityType: 'Expense',
            ),
          ),
          throwsA(isA<TenantScopingException>()),
        );
      });

      test('manages offline sync status for ActivityLogs', () async {
        await systemDao.insertActivityLog(
          ActivityLogsCompanion.insert(
            id: 'log-sync',
            businessId: 'BUS_A',
            action: 'update',
            entityType: 'Product',
          ),
        );

        final pending = await systemDao.getPendingSyncActivityLogs('BUS_A');
        expect(pending.length, equals(1));
        expect(pending.first.syncStatus, equals('pending'));

        final marked = await systemDao.markActivityLogAsSynced(
          'log-sync',
          'BUS_A',
        );
        expect(marked, isTrue);

        final pendingAfter = await systemDao.getPendingSyncActivityLogs(
          'BUS_A',
        );
        expect(pendingAfter, isEmpty);
      });
    },
  );

  // ============================================================================
  // GROUP 2: ATTACHMENTS — POLYMORPHIC ENTITY LINKS & SYNC HELPERS
  // ============================================================================
  group('Group 2: Attachments — Polymorphic Entity Links & Sync Helpers', () {
    test(
      'inserts and lists polymorphic attachments linked to an entity',
      () async {
        await systemDao.insertAttachment(
          AttachmentsCompanion.insert(
            id: 'att-001',
            businessId: 'BUS_A',
            entityType: 'Expense',
            entityId: 'exp-101',
            filePath: '/local/files/receipt_01.jpg',
            fileName: 'receipt_01.jpg',
          ),
        );
        await systemDao.insertAttachment(
          AttachmentsCompanion.insert(
            id: 'att-002',
            businessId: 'BUS_A',
            entityType: 'Expense',
            entityId: 'exp-101',
            filePath: '/local/files/receipt_02.jpg',
            fileName: 'receipt_02.jpg',
          ),
        );

        final attachments = await systemDao.listAttachmentsByEntity(
          'Expense',
          'exp-101',
          'BUS_A',
        );
        expect(attachments.length, equals(2));
        expect(
          attachments.map((a) => a.id),
          containsAll(['att-001', 'att-002']),
        );
      },
    );

    test('deletes attachment metadata record cleanly', () async {
      await systemDao.insertAttachment(
        AttachmentsCompanion.insert(
          id: 'att-del',
          businessId: 'BUS_A',
          entityType: 'Invoice',
          entityId: 'inv-202',
          filePath: '/local/files/invoice.pdf',
          fileName: 'invoice.pdf',
        ),
      );

      final deleted = await systemDao.deleteAttachment('att-del', 'BUS_A');
      expect(deleted, isTrue);

      final fetched = await systemDao.getAttachmentById('att-del', 'BUS_A');
      expect(fetched, isNull);
    });

    test('manages offline sync status for Attachments', () async {
      await systemDao.insertAttachment(
        AttachmentsCompanion.insert(
          id: 'att-sync',
          businessId: 'BUS_A',
          entityType: 'Customer',
          entityId: 'cust-001',
          filePath: '/local/files/doc.pdf',
          fileName: 'doc.pdf',
        ),
      );

      final pending = await systemDao.getPendingSyncAttachments('BUS_A');
      expect(pending.length, equals(1));

      await systemDao.markAttachmentAsSynced('att-sync', 'BUS_A');
      final after = await systemDao.getPendingSyncAttachments('BUS_A');
      expect(after, isEmpty);
    });
  });

  // ============================================================================
  // GROUP 3: EXCHANGE RATES — MULTI-CURRENCY CONVERSION & HISTORICAL QUERIES
  // ============================================================================
  group(
    'Group 3: ExchangeRates — Multi-Currency Conversion & Historical Queries',
    () {
      test(
        'inserts and retrieves latest exchange rate as of specific date',
        () async {
          final dateJan1 = DateTime(2026, 1, 15);
          final dateJun1 = DateTime(2026, 6, 15);
          final dateJul1 = DateTime(2026, 7, 15);

          // Rate on Jan 1: 0.2666
          await systemDao.insertExchangeRate(
            ExchangeRatesCompanion.insert(
              id: 'rate-jan',
              businessId: 'BUS_A',
              sourceCurrencyId: 'curr-sar',
              targetCurrencyId: 'curr-usd',
              effectiveDate: dateJan1,
              rate: 0.2666,
            ),
          );

          // Rate on Jun 1: 0.2667
          await systemDao.insertExchangeRate(
            ExchangeRatesCompanion.insert(
              id: 'rate-jun',
              businessId: 'BUS_A',
              sourceCurrencyId: 'curr-sar',
              targetCurrencyId: 'curr-usd',
              effectiveDate: dateJun1,
              rate: 0.2667,
            ),
          );

          // Query latest rate as of May 15 (should return Jan 1 rate)
          final rateAsOfMay = await systemDao.getLatestExchangeRate(
            businessId: 'BUS_A',
            sourceCurrencyId: 'curr-sar',
            targetCurrencyId: 'curr-usd',
            asOfDate: DateTime(2026, 5, 15),
          );
          expect(rateAsOfMay, isNotNull);
          expect(rateAsOfMay!.id, equals('rate-jan'));
          expect(rateAsOfMay.rate, equals(0.2666));

          // Query latest rate as of Jul 1 (should return Jun 1 rate)
          final rateAsOfJul = await systemDao.getLatestExchangeRate(
            businessId: 'BUS_A',
            sourceCurrencyId: 'curr-sar',
            targetCurrencyId: 'curr-usd',
            asOfDate: dateJul1,
          );
          expect(rateAsOfJul, isNotNull);
          expect(rateAsOfJul!.id, equals('rate-jun'));
          expect(rateAsOfJul.rate, equals(0.2667));
        },
      );

      test('updates exchange rate and increments version number', () async {
        await systemDao.insertExchangeRate(
          ExchangeRatesCompanion.insert(
            id: 'rate-upd',
            businessId: 'BUS_A',
            sourceCurrencyId: 'curr-sar',
            targetCurrencyId: 'curr-usd',
            effectiveDate: DateTime(2026, 7, 21),
            rate: 0.2700,
          ),
        );

        final initial = await systemDao.getExchangeRateById(
          'rate-upd',
          'BUS_A',
        );
        expect(initial!.version, equals(1));

        await systemDao.updateExchangeRate(
          ExchangeRatesCompanion(
            id: const drift.Value('rate-upd'),
            businessId: const drift.Value('BUS_A'),
            sourceCurrencyId: const drift.Value('curr-sar'),
            targetCurrencyId: const drift.Value('curr-usd'),
            effectiveDate: drift.Value(DateTime(2026, 7, 21)),
            rate: const drift.Value(0.2680),
          ),
        );

        final updated = await systemDao.getExchangeRateById(
          'rate-upd',
          'BUS_A',
        );
        expect(updated!.rate, equals(0.2680));
        expect(updated.version, equals(2));
        expect(updated.syncStatus, equals('pending_update'));
      });
    },
  );

  // ============================================================================
  // GROUP 4: EXPENSE CATEGORIES — CHART OF ACCOUNTS MAPPING & FILTERING
  // ============================================================================
  group(
    'Group 4: ExpenseCategories — Chart of Accounts Mapping & Filtering',
    () {
      test(
        'inserts, updates, and searches expense categories by text query',
        () async {
          await systemDao.insertExpenseCategory(
            ExpenseCategoriesCompanion.insert(
              id: 'ec-rent',
              businessId: 'BUS_A',
              chartOfAccountId: 'coa-exp-01',
              categoryName: 'Office Rent & Utilities',
              description: const drift.Value(
                'Monthly office rent payments and electricity',
              ),
            ),
          );
          await systemDao.insertExpenseCategory(
            ExpenseCategoriesCompanion.insert(
              id: 'ec-travel',
              businessId: 'BUS_A',
              chartOfAccountId: 'coa-exp-01',
              categoryName: 'Business Travel',
              description: const drift.Value('Flights and hotel accommodation'),
            ),
          );

          final rentSearch = await systemDao.listExpenseCategories(
            const ExpenseCategoryFilter(
              businessId: 'BUS_A',
              searchQuery: 'Rent',
            ),
          );
          expect(rentSearch.length, equals(1));
          expect(rentSearch.first.id, equals('ec-rent'));

          final hotelSearch = await systemDao.listExpenseCategories(
            const ExpenseCategoryFilter(
              businessId: 'BUS_A',
              searchQuery: 'hotel',
            ),
          );
          expect(hotelSearch.length, equals(1));
          expect(hotelSearch.first.id, equals('ec-travel'));
        },
      );

      test('enforces unique categoryName per business', () async {
        await systemDao.insertExpenseCategory(
          ExpenseCategoriesCompanion.insert(
            id: 'ec-unique-1',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-exp-01',
            categoryName: 'Supplies',
          ),
        );

        expect(
          () => systemDao.insertExpenseCategory(
            ExpenseCategoriesCompanion.insert(
              id: 'ec-unique-2',
              businessId: 'BUS_A',
              chartOfAccountId: 'coa-exp-01',
              categoryName: 'Supplies',
            ),
          ),
          throwsA(isA<sqlite.SqliteException>()),
        );
      });
    },
  );

  // ============================================================================
  // GROUP 5: EXPENSES — LIFECYCLE, SOFT DELETE & ATOMIC TRANSACTIONS
  // ============================================================================
  group('Group 5: Expenses — Lifecycle, Soft Delete & Atomic Transactions', () {
    setUp(() async {
      // Seed expense category required for expenses
      await systemDao.insertExpenseCategory(
        ExpenseCategoriesCompanion.insert(
          id: 'ec-gen',
          businessId: 'BUS_A',
          chartOfAccountId: 'coa-exp-01',
          categoryName: 'General Expenses',
        ),
      );
    });

    test('inserts expense and retrieves composite joined details', () async {
      await systemDao.insertExpense(
        ExpensesCompanion.insert(
          id: 'exp-001',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          expenseCategoryId: 'ec-gen',
          expenseNumber: 'EXP-2026-001',
          paymentMethodId: 'pm-cash-01',
          currencyId: 'curr-sar',
          amount: 500.00,
          baseAmount: 500.00,
          createdBy: 'u-owner',
          notes: const drift.Value('Office supplies purchase'),
        ),
      );
      await systemDao.insertAttachment(
        AttachmentsCompanion.insert(
          id: 'att-exp-1',
          businessId: 'BUS_A',
          entityType: 'Expense',
          entityId: 'exp-001',
          filePath: '/receipts/supplies.png',
          fileName: 'supplies.png',
        ),
      );

      final details = await systemDao.getExpenseWithDetails('exp-001', 'BUS_A');
      expect(details, isNotNull);
      expect(details!.expense.expenseNumber, equals('EXP-2026-001'));
      expect(details.category.categoryName, equals('General Expenses'));
      expect(details.paymentMethod.methodName, equals('Petty Cash'));
      expect(details.attachments.length, equals(1));
      expect(details.attachments.first.fileName, equals('supplies.png'));
    });

    test('updates expense lifecycle status and increments version', () async {
      await systemDao.insertExpense(
        ExpensesCompanion.insert(
          id: 'exp-status',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          expenseCategoryId: 'ec-gen',
          expenseNumber: 'EXP-2026-002',
          paymentMethodId: 'pm-cash-01',
          currencyId: 'curr-sar',
          amount: 100.00,
          baseAmount: 100.00,
          createdBy: 'u-owner',
        ),
      );

      await systemDao.updateExpenseStatus(
        'exp-status',
        'BUS_A',
        'Posted',
        updatedBy: 'u-owner',
      );

      final updated = await systemDao.getExpenseById('exp-status', 'BUS_A');
      expect(updated!.status, equals('Posted'));
      expect(updated.version, equals(2));
      expect(updated.syncStatus, equals('pending_update'));
    });

    test('soft deletes and restores expense cleanly', () async {
      await systemDao.insertExpense(
        ExpensesCompanion.insert(
          id: 'exp-del',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          expenseCategoryId: 'ec-gen',
          expenseNumber: 'EXP-2026-003',
          paymentMethodId: 'pm-cash-01',
          currencyId: 'curr-sar',
          amount: 250.00,
          baseAmount: 250.00,
          createdBy: 'u-owner',
        ),
      );

      await systemDao.softDeleteExpense('exp-del', 'BUS_A');
      final activeList = await systemDao.listExpenses(
        const ExpenseFilter(businessId: 'BUS_A'),
      );
      expect(activeList.any((e) => e.id == 'exp-del'), isFalse);

      final allList = await systemDao.listExpenses(
        const ExpenseFilter(businessId: 'BUS_A', includeSoftDeleted: true),
      );
      expect(allList.any((e) => e.id == 'exp-del'), isTrue);

      await systemDao.restoreExpense('exp-del', 'BUS_A');
      final activeAfterRestore = await systemDao.listExpenses(
        const ExpenseFilter(businessId: 'BUS_A'),
      );
      expect(activeAfterRestore.any((e) => e.id == 'exp-del'), isTrue);
    });

    test(
      'atomic transaction rollback: insertExpenseWithAttachments rolls back on child tenant mismatch',
      () async {
        final expenseCompanion = ExpensesCompanion.insert(
          id: 'exp-atomic',
          businessId: 'BUS_A',
          branchId: 'BRANCH_1',
          expenseCategoryId: 'ec-gen',
          expenseNumber: 'EXP-ATOMIC-01',
          paymentMethodId: 'pm-cash-01',
          currencyId: 'curr-sar',
          amount: 800.00,
          baseAmount: 800.00,
          createdBy: 'u-owner',
        );

        // Second attachment intentionally has mismatched businessId (BUS_B)
        final attachments = [
          AttachmentsCompanion.insert(
            id: 'att-ok',
            businessId: 'BUS_A',
            entityType: 'Expense',
            entityId: 'exp-atomic',
            filePath: '/path/ok.pdf',
            fileName: 'ok.pdf',
          ),
          AttachmentsCompanion.insert(
            id: 'att-bad',
            businessId: 'BUS_B',
            entityType: 'Expense',
            entityId: 'exp-atomic',
            filePath: '/path/bad.pdf',
            fileName: 'bad.pdf',
          ),
        ];

        expect(
          () => systemDao.insertExpenseWithAttachments(
            expenseCompanion,
            attachments,
          ),
          throwsA(isA<TenantScopingException>()),
        );

        // Verify complete rollback of both master expense and valid attachment
        final fetchedExp = await systemDao.getExpenseById(
          'exp-atomic',
          'BUS_A',
        );
        expect(fetchedExp, isNull);

        final fetchedAtts = await systemDao.listAttachmentsByEntity(
          'Expense',
          'exp-atomic',
          'BUS_A',
        );
        expect(fetchedAtts, isEmpty);
      },
    );
  });

  // ============================================================================
  // GROUP 6: REACTIVE STREAMS & OFFLINE-FIRST SYNCHRONIZATION
  // ============================================================================
  group('Group 6: Reactive Streams & Offline-First Synchronization', () {
    test(
      'watchExpenses emits updated lists when expenses are added or modified',
      () async {
        // Seed category
        await systemDao.insertExpenseCategory(
          ExpenseCategoriesCompanion.insert(
            id: 'ec-stream',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-exp-01',
            categoryName: 'Stream Expenses',
          ),
        );

        final stream = systemDao.watchExpenses(
          const ExpenseFilter(businessId: 'BUS_A'),
        );
        expect(stream, emitsInOrder([isEmpty, hasLength(1)]));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await systemDao.insertExpense(
          ExpensesCompanion.insert(
            id: 'exp-stream-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            expenseCategoryId: 'ec-stream',
            expenseNumber: 'EXP-STR-01',
            paymentMethodId: 'pm-cash-01',
            currencyId: 'curr-sar',
            amount: 300.00,
            baseAmount: 300.00,
            createdBy: 'u-owner',
          ),
        );
      },
    );
  });
}
