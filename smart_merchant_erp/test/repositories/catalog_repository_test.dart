import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/modules/catalog/infrastructure/repositories/catalog_repository_impl.dart';
import 'package:smart_merchant_erp/kernel/error/repository_exceptions.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';

void main() {
  late AppDatabase db;
  late CatalogDao dao;
  late CatalogRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    dao = CatalogDao(db);
    repository = CatalogRepositoryImpl(dao);

    // Seed parent user, account, business, and branch for foreign key constraints
    await db
        .into(db.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-1'),
            email: 'owner@smartmerchant.com',
            passwordHash: 'hash',
            firstName: 'Owner',
            lastName: 'User',
          ),
        );
    await db
        .into(db.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-1'),
            ownerId: 'u-1',
            businessName: 'Smart Store',
            businessType: 'Retail',
            defaultCurrency: 'YER',
          ),
        );
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'biz-1',
            accountId: 'acc-1',
            businessName: 'Smart Merchant Corp',
          ),
        );
    await db
        .into(db.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'branch-1',
            businessId: 'biz-1',
            branchCode: 'MAIN',
            branchName: 'Main HQ',
            isDefault: const drift.Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('CatalogRepository Unit Suite', () {
    test(
      'Catalog joins deduplicate units, isolate businesses, and react to stock and price',
      () async {
        await db
            .into(db.businesses)
            .insert(
              BusinessesCompanion.insert(
                id: 'biz-2',
                accountId: 'acc-1',
                businessName: 'Other store',
              ),
            );
        await repository.insertUnit(
          UnitsCompanion.insert(
            id: 'piece',
            businessId: 'biz-1',
            unitName: 'حبة',
            unitSymbol: 'pc',
          ),
        );
        await repository.insertUnit(
          UnitsCompanion.insert(
            id: 'box',
            businessId: 'biz-1',
            unitName: 'كرتون',
            unitSymbol: 'box',
          ),
        );
        await repository.createProductWithDetails(
          product: ProductsCompanion.insert(
            id: 'p',
            businessId: 'biz-1',
            productCode: 'P',
            productName: 'منتج',
          ),
          units: [
            ProductUnitsCompanion.insert(
              id: 'pu',
              businessId: 'biz-1',
              productId: 'p',
              unitId: 'piece',
              isBaseUnit: const drift.Value(true),
              sellingPrice: const drift.Value(100),
            ),
            ProductUnitsCompanion.insert(
              id: 'carton',
              businessId: 'biz-1',
              productId: 'p',
              unitId: 'box',
              conversionFactor: const drift.Value(12),
            ),
          ],
        );
        for (var i = 1; i <= 4; i++) {
          await db
              .into(db.warehouses)
              .insert(
                WarehousesCompanion.insert(
                  id: 'wh-$i',
                  businessId: 'biz-1',
                  branchId: 'branch-1',
                  warehouseName: 'مخزن $i',
                  warehouseCode: 'WH$i',
                ),
              );
          await db
              .into(db.inventories)
              .insert(
                InventoriesCompanion.insert(
                  id: 'stock-$i',
                  businessId: i == 4 ? 'biz-2' : 'biz-1',
                  warehouseId: 'wh-$i',
                  productUnitId: 'pu',
                  quantity: drift.Value(
                    i == 1
                        ? 8
                        : i == 2
                        ? 5
                        : 99,
                  ),
                  deletedAt: drift.Value(i == 3 ? DateTime(2026) : null),
                ),
              );
        }
        final stream = StreamIterator(repository.watchProductCatalog('biz-1'));
        addTearDown(stream.cancel);
        Future<List<ProductCatalogEntry>> next() async {
          expect(
            await stream.moveNext().timeout(const Duration(seconds: 5)),
            isTrue,
          );
          return stream.current;
        }

        var snapshot = await next();
        expect(snapshot, hasLength(1));
        expect(snapshot.single.units, hasLength(2));
        expect(snapshot.single.units.first.id, 'pu');
        expect(snapshot.single.quantitiesByUnit['pu'], 13);
        await (db.update(db.inventories)..where((s) => s.id.equals('stock-1')))
            .write(const InventoriesCompanion(quantity: drift.Value(9)));
        snapshot = await next();
        expect(snapshot.single.quantitiesByUnit['pu'], 14);
        await (db.update(db.productUnits)..where((u) => u.id.equals('pu')))
            .write(const ProductUnitsCompanion(sellingPrice: drift.Value(250)));
        snapshot = await next();
        expect(snapshot.single.units.first.sellingPrice, 250);
        await (db.update(db.products)..where((p) => p.id.equals('p'))).write(
          ProductsCompanion(deletedAt: drift.Value(DateTime(2026))),
        );
        expect(await next(), isEmpty);
        await stream.cancel();
        expect(await repository.watchProductCatalog('biz-2').first, isEmpty);
      },
    );

    test(
      'Repeated product entry allows multiple products without barcodes',
      () async {
        await repository.insertUnit(
          UnitsCompanion.insert(
            id: 'piece',
            businessId: 'biz-1',
            unitName: 'حبة',
            unitSymbol: 'pc',
          ),
        );
        for (var i = 0; i < 3; i++) {
          await repository.createProductWithDetails(
            product: ProductsCompanion.insert(
              id: 'product-$i',
              businessId: 'biz-1',
              productCode: 'CODE-$i',
              productName: 'منتج $i',
            ),
            units: [
              ProductUnitsCompanion.insert(
                id: 'product-unit-$i',
                businessId: 'biz-1',
                productId: 'product-$i',
                unitId: 'piece',
                barcode: const drift.Value(null),
                isBaseUnit: const drift.Value(true),
              ),
            ],
          );
        }
        for (var i = 0; i < 3; i++) {
          final units = await repository.listProductUnitsByProductId(
            'product-$i',
            'biz-1',
          );
          expect(units, hasLength(1));
          expect(units.single.barcode, isNull);
        }
      },
    );

    test('1. Categories, Brands, Units, and Taxes Operations', () async {
      await repository.insertCategory(
        CategoriesCompanion.insert(
          id: 'cat-1',
          businessId: 'biz-1',
          categoryName: 'Beverages',
          categoryCode: const drift.Value('BEV'),
        ),
      );
      final cat = await repository.getCategoryByCode('biz-1', 'BEV');
      expect(cat?.categoryName, 'Beverages');

      await repository.insertBrand(
        BrandsCompanion.insert(
          id: 'brand-1',
          businessId: 'biz-1',
          brandName: 'Coca-Cola',
        ),
      );
      final brand = await repository.getBrandById('brand-1', 'biz-1');
      expect(brand?.brandName, 'Coca-Cola');

      await repository.insertUnit(
        UnitsCompanion.insert(
          id: 'unit-1',
          businessId: 'biz-1',
          unitName: 'Piece',
          unitSymbol: 'PC',
        ),
      );
      final unit = await repository.getUnitById('unit-1', 'biz-1');
      expect(unit?.unitSymbol, 'PC');

      await repository.insertTax(
        TaxesCompanion.insert(
          id: 'tax-1',
          businessId: 'biz-1',
          taxName: 'VAT 15%',
          taxCode: 'VAT_15',
          rate: 15.0,
        ),
      );
      final tax = await repository.getTaxByCode('biz-1', 'VAT_15');
      expect(tax?.rate, 15.0);
    });

    test(
      '2. Products, ProductUnits, and Effective Unit Price (Branch Override)',
      () async {
        // Seed dependencies
        await repository.insertCategory(
          CategoriesCompanion.insert(
            id: 'cat-1',
            businessId: 'biz-1',
            categoryName: 'Beverages',
          ),
        );
        await repository.insertBrand(
          BrandsCompanion.insert(
            id: 'brand-1',
            businessId: 'biz-1',
            brandName: 'Coca-Cola',
          ),
        );
        await repository.insertUnit(
          UnitsCompanion.insert(
            id: 'unit-1',
            businessId: 'biz-1',
            unitName: 'Piece',
            unitSymbol: 'PC',
          ),
        );

        // Seed Product and ProductUnit via transactional creation
        await repository.createProductWithDetails(
          product: ProductsCompanion.insert(
            id: 'prod-1',
            businessId: 'biz-1',
            productCode: 'P001',
            productName: 'Coke 330ml',
            categoryId: const drift.Value('cat-1'),
            brandId: const drift.Value('brand-1'),
          ),
          units: [
            ProductUnitsCompanion.insert(
              id: 'pu-1',
              businessId: 'biz-1',
              productId: 'prod-1',
              unitId: 'unit-1',
              isBaseUnit: const drift.Value(true),
              sellingPrice: const drift.Value(100.0),
              purchasePrice: const drift.Value(80.0),
              minimumPrice: const drift.Value(85.0),
            ),
          ],
        );

        final prod = await repository.getProductByCode('biz-1', 'P001');
        expect(prod?.productName, 'Coke 330ml');

        // Check default effective price (no branch override)
        final baseEffective = await repository.getEffectiveProductUnitPrice(
          'pu-1',
          'biz-1',
        );
        expect(baseEffective?.sellingPrice, 100.0);
        expect(baseEffective?.isBranchOverride, false);

        // Add branch price override
        await repository.insertBranchProductPrice(
          BranchProductPricesCompanion.insert(
            id: 'bpp-1',
            businessId: 'biz-1',
            branchId: 'branch-1',
            productUnitId: 'pu-1',
            sellingPrice: const drift.Value(120.0),
            purchasePrice: const drift.Value(80.0),
            minimumPrice: const drift.Value(85.0),
          ),
        );

        // Check effective price with branchId
        final branchEffective = await repository.getEffectiveProductUnitPrice(
          'pu-1',
          'biz-1',
          branchId: 'branch-1',
        );
        expect(branchEffective?.sellingPrice, 120.0);
        expect(branchEffective?.isBranchOverride, true);
        expect(branchEffective?.branchId, 'branch-1');
      },
    );

    test(
      '3. RepositoryErrorGuard intercepting RecordNotFound / TenantScopingException',
      () async {
        expect(
          () => repository.insertCategory(
            CategoriesCompanion.insert(
              id: 'cat-invalid',
              businessId: '', // Empty invalid businessId
              categoryName: 'Invalid Category',
            ),
          ),
          throwsA(
            isA<RepositoryTenantScopeException>().having(
              (e) => e.toFailure(),
              'toFailure',
              isA<TenantScopeFailure>(),
            ),
          ),
        );
      },
    );
  });
}
