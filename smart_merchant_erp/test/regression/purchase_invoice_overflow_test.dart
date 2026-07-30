import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/modules/purchasing/presentation/widgets/purchase_invoice_modal.dart';

void main() {
  testWidgets('PurchaseInvoiceModal product search overflow regression test', (WidgetTester tester) async {
    // Set screen size to a narrow Android phone
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PurchaseInvoiceModal(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Find the product text field.
    final textField = find.byType(TextField).first;
    expect(textField, findsWidgets);

    // Enter text
    await tester.enterText(textField, 'منتج عربي طويل جدا جدا للتأكد من عدم وجود مشكلة في العرض أو تجاوز الحدود');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    
    // Reset sizes
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
