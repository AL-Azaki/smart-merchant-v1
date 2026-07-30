import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/sales/presentation/widgets/customer_add_modal.dart';
import 'package:smart_merchant_erp/app/di/getit_instance.dart';

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
}
