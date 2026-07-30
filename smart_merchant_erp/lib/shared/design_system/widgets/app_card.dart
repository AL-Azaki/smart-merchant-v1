import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// الحاوية والبطاقة الموحدة لجميع العناصر والأنشطة والقوائم في مشروع ERP.
///
/// تضمن مظهراً عصرياً موحداً مع دعم تلقائي للـ Dark/Light Mode وخصائص تفاعلية.
///
/// مثال الاستخدام:
/// ```dart
/// AppCard(
///   title: 'إجمالي المبيعات',
///   subtitle: 'تحديث اليوم',
///   trailing: Icon(Icons.arrow_forward_ios, size: 16),
///   onTap: () {},
///   child: Text('المحتوى الداخلي'),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// المحتوى الداخلي للبطاقة
  final Widget child;

  /// عنوان اختياري لـ Header البطاقة
  final String? title;

  /// وصف فرعي اختياري لـ Header البطاقة
  final String? subtitle;

  /// أيقونة جانبية في رأس البطاقة
  final IconData? icon;

  /// لون الأيقونة الجانبية
  final Color? iconColor;

  /// عنصر اختياري يوضع على اليمين/اليسار في رأس البطاقة (مثل زر أو badge)
  final Widget? trailing;

  /// دالة الضغط على البطاقة (يجعل البطاقة تفاعلية)
  final VoidCallback? onTap;

  /// الهامش الداخلي للبطاقة
  final EdgeInsetsGeometry padding;

  /// الهامش الخارجي للبطاقة
  final EdgeInsetsGeometry? margin;

  /// لون الخلفية المخصص
  final Color? backgroundColor;

  /// لون الإطار المخصص
  final Color? borderColor;

  /// انحناء الزوايا (الافتراضي 16)
  final double borderRadius;

  /// درجة الظل (الافتراضي 0 لنمط عصري مسطح)
  final double elevation;

  /// هل تظهر إطاراً حدودياً؟
  final bool hasBorder;

  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.elevation = 0,
    this.hasBorder = true,
  });

  /// نمط مسطح بخلفية خفيفة بدون حدود
  factory AppCard.flat({
    required Widget child,
    Key? key,
    String? title,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return AppCard(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: trailing,
      onTap: onTap,
      padding: padding,
      hasBorder: false,
      child: child,
    );
  }

  /// نمط بارز بظل خفيف (Elevated Card)
  factory AppCard.elevated({
    required Widget child,
    Key? key,
    String? title,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double elevation = 3,
  }) {
    return AppCard(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: trailing,
      onTap: onTap,
      padding: padding,
      hasBorder: false,
      elevation: elevation,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.surfaceDark : Colors.white;
    final defaultBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final effectiveBg = backgroundColor ?? defaultBg;
    final effectiveBorder = borderColor ?? defaultBorder;
    final effectiveIconColor = iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    final hasHeader = title != null || icon != null || trailing != null;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── رأس البطاقة (إن وجد) ──────────────────────────────
        if (hasHeader) ...[
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 20),
                ),
                const SizedBox(width: 12),
              ],
              if (title != null || subtitle != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── محتوى البطاقة الداخلي ─────────────────────────────
        child,
      ],
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(color: effectiveBorder) : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 1.5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: Padding(
                  padding: padding,
                  child: cardContent,
                ),
              )
            : Padding(
                padding: padding,
                child: cardContent,
              ),
      ),
    );
  }
}
