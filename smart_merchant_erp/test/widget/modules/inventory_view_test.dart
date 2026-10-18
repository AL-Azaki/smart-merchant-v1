import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/catalog/domain/models/catalog_product_item.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/providers/product_list_filters.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/providers/product_image_provider.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/views/widgets/product_thumbnail.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/views/widgets/products_table.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/views/widgets/catalog_formatters.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/providers/inventory_provider.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/providers/stock_counts_provider.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/inventory_module_view.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/inventory_workspace_view.dart';
import 'catalog_entry_test.dart' as fixture;

class EmptyCounts extends StockCountsNotifier {
  @override
  Stream<List<StockCount>> build() => Stream.value([]);
}

CatalogProductItem item(String name, double quantity, double price) =>
    CatalogProductItem(
      product: fixture.product.copyWith(id: name, productName: name),
      baseUnit: fixture.baseUnit,
      units: const [fixture.baseUnit],
      sellingPrice: price,
      stockQuantity: quantity,
    );

void main() {
  test('Arabic labels stay compact while custom names remain intact', () {
    expect(catalogDisplayName('Piece / حبة'), 'حبة');
    expect(catalogDisplayName('مواد غذائية / Groceries'), 'مواد غذائية');
    expect(catalogDisplayName('قسم أول / قسم ثان'), 'قسم أول / قسم ثان');
    expect(catalogDisplayName('A/B/C'), 'A/B/C');
  });
  testWidgets(
    'Product thumbnail loads a local photo and handles a missing file',
    (tester) async {
      late Directory directory;
      late File photo;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('catalog-photo-');
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 4, 4),
          Paint()..color = Colors.indigo,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(4, 4);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        photo = await File(
          '${directory.path}/photo.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      });
      addTearDown(() => directory.delete(recursive: true));
      await tester.runAsync(() async {
        await fixture.mount(
          tester,
          const Center(
            child: ProductThumbnail(productId: 'photo', name: 'منتج'),
          ),
          theme: ThemeData(useMaterial3: true),
          overrides: [
            productImagePathProvider(
              'photo',
            ).overrideWith((ref) => Stream.value(photo.path)),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsOneWidget);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        await fixture.mount(
          tester,
          const Center(
            child: ProductThumbnail(productId: 'missing', name: 'منتج'),
          ),
          theme: ThemeData(useMaterial3: true),
          overrides: [
            productImagePathProvider('missing').overrideWith(
              (ref) => Stream.value('${directory.path}/missing.png'),
            ),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Search and stock filters preserve barcode scanning and sort a copy',
    () {
      final products = [
        item('رز', 0, 100),
        item('حليب', 3, 200),
        item('تمر', 8, 150),
      ];
      expect(
        filterCatalogProducts(products, query: ' 123456789 '),
        hasLength(3),
      );
      expect(
        filterCatalogProducts(products, query: 'حليب').single.stockQuantity,
        3,
      );
      expect(
        filterCatalogProducts(products, query: 'حبة', unitName: (_) => 'حبة'),
        hasLength(3),
      );
      expect(
        filterCatalogProducts(
          products,
          query: '',
          stock: ProductStockFilter.low,
        ).single.product.productName,
        'حليب',
      );
      expect(
        filterCatalogProducts(
          products,
          query: '',
          stock: ProductStockFilter.empty,
        ).single.product.productName,
        'رز',
      );
      expect(
        filterCatalogProducts(
          products,
          query: '',
          sort: ProductSort.priceHigh,
        ).first.sellingPrice,
        200,
      );
      expect(products.first.product.productName, 'رز');
    },
  );

  testWidgets('Inventory has four main tabs and hides product codes', (
    tester,
  ) async {
    await fixture.mount(tester, const InventoryModuleView());
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs, hasLength(4));
    expect(find.text('المخزن والجرد'), findsOneWidget);
    expect(find.text(fixture.product.productName), findsOneWidget);
    expect(find.text('CODE-HIDDEN'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(1024, 768), const Size(390, 844)]) {
    testWidgets('Workspace switches all three operations at $size', (
      tester,
    ) async {
      await fixture.mount(
        tester,
        const InventoryWorkspaceView(),
        size: size,
        overrides: [
          stockCountsNotifierProvider.overrideWith(EmptyCounts.new),
          warehouseTransfersStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          stockAdjustmentsListProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      expect(find.text('جرد جديد'), findsOneWidget);
      await tester.tap(find.text('التحويلات'));
      await tester.pumpAndSettle();
      expect(find.text('تحويل مخزني جديد'), findsOneWidget);
      await tester.tap(find.text('التسويات'));
      await tester.pumpAndSettle();
      expect(find.text('جرد تصحيحي جديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Main and operation tabs remain independent and preserve product search',
    (tester) async {
      await fixture.mount(
        tester,
        const InventoryModuleView(),
        overrides: [
          stockCountsNotifierProvider.overrideWith(EmptyCounts.new),
          warehouseTransfersStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          stockAdjustmentsListProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      await tester.enterText(find.byType(TextField).first, 'حليب');
      await tester.tap(find.text('المخزن والجرد'));
      await tester.pumpAndSettle();
      expect(find.text('جرد جديد'), findsOneWidget);
      await tester.tap(find.text('التحويلات'));
      await tester.pumpAndSettle();
      expect(find.text('تحويل مخزني جديد'), findsOneWidget);
      await tester.tap(find.text('المنتجات').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'حليب',
      );
      expect(find.text(fixture.product.productName), findsOneWidget);
      await tester.tap(find.text('المخزن والجرد'));
      await tester.pumpAndSettle();
      expect(find.text('تحويل مخزني جديد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A thousand products build lazily and table actions target the row',
    (tester) async {
      final products = List.generate(
        1000,
        (i) => item('منتج ${i.toString().padLeft(4, '0')}', 8, 150),
      );
      ProductAction? selectedAction;
      String? selectedProduct;
      await fixture.mount(
        tester,
        ProductsTable(
          products: products,
          categories: const {},
          unitName: (_) => 'حبة',
          priceLabel: (_) => '150 ر.ي',
          sort: ProductSort.name,
          onSort: (_) {},
          onAction: (p, action) {
            selectedAction = action;
            selectedProduct = p.product.id;
          },
        ),
      );
      expect(find.text('منتج 0000'), findsOneWidget);
      expect(find.text('منتج 0999'), findsNothing);
      expect(find.byTooltip('تعديل المنتج').evaluate().length, lessThan(30));
      await tester.tap(find.byTooltip('تعديل المنتج').first);
      expect(selectedAction, ProductAction.edit);
      expect(selectedProduct, 'منتج 0000');
      expect(tester.takeException(), isNull);
    },
  );
}
