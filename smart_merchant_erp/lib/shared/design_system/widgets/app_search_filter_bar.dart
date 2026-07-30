import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Data model for filter chips used in AppSearchFilterBar.
class AppFilterChipData {
  final String label;
  final String value;
  final int? count;
  final IconData? icon;

  const AppFilterChipData({
    required this.label,
    required this.value,
    this.count,
    this.icon,
  });
}

/// A unified, responsive Search and Filter Bar widget for all ERP modules.
class AppSearchFilterBar extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final List<AppFilterChipData>? filterChips;
  final String? selectedFilterValue;
  final ValueChanged<String>? onFilterSelected;
  final Widget? trailingAction;
  final EdgeInsetsGeometry padding;

  const AppSearchFilterBar({
    required this.searchHint,
    super.key,
    this.onSearchChanged,
    this.searchController,
    this.filterChips,
    this.selectedFilterValue,
    this.onFilterSelected,
    this.trailingAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 10),
                trailingAction!,
              ],
            ],
          ),
          if (filterChips != null && filterChips!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filterChips!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = filterChips![index];
                  final isSelected = selectedFilterValue == chip.value;
                  final chipBg = isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
                  final chipFg = isSelected
                      ? Colors.white
                      : textSecondary;

                  return InkWell(
                    onTap: () {
                      if (onFilterSelected != null) {
                        onFilterSelected!(chip.value);
                      }
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chip.icon != null) ...[
                            Icon(chip.icon, size: 14, color: chipFg),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            chip.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: chipFg,
                            ),
                          ),
                          if (chip.count != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (isDark ? Colors.white10 : Colors.black12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${chip.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: chipFg,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
