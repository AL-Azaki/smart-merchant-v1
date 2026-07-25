import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/stat_card.dart';
import '../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/catalog_provider.dart';
import 'widgets/product_form_sheet.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by parent layout or Scaffold
      body: productsAsync.when(
        data: (products) {
          // Calculate stats
          final total = products.length;
          // In a real app, stock quantity is joined from inventory.
          // For presentation mapping, we assume we might need to fetch inventory later or we mock the UI boundary.
          int inStock = total; // Placeholder logic until inventory integration
          int lowStock = 0;
          int outOfStock = 0;

          // Filter by search
          final filteredProducts = products.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.productName.toLowerCase().contains(q) ||
                (p.productCode?.toLowerCase().contains(q) ?? false);
          }).toList();

          return Column(
            children: [
              // 1. Search & Actions Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppSpacing.borderMd,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منتج، كود، أو باركود...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 180,
                      child: PrimaryButton(
                        text: 'إضافة منتج',
                        icon: Icons.add_rounded,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              child: ProductFormSheet(
                                onClose: () => Navigator.pop(ctx),
                                onSave: (productData) async {
                                  await ref.read(productsNotifierProvider.notifier).saveProduct(productData);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. KPI Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: StatCard(
                        title: 'إجمالي المنتجات',
                        value: total.toString(),
                        icon: Icons.inventory_2_outlined,
                        iconColor: AppColors.primary,
                        iconBackgroundColor: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 220,
                      child: StatCard(
                        title: 'متوفر',
                        value: inStock.toString(),
                        icon: Icons.check_circle_outline,
                        iconColor: AppColors.success,
                        iconBackgroundColor: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 220,
                      child: StatCard(
                        title: 'منخفض المخزون',
                        value: lowStock.toString(),
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.warning,
                        iconBackgroundColor: AppColors.warning.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 220,
                      child: StatCard(
                        title: 'غير متوفر',
                        value: outOfStock.toString(),
                        icon: Icons.error_outline_rounded,
                        iconColor: AppColors.error,
                        iconBackgroundColor: AppColors.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Data Grid / List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text('لا توجد منتجات تطابق بحثك'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => Divider(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          itemBuilder: (context, index) {
                            final p = filteredProducts[index];
                            return ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.backgroundDark
                                      : AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: const Icon(Icons.inventory_2_outlined),
                              ),
                              title: Text(
                                p.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(p.productCode ?? 'لا يوجد كود'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                          child: ProductFormSheet(
                                            product: {
                                              'id': p.id,
                                              'product_name': p.productName,
                                              'description': p.description,
                                              'category_id': p.categoryId,
                                              'brand_id': p.brandId,
                                              'is_active': p.isActive,
                                              'sku': p.productCode,
                                            },
                                            onClose: () => Navigator.pop(ctx),
                                            onSave: (productData) async {
                                              await ref.read(productsNotifierProvider.notifier).saveProduct(productData);
                                              if (ctx.mounted) Navigator.pop(ctx);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: Text('هل أنت متأكد من رغبتك في حذف المنتج "${p.productName}"؟\nهذا الإجراء لا يمكن التراجع عنه.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await ref.read(productsNotifierProvider.notifier).deleteProduct(p.id);
                                                if (ctx.mounted) Navigator.pop(ctx);
                                              },
                                              child: const Text('حذف', style: TextStyle(color: AppColors.error)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 100), // Padding for floating bottom nav
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }
}
