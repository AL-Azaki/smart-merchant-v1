import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/views/inventory_module_view.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/providers/catalog_provider.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart'
    show Product;

class MockProductsNotifier extends AutoDisposeStreamNotifier<List<Product>>
    implements ProductsNotifier {
  final List<Product> _mockProducts;
  MockProductsNotifier(this._mockProducts);

  @override
  Stream<List<Product>> build() => Stream.value(_mockProducts);

  @override
  Future<String?> saveProduct(Map<String, dynamic> data) async {
    return null;
  }

  @override
  Future<void> deleteProduct(String id) async {}
}

void main() {
  testWidgets('InventoryModuleView renders correctly with tabs', (
    WidgetTester tester,
  ) async {
    final mockProduct = Product(
      id: '1',
      businessId: 'b1',
      productCode: 'P01',
      productName: 'منتج تجريبي 1',
      productType: 'standard',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: 'synced',
      version: 1,
      showInStore: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productsNotifierProvider.overrideWith(
            () => MockProductsNotifier([mockProduct]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ar'), Locale('en')],
          locale: Locale('ar'),
          home: Scaffold(body: InventoryModuleView()),
        ),
      ),
    );

    // Wait for the stream to emit
    await tester.pumpAndSettle();

    // Verify tabs render
    expect(find.text('المنتجات'), findsWidgets);
    expect(find.text('المشتريات'), findsWidgets);

    // Verify products view loads mock product
    expect(find.text('منتج تجريبي 1'), findsOneWidget);
    expect(find.text('P01'), findsOneWidget);
  });
}
