import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? trendText;
  final bool isTrendPositive;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.trendText,
    this.isTrendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  title,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Icon Container (Premium look with background color)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppSpacing.borderSm,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Main Value (e.g., $10,000)
            Text(
              value,
              style: AppTypography.textTheme.headlineLarge?.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            // Trend Indicator (e.g., +5% from yesterday)
            if (trendText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    isTrendPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isTrendPositive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    trendText!,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: isTrendPositive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
