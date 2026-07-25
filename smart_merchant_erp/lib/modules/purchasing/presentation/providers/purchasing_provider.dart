import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/error/failures.dart';
import '../../application/usecases/record_purchase_usecase.dart';

part 'purchasing_provider.g.dart';

class PurchaseItemState {
  final String productUnitId;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  PurchaseItemState({
    required this.productUnitId,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0.0,
  });
}

class PurchasingState {
  final List<PurchaseItemState> items;
  final String? supplierId;
  final String? warehouseId;

  // Mutation State
  final bool isSubmitting;
  final String? successInvoiceId;
  final Failure? error;

  PurchasingState({
    required this.items,
    this.supplierId,
    this.warehouseId,
    this.isSubmitting = false,
    this.successInvoiceId,
    this.error,
  });

  factory PurchasingState.initial() => PurchasingState(items: []);

  PurchasingState copyWith({
    List<PurchaseItemState>? items,
    String? supplierId,
    String? warehouseId,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successInvoiceId: clearSuccess
          ? null
          : (successInvoiceId ?? this.successInvoiceId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class PurchasingNotifier extends _$PurchasingNotifier {
  @override
  PurchasingState build() {
    return PurchasingState.initial();
  }

  void addItem({
    required String productUnitId,
    required double quantity,
    required double unitPrice,
  }) {
    if (state.isSubmitting) return;

    final currentItems = List<PurchaseItemState>.from(state.items);
    currentItems.add(
      PurchaseItemState(
        productUnitId: productUnitId,
        quantity: quantity,
        unitPrice: unitPrice,
      ),
    );

    state = state.copyWith(
      items: currentItems,
      clearError: true,
      clearSuccess: true,
    );
  }

  void setSupplier(String supplierId) {
    if (state.isSubmitting) return;
    state = state.copyWith(supplierId: supplierId);
  }

  void setWarehouse(String warehouseId) {
    if (state.isSubmitting) return;
    state = state.copyWith(warehouseId: warehouseId);
  }

  void clearForm() {
    if (state.isSubmitting) return;
    state = PurchasingState.initial();
  }

  Future<bool> submitPurchase({
    required String referenceNumber,
    required DateTime issueDate,
  }) async {
    if (state.isSubmitting ||
        state.items.isEmpty ||
        state.supplierId == null ||
        state.warehouseId == null) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final useCase = ref.read(recordPurchaseUseCaseProvider);

      final itemsCommand = state.items
          .map(
            (e) => PurchaseItemCommand(
              productUnitId: e.productUnitId,
              quantity: e.quantity,
              unitCost: e.unitPrice,
              warehouseId: state.warehouseId!,
            ),
          )
          .toList();

      final command = RecordPurchaseCommand(
        supplierId: state.supplierId!,
        currencyId: 'USD', // Needs to come from somewhere, hardcoding for now as it wasn't there before
        items: itemsCommand,
        supplierInvoiceNumber: referenceNumber,
        dueDate: issueDate,
      );

      final result = await useCase(command);

      return result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure);
          return false;
        },
        (invoiceId) {
          state = state.copyWith(isSubmitting: false, successInvoiceId: invoiceId);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: UnexpectedFailure(e.toString()));
      return false;
    }
  }
}
