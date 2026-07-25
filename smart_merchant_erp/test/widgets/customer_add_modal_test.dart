import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/customer_add_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Print CustomerAddModal TextFormField properties', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CustomerAddModal()),
        ),
      ),
    );

    expect(find.byType(CustomerAddModal), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
