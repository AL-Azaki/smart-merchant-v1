import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/core/utils/precision_math.dart';

void main() {
  group('PrecisionMath Financial Precision Tests', () {
    test('يجب معالجة خطأ IEEE 754 في جمع الفواصل العشرية بدقة', () {
      // في دارت: 0.1 + 0.2 = 0.30000000000000004
      const double rawSum = 0.1 + 0.2;
      expect(rawSum, isNot(equals(0.3))); // إثبات وجود المشكلة في دارت الخام

      // باستخدام PrecisionMath يجب أن تقرب إلى 0.30 بالضبط
      final rounded = PrecisionMath.roundMoney(rawSum);
      expect(rounded, equals(0.3));
      expect(rounded.toStringAsFixed(2), equals('0.30'));
    });

    test('يجب تقريب الكميات إلى 3 منازل عشرية بدقة', () {
      final qty = PrecisionMath.roundQuantity(1.33333333);
      expect(qty, equals(1.333));
    });

    test('فحص اتزان المدين والدائن مع استبعاد الفوارق الميكروسكوبية', () {
      expect(PrecisionMath.areBalanced(100.0, 100.0), isTrue);
      expect(PrecisionMath.areBalanced(100.001, 100.002), isTrue); // ضمن حد التسامح (0.005)
      expect(PrecisionMath.areBalanced(100.0, 100.01), isFalse); // فارق قرش كامل (غير متزن)
      expect(PrecisionMath.areBalanced(15000.0, 14999.0), isFalse);
    });

    test('توزيع الخصم الإجمالي على الأسطر يجب أن يضمن مطابقة المجموع بدون ضياع فلس واحد', () {
      // 3 أسطر بمبالغ: 100، 200، 300 (الإجمالي 600)
      // الخصم الإجمالي المراد توزيعه: 50 ريال
      final distributed = PrecisionMath.distributeProportionally(
        lineAmounts: [100.0, 200.0, 300.0],
        totalToDistribute: 50.0,
      );

      expect(distributed.length, 3);

      // مجموع الخصومات الموزعة يجب أن يساوي بالضبط 50.0
      final totalDistributed = distributed.fold(0.0, (sum, val) => sum + val);
      expect(PrecisionMath.roundMoney(totalDistributed), equals(50.0));

      // السطر الأول (100 / 600 * 50 = 8.33)
      expect(distributed[0], equals(8.33));
      // السطر الثاني (200 / 600 * 50 = 16.67)
      expect(distributed[1], equals(16.67));
      // السطر الثالث (يستوعب الباقي لضمان 50 بالضبط: 50 - 8.33 - 16.67 = 25.00)
      expect(distributed[2], equals(25.0));
    });
  });
}
