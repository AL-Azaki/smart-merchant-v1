import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../application/sales_calculator.dart';
import '../../application/usecases/complete_sale_usecase.dart';
import '../../application/services/online_order_service.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../inventory/application/services/warehouse_context_service.dart';

part 'pos_provider.g.dart';

// النموذج الخاص بعنصر السلة داخل واجهة الكاشير
class PosCartItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  // Real database IDs for submission
  final String? productUnitId;

  PosCartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.15, // Defaulting to 15% VAT for standard ERP
    this.productUnitId,
  });

  PosCartItem copyWith({double? quantity}) {
    return PosCartItem(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      taxRate: taxRate,
      productUnitId: productUnitId,
    );
  }
}

// حالة نقطة البيع
class PosState {
  final List<PosCartItem> cart;
  final InvoiceTotals totals;

  // IDs for actual sale submission
  final String? customerId;
  final String? customerName;
  final String currencyId;
  final String? warehouseId;

  // Online Order source reference (for POS handoff)
  final String? sourceOrderId;

  // Mutation State
  final bool isSubmitting;
  final String? successInvoiceId;
  final Failure? error;

  PosState({
    required this.cart,
    required this.totals,
    this.customerId,
    this.customerName,
    this.currencyId = 'YER',
    this.warehouseId,
    this.sourceOrderId,
    this.isSubmitting = false,
    this.successInvoiceId,
    this.error,
  });

  factory PosState.initial() {
    return PosState(
      cart: [],
      totals: InvoiceTotals(
        rawSubtotal: 0,
        totalDiscount: 0,
        taxableAmount: 0,
        taxTotal: 0,
        grandTotal: 0,
      ),
    );
  }

  PosState copyWith({
    List<PosCartItem>? cart,
    InvoiceTotals? totals,
    String? customerId,
    String? customerName,
    String? currencyId,
    String? warehouseId,
    String? sourceOrderId,
    bool? isSubmitting,
    String? successInvoiceId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSourceOrder = false,
  }) {
    return PosState(
      cart: cart ?? this.cart,
      totals: totals ?? this.totals,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      currencyId: currencyId ?? this.currencyId,
      warehouseId: warehouseId ?? this.warehouseId,
      sourceOrderId: clearSourceOrder
          ? null
          : (sourceOrderId ?? this.sourceOrderId),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successInvoiceId: clearSuccess
          ? null
          : (successInvoiceId ?? this.successInvoiceId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// العقل المدبر للحالة (ViewModel)
@riverpod
class PosNotifier extends _$PosNotifier {
  @override
  PosState build() {
    return PosState.initial();
  }

  void addProduct({
    required String id,
    required String name,
    required double price,
    double taxRate = 0.15,
    String? productUnitId,
  }) {
    if (state.isSubmitting) return;

    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];
      currentCart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
    } else {
      currentCart.add(
        PosCartItem(
          id: id,
          name: name,
          quantity: 1,
          unitPrice: price,
          taxRate: taxRate,
          productUnitId: productUnitId ?? id,
        ),
      );
    }

    _recalculate(currentCart);
  }

  void updateQuantity(String id, double newQuantity) {
    if (state.isSubmitting) return;

    if (newQuantity <= 0) {
      final currentCart = state.cart.where((item) => item.id != id).toList();
      _recalculate(currentCart);
      return;
    }

    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];
      currentCart[existingIndex] = existing.copyWith(quantity: newQuantity);
      _recalculate(currentCart);
    }
  }

  void _recalculate(List<PosCartItem> newCart) {
    final salesItems = newCart
        .map(
          (c) => SalesItem(
            quantity: c.quantity,
            unitPrice: c.unitPrice,
            taxRate: c.taxRate,
          ),
        )
        .toList();

    final totals = SalesCalculator.calculate(items: salesItems);

    state = state.copyWith(
      cart: newCart,
      totals: totals,
      clearError: true,
      clearSuccess: true,
    );
  }

  void setCustomer(String id, String name) {
    if (state.isSubmitting) return;
    state = state.copyWith(customerId: id, customerName: name);
  }

  void clearCart() {
    if (state.isSubmitting) return;
    state = PosState.initial();
  }

  /// Loads an accepted Online Order into the POS cart for explicit sale confirmation.
  ///
  /// CRITICAL: This does NOT complete the sale. It only populates the cart.
  /// The cashier must still explicitly confirm payment through the existing POS workflow.
  ///
  /// PRICE POLICY: Uses the storefront order price (unitPrice from the order item)
  /// since the order was placed at those agreed prices.
  ///
  /// DUPLICATE PROTECTION: Checks sourceOrderId to prevent loading the same order twice.
  /// Also checks if order is already fulfilled.
  Future<void> loadFromOnlineOrder(OrderWithItems orderWithItems) async {
    if (state.isSubmitting) return;

    final order = orderWithItems.order;
    final items = orderWithItems.items;

    // Duplicate protection: prevent loading same order again
    if (state.sourceOrderId == order.id) {
      state = state.copyWith(
        error: const ValidationFailure('هذا الطلب محمّل بالفعل في نقطة البيع.'),
      );
      return;
    }

    // Verify order is in accepted (Confirmed) state
    if (order.status != 'Confirmed') {
      state = state.copyWith(
        error: ValidationFailure(
          'لا يمكن فتح طلب بحالة "${order.status}" في نقطة البيع. يجب قبول الطلب أولاً.',
        ),
      );
      return;
    }

    // Check if order is already fulfilled
    final service = getIt<OnlineOrderService>();
    final isFulfilled = await service.isOrderAlreadyFulfilled(order.id);
    if (isFulfilled) {
      state = state.copyWith(
        error: const ValidationFailure(
          'هذا الطلب مكتمل بالفعل ولا يمكن معالجته مرة أخرى.',
        ),
      );
      return;
    }

    // Map order items to POS cart items
    // PRICE POLICY: Preserve storefront order prices
    final cartItems = items.map((item) {
      return PosCartItem(
        id: item.productUnitId,
        name:
            'منتج ${item.productUnitId.substring(0, 8)}', // Will be resolved by product lookup
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxRate: item.quantity > 0
            ? (item.tax / (item.quantity * item.unitPrice)).clamp(0.0, 1.0)
            : 0.0,
        productUnitId: item.productUnitId,
      );
    }).toList();

    // Calculate totals
    final salesItems = cartItems
        .map(
          (c) => SalesItem(
            quantity: c.quantity,
            unitPrice: c.unitPrice,
            taxRate: c.taxRate,
          ),
        )
        .toList();
    final totals = SalesCalculator.calculate(items: salesItems);

    state = PosState(
      cart: cartItems,
      totals: totals,
      customerId: order.customerId,
      currencyId: order.currencyId,
      sourceOrderId: order.id,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Executes the actual sale using the Application Layer UseCase.
  Future<void> submitSale({
    required double cashReceived,
    required String paymentMethodId,
  }) async {
    if (state.isSubmitting) return;
    if (state.cart.isEmpty) return;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    final sessionState = ref.read(sessionNotifierProvider);
    if (!sessionState.isActive || sessionState.branchId == null) {
      state = state.copyWith(
        isSubmitting: false,
        error: const ValidationFailure(
          'Session or Branch context missing. Cannot execute sale.',
        ),
      );
      return;
    }

    String resolvedWarehouseId;
    try {
      final warehouseContextService = getIt<WarehouseContextService>();
      final warehouse = await warehouseContextService.resolveDefaultWarehouse(
        sessionState.businessId!,
        sessionState.branchId!,
      );
      resolvedWarehouseId = warehouse.id;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ValidationFailure(e.toString()),
      );
      return;
    }

    final useCase = ref.read(completeSaleUseCaseProvider);

    final items = state.cart.map((item) {
      final lineTotal = item.quantity * item.unitPrice;
      return CompleteSaleItemCommand(
        productUnitId: item.productUnitId ?? item.id,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        warehouseId: resolvedWarehouseId,
        tax: lineTotal * item.taxRate,
        discount: 0,
      );
    }).toList();

    final command = CompleteSaleCommand(
      customerId: state.customerId ?? 'DEFAULT-CUSTOMER',
      currencyId: state.currencyId,
      isCreditSale: cashReceived < state.totals.grandTotal,
      items: items,
    );

    final result = await useCase(command);

    result.fold(
      (failure) {
        // SALE FAILURE: Online Order must NOT be falsely marked completed.
        // POS cart/order context remains recoverable.
        state = state.copyWith(isSubmitting: false, error: failure);
      },
      (invoiceId) async {
        // If this sale was from an Online Order, mark the order as fulfilled
        // ONLY after CompleteSaleUseCase successfully committed.
        if (state.sourceOrderId != null) {
          final service = getIt<OnlineOrderService>();
          await service.markOrderFulfilled(state.sourceOrderId!);
        }

        state = state.copyWith(
          isSubmitting: false,
          successInvoiceId: invoiceId,
        );
      },
    );
  }
}
