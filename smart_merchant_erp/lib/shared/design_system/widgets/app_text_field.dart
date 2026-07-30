import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';

/// حقل الإدخال الموحد لجميع نماذج المشروع.
///
/// يعيد إنتاج نمط الـ TextField المستخدم في account_form_sheet
/// وبقية النماذج بشكل موحد مع دعم كامل لـ Dark/Light.
///
/// مثال الاستخدام:
/// ```dart
/// AppTextField(
///   label: 'اسم الحساب *',
///   hint: 'مثال: نقدية بالصندوق',
///   controller: _nameController,
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// التسمية التوضيحية فوق الحقل
  final String label;

  /// النص التلميحي داخل الحقل
  final String? hint;

  /// المتحكم في النص
  final TextEditingController? controller;

  /// نوع لوحة المفاتيح
  final TextInputType keyboardType;

  /// هل الحقل للكتابة فقط (بدون تحرير)؟
  final bool readOnly;

  /// هل الحقل لكلمة المرور؟
  final bool obscureText;

  /// دالة التحقق
  final String? Function(String?)? validator;

  /// أيقونة/widget بداية الحقل
  final Widget? prefixIcon;

  /// أيقونة/widget نهاية الحقل
  final Widget? suffixIcon;

  /// مقيدات الإدخال (أرقام فقط، إلخ)
  final List<TextInputFormatter>? inputFormatters;

  /// دالة تغيير القيمة
  final ValueChanged<String>? onChanged;

  /// دالة الضغط (للحقول القابلة للضغط فقط)
  final VoidCallback? onTap;

  /// هل الحقل متعدد الأسطر؟
  final int? maxLines;

  /// الحد الأقصى لعدد الأحرف
  final int? maxLength;

  /// لون التركيز (الافتراضي: أزرق)
  final Color? focusColor;

  /// هل الحقل معطل؟
  final bool enabled;

  /// نص المساعدة تحت الحقل
  final String? helperText;

  /// قيمة افتراضية للعرض فقط (بديل لـ controller)
  final String? initialValue;

  const AppTextField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
    this.focusColor,
    this.enabled = true,
    this.helperText,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final disabledFill = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final effectiveFocusColor = focusColor ?? AppColors.info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── التسمية التوضيحية ─────────────────────────────────
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),

        // ── حقل الإدخال ───────────────────────────────────────
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          readOnly: readOnly,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? textPrimary : textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? surface : disabledFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            // الحدود
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: effectiveFocusColor, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: borderColor.withValues(alpha: 0.5),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// حقل نصي للأرقام فقط — يمنع تلقائياً إدخال الحروف
class AppNumberField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool allowDecimal;
  final bool enabled;
  final String? initialValue;

  const AppNumberField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.allowDecimal = true,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint ?? (allowDecimal ? '0.00' : '0'),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: validator,
      onChanged: onChanged,
      suffixIcon: suffixIcon,
      enabled: enabled,
      initialValue: initialValue,
    );
  }
}

/// حقل نصي متعدد الأسطر (للملاحظات والوصف)
class AppMultilineField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int lines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String? initialValue;

  const AppMultilineField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.lines = 3,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: TextInputType.multiline,
      maxLines: lines,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
    );
  }
}
