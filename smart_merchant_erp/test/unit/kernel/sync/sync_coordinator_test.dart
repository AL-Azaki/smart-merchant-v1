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
  });
}
