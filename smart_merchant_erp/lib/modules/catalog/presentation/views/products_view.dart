import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/stat_card.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../../../sales/presentation/providers/product_unit_provider.dart';
import '../providers/catalog_provider.dart';
import 'widgets/product_form_sheet.dart';
import '../../../inventory/presentation/dialogs/product_stock_card_dialog.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _stockFilter = 'all'; // 'all', 'in_stock', 'low_stock', 'out_of_stock'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _formatPrice(double val) {
    return '${_formatNumber(val)} ر.ي';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(posProductsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: productsAsync.when(
        data: (allProducts) {
          final categories = categoriesAsync.value ?? [];
          final categoryMap = {for (var c in categories) c.id: c.categoryName};

          final unitsList = unitsAsync.value ?? [];
          final unitMap = {for (var u in unitsList) u.id: u.unitName};

          String resolveUnitName(String unitId) {
            if (unitMap.containsKey(unitId)) {
              return unitMap[unitId]!;
            }
            if (unitId.startsWith('unit_')) {
              return 'قطعة';
            }
            return unitId.isNotEmpty ? unitId : 'قطعة';
          }

          // 1. Calculate Real Dynamic KPIs
          final totalCount = allProducts.length;
          final inStockCount =
              allProducts.where((p) => p.stockQuantity > 5).length;
          final lowStockCount = allProducts
              .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5)
              .length;
          final outOfStockCount =
              allProducts.where((p) => p.stockQuantity <= 0).length;

          // 2. Filter Products
          final filteredProducts = allProducts.where((p) {
            // Search text filter
            final q = _searchQuery.trim().toLowerCase();
            if (q.isNotEmpty) {
              final nameMatch = p.product.productName.toLowerCase().contains(q);
              final codeMatch =
                  p.product.productCode.toLowerCase().contains(q);
              final barcodeMatch =
                  p.baseUnit.barcode?.toLowerCase().contains(q) ?? false;
              final skuMatch =
                  p.baseUnit.sku?.toLowerCase().contains(q) ?? false;
              final anyUnitMatch = p.units.any(
                (u) =>
                    (u.barcode?.toLowerCase().contains(q) ?? false) ||
                    (u.sku?.toLowerCase().contains(q) ?? false) ||
                    resolveUnitName(u.unitId).toLowerCase().contains(q),
              );

              if (!nameMatch &&
                  !codeMatch &&
                  !barcodeMatch &&
                  !skuMatch &&
                  !anyUnitMatch) {
                return false;
              }
            }

            // Category filter
            if (_selectedCategoryId != null &&
                p.product.categoryId != _selectedCategoryId) {
              return false;
            }

            // Stock filter
            if (_stockFilter == 'in_stock' && p.stockQuantity <= 5) {
              return false;
            }
            if (_stockFilter == 'low_stock' &&
                (p.stockQuantity <= 0 || p.stockQuantity > 5)) {
              return false;
            }
            if (_stockFilter == 'out_of_stock' && p.stockQuantity > 0) {
              return false;
            }

            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Bar: Search, Stock Filter Tabs, & Add Product Action
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    // Search Field
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 280, maxWidth: 460),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن اسم المنتج، الكود، أو الباركود...',
                            hintStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: secondaryTextColor,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Stock Quick Filter Badges
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStockFilterChip('all', 'الكل ($totalCount)', isDark),
                          const SizedBox(width: 6),
                          _buildStockFilterChip(
                            'in_stock',
                            'متوفر ($inStockCount)',
                            isDark,
                            accentColor: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          _buildStockFilterChip(
                            'low_stock',
                            'منخفض ($lowStockCount)',
                            isDark,
                            accentColor: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          _buildStockFilterChip(
                            'out_of_stock',
                            'غير متوفر ($outOfStockCount)',
                            isDark,
                            accentColor: AppColors.error,
                          ),
                        ],
                      ),
                    ),

                    // Add Product Button
                    SizedBox(
                      height: 48,
                      child: PrimaryButton(
                        text: 'إضافة منتج جديد',
                        icon: Icons.add_circle_outline,
                        onPressed: () => _openProductFormSheet(context),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Categories Filter Chips Bar
              if (categories.isNotEmpty)
                Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: const Text('جميع التصنيفات'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) {
                            setState(() => _selectedCategoryId = null);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedCategoryId == null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _selectedCategoryId == null
                                ? AppColors.primary
                                : null,
                          ),
                          backgroundColor: surfaceColor,
                          side: BorderSide(
                            color: _selectedCategoryId == null
                                ? AppColors.primary
                                : borderColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      for (final category in categories)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(category.categoryName),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId =
                                    selected ? category.id : null;
                              });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedCategoryId == category.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedCategoryId == category.id
                                  ? AppColors.primary
                                  : null,
                            ),
                            backgroundColor: surfaceColor,
                            side: BorderSide(
                              color: _selectedCategoryId == category.id
                                  ? AppColors.primary
                                  : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // 3. KPI Real Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth > 800
                        ? (constraints.maxWidth - (3 * 12)) / 4
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: StatCard(
                            title: 'إجمالي المنتجات',
                            value: totalCount.toString(),
                            icon: Icons.inventory_2_outlined,
                            iconColor: AppColors.primary,
                            iconBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: StatCard(
                            title: 'متوفر بالمخزن',
                            value: inStockCount.toString(),
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.success,
                            iconBackgroundColor:
                                AppColors.success.withValues(alpha: 0.1),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: StatCard(
                            title: 'مخزون منخفض',
                            value: lowStockCount.toString(),
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.warning,
                            iconBackgroundColor:
                                AppColors.warning.withValues(alpha: 0.1),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: StatCard(
                            title: 'نفد من المخزن',
                            value: outOfStockCount.toString(),
                            icon: Icons.cancel_outlined,
                            iconColor: AppColors.error,
                            iconBackgroundColor: AppColors.error.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 4. Products List View
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: filteredProducts.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final item = filteredProducts[index];
                            final catName = categoryMap[item.product.categoryId] ??
                                'غير مصنف';
                            return _buildProductTile(
                              context: context,
                              item: item,
                              categoryName: catName,
                              unitNameResolver: resolveUnitName,
                              isDark: isDark,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                              secondaryTextColor: secondaryTextColor,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('حدث خطأ في تحميل بيانات المنتجات: $err'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockFilterChip(
    String filterKey,
    String label,
    bool isDark, {
    Color? accentColor,
  }) {
    final isSelected = _stockFilter == filterKey;
    final color = accentColor ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _stockFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : null,
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile({
    required BuildContext context,
    required PosProductItem item,
    required String categoryName,
    required String Function(String) unitNameResolver,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    final isAvailable = item.stockQuantity > 5;
    final isLow = item.stockQuantity > 0 && item.stockQuantity <= 5;

    final statusColor = isAvailable
        ? AppColors.success
        : (isLow ? AppColors.warning : AppColors.error);
    final statusText = isAvailable
        ? 'متوفر (${_formatNumber(item.stockQuantity)})'
        : (isLow
            ? 'منخفض (${_formatNumber(item.stockQuantity)})'
            : 'نفد المخزون');

    final baseUnitLabel = unitNameResolver(item.baseUnit.unitId);

    return InkWell(
      onTap: () => _showProductDetailsModal(
        context,
        item,
        categoryName,
        unitNameResolver,
        isDark,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Product Icon Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Product Main Details (Name, Category, Barcode/SKU, Multi-Units)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.product.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Stock Status Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Secondary Row: Barcode & Units breakdown
                  Row(
                    children: [
                      if (item.baseUnit.barcode != null &&
                          item.baseUnit.barcode!.isNotEmpty) ...[
                        Icon(
                          Icons.qr_code_scanner,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.baseUnit.barcode!,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (item.product.productCode.isNotEmpty) ...[
                        Text(
                          'كود: ${item.product.productCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Units badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.units.length > 1
                              ? '${item.units.length} وحدات (${item.units.map((u) => unitNameResolver(u.unitId)).join(' • ')})'
                              : 'الوحدة: $baseUnitLabel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Pricing Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatPrice(item.sellingPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      ' / $baseUnitLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'تكلفة الشراء: ${_formatPrice(item.baseUnit.purchasePrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'كارت حركة الصنف (سجل المخزون)',
                  icon: const Icon(
                    Icons.history_toggle_off,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => ProductStockCardDialog.show(
                    context,
                    productId: item.product.id,
                    productName: item.product.productName,
                    productCode: item.product.productCode,
                  ),
                ),
                IconButton(
                  tooltip: 'عرض تفاصيل الوحدات',
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showProductDetailsModal(
                    context,
                    item,
                    categoryName,
                    unitNameResolver,
                    isDark,
                  ),
                ),
                IconButton(
                  tooltip: 'تعديل المنتج',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _openProductFormSheet(context, item: item),
                ),
                IconButton(
                  tooltip: 'حذف المنتج',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: () => _confirmDeleteProduct(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetailsModal(
    BuildContext context,
    PosProductItem item,
    String categoryName,
    String Function(String) unitNameResolver,
    bool isDark,
  ) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final baseUnitLabel = unitNameResolver(item.baseUnit.unitId);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.productName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'التصنيف: $categoryName | كود: ${item.product.productCode.isNotEmpty ? item.product.productCode : "بدون كود"}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Current Inventory Snapshot
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'المتوفر بالمخزن (بالوحدة الأساسية)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatNumber(item.stockQuantity)} $baseUnitLabel',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'عدد الوحدات المعرفة',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.units.length} وحدات',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Text(
                  'تفاصيل وحدات المنتج وأسعارها:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // Units Table
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                        ),
                        columns: const [
                          DataColumn(label: Text('الوحدة')),
                          DataColumn(label: Text('المعامل')),
                          DataColumn(label: Text('سعر الشراء')),
                          DataColumn(label: Text('سعر البيع')),
                          DataColumn(label: Text('الباركود')),
                          DataColumn(label: Text('المتوفر بالوحدة')),
                        ],
                        rows: item.units.map((unit) {
                          final currentUnitName = unitNameResolver(unit.unitId);
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Text(
                                      currentUnitName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (unit.isBaseUnit) ...[
                                      const SizedBox(width: 4),
                                      const Text(
                                        '(أساسية)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '×${_formatNumber(unit.conversionFactor)}',
                                ),
                              ),
                              DataCell(
                                Text(_formatPrice(unit.purchasePrice)),
                              ),
                              DataCell(
                                Text(
                                  _formatPrice(unit.sellingPrice),
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  unit.barcode ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  unit.isBaseUnit
                                      ? '${_formatNumber(item.stockQuantity)} $currentUnitName'
                                      : unit.conversionFactor > 0
                                          ? '${_formatNumber(item.stockQuantity / unit.conversionFactor)} $currentUnitName'
                                          : '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل المنتج والوحدات'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openProductFormSheet(context, item: item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openProductFormSheet(BuildContext context, {PosProductItem? item}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ProductFormSheet(
          product: item != null
              ? {
                  'id': item.product.id,
                  'product_name': item.product.productName,
                  'description': item.product.description,
                  'category_id': item.product.categoryId,
                  'brand_id': item.product.brandId,
                  'is_active': item.product.isActive,
                  'sku': item.product.productCode.isNotEmpty
                      ? item.product.productCode
                      : (item.baseUnit.sku ?? ''),
                  'barcode': item.baseUnit.barcode,
                  'purchase_price': item.baseUnit.purchasePrice,
                  'selling_price': item.baseUnit.sellingPrice,
                }
              : null,
          onClose: () => Navigator.pop(ctx),
          onSave: (productData) async {
            await ref
                .read(productsNotifierProvider.notifier)
                .saveProduct(productData);
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
          },
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, PosProductItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد حذف المنتج'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف المنتج "${item.product.productName}"؟\nهذا الإجراء سيقوم بأرشفة المنتج من النظام.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(productsNotifierProvider.notifier)
                  .deleteProduct(item.product.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد منتجات تطابق معايير البحث أو التصفية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك تغيير كلمات البحث أو إعادة ضبط خيارات التصفية أو إضافة منتج جديد.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة منتج جديد'),
              onPressed: () => _openProductFormSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
