import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class SettingsTabItem {
  final String title;
  final IconData icon;
  final Widget? destinationView;

  const SettingsTabItem({
    required this.title,
    required this.icon,
    this.destinationView,
  });
}

class SettingsTabBarWidget extends StatelessWidget {
  final List<SettingsTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const SettingsTabBarWidget({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          final tab = tabs[index];

          return InkWell(
            onTap: () => onTabSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab.icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
