import 'dart:math' as math;

/// Utility class for financial precision, rounding, and invariant checking.
/// Prevents floating-point drift (e.g., 0.1 + 0.2 != 0.3) across all ERP domains.
class PrecisionMath {
  PrecisionMath._();

  /// Standard currency rounding (default: 2 decimals, supports custom precision).
  static double roundMoney(double value, [int decimals = 2]) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final mod = math.pow(10, decimals).toDouble();
    return ((value * mod).roundToDouble()) / mod;
  }

  /// Stock quantity rounding (default: 3 decimals for weights/volumes).
  static double roundQty(double value, [int decimals = 3]) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final mod = math.pow(10, decimals).toDouble();
    return ((value * mod).roundToDouble()) / mod;
  }

  /// Tolerance-based check for double-entry ledger balance.
  static bool areBalanced(
    double debit,
    double credit, [
    double tolerance = 0.001,
  ]) {
    return (debit - credit).abs() <= tolerance;
  }

  /// Safe Weighted Average Cost (WAC) calculator in Base Currency.
  /// Handles initial stock (oldQty <= 0) and prevents division by zero.
  static double calculateWac({
    required double oldQty,
    required double oldAvgCost,
    required double newQty,
    required double newUnitCostInBase,
  }) {
    final validOldQty = oldQty > 0 ? oldQty : 0.0;
    final validOldCost = oldAvgCost >= 0 ? oldAvgCost : 0.0;
    final validNewQty = newQty > 0 ? newQty : 0.0;
    final validNewCost = newUnitCostInBase >= 0 ? newUnitCostInBase : 0.0;

    final totalQty = validOldQty + validNewQty;
    if (totalQty <= 0) {
      return roundMoney(validOldCost);
    }

    final totalValue = (validOldQty * validOldCost) + (validNewQty * validNewCost);
    return roundMoney(totalValue / totalQty, 4);
  }

  /// Converts a foreign currency amount to base currency with rounding.
  static double toBaseAmount({
    required double foreignAmount,
    required double exchangeRate,
    int decimals = 2,
  }) {
    final rate = exchangeRate > 0 ? exchangeRate : 1.0;
    return roundMoney(foreignAmount * rate, decimals);
  }

  /// Converts a base currency amount to foreign currency with rounding.
  static double toForeignAmount({
    required double baseAmount,
    required double exchangeRate,
    int decimals = 2,
  }) {
    final rate = exchangeRate > 0 ? exchangeRate : 1.0;
    return roundMoney(baseAmount / rate, decimals);
  }

  /// Converts package/carton quantity to base unit quantity.
  static double toBaseQuantity({
    required double packageQuantity,
    required double conversionFactor,
  }) {
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;
    return roundQty(packageQuantity * factor);
  }

  /// Converts unit cost of a package/carton to unit cost of a base item.
  static double toBaseUnitCost({
    required double packageUnitCost,
    required double conversionFactor,
    int decimals = 4,
  }) {
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;
    return roundMoney(packageUnitCost / factor, decimals);
  }
}
