import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/providers/purchase_returns_provider.dart';

void main() {
  group('PurchaseReturns Quick Actions - Provider Tests', () {
    test('setAllQuantities populates full invoice items and clearAllQuantities resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(purchaseReturnNotifierProvider.notifier);

      expect(container.read(purchaseReturnNotifierProvider).returnQuantities, isEmpty);

      // Simulate clicking "تنزيل الكل"
      final invoiceQuantities = {
        'prod-unit-1': 10.0,
        'prod-unit-2': 5.0,
        'prod-unit-3': 1.5,
      };

      notifier.setAllQuantities(invoiceQuantities);

      final populatedState = container.read(purchaseReturnNotifierProvider);
      expect(populatedState.returnQuantities.length, 3);
      expect(populatedState.returnQuantities['prod-unit-1'], 10.0);
      expect(populatedState.returnQuantities['prod-unit-2'], 5.0);
      expect(populatedState.returnQuantities['prod-unit-3'], 1.5);

      // Simulate clicking "إلغاء الكل"
      notifier.clearAllQuantities();

      final clearedState = container.read(purchaseReturnNotifierProvider);
      expect(clearedState.returnQuantities, isEmpty);
    });
  });
}

