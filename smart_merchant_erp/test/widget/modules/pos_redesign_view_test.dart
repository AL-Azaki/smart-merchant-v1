import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/views/pos_view.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/quick_checkout_bar.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/pos_cart_panel.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/pos_products_grid.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/product_unit_provider.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

void main() {
  Widget createTestWidget({
    required Size screenSize,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const Scaffold(body: PosView()),
        ),
      ),
    );
  }

  testWidgets('POS View renders dual-column split layout on Tablet dimensions',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createTestWidget(
        screenSize: const Size(1200, 800),
        overrides: [
          posProductsNotifierProvider.overrideWith(
            () => _FakePosProductsNotifier(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Verify both Products Grid and Cart Panel are present on wide screen
    expect(find.byType(PosProductsGrid), findsOneWidget);
    expect(find.byType(PosCartPanel), findsOneWidget);
    expect(find.byType(QuickCheckoutBar), findsOneWidget);
    expect(find.text('كاش فوري'), findsOneWidget);
    expect(find.text('شبكة'), findsOneWidget);
    expect(find.text('كاشير التجزئة السريع'), findsOneWidget);
  });

  testWidgets('POS View renders mobile layout on phone screen dimensions',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      createTestWidget(
        screenSize: const Size(400, 800),
        overrides: [
          posProductsNotifierProvider.overrideWith(
            () => _FakePosProductsNotifier(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // In mobile portrait, products grid is full screen
    expect(find.byType(PosProductsGrid), findsOneWidget);
    // Cart panel is not docked on mobile
    expect(find.byType(PosCartPanel), findsNothing);
  });
}

class _FakePosProductsNotifier extends PosProductsNotifier {
  @override
  Stream<List<PosProductItem>> build() async* {
    yield [
      const PosProductItem(
        product: Product(
          id: 'prod-1',
          businessId: 'BUS_A',
          productType: 'standard',
          productCode: 'PRD-01',
          productName: 'عصير برتقال طبيعي',
          isActive: true,
          showInStore: true,
          syncStatus: 'synced',
          version: 1,
        ),
        baseUnit: ProductUnit(
          id: 'unit-1',
          businessId: 'BUS_A',
          productId: 'prod-1',
          unitId: 'u-piece',
          conversionFactor: 1.0,
          purchasePrice: 400.0,
          sellingPrice: 500.0,
          minimumPrice: 450.0,
          isBaseUnit: true,
          isActive: true,
          syncStatus: 'synced',
          version: 1,
        ),
        sellingPrice: 500.0,
        units: [
          ProductUnit(
            id: 'unit-1',
            businessId: 'BUS_A',
            productId: 'prod-1',
            unitId: 'u-piece',
            conversionFactor: 1.0,
            purchasePrice: 400.0,
            sellingPrice: 500.0,
            minimumPrice: 450.0,
            isBaseUnit: true,
            isActive: true,
            syncStatus: 'synced',
            version: 1,
          ),
        ],
      ),
    ];
  }
}
