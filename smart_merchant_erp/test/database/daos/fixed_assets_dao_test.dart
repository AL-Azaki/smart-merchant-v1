import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/fixed_assets_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late FixedAssetsDao fixedAssetsDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    fixedAssetsDao = FixedAssetsDao(database);

    // Seed required parent User, Account, Businesses, Branches, and Currencies
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@assets.com',
            passwordHash: 'hash',
            firstName: 'Asset',
            lastName: 'Manager',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-fa-01'),
            ownerId: 'u-owner',
            businessName: 'Fixed Assets Enterprise',
            businessType: 'Enterprise',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-fa-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-fa-01',
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
  });

  tearDown(() async {
    await database.close();
  });

  group('FixedAssetsDao Phase 09 Test Suite -', () {
    test(
      '1. Core CRUD & Composite Reads: FixedAssets and DepreciationSchedules',
      () async {
        // 1. Insert FixedAsset
        final faCompanion = FixedAssetsCompanion.insert(
          id: 'fa-101',
          businessId: 'BUS_A',
          branchId: const drift.Value('BRANCH_1'),
          currencyId: 'curr-sar',
          assetCode: 'FA-001',
          assetName: 'MacBook Pro M3 Max',
          acquisitionDate: DateTime(2026, 1, 15),
          acquisitionCost: 12000.0,
          baseAcquisitionCost: 12000.0,
          usefulLife: 36,
          residualValue: const drift.Value(1200.0),
          baseResidualValue: const drift.Value(1200.0),
          depreciationMethod: 'StraightLine',
          depreciationStartDate: DateTime(2026, 2, 1),
          status: const drift.Value('Active'),
          createdBy: 'u-owner',
        );
        await fixedAssetsDao.insertFixedAsset(faCompanion);

        // 2. Verify getFixedAssetById and getFixedAssetByCode
        final fetchedById = await fixedAssetsDao.getFixedAssetById(
          'fa-101',
          'BUS_A',
        );
        expect(fetchedById, isNotNull);
        expect(fetchedById!.assetName, 'MacBook Pro M3 Max');
        expect(fetchedById.syncStatus, 'pending_insert');
        expect(fetchedById.version, 1);

        final fetchedByCode = await fixedAssetsDao.getFixedAssetByCode(
          'FA-001',
          'BUS_A',
        );
        expect(fetchedByCode, isNotNull);
        expect(fetchedByCode!.id, 'fa-101');

        // 3. Insert DepreciationSchedules
        await fixedAssetsDao.insertDepreciationSchedule(
          DepreciationSchedulesCompanion.insert(
            id: 'ds-101-1',
            businessId: 'BUS_A',
            fixedAssetId: 'fa-101',
            depreciationPeriod: 1,
            scheduledPostingDate: DateTime(2026, 2, 28),
            depreciationAmount: 300.0,
            baseDepreciationAmount: 300.0,
            accumulatedDepreciation: 300.0,
            baseAccumulatedDepreciation: 300.0,
            remainingBookValue: 11700.0,
            baseRemainingBookValue: 11700.0,
            status: const drift.Value('Pending'),
            createdBy: 'u-owner',
          ),
        );
        await fixedAssetsDao.insertDepreciationSchedule(
          DepreciationSchedulesCompanion.insert(
            id: 'ds-101-2',
            businessId: 'BUS_A',
            fixedAssetId: 'fa-101',
            depreciationPeriod: 2,
            scheduledPostingDate: DateTime(2026, 3, 31),
            depreciationAmount: 300.0,
            baseDepreciationAmount: 300.0,
            accumulatedDepreciation: 600.0,
            baseAccumulatedDepreciation: 600.0,
            remainingBookValue: 11400.0,
            baseRemainingBookValue: 11400.0,
            status: const drift.Value('Pending'),
            createdBy: 'u-owner',
          ),
        );

        // 4. Verify getScheduleById and listSchedulesByAssetId
        final sched1 = await fixedAssetsDao.getScheduleById(
          'ds-101-1',
          'BUS_A',
        );
        expect(sched1, isNotNull);
        expect(sched1!.depreciationPeriod, 1);
        expect(sched1.depreciationAmount, 300.0);

        final allScheds = await fixedAssetsDao.listSchedulesByAssetId(
          'fa-101',
          'BUS_A',
        );
        expect(allScheds.length, 2);
        expect(allScheds[0].depreciationPeriod, 1);
        expect(allScheds[1].depreciationPeriod, 2);

        // 5. Verify composite getFixedAssetWithDetails
        final composite = await fixedAssetsDao.getFixedAssetWithDetails(
          'fa-101',
          'BUS_A',
        );
        expect(composite, isNotNull);
        expect(composite!.asset.assetCode, 'FA-001');
        expect(composite.schedules.length, 2);

        // 6. Verify Updates
        // Update asset name & status
        final updateSuccess = await fixedAssetsDao.updateFixedAsset(
          const FixedAssetsCompanion(
            id: drift.Value('fa-101'),
            businessId: drift.Value('BUS_A'),
            assetName: drift.Value('MacBook Pro M3 Max - Assigned'),
          ),
        );
        expect(updateSuccess, isTrue);

        final updatedAsset = await fixedAssetsDao.getFixedAssetById(
          'fa-101',
          'BUS_A',
        );
        expect(updatedAsset!.assetName, 'MacBook Pro M3 Max - Assigned');
        expect(updatedAsset.version, 2);

        // Update asset status
        final statusUpdateSuccess = await fixedAssetsDao.updateFixedAssetStatus(
          'fa-101',
          'BUS_A',
          'Depreciating',
          updatedBy: 'u-owner',
        );
        expect(statusUpdateSuccess, isTrue);
        final assetDepreciating = await fixedAssetsDao.getFixedAssetById(
          'fa-101',
          'BUS_A',
        );
        expect(assetDepreciating!.status, 'Depreciating');
        expect(assetDepreciating.version, 3);
        expect(assetDepreciating.updatedBy, 'u-owner');

        // Update schedule status
        final schedStatusSuccess = await fixedAssetsDao.updateScheduleStatus(
          'ds-101-1',
          'BUS_A',
          'Posted',
          updatedBy: 'u-owner',
        );
        expect(schedStatusSuccess, isTrue);
        final postedSched = await fixedAssetsDao.getScheduleById(
          'ds-101-1',
          'BUS_A',
        );
        expect(postedSched!.status, 'Posted');
        expect(postedSched.version, 2);
      },
    );

    test('2. Tenant Isolation & Branch Scoping Policy', () async {
      // 1. Insert asset under BUS_A
      await fixedAssetsDao.insertFixedAsset(
        FixedAssetsCompanion.insert(
          id: 'fa-busA',
          businessId: 'BUS_A',
          branchId: const drift.Value('BRANCH_1'),
          currencyId: 'curr-sar',
          assetCode: 'FA-A1',
          assetName: 'Asset A',
          acquisitionDate: DateTime(2026, 1, 1),
          acquisitionCost: 1000.0,
          baseAcquisitionCost: 1000.0,
          usefulLife: 12,
          depreciationMethod: 'StraightLine',
          depreciationStartDate: DateTime(2026, 1, 1),
          createdBy: 'u-owner',
        ),
      );

      // 2. Insert asset under BUS_B
      await fixedAssetsDao.insertFixedAsset(
        FixedAssetsCompanion.insert(
          id: 'fa-busB',
          businessId: 'BUS_B',
          currencyId: 'curr-sar',
          assetCode: 'FA-B1',
          assetName: 'Asset B',
          acquisitionDate: DateTime(2026, 1, 1),
          acquisitionCost: 2000.0,
          baseAcquisitionCost: 2000.0,
          usefulLife: 24,
          depreciationMethod: 'StraightLine',
          depreciationStartDate: DateTime(2026, 1, 1),
          createdBy: 'u-owner',
        ),
      );

      // Verify tenant isolation
      final listBusA = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A'),
      );
      expect(listBusA.length, 1);
      expect(listBusA.first.id, 'fa-busA');

      final listBusB = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_B'),
      );
      expect(listBusB.length, 1);
      expect(listBusB.first.id, 'fa-busB');

      // Verify cross-tenant getById returns null
      final crossGet = await fixedAssetsDao.getFixedAssetById(
        'fa-busA',
        'BUS_B',
      );
      expect(crossGet, isNull);

      // Verify missing or empty businessId throws TenantScopingException
      expect(
        () => fixedAssetsDao.getFixedAssetById('fa-busA', ''),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () => fixedAssetsDao.listFixedAssets(
          const FixedAssetFilter(businessId: '   '),
        ),
        throwsA(isA<TenantScopingException>()),
      );

      // 3. Branch Scoping Verification
      await fixedAssetsDao.insertFixedAsset(
        FixedAssetsCompanion.insert(
          id: 'fa-branch2',
          businessId: 'BUS_A',
          branchId: const drift.Value('BRANCH_2'),
          currencyId: 'curr-sar',
          assetCode: 'FA-A2',
          assetName: 'Asset Branch 2',
          acquisitionDate: DateTime(2026, 1, 5),
          acquisitionCost: 1500.0,
          baseAcquisitionCost: 1500.0,
          usefulLife: 12,
          depreciationMethod: 'StraightLine',
          depreciationStartDate: DateTime(2026, 1, 5),
          createdBy: 'u-owner',
        ),
      );

      final branch1List = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', branchId: 'BRANCH_1'),
      );
      expect(branch1List.length, 1);
      expect(branch1List.first.id, 'fa-busA');

      final branch2List = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', branchId: 'BRANCH_2'),
      );
      expect(branch2List.length, 1);
      expect(branch2List.first.id, 'fa-branch2');

      final allBranchList = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A'),
      );
      expect(allBranchList.length, 2);
    });

    test('3. Filtering, Search & Pagination Accuracy', () async {
      // Seed 10 assets with varying statuses and names
      for (int i = 1; i <= 10; i++) {
        await fixedAssetsDao.insertFixedAsset(
          FixedAssetsCompanion.insert(
            id: 'fa-item-$i',
            businessId: 'BUS_A',
            currencyId: 'curr-sar',
            assetCode: 'CODE-${i.toString().padLeft(3, '0')}',
            assetName: i % 2 == 0 ? 'Vehicle Unit $i' : 'Computer Equipment $i',
            acquisitionDate: DateTime(2026, 1, i),
            acquisitionCost: 1000.0 * i,
            baseAcquisitionCost: 1000.0 * i,
            usefulLife: 12,
            depreciationMethod: 'StraightLine',
            depreciationStartDate: DateTime(2026, 1, i),
            status: drift.Value(i <= 5 ? 'Active' : 'Depreciating'),
            createdBy: 'u-owner',
          ),
        );
      }

      // Filter by status
      final activeList = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', status: 'Active'),
      );
      expect(activeList.length, 5);

      final depList = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', status: 'Depreciating'),
      );
      expect(depList.length, 5);

      // Search query filter (like query)
      final searchVehicle = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', searchQuery: 'Vehicle'),
      );
      expect(searchVehicle.length, 5);

      final searchCode = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', searchQuery: 'CODE-003'),
      );
      expect(searchCode.length, 1);
      expect(searchCode.first.id, 'fa-item-3');

      // Pagination check
      final page1 = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', limit: 4, offset: 0),
      );
      expect(page1.length, 4);

      final page2 = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', limit: 4, offset: 4),
      );
      expect(page2.length, 4);

      final page3 = await fixedAssetsDao.listFixedAssets(
        const FixedAssetFilter(businessId: 'BUS_A', limit: 4, offset: 8),
      );
      expect(page3.length, 2);

      // Verify no overlap across pages
      final idsPage1 = page1.map((e) => e.id).toSet();
      final idsPage2 = page2.map((e) => e.id).toSet();
      expect(idsPage1.intersection(idsPage2), isEmpty);
    });

    test('4. Atomic Transaction & Batch Persistence Rollbacks', () async {
      // 1. Successful atomic insertion of Asset + Schedules
      final assetComp = FixedAssetsCompanion.insert(
        id: 'fa-atomic-1',
        businessId: 'BUS_A',
        currencyId: 'curr-sar',
        assetCode: 'FA-ATM-01',
        assetName: 'Atomic Server Unit',
        acquisitionDate: DateTime(2026, 1, 10),
        acquisitionCost: 24000.0,
        baseAcquisitionCost: 24000.0,
        usefulLife: 24,
        depreciationMethod: 'StraightLine',
        depreciationStartDate: DateTime(2026, 1, 10),
        createdBy: 'u-owner',
      );

      final schedComps = [
        DepreciationSchedulesCompanion.insert(
          id: 'ds-atomic-1',
          businessId: 'BUS_A',
          fixedAssetId: 'fa-atomic-1',
          depreciationPeriod: 1,
          scheduledPostingDate: DateTime(2026, 2, 10),
          depreciationAmount: 1000.0,
          baseDepreciationAmount: 1000.0,
          accumulatedDepreciation: 1000.0,
          baseAccumulatedDepreciation: 1000.0,
          remainingBookValue: 23000.0,
          baseRemainingBookValue: 23000.0,
          createdBy: 'u-owner',
        ),
        DepreciationSchedulesCompanion.insert(
          id: 'ds-atomic-2',
          businessId: 'BUS_A',
          fixedAssetId: 'fa-atomic-1',
          depreciationPeriod: 2,
          scheduledPostingDate: DateTime(2026, 3, 10),
          depreciationAmount: 1000.0,
          baseDepreciationAmount: 1000.0,
          accumulatedDepreciation: 2000.0,
          baseAccumulatedDepreciation: 2000.0,
          remainingBookValue: 22000.0,
          baseRemainingBookValue: 22000.0,
          createdBy: 'u-owner',
        ),
      ];

      await fixedAssetsDao.insertFixedAssetWithSchedules(assetComp, schedComps);

      final savedDetails = await fixedAssetsDao.getFixedAssetWithDetails(
        'fa-atomic-1',
        'BUS_A',
      );
      expect(savedDetails, isNotNull);
      expect(savedDetails!.schedules.length, 2);

      // 2. Transaction Rollback when child schedule violates unique/businessId check or constraint
      final failAssetComp = FixedAssetsCompanion.insert(
        id: 'fa-fail-1',
        businessId: 'BUS_A',
        currencyId: 'curr-sar',
        assetCode: 'FA-FAIL-01',
        assetName: 'Failing Asset Unit',
        acquisitionDate: DateTime(2026, 1, 10),
        acquisitionCost: 10000.0,
        baseAcquisitionCost: 10000.0,
        usefulLife: 10,
        depreciationMethod: 'StraightLine',
        depreciationStartDate: DateTime(2026, 1, 10),
        createdBy: 'u-owner',
      );

      final mismatchSchedComp = [
        DepreciationSchedulesCompanion.insert(
          id: 'ds-fail-1',
          businessId: 'BUS_B', // MISMATCH BUSINESS ID!
          fixedAssetId: 'fa-fail-1',
          depreciationPeriod: 1,
          scheduledPostingDate: DateTime(2026, 2, 10),
          depreciationAmount: 1000.0,
          baseDepreciationAmount: 1000.0,
          accumulatedDepreciation: 1000.0,
          baseAccumulatedDepreciation: 1000.0,
          remainingBookValue: 9000.0,
          baseRemainingBookValue: 9000.0,
          createdBy: 'u-owner',
        ),
      ];

      expect(
        () => fixedAssetsDao.insertFixedAssetWithSchedules(
          failAssetComp,
          mismatchSchedComp,
        ),
        throwsA(isA<TenantScopingException>()),
      );

      // Verify clean rollback of parent asset
      final parentAfterRollback = await fixedAssetsDao.getFixedAssetById(
        'fa-fail-1',
        'BUS_A',
      );
      expect(parentAfterRollback, isNull);

      // 3. Batch insert check
      final batchScheds = [
        DepreciationSchedulesCompanion.insert(
          id: 'ds-batch-1',
          businessId: 'BUS_A',
          fixedAssetId: 'fa-atomic-1',
          depreciationPeriod: 3,
          scheduledPostingDate: DateTime(2026, 4, 10),
          depreciationAmount: 1000.0,
          baseDepreciationAmount: 1000.0,
          accumulatedDepreciation: 3000.0,
          baseAccumulatedDepreciation: 3000.0,
          remainingBookValue: 21000.0,
          baseRemainingBookValue: 21000.0,
          createdBy: 'u-owner',
        ),
      ];
      await fixedAssetsDao.insertScheduleBatch(batchScheds);
      final updatedSchedules = await fixedAssetsDao.listSchedulesByAssetId(
        'fa-atomic-1',
        'BUS_A',
      );
      expect(updatedSchedules.length, 3);
    });

    test(
      '5. Reactive Streams (watchFixedAssetById, watchFixedAssets, watchSchedulesByAssetId)',
      () async {
        // 1. Insert initial asset for stream test
        await fixedAssetsDao.insertFixedAsset(
          FixedAssetsCompanion.insert(
            id: 'fa-stream-init',
            businessId: 'BUS_A',
            currencyId: 'curr-sar',
            assetCode: 'FA-STR-INIT',
            assetName: 'Initial Stream Asset',
            acquisitionDate: DateTime(2026, 1, 1),
            acquisitionCost: 500.0,
            baseAcquisitionCost: 500.0,
            usefulLife: 12,
            depreciationMethod: 'StraightLine',
            depreciationStartDate: DateTime(2026, 1, 1),
            createdBy: 'u-owner',
          ),
        );

        // Watch list
        final streamList = fixedAssetsDao.watchFixedAssets(
          const FixedAssetFilter(businessId: 'BUS_A'),
        );
        final expectationList = expectLater(
          streamList.map((list) => list.length),
          emitsInOrder([1, 2]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await fixedAssetsDao.insertFixedAsset(
          FixedAssetsCompanion.insert(
            id: 'fa-stream-1',
            businessId: 'BUS_A',
            currencyId: 'curr-sar',
            assetCode: 'FA-STR-01',
            assetName: 'Stream Asset',
            acquisitionDate: DateTime(2026, 1, 1),
            acquisitionCost: 500.0,
            baseAcquisitionCost: 500.0,
            usefulLife: 12,
            depreciationMethod: 'StraightLine',
            depreciationStartDate: DateTime(2026, 1, 1),
            createdBy: 'u-owner',
          ),
        );

        await expectationList;

        // 2. Watch single asset
        final streamSingle = fixedAssetsDao.watchFixedAssetById(
          'fa-stream-1',
          'BUS_A',
        );
        final expectationSingle = expectLater(
          streamSingle.map((a) => a?.assetName),
          emitsInOrder(['Stream Asset', 'Stream Asset Updated']),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await fixedAssetsDao.updateFixedAsset(
          const FixedAssetsCompanion(
            id: drift.Value('fa-stream-1'),
            businessId: drift.Value('BUS_A'),
            assetName: drift.Value('Stream Asset Updated'),
          ),
        );

        await expectationSingle;

        // 3. Watch schedules by asset ID
        await fixedAssetsDao.insertDepreciationSchedule(
          DepreciationSchedulesCompanion.insert(
            id: 'ds-stream-1',
            businessId: 'BUS_A',
            fixedAssetId: 'fa-stream-1',
            depreciationPeriod: 1,
            scheduledPostingDate: DateTime(2026, 2, 1),
            depreciationAmount: 100.0,
            baseDepreciationAmount: 100.0,
            accumulatedDepreciation: 100.0,
            baseAccumulatedDepreciation: 100.0,
            remainingBookValue: 400.0,
            baseRemainingBookValue: 400.0,
            createdBy: 'u-owner',
          ),
        );

        final streamSchedules = fixedAssetsDao.watchSchedulesByAssetId(
          'fa-stream-1',
          'BUS_A',
        );
        final expectationSchedules = expectLater(
          streamSchedules.map((list) => list.length),
          emitsInOrder([1, 2]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await fixedAssetsDao.insertDepreciationSchedule(
          DepreciationSchedulesCompanion.insert(
            id: 'ds-stream-2',
            businessId: 'BUS_A',
            fixedAssetId: 'fa-stream-1',
            depreciationPeriod: 2,
            scheduledPostingDate: DateTime(2026, 3, 1),
            depreciationAmount: 100.0,
            baseDepreciationAmount: 100.0,
            accumulatedDepreciation: 200.0,
            baseAccumulatedDepreciation: 200.0,
            remainingBookValue: 300.0,
            baseRemainingBookValue: 300.0,
            createdBy: 'u-owner',
          ),
        );

        await expectationSchedules;
      },
    );

    test('6. Offline-First Synchronization Helpers', () async {
      // 1. Insert asset & schedule
      await fixedAssetsDao.insertFixedAsset(
        FixedAssetsCompanion.insert(
          id: 'fa-sync-1',
          businessId: 'BUS_A',
          currencyId: 'curr-sar',
          assetCode: 'FA-SYNC-01',
          assetName: 'Sync Asset',
          acquisitionDate: DateTime(2026, 1, 1),
          acquisitionCost: 3000.0,
          baseAcquisitionCost: 3000.0,
          usefulLife: 30,
          depreciationMethod: 'StraightLine',
          depreciationStartDate: DateTime(2026, 1, 1),
          createdBy: 'u-owner',
        ),
      );

      await fixedAssetsDao.insertDepreciationSchedule(
        DepreciationSchedulesCompanion.insert(
          id: 'ds-sync-1',
          businessId: 'BUS_A',
          fixedAssetId: 'fa-sync-1',
          depreciationPeriod: 1,
          scheduledPostingDate: DateTime(2026, 2, 1),
          depreciationAmount: 100.0,
          baseDepreciationAmount: 100.0,
          accumulatedDepreciation: 100.0,
          baseAccumulatedDepreciation: 100.0,
          remainingBookValue: 2900.0,
          baseRemainingBookValue: 2900.0,
          createdBy: 'u-owner',
        ),
      );

      // Verify initial pending sync status
      final pendingAssets = await fixedAssetsDao.getPendingSyncFixedAssets(
        'BUS_A',
      );
      expect(pendingAssets.length, 1);
      expect(pendingAssets.first.syncStatus, 'pending_insert');

      final pendingSchedules = await fixedAssetsDao.getPendingSyncSchedules(
        'BUS_A',
      );
      expect(pendingSchedules.length, 1);
      expect(pendingSchedules.first.syncStatus, 'pending_insert');

      // Mark as synced
      await fixedAssetsDao.markFixedAssetAsSynced('fa-sync-1', 'BUS_A');
      await fixedAssetsDao.markScheduleAsSynced('ds-sync-1', 'BUS_A');

      // Verify no longer pending
      final pendingAssetsAfter = await fixedAssetsDao.getPendingSyncFixedAssets(
        'BUS_A',
      );
      expect(pendingAssetsAfter, isEmpty);

      final pendingSchedulesAfter = await fixedAssetsDao
          .getPendingSyncSchedules('BUS_A');
      expect(pendingSchedulesAfter, isEmpty);

      // Verify record states
      final assetSynced = await fixedAssetsDao.getFixedAssetById(
        'fa-sync-1',
        'BUS_A',
      );
      expect(assetSynced!.syncStatus, 'synced');

      final schedSynced = await fixedAssetsDao.getScheduleById(
        'ds-sync-1',
        'BUS_A',
      );
      expect(schedSynced!.syncStatus, 'synced');
    });
  });
}
