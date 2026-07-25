import 'package:flutter/services.dart';

/// Centralized input formatters for the ERP.
class AppInputFormatters {
  /// Prevents typing letters in phone number fields. Allows numbers and + sign.
  static final TextInputFormatter phone =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'));

  /// Prevents typing letters in decimal fields (like price or quantity).
  static final TextInputFormatter decimal =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  /// Prevents typing letters in integer fields (like quantity without decimals).
  static final TextInputFormatter integer =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

  /// English only identifier (e.g. usernames, certain codes)
  static final TextInputFormatter englishOnly =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-\.]'));
}
