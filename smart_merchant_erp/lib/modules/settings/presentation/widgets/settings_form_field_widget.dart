import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class SettingsFormFieldWidget extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final int maxLines;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;

  const SettingsFormFieldWidget({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isRequired = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label with optional required asterisk
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),

        // Input Field Container
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
