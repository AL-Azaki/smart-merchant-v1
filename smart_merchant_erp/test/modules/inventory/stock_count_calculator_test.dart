import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/modules/inventory/presentation/widgets/count_quantity_row.dart';

void main() {
  group('Stock Count Quantity Evaluator Tests', () {
    test('parses direct numbers', () {
      expect(parseCountQuantity('10'), 10.0);
      expect(parseCountQuantity('25.5'), 25.5);
      expect(parseCountQuantity('0'), 0.0);
    });

    test('parses Arabic digits', () {
      expect(parseCountQuantity('١٠'), 10.0);
      expect(parseCountQuantity('٢٥٫٥'), 25.5);
    });

    test('parses multiplication expression (packages * factor)', () {
      expect(parseCountQuantity('3*12'), 36.0);
      expect(parseCountQuantity('5 × 10'), 50.0);
      expect(parseCountQuantity('2x24'), 48.0);
    });

    test('parses combined expression (packages * factor + loose pieces)', () {
      expect(parseCountQuantity('2*12+6'), 30.0);
      expect(parseCountQuantity('4 × 24 + 5'), 101.0);
      expect(parseCountQuantity('٢*١٢+٦'), 30.0);
      expect(parseCountQuantity('10 + 20'), 30.0);
    });

    test('rejects invalid inputs safely', () {
      expect(parseCountQuantity(''), isNull);
      expect(parseCountQuantity('abc'), isNull);
      expect(parseCountQuantity('-5'), isNull);
      expect(parseCountQuantity('2*-5'), isNull);
    });
  });
}

