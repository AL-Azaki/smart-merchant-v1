import '../../../../kernel/storage/app_database.dart';

/// The shared catalogue data used by product management and point of sale.
class CatalogProductItem {
  final Product product;
  final ProductUnit baseUnit;
  final double sellingPrice;
  final List<ProductUnit> units;
  final double stockQuantity;

  const CatalogProductItem({
    required this.product,
    required this.baseUnit,
    required this.sellingPrice,
    this.units = const [],
    this.stockQuantity = 0,
  });
}
