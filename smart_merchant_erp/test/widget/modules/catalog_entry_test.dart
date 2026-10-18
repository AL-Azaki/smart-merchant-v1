import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/providers/catalog_provider.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/views/products_view.dart';
import 'package:smart_merchant_erp/modules/catalog/presentation/views/widgets/product_form_sheet.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/providers/inventory_provider.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/providers/purchasing_provider.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/providers/product_unit_provider.dart';
import 'package:smart_merchant_erp/shared/design_system/theme/app_theme.dart';
import 'package:smart_merchant_erp/shared/design_system/widgets/app_text_field.dart';

const category = Category(
  id: 'cat',
  businessId: 'business',
  categoryName: 'مواد غذائية',
  sortOrder: 0,
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const piece = Unit(
  id: 'piece',
  businessId: 'business',
  unitName: 'حبة',
  unitSymbol: 'pc',
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const carton = Unit(
  id: 'carton',
  businessId: 'business',
  unitName: 'كرتون',
  unitSymbol: 'box',
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const currency = CurrencyEntity(
  id: 'yer',
  currencyCode: 'YER',
  currencyNameAr: 'ريال يمني',
  currencyNameEn: 'Yemeni rial',
  currencySymbol: 'ر.ي',
  decimalPlaces: 2,
  exchangeRate: 1,
  isBaseCurrency: true,
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const warehouse = Warehouse(
  id: 'warehouse',
  businessId: 'business',
  branchId: 'branch',
  warehouseName: 'المستودع الرئيسي',
  warehouseCode: 'WH',
  isDefault: true,
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const baseUnit = ProductUnit(
  id: 'pu',
  businessId: 'business',
  productId: 'product',
  unitId: 'piece',
  barcode: '123456789',
  sku: 'SKU-HIDDEN',
  conversionFactor: 1,
  purchasePrice: 100,
  sellingPrice: 150,
  minimumPrice: 0,
  isBaseUnit: true,
  isActive: true,
  syncStatus: 'synced',
  version: 1,
);
const product = Product(
  id: 'product',
  businessId: 'business',
  categoryId: 'cat',
  productCode: 'CODE-HIDDEN',
  productName: 'حليب كامل الدسم طويل الاسم للاختبار',
  productType: 'standard',
  isActive: true,
  showInStore: false,
  syncStatus: 'synced',
  version: 1,
);

class Categories extends CategoriesNotifier {
  @override
  Stream<List<Category>> build() => Stream.value([category]);
}

class Units extends UnitsNotifier {
  @override
  Stream<List<Unit>> build() => Stream.value([carton, piece]);
}

class Products extends PosProductsNotifier {
  @override
  Stream<List<PosProductItem>> build() => Stream.value([
    const PosProductItem(
      product: product,
      baseUnit: baseUnit,
      units: [baseUnit],
      sellingPrice: 150,
      stockQuantity: 8,
    ),
  ]);
}

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1024, 768),
  bool dark = false,
  double scale = 1,
  double keyboard = 0,
  List<Override> overrides = const [],
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesNotifierProvider.overrideWith(Categories.new),
        unitsNotifierProvider.overrideWith(Units.new),
        posProductsNotifierProvider.overrideWith(Products.new),
        activeWarehousesProvider.overrideWith((ref) async => [warehouse]),
        availableCurrenciesFutureProvider.overrideWith(
          (ref) async => [currency],
        ),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: theme ?? (dark ? AppTheme.darkTheme : AppTheme.lightTheme),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder field(String label) => find.descendant(
  of: find.widgetWithText(AppTextField, label),
  matching: find.byType(TextFormField),
);

Widget form({
  required Future<void> Function(Map<String, dynamic>) save,
  Future<void> Function(Map<String, dynamic>)? repeat,
  bool hideStock = false,
}) => Dialog(
  insetPadding: const EdgeInsets.all(16),
  child: ProductFormSheet(
    initialCategoryId: 'cat',
    onClose: () {},
    onSave: save,
    onSaveAndAdd: repeat,
    hideOpeningStock: hideStock,
  ),
);

void main() {
  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(390, 844),
    const Size(320, 740),
  ]) {
    testWidgets('Simple catalogue and form fit $size in Arabic', (
      tester,
    ) async {
      await mount(tester, const ProductsView(), size: size);
      expect(tester.takeException(), isNull);
      expect(find.text(product.productName), findsOneWidget);
      expect(find.text('CODE-HIDDEN'), findsNothing);
      expect(find.text('SKU-HIDDEN'), findsNothing);
      expect(find.text('123456789'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '123456789');
      await tester.pumpAndSettle();
      expect(find.text(product.productName), findsOneWidget);
      await tester.tap(find.text('إضافة منتج'));
      await tester.pumpAndSettle();
      expect(find.text('حفظ وإضافة التالي'), findsOneWidget);
      expect(field('الباركود').hitTestable(), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Repeated save awaits success, prevents duplicates and retains defaults',
    (tester) async {
      final pending = Completer<void>();
      final saved = <Map<String, dynamic>>[];
      await mount(
        tester,
        form(
          save: (_) async {},
          repeat: (data) async {
            saved.add(data);
            await pending.future;
          },
        ),
      );
      await tester.enterText(field('اسم المنتج *'), 'أرز');
      await tester.enterText(field('سعر البيع *'), '350');
      await tester.enterText(field('الكمية الافتتاحية'), '12');
      await tester.tap(find.text('حفظ وإضافة التالي'));
      await tester.pump();
      expect(saved, hasLength(1));
      expect(saved.single['unit_id'], 'piece');
      expect(saved.single['currency_id'], 'yer');
      expect(saved.single['opening_warehouse_id'], 'warehouse');
      expect(saved.single['opening_quantity'], '12');
      expect(saved.single['category_id'], 'cat');
      expect(saved.single['barcode'], isNull);
      expect(
        find.widgetWithText(ElevatedButton, 'حفظ وإضافة التالي'),
        findsNothing,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(field('اسم المنتج *')).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(field('سعر البيع *')).controller!.text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextFormField>(field('الكمية الافتتاحية'))
            .controller!
            .text,
        '0',
      );
      expect(find.text('تم حفظ 1 منتج • جاهز للمنتج التالي'), findsOneWidget);
      await tester.enterText(field('اسم المنتج *'), 'سكر');
      await tester.enterText(field('سعر البيع *'), '500');
      await tester.tap(find.text('حفظ وإضافة التالي'));
      await tester.pumpAndSettle();
      expect(saved, hasLength(2));
      expect(saved.last['category_id'], 'cat');
      expect(saved.last['unit_id'], 'piece');
      expect(saved.last['opening_quantity'], '0');
      expect(saved.last['barcode'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Failure retains entered product and allows retry', (
    tester,
  ) async {
    var calls = 0;
    await mount(
      tester,
      form(
        save: (_) async {},
        repeat: (_) async {
          calls++;
          if (calls == 1) {
            throw StateError('failed');
          }
        },
      ),
    );
    await tester.enterText(field('اسم المنتج *'), 'قهوة');
    await tester.enterText(field('سعر البيع *'), '1500');
    await tester.tap(find.text('حفظ وإضافة التالي'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('اسم المنتج *')).controller!.text,
      'قهوة',
    );
    expect(
      find.text('تعذر حفظ المنتج. بياناتك محفوظة هنا، حاول مرة أخرى.'),
      findsOneWidget,
    );
    await tester.tap(find.text('حفظ وإضافة التالي'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(
      tester.widget<TextFormField>(field('اسم المنتج *')).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Required fields validate and purchasing can hide opening stock',
    (tester) async {
      var saved = false;
      await mount(
        tester,
        form(
          save: (_) async {
            saved = true;
          },
          hideStock: true,
        ),
      );
      expect(find.text('الكمية الافتتاحية'), findsNothing);
      await tester.tap(find.text('حفظ المنتج'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل اسم المنتج'), findsOneWidget);
      expect(find.text('أدخل سعر البيع'), findsOneWidget);
      expect(saved, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tablet keyboard and dark large text keep save accessible', (
    tester,
  ) async {
    await mount(
      tester,
      form(save: (_) async {}, repeat: (_) async {}),
      dark: true,
      scale: 1.3,
      keyboard: 300,
    );
    expect(find.text('حفظ وإضافة التالي').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
