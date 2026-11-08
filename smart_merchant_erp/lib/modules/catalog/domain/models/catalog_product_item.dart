import '../../../../kernel/storage/app_database.dart';

/// The shared catalogue data used by product management, inventory, and point of sale.
class CatalogProductItem {
  final Product product;
  final ProductUnit baseUnit;
  final double sellingPrice;
  final List<ProductUnit> units;
  final double stockQuantity;
  final double baseAverageCost;
  final double alertQuantity;

  const CatalogProductItem({
    required this.product,
    required this.baseUnit,
    required this.sellingPrice,
    this.units = const [],
    this.stockQuantity = 0,
    this.baseAverageCost = 0.0,
    this.alertQuantity = 0.0,
  });

  /// Finds the matching unit by exact barcode or SKU across all assigned product units.
  ProductUnit? findUnitByBarcodeOrSku(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return null;

    // Check barcode first
    for (final u in units) {
      if (u.barcode != null && u.barcode!.trim() == clean) {
        return u;
      }
    }

    // Check SKU
    for (final u in units) {
      if (u.sku != null && u.sku!.trim() == clean) {
        return u;
      }
    }

    // Check base unit as fallback
    if (baseUnit.barcode != null && baseUnit.barcode!.trim() == clean) {
      return baseUnit;
    }
    if (baseUnit.sku != null && baseUnit.sku!.trim() == clean) {
      return baseUnit;
    }

    return null;
  }

  /// Returns the maximum available quantity expressed in the given unit.
  double availableInUnit(ProductUnit unit) {
    final factor = unit.conversionFactor > 0 ? unit.conversionFactor : 1.0;
    if (unit.isBaseUnit || factor == 1.0) {
      return stockQuantity;
    }
    return (stockQuantity / factor).floorToDouble();
  }
}