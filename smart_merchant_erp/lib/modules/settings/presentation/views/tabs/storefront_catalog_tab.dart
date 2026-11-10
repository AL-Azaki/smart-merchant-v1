import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../catalog/domain/models/catalog_product_item.dart';
import '../../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../../platform/presentation/providers/sync_provider.dart';
import '../../../../sales/presentation/providers/product_unit_provider.dart';

enum _StoreCatalogFilter {
  all,
  published,
  hidden,
  outOfStock,
}

class StorefrontCatalogTab extends ConsumerStatefulWidget {
  final VoidCallback onOpenSimulator;

  const StorefrontCatalogTab({
    super.key,
    required this.onOpenSimulator,
  });

  @override
  ConsumerState<StorefrontCatalogTab> createState() =>
      _StorefrontCatalogTabState();
}

class _StorefrontCatalogTabState extends ConsumerState<StorefrontCatalogTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  _StoreCatalogFilter _visibilityFilter = _StoreCatalogFilter.all;
  bool _isBulkUpdating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleProduct(
    CatalogProductItem item,
    bool showInStore,
  ) async {
    final ok = await ref
        .read(productsNotifierProvider.notifier)
        .toggleStoreVisibility(item.product.id, showInStore);
    if (!mounted) return;
    if (ok) {
      unawaited(ref.read(syncNotifierProvider.notifier).syncNow());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                showInStore
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  showInStore
                      ? 'تم نشر "${item.product.productName}" في المتجر الإلكتروني'
                      : 'تم إخفاء "${item.product.productName}" من المتجر الإلكتروني',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor:
              showInStore ? AppColors.success : const Color(0xFF475569),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleBulkVisibility(bool showInStore) async {
    if (_isBulkUpdating) return;
    setState(() => _isBulkUpdating = true);

    final updatedCount = await ref
        .read(productsNotifierProvider.notifier)
        .setAllStoreVisibility(showInStore);

    if (!mounted) return;
    setState(() => _isBulkUpdating = false);

    unawaited(ref.read(syncNotifierProvider.notifier).syncNow());
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          showInStore
              ? 'تم إظهار جميع المنتجات النشطة في المتجر الإلكتروني ($updatedCount منتج تم تحديثه)'
              : 'تم إخفاء جميع المنتجات من المتجر الإلكتروني ($updatedCount منتج تم تحديثه)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor:
            showInStore ? AppColors.success : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoriesNotifierProvider).valueOrNull ?? [];
    final units = ref.watch(unitsNotifierProvider).valueOrNull ?? [];
    final productsAsync = ref.watch(posProductsNotifierProvider);

    final categoryNames = {
      for (final c in categories) c.id: catalogDisplayName(c.categoryName),
    };
    final unitNames = {
      for (final u in units) u.id: catalogDisplayName(u.unitName),
    };

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('تعذر تحميل منتجات المتجر: $err'),
      ),
      data: (allItems) {
        final publishedCount =
            allItems.where((i) => i.product.showInStore).length;
        final hiddenCount =
            allItems.where((i) => !i.product.showInStore).length;
        final outOfStockCount =
            allItems.where((i) => i.stockQuantity <= 0).length;

        var filtered = allItems;

        if (_visibilityFilter == _StoreCatalogFilter.published) {
          filtered = filtered.where((i) => i.product.showInStore).toList();
        } else if (_visibilityFilter == _StoreCatalogFilter.hidden) {
          filtered = filtered.where((i) => !i.product.showInStore).toList();
        } else if (_visibilityFilter == _StoreCatalogFilter.outOfStock) {
          filtered = filtered.where((i) => i.stockQuantity <= 0).toList();
        }

        if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
          filtered = filtered
              .where((i) => i.product.categoryId == _selectedCategoryId)
              .toList();
        }

        if (_searchQuery.trim().isNotEmpty) {
          final q = _searchQuery.trim().toLowerCase();
          filtered = filtered.where((i) {
            return i.product.productName.toLowerCase().contains(q) ||
                i.product.productCode.toLowerCase().contains(q) ||
                (i.baseUnit.barcode?.toLowerCase().contains(q) ?? false);
          }).toList();
        }

        return Column(
          children: [
            // Top Summary & Bulk Actions Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التحكم السريع بمنتجات المتجر الإلكتروني',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'معروض حالياً: $publishedCount من أصل ${allItems.length} منتج نشط',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isBulkUpdating
                            ? null
                            : () => _handleBulkVisibility(true),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('إظهار الكل في المتجر'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isBulkUpdating
                            ? null
                            : () => _handleBulkVisibility(false),
                        icon:
                            const Icon(Icons.visibility_off_outlined, size: 16),
                        label: const Text('إخفاء الكل'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: widget.onOpenSimulator,
                        icon: const Icon(Icons.phone_iphone_rounded, size: 16),
                        label: const Text('معاينة كعميل'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'الكل',
                    count: allItems.length,
                    filter: _StoreCatalogFilter.all,
                    isDark: isDark,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'منشور بالمتجر',
                    count: publishedCount,
                    filter: _StoreCatalogFilter.published,
                    isDark: isDark,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'مخفي عن المتجر',
                    count: hiddenCount,
                    filter: _StoreCatalogFilter.hidden,
                    isDark: isDark,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'نفد من المخزون',
                    count: outOfStockCount,
                    filter: _StoreCatalogFilter.outOfStock,
                    isDark: isDark,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),

            // Search & Category Filter Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المنتج أو الكود أو الباركود...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.borderSm,
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppSpacing.borderSm,
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (categoryNames.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppSpacing.borderSm,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            hint: const Text(
                              'كل الأقسام',
                              style: TextStyle(fontSize: 13),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'كل الأقسام',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              for (final entry in categoryNames.entries)
                                DropdownMenuItem<String?>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedCategoryId = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Products List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد منتجات مطابقة للفلتر المحدد',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isShown = item.product.showInStore;
                        final catName =
                            categoryNames[item.product.categoryId] ?? 'عام';
                        final unitLabel =
                            unitNames[item.baseUnit.unitId] ?? 'قطعة';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isShown
                                  ? AppColors.success.withValues(alpha: 0.4)
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isShown
                                      ? AppColors.success.withValues(alpha: 0.12)
                                      : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  isShown
                                      ? Icons.storefront_rounded
                                      : Icons.visibility_off_outlined,
                                  color: isShown
                                      ? AppColors.success
                                      : const Color(0xFF94A3B8),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.product.productName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            catName,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 14,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'السعر: ${item.sellingPrice.toStringAsFixed(0)} ر.ي / $unitLabel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          'المخزون: ${item.stockQuantity.toStringAsFixed(0)} $unitLabel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: item.stockQuantity > 0
                                                ? (isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors
                                                        .textSecondaryLight)
                                                : AppColors.error,
                                          ),
                                        ),
                                        if (item.units.length > 1)
                                          Text(
                                            '${item.units.length} وحدات بيع متاحة',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF0D9488),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: isShown,
                                    activeThumbColor: AppColors.success,
                                    activeTrackColor: AppColors.success
                                        .withValues(alpha: 0.35),
                                    onChanged: (val) =>
                                        _handleToggleProduct(item, val),
                                  ),
                                  Text(
                                    isShown ? 'معروض بالمتجر' : 'مخفي',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isShown
                                          ? AppColors.success
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required _StoreCatalogFilter filter,
    required bool isDark,
    required Color color,
  }) {
    final selected = _visibilityFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _visibilityFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

