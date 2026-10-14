import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../providers/pos_search_provider.dart';
import '../providers/product_unit_provider.dart';
import 'pos_product_card.dart';

/// The products catalog grid for POS.
/// High-density, fast scan and tap interface with category filters and search.
class PosProductsGrid extends ConsumerStatefulWidget {
  const PosProductsGrid({super.key});

  @override
  ConsumerState<PosProductsGrid> createState() => _PosProductsGridState();
}

class _PosProductsGridState extends ConsumerState<PosProductsGrid> {
  String? _selectedCategoryId;
  String? _selectedCategoryKeyword;

  Widget _buildCategoryChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimaryLight),
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : const Color(0xFFF9FAFB);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final searchQuery = ref.watch(posSearchQueryProvider);
    final productsAsync = ref.watch(posProductsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final dbCategories = categoriesAsync.asData?.value ?? [];

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // 1. CATEGORY PILLS BAR (Top-level, maximum screen real estate for catalog)
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "الكل" (All Products)
                _buildCategoryChip(
                  label: 'الكل',
                  icon: Icons.grid_view_rounded,
                  isSelected: _selectedCategoryId == null && _selectedCategoryKeyword == null,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                      _selectedCategoryKeyword = null;
                    });
                  },
                  isDark: isDark,
                  borderColor: borderColor,
                ),
                const SizedBox(width: 8),

                // If DB categories exist, show them
                if (dbCategories.isNotEmpty) ...[
                  for (final cat in dbCategories) ...[
                    _buildCategoryChip(
                      label: cat.categoryName,
                      isSelected: _selectedCategoryId == cat.id,
                      onTap: () {
                        setState(() {
                          if (_selectedCategoryId == cat.id) {
                            _selectedCategoryId = null;
                            _selectedCategoryKeyword = null;
                          } else {
                            _selectedCategoryId = cat.id;
                            _selectedCategoryKeyword = null;
                          }
                        });
                      },
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                ] else ...[
                  // Retail Quick Categories Fallback
                  for (final item in const [
                    ('ألبان وأجبان', 'حليب', Icons.local_drink_rounded),
                    ('حبوب وأرز', 'أرز', Icons.grain_rounded),
                    ('بسكويت وحلويات', 'بسكويت', Icons.cookie_rounded),
                    ('دقيق ومخبوزات', 'دقيق', Icons.bakery_dining_rounded),
                    ('بهارات', 'بهار', Icons.soup_kitchen_rounded),
                  ]) ...[
                    _buildCategoryChip(
                      label: item.$1,
                      icon: item.$3,
                      isSelected: _selectedCategoryKeyword == item.$2,
                      onTap: () {
                        setState(() {
                          if (_selectedCategoryKeyword == item.$2) {
                            _selectedCategoryKeyword = null;
                          } else {
                            _selectedCategoryKeyword = item.$2;
                            _selectedCategoryId = null;
                          }
                        });
                      },
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ],
            ),
          ),

          // 3. PRODUCT CARDS GRID
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('حدث خطأ في تحميل الأصناف: $err'),
              ),
              data: (items) {
                // Filter by search query & category
                final filtered = items.where((item) {
                  final nameLower = item.product.productName.toLowerCase();
                  final matchesSearch = searchQuery.isEmpty ||
                      nameLower.contains(searchQuery) ||
                      (item.baseUnit.barcode != null &&
                          item.baseUnit.barcode!
                              .toLowerCase()
                              .contains(searchQuery));

                  final matchesCatId = _selectedCategoryId == null ||
                      item.product.categoryId == _selectedCategoryId;

                  final matchesKeyword = _selectedCategoryKeyword == null ||
                      nameLower.contains(_selectedCategoryKeyword!);

                  return matchesSearch && matchesCatId && matchesKeyword;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد أصناف مطابقة للبحث',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Responsive compact column counts to show more items
                    final crossAxisCount = width > 1000
                        ? 6
                        : (width > 700
                            ? 5
                            : (width > 480
                                ? 4
                                : (width > 320 ? 3 : 2)));
                    final childAspectRatio = width > 600 ? 0.98 : 0.88;

                    return GridView.builder(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: width < 768 ? 78 : 16,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return PosProductCard(posItem: filtered[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
