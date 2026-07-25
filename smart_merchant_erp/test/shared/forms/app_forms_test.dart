import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/shared/forms/app_field_config.dart';
import 'package:smart_merchant_erp/shared/forms/app_validators.dart';
import 'package:smart_merchant_erp/shared/forms/app_input_formatters.dart';

void main() {
  group('AppValidators', () {
    test('humanName validates properly', () {
      // Valid Arabic
      expect(AppValidators.humanName('بشير العزكي'), isNull);
      expect(AppValidators.humanName('مؤسسة Smart Merchant للتجارة'), isNull);
      
      // Valid English
      expect(AppValidators.humanName('Bashir Al-Azaki'), isNull);
      
      // Invalid (too short)
      expect(AppValidators.humanName('أ'), isNotNull);
    });

    test('required validates properly', () {
      expect(AppValidators.required(' '), isNotNull);
      expect(AppValidators.required(''), isNotNull);
      expect(AppValidators.required('text'), isNull);
    });
  });

  group('AppFieldConfig', () {
    test('humanName maps correctly', () {
      final config = AppFieldConfig.fromType(AppFieldType.humanName);
      
      expect(config.inputFormatters, isNull);
    });

    test('phone maps correctly', () {
      final config = AppFieldConfig.fromType(AppFieldType.phone);
      
      expect(config.inputFormatters, isNotEmpty);
      expect(config.inputFormatters!.contains(AppInputFormatters.phone), isTrue);
    });
    
    test('username/barcode applies englishOnly', () {
      final config = AppFieldConfig.fromType(AppFieldType.barcode);
      expect(config.inputFormatters, isNotEmpty);
      expect(config.inputFormatters!.contains(AppInputFormatters.englishOnly), isTrue);
    });
  });
}
