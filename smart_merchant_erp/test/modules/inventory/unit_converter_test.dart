import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/inventory/application/unit_converter.dart';

void main() {
  group('UnitConverter Packaging & Multiplier Tests', () {
    test('تحويل الكمية المدخلة بالكرتون إلى وحدة الأساس (حبة)', () {
      // 5 كراتين عصير، معامل التحويل 24 حبة للكرتون
      final baseQty = UnitConverter.toBaseQuantity(
        enteredQuantity: 5.0,
        conversionFactor: 24.0,
      );

      // 5 * 24 = 120 حبة
      expect(baseQty, equals(120.0));
    });

    test('تحويل كمية الأساس (حبة) إلى كراتين', () {
      // 72 حبة / 24 = 3 كراتين
      final boxQty = UnitConverter.fromBaseQuantity(
        baseQuantity: 72.0,
        conversionFactor: 24.0,
      );

      expect(boxQty, equals(3.0));
    });

    test('تحويل تكلفة وحدة الأساس إلى تكلفة الكرتون', () {
      // تكلفة الحبة 150 ريال * 24 = 3,600 ريال للكرتون
      final cartonCost = UnitConverter.toUnitCost(
        baseUnitCost: 150.0,
        conversionFactor: 24.0,
      );

      expect(cartonCost, equals(3600.0));
    });

    test('تحويل سعر شراء الكرتون إلى تكلفة وحدة الأساس الواحدة', () {
      // كرتون تم شراؤه بـ 3,600 ريال / 24 = 150 ريال للحبة
      final baseCost = UnitConverter.toBaseUnitCost(
        packageUnitCost: 3600.0,
        conversionFactor: 24.0,
      );

      expect(baseCost, equals(150.0));
    });

    test('رمي استثناء عند إدخال معامل تحويل صفر أو سالب', () {
      expect(
        () => UnitConverter.toBaseQuantity(enteredQuantity: 10, conversionFactor: 0),
        throwsArgumentError,
      );
      expect(
        () => UnitConverter.toBaseQuantity(enteredQuantity: 10, conversionFactor: -1),
        throwsArgumentError,
      );
    });
  });
}
