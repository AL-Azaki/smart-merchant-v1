import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../../../../app/config/api_client.dart';
import '../../../../kernel/network/connectivity/network_monitor.dart';
import '../../../../kernel/sync/api/sync_remote_api_client.dart';
import '../../domain/models/order_status_feedback_item.dart';
import '../../domain/repositories/order_status_feedback_storage.dart';

/// Service responsible for queueing, transmitting, and retrying
/// online order status feedback from Flutter ERP to Laravel.
///
/// INVARIANTS:
/// - Never pushes entire order data.
/// - Only transmits status, idempotency_key, and optional POS invoice reference.
/// - Retry NEVER creates duplicate invoices or repeats stock deduction.
/// - Feedback is durably stored locally so it survives network dropouts and app restarts.
class OrderStatusFeedbackService {
  final SyncRemoteApiClient _apiClient;
  final OrderStatusFeedbackStorage _storage;
  final Uuid _uuid;

  bool _isRetrying = false;
  bool get isRetrying => _isRetrying;

  StreamSubscription<NetworkStatus>? _connectivitySub;

  OrderStatusFeedbackService({
    required SyncRemoteApiClient apiClient,
    required OrderStatusFeedbackStorage storage,
    Uuid? uuid,
  })  : _apiClient = apiClient,
        _storage = storage,
        _uuid = uuid ?? const Uuid();

  /// Hooks into connectivity notifications to automatically retry pending feedback items
  /// when device connectivity transitions to online.
  void initializeConnectivityListener(NetworkMonitorContract networkMonitor) {
    _connectivitySub?.cancel();
    _connectivitySub = networkMonitor.onStatusChanged.listen((status) {
      if (status == NetworkStatus.online) {
        retryPendingFeedbacks(force: true);
      }
    });
  }

  /// Cancels connectivity stream subscription when service is disposed.
  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Enqueues status feedback locally and attempts an immediate dispatch.
  /// If the network is unavailable or times out, the feedback remains safely
  /// persisted in pending state for subsequent retries.
  Future<OrderStatusFeedbackItem> sendFeedback({
    required String orderId,
    required String status,
    String? invoiceId,
    String? invoiceNumber,
    String? completedAt,
  }) async {
    final now = DateTime.now();
    final item = OrderStatusFeedbackItem(
      id: _uuid.v4(),
      orderId: orderId,
      status: status,
      idempotencyKey: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      completedAt: completedAt,
    );

    await _storage.save(item);

    return _dispatch(item);
  }

  /// Retries all pending (unsynced) feedback items.
  /// Called upon network reconnection, app startup, or periodic sync schedule.
  ///
  /// CRITICAL INVARIANTS:
  /// - Only updates status remotely; NEVER modifies local invoices or inventory.
  /// - Guarded against concurrent duplicate execution via [_isRetrying].
  /// - Respects exponential backoff and permanent error thresholds, unless [force] is true.
  Future<int> retryPendingFeedbacks({bool force = false}) async {
    if (_isRetrying) {
      return 0; // Concurrency guard: already retrying
    }
    _isRetrying = true;

    try {
      final pendingItems = await _storage.getPending();
      int successCount = 0;
      final now = DateTime.now();

      for (final item in pendingItems) {
        // Skip if scheduled for future retry under exponential backoff (unless forced)
        if (!force && item.nextRetryAt != null && now.isBefore(item.nextRetryAt!)) {
          continue;
        }

        // If permanently failed (403/422 with multiple retries), do not hammer server forever
        if (item.retryCount >= 5 &&
            (item.lastErrorCode == 403 ||
                item.lastErrorCode == 422 ||
                (item.lastError != null &&
                    (item.lastError!.contains('403') ||
                        item.lastError!.contains('422'))))) {
          continue;
        }

        final result = await _dispatch(item);
        if (result.isSynced) {
          successCount++;
        }
      }

      return successCount;
    } finally {
      _isRetrying = false;
    }
  }

  /// Calculates next retry timestamp using exponential backoff capped at 5 minutes.
  DateTime _calculateNextRetry(int attemptCount) {
    final delaySeconds = math.min(300, math.pow(2, attemptCount).toInt() * 5);
    return DateTime.now().add(Duration(seconds: delaySeconds));
  }

  /// Internal dispatch worker sending the limited feedback payload to Laravel.
  Future<OrderStatusFeedbackItem> _dispatch(OrderStatusFeedbackItem item) async {
    try {
      final response = await _apiClient.updateOrderStatus(
        orderId: item.orderId,
        status: item.status,
        idempotencyKey: item.idempotencyKey,
        invoiceId: item.invoiceId,
        invoiceNumber: item.invoiceNumber,
        completedAt: item.completedAt,
      );

      // Check if success or idempotent replay
      if (response['status'] == 'success') {
        await _storage.markSynced(item.id);
        final synced = item.copyWith(
          isSynced: true,
          updatedAt: DateTime.now(),
        );
        await _storage.save(synced);
        return synced;
      } else {
        final failed = item.copyWith(
          retryCount: item.retryCount + 1,
          lastError: response['message']?.toString() ?? 'Unknown response',
          nextRetryAt: _calculateNextRetry(item.retryCount),
          updatedAt: DateTime.now(),
        );
        await _storage.save(failed);
        return failed;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Preserved for re-authentication retry; do not increment counter excessively
        final waiting = item.copyWith(
          lastErrorCode: 401,
          lastError: '401: ${e.message}',
          updatedAt: DateTime.now(),
        );
        await _storage.save(waiting);
        return waiting;
      } else if (e.statusCode == 403 || e.statusCode == 422) {
        // Permanent error: invalid transition or tenant mismatch
        final permFailed = item.copyWith(
          retryCount: item.retryCount + 1,
          lastErrorCode: e.statusCode,
          lastError: '${e.statusCode}: ${e.message}',
          updatedAt: DateTime.now(),
        );
        await _storage.save(permFailed);
        return permFailed;
      } else if (e.statusCode == 409) {
        // Conflict / idempotency replay
        // If the server notes it as replay, mark synced
        if (e.message.contains('replay') || e.message.contains('already')) {
          await _storage.markSynced(item.id);
          final synced = item.copyWith(
            isSynced: true,
            updatedAt: DateTime.now(),
          );
          await _storage.save(synced);
          return synced;
        }
        final conflict = item.copyWith(
          retryCount: item.retryCount + 1,
          lastErrorCode: 409,
          lastError: '409: ${e.message}',
          nextRetryAt: _calculateNextRetry(item.retryCount),
          updatedAt: DateTime.now(),
        );
        await _storage.save(conflict);
        return conflict;
      } else {
        // Transient network, timeout, 5xx: increment retry and keep pending with backoff
        final retrying = item.copyWith(
          retryCount: item.retryCount + 1,
          lastErrorCode: e.statusCode,
          lastError: e.message,
          nextRetryAt: _calculateNextRetry(item.retryCount),
          updatedAt: DateTime.now(),
        );
        await _storage.save(retrying);
        return retrying;
      }
    } catch (e) {
      // General network error
      final retrying = item.copyWith(
        retryCount: item.retryCount + 1,
        lastError: e.toString(),
        nextRetryAt: _calculateNextRetry(item.retryCount),
        updatedAt: DateTime.now(),
      );
      await _storage.save(retrying);
      return retrying;
    }
  }

  /// Exposes storage for inspection in tests and diagnostics.
  OrderStatusFeedbackStorage get storage => _storage;
}
