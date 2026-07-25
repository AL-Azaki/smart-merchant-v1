/// Centralized validation logic for the ERP.
class AppValidators {
  /// Ensures the field is not empty.
  static String? required(String? value, {String message = 'هذا الحقل مطلوب'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  /// Ensures a human-readable name is valid (allows Arabic, English, spaces).
  static String? humanName(String? value, {String message = 'الاسم غير صالح'}) {
    if (value == null || value.trim().isEmpty) return null; // Use required() for empty check
    // Simple length check or structure check. Let's not restrict characters aggressively, 
    // as per requirements. We only restrict things like just numbers if needed.
    if (value.trim().length < 2) {
      return 'الاسم قصير جداً';
    }
    return null;
  }

  /// Validates a phone number.
  static String? phone(String? value, {String message = 'رقم الهاتف غير صالح'}) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  /// Validates an email address.
  static String? email(String? value, {String message = 'البريد الإلكتروني غير صالح'}) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  /// Combines multiple validators.
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
