import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import 'catalog_dao.dart';

/// Extension methods on [CatalogDao] providing sync-specific queries
/// for the Catalog domain.
extension CatalogSyncQueries on CatalogDao {
  // ── Pending sync queries ─────────────────────────────────

  Future<List<Category>> listPendingSyncCategories([String? businessId]) {
    final query = select(categories)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    return query.get();
  }

  Future<List<Brand>> listPendingSyncBrands([String? businessId]) {
    final query = select(brands)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    return query.get();
  }

  Future<List<Unit>> listPendingSyncUnits([String? businessId]) {
    final query = select(units)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    return query.get();
  }

  Future<List<Product>> listPendingSyncProducts([String? businessId]) {
    final query = select(products)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    return query.get();
  }

  Future<List<ProductUnit>> listPendingSyncProductUnits([String? businessId]) {
    final query = select(productUnits)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      query.where((t) => t.businessId.equals(businessId));
    }
    return query.get();
  }

  Future<List<ProductImage>> listPendingSyncProductImages([String? businessId]) {
    final query = select(productImages)..where((t) => t.syncStatus.isNotValue('synced'));
    if (businessId != null) {
      final productSubquery = selectOnly(products)
        ..addColumns([products.id])
        ..where(products.businessId.equals(businessId));
      query.where((t) => t.productId.isInQuery(productSubquery));
    }
    return query.get();
  }

  // ── Mark synced ──────────────────────────────────────────

  Future<void> markCategorySynced(String id) {
    return (update(categories)..where((t) => t.id.equals(id))).write(
      const CategoriesCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markBrandSynced(String id) {
    return (update(brands)..where((t) => t.id.equals(id))).write(
      const BrandsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markUnitSynced(String id) {
    return (update(units)..where((t) => t.id.equals(id))).write(
      const UnitsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markProductSynced(String id) {
    return (update(products)..where((t) => t.id.equals(id))).write(
      const ProductsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markProductUnitSynced(String id) {
    return (update(productUnits)..where((t) => t.id.equals(id))).write(
      const ProductUnitsCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> markProductImageSynced(String id) {
    return (update(productImages)..where((t) => t.id.equals(id))).write(
      const ProductImagesCompanion(syncStatus: Value('synced')),
    );
  }

  Future<void> updateProductImagePath(String id, String imagePath) {
    return (update(productImages)..where((t) => t.id.equals(id))).write(
      ProductImagesCompanion(imagePath: Value(imagePath)),
    );
  }
}
