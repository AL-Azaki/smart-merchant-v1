import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/core/utils/precision_math.dart';

void main() {
  group('PrecisionMath Utility Tests', () {
    test('roundMoney properly rounds 2 decimal places and handles float drift', () {
      expect(PrecisionMath.roundMoney(10.556), 10.56);
      expect(PrecisionMath.roundMoney(10.554), 10.55);
      expect(PrecisionMath.roundMoney(0.1 + 0.2), 0.3);
      expect(PrecisionMath.roundMoney(100.0), 100.0);
    });

    test('roundQty properly rounds 3 decimal places', () {
      expect(PrecisionMath.roundQty(1.2345), 1.235);
      expect(PrecisionMath.roundQty(1.2344), 1.234);
    });

    test('areBalanced handles minor floating-point tolerances', () {
      expect(PrecisionMath.areBalanced(100.0, 100.0), isTrue);
      expect(PrecisionMath.areBalanced(100.0001, 100.0002), isTrue);
      expect(PrecisionMath.areBalanced(100.0, 100.05), isFalse);
    });

    test('calculateWac computes accurate weighted average cost', () {
      // 10 units at 100 YER + 10 units at 530 YER (1 USD at 530 exchange rate)
      // Total value: (10 * 100) + (10 * 530) = 1000 + 5300 = 6300 YER.
      // Total qty: 20 -> New WAC = 315 YER
      final wac = PrecisionMath.calculateWac(
        oldQty: 10.0,
        oldAvgCost: 100.0,
        newQty: 10.0,
        newUnitCostInBase: 530.0,
      );
      expect(wac, 315.0);
    });

    test('calculateWac handles zero initial stock gracefully', () {
      final wac = PrecisionMath.calculateWac(
        oldQty: 0.0,
        oldAvgCost: 0.0,
        newQty: 5.0,
        newUnitCostInBase: 250.0,
      );
      expect(wac, 250.0);
    });

    test('calculateWac prevents division by zero if total qty is 0', () {
      final wac = PrecisionMath.calculateWac(
        oldQty: 0.0,
        oldAvgCost: 150.0,
        newQty: 0.0,
        newUnitCostInBase: 200.0,
      );
      expect(wac, 150.0);
    });

    test('currency and unit conversion functions work accurately', () {
      // 10 USD at 530 exchange rate
      expect(PrecisionMath.toBaseAmount(foreignAmount: 10.0, exchangeRate: 530.0), 5300.0);

      // 5300 YER to USD at 530 exchange rate
      expect(PrecisionMath.toForeignAmount(baseAmount: 5300.0, exchangeRate: 530.0), 10.0);

      // 2 cartons of 24 pieces
      expect(PrecisionMath.toBaseQuantity(packageQuantity: 2.0, conversionFactor: 24.0), 48.0);

      // 2400 YER per carton of 24 pieces -> 100 YER per piece
      expect(PrecisionMath.toBaseUnitCost(packageUnitCost: 2400.0, conversionFactor: 24.0), 100.0);
    });
  });
}
