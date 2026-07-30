import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../../forms/app_field_config.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final AppFieldType? fieldType;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;

  const CustomTextField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.fieldType,
    this.isRequired = false,
    this.onChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    AppFieldConfig? config;
    if (fieldType != null) {
      config = AppFieldConfig.fromType(fieldType!, required: isRequired);
    }

    final effectiveKeyboardType = keyboardType ?? config?.keyboardType ?? TextInputType.text;
    
    // Combine input formatters
    final effectiveFormatters = <TextInputFormatter>[];
    if (config?.inputFormatters != null) {
      effectiveFormatters.addAll(config!.inputFormatters!);
    }
    if (inputFormatters != null) {
      effectiveFormatters.addAll(inputFormatters!);
    }

    // Combine validators
    String? Function(String?)? effectiveValidator = validator;
    if (config?.validator != null && validator == null) {
      effectiveValidator = config!.validator;
    } else if (config?.validator != null && validator != null) {
      effectiveValidator = (val) {
        final configError = config!.validator!(val);
        if (configError != null) {
          return configError;
        }
        return validator!(val);
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label placed ABOVE the field (Best practice for ERP/Forms)
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.textSecondaryDark 
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: effectiveKeyboardType,
          obscureText: obscureText,
          validator: effectiveValidator,
          inputFormatters: effectiveFormatters.isNotEmpty ? effectiveFormatters : null,
          onChanged: onChanged,
          style: style ?? Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.textSecondaryDark 
                  : AppColors.textSecondaryLight,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
