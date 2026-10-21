import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/secure_storage_contract.dart';
import 'package:smart_merchant_erp/kernel/sync/api/sync_remote_api_client.dart';
import 'package:smart_merchant_erp/kernel/sync/coordinator/sync_coordinator.dart';
import 'package:smart_merchant_erp/kernel/sync/dto/sync_dtos.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/network/retry/sync_retry_policy.dart';

import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';

class MockSyncRemoteApiClient extends Mock implements SyncRemoteApiClient {}

class MockSecureStorage extends Mock implements SecureStorageContract {}

void main() {
  late SyncCoordinator coordinator;
  late MockSyncRemoteApiClient mockApiClient;
  late MockSecureStorage mockStorage;
  late AppDatabase db;
  late CatalogDao catalogDao;
  late InventoryDao inventoryDao;
  late SalesDao salesDao;

  setUpAll(() {
    registerFallbackValue(const PushSyncRequestDto(entity: 'test', items: []));
    registerFallbackValue(const PullSyncRequestDto(entity: 'test'));
    registerFallbackValue(
      const AckSyncRequestDto(
        entity: 'test',
        idempotencyKey: 'test',
        items: [],
      ),
    );
  });

  setUp(() async {
    mockApiClient = MockSyncRemoteApiClient();
    mockStorage = MockSecureStorage();
    db = AppDatabase(connection: NativeDatabase.memory());
    catalogDao = CatalogDao(db);
    inventoryDao = InventoryDao(db);
    salesDao = SalesDao(db);

    // Stub common storage operations
    when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
    when(
      () => mockStorage.read(StorageKeys.lastPullCursor),
    ).thenAnswer((_) async => '0');

    // Stub pull orders
    when(() => mockApiClient.pull(any())).thenAnswer(
      (_) async => const PullSyncResponseDto(
        status: 'success',
        items: [],
        nextCursor: 1,
      ),
    );

    // Seed parent User, Account, and Business for foreign keys
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@sync.com',
            passwordHash: 'hash',
            firstName: 'Sync',
            lastName: 'Owner',
          ),
        );
    await db
        .into(db.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-sync-01'),
            ownerId: 'u-owner',
            businessName: 'Sync Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-sync-01',
            businessName: 'Business A',
          ),
        );

    coordinator = SyncCoordinator(
      apiClient: mockApiClient,
      secureStorage: mockStorage,
      db: db,
      catalogDao: catalogDao,
      inventoryDao: inventoryDao,
      salesDao: salesDao,
      retryPolicy: const SyncRetryPolicy(
        maxAttempts: 1,
        initialDelay: Duration.zero,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncCoordinator', () {
    test(
      'runFullSync with empty pending data completes successfully',
      () async {
        final result = await coordinator.runFullSync();

        expect(result.status, equals(SyncStatus.success));
        expect(result.pushedCount, equals(0));
        expect(result.pulledCount, equals(0));
        expect(result.failures, isEmpty);

        // Verify no push requests were made
        verifyNever(() => mockApiClient.push(any()));
        // Verify pull was called for orders
        verify(() => mockApiClient.pull(any())).called(1);
      },
    );

    test('runFullSync handles authentication failure gracefully', () async {
      // Simulate auth error during pull
      when(
        () => mockApiClient.pull(any()),
      ).thenThrow(ApiException.unauthorized('Invalid token'));

      final result = await coordinator.runFullSync();

      expect(result.status, equals(SyncStatus.authenticationRequired));
      expect(result.failures.length, equals(1));
      expect(result.failures.first.type, equals(ApiExceptionType.unauthorized));
    });

    test('runFullSync handles offline failure gracefully', () async {
      // Simulate offline error during pull
      when(
        () => mockApiClient.pull(any()),
      ).thenThrow(const ApiException.noNetwork());

      final result = await coordinator.runFullSync();

      expect(result.status, equals(SyncStatus.offline));
      expect(result.failures.length, equals(1));
      expect(result.failures.first.type, equals(ApiExceptionType.noNetwork));
    });

    test(
      'runFullSync pushes products with show_in_store, attributes, and marks synced',
      () async {
        await catalogDao.insertUnit(
          UnitsCompanion.insert(
            id: 'unit-1',
            businessId: 'BUS_A',
            unitName: 'Piece',
            unitSymbol: 'PCS',
            syncStatus: const drift.Value('synced'),
          ),
        );

        // Insert product with show_in_store = true
        await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'prod-pub-1',
            businessId: 'BUS_A',
            productName: 'Published Product',
            productCode: 'PRD-001',
            description: const drift.Value('Descriptive text'),
            showInStore: const drift.Value(true),
            isActive: const drift.Value(true),
            syncStatus: const drift.Value('pending'),
            version: const drift.Value(1),
          ),
        );

        // Mock API success for products push
        PushSyncRequestDto? capturedProductRequest;
        when(() => mockApiClient.push(any())).thenAnswer((invocation) async {
          final req =
              invocation.positionalArguments.first as PushSyncRequestDto;
          if (req.entity == 'products') {
            capturedProductRequest = req;
            return const PushSyncResponseDto(
              status: 'success',
              results: [
                PushItemResultDto(
                  id: 'prod-pub-1',
                  status: 'applied',
                  serverRevision: 1,
                ),
              ],
            );
          }
          return const PushSyncResponseDto(status: 'success', results: []);
        });

        final result = await coordinator.runFullSync();
        expect(result.status, equals(SyncStatus.success));

        // Verify payload
        expect(capturedProductRequest, isNotNull);
        expect(capturedProductRequest!.entity, equals('products'));
        expect(capturedProductRequest!.items.length, equals(1));
        final item = capturedProductRequest!.items.first;
        expect(item['id'], equals('prod-pub-1'));
        expect(item['product_name'], equals('Published Product'));
        expect(item['product_code'], equals('PRD-001'));
        expect(item['show_in_store'], isTrue);
        expect(item['is_active'], isTrue);
        expect(item['revision'], equals(1));
        expect(item['deleted_at'], isNull);

        // Verify local syncStatus updated to synced
        final syncedProd = await catalogDao.getProductById(
          'prod-pub-1',
          'BUS_A',
        );
        expect(syncedProd!.syncStatus, equals('synced'));
      },
    );

    test(
      'runFullSync pushes product_units with selling_price and correct revision',
      () async {
        await catalogDao.insertUnit(
          UnitsCompanion.insert(
            id: 'unit-b',
            businessId: 'BUS_A',
            unitName: 'Box',
            unitSymbol: 'BOX',
            syncStatus: const drift.Value('synced'),
          ),
        );
        await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'prod-b',
            businessId: 'BUS_A',
            productName: 'Box Product',
            productCode: 'PRD-BOX',
            showInStore: const drift.Value(true),
            isActive: const drift.Value(true),
            syncStatus: const drift.Value('synced'),
            version: const drift.Value(1),
          ),
        );

        // Insert pending product unit with selling_price 350.0
        await catalogDao.insertProductUnit(
          ProductUnitsCompanion.insert(
            id: 'pu-box-1',
            businessId: 'BUS_A',
            productId: 'prod-b',
            unitId: 'unit-b',
            sellingPrice: const drift.Value(350.0),
            purchasePrice: const drift.Value(200.0),
            isBaseUnit: const drift.Value(true),
            isActive: const drift.Value(true),
            syncStatus: const drift.Value('pending'),
            version: const drift.Value(3),
          ),
        );

        PushSyncRequestDto? capturedUnitRequest;
        when(() => mockApiClient.push(any())).thenAnswer((invocation) async {
          final req =
              invocation.positionalArguments.first as PushSyncRequestDto;
          if (req.entity == 'product_units') {
            capturedUnitRequest = req;
            return const PushSyncResponseDto(
              status: 'success',
              results: [
                PushItemResultDto(
                  id: 'pu-box-1',
                  status: 'applied',
                  serverRevision: 3,
                ),
              ],
            );
          }
          return const PushSyncResponseDto(status: 'success', results: []);
        });

        final result = await coordinator.runFullSync();
        expect(result.status, equals(SyncStatus.success));

        expect(capturedUnitRequest, isNotNull);
        final item = capturedUnitRequest!.items.first;
        expect(item['id'], equals('pu-box-1'));
        expect(item['product_id'], equals('prod-b'));
        expect(item['selling_price'], equals(350.0));
        expect(item['cost_price'], equals(200.0));
        expect(item['is_active'], isTrue);
        expect(item['revision'], equals(3));

        final syncedUnit = await catalogDao.getProductUnitById(
          'pu-box-1',
          'BUS_A',
        );
        expect(syncedUnit!.syncStatus, equals('synced'));
      },
    );

    test(
      'softDeleteProduct and softDeleteProductUnit bump version and push deleted_at',
      () async {
        await catalogDao.insertUnit(
          UnitsCompanion.insert(
            id: 'unit-c',
            businessId: 'BUS_A',
            unitName: 'Item',
            unitSymbol: 'ITM',
            syncStatus: const drift.Value('synced'),
          ),
        );
        await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'prod-c',
            businessId: 'BUS_A',
            productName: 'Soft Deleted Prod',
            productCode: 'PRD-C',
            syncStatus: const drift.Value('synced'),
            version: const drift.Value(1),
          ),
        );
        await catalogDao.insertProductUnit(
          ProductUnitsCompanion.insert(
            id: 'pu-c',
            businessId: 'BUS_A',
            productId: 'prod-c',
            unitId: 'unit-c',
            syncStatus: const drift.Value('synced'),
            version: const drift.Value(1),
          ),
        );

        // Perform soft deletes
        await catalogDao.softDeleteProduct('prod-c', 'BUS_A');
        await catalogDao.softDeleteProductUnit('pu-c', 'BUS_A');

        final deletedProd = await (db.select(
          db.products,
        )..where((t) => t.id.equals('prod-c'))).getSingle();
        final deletedUnit = await (db.select(
          db.productUnits,
        )..where((t) => t.id.equals('pu-c'))).getSingle();

        expect(deletedProd.syncStatus, equals('pending_delete'));
        expect(deletedProd.version, equals(2)); // Incremented
        expect(deletedProd.deletedAt, isNotNull);

        expect(deletedUnit.syncStatus, equals('pending_delete'));
        expect(deletedUnit.version, equals(2)); // Incremented
        expect(deletedUnit.deletedAt, isNotNull);

        PushSyncRequestDto? capturedProdReq;
        PushSyncRequestDto? capturedUnitReq;

        when(() => mockApiClient.push(any())).thenAnswer((invocation) async {
          final req =
              invocation.positionalArguments.first as PushSyncRequestDto;
          if (req.entity == 'products') {
            capturedProdReq = req;
            return const PushSyncResponseDto(
              status: 'success',
              results: [
                PushItemResultDto(
                  id: 'prod-c',
                  status: 'applied',
                  serverRevision: 2,
                ),
              ],
            );
          }
          if (req.entity == 'product_units') {
            capturedUnitReq = req;
            return const PushSyncResponseDto(
              status: 'success',
              results: [
                PushItemResultDto(
                  id: 'pu-c',
                  status: 'applied',
                  serverRevision: 2,
                ),
              ],
            );
          }
          return const PushSyncResponseDto(status: 'success', results: []);
        });

        final result = await coordinator.runFullSync();
        expect(result.status, equals(SyncStatus.success));

        expect(capturedProdReq, isNotNull);
        expect(capturedProdReq!.items.first['deleted_at'], isNotNull);
        expect(capturedProdReq!.items.first['revision'], equals(2));

        expect(capturedUnitReq, isNotNull);
        expect(capturedUnitReq!.items.first['deleted_at'], isNotNull);
        expect(capturedUnitReq!.items.first['revision'], equals(2));
      },
    );

    test('push failure retains pending status for future retry', () async {
      await catalogDao.insertProduct(
        ProductsCompanion.insert(
          id: 'prod-fail-1',
          businessId: 'BUS_A',
          productName: 'Failing Product',
          productCode: 'PRD-FAIL',
          syncStatus: const drift.Value('pending'),
          version: const drift.Value(1),
        ),
      );

      when(
        () => mockApiClient.push(any()),
      ).thenThrow(ApiException.server('Server temporarily down'));

      final result = await coordinator.runFullSync();
      expect(result.status, equals(SyncStatus.partialFailure));
      expect(result.failures, isNotEmpty);

      // Product must still be pending
      final product = await catalogDao.getProductById('prod-fail-1', 'BUS_A');
      expect(product!.syncStatus, equals('pending'));
    });
  });
}
