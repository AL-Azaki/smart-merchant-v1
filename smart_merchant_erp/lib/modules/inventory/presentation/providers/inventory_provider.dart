import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../../../kernel/error/failures.dart';
import '../../application/usecases/process_warehouse_transfer_usecase.dart';
import '../../application/usecases/process_stock_adjustment_usecase.dart' as smart_merchant_erp_usecase;

part 'inventory_provider.g.dart';

class TransferItemState {
  final String productUnitId;
  final double quantity;

  TransferItemState({required this.productUnitId, required this.quantity});
}

class TransferState {
  final List<TransferItemState> items;
  final String? sourceWarehouseId;
  final String? targetWarehouseId;

  // Mutation State
  final bool isSubmitting;
  final String? successTransferId;
  final Failure? error;

  TransferState({
    required this.items,
    this.sourceWarehouseId,
    this.targetWarehouseId,
    this.isSubmitting = false,
    this.successTransferId,
    this.error,
  });

  factory TransferState.initial() => TransferState(items: []);

  TransferState copyWith({
    List<TransferItemState>? items,
    String? sourceWarehouseId,
    String? targetWarehouseId,
    bool? isSubmitting,
    String? successTransferId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TransferState(
      items: items ?? this.items,
      sourceWarehouseId: sourceWarehouseId ?? this.sourceWarehouseId,
      targetWarehouseId: targetWarehouseId ?? this.targetWarehouseId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successTransferId: clearSuccess
          ? null
          : (successTransferId ?? this.successTransferId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class TransferNotifier extends _$TransferNotifier {
  @override
  TransferState build() {
    return TransferState.initial();
  }

  void addItem({required String productUnitId, required double quantity}) {
    if (state.isSubmitting) return;

    final currentItems = List<TransferItemState>.from(state.items);
    currentItems.add(
      TransferItemState(productUnitId: productUnitId, quantity: quantity),
    );

    state = state.copyWith(
      items: currentItems,
      clearError: true,
      clearSuccess: true,
    );
  }

  void setSourceWarehouse(String warehouseId) {
    if (state.isSubmitting) return;
    state = state.copyWith(sourceWarehouseId: warehouseId);
  }

  void setTargetWarehouse(String warehouseId) {
    if (state.isSubmitting) return;
    state = state.copyWith(targetWarehouseId: warehouseId);
  }

  void clearForm() {
    if (state.isSubmitting) return;
    state = TransferState.initial();
  }

  Future<void> submitTransfer({
    required String referenceNumber,
    String? notes,
  }) async {
    if (state.isSubmitting ||
        state.items.isEmpty ||
        state.sourceWarehouseId == null ||
        state.targetWarehouseId == null) {
      return;
    }

    if (state.sourceWarehouseId == state.targetWarehouseId) {
      state = state.copyWith(
        error: const UnexpectedFailure(
          "Source and target warehouse cannot be the same.",
        ),
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    final useCase = ref.read(processWarehouseTransferUseCaseProvider);

    final itemsCommand = state.items
        .map(
          (e) => WarehouseTransferItemCommand(
            productUnitId: e.productUnitId,
            quantity: e.quantity,
          ),
        )
        .toList();

    final command = ProcessWarehouseTransferCommand(
      sourceWarehouseId: state.sourceWarehouseId!,
      destinationWarehouseId: state.targetWarehouseId!,
      items: itemsCommand,
      notes: notes,
    );

    final result = await useCase(command);

    result.fold(
      (failure) => state = state.copyWith(isSubmitting: false, error: failure),
      (transferId) => state = state.copyWith(
        isSubmitting: false,
        successTransferId: transferId,
      ),
    );
  }
}

class StockAdjustmentState {
  final bool isSubmitting;
  final String? successAdjustmentId;
  final Failure? error;

  StockAdjustmentState({
    this.isSubmitting = false,
    this.successAdjustmentId,
    this.error,
  });

  factory StockAdjustmentState.initial() => StockAdjustmentState();

  StockAdjustmentState copyWith({
    bool? isSubmitting,
    String? successAdjustmentId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StockAdjustmentState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successAdjustmentId: clearSuccess ? null : (successAdjustmentId ?? this.successAdjustmentId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class StockAdjustmentNotifier extends _$StockAdjustmentNotifier {
  @override
  StockAdjustmentState build() {
    return StockAdjustmentState.initial();
  }

  void reset() {
    state = StockAdjustmentState.initial();
  }

  Future<bool> submitAdjustment(Map<String, dynamic> data) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);

    try {
      final useCase = getIt<smart_merchant_erp_usecase.ProcessStockAdjustmentUseCase>();
      
      final lines = (data['lines'] as List).map((l) {
        return smart_merchant_erp_usecase.StockAdjustmentItemCommand(
          productUnitId: l['product_unit_id'] ?? l['product_id'], // Adjust logic as needed
          countedQuantity: (l['physical_qty'] as num).toDouble(),
          expectedQuantity: (l['system_qty'] as num).toDouble(),
          difference: (l['discrepancy'] as num).toDouble(),
        );
      }).toList();

      final command = smart_merchant_erp_usecase.ProcessStockAdjustmentCommand(
        warehouseId: data['warehouse_id'],
        notes: data['notes'],
        items: lines,
      );

      final result = await useCase(command);

      return result.fold(
        (failure) {
          state = state.copyWith(isSubmitting: false, error: failure);
          return false;
        },
        (id) {
          state = state.copyWith(isSubmitting: false, successAdjustmentId: id);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: UnexpectedFailure(e.toString()));
      return false;
    }
  }
}

