import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// الحاوية الموحدة لجميع النوافذ المنبثقة (Bottom Sheets / Dialogs) في المشروع.
///
/// توحد:
/// - مقبض السحب العلوي
/// - رأس موحد (أيقونة + عنوان + زر إغلاق)
/// - منطقة محتوى قابلة للتمرير
/// - شريط أزرار سفلي (إلغاء + تأكيد)
class AppModalSheet extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onClose;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String cancelLabel;
  final bool isLoading;
  final double maxHeightFactor;
  final EdgeInsetsGeometry contentPadding;
  final Color? primaryColor;
  final bool hideActions;

  const AppModalSheet({
    required this.title,
    required this.onClose,
    required this.child,
    required this.primaryLabel,
    super.key,
    this.onPrimary,
    this.icon,
    this.iconColor,
    this.cancelLabel = 'إلغاء',
    this.isLoading = false,
    this.maxHeightFactor = 0.85,
    this.contentPadding = const EdgeInsets.all(20),
    this.primaryColor,
    this.hideActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final effectiveIconColor = iconColor ?? const Color(0xFF6366F1);
    final effectivePrimaryColor = primaryColor ?? const Color(0xFF6366F1);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * maxHeightFactor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // مقبض السحب
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // الرأس
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
          ),

          // المحتوى
          Flexible(
            child: SingleChildScrollView(padding: contentPadding, child: child),
          ),

          // الأزرار السفلية
          if (!hideActions)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onClose,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(cancelLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onPrimary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: effectivePrimaryColor,
                          disabledBackgroundColor: effectivePrimaryColor.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(primaryLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// دالة مساعدة لعرض AppModalSheet كـ Bottom Sheet
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}
