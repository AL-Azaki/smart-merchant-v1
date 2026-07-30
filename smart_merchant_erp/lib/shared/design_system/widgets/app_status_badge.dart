import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Preset variants for standard ERP status badges.
enum AppStatusBadgeVariant {
  success,
  warning,
  error,
  info,
  neutral,
  purple,
}

/// A unified, highly responsive status badge widget used across all ERP modules.
///
/// Ensures clean visual consistency for states like (مُرحَّل, مسودة, نشط, معطل, مدفوع, معلق, إلخ).
class AppStatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppStatusBadgeVariant variant;
  final Color? customColor;
  final Color? customBackgroundColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppStatusBadge({
    required this.label,
    super.key,
    this.icon,
    this.variant = AppStatusBadgeVariant.neutral,
    this.customColor,
    this.customBackgroundColor,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 8.0,
  });

  /// Factory constructor for quick status text mapping.
  factory AppStatusBadge.fromStatus({
    required String status,
    Key? key,
    IconData? icon,
    double fontSize = 12.0,
  }) {
    AppStatusBadgeVariant variant = AppStatusBadgeVariant.neutral;
    final normalized = status.trim().toLowerCase();

    if (normalized.contains('نشط') ||
        normalized.contains('مُرحَّل') ||
        normalized.contains('مرحل') ||
        normalized.contains('مدفوع') ||
        normalized.contains('مكتمل') ||
        normalized.contains('active') ||
        normalized.contains('posted') ||
        normalized.contains('paid')) {
      variant = AppStatusBadgeVariant.success;
    } else if (normalized.contains('معلق') ||
        normalized.contains('قيد') ||
        normalized.contains('pending') ||
        normalized.contains('warning')) {
      variant = AppStatusBadgeVariant.warning;
    } else if (normalized.contains('معطل') ||
        normalized.contains('ملغي') ||
        normalized.contains('مرفوض') ||
        normalized.contains('inactive') ||
        normalized.contains('cancelled') ||
        normalized.contains('rejected')) {
      variant = AppStatusBadgeVariant.error;
    } else if (normalized.contains('مسودة') ||
        normalized.contains('draft') ||
        normalized.contains('info')) {
      variant = AppStatusBadgeVariant.info;
    } else if (normalized.contains('مدير') ||
        normalized.contains('admin') ||
        normalized.contains('مشرف')) {
      variant = AppStatusBadgeVariant.purple;
    }

    return AppStatusBadge(
      key: key,
      label: status,
      icon: icon,
      variant: variant,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: customBackgroundColor ?? colors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: customColor ?? colors.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: customColor ?? colors.foreground,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColorPair _resolveColors(BuildContext context) {
    switch (variant) {
      case AppStatusBadgeVariant.success:
        return const _BadgeColorPair(
          foreground: Color(0xFF10B981),
          background: Color(0x1F10B981),
        );
      case AppStatusBadgeVariant.warning:
        return const _BadgeColorPair(
          foreground: Color(0xFFF59E0B),
          background: Color(0x1FF59E0B),
        );
      case AppStatusBadgeVariant.error:
        return const _BadgeColorPair(
          foreground: Color(0xFFEF4444),
          background: Color(0x1FEF4444),
        );
      case AppStatusBadgeVariant.info:
        return const _BadgeColorPair(
          foreground: Color(0xFF3B82F6),
          background: Color(0x1F3B82F6),
        );
      case AppStatusBadgeVariant.purple:
        return const _BadgeColorPair(
          foreground: Color(0xFF8B5CF6),
          background: Color(0x1F8B5CF6),
        );
      case AppStatusBadgeVariant.neutral:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return _BadgeColorPair(
          foreground: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          background: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        );
    }
  }
}

class _BadgeColorPair {
  final Color foreground;
  final Color background;
  const _BadgeColorPair({required this.foreground, required this.background});
}
