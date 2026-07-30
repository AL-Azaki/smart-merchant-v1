import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/online_order_service.dart';

/// State class for the Online Orders Inbox.
class OnlineOrdersState {
  final List<OrderEntity> orders;
  final String? selectedOrderId;
  final String? statusFilter;
  final String searchQuery;
  final bool isLoading;
  final bool isActionInProgress;
  final String? errorMessage;
  final String? successMessage;

  const OnlineOrdersState({
    this.orders = const [],
    this.selectedOrderId,
    this.statusFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.isActionInProgress = false,
    this.errorMessage,
    this.successMessage,
  });

  OnlineOrdersState copyWith({
    List<OrderEntity>? orders,
    String? selectedOrderId,
    String? statusFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isActionInProgress,
    String? errorMessage,
    String? successMessage,
    bool clearSelectedOrder = false,
    bool clearStatusFilter = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OnlineOrdersState(
      orders: orders ?? this.orders,
      selectedOrderId: clearSelectedOrder
          ? null
          : (selectedOrderId ?? this.selectedOrderId),
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  /// Count of orders in Pending status.
  int get pendingCount => orders.where((o) => o.status == 'Pending').length;

  /// Count of orders in Confirmed (accepted) status.
  int get confirmedCount => orders.where((o) => o.status == 'Confirmed').length;
}

/// Reactive stream provider for online orders from SQLite.
final onlineOrdersNotifierProvider = AutoDisposeStreamNotifierProvider<OnlineOrdersNotifier, List<OrderEntity>>(() => OnlineOrdersNotifier());

class OnlineOrdersNotifier extends AutoDisposeStreamNotifier<List<OrderEntity>> {
  @override
  Stream<List<OrderEntity>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(salesRepositoryProvider);

    // Watch all orders for this business, sorted by order date descending
    return repo.watchOrders(OrderFilter(businessId: session.businessId!));
  }
}

/// Stateful notifier for UI actions (accept, reject, select, filter, search).
final onlineOrdersActionNotifierProvider = AutoDisposeNotifierProvider<OnlineOrdersActionNotifier, OnlineOrdersState>(() => OnlineOrdersActionNotifier());

class OnlineOrdersActionNotifier extends AutoDisposeNotifier<OnlineOrdersState> {
  @override
  OnlineOrdersState build() {
    return const OnlineOrdersState();
  }

  void selectOrder(String? orderId) {
    state = state.copyWith(
      selectedOrderId: orderId,
      clearError: true,
      clearSuccess: true,
    );
  }

  void setStatusFilter(String? filter) {
    if (filter == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(statusFilter: filter);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<void> acceptOrder(String orderId) async {
    if (state.isActionInProgress) return;

    state = state.copyWith(
      isActionInProgress: true,
      clearError: true,
      clearSuccess: true,
    );

    final service = getIt<OnlineOrderService>();
    final result = await service.acceptOrder(orderId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isActionInProgress: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isActionInProgress: false,
          successMessage: 'تم قبول الطلب بنجاح',
        );
      },
    );
  }

  Future<void> rejectOrder(String orderId) async {
    if (state.isActionInProgress) return;

    state = state.copyWith(
      isActionInProgress: true,
      clearError: true,
      clearSuccess: true,
    );

    final service = getIt<OnlineOrderService>();
    final result = await service.rejectOrder(orderId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isActionInProgress: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isActionInProgress: false,
          successMessage: 'تم رفض الطلب',
          clearSelectedOrder: true,
        );
      },
    );
  }

  Future<void> markOrderFulfilled(String orderId) async {
    if (state.isActionInProgress) return;

    state = state.copyWith(
      isActionInProgress: true,
      clearError: true,
      clearSuccess: true,
    );

    final service = getIt<OnlineOrderService>();
    final result = await service.markOrderFulfilled(orderId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isActionInProgress: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isActionInProgress: false,
          successMessage: 'تم إكمال الطلب وربطه بالفاتورة',
        );
      },
    );
  }
}
