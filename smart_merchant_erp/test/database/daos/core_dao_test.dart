import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';
import 'package:smart_merchant_erp/database/enums/system_setting_type.dart';

void main() {
  late AppDatabase database;
  late CoreDao coreDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    coreDao = CoreDao(database);

    // Seed required parent User and Account for foreign keys
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@core.com',
            passwordHash: 'hash',
            firstName: 'Owner',
            lastName: 'One',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-core-01'),
            ownerId: 'u-owner',
            businessName: 'Core Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('CoreDao Phase 01 Test Suite -', () {
    test('1. AccountTypes & Currencies CRUD and Sync Helpers', () async {
      // AccountTypes (Lookup)
      await coreDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const drift.Value(101),
          nameEn: 'Assets',
          nameAr: 'الأصول',
          slug: 'assets',
        ),
      );
      final fetchedType = await coreDao.getAccountTypeBySlug('assets');
      expect(fetchedType, isNotNull);
      expect(fetchedType!.nameEn, equals('Assets'));

      // Currencies
      final currId = 'curr-sar-test';
      await coreDao.insertCurrency(
        CurrenciesCompanion.insert(
          id: currId,
          currencyCode: 'SAR',
          currencyNameAr: 'ريال سعودي',
          currencyNameEn: 'Saudi Riyal',
          currencySymbol: 'ر.س',
          isBaseCurrency: const drift.Value(true),
        ),
      );

      final baseCurr = await coreDao.getBaseCurrency();
      expect(baseCurr, isNotNull);
      expect(baseCurr!.currencyCode, equals('SAR'));
      expect(baseCurr.syncStatus, equals('pending'));

      final pendingCurrencies = await coreDao.getPendingSyncCurrencies();
      expect(pendingCurrencies.length, equals(1));

      await coreDao.markCurrenciesAsSynced([currId]);
      final afterSync = await coreDao.getPendingSyncCurrencies();
      expect(afterSync, isEmpty);
    });

    test('2. Businesses CRUD, Filtering, Soft Delete & Restore', () async {
      final bizId = 'biz-01';
      await coreDao.insertBusiness(
        BusinessesCompanion.insert(
          id: bizId,
          accountId: 'acc-core-01',
          businessName: 'Smart Retail Store',
          status: const drift.Value('Active'),
        ),
      );

      final fetchedBiz = await coreDao.getBusinessById(bizId);
      expect(fetchedBiz, isNotNull);
      expect(fetchedBiz!.businessName, equals('Smart Retail Store'));

      final activeList = await coreDao.listBusinesses(
        const BusinessFilter(accountId: 'acc-core-01', status: 'Active'),
      );
      expect(activeList.length, equals(1));

      // Soft Delete
      await coreDao.softDeleteBusiness(bizId, 'acc-core-01');
      expect(await coreDao.getBusinessById(bizId), isNull);
      expect(
        await coreDao.getBusinessById(bizId, includeDeleted: true),
        isNotNull,
      );

      final archived = await coreDao.listArchivedBusinesses(
        accountId: 'acc-core-01',
      );
      expect(archived.length, equals(1));
      expect(archived.first.syncStatus, equals('pending_delete'));

      // Restore
      await coreDao.restoreBusiness(bizId, 'acc-core-01');
      expect(await coreDao.getBusinessById(bizId), isNotNull);
      final restoredBiz = await coreDao.getBusinessById(bizId);
      expect(restoredBiz!.deletedAt, isNull);
      expect(restoredBiz.syncStatus, equals('pending_update'));
    });

    test('3. Strict Tenant Scoping Enforcement (businessId check)', () async {
      expect(
        () async => await coreDao.getBranchById('br-1', ''),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async =>
            await coreDao.listBranches(const BranchFilter(businessId: '  ')),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async => await coreDao.insertBranch(
          BranchesCompanion.insert(
            id: 'br-2',
            businessId: '   ',
            branchName: 'Invalid Branch',
            branchCode: 'IB',
          ),
        ),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async => await coreDao.getEffectivePrintSetting('', 'Invoice'),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async => await coreDao.getSequence('', 'Invoice'),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async =>
            await coreDao.incrementAndGetNextSequenceNumber('', 'Invoice'),
        throwsA(isA<TenantScopingException>()),
      );
    });

    test('4. Branches Scoping, Soft Delete & Sync Helpers', () async {
      final bizA = 'biz-branch-test-a';
      final bizB = 'biz-branch-test-b';
      await coreDao.insertBusiness(
        BusinessesCompanion.insert(
          id: bizA,
          accountId: 'acc-core-01',
          businessName: 'Biz A',
        ),
      );
      await coreDao.insertBusiness(
        BusinessesCompanion.insert(
          id: bizB,
          accountId: 'acc-core-01',
          businessName: 'Biz B',
        ),
      );

      final branchA1 = 'br-a1';
      final branchA2 = 'br-a2';
      final branchB1 = 'br-b1';

      await coreDao.insertBranch(
        BranchesCompanion.insert(
          id: branchA1,
          businessId: bizA,
          branchName: 'Main Branch A',
          branchCode: 'BR-A1',
          isDefault: const drift.Value(true),
        ),
      );
      await coreDao.insertBranch(
        BranchesCompanion.insert(
          id: branchA2,
          businessId: bizA,
          branchName: 'Sub Branch A',
          branchCode: 'BR-A2',
        ),
      );
      await coreDao.insertBranch(
        BranchesCompanion.insert(
          id: branchB1,
          businessId: bizB,
          branchName: 'Main Branch B',
          branchCode: 'BR-B1',
          isDefault: const drift.Value(true),
        ),
      );

      // Verify businessId scoping isolation
      final listBizA = await coreDao.listBranches(
        BranchFilter(businessId: bizA),
      );
      expect(listBizA.length, equals(2));
      expect(listBizA.map((b) => b.id), containsAll([branchA1, branchA2]));
      expect(listBizA.map((b) => b.id), isNot(contains(branchB1)));

      // Verify getDefaultBranch
      final defaultA = await coreDao.getDefaultBranch(bizA);
      expect(defaultA, isNotNull);
      expect(defaultA!.id, equals(branchA1));

      // Soft Delete Branch A2
      await coreDao.softDeleteBranch(branchA2, bizA);
      expect(await coreDao.getBranchById(branchA2, bizA), isNull);
      expect(
        await coreDao.getBranchById(branchA2, bizA, includeDeleted: true),
        isNotNull,
      );

      // Sync Helpers
      final pendingBranchesA = await coreDao.getPendingSyncBranches(bizA);
      expect(
        pendingBranchesA.length,
        equals(2),
      ); // A1 pending, A2 pending_delete
      await coreDao.markBranchesAsSynced([branchA1, branchA2], bizA);
      expect(await coreDao.getPendingSyncBranches(bizA), isEmpty);
    });

    test('5. PrintSettings Branch-Specific Resolution & Fallback', () async {
      final bizId = 'biz-print-01';
      await coreDao.insertBusiness(
        BusinessesCompanion.insert(
          id: bizId,
          accountId: 'acc-core-01',
          businessName: 'Print Store',
        ),
      );
      final brId = 'br-print-01';
      await coreDao.insertBranch(
        BranchesCompanion.insert(
          id: brId,
          businessId: bizId,
          branchName: 'Branch 1',
          branchCode: 'BP1',
        ),
      );

      // Global Print Setting for Business
      await coreDao.insertPrintSetting(
        PrintSettingsCompanion.insert(
          id: 'ps-global',
          businessId: bizId,
          documentType: 'Invoice',
          headerText: const drift.Value('Global Business Header'),
          showLogo: const drift.Value(true),
          showTaxSummary: const drift.Value(true),
          showQrCode: const drift.Value(true),
        ),
      );

      // Verify effective setting for Branch 1 without branch-specific setting falls back to global
      final effectiveGlobal = await coreDao.getEffectivePrintSetting(
        bizId,
        'Invoice',
        branchId: brId,
      );
      expect(effectiveGlobal, isNotNull);
      expect(effectiveGlobal!.headerText, equals('Global Business Header'));

      // Add Branch-Specific Print Setting
      await coreDao.insertPrintSetting(
        PrintSettingsCompanion.insert(
          id: 'ps-branch-specific',
          businessId: bizId,
          branchId: drift.Value(brId),
          documentType: 'Invoice',
          headerText: const drift.Value('Branch 1 Special Header'),
          showLogo: const drift.Value(true),
          showTaxSummary: const drift.Value(true),
          showQrCode: const drift.Value(true),
        ),
      );

      // Verify effective setting now returns branch-specific setting
      final effectiveBranch = await coreDao.getEffectivePrintSetting(
        bizId,
        'Invoice',
        branchId: brId,
      );
      expect(effectiveBranch, isNotNull);
      expect(effectiveBranch!.headerText, equals('Branch 1 Special Header'));
      expect(effectiveBranch.branchId, equals(brId));
    });

    test(
      '6. Sequences Atomic Incrementing & Document Number Formatting',
      () async {
        final bizId = 'biz-seq-01';
        await coreDao.insertBusiness(
          BusinessesCompanion.insert(
            id: bizId,
            accountId: 'acc-core-01',
            businessName: 'Seq Store',
          ),
        );

        await coreDao.insertSequence(
          SequencesCompanion.insert(
            id: 'seq-inv',
            businessId: bizId,
            documentType: 'SalesInvoice',
            prefix: const drift.Value('INV-'),
            suffix: const drift.Value('-2026'),
            currentValue: const drift.Value(0),
            step: const drift.Value(1),
            padding: const drift.Value(5),
          ),
        );

        final docNum1 = await coreDao.incrementAndGetNextSequenceNumber(
          bizId,
          'SalesInvoice',
        );
        expect(docNum1, equals('INV-00001-2026'));

        final docNum2 = await coreDao.incrementAndGetNextSequenceNumber(
          bizId,
          'SalesInvoice',
        );
        expect(docNum2, equals('INV-00002-2026'));

        // Verify DB sequence currentValue is now 2
        final seqRecord = await coreDao.getSequence(bizId, 'SalesInvoice');
        expect(seqRecord!.currentValue, equals(2));
      },
    );

    test('7. SystemSettings CRUD & Scope Verification', () async {
      final bizId = 'biz-sys-01';
      await coreDao.insertBusiness(
        BusinessesCompanion.insert(
          id: bizId,
          accountId: 'acc-core-01',
          businessName: 'Sys Store',
        ),
      );

      await coreDao.insertSystemSetting(
        SystemSettingsCompanion.insert(
          id: 'sys-tax-mode',
          businessId: bizId,
          settingKey: 'tax_calculation_mode',
          settingType: const drift.Value(SystemSettingType.string),
          isPublic: const drift.Value(true),
        ),
      );

      final setting = await coreDao.getSystemSettingByKey(
        bizId,
        'tax_calculation_mode',
      );
      expect(setting, isNotNull);
      expect(setting!.settingKey, equals('tax_calculation_mode'));

      final list = await coreDao.listSystemSettings(
        SystemSettingFilter(businessId: bizId, isPublic: true),
      );
      expect(list.length, equals(1));
    });

    test(
      '8. Transactional Seeding (createBusinessWithDefaults) & Rollback',
      () async {
        final bizCompanion = BusinessesCompanion.insert(
          id: 'biz-seeded-100',
          accountId: 'acc-core-01',
          businessName: 'Seeded Enterprise',
        );
        final branchCompanion = BranchesCompanion.insert(
          id: 'branch-seeded-100',
          businessId: 'biz-seeded-100',
          branchName: 'HQ Branch',
          branchCode: 'HQ-100',
          isDefault: const drift.Value(true),
        );
        final seqList = [
          SequencesCompanion.insert(
            id: 'seq-s-1',
            businessId: 'biz-seeded-100',
            documentType: 'Invoice',
            prefix: const drift.Value('INV-'),
            currentValue: const drift.Value(0),
          ),
          SequencesCompanion.insert(
            id: 'seq-s-2',
            businessId: 'biz-seeded-100',
            documentType: 'Receipt',
            prefix: const drift.Value('REC-'),
            currentValue: const drift.Value(0),
          ),
        ];

        // Execute atomic seed
        await coreDao.createBusinessWithDefaults(
          bizCompanion,
          branchCompanion,
          seqList,
        );

        expect(await coreDao.getBusinessById('biz-seeded-100'), isNotNull);
        expect(await coreDao.getDefaultBranch('biz-seeded-100'), isNotNull);
        final seqs = await coreDao.listSequences(
          const SequenceFilter(businessId: 'biz-seeded-100'),
        );
        expect(seqs.length, equals(2));

        // Verify Rollback on error
        final invalidBranchCompanion = BranchesCompanion.insert(
          id: 'branch-rollback',
          businessId:
              'non-existent-biz-for-rollback-999', // Foreign key violation!
          branchName: 'Should Not Insert',
          branchCode: 'FAIL',
        );
        final newBizCompanion = BusinessesCompanion.insert(
          id: 'biz-rollback-100',
          accountId: 'acc-core-01',
          businessName: 'Rollback Biz',
        );

        expect(
          () async => await coreDao.createBusinessWithDefaults(
            newBizCompanion,
            invalidBranchCompanion,
            [],
          ),
          throwsA(isA<sqlite.SqliteException>()),
        );

        expect(await coreDao.getBusinessById('biz-rollback-100'), isNull);
        expect(
          await coreDao.getBranchById(
            'branch-rollback',
            'non-existent-biz-for-rollback-999',
          ),
          isNull,
        );
      },
    );
  });
}
