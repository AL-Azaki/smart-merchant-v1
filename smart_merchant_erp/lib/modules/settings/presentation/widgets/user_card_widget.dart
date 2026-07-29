import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class UserCardModel {
  final String id;
  final String name;
  final String role;
  final String branch;
  final String initialLetter;
  final bool isActive;
  final Color avatarColor;

  const UserCardModel({
    required this.id,
    required this.name,
    required this.role,
    required this.branch,
    required this.initialLetter,
    this.isActive = true,
    this.avatarColor = const Color(0xFF6366F1),
  });
}

class UserCardWidget extends StatelessWidget {
  final UserCardModel user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCardWidget({
    super.key,
    required this.user,
    this.onEdit,
    this.onDelete,
  });

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
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Status Icon + User Name + Avatar
          Row(
            children: [
              // Active / Inactive Status Badge Icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  user.isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                  size: 16,
                  color: user.isActive ? AppColors.success : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // User Name
              Expanded(
                child: Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Avatar Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: user.avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: user.avatarColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.initialLetter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: user.avatarColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Badges Row: Role Badge + Branch Badge
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs,
            children: [
              // Role Badge (Shield icon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Branch Badge (Location icon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.branch,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
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

          // Action Buttons: Delete & Edit Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
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
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
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
