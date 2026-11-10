import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class LogoUploadCardWidget extends StatelessWidget {
  final String? logoPath;
  final String businessName;
  final VoidCallback? onUploadTap;
  final VoidCallback? onRemoveTap;

  const LogoUploadCardWidget({
    super.key,
    this.logoPath,
    this.businessName = '',
    this.onUploadTap,
    this.onRemoveTap,
  });

  bool get _hasLogo => logoPath != null && logoPath!.trim().isNotEmpty;

  Widget _buildLogoPreview(bool isDark) {
    final path = logoPath?.trim() ?? '';
    if (path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.network(
            path,
            fit: BoxFit.contain,
            width: 110,
            height: 110,
            errorBuilder: (_, _, _) => _buildInitialBadge(),
          ),
        );
      }
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.file(
            file,
            fit: BoxFit.contain,
            width: 110,
            height: 110,
            errorBuilder: (_, _, _) => _buildInitialBadge(),
          ),
        );
      }
    }
    return _buildInitialBadge();
  }

  Widget _buildInitialBadge() {
    final trimmed = businessName.trim();
    final initial = trimmed.isNotEmpty ? trimmed.substring(0, 1) : 'م';
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'شعار المنشأة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Interactive Logo Box
          InkWell(
            onTap: onUploadTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              height: 165,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoPreview(isDark),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hasLogo ? 'تغيير الشعار' : 'اختيار شعار المنشأة',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_hasLogo && onRemoveTap != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRemoveTap,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.error,
              ),
              label: const Text(
                'إزالة الشعار الحالي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          Text(
            'يظهر الشعار والاسم التجاري في ترويسة الفواتير والتقارير الرسمية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
