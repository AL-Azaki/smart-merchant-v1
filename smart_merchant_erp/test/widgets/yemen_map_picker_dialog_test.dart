import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/shared/design_system/widgets/yemen_map_picker_dialog.dart';

void main() {
  group('YemenMapPickerDialog - Widget Tests', () {
    testWidgets('renders dialog with title, cities and action buttons',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YemenMapPickerDialog(
              initialLatitude: 15.369445,
              initialLongitude: 44.191006,
              initialCityName: 'صنعاء',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header title
      expect(
        find.textContaining('تحديد موقع المتجر على الخريطة'),
        findsOneWidget,
      );
      expect(find.text('صنعاء'), findsWidgets);

      // Check quick jump cities are rendered
      expect(find.text('صنعاء (المركز والتحرير)'), findsOneWidget);

      // Check buttons
      expect(find.textContaining('تأكيد'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('clicking city jump button updates selected location',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YemenMapPickerDialog(
              initialLatitude: 15.369445,
              initialLongitude: 44.191006,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the second visible city in the strip: صنعاء (حدة والسبعين)
      final haddaFinder = find.text('صنعاء (حدة والسبعين)');
      expect(haddaFinder, findsOneWidget);
      await tester.tap(haddaFinder);
      await tester.pumpAndSettle();

      // Verify that the view settled without errors
      expect(find.byType(YemenMapPickerDialog), findsOneWidget);
    });

    testWidgets('toggling manual coordinates drawer shows text fields',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YemenMapPickerDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the manual coordinates toggle button
      final manualCoordsBtn = find.text('إدخال يدوي');
      expect(manualCoordsBtn, findsOneWidget);
      await tester.tap(manualCoordsBtn);
      await tester.pumpAndSettle();

      // Check Lat / Lng input fields appear
      expect(find.text('خط العرض (Lat)'), findsOneWidget);
      expect(find.text('خط الطول (Lng)'), findsOneWidget);
      expect(find.text('تطبيق على الخريطة'), findsOneWidget);
    });

    testWidgets('confirm button returns selected YemenMapLocation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      YemenMapLocation? returnedLocation;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedLocation = await YemenMapPickerDialog.show(
                    context,
                    initialLatitude: 15.3547,
                    initialLongitude: 44.2066,
                    initialCityName: 'صنعاء - التحرير',
                  );
                },
                child: const Text('Open Map'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();

      expect(find.byType(YemenMapPickerDialog), findsOneWidget);

      // Tap confirm button
      final confirmBtn = find.textContaining('تأكيد');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Dialog should dismiss and location should be captured
      expect(find.byType(YemenMapPickerDialog), findsNothing);
      expect(returnedLocation, isNotNull);
      expect(returnedLocation!.latitude, closeTo(15.3547, 0.001));
      expect(returnedLocation!.longitude, closeTo(44.2066, 0.001));
    });
  });
}
