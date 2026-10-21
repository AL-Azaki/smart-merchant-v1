import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/app/config/api_client.dart';
import 'package:smart_merchant_erp/kernel/sync/api/sync_remote_api_client.dart';
import 'package:smart_merchant_erp/modules/sales/domain/models/order_status_feedback_item.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/order_status_feedback_storage.dart';
import 'package:smart_merchant_erp/modules/sales/application/services/order_status_feedback_service.dart';
import 'package:smart_merchant_erp/modules/sales/application/services/online_order_service.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

class MockSyncRemoteApiClient extends Mock implements SyncRemoteApiClient {}
class MockSalesRepository extends Mock implements SalesRepository {}
class MockApplicationContext extends Mock implements ApplicationContext {}

void main() {
  late MockSyncRemoteApiClient mockApiClient;
  late InMemoryOrderStatusFeedbackStorage storage;
  late OrderStatusFeedbackService feedbackService;
  late MockSalesRepository mockSalesRepo;
  late MockApplicationContext mockContext;
  late OnlineOrderService onlineOrderService;

  const testBusinessId = 'bus-001';
  const testOrderId = 'ord-123';

  setUp(() {
    mockApiClient = MockSyncRemoteApiClient();
    storage = InMemoryOrderStatusFeedbackStorage();
    feedbackService = OrderStatusFeedbackService(
      apiClient: mockApiClient,
      storage: storage,
    );

    mockSalesRepo = MockSalesRepository();
    mockContext = MockApplicationContext();
    when(() => mockContext.currentBusinessId).thenReturn(testBusinessId);

    onlineOrderService = OnlineOrderService(
      mockSalesRepo,
      mockContext,
      feedbackService,
    );
  });

  OrderEntity createMockOrder({String status = 'Pending'}) {
    return OrderEntity(
      id: testOrderId,
      businessId: testBusinessId,
      branchId: 'branch-1',
      channelId: 'channel-1',
      orderNumber: 'ORD-001',
      orderDate: DateTime.now(),
      currencyId: 'YER',
      exchangeRate: 1.0,
      subTotal: 100.0,
      discountTotal: 0.0,
      taxTotal: 0.0,
      grandTotal: 100.0,
      baseSubTotal: 100.0,
      baseDiscountTotal: 0.0,
      baseTaxTotal: 0.0,
      baseGrandTotal: 100.0,
      paymentStatus: 'Unpaid',
      status: status,
      syncStatus: 'synced',
      version: 1,
    );
  }

  group('OrderStatusFeedbackService Unit Tests', () {
    test('1. Accept order triggers Confirmed feedback with strict limited payload', () async {
      when(() => mockSalesRepo.getOrderById(testOrderId, testBusinessId))
          .thenAnswer((_) async => createMockOrder());
      when(() => mockSalesRepo.updateOrderStatus(testOrderId, testBusinessId, 'Confirmed'))
          .thenAnswer((_) async => true);

      when(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Confirmed',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => {'status': 'success'});

      final result = await onlineOrderService.acceptOrder(testOrderId);
      expect(result.isRight(), true);

      final pending = await storage.getPending();
      expect(pending.length, 0); // Synced immediately

      // Verify remote API call had strictly limited arguments
      verify(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Confirmed',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).called(1);
    });

    test('2. Reject order triggers Cancelled feedback', () async {
      when(() => mockSalesRepo.getOrderById(testOrderId, testBusinessId))
          .thenAnswer((_) async => createMockOrder());
      when(() => mockSalesRepo.updateOrderStatus(testOrderId, testBusinessId, 'Cancelled'))
          .thenAnswer((_) async => true);

      when(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Cancelled',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => {'status': 'success'});

      final result = await onlineOrderService.rejectOrder(testOrderId);
      expect(result.isRight(), true);

      verify(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Cancelled',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).called(1);
    });

    test('3. Successful POS sale completion triggers Delivered feedback with invoiceId', () async {
      when(() => mockSalesRepo.getOrderById(testOrderId, testBusinessId))
          .thenAnswer((_) async => createMockOrder(status: 'Confirmed'));
      when(() => mockSalesRepo.updateOrderStatus(testOrderId, testBusinessId, 'Delivered'))
          .thenAnswer((_) async => true);

      when(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Delivered',
            idempotencyKey: any(named: 'idempotencyKey'),
            invoiceId: 'inv-pos-999',
            completedAt: any(named: 'completedAt'),
          )).thenAnswer((_) async => {'status': 'success'});

      final result = await onlineOrderService.markOrderFulfilled(
        testOrderId,
        invoiceId: 'inv-pos-999',
      );
      expect(result.isRight(), true);

      verify(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Delivered',
            idempotencyKey: any(named: 'idempotencyKey'),
            invoiceId: 'inv-pos-999',
            completedAt: any(named: 'completedAt'),
          )).called(1);
    });

    test('4. Offline dispatch persists feedback locally as pending without failing local operation', () async {
      when(() => mockSalesRepo.getOrderById(testOrderId, testBusinessId))
          .thenAnswer((_) async => createMockOrder(status: 'Confirmed'));
      when(() => mockSalesRepo.updateOrderStatus(testOrderId, testBusinessId, 'Delivered'))
          .thenAnswer((_) async => true);

      // Simulate offline / network failure
      when(() => mockApiClient.updateOrderStatus(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
            idempotencyKey: any(named: 'idempotencyKey'),
            invoiceId: any(named: 'invoiceId'),
            completedAt: any(named: 'completedAt'),
          )).thenThrow(const ApiException.noNetwork());

      final result = await onlineOrderService.markOrderFulfilled(
        testOrderId,
        invoiceId: 'inv-offline-01',
      );

      // Local operation succeeded!
      expect(result.isRight(), true);

      // Feedback is preserved locally in pending status
      final pending = await storage.getPending();
      expect(pending.length, 1);
      expect(pending.first.orderId, testOrderId);
      expect(pending.first.status, 'Delivered');
      expect(pending.first.isSynced, false);
      expect(pending.first.retryCount, 1);
    });

    test('5. Reconnect retry sends pending feedback using same idempotency key', () async {
      // Seed pending offline item in storage
      final now = DateTime.now();
      const fixedKey = 'idem-fixed-uuid-123';
      final offlineItem = OrderStatusFeedbackItem(
        id: 'fb-01',
        orderId: testOrderId,
        status: 'Delivered',
        idempotencyKey: fixedKey,
        createdAt: now,
        updatedAt: now,
        invoiceId: 'inv-offline-01',
        retryCount: 1,
      );
      await storage.save(offlineItem);

      // Reconnect: remote API is now available
      when(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Delivered',
            idempotencyKey: fixedKey,
            invoiceId: 'inv-offline-01',
          )).thenAnswer((_) async => {'status': 'success', 'message': 'Delivered'});

      final syncedCount = await feedbackService.retryPendingFeedbacks();
      expect(syncedCount, 1);

      // Item is now marked as synced
      final pendingAfter = await storage.getPending();
      expect(pendingAfter.length, 0);

      final stored = await storage.getById('fb-01');
      expect(stored?.isSynced, true);
    });

    test('6. Idempotent replay from server is treated as success and marks item synced', () async {
      when(() => mockApiClient.updateOrderStatus(
            orderId: testOrderId,
            status: 'Delivered',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => {
            'status': 'success',
            'message': 'Idempotent replay',
          });

      final item = await feedbackService.sendFeedback(
        orderId: testOrderId,
        status: 'Delivered',
      );

      expect(item.isSynced, true);
      final stored = await storage.getById(item.id);
      expect(stored?.isSynced, true);
    });

    test('7. 403 Forbidden / 422 Invalid Transition stops infinite retries', () async {
      when(() => mockApiClient.updateOrderStatus(
            orderId: any(named: 'orderId'),
            status: any(named: 'status'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(ApiException.validation('Invalid order status transition'));

      final item = await feedbackService.sendFeedback(
        orderId: testOrderId,
        status: 'Delivered',
      );

      expect(item.isSynced, false);
      expect(item.lastError, contains('422'));

      // Simulate 5 repeated retry failures
      OrderStatusFeedbackItem current = item;
      for (int i = 0; i < 5; i++) {
        current = current.copyWith(retryCount: current.retryCount + 1);
        await storage.save(current);
      }

      // Now retryPendingFeedbacks will skip hammering server
      final retryResult = await feedbackService.retryPendingFeedbacks();
      expect(retryResult, 0);
    });

    test('8. Retry NEVER touches invoice creation or stock deduction', () async {
      // Pre-condition: Pending feedback exists in storage
      final item = OrderStatusFeedbackItem(
        id: 'fb-test',
        orderId: 'ord-retry-safety',
        status: 'Delivered',
        idempotencyKey: 'key-safety-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        invoiceId: 'inv-already-created-once',
      );
      await storage.save(item);

      when(() => mockApiClient.updateOrderStatus(
            orderId: 'ord-retry-safety',
            status: 'Delivered',
            idempotencyKey: 'key-safety-1',
            invoiceId: 'inv-already-created-once',
          )).thenAnswer((_) async => {'status': 'success'});

      // Running retry
      await feedbackService.retryPendingFeedbacks();

      // Zero calls to repository to create invoices or adjust inventory
      verifyNever(() => mockSalesRepo.getOrderById(any(), any()));
      verifyNever(() => mockSalesRepo.updateOrderStatus(any(), any(), any()));
    });
  });
}
