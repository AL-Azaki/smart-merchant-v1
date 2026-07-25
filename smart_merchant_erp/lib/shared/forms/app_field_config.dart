import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_validators.dart';
import 'app_input_formatters.dart';

enum AppFieldType {
  humanName,
  businessName,
  generalText,
  email,
  phone,
  password,
  integer,
  decimal,
  percentage,
  sku,
  barcode,
  search,
}

class AppFieldConfig {
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const AppFieldConfig({
    required this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  factory AppFieldConfig.fromType(AppFieldType type, {bool required = false}) {
    List<TextInputFormatter>? formatters;
    TextInputType keyboardType = TextInputType.text;
    List<String? Function(String?)> validators = [];

    if (required) {
      validators.add(AppValidators.required);
    }

    switch (type) {
      case AppFieldType.humanName:
        keyboardType = TextInputType.name;
        validators.add(AppValidators.humanName);
        break;
      case AppFieldType.businessName:
      case AppFieldType.generalText:
      case AppFieldType.search:
        keyboardType = TextInputType.text;
        // Allows any Unicode characters safely.
        break;
      case AppFieldType.email:
        keyboardType = TextInputType.emailAddress;
        validators.add(AppValidators.email);
        break;
      case AppFieldType.phone:
        keyboardType = TextInputType.phone;
        formatters = [AppInputFormatters.phone];
        validators.add(AppValidators.phone);
        break;
      case AppFieldType.password:
        keyboardType = TextInputType.visiblePassword;
        break;
      case AppFieldType.integer:
        keyboardType = TextInputType.number;
        formatters = [AppInputFormatters.integer];
        break;
      case AppFieldType.decimal:
      case AppFieldType.percentage:
        keyboardType = const TextInputType.numberWithOptions(decimal: true);
        formatters = [AppInputFormatters.decimal];
        break;
      case AppFieldType.sku:
      case AppFieldType.barcode:
        keyboardType = TextInputType.text;
        // SKUs and Barcodes might have restrictions, but we allow englishOnly + some marks
        formatters = [AppInputFormatters.englishOnly];
        break;
    }

    return AppFieldConfig(
      keyboardType: keyboardType,
      inputFormatters: formatters,
      validator: validators.isNotEmpty ? AppValidators.combine(validators) : null,
    );
  }
}
