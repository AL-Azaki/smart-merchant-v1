import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/catalog/domain/models/catalog_product_item.dart';
import 'package:smart_merchant_erp/modules/catalog/domain/services/unit_quantity_formatter.dart';

void main() {
  group('Multi-Unit Stock & Conversion Engine Tests', () {
    const businessId = 'test-biz';
    const productId = 'prod-1';

    final basePiece = ProductUnit(
      id: 'unit-piece-id',
      businessId: businessId,
      productId: productId,
      unitId: 'def-piece',
      conversionFactor: 1.0,
      purchasePrice: 100.0,
      sellingPrice: 150.0,
      minimumPrice: 120.0,
      isBaseUnit: true,
      barcode: '628100000001',
      isActive: true,
      syncStatus: 'synced',
      version: 1,
    );

    final cartonUnit = ProductUnit(
      id: 'unit-carton-id',
      businessId: businessId,
      productId: productId,
      unitId: 'def-carton',
      conversionFactor: 12.0,
      purchasePrice: 1100.0,
      sellingPrice: 1600.0,
      minimumPrice: 1400.0,
      isBaseUnit: false,
      barcode: '628100000012',
      isActive: true,
      syncStatus: 'synced',
      version: 1,
    );

    String mockUnitResolver(String unitId) {
      if (unitId == 'def-carton') return 'كرتون';
      return 'حبة';
    }

    test('UnitQuantityFormatter formats hierarchical breakdown accurately', () {
      final units = [basePiece, cartonUnit];

      // 57 pieces = 4 cartons (48) + 9 pieces
      expect(
        UnitQuantityFormatter.formatBreakdown(
          baseQuantity: 57,
          units: units,
          unitNameResolver: mockUnitResolver,
        ),
        equals('4 كرتون و 9 حبة'),
      );

      // 24 pieces = exactly 2 cartons
      expect(
        UnitQuantityFormatter.formatBreakdown(
          baseQuantity: 24,
          units: units,
          unitNameResolver: mockUnitResolver,
        ),
        equals('2 كرتون'),
      );

      // 5 pieces = 5 pieces (no full carton)
      expect(
        UnitQuantityFormatter.formatBreakdown(
          baseQuantity: 5,
          units: units,
          unitNameResolver: mockUnitResolver,
        ),
        equals('5 حبة'),
      );

      // 0 pieces
      expect(
        UnitQuantityFormatter.formatBreakdown(
          baseQuantity: 0,
          units: units,
          unitNameResolver: mockUnitResolver,
        ),
        equals('0 حبة'),
      );
    });

    test('UnitQuantityFormatter computes quantityInUnit correctly', () {
      final breakdown = UnitQuantityFormatter.quantityInUnit(
        baseQuantity: 57,
        targetUnit: cartonUnit,
      );

      expect(breakdown.fullUnits, equals(4));
      expect(breakdown.remainderBase, equals(9.0));
      expect(breakdown.exactDecimal, equals(4.75));
    });

    test('UnitQuantityFormatter computes unit WAC correctly', () {
      final cartonWac = UnitQuantityFormatter.unitAverageCost(
        baseAverageCost: 95.5,
        targetUnit: cartonUnit,
      );

      expect(cartonWac, equals(95.5 * 12.0));
    });

    test('CatalogProductItem finds correct unit by barcode or SKU', () {
      final item = CatalogProductItem(
        product: Product(
          id: productId,
          businessId: businessId,
          productType: 'Standard',
          productCode: 'PRD-01',
          productName: 'حليب نادك 1 لتر',
          categoryId: 'cat-1',
          isActive: true,
          showInStore: true,
          syncStatus: 'synced',
          version: 1,
        ),
        baseUnit: basePiece,
        sellingPrice: 150.0,
        units: [basePiece, cartonUnit],
        stockQuantity: 57,
        baseAverageCost: 95.5,
      );

      // Scan Carton barcode
      final foundCarton = item.findUnitByBarcodeOrSku('628100000012');
      expect(foundCarton, isNotNull);
      expect(foundCarton!.id, equals('unit-carton-id'));
      expect(foundCarton.conversionFactor, equals(12.0));

      // Scan Piece barcode
      final foundPiece = item.findUnitByBarcodeOrSku('628100000001');
      expect(foundPiece, isNotNull);
      expect(foundPiece!.id, equals('unit-piece-id'));

      // Scan non-existing code
      final notFound = item.findUnitByBarcodeOrSku('999999999999');
      expect(notFound, isNull);

      // Available full units in carton
      expect(item.availableInUnit(cartonUnit), equals(4.0));
    });
  });
}
