import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/catalog/branch_product_prices_table.dart';
import '../tables/catalog/brands_table.dart';
import '../tables/catalog/categories_table.dart';
import '../tables/catalog/product_images_table.dart';
import '../tables/catalog/product_taxes_table.dart';
import '../tables/catalog/product_units_table.dart';
import '../tables/catalog/product_variants_table.dart';
import '../tables/catalog/products_table.dart';
import '../tables/catalog/taxes_table.dart';
import '../tables/catalog/units_table.dart';
import '../tables/core/businesses_table.dart';
import '../tables/core/branches_table.dart';
import 'dao_exceptions.dart';

part 'catalog_dao.g.dart';

/// Filter DTO for [Categories] queries.
class CategoryFilter {
  final String businessId;
  final String? parentId;
  final bool? isActive;
  final bool includeDeleted;

  const CategoryFilter({
    required this.businessId,
    this.parentId,
    this.isActive,
    this.includeDeleted = false,
  });
}

/// Filter DTO for [Products] queries with search and pagination support.
class ProductFilter {
  final String businessId;
  final String? categoryId;
  final String? brandId;
  final String? productType;
  final bool? isActive;
  final bool includeDeleted;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  const ProductFilter({
    required this.businessId,
    this.categoryId,
    this.brandId,
    this.productType,
    this.isActive,
    this.includeDeleted = false,
    this.searchQuery,
    this.limit,
    this.offset,
  });
}

/// DTO representing the resolved effective pricing for a product unit.
class EffectiveUnitPrice {
  final String productUnitId;
  final double purchasePrice;
  final double sellingPrice;
  final double minimumPrice;
  final bool isBranchOverride;
  final String? branchId;

  const EffectiveUnitPrice({
    required this.productUnitId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minimumPrice,
    required this.isBranchOverride,
    this.branchId,
  });
}

/// Module-Driven DAO for Domain: Catalog (Phase 02).
///
/// Encapsulates pure local database CRUD, queries, reactive streams, pagination,
/// multi-tenant scoping (`businessId`), branch overrides (`branchId`), soft-delete
/// rules (`deletedAt`), and atomic transactional product catalog seeding for:
/// [BranchProductPrices], [Brands], [Categories], [ProductImages], [ProductTaxes],
/// [ProductUnits], [ProductVariants], [Products], [Taxes], and [Units].
@DriftAccessor(
  tables: [
    BranchProductPrices,
    Brands,
    Categories,
    ProductImages,
    ProductTaxes,
    ProductUnits,
    ProductVariants,
    Products,
    Taxes,
    Units,
    Businesses,
    Branches,
  ],
)
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  // ==========================================
  // 1. CATEGORIES (businessId Scoped, Soft Delete)
  // ==========================================

  /// Retrieves a category by unique ID within a business.
  Future<Category?> getCategoryById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(categories)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a category by unique category code within a business.
  Future<Category?> getCategoryByCode(
    String businessId,
    String categoryCode, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(categories)
      ..where(
        (tbl) =>
            tbl.businessId.equals(businessId) &
            tbl.categoryCode.equals(categoryCode),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists categories based on filter criteria with strict tenant scoping.
  Future<List<Category>> listCategories(CategoryFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(categories)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.parentId != null) {
      query.where((tbl) => tbl.parentId.equals(filter.parentId!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.sortOrder),
      (tbl) => OrderingTerm(expression: tbl.categoryName),
    ]);
    return query.get();
  }

  /// Reactive stream watching categories based on filter.
  Stream<List<Category>> watchCategories(
    String businessId, {
    String? parentId,
    bool? isActive,
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(categories)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (parentId != null) {
      query.where((tbl) => tbl.parentId.equals(parentId));
    }
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.sortOrder),
      (tbl) => OrderingTerm(expression: tbl.categoryName),
    ]);
    return query.watch();
  }

  /// Inserts a new category.
  Future<int> insertCategory(CategoriesCompanion category) {
    if (!category.businessId.present ||
        category.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertCategory requires businessId.');
    }
    return into(categories).insert(category);
  }

  /// Updates an existing category.
  Future<bool> updateCategory(CategoriesCompanion category) {
    if (!category.businessId.present ||
        category.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateCategory requires businessId.');
    }
    return update(categories).replace(category);
  }

  /// Soft-deletes a category (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteCategory(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(categories)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          CategoriesCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted category (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreCategory(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(categories)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const CategoriesCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Lists archived (soft-deleted) categories.
  Future<List<Category>> listArchivedCategories(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(categories)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) & tbl.deletedAt.isNotNull(),
        ))
        .get();
  }

  /// Retrieves pending synchronization categories for a business.
  Future<List<Category>> getPendingSyncCategories(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(categories)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified category IDs as synchronized.
  Future<int> markCategoriesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          categories,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const CategoriesCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 2. BRANDS (businessId Scoped, No deletedAt in Schema)
  // ==========================================

  /// Retrieves a brand by ID within a business.
  Future<Brand?> getBrandById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(brands)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists brands for a business, optionally filtered by active status.
  Future<List<Brand>> listBrands(String businessId, {bool? isActive}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(brands)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.brandName)]);
    return query.get();
  }

  /// Reactive stream watching brands for a business.
  Stream<List<Brand>> watchBrands(String businessId, {bool? isActive}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(brands)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.brandName)]);
    return query.watch();
  }

  /// Inserts a new brand.
  Future<int> insertBrand(BrandsCompanion brand) {
    if (!brand.businessId.present || brand.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertBrand requires businessId.');
    }
    return into(brands).insert(brand);
  }

  /// Updates an existing brand.
  Future<bool> updateBrand(BrandsCompanion brand) {
    if (!brand.businessId.present || brand.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateBrand requires businessId.');
    }
    return update(brands).replace(brand);
  }

  /// Hard-deletes a brand (no deletedAt column in actual schema).
  Future<int> deleteBrand(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(brands)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization brands for a business.
  Future<List<Brand>> getPendingSyncBrands(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(brands)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified brand IDs as synchronized.
  Future<int> markBrandsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          brands,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const BrandsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 3. UNITS (businessId Scoped, Soft Delete)
  // ==========================================

  /// Retrieves a unit of measurement by ID within a business.
  Future<Unit?> getUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(units)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists units of measurement for a business.
  Future<List<Unit>> listUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(units)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.unitName)]);
    return query.get();
  }

  /// Reactive stream watching units for a business.
  Stream<List<Unit>> watchUnits(
    String businessId, {
    bool? isActive,
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(units)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.unitName)]);
    return query.watch();
  }

  /// Inserts a new unit of measurement.
  Future<int> insertUnit(UnitsCompanion unit) {
    if (!unit.businessId.present || unit.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertUnit requires businessId.');
    }
    return into(units).insert(unit);
  }

  /// Updates an existing unit of measurement.
  Future<bool> updateUnit(UnitsCompanion unit) {
    if (!unit.businessId.present || unit.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateUnit requires businessId.');
    }
    return update(units).replace(unit);
  }

  /// Soft-deletes a unit (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteUnit(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(units)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          UnitsCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted unit (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreUnit(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(units)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const UnitsCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Retrieves pending synchronization units for a business.
  Future<List<Unit>> getPendingSyncUnits(String businessId, {int limit = 500}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(units)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified unit IDs as synchronized.
  Future<int> markUnitsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          units,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const UnitsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 4. TAXES (businessId Scoped, No deletedAt in Schema)
  // ==========================================

  /// Retrieves a tax rule definition by ID within a business.
  Future<Tax?> getTaxById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(taxes)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a tax rule by code within a business.
  Future<Tax?> getTaxByCode(String businessId, String taxCode) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(taxes)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) & tbl.taxCode.equals(taxCode),
        ))
        .getSingleOrNull();
  }

  /// Lists tax rules for a business.
  Future<List<Tax>> listTaxes(String businessId, {bool? isActive}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(taxes)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.taxName)]);
    return query.get();
  }

  /// Reactive stream watching tax definitions for a business.
  Stream<List<Tax>> watchTaxes(String businessId, {bool? isActive}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(taxes)
      ..where((tbl) => tbl.businessId.equals(businessId));
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    query.orderBy([(tbl) => OrderingTerm(expression: tbl.taxName)]);
    return query.watch();
  }

  /// Inserts a new tax rule.
  Future<int> insertTax(TaxesCompanion tax) {
    if (!tax.businessId.present || tax.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertTax requires businessId.');
    }
    return into(taxes).insert(tax);
  }

  /// Updates an existing tax rule.
  Future<bool> updateTax(TaxesCompanion tax) {
    if (!tax.businessId.present || tax.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateTax requires businessId.');
    }
    return update(taxes).replace(tax);
  }

  /// Hard-deletes a tax definition (no deletedAt column in actual schema).
  Future<int> deleteTax(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(taxes)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization tax definitions for a business.
  Future<List<Tax>> getPendingSyncTaxes(String businessId, {int limit = 500}) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(taxes)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified tax IDs as synchronized.
  Future<int> markTaxesAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          taxes,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const TaxesCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 5. PRODUCTS (businessId Scoped, Soft Delete, Search, Pagination)
  // ==========================================

  /// Retrieves a product by ID within a business.
  Future<Product?> getProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(products)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a product by unique product code within a business.
  Future<Product?> getProductByCode(
    String businessId,
    String productCode, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(products)
      ..where(
        (tbl) =>
            tbl.businessId.equals(businessId) &
            tbl.productCode.equals(productCode),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists products based on filter, search, and pagination criteria.
  Future<List<Product>> listProducts(ProductFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(products)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(filter.categoryId!));
    }
    if (filter.brandId != null) {
      query.where((tbl) => tbl.brandId.equals(filter.brandId!));
    }
    if (filter.productType != null) {
      query.where((tbl) => tbl.productType.equals(filter.productType!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final term = '%${filter.searchQuery!.trim()}%';
      query.where(
        (tbl) =>
            tbl.productName.like(term) |
            tbl.productCode.like(term) |
            (tbl.description.isNotNull() & tbl.description.like(term)),
      );
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.productName),
      (tbl) => OrderingTerm(expression: tbl.id),
    ]);
    if (filter.limit != null) {
      query.limit(filter.limit!, offset: filter.offset ?? 0);
    }
    return query.get();
  }

  /// Reactive stream watching a product by ID.
  Stream<Product?> watchProductById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(products)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watchSingleOrNull();
  }

  /// Reactive stream watching products based on filter criteria.
  Stream<List<Product>> watchProducts(ProductFilter filter) {
    if (filter.businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(products)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));
    if (filter.categoryId != null) {
      query.where((tbl) => tbl.categoryId.equals(filter.categoryId!));
    }
    if (filter.brandId != null) {
      query.where((tbl) => tbl.brandId.equals(filter.brandId!));
    }
    if (filter.productType != null) {
      query.where((tbl) => tbl.productType.equals(filter.productType!));
    }
    if (filter.isActive != null) {
      query.where((tbl) => tbl.isActive.equals(filter.isActive!));
    }
    if (!filter.includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final term = '%${filter.searchQuery!.trim()}%';
      query.where(
        (tbl) =>
            tbl.productName.like(term) |
            tbl.productCode.like(term) |
            (tbl.description.isNotNull() & tbl.description.like(term)),
      );
    }
    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.productName),
      (tbl) => OrderingTerm(expression: tbl.id),
    ]);
    if (filter.limit != null) {
      query.limit(filter.limit!, offset: filter.offset ?? 0);
    }
    return query.watch();
  }

  /// Inserts a new product.
  Future<int> insertProduct(ProductsCompanion product) {
    if (!product.businessId.present ||
        product.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('insertProduct requires businessId.');
    }
    return into(products).insert(product);
  }

  /// Updates an existing product.
  Future<bool> updateProduct(ProductsCompanion product) {
    if (!product.businessId.present ||
        product.businessId.value.trim().isEmpty) {
      throw const TenantScopingException('updateProduct requires businessId.');
    }
    return update(products).replace(product);
  }

  /// Soft-deletes a product (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteProduct(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(products)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          ProductsCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted product (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreProduct(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(products)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const ProductsCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Lists archived (soft-deleted) products.
  Future<List<Product>> listArchivedProducts(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(products)..where(
          (tbl) =>
              tbl.businessId.equals(businessId) & tbl.deletedAt.isNotNull(),
        ))
        .get();
  }

  /// Retrieves pending synchronization products for a business.
  Future<List<Product>> getPendingSyncProducts(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(products)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified product IDs as synchronized.
  Future<int> markProductsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          products,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const ProductsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 6. PRODUCT UNITS (businessId Scoped, Soft Delete)
  // ==========================================

  /// Retrieves a product unit by ID within a business.
  Future<ProductUnit?> getProductUnitById(
    String id,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(productUnits)
      ..where((tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a product unit by unique barcode within a business.
  Future<ProductUnit?> getProductUnitByBarcode(
    String businessId,
    String barcode, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(productUnits)
      ..where(
        (tbl) =>
            tbl.businessId.equals(businessId) & tbl.barcode.equals(barcode),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Retrieves a product unit by unique SKU within a business.
  Future<ProductUnit?> getProductUnitBySku(
    String businessId,
    String sku, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(productUnits)
      ..where((tbl) => tbl.businessId.equals(businessId) & tbl.sku.equals(sku));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// Lists all units assigned to a specific product within a business.
  Future<List<ProductUnit>> listProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(productUnits)
      ..where(
        (tbl) =>
            tbl.productId.equals(productId) & tbl.businessId.equals(businessId),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([
      (tbl) =>
          OrderingTerm(expression: tbl.isBaseUnit, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.conversionFactor),
    ]);
    return query.get();
  }

  /// Reactive stream watching units for a specific product.
  Stream<List<ProductUnit>> watchProductUnitsByProductId(
    String productId,
    String businessId, {
    bool includeDeleted = false,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    final query = select(productUnits)
      ..where(
        (tbl) =>
            tbl.productId.equals(productId) & tbl.businessId.equals(businessId),
      );
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([
      (tbl) =>
          OrderingTerm(expression: tbl.isBaseUnit, mode: OrderingMode.desc),
      (tbl) => OrderingTerm(expression: tbl.conversionFactor),
    ]);
    return query.watch();
  }

  /// Inserts a new product unit.
  Future<int> insertProductUnit(ProductUnitsCompanion unit) {
    if (!unit.businessId.present || unit.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertProductUnit requires businessId.',
      );
    }
    return into(productUnits).insert(unit);
  }

  /// Updates an existing product unit.
  Future<bool> updateProductUnit(ProductUnitsCompanion unit) {
    if (!unit.businessId.present || unit.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateProductUnit requires businessId.',
      );
    }
    return update(productUnits).replace(unit);
  }

  /// Soft-deletes a product unit (`deletedAt = now`, `syncStatus = 'pending_delete'`).
  Future<int> softDeleteProductUnit(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(productUnits)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          ProductUnitsCompanion(
            deletedAt: Value(DateTime.now()),
            syncStatus: const Value('pending_delete'),
          ),
        );
  }

  /// Restores a soft-deleted product unit (`deletedAt = null`, `syncStatus = 'pending_update'`).
  Future<int> restoreProductUnit(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (update(productUnits)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const ProductUnitsCompanion(
            deletedAt: Value(null),
            syncStatus: Value('pending_update'),
          ),
        );
  }

  /// Retrieves pending synchronization product units for a business.
  Future<List<ProductUnit>> getPendingSyncProductUnits(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productUnits)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified product unit IDs as synchronized.
  Future<int> markProductUnitsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          productUnits,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const ProductUnitsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 7. PRODUCT VARIANTS (businessId Scoped, No deletedAt in Schema)
  // ==========================================

  /// Retrieves a product variant by ID within a business.
  Future<ProductVariant?> getProductVariantById(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productVariants)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Lists variants assigned to a specific product unit within a business.
  Future<List<ProductVariant>> listVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productVariants)
          ..where(
            (tbl) =>
                tbl.productUnitId.equals(productUnitId) &
                tbl.businessId.equals(businessId),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.variantName)]))
        .get();
  }

  /// Reactive stream watching variants for a specific product unit.
  Stream<List<ProductVariant>> watchVariantsByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productVariants)
          ..where(
            (tbl) =>
                tbl.productUnitId.equals(productUnitId) &
                tbl.businessId.equals(businessId),
          )
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.variantName)]))
        .watch();
  }

  /// Inserts a new product variant.
  Future<int> insertProductVariant(ProductVariantsCompanion variant) {
    if (!variant.businessId.present ||
        variant.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertProductVariant requires businessId.',
      );
    }
    return into(productVariants).insert(variant);
  }

  /// Updates an existing product variant.
  Future<bool> updateProductVariant(ProductVariantsCompanion variant) {
    if (!variant.businessId.present ||
        variant.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateProductVariant requires businessId.',
      );
    }
    return update(productVariants).replace(variant);
  }

  /// Hard-deletes a product variant (no deletedAt column in actual schema).
  Future<int> deleteProductVariant(String id, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(productVariants)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization product variants for a business.
  Future<List<ProductVariant>> getPendingSyncProductVariants(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productVariants)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified product variant IDs as synchronized.
  Future<int> markProductVariantsAsSynced(List<String> ids, String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          productVariants,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const ProductVariantsCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 8. PRODUCT IMAGES (Linked via productId, No deletedAt in Schema)
  // ==========================================

  /// Retrieves images assigned to a product, ordered by primary designation and creation time.
  Future<List<ProductImage>> getProductImagesByProductId(String productId) {
    return (select(productImages)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isPrimary,
              mode: OrderingMode.desc,
            ),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .get();
  }

  /// Reactive stream watching images for a product.
  Stream<List<ProductImage>> watchProductImagesByProductId(String productId) {
    return (select(productImages)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isPrimary,
              mode: OrderingMode.desc,
            ),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .watch();
  }

  /// Inserts a new product image gallery entry.
  Future<int> insertProductImage(ProductImagesCompanion image) {
    return into(productImages).insert(image);
  }

  /// Updates an existing product image gallery entry.
  Future<bool> updateProductImage(ProductImagesCompanion image) {
    return update(productImages).replace(image);
  }

  /// Hard-deletes a product image entry.
  Future<int> deleteProductImage(String id) {
    return (delete(productImages)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves pending synchronization product images.
  Future<List<ProductImage>> getPendingSyncProductImages({int limit = 500}) {
    return (select(productImages)
          ..where((tbl) => tbl.syncStatus.isNotValue('synced'))
          ..limit(limit))
        .get();
  }

  /// Marks specified product image IDs as synchronized.
  Future<int> markProductImagesAsSynced(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(productImages)..where((tbl) => tbl.id.isIn(ids))).write(
      const ProductImagesCompanion(syncStatus: Value('synced')),
    );
  }

  // ==========================================
  // 9. PRODUCT TAXES PIVOT (businessId Scoped, No deletedAt in Schema)
  // ==========================================

  /// Lists tax associations for a specific product unit within a business.
  Future<List<ProductTax>> listProductTaxesByProductUnitId(
    String productUnitId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productTaxes)..where(
          (tbl) =>
              tbl.productUnitId.equals(productUnitId) &
              tbl.businessId.equals(businessId),
        ))
        .get();
  }

  /// Lists product units linked to a specific tax definition within a business.
  Future<List<ProductTax>> listProductTaxesByTaxId(
    String taxId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productTaxes)..where(
          (tbl) => tbl.taxId.equals(taxId) & tbl.businessId.equals(businessId),
        ))
        .get();
  }

  /// Inserts a new product-tax association.
  Future<int> insertProductTax(ProductTaxesCompanion productTax) {
    if (!productTax.businessId.present ||
        productTax.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertProductTax requires businessId.',
      );
    }
    return into(productTaxes).insert(productTax);
  }

  /// Deletes a specific product-tax association within a business.
  Future<int> deleteProductTax(
    String productUnitId,
    String taxId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(productTaxes)..where(
          (tbl) =>
              tbl.productUnitId.equals(productUnitId) &
              tbl.taxId.equals(taxId) &
              tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization product tax pivot entries for a business.
  Future<List<ProductTax>> getPendingSyncProductTaxes(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(productTaxes)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified product-tax associations as synchronized.
  Future<int> markProductTaxesAsSynced(
    List<ProductTax> entries,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (entries.isEmpty) {
      return Future.value(0);
    }
    return transaction(() async {
      int count = 0;
      for (final e in entries) {
        if (e.businessId != businessId) {
          continue;
        }
        final updated =
            await (update(productTaxes)..where(
                  (tbl) =>
                      tbl.businessId.equals(businessId) &
                      tbl.productUnitId.equals(e.productUnitId) &
                      tbl.taxId.equals(e.taxId),
                ))
                .write(
                  const ProductTaxesCompanion(syncStatus: Value('synced')),
                );
        count += updated;
      }
      return count;
    });
  }

  // ==========================================
  // 10. BRANCH PRODUCT PRICES (businessId & branchId Scoped, No deletedAt in Schema)
  // ==========================================

  /// Retrieves a specific branch price override for a product unit.
  Future<BranchProductPrice?> getBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branchProductPrices)..where(
          (tbl) =>
              tbl.branchId.equals(branchId) &
              tbl.productUnitId.equals(productUnitId) &
              tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Resolves the effective pricing for a product unit.
  /// If [branchId] is provided and an active branch override exists, returns branch pricing.
  /// Otherwise, falls back to the product unit's base prices.
  Future<EffectiveUnitPrice?> getEffectiveProductUnitPrice(
    String productUnitId,
    String businessId, {
    String? branchId,
  }) async {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (branchId != null && branchId.trim().isNotEmpty) {
      final overridePrice = await getBranchProductPrice(
        branchId,
        productUnitId,
        businessId,
      );
      if (overridePrice != null && overridePrice.isActive) {
        return EffectiveUnitPrice(
          productUnitId: productUnitId,
          purchasePrice: overridePrice.purchasePrice,
          sellingPrice: overridePrice.sellingPrice,
          minimumPrice: overridePrice.minimumPrice,
          isBranchOverride: true,
          branchId: branchId,
        );
      }
    }
    final baseUnit = await getProductUnitById(productUnitId, businessId);
    if (baseUnit == null) {
      return null;
    }
    return EffectiveUnitPrice(
      productUnitId: productUnitId,
      purchasePrice: baseUnit.purchasePrice,
      sellingPrice: baseUnit.sellingPrice,
      minimumPrice: baseUnit.minimumPrice,
      isBranchOverride: false,
    );
  }

  /// Lists all branch price overrides for a specific branch within a business.
  Future<List<BranchProductPrice>> listBranchPricesByBranchId(
    String branchId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branchProductPrices)..where(
          (tbl) =>
              tbl.branchId.equals(branchId) & tbl.businessId.equals(businessId),
        ))
        .get();
  }

  /// Reactive stream watching branch price overrides for a specific branch.
  Stream<List<BranchProductPrice>> watchBranchPricesByBranchId(
    String branchId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branchProductPrices)..where(
          (tbl) =>
              tbl.branchId.equals(branchId) & tbl.businessId.equals(businessId),
        ))
        .watch();
  }

  /// Inserts a new branch price override.
  Future<int> insertBranchProductPrice(BranchProductPricesCompanion price) {
    if (!price.businessId.present || price.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'insertBranchProductPrice requires businessId.',
      );
    }
    return into(branchProductPrices).insert(price);
  }

  /// Updates an existing branch price override.
  Future<bool> updateBranchProductPrice(BranchProductPricesCompanion price) {
    if (!price.businessId.present || price.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'updateBranchProductPrice requires businessId.',
      );
    }
    return update(branchProductPrices).replace(price);
  }

  /// Deletes a branch price override.
  Future<int> deleteBranchProductPrice(
    String branchId,
    String productUnitId,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (delete(branchProductPrices)..where(
          (tbl) =>
              tbl.branchId.equals(branchId) &
              tbl.productUnitId.equals(productUnitId) &
              tbl.businessId.equals(businessId),
        ))
        .go();
  }

  /// Retrieves pending synchronization branch product prices for a business.
  Future<List<BranchProductPrice>> getPendingSyncBranchProductPrices(
    String businessId, {
    int limit = 500,
  }) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    return (select(branchProductPrices)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotValue('synced'),
          )
          ..limit(limit))
        .get();
  }

  /// Marks specified branch product price IDs as synchronized.
  Future<int> markBranchProductPricesAsSynced(
    List<String> ids,
    String businessId,
  ) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
    if (ids.isEmpty) {
      return Future.value(0);
    }
    return (update(
          branchProductPrices,
        )..where((tbl) => tbl.id.isIn(ids) & tbl.businessId.equals(businessId)))
        .write(const BranchProductPricesCompanion(syncStatus: Value('synced')));
  }

  // ==========================================
  // 11. TRANSACTIONAL PERSISTENCE / SETUP
  // ==========================================

  /// Atomically seeds a new product along with its units, variants, images, and tax associations.
  /// If any child insertion fails constraint verification, the entire transaction rolls back.
  Future<void> createProductWithDetails({
    required ProductsCompanion product,
    required List<ProductUnitsCompanion> units,
    List<ProductVariantsCompanion> variants = const [],
    List<ProductImagesCompanion> images = const [],
    List<ProductTaxesCompanion> taxes = const [],
  }) {
    if (!product.businessId.present ||
        product.businessId.value.trim().isEmpty) {
      throw const TenantScopingException(
        'createProductWithDetails requires product.businessId.',
      );
    }
    return transaction(() async {
      await into(products).insert(product);
      for (final u in units) {
        await into(productUnits).insert(u);
      }
      for (final v in variants) {
        await into(productVariants).insert(v);
      }
      for (final img in images) {
        await into(productImages).insert(img);
      }
      for (final t in taxes) {
        await into(productTaxes).insert(t);
      }
    });
  }
}
