import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class RoleCardModel {
  final String id;
  final String title;
  final String description;
  final int permissionsCount;
  final bool isSystemRole;
  final bool isActive;

  const RoleCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.permissionsCount,
    this.isSystemRole = false,
    this.isActive = true,
  });
}

class RoleCardWidget extends StatelessWidget {
  final RoleCardModel role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoleCardWidget({
    super.key,
    required this.role,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    const amberColor = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Shield Icon + System Role Badge + Title & Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shield Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: amberColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: amberColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title, Badges, & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            role.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role.isSystemRole) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                                SizedBox(width: 2),
                                Text(
                                  'دور نظام',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Permissions Count Chip (Clickable to view/edit permissions)
                    InkWell(
                      onTap: onEdit ?? () {},
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: amberColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, size: 13, color: amberColor),
                            const SizedBox(width: 4),
                            Text(
                              '${role.permissionsCount} صلاحيات (عرض الصلاحيات)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: amberColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: border.withValues(alpha: 0.6), height: 1, thickness: 1),
          const SizedBox(height: AppSpacing.sm),

          // Bottom Actions Row: Status Badge + Delete & Edit Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Action Buttons (Edit & Delete)
              Row(
                children: [
                  // Edit Button
                  InkWell(
                    onTap: onEdit ?? () {},
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Delete Button
                  InkWell(
                    onTap: onDelete ?? () {},
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: role.isSystemRole
                            ? (isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9))
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: role.isSystemRole
                            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),

              // Status Active Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: role.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  role.isActive ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: role.isActive ? AppColors.success : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
