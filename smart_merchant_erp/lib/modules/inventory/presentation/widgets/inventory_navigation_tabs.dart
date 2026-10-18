import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class InventoryTab {
  final String label;
  final IconData icon;
  const InventoryTab(this.label, this.icon);
}

/// A single tab treatment shared by inventory navigation and its operations.
class InventoryNavigationTabs extends StatelessWidget {
  final List<InventoryTab> tabs;
  final bool compact;
  const InventoryNavigationTabs({
    required this.tabs,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.primaryLight : AppColors.primary;
    return LayoutBuilder(
      builder: (_, constraints) {
        final scrollable = constraints.maxWidth < (compact ? 520 : 780);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            compact ? 8 : 10,
            12,
            compact ? 4 : 10,
          ),
          child: TabBar(
            isScrollable: scrollable,
            tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: accent.withValues(alpha: compact ? 0.07 : 0.1),
              border: Border.all(color: accent.withValues(alpha: 0.13)),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: accent,
            unselectedLabelColor: dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            labelStyle: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              for (final tab in tabs)
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, size: compact ? 18 : 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
