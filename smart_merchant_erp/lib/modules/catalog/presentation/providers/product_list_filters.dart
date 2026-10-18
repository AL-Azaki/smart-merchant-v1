import '../../domain/models/catalog_product_item.dart';

enum ProductStockFilter { all, available, low, empty }

enum ProductSort { name, priceLow, priceHigh, stockLow }

List<CatalogProductItem> filterCatalogProducts(
  List<CatalogProductItem> products, {
  required String query,
  String? categoryId,
  ProductStockFilter stock = ProductStockFilter.all,
  ProductSort sort = ProductSort.name,
  String Function(String)? unitName,
}) {
  final q = query.trim().toLowerCase();
  final result = products.where((item) {
    if (categoryId != null && item.product.categoryId != categoryId) {
      return false;
    }
    final quantity = item.stockQuantity;
    if (stock == ProductStockFilter.available && quantity <= 5) {
      return false;
    }
    if (stock == ProductStockFilter.low && (quantity <= 0 || quantity > 5)) {
      return false;
    }
    if (stock == ProductStockFilter.empty && quantity > 0) {
      return false;
    }
    return q.isEmpty ||
        item.product.productName.toLowerCase().contains(q) ||
        item.product.productCode.toLowerCase().contains(q) ||
        [item.baseUnit, ...item.units].any(
          (u) =>
              (u.barcode?.toLowerCase().contains(q) ?? false) ||
              (u.sku?.toLowerCase().contains(q) ?? false) ||
              (unitName?.call(u.unitId).toLowerCase().contains(q) ?? false),
        );
  }).toList();
  result.sort((a, b) {
    final compared = switch (sort) {
      ProductSort.name => a.product.productName.compareTo(
        b.product.productName,
      ),
      ProductSort.priceLow => a.sellingPrice.compareTo(b.sellingPrice),
      ProductSort.priceHigh => b.sellingPrice.compareTo(a.sellingPrice),
      ProductSort.stockLow => a.stockQuantity.compareTo(b.stockQuantity),
    };
    return compared != 0 ? compared : a.product.id.compareTo(b.product.id);
  });
  return result;
}
