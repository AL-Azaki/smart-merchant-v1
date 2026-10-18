import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../catalog/domain/models/catalog_product_item.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

part 'product_unit_provider.g.dart';

// Compatibility for existing point-of-sale consumers.
typedef PosProductItem = CatalogProductItem;

@riverpod
class PosProductsNotifier extends _$PosProductsNotifier {
  @override
  Stream<List<PosProductItem>> build() {
    final session = ref.watch(sessionNotifierProvider);
    if (!session.isActive) {
      return Stream.value(const []);
    }
    return ref
        .watch(catalogRepositoryProvider)
        .watchProductCatalog(session.businessId!)
        .map((entries) => entries.map(_catalogItem).toList());
  }
}

CatalogProductItem _catalogItem(ProductCatalogEntry entry) {
  final product = entry.product;
  final base = entry.units.firstWhere(
    (u) => u.isBaseUnit,
    orElse: () => entry.units.isNotEmpty
        ? entry.units.first
        : ProductUnit(
            id: 'unit_${product.id}',
            businessId: product.businessId,
            productId: product.id,
            unitId: 'unit_piece',
            conversionFactor: 1,
            purchasePrice: 0,
            sellingPrice: 0,
            minimumPrice: 0,
            isBaseUnit: true,
            isActive: true,
            syncStatus: 'synced',
            version: 1,
          ),
  );
  return CatalogProductItem(
    product: product,
    baseUnit: base,
    sellingPrice: base.sellingPrice,
    units: entry.units.isEmpty ? [base] : entry.units,
    stockQuantity: entry.quantitiesByUnit[base.id] ?? 0,
  );
}
