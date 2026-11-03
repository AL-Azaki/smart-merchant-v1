import 'package:flutter/material.dart';
import '../../../../kernel/security/user_permissions_model.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class UserCardWidget extends StatelessWidget {
  final AppUserModel user;
  final bool isCurrentActive;
  final VoidCallback? onManagePermissions;
  final VoidCallback? onEditBasic;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onSwitchToUser;

  const UserCardWidget({
    required this.user,
    super.key,
    this.isCurrentActive = false,
    this.onManagePermissions,
    this.onEditBasic,
    this.onDelete,
    this.onToggleActive,
    this.onSwitchToUser,
  });

  Color _getRoleColor() {
    switch (user.rolePreset) {
      case 'admin':
        return const Color(0xFF6366F1); // Indigo
      case 'cashier':
        return const Color(0xFF3B82F6); // Blue
      case 'purchaser':
        return const Color(0xFF8B5CF6); // Purple
      case 'inventory_keeper':
        return const Color(0xFFF59E0B); // Amber
      case 'accountant':
        return const Color(0xFF10B981); // Emerald
      default:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  IconData _getRoleIcon() {
    switch (user.rolePreset) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'cashier':
        return Icons.point_of_sale_rounded;
      case 'purchaser':
        return Icons.shopping_bag_rounded;
      case 'inventory_keeper':
        return Icons.inventory_rounded;
      case 'accountant':
        return Icons.account_balance_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final roleColor = _getRoleColor();

    final initial = user.name.trim().isNotEmpty ? user.name.trim().substring(0, 1) : 'م';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentActive ? const Color(0xFF10B981) : border,
          width: isCurrentActive ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentActive
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Banner for Current Active User ──
          if (isCurrentActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'المستخدم المسجل حالياً على هذا الجهاز',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Row: Avatar + Info + Switch Toggle ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Active / Inactive Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: user.isActive
                                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  user.isActive ? 'نشط' : 'معطل',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: user.isActive ? const Color(0xFF10B981) : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '@${user.username} • ${user.phone ?? "بدون هاتف"} • ${user.branch}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Role Preset Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getRoleIcon(), size: 14, color: roleColor),
                                const SizedBox(width: 5),
                                Text(
                                  user.roleTitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: roleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toggle Active Switch
                    if (onToggleActive != null && user.id != 'user_admin_001')
                      Switch.adaptive(
                        value: user.isActive,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: onToggleActive,
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: border, height: 1),
                const SizedBox(height: 10),

                // ── Middle Section: Permissions Pills Summary ──
                Text(
                  'ملخص الصلاحيات الممنوحة:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _buildPermissionsSummary(isDark, textPrimary),

                const SizedBox(height: 12),
                Divider(color: border, height: 1),
                const SizedBox(height: 10),

                // ── Bottom Action Buttons ──
                Row(
                  children: [
                    // Switch to User Button
                    if (!isCurrentActive && user.isActive && onSwitchToUser != null) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onSwitchToUser,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text(
                          'تفعيل حسابه',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Manage Permissions Button (Distinct & Prominent)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onManagePermissions,
                        icon: const Icon(Icons.shield_rounded, size: 17),
                        label: const Text(
                          'إدارة الصلاحيات',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit Basic Info Button
                    if (onEditBasic != null)
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF232836) : const Color(0xFFF1F5F9),
                          foregroundColor: textPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        tooltip: 'تعديل البيانات الأساسية',
                        onPressed: onEditBasic,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                      ),

                    // Delete Button (Disabled for main admin)
                    if (user.id != 'user_admin_001' && onDelete != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        tooltip: 'حذف المستخدم',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSummary(bool isDark, Color textPrimary) {
    const modules = SystemModules.all;
    final List<Widget> moduleChips = [];

    for (final mod in modules) {
      final perm = user.permissions[mod.id];
      if (perm == null || !perm.canView) {
        continue;
      }

      final actions = <String>[];
      if (perm.canView) {
        actions.add('عرض');
      }
      if (perm.canAdd) {
        actions.add('إضافة');
      }
      if (perm.canEdit) {
        actions.add('تعديل');
      }
      if (perm.canDelete) {
        actions.add('حذف');
      }

      moduleChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: mod.color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mod.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(mod.icon, size: 13, color: mod.color),
              const SizedBox(width: 4),
              Text(
                '${mod.title}: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: mod.color,
                ),
              ),
              Text(
                actions.join(' • '),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (moduleChips.isEmpty) {
      return const Text(
        'لا توجد صلاحيات مفعلة لهذا المستخدم حالياً',
        style: TextStyle(fontSize: 11, color: AppColors.error, fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: moduleChips,
    );
  }
}
