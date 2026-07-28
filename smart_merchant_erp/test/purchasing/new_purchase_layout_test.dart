import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/views/new_purchase_view.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/providers/purchasing_provider.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/product_unit_provider.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

class FakeSuppliersNotifier extends SuppliersNotifier {
  @override
  Stream<List<Supplier>> build() => Stream.value([]);
}

class FakePosProductsNotifier extends PosProductsNotifier {
  @override
  Stream<List<PosProductItem>> build() => Stream.value([]);
}

void main() {
  testWidgets('NewPurchaseView renders correctly on small screen (320px) without overflow', (WidgetTester tester) async {
    // Set screen size to a narrow mobile device
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppliersNotifierProvider.overrideWith(() => FakeSuppliersNotifier()),
          posProductsNotifierProvider.overrideWith(() => FakePosProductsNotifier()),
          activeWarehousesStreamProvider.overrideWith((ref) => Stream.value([])),
          availableCurrenciesFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NewPurchaseView(
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title exists
    expect(find.text('فاتورة مشتريات (إدخال سريع)'), findsOneWidget);

    // Verify main components are present
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.text('الباركود/SKU'), findsOneWidget); // Table Header

    // Ensure no exceptions were thrown during layout (pumpAndSettle would fail if there were RenderFlex overflows that throw exceptions in tests, though in some configurations they only print. To be safe we check tester.takeException)
    expect(tester.takeException(), isNull);
    
    // Reset window size
    addTearDown(tester.view.resetPhysicalSize);
  });
  
  testWidgets('NewPurchaseView renders correctly on large screen (1024px) without overflow', (WidgetTester tester) async {
    // Set screen size to a desktop/tablet device
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suppliersNotifierProvider.overrideWith(() => FakeSuppliersNotifier()),
          posProductsNotifierProvider.overrideWith(() => FakePosProductsNotifier()),
          activeWarehousesStreamProvider.overrideWith((ref) => Stream.value([])),
          availableCurrenciesFutureProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NewPurchaseView(
              onBack: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('فاتورة مشتريات (إدخال سريع)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    
    addTearDown(tester.view.resetPhysicalSize);
  });
}
