import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/shared/utils/arabic_tafqeet.dart';

void main() {
  group('ArabicTafqeet Tests', () {
    test('converts zero correctly', () {
      final result = ArabicTafqeet.convert(0, currencyName: 'ريال يمني');
      expect(result, 'فقط صفر ريال يمني لا غير');
    });

    test('converts single digit numbers', () {
      final result = ArabicTafqeet.convert(5, currencyName: 'ريال يمني');
      expect(result, 'فقط خمسة ريال يمني لا غير');
    });

    test('converts teens', () {
      final result = ArabicTafqeet.convert(15, currencyName: 'ريال يمني');
      expect(result, 'فقط خمسة عشر ريال يمني لا غير');
    });

    test('converts tens and hundreds', () {
      final result = ArabicTafqeet.convert(150, currencyName: 'ريال يمني');
      expect(result, 'فقط مائة وخمسون ريال يمني لا غير');
    });

    test('converts thousands', () {
      final result = ArabicTafqeet.convert(5000, currencyName: 'ريال يمني');
      expect(result, 'فقط خمسة آلاف ريال يمني لا غير');
    });

    test('converts large invoice amounts', () {
      final result = ArabicTafqeet.convert(25500, currencyName: 'ريال يمني');
      expect(result, 'فقط خمسة وعشرون ألفاً وخمسمائة ريال يمني لا غير');
    });

    test('converts millions', () {
      final result = ArabicTafqeet.convert(1000000, currencyName: 'ريال يمني');
      expect(result, 'فقط مليون ريال يمني لا غير');
    });
  });
}
