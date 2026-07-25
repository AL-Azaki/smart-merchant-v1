import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/pos_provider.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/app/di/getit_providers.dart';

class MockCompleteSaleUseCase extends Mock implements CompleteSaleUseCase {}

class FakeCompleteSaleCommand extends Fake implements CompleteSaleCommand {}

void main() {
  late MockCompleteSaleUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeCompleteSaleCommand());
  });

  setUp(() {
    mockUseCase = MockCompleteSaleUseCase();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [completeSaleUseCaseProvider.overrideWithValue(mockUseCase)],
    );
  }

  test('Adding products updates cart and totals correctly', () {
    final container = createContainer();
    final notifier = container.read(posNotifierProvider.notifier);

    notifier.addProduct(
      id: 'p1',
      name: 'Product 1',
      price: 100.0,
      taxRate: 0.15,
    );

    var state = container.read(posNotifierProvider);
    expect(state.cart.length, 1);
    expect(state.cart.first.quantity, 1.0);
    // Total should be 100 + 15 = 115
    expect(state.totals.grandTotal, 115.0);

    notifier.addProduct(
      id: 'p1',
      name: 'Product 1',
      price: 100.0,
      taxRate: 0.15,
    );

    state = container.read(posNotifierProvider);
    expect(state.cart.length, 1);
    expect(state.cart.first.quantity, 2.0);
    expect(state.totals.grandTotal, 230.0);
  });

  test(
    'Successful submitSale preserves cart and sets successInvoiceId',
    () async {
      when(
        () => mockUseCase.call(any()),
      ).thenAnswer((_) async => const Right('INV-123'));

      final container = createContainer();
      final notifier = container.read(posNotifierProvider.notifier);

      notifier.addProduct(id: 'p1', name: 'Product 1', price: 100.0);
      notifier.setCustomer('cust1', 'Ahmed');

      await notifier.submitSale(cashReceived: 115.0, paymentMethodId: 'CASH');

      final state = container.read(posNotifierProvider);

      expect(state.isSubmitting, isFalse);
      expect(state.error, isNull);
      expect(state.successInvoiceId, 'INV-123');
      // Cart MUST NOT be cleared automatically
      expect(state.cart.isNotEmpty, isTrue);

      verify(() => mockUseCase.call(any())).called(1);
    },
  );

  test('Failed submitSale preserves cart and sets error', () async {
    const failure = UnexpectedFailure('Not enough stock');
    when(
      () => mockUseCase.call(any()),
    ).thenAnswer((_) async => const Left(failure));

    final container = createContainer();
    final notifier = container.read(posNotifierProvider.notifier);

    notifier.addProduct(id: 'p1', name: 'Product 1', price: 100.0);

    await notifier.submitSale(cashReceived: 115.0, paymentMethodId: 'CASH');

    final state = container.read(posNotifierProvider);

    expect(state.isSubmitting, isFalse);
    expect(state.error, failure);
    expect(state.successInvoiceId, isNull);
    // Cart MUST be preserved
    expect(state.cart.isNotEmpty, isTrue);
  });

  test(
    'Does not submit if already submitting (duplicate protection)',
    () async {
      when(() => mockUseCase.call(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return const Right('INV-123');
      });

      final container = createContainer();
      final notifier = container.read(posNotifierProvider.notifier);

      notifier.addProduct(id: 'p1', name: 'Product 1', price: 100.0);

      // Fire two submissions concurrently
      final future1 = notifier.submitSale(
        cashReceived: 115.0,
        paymentMethodId: 'CASH',
      );
      final future2 = notifier.submitSale(
        cashReceived: 115.0,
        paymentMethodId: 'CASH',
      );

      await Future.wait([future1, future2]);

      verify(() => mockUseCase.call(any())).called(1); // Only called once
    },
  );
}
