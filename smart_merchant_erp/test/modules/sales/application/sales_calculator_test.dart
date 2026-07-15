import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/sales/application/sales_calculator.dart';

void main() {
  group('SalesCalculator Business Logic Tests -', () {
    
    test('يجب أن يعالج مشكلة الفواصل العشرية (Floating Point Precision) بشكل صحيح', () {
      // في البرمجة العادية: 10.99 * 3 = 32.970000000000006
      final items = [
        SalesItem(quantity: 3, unitPrice: 10.99),
      ];

      final totals = SalesCalculator.calculate(items: items);

      // يجب أن يكون الناتج 32.97 بالضبط بدون أعشار خاطئة
      expect(totals.rawSubtotal, equals(32.97));
      expect(totals.grandTotal, equals(32.97));
    });

    test('يجب أن يحسب الضريبة بشكل قانوني بعد خصم جميع التخفيضات (النسبة المئوية)', () {
      final items = [
        SalesItem(quantity: 2, unitPrice: 50.00, taxRate: 0.15), // المجموع 100
      ];

      // خصم شامل 10%
      final totals = SalesCalculator.calculate(
        items: items, 
        globalDiscountValue: 10, 
        isGlobalDiscountPercentage: true,
      );

      // المجموع 100
      expect(totals.rawSubtotal, equals(100.00));
      // خصم 10% = 10
      expect(totals.totalDiscount, equals(10.00));
      // المبلغ الخاضع للضريبة (100 - 10) = 90
      expect(totals.taxableAmount, equals(90.00));
      // الضريبة (15% من 90) = 13.5
      expect(totals.taxTotal, equals(13.50));
      // الإجمالي (90 + 13.5) = 103.5
      expect(totals.grandTotal, equals(103.50));
    });
  });
}
