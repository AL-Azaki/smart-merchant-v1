import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// الشاشة الموحدة للبيانات الفارغة وحالات الانتظار/الخطأ في جميع شاشات المشروع.
///
/// توفر:
/// - شاشة بيانات فارغة قياسية مع أيقونة وعنوان ووصف
/// - زر إجراء أساسي (مثل: إضافة عنصر جديد)
/// - زر إجراء ثانوي (مثل: إعادة الفلترة)
/// - نمط مدمج (Compact) للجداول والبطاقات الصغرى
/// - مكون خاص بحالة التحميل (AppLoadingState)
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;
  final bool isCompact;

  const AppEmptyState({
    required this.title,
    super.key,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.isCompact = false,
  });

  /// خيار مسبق لحالة "لا توجد نتائج بحث"
  factory AppEmptyState.search({
    Key? key,
    String title = 'لا توجد نتائج بحث',
    String? subtitle = 'جرب البحث بكلمات مختلفة أو إزالة الفلاتر',
    VoidCallback? onClearSearch,
  }) {
    return AppEmptyState(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: Icons.search_off_rounded,
      iconColor: AppColors.info,
      actionLabel: onClearSearch != null ? 'إعادة ضبط البحث' : null,
      onAction: onClearSearch,
    );
  }

  /// خيار مسبق لحالة "خطأ في تحميل البيانات"
  factory AppEmptyState.error({
    Key? key,
    String title = 'حدث خطأ أثناء تحميل البيانات',
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return AppEmptyState(
      key: key,
      title: title,
      subtitle: subtitle ?? 'يرجى التحقق من الاتصال بالشبكة والمحاولة مرة أخرى',
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      actionLabel: onRetry != null ? 'إعادة المحاولة' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final effectiveIconColor = iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final iconBgColor = effectiveIconColor.withValues(alpha: 0.1);

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: effectiveIconColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة دائرية مزخرفة
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 20),

            // العنوان الرئيسي
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // الوصف الفرعي
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // الأزرار والتصرفات
            if (actionLabel != null || secondaryActionLabel != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(secondaryActionLabel!),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (actionLabel != null && onAction != null)
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveIconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ودجت موحد لحالة التحميل والانتظار
class AppLoadingState extends StatelessWidget {
  final String? message;
  final bool isCompact;

  const AppLoadingState({
    super.key,
    this.message,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
