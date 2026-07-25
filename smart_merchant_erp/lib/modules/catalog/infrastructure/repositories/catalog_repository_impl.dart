import 'package:injectable/injectable.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/catalog_dao.dart';

@LazySingleton(as: CatalogRepository)
class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogDao _dao;

  CatalogRepositoryImpl(this._dao);

  // Categories
  @override
  Future<Category?> getCategoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () =>
          _dao.getCategoryById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Category?> getCategoryByCode(
    String businessId,
    String categoryCode, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getCategoryByCode(
        businessId,
        categoryCode,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<Category>> listCategories(CategoryFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listCategories(filter));
  }

  @override
  Stream<List<Category>> watchCategories(
    String businessId, {
    String? parentId,
    bool? isActive,
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchCategories(
        businessId,
        parentId: parentId,
        isActive: isActive,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<int> insertCategory(CategoriesCompanion category) {
    return RepositoryErrorGuard.run(() => _dao.insertCategory(category));
  }

  @override
  Future<bool> updateCategory(CategoriesCompanion category) {
    return RepositoryErrorGuard.run(() => _dao.updateCategory(category));
  }

  @override
  Future<int> softDeleteCategory(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteCategory(id, businessId),
    );
  }

  @override
  Future<int> restoreCategory(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreCategory(id, businessId));
  }

  @override
  Future<List<Category>> listArchivedCategories(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.listArchivedCategories(businessId),
    );
  }

  @override
  Future<List<Category>> getPendingSyncCategories(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncCategories(businessId, limit: limit),
    );
  }

  @override
  Future<int> markCategoriesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markCategoriesAsSynced(ids, businessId),
    );
  }

  // Brands
  @override
  Future<Brand?> getBrandById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getBrandById(id, businessId));
  }

  @override
  Future<List<Brand>> listBrands(String businessId, {bool? isActive}) {
    return RepositoryErrorGuard.run(
      () => _dao.listBrands(businessId, isActive: isActive),
    );
  }

  @override
  Stream<List<Brand>> watchBrands(String businessId, {bool? isActive}) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBrands(businessId, isActive: isActive),
    );
  }

  @override
  Future<int> insertBrand(BrandsCompanion brand) {
    return RepositoryErrorGuard.run(() => _dao.insertBrand(brand));
  }

  @override
  Future<bool> updateBrand(BrandsCompanion brand) {
    return RepositoryErrorGuard.run(() => _dao.updateBrand(brand));
  }

  @override
  Future<int> deleteBrand(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteBrand(id, businessId));
  }

  @override
  Future<List<Brand>> getPendingSyncBrands(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncBrands(businessId, limit: limit),
    );
  }

  @override
  Future<int> markBrandsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markBrandsAsSynced(ids, businessId),
    );
  }

  // Units
  @override
  Future<Unit?> getUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getUnitById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<List<Unit>> listUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.listUnits(
        businessId,
        isActive: isActive,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Stream<List<Unit>> watchUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchUnits(
        businessId,
        isActive: isActive,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<int> insertUnit(UnitsCompanion unit) {
    return RepositoryErrorGuard.run(() => _dao.insertUnit(unit));
  }

  @override
  Future<bool> updateUnit(UnitsCompanion unit) {
    return RepositoryErrorGuard.run(() => _dao.updateUnit(unit));
  }

  @override
  Future<int> softDeleteUnit(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.softDeleteUnit(id, businessId));
  }

  @override
  Future<int> restoreUnit(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreUnit(id, businessId));
  }

  @override
  Future<List<Unit>> getPendingSyncUnits(String businessId, {int limit = 500}) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncUnits(businessId, limit: limit),
    );
  }

  @override
  Future<int> markUnitsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markUnitsAsSynced(ids, businessId),
    );
  }

  // Taxes
  @override
  Future<Tax?> getTaxById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getTaxById(id, businessId));
  }

  @override
  Future<Tax?> getTaxByCode(String businessId, String taxCode) {
    return RepositoryErrorGuard.run(
      () => _dao.getTaxByCode(businessId, taxCode),
    );
  }

  @override
  Future<List<Tax>> listTaxes(String businessId, {bool? isActive}) {
    return RepositoryErrorGuard.run(
      () => _dao.listTaxes(businessId, isActive: isActive),
    );
  }

  @override
  Stream<List<Tax>> watchTaxes(String businessId, {bool? isActive}) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchTaxes(businessId, isActive: isActive),
    );
  }

  @override
  Future<int> insertTax(TaxesCompanion tax) {
    return RepositoryErrorGuard.run(() => _dao.insertTax(tax));
  }

  @override
  Future<bool> updateTax(TaxesCompanion tax) {
    return RepositoryErrorGuard.run(() => _dao.updateTax(tax));
  }

  @override
  Future<int> deleteTax(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.deleteTax(id, businessId));
  }

  @override
  Future<List<Tax>> getPendingSyncTaxes(String businessId, {int limit = 500}) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncTaxes(businessId, limit: limit),
    );
  }

  @override
  Future<int> markTaxesAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markTaxesAsSynced(ids, businessId),
    );
  }

  // Products
  @override
  Future<Product?> getProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Future<Product?> getProductByCode(
    String businessId,
    String productCode, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductByCode(
        businessId,
        productCode,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<Product>> listProducts(ProductFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listProducts(filter));
  }

  @override
  Stream<Product?> watchProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchProductById(id, businessId, includeDeleted: includeDeleted),
    );
  }

  @override
  Stream<List<Product>> watchProducts(ProductFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchProducts(filter));
  }

  @override
  Future<int> insertProduct(ProductsCompanion product) {
    return RepositoryErrorGuard.run(() => _dao.insertProduct(product));
  }

  @override
  Future<bool> updateProduct(ProductsCompanion product) {
    return RepositoryErrorGuard.run(() => _dao.updateProduct(product));
  }

  @override
  Future<int> softDeleteProduct(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteProduct(id, businessId),
    );
  }

  @override
  Future<int> restoreProduct(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.restoreProduct(id, businessId));
  }

  @override
  Future<List<Product>> listArchivedProducts(String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.listArchivedProducts(businessId),
    );
  }

  @override
  Future<List<Product>> getPendingSyncProducts(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncProducts(businessId, limit: limit),
    );
  }

  @override
  Future<int> markProductsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markProductsAsSynced(ids, businessId),
    );
  }

  // Product Units
  @override
  Future<ProductUnit?> getProductUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductUnitById(
        id,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<ProductUnit?> getProductUnitByBarcode(
    String businessId,
    String barcode, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductUnitByBarcode(
        businessId,
        barcode,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<ProductUnit?> getProductUnitBySku(
    String businessId,
    String sku, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductUnitBySku(
        businessId,
        sku,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<List<ProductUnit>> listProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.listProductUnitsByProductId(
        productId,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Stream<List<ProductUnit>> watchProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  }) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchProductUnitsByProductId(
        productId,
        businessId,
        includeDeleted: includeDeleted,
      ),
    );
  }

  @override
  Future<int> insertProductUnit(ProductUnitsCompanion unit) {
    return RepositoryErrorGuard.run(() => _dao.insertProductUnit(unit));
  }

  @override
  Future<bool> updateProductUnit(ProductUnitsCompanion unit) {
    return RepositoryErrorGuard.run(() => _dao.updateProductUnit(unit));
  }

  @override
  Future<int> softDeleteProductUnit(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.softDeleteProductUnit(id, businessId),
    );
  }

  @override
  Future<int> restoreProductUnit(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.restoreProductUnit(id, businessId),
    );
  }

  @override
  Future<List<ProductUnit>> getPendingSyncProductUnits(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncProductUnits(businessId, limit: limit),
    );
  }

  @override
  Future<int> markProductUnitsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markProductUnitsAsSynced(ids, businessId),
    );
  }

  // Product Variants
  @override
  Future<ProductVariant?> getProductVariantById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductVariantById(id, businessId),
    );
  }

  @override
  Future<List<ProductVariant>> listVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listVariantsByProductUnitId(productUnitId, businessId),
    );
  }

  @override
  Stream<List<ProductVariant>> watchVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchVariantsByProductUnitId(productUnitId, businessId),
    );
  }

  @override
  Future<int> insertProductVariant(ProductVariantsCompanion variant) {
    return RepositoryErrorGuard.run(() => _dao.insertProductVariant(variant));
  }

  @override
  Future<bool> updateProductVariant(ProductVariantsCompanion variant) {
    return RepositoryErrorGuard.run(() => _dao.updateProductVariant(variant));
  }

  @override
  Future<int> deleteProductVariant(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteProductVariant(id, businessId),
    );
  }

  @override
  Future<List<ProductVariant>> getPendingSyncProductVariants(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncProductVariants(businessId, limit: limit),
    );
  }

  @override
  Future<int> markProductVariantsAsSynced(List<String> ids, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markProductVariantsAsSynced(ids, businessId),
    );
  }

  // Product Images
  @override
  Future<List<ProductImage>> getProductImagesByProductId(String productId) {
    return RepositoryErrorGuard.run(
      () => _dao.getProductImagesByProductId(productId),
    );
  }

  @override
  Stream<List<ProductImage>> watchProductImagesByProductId(String productId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchProductImagesByProductId(productId),
    );
  }

  @override
  Future<int> insertProductImage(ProductImagesCompanion image) {
    return RepositoryErrorGuard.run(() => _dao.insertProductImage(image));
  }

  @override
  Future<bool> updateProductImage(ProductImagesCompanion image) {
    return RepositoryErrorGuard.run(() => _dao.updateProductImage(image));
  }

  @override
  Future<int> deleteProductImage(String id) {
    return RepositoryErrorGuard.run(() => _dao.deleteProductImage(id));
  }

  @override
  Future<List<ProductImage>> getPendingSyncProductImages({int limit = 500}) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncProductImages(limit: limit),
    );
  }

  @override
  Future<int> markProductImagesAsSynced(List<String> ids) {
    return RepositoryErrorGuard.run(() => _dao.markProductImagesAsSynced(ids));
  }

  // Product Taxes Pivot
  @override
  Future<List<ProductTax>> listProductTaxesByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listProductTaxesByProductUnitId(productUnitId, businessId),
    );
  }

  @override
  Future<List<ProductTax>> listProductTaxesByTaxId(
    String taxId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listProductTaxesByTaxId(taxId, businessId),
    );
  }

  @override
  Future<int> insertProductTax(ProductTaxesCompanion productTax) {
    return RepositoryErrorGuard.run(() => _dao.insertProductTax(productTax));
  }

  @override
  Future<int> deleteProductTax(
    String productUnitId,
    String taxId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteProductTax(productUnitId, taxId, businessId),
    );
  }

  @override
  Future<List<ProductTax>> getPendingSyncProductTaxes(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncProductTaxes(businessId, limit: limit),
    );
  }

  @override
  Future<int> markProductTaxesAsSynced(
    List<ProductTax> entries,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markProductTaxesAsSynced(entries, businessId),
    );
  }

  // Branch Product Prices / Effective Pricing
  @override
  Future<BranchProductPrice?> getBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getBranchProductPrice(branchId, productUnitId, businessId),
    );
  }

  @override
  Future<EffectiveUnitPrice?> getEffectiveProductUnitPrice(
    String productUnitId,
    String businessId, {
    String? branchId,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getEffectiveProductUnitPrice(
        productUnitId,
        businessId,
        branchId: branchId,
      ),
    );
  }

  @override
  Future<List<BranchProductPrice>> listBranchPricesByBranchId(
    String branchId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listBranchPricesByBranchId(branchId, businessId),
    );
  }

  @override
  Stream<List<BranchProductPrice>> watchBranchPricesByBranchId(
    String branchId,
    String businessId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchBranchPricesByBranchId(branchId, businessId),
    );
  }

  @override
  Future<int> insertBranchProductPrice(BranchProductPricesCompanion price) {
    return RepositoryErrorGuard.run(() => _dao.insertBranchProductPrice(price));
  }

  @override
  Future<bool> updateBranchProductPrice(BranchProductPricesCompanion price) {
    return RepositoryErrorGuard.run(() => _dao.updateBranchProductPrice(price));
  }

  @override
  Future<int> deleteBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.deleteBranchProductPrice(branchId, productUnitId, businessId),
    );
  }

  @override
  Future<List<BranchProductPrice>> getPendingSyncBranchProductPrices(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncBranchProductPrices(businessId, limit: limit),
    );
  }

  @override
  Future<int> markBranchProductPricesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.markBranchProductPricesAsSynced(ids, businessId),
    );
  }

  // Transactional Creation
  @override
  Future<void> createProductWithDetails({
    required ProductsCompanion product,
    required List<ProductUnitsCompanion> units,
    List<ProductVariantsCompanion> variants = const [],
    List<ProductImagesCompanion> images = const [],
    List<ProductTaxesCompanion> taxes = const [],
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.createProductWithDetails(
        product: product,
        units: units,
        variants: variants,
        images: images,
        taxes: taxes,
      ),
    );
  }
}
