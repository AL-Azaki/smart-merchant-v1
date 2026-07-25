import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/kernel/storage/secure_storage/secure_storage_contract.dart';
import 'package:smart_merchant_erp/kernel/sync/api/sync_remote_api_client.dart';
import 'package:smart_merchant_erp/kernel/sync/coordinator/sync_coordinator.dart';
import 'package:smart_merchant_erp/kernel/sync/dto/sync_dtos.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;

class MockSyncRemoteApiClient extends Mock implements SyncRemoteApiClient {}

class MockSecureStorage extends Mock implements SecureStorageContract {}

void main() {
  group('Sync Integration E2E Mock Tests', () {
    late SyncCoordinator coordinator;
    late MockSyncRemoteApiClient mockApiClient;
    late MockSecureStorage mockStorage;
    late AppDatabase db;
    late CatalogDao catalogDao;
    late InventoryDao inventoryDao;
    late SalesDao salesDao;

    setUpAll(() {
      registerFallbackValue(
        const PushSyncRequestDto(entity: 'test', items: []),
      );
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

      // Force open and disable foreign keys for tests
      await db.customSelect('SELECT 1').get();
      await db.customStatement('PRAGMA foreign_keys = OFF;');

      // Basic storage stubs
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      when(
        () => mockStorage.read(StorageKeys.lastPullCursor),
      ).thenAnswer((_) async => '0');
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Full Sync Cycle: Push 1 category, Pull 1 order, ACK 1 order',
      () async {
        // 1. Setup Push data (1 category pending) by inserting it into real DB
        await db
            .into(db.categories)
            .insert(
              const CategoriesCompanion(
                id: Value('cat1'),
                businessId: Value('b1'),
                categoryName: Value('Test'),
                isActive: Value(true),
                syncStatus: Value('pending'),
                version: Value(1),
                sortOrder: Value(0),
              ),
            );

        // Mock push response for category
        when(() => mockApiClient.push(any())).thenAnswer((invocation) async {
          final req =
              invocation.positionalArguments.first as PushSyncRequestDto;
          expect(req.entity, equals('categories'));
          expect(req.items.length, equals(1));
          return const PushSyncResponseDto(
            status: 'success',
            results: [
              PushItemResultDto(
                id: 'cat1',
                status: 'applied',
                serverRevision: 1,
              ),
            ],
          );
        });

        // 2. Setup Pull data (1 order incoming)
        when(() => mockApiClient.pull(any())).thenAnswer(
          (_) async => const PullSyncResponseDto(
            status: 'success',
            nextCursor: 2,
            items: [
              {
                'id': 'order1',
                'business_id': 'b1',
                'order_number': 'ORD-001',
                'status': 'Pending',
                'revision': 2,
              },
            ],
          ),
        );

        // 3. Setup ACK
        when(() => mockApiClient.ack(any())).thenAnswer((invocation) async {
          final req = invocation.positionalArguments.first as AckSyncRequestDto;
          expect(req.entity, equals('orders'));
          expect(req.items.length, equals(1));
          expect(req.items.first.id, equals('order1'));
          return const AckSyncResponseDto(
            status: 'success',
            results: [AckItemResultDto(id: 'order1', status: 'acked')],
          );
        });

        coordinator = SyncCoordinator(
          apiClient: mockApiClient,
          secureStorage: mockStorage,
          db: db,
          catalogDao: catalogDao,
          inventoryDao: inventoryDao,
          salesDao: salesDao,
        );

        final result = await coordinator.runFullSync();

        expect(result.status, equals(SyncStatus.success));
        expect(result.pushedCount, equals(1));
        expect(result.pulledCount, equals(1));
        expect(result.ackedCount, equals(1));

        // Verify category was marked synced in the DB
        final cat = await (db.select(
          db.categories,
        )..where((t) => t.id.equals('cat1'))).getSingle();
        expect(cat.syncStatus, equals('synced'));

        // Verify order was inserted
        final order = await salesDao.getOrderById('order1', 'b1');
        expect(order, isNotNull);
        expect(order!.orderNumber, equals('ORD-001'));

        // Verify ACK was sent
        verify(() => mockApiClient.ack(any())).called(1);
      },
    );
  });
}
