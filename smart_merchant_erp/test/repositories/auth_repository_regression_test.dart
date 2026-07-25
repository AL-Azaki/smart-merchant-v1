import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/error/repository_exceptions.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/data_sources/auth_local_data_source.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/repositories/auth_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AuthLocalDataSourceImpl localDataSource;
  late AuthRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    localDataSource = AuthLocalDataSourceImpl(db);
    repository = AuthRepositoryImpl(localDataSource);
  });

  tearDown(() async {
    await db.close();
  });

  group(
    'AuthRepository Regression Suite (Local User, Account & Subscription Abstraction)',
    () {
      test('1. User CRUD & Stream Abstraction via AuthDao', () async {
        final userId = await repository.insertUser(
          UsersTableCompanion.insert(
            id: const drift.Value('u-101'),
            email: 'test@smartmerchant.com',
            passwordHash: 'secret_hash',
            firstName: 'Sarah',
            lastName: 'Connor',
          ),
        );
        expect(userId, greaterThan(0));

        final fetchedUser = await repository.getUserById('u-101');
        expect(fetchedUser, isNotNull);
        expect(fetchedUser!.email, 'test@smartmerchant.com');

        final byEmail = await repository.getUserByEmail(
          'test@smartmerchant.com',
        );
        expect(byEmail?.id, 'u-101');

        final list = await repository.listUsers();
        expect(list.length, 1);

        // Update
        await repository.updateUser(
          UsersTableCompanion(
            id: const drift.Value('u-101'),
            email: const drift.Value('updated@smartmerchant.com'),
            passwordHash: const drift.Value('secret_hash'),
            firstName: const drift.Value('Sarah'),
            lastName: const drift.Value('Connor'),
          ),
        );
        final updatedUser = await repository.getUserById('u-101');
        expect(updatedUser!.email, 'updated@smartmerchant.com');

        // Stream
        expect(repository.watchUserById('u-101'), emits(isA<UserAccount?>()));

        // Delete
        await repository.deleteUser('u-101');
        final deleted = await repository.getUserById('u-101');
        expect(deleted, isNull);
      });

      test(
        '2. Account & Subscription Operations & Transactional Seeding',
        () async {
          // Seed owner
          await repository.insertUser(
            UsersTableCompanion.insert(
              id: const drift.Value('u-owner-1'),
              email: 'owner1@smartmerchant.com',
              passwordHash: 'hash',
              firstName: 'Owner',
              lastName: 'One',
            ),
          );

          await repository.createAccountWithSubscription(
            AccountsTableCompanion.insert(
              id: const drift.Value('acc-1'),
              ownerId: 'u-owner-1',
              businessName: 'Smart Store',
              businessType: 'Retail',
              defaultCurrency: 'USD',
            ),
            SubscriptionsTableCompanion.insert(
              id: const drift.Value('sub-1'),
              accountId: 'acc-1',
              planId: 'Enterprise_Plan',
              status: 'active',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 365)),
            ),
          );

          final accounts = await repository.listAccountsByOwnerId('u-owner-1');
          expect(accounts.length, 1);
          expect(accounts.first.businessName, 'Smart Store');

          final sub = await repository.getActiveSubscriptionByAccountId(
            'acc-1',
          );
          expect(sub, isNotNull);
          expect(sub!.planId, 'Enterprise_Plan');
        },
      );

      test(
        '3. RepositoryErrorGuard Error Interception & Failure Mapping',
        () async {
          // Attempting to insert an account with a non-existent ownerId should trigger foreign key violation
          expect(
            () => repository.insertAccount(
              AccountsTableCompanion.insert(
                id: const drift.Value('acc-invalid'),
                ownerId: 'non-existent-user',
                businessName: 'Ghost Store',
                businessType: 'Retail',
                defaultCurrency: 'USD',
              ),
            ),
            throwsA(
              isA<RepositoryConflictException>().having(
                (e) => e.toFailure(),
                'toFailure',
                isA<ConflictFailure>(),
              ),
            ),
          );
        },
      );
    },
  );
}
