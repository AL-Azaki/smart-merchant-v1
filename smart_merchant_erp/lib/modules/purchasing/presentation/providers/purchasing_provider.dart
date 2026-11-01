import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/purchasing_dao.dart';
import '../../../../database/daos/inventory_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/usecases/record_purchase_usecase.dart';
import '../../../sales/presentation/providers/product_unit_provider.dart';
import '../../../treasury/domain/repositories/treasury_repository.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../../app/di/getit_instance.dart';

class PurchaseItemState {
  final String id;
  final String? productUnitId;
  final String? productId;
  final String barcode;
  final String productName;
  final String categoryId;
  final String unitId;
  final double quantity;
  final double purchasePrice;
  final double sellingPrice;
  final double discount;
  final String expiryDate;

  PurchaseItemState({
    required this.id,
    this.productUnitId,
    this.productId,
    required this.barcode,
    required this.productName,
    required this.categoryId,
    required this.unitId,
    required this.quantity,
    required this.purchasePrice,
    required this.sellingPrice,
    this.discount = 0.0,
    required this.expiryDate,
  });

  PurchaseItemState copyWith({
    String? productUnitId,
    String? productId,
    String? barcode,
    String? productName,
    String? categoryId,
    String? unitId,
    double? quantity,
    double? purchasePrice,
    double? sellingPrice,
    double? discount,
    String? expiryDate,
  }) {
    return PurchaseItemState(
      id: this.id,
      productUnitId: productUnitId ?? this.productUnitId,
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount: discount ?? this.discount,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

class PurchasingState {
  final List<PurchaseItemState> items;
  final String supplierId;
  final String warehouseId;
  final String currencyId;
  final double exchangeRate;
  final String invoiceRef;
  final double invoiceDiscount;

  // Payment State
  final Map<String, String> paymentAmounts;

  // Mutation State
  final bool isSubmitting;
  final String? successInvoiceId;
  final Failure? error;

  PurchasingState({
    required this.items,
    this.supplierId = '',
    this.warehouseId = '',
    this.currencyId = '',
    this.exchangeRate = 1.0,
    this.invoiceRef = '',
    this.invoiceDiscount = 0.0,
    this.paymentAmounts = const {},
    this.isSubmitting = false,
    this.successInvoiceId,
    this.error,
  });

  double get subtotal =>
      items.fold(0.0, (sum, r) => sum + (r.quantity * r.purchasePrice));
  double get itemsDiscount =>
      items.fold(0.0, (sum, r) => sum + r.discount);
  double get totalDiscount => itemsDiscount + invoiceDiscount;
  double get total =>
      (subtotal - totalDiscount).clamp(0.0, double.infinity);

  factory PurchasingState.initial() => PurchasingState(
    items: [
      PurchaseItemState(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: '',
        productName: '',
        categoryId: '',
        unitId: '',
        quantity: 1,
        purchasePrice: 0,
        sellingPrice: 0,
        discount: 0,
        expiryDate: '',
      ),
    ],
    invoiceDiscount: 0.0,
  );

  PurchasingState copyWith({
    List<PurchaseItemState>? items,
    String? supplierId,
    String? warehouseId,
    String? currencyId,
    double? exchangeRate,
    String? invoiceRef,
    double? invoiceDiscount,
    Map<String, String>? paymentAmounts,
    bool? isSubmitting,
    String? successInvoiceId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PurchasingState(
      items: items ?? this.items,
      supplierId: supplierId ?? this.supplierId,
      warehouseId: warehouseId ?? this.warehouseId,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      invoiceRef: invoiceRef ?? this.invoiceRef,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      paymentAmounts: paymentAmounts ?? this.paymentAmounts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successInvoiceId: clearSuccess
          ? null
          : (successInvoiceId ?? this.successInvoiceId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final purchasingNotifierProvider = AutoDisposeNotifierProvider<PurchasingNotifier, PurchasingState>(() => PurchasingNotifier());

class PurchasingNotifier extends AutoDisposeNotifier<PurchasingState> {
  @override
  PurchasingState build() {
    return PurchasingState.initial();
  }

  void updateState(PurchasingState newState) {
    state = newState;
  }

  Future<void> changeCurrency(String currencyId, double fallbackRate) async {
    state = state.copyWith(currencyId: currencyId);
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive) return;

    final currencies = await ref.read(availableCurrenciesFutureProvider.future);
    final baseCurrency = currencies.firstWhere(
      (c) => c.isBaseCurrency,
      orElse: () => currencies.first,
    );

    if (currencyId == baseCurrency.id) {
      state = state.copyWith(exchangeRate: 1.0, error: null, clearError: true);
      return;
    }

    final systemRepo = ref.read(systemRepositoryProvider);
    final latestRate = await systemRepo.getLatestExchangeRate(
      businessId: session.businessId!,
      sourceCurrencyId: currencyId,
      targetCurrencyId: baseCurrency.id,
    );

    if (latestRate != null) {
      state = state.copyWith(
        exchangeRate: latestRate.rate,
        error: null,
        clearError: true,
      );
    } else {
      // If ERP requires exchange rate and none exists
      state = state.copyWith(
        exchangeRate: fallbackRate,
        error: const ValidationFailure(
          'تعذر العثور على سعر صرف صالح لهذه العملة في النظام',
        ),
      );
    }
  }

  void addRow() {
    final currentItems = List<PurchaseItemState>.from(state.items);
    currentItems.add(
      PurchaseItemState(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: '',
        productName: '',
        categoryId: '',
        unitId: '',
        quantity: 1,
        purchasePrice: 0,
        sellingPrice: 0,
        expiryDate: '',
      ),
    );
    state = state.copyWith(items: currentItems);
  }

  void removeRow(String id) {
    if (state.items.length <= 1) return;
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  void updateRow(String id, PurchaseItemState updatedRow) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final newItems = List<PurchaseItemState>.from(state.items);
      newItems[index] = updatedRow;
      state = state.copyWith(items: newItems);
    }
  }

  void updateItemDiscount(String id, double discount) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final newItems = List<PurchaseItemState>.from(state.items);
      newItems[index] = newItems[index].copyWith(discount: discount);
      state = state.copyWith(items: newItems);
    }
  }

  void setInvoiceDiscount(double discount) {
    state = state.copyWith(invoiceDiscount: discount);
  }

  void clearForm() {
    state = PurchasingState.initial();
  }

  Future<bool> submitPurchase() async {
    if (state.isSubmitting ||
        state.items.isEmpty ||
        state.supplierId.isEmpty ||
        state.warehouseId.isEmpty ||
        state.currencyId.isEmpty) {
      return false;
    }

    // Filter out empty rows
    final validItems = state.items
        .where((r) => r.productName.isNotEmpty && r.quantity > 0)
        .toList();
    if (validItems.isEmpty) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final useCase = ref.read(recordPurchaseUseCaseProvider);

      for (var item in validItems) {
        if (item.productUnitId == null) {
          state = state.copyWith(
            isSubmitting: false,
            error: ValidationFailure(
              'المنتج "${item.productName}" غير مسجل بقاعدة البيانات.',
            ),
          );
          return false;
        }
      }

      final itemsCommand = validItems
          .map(
            (e) => PurchaseItemCommand(
              productUnitId: e.productUnitId!,
              quantity: e.quantity,
              unitCost: e.purchasePrice,
              discount: e.discount,
              warehouseId: state.warehouseId,
            ),
          )
          .toList();

      // check payment
      double itemsTotal = 0;
      double itemsDiscountTotal = 0;
      for (final item in validItems) {
        itemsTotal += item.quantity * item.purchasePrice;
        itemsDiscountTotal += item.discount;
      }
      final grandTotal = (itemsTotal - itemsDiscountTotal - state.invoiceDiscount).clamp(0.0, double.infinity);

      final session = ref.read(sessionNotifierProvider);
      final businessId = session.businessId ?? '';
      final treasuryRepo = ref.read(treasuryRepositoryProvider);
      final paymentMethods = await treasuryRepo.listPaymentMethods(businessId, isActive: true);

      double totalPaid = 0;
      double cashPaid = 0;
      double bankPaid = 0;
      String? activePaymentMethodId;

      state.paymentAmounts.forEach((key, value) {
        if (key != 'Other') {
          final amt = double.tryParse(value) ?? 0;
          if (amt > 0) {
            totalPaid += amt;
            activePaymentMethodId = key;
            final matchedPm = paymentMethods
                .where((m) => m.id == key || m.methodCode == key)
                .firstOrNull;
            if (matchedPm != null &&
                (matchedPm.paymentType == 'Bank' ||
                    matchedPm.paymentType == 'Card')) {
              bankPaid += amt;
            } else {
              cashPaid += amt;
            }
          }
        }
      });

      // If user selected a payment method but left amount blank (implying full payment)
      if (totalPaid == 0 && state.paymentAmounts.isNotEmpty) {
        final nonOther = state.paymentAmounts.keys.where((k) => k != 'Other').toList();
        if (nonOther.isNotEmpty) {
          final firstKey = nonOther.first;
          final matchedPm = paymentMethods
              .where((m) => m.id == firstKey || m.methodCode == firstKey)
              .firstOrNull;
          if (matchedPm != null &&
              (matchedPm.paymentType == 'Bank' ||
                  matchedPm.paymentType == 'Card')) {
            bankPaid = grandTotal;
          } else {
            cashPaid = grandTotal;
          }
          totalPaid = grandTotal;
          activePaymentMethodId = firstKey;
        }
      }

      bool isCredit = totalPaid < grandTotal;

      final command = RecordPurchaseCommand(
        supplierId: state.supplierId,
        currencyId: state.currencyId,
        exchangeRate: state.exchangeRate,
        items: itemsCommand,
        supplierInvoiceNumber: state.invoiceRef.isEmpty
            ? null
            : state.invoiceRef,
        dueDate: DateTime.now(),
        isCreditPurchase: isCredit,
        paymentMethodId: activePaymentMethodId,
        paidAmount: totalPaid,
        cashAmount: cashPaid,
        bankAmount: bankPaid,
        invoiceDiscount: state.invoiceDiscount,
      );

      final result = await useCase(command);

      return result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure);
          return false;
        },
        (invoiceId) {
          if (getIt.isRegistered<CatalogRepository>()) {
            ref.invalidate(posProductsNotifierProvider);
          }
          state = state.copyWith(
            isSubmitting: false,
            successInvoiceId: invoiceId,
          );
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: UnexpectedFailure(e.toString()),
      );
      return false;
    }
  }
}

final suppliersNotifierProvider = AutoDisposeStreamNotifierProvider<SuppliersNotifier, List<Supplier>>(() => SuppliersNotifier());

class SuppliersNotifier extends AutoDisposeStreamNotifier<List<Supplier>> {
  @override
  Stream<List<Supplier>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(purchasingRepositoryProvider);

    return repo.watchSuppliers(
      SupplierFilter(businessId: session.businessId!, isActive: true),
    );
  }
}

final purchaseInvoicesNotifierProvider = AutoDisposeStreamNotifierProvider<PurchaseInvoicesNotifier, List<PurchaseInvoice>>(() => PurchaseInvoicesNotifier());

class PurchaseInvoicesNotifier extends AutoDisposeStreamNotifier<List<PurchaseInvoice>> {
  @override
  Stream<List<PurchaseInvoice>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) return const Stream.empty();

    final repo = ref.watch(purchasingRepositoryProvider);

    return repo.watchInvoices(
      PurchaseInvoiceFilter(businessId: session.businessId!),
    );
  }
}

final activeWarehousesStreamProvider = StreamProvider.autoDispose<List<Warehouse>>((ref) => _activeWarehousesStream(ref));

Stream<List<Warehouse>> _activeWarehousesStream(Ref ref)  {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive) return const Stream.empty();

  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.watchWarehouses(
    WarehouseFilter(
      businessId: session.businessId!,
    ),
  );
}

final availableCurrenciesFutureProvider = FutureProvider.autoDispose<List<CurrencyEntity>>((ref) => _availableCurrenciesFuture(ref));

Future<List<CurrencyEntity>> _availableCurrenciesFuture(
  Ref ref,
) async {
  final coreRepo = ref.watch(coreRepositoryProvider);
  return await coreRepo.listCurrencies(isActive: true);
}

final availablePaymentMethodsFutureProvider = FutureProvider.autoDispose<List<PaymentMethod>>((ref) => _availablePaymentMethodsFuture(ref));

Future<List<PaymentMethod>> _availablePaymentMethodsFuture(
  Ref ref,
) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive) return [];
  final repo = ref.watch(treasuryRepositoryProvider);
  return await repo.listPaymentMethods(session.businessId!, isActive: true);
}

final supplierBalanceSummaryProvider =
    FutureProvider.autoDispose.family<SupplierBalanceSummary?, String>((
  ref,
  supplierId,
) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive || session.businessId == null) return null;
  final repo = ref.watch(purchasingRepositoryProvider);
  return await repo.getSupplierBalanceSummary(supplierId, session.businessId!);
});
