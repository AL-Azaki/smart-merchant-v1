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
import '../../../../app/di/getit_providers.dart';

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
    this.paymentAmounts = const {},
    this.isSubmitting = false,
    this.successInvoiceId,
    this.error,
  });

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
        expiryDate: '',
      ),
    ],
  );

  PurchasingState copyWith({
    List<PurchaseItemState>? items,
    String? supplierId,
    String? warehouseId,
    String? currencyId,
    double? exchangeRate,
    String? invoiceRef,
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
              warehouseId: state.warehouseId,
            ),
          )
          .toList();

      // check payment
      double totalPaid = 0;
      String? activePaymentMethodId;
      state.paymentAmounts.forEach((key, value) {
        if (key != 'Other') {
          totalPaid += double.tryParse(value) ?? 0;
          activePaymentMethodId = key;
        }
      });

      double grandTotal = 0;
      for (final item in validItems) {
        grandTotal += item.quantity * item.purchasePrice;
      }

      if (totalPaid > 0 && totalPaid < grandTotal) {
        state = state.copyWith(
          isSubmitting: false,
          error: const ValidationFailure(
            'CAPABILITY GAP: الدفع الجزئي غير مدعوم حالياً',
          ),
        );
        return false;
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
        paymentMethodId: isCredit ? null : activePaymentMethodId,
      );

      final result = await useCase(command);

      return result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure);
          return false;
        },
        (invoiceId) {
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
      branchId: session.branchId,
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
