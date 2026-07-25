import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import 'catalog_dao.dart';

/// Extension methods on [CatalogDao] providing sync-specific queries
/// for the Catalog domain.
extension CatalogSyncQueries on CatalogDao {
  // ── Pending sync queries ─────────────────────────────────

  Future<List<Category>> listPendingSyncCategories() {
    return (select(
      categories,
    )..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<List<Brand>> listPendingSyncBrands() {
    return (select(brands)..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<List<Unit>> listPendingSyncUnits() {
    return (select(units)..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<List<Product>> listPendingSyncProducts() {
    return (select(
      products,
    )..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<List<ProductUnit>> listPendingSyncProductUnits() {
    return (select(
      productUnits,
    )..where((t) => t.syncStatus.equals('pending'))).get();
  }

  Future<List<ProductImage>> listPendingSyncProductImages() {
    return (select(
      productImages,
    )..where((t) => t.syncStatus.equals('pending'))).get();
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
}
