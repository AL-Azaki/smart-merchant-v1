import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';
import 'package:smart_merchant_erp/kernel/error/repository_exceptions.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';

void main() {
  late AppDatabase db;
  late CoreDao dao;
  late CoreRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    dao = CoreDao(db);
    repository = CoreRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CoreRepository Unit Suite', () {
    test('1. AccountTypes and Currencies Operations', () async {
      await repository.insertAccountType(
        AccountTypesCompanion.insert(
          slug: 'asset',
          nameEn: 'Assets',
          nameAr: 'الأصول',
        ),
      );
      final type = await repository.getAccountTypeBySlug('asset');
      expect(type, isNotNull);
      expect(type!.nameEn, 'Assets');

      await repository.insertCurrency(
        CurrenciesCompanion.insert(
          id: 'YER',
          currencyCode: 'YER',
          currencyNameEn: 'Yemeni Rial',
          currencyNameAr: 'ريال يمني',
          currencySymbol: '﷼',
        ),
      );
      final currency = await repository.getCurrencyByCode('YER');
      expect(currency?.currencyNameEn, 'Yemeni Rial');
    });

    test('2. Businesses, Branches, and Sequence Number Generation', () async {
      // Seed user and account to satisfy foreign key constraints
      await db
          .into(db.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: const drift.Value('u-owner-1'),
              email: 'owner@smartmerchant.com',
              passwordHash: 'hash',
              firstName: 'Owner',
              lastName: 'User',
            ),
          );
      await db
          .into(db.accountsTable)
          .insert(
            AccountsTableCompanion.insert(
              id: const drift.Value('acc-1'),
              ownerId: 'u-owner-1',
              businessName: 'Smart Store',
              businessType: 'Retail',
              defaultCurrency: 'YER',
            ),
          );

      // Seed business
      await repository.insertBusiness(
        BusinessesCompanion.insert(
          id: 'biz-1',
          accountId: 'acc-1',
          businessName: 'Smart Merchant Corp',
        ),
      );
      final biz = await repository.getBusinessById('biz-1');
      expect(biz?.businessName, 'Smart Merchant Corp');

      // Seed default branch
      await repository.insertBranch(
        BranchesCompanion.insert(
          id: 'branch-1',
          businessId: 'biz-1',
          branchCode: 'MAIN',
          branchName: 'Main HQ',
          isDefault: const drift.Value(true),
        ),
      );
      final defaultBranch = await repository.getDefaultBranch('biz-1');
      expect(defaultBranch?.branchCode, 'MAIN');

      // Seed sequence
      await repository.insertSequence(
        SequencesCompanion.insert(
          id: 'seq-1',
          businessId: 'biz-1',
          documentType: 'INV',
          prefix: const drift.Value('INV-'),
          currentValue: const drift.Value(100),
          step: const drift.Value(1),
          padding: const drift.Value(5),
        ),
      );

      final nextNumber = await repository.incrementAndGetNextSequenceNumber(
        'biz-1',
        'INV',
      );
      expect(nextNumber, 'INV-00101');
    });

    test(
      '3. RepositoryErrorGuard intercepting TenantScopingException',
      () async {
        expect(
          () => repository.insertBranch(
            BranchesCompanion.insert(
              id: 'branch-invalid',
              businessId: '', // Invalid empty businessId
              branchCode: 'ERR',
              branchName: 'Invalid Branch',
            ),
          ),
          throwsA(
            isA<RepositoryTenantScopeException>().having(
              (e) => e.toFailure(),
              'toFailure',
              isA<TenantScopeFailure>(),
            ),
          ),
        );
      },
    );
  });
}
