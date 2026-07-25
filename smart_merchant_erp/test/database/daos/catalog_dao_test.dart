import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late CatalogDao catalogDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    catalogDao = CatalogDao(database);

    // Seed required parent User, Account, Businesses, and Branches for foreign keys
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@catalog.com',
            passwordHash: 'hash',
            firstName: 'Catalog',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-catalog-01'),
            ownerId: 'u-owner',
            businessName: 'Catalog Account',
            businessType: 'Retail',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-catalog-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-catalog-01',
            businessName: 'Business Beta',
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_1',
            businessId: 'BUS_A',
            branchName: 'Main Branch Alpha',
            branchCode: 'BR-A1',
            isDefault: const drift.Value(true),
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_2',
            businessId: 'BUS_A',
            branchName: 'Sub Branch Alpha',
            branchCode: 'BR-A2',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('CatalogDao Phase 02 Test Suite -', () {
    test(
      '1. Categories CRUD, Hierarchical Parent-Child, Soft Delete & Restore',
      () async {
        // Insert Root Category
        final rootId = 'cat-root-a';
        await catalogDao.insertCategory(
          CategoriesCompanion.insert(
            id: rootId,
            businessId: 'BUS_A',
            categoryName: 'Electronics',
            categoryCode: const drift.Value('ELEC'),
            sortOrder: const drift.Value(1),
          ),
        );

        // Insert Child Category
        final childId = 'cat-child-a';
        await catalogDao.insertCategory(
          CategoriesCompanion.insert(
            id: childId,
            businessId: 'BUS_A',
            parentId: drift.Value(rootId),
            categoryName: 'Smartphones',
            categoryCode: const drift.Value('PHONE'),
            sortOrder: const drift.Value(2),
          ),
        );

        final fetchedRoot = await catalogDao.getCategoryByCode('BUS_A', 'ELEC');
        expect(fetchedRoot, isNotNull);
        expect(fetchedRoot!.id, equals(rootId));

        final children = await catalogDao.listCategories(
          CategoryFilter(businessId: 'BUS_A', parentId: rootId),
        );
        expect(children.length, equals(1));
        expect(children.first.categoryName, equals('Smartphones'));

        // Soft Delete Child
        await catalogDao.softDeleteCategory(childId, 'BUS_A');
        expect(await catalogDao.getCategoryById(childId, 'BUS_A'), isNull);
        expect(
          await catalogDao.getCategoryById(
            childId,
            'BUS_A',
            includeDeleted: true,
          ),
          isNotNull,
        );

        final archived = await catalogDao.listArchivedCategories('BUS_A');
        expect(archived.length, equals(1));
        expect(archived.first.syncStatus, equals('pending_delete'));

        // Restore Child
        await catalogDao.restoreCategory(childId, 'BUS_A');
        final restored = await catalogDao.getCategoryById(childId, 'BUS_A');
        expect(restored, isNotNull);
        expect(restored!.syncStatus, equals('pending_update'));
      },
    );

    test('2. Brands & Units CRUD and Offline Sync Helpers', () async {
      // Brands (No deletedAt in schema)
      final brandId = 'brand-apple';
      await catalogDao.insertBrand(
        BrandsCompanion.insert(
          id: brandId,
          businessId: 'BUS_A',
          brandName: 'Apple',
        ),
      );
      final brand = await catalogDao.getBrandById(brandId, 'BUS_A');
      expect(brand, isNotNull);
      expect(brand!.brandName, equals('Apple'));

      // Units (Has deletedAt)
      final unitId = 'unit-pc';
      await catalogDao.insertUnit(
        UnitsCompanion.insert(
          id: unitId,
          businessId: 'BUS_A',
          unitName: 'Piece',
          unitSymbol: 'PC',
        ),
      );
      final unit = await catalogDao.getUnitById(unitId, 'BUS_A');
      expect(unit, isNotNull);
      expect(unit!.unitSymbol, equals('PC'));

      // Soft delete & restore unit
      await catalogDao.softDeleteUnit(unitId, 'BUS_A');
      expect(await catalogDao.getUnitById(unitId, 'BUS_A'), isNull);
      await catalogDao.restoreUnit(unitId, 'BUS_A');
      expect(await catalogDao.getUnitById(unitId, 'BUS_A'), isNotNull);

      // Sync verification
      final pendingBrands = await catalogDao.getPendingSyncBrands('BUS_A');
      expect(pendingBrands.length, equals(1));
      await catalogDao.markBrandsAsSynced([brandId], 'BUS_A');
      expect(await catalogDao.getPendingSyncBrands('BUS_A'), isEmpty);

      final pendingUnits = await catalogDao.getPendingSyncUnits('BUS_A');
      expect(pendingUnits.length, equals(1));
      await catalogDao.markUnitsAsSynced([unitId], 'BUS_A');
      expect(await catalogDao.getPendingSyncUnits('BUS_A'), isEmpty);
    });

    test('3. Taxes CRUD & Pivot Associations (ProductTaxes)', () async {
      final taxId = 'tax-vat-15';
      await catalogDao.insertTax(
        TaxesCompanion.insert(
          id: taxId,
          businessId: 'BUS_A',
          taxName: 'Value Added Tax 15%',
          taxCode: 'VAT_15',
          rate: 15.0,
          taxType: const drift.Value('Percentage'),
        ),
      );

      final tax = await catalogDao.getTaxByCode('BUS_A', 'VAT_15');
      expect(tax, isNotNull);
      expect(tax!.rate, equals(15.0));

      // Seed required Product and ProductUnit for Pivot test
      await catalogDao.insertUnit(
        UnitsCompanion.insert(
          id: 'u-base',
          businessId: 'BUS_A',
          unitName: 'Box',
          unitSymbol: 'BX',
        ),
      );
      await catalogDao.insertProduct(
        ProductsCompanion.insert(
          id: 'prod-pivot-test',
          businessId: 'BUS_A',
          productCode: 'P-PIVOT',
          productName: 'Pivot Test Product',
        ),
      );
      await catalogDao.insertProductUnit(
        ProductUnitsCompanion.insert(
          id: 'pu-pivot-test',
          businessId: 'BUS_A',
          productId: 'prod-pivot-test',
          unitId: 'u-base',
          isBaseUnit: const drift.Value(true),
        ),
      );

      // Pivot Insertion
      await catalogDao.insertProductTax(
        ProductTaxesCompanion.insert(
          businessId: 'BUS_A',
          productUnitId: 'pu-pivot-test',
          taxId: taxId,
        ),
      );

      final linkedTaxes = await catalogDao.listProductTaxesByProductUnitId(
        'pu-pivot-test',
        'BUS_A',
      );
      expect(linkedTaxes.length, equals(1));
      expect(linkedTaxes.first.taxId, equals(taxId));

      await catalogDao.deleteProductTax('pu-pivot-test', taxId, 'BUS_A');
      expect(
        await catalogDao.listProductTaxesByProductUnitId(
          'pu-pivot-test',
          'BUS_A',
        ),
        isEmpty,
      );
    });

    test('4. Strict Tenant Scoping Enforcement Across Catalog Tables', () async {
      // Seed categories in BUS_A and BUS_B
      await catalogDao.insertCategory(
        CategoriesCompanion.insert(
          id: 'cat-a',
          businessId: 'BUS_A',
          categoryName: 'Cat A',
        ),
      );
      await catalogDao.insertCategory(
        CategoriesCompanion.insert(
          id: 'cat-b',
          businessId: 'BUS_B',
          categoryName: 'Cat B',
        ),
      );

      final listA = await catalogDao.listCategories(
        const CategoryFilter(businessId: 'BUS_A'),
      );
      expect(listA.length, equals(1));
      expect(listA.first.id, equals('cat-a'));

      final listB = await catalogDao.listCategories(
        const CategoryFilter(businessId: 'BUS_B'),
      );
      expect(listB.length, equals(1));
      expect(listB.first.id, equals('cat-b'));

      // Verify that calling methods without businessId throws TenantScopingException
      expect(
        () async => await catalogDao.getCategoryById('cat-a', ''),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async =>
            await catalogDao.listProducts(const ProductFilter(businessId: ' ')),
        throwsA(isA<TenantScopingException>()),
      );
      expect(
        () async => await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'p-invalid',
            businessId: '   ',
            productCode: 'INVALID',
            productName: 'Invalid Tenant Product',
          ),
        ),
        throwsA(isA<TenantScopingException>()),
      );
    });

    test(
      '5. BranchProductPrices Resolution & Effective Pricing Fallback',
      () async {
        await catalogDao.insertUnit(
          UnitsCompanion.insert(
            id: 'u-unit-1',
            businessId: 'BUS_A',
            unitName: 'Piece',
            unitSymbol: 'PC',
          ),
        );
        await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'prod-price-test',
            businessId: 'BUS_A',
            productCode: 'P-PRICE',
            productName: 'Price Test Item',
          ),
        );
        final puId = 'pu-price-test';
        await catalogDao.insertProductUnit(
          ProductUnitsCompanion.insert(
            id: puId,
            businessId: 'BUS_A',
            productId: 'prod-price-test',
            unitId: 'u-unit-1',
            purchasePrice: const drift.Value(50.0),
            sellingPrice: const drift.Value(100.0),
            minimumPrice: const drift.Value(80.0),
            isBaseUnit: const drift.Value(true),
          ),
        );

        // 1. Check fallback when no branch override exists (or branchId is null)
        final fallbackPrice = await catalogDao.getEffectiveProductUnitPrice(
          puId,
          'BUS_A',
          branchId: 'BRANCH_1',
        );
        expect(fallbackPrice, isNotNull);
        expect(fallbackPrice!.sellingPrice, equals(100.0));
        expect(fallbackPrice.isBranchOverride, isFalse);

        // 2. Insert branch override for BRANCH_1
        await catalogDao.insertBranchProductPrice(
          BranchProductPricesCompanion.insert(
            id: 'bpp-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            productUnitId: puId,
            purchasePrice: const drift.Value(55.0),
            sellingPrice: const drift.Value(120.0),
            minimumPrice: const drift.Value(90.0),
          ),
        );

        // 3. Verify effective price now returns BRANCH_1 override
        final overridePrice = await catalogDao.getEffectiveProductUnitPrice(
          puId,
          'BUS_A',
          branchId: 'BRANCH_1',
        );
        expect(overridePrice, isNotNull);
        expect(overridePrice!.sellingPrice, equals(120.0));
        expect(overridePrice.isBranchOverride, isTrue);
        expect(overridePrice.branchId, equals('BRANCH_1'));

        // 4. Verify BRANCH_2 still falls back to base unit price
        final branch2Price = await catalogDao.getEffectiveProductUnitPrice(
          puId,
          'BUS_A',
          branchId: 'BRANCH_2',
        );
        expect(branch2Price, isNotNull);
        expect(branch2Price!.sellingPrice, equals(100.0));
        expect(branch2Price.isBranchOverride, isFalse);
      },
    );

    test('6. Products Search, Pagination & Ordering Accuracy', () async {
      await catalogDao.insertUnit(
        UnitsCompanion.insert(
          id: 'u-search',
          businessId: 'BUS_A',
          unitName: 'Item',
          unitSymbol: 'ITM',
        ),
      );

      // Insert 5 products alphabetically named
      for (int i = 1; i <= 5; i++) {
        await catalogDao.insertProduct(
          ProductsCompanion.insert(
            id: 'prod-0$i',
            businessId: 'BUS_A',
            productCode: 'CODE-$i',
            productName: 'Alpha Product 0$i',
            description: drift.Value(
              i == 3 ? 'Special Widget Item' : 'Standard Item',
            ),
          ),
        );
      }

      // Test Search Query matching description/name
      final searchResults = await catalogDao.listProducts(
        const ProductFilter(businessId: 'BUS_A', searchQuery: 'Widget'),
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('prod-03'));

      // Test Pagination & Ordering
      final page1 = await catalogDao.listProducts(
        const ProductFilter(businessId: 'BUS_A', limit: 2, offset: 0),
      );
      expect(page1.length, equals(2));
      expect(page1[0].productName, equals('Alpha Product 01'));
      expect(page1[1].productName, equals('Alpha Product 02'));

      final page2 = await catalogDao.listProducts(
        const ProductFilter(businessId: 'BUS_A', limit: 2, offset: 2),
      );
      expect(page2.length, equals(2));
      expect(page2[0].productName, equals('Alpha Product 03'));
      expect(page2[1].productName, equals('Alpha Product 04'));

      final page3 = await catalogDao.listProducts(
        const ProductFilter(businessId: 'BUS_A', limit: 2, offset: 4),
      );
      expect(page3.length, equals(1));
      expect(page3[0].productName, equals('Alpha Product 05'));
    });

    test('7. ProductVariants & ProductImages CRUD and Stream Watch', () async {
      await catalogDao.insertUnit(
        UnitsCompanion.insert(
          id: 'u-var',
          businessId: 'BUS_A',
          unitName: 'Box',
          unitSymbol: 'BX',
        ),
      );
      await catalogDao.insertProduct(
        ProductsCompanion.insert(
          id: 'prod-watch-test',
          businessId: 'BUS_A',
          productCode: 'P-WATCH',
          productName: 'Watch Test Product',
        ),
      );
      final puId = 'pu-watch-test';
      await catalogDao.insertProductUnit(
        ProductUnitsCompanion.insert(
          id: puId,
          businessId: 'BUS_A',
          productId: 'prod-watch-test',
          unitId: 'u-var',
        ),
      );

      // Test ProductVariants
      await catalogDao.insertProductVariant(
        ProductVariantsCompanion.insert(
          id: 'var-color-red',
          businessId: 'BUS_A',
          productUnitId: puId,
          variantName: 'Color',
          variantValue: 'Red',
        ),
      );
      final variants = await catalogDao.listVariantsByProductUnitId(
        puId,
        'BUS_A',
      );
      expect(variants.length, equals(1));
      expect(variants.first.variantValue, equals('Red'));

      // Test ProductImages
      await catalogDao.insertProductImage(
        ProductImagesCompanion.insert(
          id: 'img-1',
          productId: 'prod-watch-test',
          imagePath: '/images/front.png',
          isPrimary: const drift.Value(true),
        ),
      );
      final images = await catalogDao.getProductImagesByProductId(
        'prod-watch-test',
      );
      expect(images.length, equals(1));
      expect(images.first.isPrimary, isTrue);

      // Verify Reactive Stream Emission
      final stream = catalogDao.watchVariantsByProductUnitId(puId, 'BUS_A');
      expect(stream, emitsInOrder([hasLength(1), hasLength(2)]));

      // Emit new variant to trigger stream
      await catalogDao.insertProductVariant(
        ProductVariantsCompanion.insert(
          id: 'var-size-large',
          businessId: 'BUS_A',
          productUnitId: puId,
          variantName: 'Size',
          variantValue: 'Large',
        ),
      );
    });

    test(
      '8. Atomic Transaction Seeding (createProductWithDetails) & Rollback',
      () async {
        await catalogDao.insertUnit(
          UnitsCompanion.insert(
            id: 'u-atomic',
            businessId: 'BUS_A',
            unitName: 'Carton',
            unitSymbol: 'CTN',
          ),
        );

        final productComp = ProductsCompanion.insert(
          id: 'prod-atomic-100',
          businessId: 'BUS_A',
          productCode: 'ATOMIC-100',
          productName: 'Atomic Master Product',
        );
        final unitsComp = [
          ProductUnitsCompanion.insert(
            id: 'pu-atomic-100',
            businessId: 'BUS_A',
            productId: 'prod-atomic-100',
            unitId: 'u-atomic',
            isBaseUnit: const drift.Value(true),
            sellingPrice: const drift.Value(250.0),
          ),
        ];
        final variantsComp = [
          ProductVariantsCompanion.insert(
            id: 'var-atomic-1',
            businessId: 'BUS_A',
            productUnitId: 'pu-atomic-100',
            variantName: 'Grade',
            variantValue: 'Premium',
          ),
        ];

        // Successful Atomic Seeding
        await catalogDao.createProductWithDetails(
          product: productComp,
          units: unitsComp,
          variants: variantsComp,
        );

        expect(
          await catalogDao.getProductById('prod-atomic-100', 'BUS_A'),
          isNotNull,
        );
        expect(
          (await catalogDao.listProductUnitsByProductId(
            'prod-atomic-100',
            'BUS_A',
          )).length,
          equals(1),
        );

        // Deliberate Rollback Test
        final rollbackProd = ProductsCompanion.insert(
          id: 'prod-rollback-200',
          businessId: 'BUS_A',
          productCode: 'ATOMIC-ROLLBACK',
          productName: 'Rollback Target Item',
        );
        final invalidUnits = [
          ProductUnitsCompanion.insert(
            id: 'pu-invalid-rollback',
            businessId: 'BUS_A',
            productId: 'prod-rollback-200',
            unitId: 'non-existent-unit-999', // Will trigger FK violation!
          ),
        ];

        expect(
          () async => await catalogDao.createProductWithDetails(
            product: rollbackProd,
            units: invalidUnits,
          ),
          throwsA(isA<sqlite.SqliteException>()),
        );

        // Verify complete rollback (Parent product does NOT exist)
        expect(
          await catalogDao.getProductById('prod-rollback-200', 'BUS_A'),
          isNull,
        );
      },
    );
  });
}
