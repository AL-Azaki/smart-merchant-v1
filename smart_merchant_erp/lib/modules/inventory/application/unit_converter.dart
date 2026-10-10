import '../../../../core/utils/precision_math.dart';

/// UnitConverter handles all unit conversions between packaging units (Boxes, Cartons, Dozens)
/// and the product's atomic base unit (Pieces).
class UnitConverter {
  /// Converts an entered quantity in a specific unit into its equivalent in base units.
  /// Example: 2 cartons with conversion factor 24 = 48 base pieces.
  static double toBaseQuantity({
    required double enteredQuantity,
    required double conversionFactor,
  }) {
    if (conversionFactor <= 0) {
      throw ArgumentError('معامل التحويل للوحدة يجب أن يكون رقماً موجباً أكبر من الصفر');
    }
    return PrecisionMath.roundQuantity(enteredQuantity * conversionFactor);
  }

  /// Converts a base quantity into a packaging unit quantity.
  /// Example: 48 pieces / 24 = 2 cartons.
  static double fromBaseQuantity({
    required double baseQuantity,
    required double conversionFactor,
  }) {
    if (conversionFactor <= 0) {
      throw ArgumentError('معامل التحويل للوحدة يجب أن يكون رقماً موجباً أكبر من الصفر');
    }
    return PrecisionMath.roundQuantity(baseQuantity / conversionFactor);
  }

  /// Converts the cost of a base unit into the cost of the larger packaging unit.
  /// Example: Base piece cost 100 * 24 = 2,400 per carton.
  static double toUnitCost({
    required double baseUnitCost,
    required double conversionFactor,
  }) {
    return PrecisionMath.roundMoney(baseUnitCost * conversionFactor);
  }

  /// Converts the purchase price of a larger packaging unit into the effective cost per base unit.
  /// Example: Carton bought for 2,400 / 24 = 100 per base piece.
  static double toBaseUnitCost({
    required double packageUnitCost,
    required double conversionFactor,
  }) {
    if (conversionFactor <= 0) {
      throw ArgumentError('معامل التحويل للوحدة يجب أن يكون رقماً موجباً أكبر من الصفر');
    }
    return PrecisionMath.roundMoney(packageUnitCost / conversionFactor);
  }
}
