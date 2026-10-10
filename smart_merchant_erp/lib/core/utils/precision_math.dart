import 'dart:math' as math;

/// PrecisionMath handles currency and quantity rounding to prevent IEEE 754 floating-point drift.
/// 
/// Dart uses double-precision floats where `0.1 + 0.2 = 0.30000000000000004`.
/// This utility ensures every financial calculation rounds to a fixed decimal precision
/// before being stored in the database or passed to accounting journal entries.
class PrecisionMath {
  /// Rounds a monetary value to a specific number of decimal places (default is 2).
  static double roundMoney(double value, {int decimals = 2}) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// Rounds an inventory quantity to a specific number of decimal places (default is 3).
  static double roundQuantity(double value, {int decimals = 3}) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// Verifies whether debit and credit amounts are strictly balanced
  /// within an acceptable threshold of half a cent/fils (0.005).
  static bool areBalanced(double debit, double credit, {double threshold = 0.005}) {
    return (debit - credit).abs() < threshold;
  }

  /// Multiplies quantity by unit price and rounds to currency decimals.
  static double lineGross(double quantity, double unitPrice, {int decimals = 2}) {
    return roundMoney(quantity * unitPrice, decimals: decimals);
  }

  /// Distributes a global discount proportionally across lines based on line gross amounts.
  /// 
  /// Returns a list of distributed discount amounts for each line, ensuring
  /// the sum of line discounts exactly equals the global discount without penny loss.
  static List<double> distributeProportionally({
    required List<double> lineAmounts,
    required double totalToDistribute,
    int decimals = 2,
  }) {
    if (lineAmounts.isEmpty || totalToDistribute <= 0) {
      return List.filled(lineAmounts.length, 0.0);
    }

    final totalAmount = lineAmounts.fold(0.0, (sum, val) => sum + val);
    if (totalAmount <= 0) {
      return List.filled(lineAmounts.length, 0.0);
    }

    final distributed = <double>[];
    double accumulated = 0.0;

    for (var i = 0; i < lineAmounts.length; i++) {
      if (i == lineAmounts.length - 1) {
        // Last line absorbs any rounding remainder
        final remainder = roundMoney(totalToDistribute - accumulated, decimals: decimals);
        distributed.add(remainder > 0 ? remainder : 0.0);
      } else {
        final share = roundMoney((lineAmounts[i] / totalAmount) * totalToDistribute, decimals: decimals);
        distributed.add(share);
        accumulated += share;
      }
    }

    return distributed;
  }
}
