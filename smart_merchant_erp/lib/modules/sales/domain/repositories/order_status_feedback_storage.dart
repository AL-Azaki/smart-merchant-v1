import '../models/order_status_feedback_item.dart';

/// Abstract interface for storing order status feedback items.
/// Production implementations must write durably to Drift / SQLite outbox table.
abstract interface class OrderStatusFeedbackStorage {
  Future<void> save(OrderStatusFeedbackItem item);
  Future<List<OrderStatusFeedbackItem>> getPending();
  Future<OrderStatusFeedbackItem?> getById(String id);
  Future<void> markSynced(String id);
  Future<void> delete(String id);
  Future<void> clear();
}

/// In-memory TEST FAKE ONLY.
///
/// CAUTION: This implementation stores items in a transient RAM map.
/// It CANNOT survive process death, app close, or system reboot.
/// DO NOT register this class in production dependency injection.
class FakeInMemoryOrderStatusFeedbackStorage implements OrderStatusFeedbackStorage {
  final Map<String, OrderStatusFeedbackItem> _items = {};

  @override
  Future<void> save(OrderStatusFeedbackItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<List<OrderStatusFeedbackItem>> getPending() async {
    return _items.values.where((item) => !item.isSynced).toList();
  }

  @override
  Future<OrderStatusFeedbackItem?> getById(String id) async {
    return _items[id];
  }

  @override
  Future<void> markSynced(String id) async {
    final existing = _items[id];
    if (existing != null) {
      _items[id] = existing.copyWith(
        isSynced: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

/// Backwards compatibility alias for unit tests.
@Deprecated('Use FakeInMemoryOrderStatusFeedbackStorage for unit tests, or DriftOrderStatusFeedbackStorage in production')
typedef InMemoryOrderStatusFeedbackStorage = FakeInMemoryOrderStatusFeedbackStorage;

