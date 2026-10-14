import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/failures.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/utils/precision_math.dart';

/// DTO representing a resolved product unit with its corresponding base conversion unit.
class ResolvedUnitInfo {
  final ProductUnit unit;
  final ProductUnit baseUnit;
  final double conversionFactor;

  const ResolvedUnitInfo({
    required this.unit,
    required this.baseUnit,
    required this.conversionFactor,
  });

  /// True if this unit is already the base unit.
  bool get isBase => unit.id == baseUnit.id;

  /// Converts an input quantity in this unit to the normalized base unit quantity.
  double toBaseQuantity(double quantity) {
    return PrecisionMath.toBaseQuantity(
      packageQuantity: quantity,
      conversionFactor: conversionFactor,
    );
  }

  /// Converts an input unit cost (in foreign or base currency) into the base unit cost in base currency.
  double toBaseUnitCost({
    required double unitCost,
    required double exchangeRate,
  }) {
    final costInBase = PrecisionMath.toBaseAmount(
      foreignAmount: unitCost,
      exchangeRate: exchangeRate,
      decimals: 4,
    );
    return PrecisionMath.toBaseUnitCost(
      packageUnitCost: costInBase,
      conversionFactor: conversionFactor,
    );
  }
}

/// Domain/Application service that resolves the canonical base unit and conversion ratio for any unit.
class ProductUnitResolver {
  final CatalogRepository _catalogRepository;

  ProductUnitResolver(this._catalogRepository);

  /// Resolves the unit and its canonical base unit for a product unit ID.
  Future<ResolvedUnitInfo> resolve(
    String productUnitId,
    String businessId,
  ) async {
    final unit = await _catalogRepository.getProductUnitById(
      productUnitId,
      businessId,
    );

    if (unit == null) {
      throw ValidationFailure(
        'Product unit not found: $productUnitId',
      );
    }

    final factor = unit.conversionFactor > 0 ? unit.conversionFactor : 1.0;

    if (unit.isBaseUnit) {
      return ResolvedUnitInfo(
        unit: unit,
        baseUnit: unit,
        conversionFactor: factor,
      );
    }

    // Fetch all units for this product to find the canonical base unit
    final allUnits = await _catalogRepository.listProductUnitsByProductId(
      unit.productId,
      businessId,
    );

    final baseUnit = allUnits.firstWhere(
      (u) => u.isBaseUnit,
      orElse: () => unit,
    );

    return ResolvedUnitInfo(
      unit: unit,
      baseUnit: baseUnit,
      conversionFactor: factor,
    );
  }
}
