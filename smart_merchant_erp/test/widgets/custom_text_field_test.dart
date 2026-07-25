import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/shared/design_system/widgets/custom_text_field.dart';

void main() {
  testWidgets('CustomTextField allows Arabic text input by default', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Test',
            controller: controller,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'بشير العزكي');
    await tester.pump();

    expect(controller.text, 'بشير العزكي');
  });
}
