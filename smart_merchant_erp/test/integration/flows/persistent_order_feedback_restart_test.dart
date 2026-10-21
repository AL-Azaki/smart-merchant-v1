import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/network/connectivity/network_monitor.dart';
import 'package:smart_merchant_erp/kernel/sync/api/sync_remote_api_client.dart';
import 'package:smart_merchant_erp/modules/sales/domain/models/order_status_feedback_item.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/drift_order_status_feedback_storage.dart';
import 'package:smart_merchant_erp/modules/sales/application/services/order_status_feedback_service.dart';

class MockSyncRemoteApiClient implements SyncRemoteApiClient {
  final List<Map<String, dynamic>> dispatchedCalls = [];
  bool simulateOffline = false;
  bool returnReplayConflict = false;
  bool returnPermanentError = false;

  @override
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    required String idempotencyKey,
    String? invoiceId,
    String? invoiceNumber,
    String? completedAt,
    int? revision,
  }) async {
    if (simulateOffline) {
      throw const SocketException('Connection refused - offline');
    }

    dispatchedCalls.add({
      'orderId': orderId,
      'status': status,
      'idempotencyKey': idempotencyKey,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'completedAt': completedAt,
      'revision': revision,
    });

    if (returnReplayConflict) {
      return {
        'status': 'success',
        'message': 'Idempotent replay: order status already delivered',
        'data': {
          'order_id': orderId,
          'status': status,
          'replay': true,
        },
      };
    }

    if (returnPermanentError) {
      return {
        'status': 'error',
        'message': '422: Invalid state transition',
      };
    }

    return {
      'status': 'success',
      'message': 'Order status updated successfully',
      'data': {
        'order_id': orderId,
        'status': status,
      },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('drift_restart_test_');
    dbFile = File('${tempDir.path}/order_feedback_restart.sqlite');
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Drift Persistent Order Status Feedback & Process Restart QA', () {
    test('1. True Physical File Persistence across DB Close and Re-instantiation', () async {
      final orderId = const Uuid().v4();
      final invoiceId = const Uuid().v4();
      final idempotencyKey = const Uuid().v4();
      final now = DateTime.now();

      // === PROCESS 1: Open DB from file, write pending record, and close connection ===
      {
        final db1 = AppDatabase(connection: NativeDatabase(dbFile));
        final storage1 = DriftOrderStatusFeedbackStorage(db1);
        await storage1.ensureTable();

        final item = OrderStatusFeedbackItem(
          id: const Uuid().v4(),
          orderId: orderId,
          status: 'Delivered',
          idempotencyKey: idempotencyKey,
          invoiceId: invoiceId,
          invoiceNumber: 'INV-TEST-001',
          completedAt: now.toIso8601String(),
          createdAt: now,
          updatedAt: now,
        );

        await storage1.save(item);

        final pendingBeforeClose = await storage1.getPending();
        expect(pendingBeforeClose.length, equals(1));
        expect(pendingBeforeClose.first.orderId, equals(orderId));
        expect(pendingBeforeClose.first.idempotencyKey, equals(idempotencyKey));

        // Teardown Process 1 completely
        await db1.close();
      }

      // Memory map is gone. Only the physical SQLite file on disk remains.
      expect(dbFile.existsSync(), isTrue);
      expect(dbFile.lengthSync(), greaterThan(0));

      // === PROCESS 2: Reopen DB from the same SQLite file from scratch ===
      {
        final db2 = AppDatabase(connection: NativeDatabase(dbFile));
        final storage2 = DriftOrderStatusFeedbackStorage(db2);

        // Read pending feedback from disk
        final pendingAfterRestart = await storage2.getPending();
        expect(pendingAfterRestart.length, equals(1));

        final recovered = pendingAfterRestart.first;
        expect(recovered.orderId, equals(orderId));
        expect(recovered.status, equals('Delivered'));
        expect(recovered.idempotencyKey, equals(idempotencyKey));
        expect(recovered.invoiceId, equals(invoiceId));
        expect(recovered.invoiceNumber, equals('INV-TEST-001'));
        expect(recovered.isSynced, isFalse);

        // Dispatch feedback successfully in Process 2
        final mockApi = MockSyncRemoteApiClient();
        final service2 = OrderStatusFeedbackService(
          apiClient: mockApi,
          storage: storage2,
        );

        final syncedCount = await service2.retryPendingFeedbacks();
        expect(syncedCount, equals(1));
        expect(mockApi.dispatchedCalls.length, equals(1));
        expect(mockApi.dispatchedCalls.first['idempotencyKey'], equals(idempotencyKey));

        // Verify marked synced in storage
        final pendingAfterSync = await storage2.getPending();
        expect(pendingAfterSync.isEmpty, isTrue);

        await db2.close();
      }

      // === PROCESS 3: Reopen again, verify synced item is NOT in pending queue ===
      {
        final db3 = AppDatabase(connection: NativeDatabase(dbFile));
        final storage3 = DriftOrderStatusFeedbackStorage(db3);

        final pendingInProcess3 = await storage3.getPending();
        expect(pendingInProcess3.isEmpty, isTrue);

        await db3.close();
      }
    });

    test('2. Crash Scenario A: App crashes offline before dispatch, recovers on reconnect', () async {
      final orderId = const Uuid().v4();

      // Session 1: Offline dispatch stores locally in SQLite and fails dispatch gracefully
      {
        final db1 = AppDatabase(connection: NativeDatabase(dbFile));
        final storage1 = DriftOrderStatusFeedbackStorage(db1);
        final mockApi = MockSyncRemoteApiClient()..simulateOffline = true;
        final service1 = OrderStatusFeedbackService(apiClient: mockApi, storage: storage1);

        final result = await service1.sendFeedback(
          orderId: orderId,
          status: 'Delivered',
          invoiceId: 'inv-crash-a',
        );

        expect(result.isSynced, isFalse);
        final pending = await storage1.getPending();
        expect(pending.length, equals(1));

        // Crash simulation: close DB
        await db1.close();
      }

      // Session 2: App starts up, reconnects to network, and successfully delivers outbox
      {
        final db2 = AppDatabase(connection: NativeDatabase(dbFile));
        final storage2 = DriftOrderStatusFeedbackStorage(db2);
        final mockApi = MockSyncRemoteApiClient()..simulateOffline = false;
        final service2 = OrderStatusFeedbackService(apiClient: mockApi, storage: storage2);

        final pendingOnStartup = await storage2.getPending();
        expect(pendingOnStartup.length, equals(1));

        final syncedCount = await service2.retryPendingFeedbacks(force: true);
        expect(syncedCount, equals(1));
        expect(mockApi.dispatchedCalls.length, equals(1));

        final pendingAfterRetry = await storage2.getPending();
        expect(pendingAfterRetry.isEmpty, isTrue);

        await db2.close();
      }
    });

    test('3. Crash Scenario B: Feedback reached server, app crashed before markSynced -> replay idempotency handled cleanly', () async {
      final orderId = const Uuid().v4();
      final idempotencyKey = const Uuid().v4();
      final now = DateTime.now();

      final db = AppDatabase(connection: NativeDatabase(dbFile));
      final storage = DriftOrderStatusFeedbackStorage(db);
      final mockApi = MockSyncRemoteApiClient()..returnReplayConflict = true;
      final service = OrderStatusFeedbackService(apiClient: mockApi, storage: storage);

      final item = OrderStatusFeedbackItem(
        id: const Uuid().v4(),
        orderId: orderId,
        status: 'Delivered',
        idempotencyKey: idempotencyKey,
        createdAt: now,
        updatedAt: now,
      );
      await storage.save(item);

      final syncedCount = await service.retryPendingFeedbacks();
      expect(syncedCount, equals(1));

      final pending = await storage.getPending();
      expect(pending.isEmpty, isTrue);

      await db.close();
    });

    test('4. Concurrency Guard: Concurrent retry execution is prevented', () async {
      final db = AppDatabase(connection: NativeDatabase(dbFile));
      final storage = DriftOrderStatusFeedbackStorage(db);
      final mockApi = MockSyncRemoteApiClient();
      final service = OrderStatusFeedbackService(apiClient: mockApi, storage: storage);

      expect(service.isRetrying, isFalse);

      // Save an item
      final now = DateTime.now();
      await storage.save(OrderStatusFeedbackItem(
        id: const Uuid().v4(),
        orderId: const Uuid().v4(),
        status: 'Confirmed',
        idempotencyKey: const Uuid().v4(),
        createdAt: now,
        updatedAt: now,
      ));

      // Trigger parallel retry calls
      final future1 = service.retryPendingFeedbacks();
      final future2 = service.retryPendingFeedbacks();

      final results = await Future.wait([future1, future2]);
      // Exactly one succeeds and one returns 0 due to guard lock
      expect(results.contains(1), isTrue);
      expect(results.contains(0), isTrue);
      expect(mockApi.dispatchedCalls.length, equals(1));

      await db.close();
    });

    test('5. Connectivity Trigger: Reconnecting triggers retry automatically', () async {
      final db = AppDatabase(connection: NativeDatabase(dbFile));
      final storage = DriftOrderStatusFeedbackStorage(db);
      final mockApi = MockSyncRemoteApiClient();
      final service = OrderStatusFeedbackService(apiClient: mockApi, storage: storage);
      final networkMonitor = NetworkMonitorImpl();

      service.initializeConnectivityListener(networkMonitor);

      // Ensure network monitor transitions from offline to online
      networkMonitor.updateStatus(NetworkStatus.offline);

      // Save pending item
      final now = DateTime.now();
      await storage.save(OrderStatusFeedbackItem(
        id: const Uuid().v4(),
        orderId: const Uuid().v4(),
        status: 'Delivered',
        idempotencyKey: const Uuid().v4(),
        createdAt: now,
        updatedAt: now,
      ));

      expect((await storage.getPending()).length, equals(1));

      // Simulate network transition to online
      networkMonitor.updateStatus(NetworkStatus.online);

      // Allow microtasks/event loop to process stream event and async dispatch
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect((await storage.getPending()).isEmpty, isTrue);
      expect(mockApi.dispatchedCalls.length, equals(1));

      service.dispose();
      networkMonitor.dispose();
      await db.close();
    });

    test('6. Security & Privacy Review: Outbox schema contains NO customer PII or line items', () async {
      final db = AppDatabase(connection: NativeDatabase(dbFile));
      final storage = DriftOrderStatusFeedbackStorage(db);
      await storage.ensureTable();

      final columns = await db.customSelect(
        'PRAGMA table_info(order_status_feedback_outbox);',
      ).get();

      final columnNames = columns.map((c) => c.read<String>('name')).toSet();

      // Check strictly allowed fields
      expect(columnNames.contains('id'), isTrue);
      expect(columnNames.contains('order_id'), isTrue);
      expect(columnNames.contains('target_status'), isTrue);
      expect(columnNames.contains('invoice_id'), isTrue);
      expect(columnNames.contains('invoice_number'), isTrue);
      expect(columnNames.contains('completed_at'), isTrue);
      expect(columnNames.contains('idempotency_key'), isTrue);
      expect(columnNames.contains('sync_status'), isTrue);
      expect(columnNames.contains('attempt_count'), isTrue);

      // Strictly verify PROHIBITED fields are absent
      expect(columnNames.contains('customer_name'), isFalse);
      expect(columnNames.contains('customer_phone'), isFalse);
      expect(columnNames.contains('shipping_address'), isFalse);
      expect(columnNames.contains('order_items'), isFalse);
      expect(columnNames.contains('product_ids'), isFalse);
      expect(columnNames.contains('quantities'), isFalse);
      expect(columnNames.contains('prices'), isFalse);
      expect(columnNames.contains('totals'), isFalse);

      await db.close();
    });
  });
}
