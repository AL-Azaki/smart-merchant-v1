import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../application/sales_calculator.dart';
import '../../application/usecases/complete_sale_usecase.dart';
import '../../application/services/online_order_service.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../inventory/application/services/warehouse_context_service.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import 'product_unit_provider.dart';

import '../../../../kernel/storage/app_database.dart';

part 'pos_provider.g.dart';

// النموذج الخاص بعنصر السلة داخل واجهة الكاشير

class PosCartItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double discount;

  // Real database IDs for submission
  final String? productUnitId;
  final String? unitName;
  final double conversionFactor;
  final List<ProductUnit> availableUnits;
  final double totalBaseStock;

  PosCartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.0, // 0% Tax (No VAT)
    this.discount = 0.0,
    this.productUnitId,
    this.unitName,
    this.conversionFactor = 1.0,
    this.availableUnits = const [],
    this.totalBaseStock = double.infinity,
  });

  PosCartItem copyWith({
    double? quantity,
    double? discount,
    String? productUnitId,
    String? unitName,
    double? unitPrice,
    double? conversionFactor,
    List<ProductUnit>? availableUnits,
    double? totalBaseStock,
  }) {
    return PosCartItem(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate,
      discount: discount ?? this.discount,
      productUnitId: productUnitId ?? this.productUnitId,
      unitName: unitName ?? this.unitName,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      availableUnits: availableUnits ?? this.availableUnits,
      totalBaseStock: totalBaseStock ?? this.totalBaseStock,
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

  // Invoice discount
  final double invoiceDiscount;
  final bool isInvoiceDiscountPercentage;

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
    this.invoiceDiscount = 0.0,
    this.isInvoiceDiscountPercentage = false,
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
      invoiceDiscount: 0.0,
      isInvoiceDiscountPercentage: false,
    );
  }

  PosState copyWith({
    List<PosCartItem>? cart,
    InvoiceTotals? totals,
    String? customerId,
    String? customerName,
    String? currencyId,
    String? warehouseId,
    double? invoiceDiscount,
    bool? isInvoiceDiscountPercentage,
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
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      isInvoiceDiscountPercentage:
          isInvoiceDiscountPercentage ?? this.isInvoiceDiscountPercentage,
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
    double taxRate = 0.0,
    String? productUnitId,
    String? unitName,
    double conversionFactor = 1.0,
    List<ProductUnit> availableUnits = const [],
    double? totalBaseStock,
  }) {
    if (state.isSubmitting) return;

    final targetUnitId = productUnitId ?? id;
    final currentCart = List<PosCartItem>.from(state.cart);
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;

    final existingIndex = currentCart.indexWhere(
      (item) => item.id == id && (item.productUnitId ?? item.id) == targetUnitId,
    );

    // Resolve known total base stock for this product
    final stockLimit = totalBaseStock ??
        (existingIndex >= 0
            ? currentCart[existingIndex].totalBaseStock
            : currentCart.where((item) => item.id == id).map((e) => e.totalBaseStock).firstOrNull ?? double.infinity);

    // 1. Strict guard: Out of stock check
    if (stockLimit <= 0) {
      state = state.copyWith(
        error: ValidationFailure('نفد المخزون: لا توجد كمية متوفرة من "$name" في المخزن حالياً.'),
      );
      return;
    }

    // 2. Strict guard: Check cumulative quantity across all units in cart for this product
    final currentReservedBase = currentCart
        .where((item) => item.id == id)
        .fold<double>(0.0, (sum, item) => sum + (item.quantity * (item.conversionFactor > 0 ? item.conversionFactor : 1.0)));

    if (stockLimit.isFinite && (currentReservedBase + factor) > (stockLimit + 0.0001)) {
      final remaining = (stockLimit - currentReservedBase).clamp(0.0, double.infinity);
      state = state.copyWith(
        error: ValidationFailure(
          'الكمية المتوفرة لا تكفي! المتبقي في المخزن (${remaining.toInt()} حبة)، ولا يمكن إضافة المزيد من "$name".',
        ),
      );
      return;
    }

    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];
      currentCart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
        totalBaseStock: stockLimit,
      );
    } else {
      currentCart.add(
        PosCartItem(
          id: id,
          name: name,
          quantity: 1,
          unitPrice: price,
          taxRate: taxRate,
          productUnitId: targetUnitId,
          unitName: unitName,
          conversionFactor: factor,
          availableUnits: availableUnits,
          totalBaseStock: stockLimit,
        ),
      );
    }

    _recalculate(currentCart);
  }

  void switchCartItemUnit(String currentUnitId, ProductUnit newUnit, String newUnitName) {
    if (state.isSubmitting) return;
    final currentCart = List<PosCartItem>.from(state.cart);
    final index = currentCart.indexWhere(
      (item) => (item.productUnitId ?? item.id) == currentUnitId,
    );
    if (index >= 0) {
      final item = currentCart[index];
      final newFactor = newUnit.conversionFactor > 0 ? newUnit.conversionFactor : 1.0;

      // Check if another line for the SAME product already uses newUnit.id
      final duplicateIndex = currentCart.indexWhere(
        (other) =>
            other.id == item.id &&
            (other.productUnitId ?? other.id) == newUnit.id &&
            other != item,
      );

      // Strict stock guard when switching unit
      if (item.totalBaseStock.isFinite) {
        final otherLinesBase = currentCart
            .where((other) =>
                other.id == item.id &&
                (other.productUnitId ?? other.id) != currentUnitId &&
                other != item &&
                (duplicateIndex < 0 || other != currentCart[duplicateIndex]))
            .fold<double>(0.0, (sum, other) => sum + (other.quantity * (other.conversionFactor > 0 ? other.conversionFactor : 1.0)));

        final totalTargetQty = duplicateIndex >= 0
            ? (currentCart[duplicateIndex].quantity + item.quantity)
            : item.quantity;

        final newTotalBase = otherLinesBase + (totalTargetQty * newFactor);
        if (newTotalBase > (item.totalBaseStock + 0.0001)) {
          state = state.copyWith(
            error: ValidationFailure(
              'لا يمكن التحويل إلى "$newUnitName"؛ المخزون المتوفر (${item.totalBaseStock.toInt()} حبة) لا يكفي لهذه الكمية.',
            ),
          );
          return;
        }
      }

      if (duplicateIndex >= 0) {
        // Merge into the existing line for this unit to prevent duplicate rows
        final existingItem = currentCart[duplicateIndex];
        currentCart[duplicateIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity,
        );
        currentCart.removeAt(index);
      } else {
        currentCart[index] = item.copyWith(
          productUnitId: newUnit.id,
          unitName: newUnitName,
          unitPrice: newUnit.sellingPrice > 0 ? newUnit.sellingPrice : item.unitPrice,
          conversionFactor: newFactor,
        );
      }

      _recalculate(currentCart);
    }
  }

  void updateQuantity(String idOrUnitId, double newQuantity) {
    if (state.isSubmitting) return;

    if (newQuantity <= 0) {
      final currentCart = state.cart
          .where((item) =>
              (item.productUnitId ?? item.id) != idOrUnitId &&
              item.id != idOrUnitId)
          .toList();
      _recalculate(currentCart);
      return;
    }

    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere(
      (item) =>
          (item.productUnitId ?? item.id) == idOrUnitId ||
          item.id == idOrUnitId,
    );
    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];

      // Strict stock guard
      if (existing.totalBaseStock.isFinite) {
        final otherLinesBase = currentCart
            .where((item) =>
                item.id == existing.id &&
                (item.productUnitId ?? item.id) != (existing.productUnitId ?? existing.id))
            .fold<double>(0.0, (sum, item) => sum + (item.quantity * (item.conversionFactor > 0 ? item.conversionFactor : 1.0)));

        final requestedTotalBase = otherLinesBase + (newQuantity * existing.conversionFactor);
        if (requestedTotalBase > (existing.totalBaseStock + 0.0001)) {
          final maxAllowedForThisLine =
              ((existing.totalBaseStock - otherLinesBase) / existing.conversionFactor).floorToDouble();
          state = state.copyWith(
            error: ValidationFailure(
              'الكمية المطلوبة تتجاوز المخزون المتوفر! أقصى كمية مسموحة من "${existing.name}" هي ${maxAllowedForThisLine.toInt()} ${existing.unitName ?? "وحدة"} (${existing.totalBaseStock.toInt()} حبة كلياً).',
            ),
          );
          return;
        }
      }

      currentCart[existingIndex] = existing.copyWith(quantity: newQuantity);
      _recalculate(currentCart);
    }
  }

  void removeProduct(String idOrUnitId) {
    updateQuantity(idOrUnitId, 0);
  }

  void updateItemDiscount(String idOrUnitId, double discount) {
    if (state.isSubmitting) return;

    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere(
      (item) =>
          (item.productUnitId ?? item.id) == idOrUnitId ||
          item.id == idOrUnitId,
    );
    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];
      final maxDiscount = existing.quantity * existing.unitPrice;
      final safeDiscount = discount.clamp(0.0, maxDiscount);
      currentCart[existingIndex] = existing.copyWith(discount: safeDiscount);
      _recalculate(currentCart);
    }
  }

  void setInvoiceDiscount(double discount, {bool isPercentage = false}) {
    if (state.isSubmitting) return;
    _recalculate(
      state.cart,
      invoiceDiscount: discount >= 0 ? discount : 0.0,
      isPercentage: isPercentage,
    );
  }

  void _recalculate(
    List<PosCartItem> newCart, {
    double? invoiceDiscount,
    bool? isPercentage,
  }) {
    final effectiveDiscount = invoiceDiscount ?? state.invoiceDiscount;
    final effectiveIsPercentage =
        isPercentage ?? state.isInvoiceDiscountPercentage;

    final salesItems = newCart
        .map(
          (c) => SalesItem(
            quantity: c.quantity,
            unitPrice: c.unitPrice,
            discountAmount: c.discount,
            taxRate: c.taxRate,
          ),
        )
        .toList();

    final totals = SalesCalculator.calculate(
      items: salesItems,
      globalDiscountValue: effectiveDiscount,
      isGlobalDiscountPercentage: effectiveIsPercentage,
    );

    state = state.copyWith(
      cart: newCart,
      totals: totals,
      invoiceDiscount: effectiveDiscount,
      isInvoiceDiscountPercentage: effectiveIsPercentage,
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
        taxRate: 0.0,
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
    double bankReceived = 0.0,
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
        discount: item.discount,
      );
    }).toList();

    final total = state.totals.grandTotal;
    double resolvedCash = cashReceived;
    double resolvedBank = bankReceived;

    if (state.customerId == null) {
      // Walk-in customer: cannot leave remaining unpaid credit
      final methodUpper = paymentMethodId.toUpperCase();
      if (methodUpper == 'SPLIT') {
        // Multi-payment (Cash + Bank): preserve the split amounts entered
        resolvedCash = cashReceived;
        resolvedBank = bankReceived;
      } else if (methodUpper == 'BANK' || methodUpper == 'CARD' || methodUpper == 'NETWORK') {
        resolvedBank = total;
        resolvedCash = 0.0;
      } else {
        resolvedCash = total;
        resolvedBank = 0.0;
      }
    }

    final totalPaid = resolvedCash + resolvedBank;
    final isCredit = totalPaid < (total - 0.001);

    final totalItemDiscounts = state.cart.fold<double>(
      0.0,
      (sum, i) => sum + i.discount,
    );
    final effectiveInvoiceDiscount =
        (state.totals.totalDiscount - totalItemDiscounts)
            .clamp(0.0, state.totals.totalDiscount);

    // Strict pre-submission inventory stock guard
    for (final item in state.cart) {
      if (item.totalBaseStock.isFinite) {
        final totalDemandForProduct = state.cart
            .where((other) => other.id == item.id)
            .fold<double>(0.0, (sum, other) => sum + (other.quantity * (other.conversionFactor > 0 ? other.conversionFactor : 1.0)));
        if (totalDemandForProduct > (item.totalBaseStock + 0.0001)) {
          state = state.copyWith(
            isSubmitting: false,
            error: ValidationFailure(
              'لا يمكن إتمام البيع: الكمية المطلوبة للمنتج "${item.name}" (${totalDemandForProduct.toInt()} حبة) تتجاوز المخزون المتوفر (${item.totalBaseStock.toInt()} حبة).',
            ),
          );
          return;
        }
      }
    }

    final command = CompleteSaleCommand(
      customerId: state.customerId,
      currencyId: state.currencyId,
      isCreditSale: isCredit,
      paymentMethodId: paymentMethodId,
      paidAmount: totalPaid,
      cashAmount: resolvedCash,
      bankAmount: resolvedBank,
      items: items,
      invoiceDiscount: effectiveInvoiceDiscount,
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
          await service.markOrderFulfilled(state.sourceOrderId!, invoiceId: invoiceId);
        }

        // Refresh products catalog in POS to reflect updated inventory stock
        if (getIt.isRegistered<CatalogRepository>()) {
          ref.invalidate(posProductsNotifierProvider);
        }

        // Successful sale commits invoice and inventory.
        // Cart and totals MUST be cleared immediately to prevent duplicate submissions.
        state = PosState(
          cart: const [],
          totals: InvoiceTotals(
            rawSubtotal: 0,
            totalDiscount: 0,
            taxableAmount: 0,
            taxTotal: 0,
            grandTotal: 0,
          ),
          currencyId: state.currencyId,
          isSubmitting: false,
          successInvoiceId: invoiceId,
          invoiceDiscount: 0.0,
          isInvoiceDiscountPercentage: false,
        );
      },
    );
  }
}

