import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// رأس الصفحة الموحد لجميع شاشات ومودولات مشروع ERP.
///
/// يضمن توحيد العناوين الرئيسية، الوصف الفرعي، مسارات التنقل (Breadcrumbs)،
/// وأزرار الإجراءات السريعة (مثل إضافة عنصر جديد، تصدير، تحديث).
///
/// مثال الاستخدام:
/// ```dart
/// AppPageHeader(
///   title: 'دليل الحسابات',
///   subtitle: 'إدارة وتتبع الحسابات المالية وشجرة الحسابات',
///   icon: Icons.account_tree_outlined,
///   actions: [
///     ElevatedButton.icon(
///       onPressed: () {},
///       icon: Icon(Icons.add),
///       label: Text('حساب جديد'),
///     ),
///   ],
/// )
/// ```
class AppPageHeader extends StatelessWidget {
  /// عنوان الصفحة الرئيسي
  final String title;

  /// الوصف الفرعي أو التوضيحي تحت العنوان
  final String? subtitle;

  /// أيقونة الصفحة الرئيسية
  final IconData? icon;

  /// لون الأيقونة
  final Color? iconColor;

  /// قائمة بأزرار الإجراءات الرئيسية (تظهر على اليسار/اليمين)
  final List<Widget>? actions;

  /// دالة الرجوع (تظهر زر السهم للرجوع للتقارير والشاشات الفرعية)
  final VoidCallback? onBack;

  /// هل يظهر زر الرجوع افتراضياً؟
  final bool showBackButton;

  /// النص التوضيحي للمسار أعلى العنوان (مثل: المحاسبة / دليل الحسابات)
  final String? breadcrumb;

  /// هامش الرأس
  final EdgeInsetsGeometry padding;

  const AppPageHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.actions,
    this.onBack,
    this.showBackButton = false,
    this.breadcrumb,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final effectiveIconColor = iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final iconBgColor = effectiveIconColor.withValues(alpha: 0.12);

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final headerTextSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // مسار التنقل (Breadcrumb)
              if (breadcrumb != null) ...[
                Text(
                  breadcrumb!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // صف العنوان والأيقونة وزر الرجوع
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBackButton || onBack != null) ...[
                    IconButton(
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: textPrimary,
                      tooltip: 'رجوع',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: effectiveIconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // الوصف الفرعي
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          );

          final hasActions = actions != null && actions!.isNotEmpty;

          // للشاشات الصغيرة: رص العناصر رأسياً إذا لزم الأمر
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                headerTextSection,
                if (hasActions) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions!,
                  ),
                ],
              ],
            );
          }

          // للشاشات الكبيرة: رص العنوان والأزرار أفقياً في صف واحد
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: headerTextSection),
              if (hasActions) ...[
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!
                      .map((act) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: act,
                          ))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
