import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/auth_dao.dart';

void main() {
  late AppDatabase database;
  late AuthDao authDao;

  setUp(() {
    database = AppDatabase(connection: NativeDatabase.memory());
    authDao = AuthDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('AuthDao Phase 01 Test Suite -', () {
    test('1. Initialization & User CRUD Verification', () async {
      // 1. Insert User
      final userId = 'user-test-01';
      final email = 'test@merchant.com';
      await authDao.insertUser(
        UsersTableCompanion.insert(
          id: drift.Value(userId),
          email: email,
          passwordHash: 'hashed_password_abc',
          firstName: 'John',
          lastName: 'Doe',
        ),
      );

      // 2. Read by ID and Email
      final userById = await authDao.getUserById(userId);
      expect(userById, isNotNull);
      expect(userById!.email, equals(email));
      expect(userById.firstName, equals('John'));

      final userByEmail = await authDao.getUserByEmail(email);
      expect(userByEmail, isNotNull);
      expect(userByEmail!.id, equals(userId));

      // 3. Update User
      final updatedUser = userById.copyWith(
        firstName: 'Johnathan',
        isActive: false,
      );
      await authDao.updateUser(updatedUser.toCompanion(false));

      final fetchedAfterUpdate = await authDao.getUserById(userId);
      expect(fetchedAfterUpdate!.firstName, equals('Johnathan'));
      expect(fetchedAfterUpdate.isActive, isFalse);

      // 4. List Users filter
      final activeUsers = await authDao.listUsers(isActive: true);
      expect(activeUsers, isEmpty);

      final inactiveUsers = await authDao.listUsers(isActive: false);
      expect(inactiveUsers.length, equals(1));

      // 5. Delete User
      final deletedRows = await authDao.deleteUser(userId);
      expect(deletedRows, equals(1));
      final userAfterDelete = await authDao.getUserById(userId);
      expect(userAfterDelete, isNull);
    });

    test('2. Accounts & Subscriptions CRUD and Scope Verification', () async {
      // Setup User first (owner)
      final ownerId = 'user-owner-a';
      await authDao.insertUser(
        UsersTableCompanion.insert(
          id: drift.Value(ownerId),
          email: 'owner@a.com',
          passwordHash: 'hash',
          firstName: 'Alice',
          lastName: 'Smith',
        ),
      );

      // Insert Account
      final accountId = 'acc-a-01';
      await authDao.insertAccount(
        AccountsTableCompanion.insert(
          id: drift.Value(accountId),
          ownerId: ownerId,
          businessName: 'Smith Enterprises',
          businessType: 'Retail POS',
          defaultCurrency: 'SAR',
        ),
      );

      // Verify Account Lookup
      final fetchedAccount = await authDao.getAccountById(accountId);
      expect(fetchedAccount, isNotNull);
      expect(fetchedAccount!.businessName, equals('Smith Enterprises'));

      final ownerAccounts = await authDao.listAccountsByOwnerId(ownerId);
      expect(ownerAccounts.length, equals(1));

      // Insert Subscriptions scoped by accountId
      final subActiveId = 'sub-active';
      await authDao.insertSubscription(
        SubscriptionsTableCompanion.insert(
          id: drift.Value(subActiveId),
          accountId: accountId,
          status: 'active',
          planId: 'plan-pro',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
        ),
      );

      final subExpiredId = 'sub-expired';
      await authDao.insertSubscription(
        SubscriptionsTableCompanion.insert(
          id: drift.Value(subExpiredId),
          accountId: accountId,
          status: 'expired',
          planId: 'plan-basic',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
        ),
      );

      // Verify listSubscriptionsByAccountId
      final allSubs = await authDao.listSubscriptionsByAccountId(accountId);
      expect(allSubs.length, equals(2));

      // Verify getActiveSubscriptionByAccountId only returns active/trial status
      final activeSub = await authDao.getActiveSubscriptionByAccountId(
        accountId,
      );
      expect(activeSub, isNotNull);
      expect(activeSub!.id, equals(subActiveId));
      expect(activeSub.status, equals('active'));
    });

    test('3. Foreign Key Enforcement Verification', () async {
      // Attempting to insert an account for a non-existent ownerId must fail
      expect(
        () async => await authDao.insertAccount(
          AccountsTableCompanion.insert(
            id: const drift.Value('orphan-acc'),
            ownerId: 'non-existent-user-id',
            businessName: 'Orphan Business',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        ),
        throwsA(
          isA<sqlite.SqliteException>().having(
            (e) => e.message.toLowerCase(),
            'message',
            contains('foreign key constraint failed'),
          ),
        ),
      );
    });

    test('4. Transactional Persistence & Rollback Verification', () async {
      final userId = 'user-tx';
      await authDao.insertUser(
        UsersTableCompanion.insert(
          id: drift.Value(userId),
          email: 'tx@merchant.com',
          passwordHash: 'hash',
          firstName: 'Tx',
          lastName: 'User',
        ),
      );

      final accountCompanion = AccountsTableCompanion.insert(
        id: const drift.Value('acc-tx-01'),
        ownerId: userId,
        businessName: 'Tx Business',
        businessType: 'Retail',
        defaultCurrency: 'SAR',
      );
      final subCompanion = SubscriptionsTableCompanion.insert(
        id: const drift.Value('sub-tx-01'),
        accountId: 'acc-tx-01',
        status: 'active',
        planId: 'plan-enterprise',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
      );

      // Verify atomic success
      await authDao.createAccountWithSubscription(
        accountCompanion,
        subCompanion,
      );
      expect(await authDao.getAccountById('acc-tx-01'), isNotNull);
      expect(await authDao.getSubscriptionById('sub-tx-01'), isNotNull);

      // Verify transaction rollback if child fails foreign key or unique constraint
      final invalidSubCompanion = SubscriptionsTableCompanion.insert(
        id: const drift.Value('sub-tx-02'),
        accountId: 'non-existent-account-for-rollback',
        status: 'active',
        planId: 'plan-pro',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      final newAccountCompanion = AccountsTableCompanion.insert(
        id: const drift.Value('acc-tx-rollback'),
        ownerId: userId,
        businessName: 'Should Not Exist',
        businessType: 'Retail',
        defaultCurrency: 'SAR',
      );

      expect(
        () async => await authDao.createAccountWithSubscription(
          newAccountCompanion,
          invalidSubCompanion,
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );

      // Confirm both the account and subscription rolled back!
      expect(await authDao.getAccountById('acc-tx-rollback'), isNull);
      expect(await authDao.getSubscriptionById('sub-tx-02'), isNull);
    });

    test('5. Reactive Stream Verification', () async {
      final userId = 'user-stream';
      await authDao.insertUser(
        UsersTableCompanion.insert(
          id: drift.Value(userId),
          email: 'stream@merchant.com',
          passwordHash: 'hash',
          firstName: 'Stream',
          lastName: 'Tester',
        ),
      );

      final stream = authDao.watchUserById(userId);
      expect(
        stream,
        emitsInOrder([
          isA<UserAccount>().having((u) => u.firstName, 'firstName', 'Stream'),
          isA<UserAccount>().having(
            (u) => u.firstName,
            'firstName',
            'Updated Stream',
          ),
        ]),
      );

      // Trigger update
      await Future.delayed(const Duration(milliseconds: 50));
      final u = await authDao.getUserById(userId);
      await authDao.updateUser(
        u!.copyWith(firstName: 'Updated Stream').toCompanion(false),
      );
    });
  });
}
