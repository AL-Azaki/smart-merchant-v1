import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/purchasing_dao.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/usecases/record_purchase_return_usecase.dart';

final purchaseReturnsFutureProvider = FutureProvider.autoDispose.family<List<PurchaseReturn>, String?>((ref, searchQuery) => _purchaseReturnsFuture(ref, searchQuery: searchQuery));

Future<List<PurchaseReturn>> _purchaseReturnsFuture(
  Ref ref, {
  String? searchQuery,
}) async {
  final session = ref.watch(sessionNotifierProvider);
  if (!session.isActive) return [];

  final repo = ref.watch(purchasingRepositoryProvider);
  final filter = PurchaseReturnFilter(businessId: session.businessId!);

  // Note: we can filter by search query if needed in memory or in dao
  return await repo.listReturns(filter);
}

class PurchaseReturnState {
  final String purchaseInvoiceId;
  final String supplierId;
  final String currencyId;
  final double exchangeRate;
  final String notes;
  final Map<String, double> returnQuantities;

  final bool isSubmitting;
  final String? successReturnId;
  final Failure? error;

  PurchaseReturnState({
    this.purchaseInvoiceId = '',
    this.supplierId = '',
    this.currencyId = '',
    this.exchangeRate = 1.0,
    this.notes = 'تالف',
    this.returnQuantities = const {},
    this.isSubmitting = false,
    this.successReturnId,
    this.error,
  });

  factory PurchaseReturnState.initial() => PurchaseReturnState();

  PurchaseReturnState copyWith({
    String? purchaseInvoiceId,
    String? supplierId,
    String? currencyId,
    double? exchangeRate,
    String? notes,
    Map<String, double>? returnQuantities,
    bool? isSubmitting,
    String? successReturnId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PurchaseReturnState(
      purchaseInvoiceId: purchaseInvoiceId ?? this.purchaseInvoiceId,
      supplierId: supplierId ?? this.supplierId,
      currencyId: currencyId ?? this.currencyId,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      notes: notes ?? this.notes,
      returnQuantities: returnQuantities ?? this.returnQuantities,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successReturnId: clearSuccess
          ? null
          : (successReturnId ?? this.successReturnId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final purchaseReturnNotifierProvider = AutoDisposeNotifierProvider<PurchaseReturnNotifier, PurchaseReturnState>(() => PurchaseReturnNotifier());

class PurchaseReturnNotifier extends AutoDisposeNotifier<PurchaseReturnState> {
  @override
  PurchaseReturnState build() {
    return PurchaseReturnState.initial();
  }

  void updateState(PurchaseReturnState newState) {
    state = newState;
  }

  void setInvoice(PurchaseInvoiceWithItems invoiceWithItems) {
    state = state.copyWith(
      purchaseInvoiceId: invoiceWithItems.invoice.id,
      supplierId: invoiceWithItems.invoice.supplierId,
      currencyId: invoiceWithItems.invoice.currencyId,
      exchangeRate: invoiceWithItems.invoice.exchangeRate,
      returnQuantities: {}, // Reset return quantities
    );
  }

  void updateQuantity(String productUnitId, double qty) {
    final newQtys = Map<String, double>.from(state.returnQuantities);
    if (qty <= 0) {
      newQtys.remove(productUnitId);
    } else {
      newQtys[productUnitId] = qty;
    }
    state = state.copyWith(returnQuantities: newQtys);
  }

  void clearForm() {
    state = PurchaseReturnState.initial();
  }

  Future<bool> submitReturn(PurchaseInvoiceWithItems invoiceWithItems) async {
    if (state.isSubmitting ||
        state.purchaseInvoiceId.isEmpty ||
        state.returnQuantities.isEmpty) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final useCase = ref.read(recordPurchaseReturnUseCaseProvider);

      final items = <PurchaseReturnItemCommand>[];
      for (final line in invoiceWithItems.items) {
        final qty = state.returnQuantities[line.productUnitId] ?? 0.0;
        if (qty > 0) {
          items.add(
            PurchaseReturnItemCommand(
              purchaseInvoiceItemId: line.id,
              productUnitId: line.productUnitId,
              warehouseId: line.warehouseId,
              quantity: qty,
              unitPrice: line.unitPrice,
            ),
          );
        }
      }

      if (items.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          error: const ValidationFailure('No items selected for return.'),
        );
        return false;
      }

      final result = await useCase(
        RecordPurchaseReturnCommand(
          purchaseInvoiceId: state.purchaseInvoiceId,
          supplierId: state.supplierId,
          currencyId: state.currencyId,
          exchangeRate: state.exchangeRate,
          items: items,
          notes: state.notes,
        ),
      );

      return result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure);
          return false;
        },
        (returnId) {
          state = state.copyWith(
            isSubmitting: false,
            successReturnId: returnId,
            clearError: true,
          );
          ref.invalidate(purchaseReturnsFutureProvider);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: DatabaseFailure(e.toString()),
      );
      return false;
    }
  }
}
