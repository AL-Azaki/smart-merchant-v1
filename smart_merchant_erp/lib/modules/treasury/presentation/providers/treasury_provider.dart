import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/error/failures.dart';
import '../../application/usecases/receive_payment_usecase.dart';

part 'treasury_provider.g.dart';

class PaymentState {
  final String? customerId;
  final String? bankAccountId;
  final String? cashRegisterId;
  final String paymentMethodId;
  final double amount;

  // Target invoices this payment allocates against
  final Map<String, double> allocations; // Invoice ID -> Amount allocated

  // Mutation State
  final bool isSubmitting;
  final String? successPaymentId;
  final Failure? error;

  PaymentState({
    this.customerId,
    this.bankAccountId,
    this.cashRegisterId,
    required this.paymentMethodId,
    required this.amount,
    required this.allocations,
    this.isSubmitting = false,
    this.successPaymentId,
    this.error,
  });

  factory PaymentState.initial() => PaymentState(
    paymentMethodId: 'CASH', // Default
    amount: 0.0,
    allocations: {},
  );

  PaymentState copyWith({
    String? customerId,
    String? bankAccountId,
    String? cashRegisterId,
    String? paymentMethodId,
    double? amount,
    Map<String, double>? allocations,
    bool? isSubmitting,
    String? successPaymentId,
    Failure? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PaymentState(
      customerId: customerId ?? this.customerId,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      cashRegisterId: cashRegisterId ?? this.cashRegisterId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      allocations: allocations ?? this.allocations,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successPaymentId: clearSuccess
          ? null
          : (successPaymentId ?? this.successPaymentId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() {
    return PaymentState.initial();
  }

  void setCustomer(String customerId) {
    if (state.isSubmitting) return;
    state = state.copyWith(customerId: customerId);
  }

  void setPaymentMethod(String methodId) {
    if (state.isSubmitting) return;
    state = state.copyWith(paymentMethodId: methodId);
  }

  void setAmount(double amount) {
    if (state.isSubmitting) return;
    state = state.copyWith(amount: amount);
  }

  void addAllocation(String invoiceId, double amount) {
    if (state.isSubmitting) return;
    final current = Map<String, double>.from(state.allocations);
    current[invoiceId] = amount;
    state = state.copyWith(allocations: current);
  }

  void setBankAccount(String bankAccountId) {
    if (state.isSubmitting) return;
    state = state.copyWith(bankAccountId: bankAccountId, cashRegisterId: null);
  }

  void setCashRegister(String cashRegisterId) {
    if (state.isSubmitting) return;
    state = state.copyWith(cashRegisterId: cashRegisterId, bankAccountId: null);
  }

  void clearForm() {
    if (state.isSubmitting) return;
    state = PaymentState.initial();
  }

  Future<void> submitPayment({
    required String referenceNumber,
    required String currencyId,
  }) async {
    if (state.isSubmitting || state.customerId == null || state.amount <= 0) {
      return;
    }

    if (state.bankAccountId == null && state.cashRegisterId == null) {
      state = state.copyWith(
        error: const UnexpectedFailure(
          "Must select either a Bank Account or Cash Register for the destination.",
        ),
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    final useCase = ref.read(receivePaymentUseCaseProvider);

    final allocationsCommand = state.allocations.entries
        .map(
          (e) => PaymentAllocationCommand(
            receivableId: e.key,
            allocatedAmount: e.value,
          ),
        )
        .toList();

    final chartOfAccountId = state.bankAccountId ?? state.cashRegisterId ?? '';

    final command = ReceivePaymentCommand(
      customerId: state.customerId!,
      amount: state.amount,
      currencyId: currencyId,
      exchangeRate: 1.0,
      paymentMethodId: state.paymentMethodId,
      chartOfAccountId: chartOfAccountId,
      notes: referenceNumber,
      allocations: allocationsCommand,
    );

    final result = await useCase(command);

    result.fold(
      (failure) => state = state.copyWith(isSubmitting: false, error: failure),
      (paymentId) => state = state.copyWith(
        isSubmitting: false,
        successPaymentId: paymentId,
      ),
    );
  }
}
