import '../../../../core/utils/precision_math.dart';
import '../../../../kernel/storage/app_database.dart';

class UnitQuantityBreakdown {
  final int fullUnits;
  final double remainderBase;
  final double exactDecimal;

  const UnitQuantityBreakdown({
    required this.fullUnits,
    required this.remainderBase,
    required this.exactDecimal,
  });
}

/// Domain utility for formatting hierarchical unit breakdowns and stock conversions.
class UnitQuantityFormatter {
  /// Breaks down a base unit quantity into a human-readable hierarchical breakdown.
  /// Example: 57 base pieces with Carton (conversionFactor = 12) -> "4 كرتون و 9 حبة"
  static String formatBreakdown({
    required double baseQuantity,
    required List<ProductUnit> units,
    required String Function(String unitId) unitNameResolver,
    bool includeTotalReference = false,
  }) {
    if (units.isEmpty) {
      return '${_formatQty(baseQuantity)}';
    }

    // Find base unit
    final baseUnit = units.where((u) => u.isBaseUnit).firstOrNull ??
        units.reduce((a, b) => a.conversionFactor <= b.conversionFactor ? a : b);
    final baseUnitName = unitNameResolver(baseUnit.unitId);

    if (baseQuantity <= 0) {
      return '0 $baseUnitName';
    }

    // Sort higher packaging units descending by conversionFactor
    final higherUnits = units
        .where((u) => !u.isBaseUnit && u.conversionFactor > 1.0 && u.isActive)
        .toList()
      ..sort((a, b) => b.conversionFactor.compareTo(a.conversionFactor));

    if (higherUnits.isEmpty) {
      return '${_formatQty(baseQuantity)} $baseUnitName';
    }

    double remaining = baseQuantity;
    final parts = <String>[];

    for (final unit in higherUnits) {
      final factor = unit.conversionFactor;
      if (factor <= 0) continue;

      final count = (remaining / factor).floor();
      if (count > 0) {
        final name = unitNameResolver(unit.unitId);
        parts.add('$count $name');
        remaining -= count * factor;
      }
    }

    if (remaining > 0 || parts.isEmpty) {
      parts.add('${_formatQty(remaining)} $baseUnitName');
    }

    final breakdownStr = parts.join(' و ');
    if (includeTotalReference && higherUnits.isNotEmpty) {
      return '$breakdownStr (إجمالي ${_formatQty(baseQuantity)} $baseUnitName)';
    }

    return breakdownStr;
  }

  /// Calculates available quantity in terms of a specific target unit.
  static UnitQuantityBreakdown quantityInUnit({
    required double baseQuantity,
    required ProductUnit targetUnit,
  }) {
    final factor = targetUnit.conversionFactor > 0 ? targetUnit.conversionFactor : 1.0;
    final fullUnits = (baseQuantity / factor).floor();
    final remainderBase = baseQuantity - (fullUnits * factor);
    final exactDecimal = baseQuantity / factor;

    return UnitQuantityBreakdown(
      fullUnits: fullUnits < 0 ? 0 : fullUnits,
      remainderBase: remainderBase < 0 ? 0 : remainderBase,
      exactDecimal: exactDecimal < 0 ? 0 : exactDecimal,
    );
  }

  /// Calculates the weighted average cost for a specific packaging unit.
  static double unitAverageCost({
    required double baseAverageCost,
    required ProductUnit targetUnit,
  }) {
    final factor = targetUnit.conversionFactor > 0 ? targetUnit.conversionFactor : 1.0;
    return PrecisionMath.roundMoney(baseAverageCost * factor);
  }

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
}
