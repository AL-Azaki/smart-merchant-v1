import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/customer_add_modal.dart';

void main() {
  testWidgets('Customer Add Modal accepts Arabic text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomerAddModal(),
          ),
        ),
      ),
    );

    final nameField = find.byType(TextField).first;

    const arabicText = 'بشير العزكي';
    await tester.enterText(nameField, arabicText);
    await tester.pump();

    final TextField textFieldWidget = tester.widget(nameField);
    expect(textFieldWidget.controller?.text, arabicText);
  });

  testWidgets('CustomerAddModal renders inside showDialog without missing Material exception', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const CustomerAddModal(),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerAddModal), findsOneWidget);
    expect(find.text('إضافة عميل جديد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CustomerAddModal.show opens centered dialog without exceptions and email field is hidden', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CustomerAddModal.show(context),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerAddModal), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('إضافة عميل جديد'), findsOneWidget);
    // البريد الإلكتروني مخفي من الواجهة
    expect(find.text('البريد الإلكتروني (اختياري)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
