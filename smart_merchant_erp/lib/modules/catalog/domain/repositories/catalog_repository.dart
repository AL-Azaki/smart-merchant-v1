import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/catalog_dao.dart';

/// Contract for Catalog domain data operations.
/// Isolates application use cases from Drift ORM and SQLite specifics while
/// preserving multi-tenant (`businessId`), branch override (`branchId`), offline-sync, and reactive stream semantics.
abstract class CatalogRepository {
  // Categories
  Future<Category?> getCategoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Category?> getCategoryByCode(
    String businessId,
    String categoryCode, {
    bool includeDeleted = false,
  });
  Future<List<Category>> listCategories(CategoryFilter filter);
  Stream<List<Category>> watchCategories(
    String businessId, {
    String? parentId,
    bool? isActive,
    bool includeDeleted = false,
  });
  Future<int> insertCategory(CategoriesCompanion category);
  Future<bool> updateCategory(CategoriesCompanion category);
  Future<int> softDeleteCategory(String id, String businessId);
  Future<int> restoreCategory(String id, String businessId);
  Future<List<Category>> listArchivedCategories(String businessId);
  Future<List<Category>> getPendingSyncCategories(
    String businessId, {
    int limit = 500,
  });
  Future<int> markCategoriesAsSynced(List<String> ids, String businessId);

  // Brands
  Future<Brand?> getBrandById(String id, String businessId);
  Future<List<Brand>> listBrands(String businessId, {bool? isActive});
  Stream<List<Brand>> watchBrands(String businessId, {bool? isActive});
  Future<int> insertBrand(BrandsCompanion brand);
  Future<bool> updateBrand(BrandsCompanion brand);
  Future<int> deleteBrand(String id, String businessId);
  Future<List<Brand>> getPendingSyncBrands(
    String businessId, {
    int limit = 500,
  });
  Future<int> markBrandsAsSynced(List<String> ids, String businessId);

  // Units
  Future<Unit?> getUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<List<Unit>> listUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  });
  Stream<List<Unit>> watchUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  });
  Future<int> insertUnit(UnitsCompanion unit);
  Future<bool> updateUnit(UnitsCompanion unit);
  Future<int> softDeleteUnit(String id, String businessId);
  Future<int> restoreUnit(String id, String businessId);
  Future<List<Unit>> getPendingSyncUnits(String businessId, {int limit = 500});
  Future<int> markUnitsAsSynced(List<String> ids, String businessId);

  // Taxes
  Future<Tax?> getTaxById(String id, String businessId);
  Future<Tax?> getTaxByCode(String businessId, String taxCode);
  Future<List<Tax>> listTaxes(String businessId, {bool? isActive});
  Stream<List<Tax>> watchTaxes(String businessId, {bool? isActive});
  Future<int> insertTax(TaxesCompanion tax);
  Future<bool> updateTax(TaxesCompanion tax);
  Future<int> deleteTax(String id, String businessId);
  Future<List<Tax>> getPendingSyncTaxes(String businessId, {int limit = 500});
  Future<int> markTaxesAsSynced(List<String> ids, String businessId);

  // Products
  Future<Product?> getProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<Product?> getProductByCode(
    String businessId,
    String productCode, {
    bool includeDeleted = false,
  });
  Future<List<Product>> listProducts(ProductFilter filter);
  Stream<Product?> watchProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Stream<List<Product>> watchProducts(ProductFilter filter);
  Future<int> insertProduct(ProductsCompanion product);
  Future<bool> updateProduct(ProductsCompanion product);
  Future<int> softDeleteProduct(String id, String businessId);
  Future<int> restoreProduct(String id, String businessId);
  Future<List<Product>> listArchivedProducts(String businessId);
  Future<List<Product>> getPendingSyncProducts(
    String businessId, {
    int limit = 500,
  });
  Future<int> markProductsAsSynced(List<String> ids, String businessId);

  // Product Units
  Future<ProductUnit?> getProductUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<ProductUnit?> getProductUnitByBarcode(
    String businessId,
    String barcode, {
    bool includeDeleted = false,
  });
  Future<ProductUnit?> getProductUnitBySku(
    String businessId,
    String sku, {
    bool includeDeleted = false,
  });
  Future<List<ProductUnit>> listProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  });
  Stream<List<ProductUnit>> watchProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  });
  Future<int> insertProductUnit(ProductUnitsCompanion unit);
  Future<bool> updateProductUnit(ProductUnitsCompanion unit);
  Future<int> softDeleteProductUnit(String id, String businessId);
  Future<int> restoreProductUnit(String id, String businessId);
  Future<List<ProductUnit>> getPendingSyncProductUnits(
    String businessId, {
    int limit = 500,
  });
  Future<int> markProductUnitsAsSynced(List<String> ids, String businessId);

  // Product Variants
  Future<ProductVariant?> getProductVariantById(String id, String businessId);
  Future<List<ProductVariant>> listVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  );
  Stream<List<ProductVariant>> watchVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  );
  Future<int> insertProductVariant(ProductVariantsCompanion variant);
  Future<bool> updateProductVariant(ProductVariantsCompanion variant);
  Future<int> deleteProductVariant(String id, String businessId);
  Future<List<ProductVariant>> getPendingSyncProductVariants(
    String businessId, {
    int limit = 500,
  });
  Future<int> markProductVariantsAsSynced(List<String> ids, String businessId);

  // Product Images
  Future<List<ProductImage>> getProductImagesByProductId(String productId);
  Stream<List<ProductImage>> watchProductImagesByProductId(String productId);
  Future<int> insertProductImage(ProductImagesCompanion image);
  Future<bool> updateProductImage(ProductImagesCompanion image);
  Future<int> deleteProductImage(String id);
  Future<List<ProductImage>> getPendingSyncProductImages({int limit = 500});
  Future<int> markProductImagesAsSynced(List<String> ids);

  // Product Taxes Pivot
  Future<List<ProductTax>> listProductTaxesByProductUnitId(
    String productUnitId,
    String businessId,
  );
  Future<List<ProductTax>> listProductTaxesByTaxId(
    String taxId,
    String businessId,
  );
  Future<int> insertProductTax(ProductTaxesCompanion productTax);
  Future<int> deleteProductTax(
    String productUnitId,
    String taxId,
    String businessId,
  );
  Future<List<ProductTax>> getPendingSyncProductTaxes(
    String businessId, {
    int limit = 500,
  });
  Future<int> markProductTaxesAsSynced(
    List<ProductTax> entries,
    String businessId,
  );

  // Branch Product Prices / Effective Pricing
  Future<BranchProductPrice?> getBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  );
  Future<EffectiveUnitPrice?> getEffectiveProductUnitPrice(
    String productUnitId,
    String businessId, {
    String? branchId,
  });
  Future<List<BranchProductPrice>> listBranchPricesByBranchId(
    String branchId,
    String businessId,
  );
  Stream<List<BranchProductPrice>> watchBranchPricesByBranchId(
    String branchId,
    String businessId,
  );
  Future<int> insertBranchProductPrice(BranchProductPricesCompanion price);
  Future<bool> updateBranchProductPrice(BranchProductPricesCompanion price);
  Future<int> deleteBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  );
  Future<List<BranchProductPrice>> getPendingSyncBranchProductPrices(
    String businessId, {
    int limit = 500,
  });
  Future<int> markBranchProductPricesAsSynced(
    List<String> ids,
    String businessId,
  );

  // Transactional Creation
  Future<void> createProductWithDetails({
    required ProductsCompanion product,
    required List<ProductUnitsCompanion> units,
    List<ProductVariantsCompanion> variants = const [],
    List<ProductImagesCompanion> images = const [],
    List<ProductTaxesCompanion> taxes = const [],
  });
}
