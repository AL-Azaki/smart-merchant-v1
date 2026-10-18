import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../sales/presentation/providers/product_unit_provider.dart';
import '../../../purchasing/presentation/providers/purchasing_provider.dart'
    show availableCurrenciesFutureProvider;
import '../../../inventory/presentation/dialogs/product_stock_card_dialog.dart';
import '../../domain/models/catalog_product_item.dart';
import '../providers/catalog_provider.dart';
import '../providers/product_list_filters.dart';
import 'widgets/product_form_sheet.dart';
import 'widgets/product_details_dialog.dart';
import 'widgets/products_table.dart';
import 'widgets/catalog_formatters.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});
  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  ProductStockFilter _stockFilter = ProductStockFilter.all;
  ProductSort _sort = ProductSort.name;

  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const _sortLabels = {
    ProductSort.name: 'الاسم',
    ProductSort.priceLow: 'السعر: الأقل أولاً',
    ProductSort.priceHigh: 'السعر: الأعلى أولاً',
    ProductSort.stockLow: 'المخزون: الأقل أولاً',
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesNotifierProvider).valueOrNull ?? [];
    final units = ref.watch(unitsNotifierProvider).valueOrNull ?? [];
    final currencies =
        ref.watch(availableCurrenciesFutureProvider).valueOrNull ?? [];
    final categoryNames = {
      for (final c in categories) c.id: catalogDisplayName(c.categoryName),
    };
    final unitNames = {for (final u in units) u.id: u.unitName};
    String unitName(String id) => catalogDisplayName(
      unitNames[id] ?? (id.startsWith('unit_') ? 'قطعة' : 'وحدة'),
    );
    String currency(CatalogProductItem item) {
      final selected = currencies
          .where((c) => c.id == item.product.currencyId)
          .firstOrNull;
      final base = currencies.where((c) => c.isBaseCurrency).firstOrNull;
      return selected?.currencySymbol ??
          (item.product.currencyId == null
              ? base?.currencySymbol ?? 'ر.ي'
              : '');
    }

    final border = theme.brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
    return ref
        .watch(posProductsNotifierProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                const Text('تعذر تحميل المنتجات.'),
                TextButton.icon(
                  onPressed: () => ref.invalidate(posProductsNotifierProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          data: (allProducts) {
            final products = filterCatalogProducts(
              allProducts,
              query: _searchQuery,
              categoryId: _selectedCategoryId,
              stock: _stockFilter,
              sort: _sort,
              unitName: (id) => unitNames[id] ?? '',
            );
            final counts = {
              ProductStockFilter.all: allProducts.length,
              ProductStockFilter.available: allProducts
                  .where((p) => p.stockQuantity > 5)
                  .length,
              ProductStockFilter.low: allProducts
                  .where((p) => p.stockQuantity > 0 && p.stockQuantity <= 5)
                  .length,
              ProductStockFilter.empty: allProducts
                  .where((p) => p.stockQuantity <= 0)
                  .length,
            };
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: theme.colorScheme.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المنتجات',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${allProducts.length} منتج في الكتالوج',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openProductFormSheet(context),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('إضافة منتج'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final search = TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث باسم المنتج أو امسح الباركود',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح البحث',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      );
                      final category = _dropdown<String>(
                        icon: Icons.category_outlined,
                        value: categoryNames.containsKey(_selectedCategoryId)
                            ? _selectedCategoryId!
                            : '',
                        options: {'': 'جميع التصنيفات', ...categoryNames},
                        onChanged: (v) => setState(
                          () => _selectedCategoryId = v == '' ? null : v,
                        ),
                      );
                      final sort = _dropdown<ProductSort>(
                        icon: Icons.sort_rounded,
                        value: _sort,
                        options: _sortLabels,
                        onChanged: (v) => setState(() => _sort = v),
                      );
                      if (constraints.maxWidth < 660) {
                        return Column(
                          children: [
                            search,
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: category),
                                const SizedBox(width: 10),
                                Expanded(child: sort),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(flex: 3, child: search),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: category),
                          const SizedBox(width: 12),
                          SizedBox(width: 178, child: sort),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _stockChip(
                          ProductStockFilter.all,
                          'الكل',
                          Icons.apps_rounded,
                          counts[ProductStockFilter.all]!,
                          theme.colorScheme.primary,
                        ),
                        _stockChip(
                          ProductStockFilter.available,
                          'متوفر',
                          Icons.check_circle_outline_rounded,
                          counts[ProductStockFilter.available]!,
                          theme.brightness == Brightness.dark
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF047857),
                        ),
                        _stockChip(
                          ProductStockFilter.low,
                          'منخفض',
                          Icons.warning_amber_rounded,
                          counts[ProductStockFilter.low]!,
                          theme.brightness == Brightness.dark
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFF92400E),
                        ),
                        _stockChip(
                          ProductStockFilter.empty,
                          'نفد',
                          Icons.remove_shopping_cart_outlined,
                          counts[ProductStockFilter.empty]!,
                          theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_rows_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${products.length} من ${allProducts.length} منتج',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (MediaQuery.sizeOf(context).width < 780)
                          Text(
                            'اسحب لعرض بقية الأعمدة',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: border),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: products.isEmpty
                          ? _empty(allProducts.isEmpty)
                          : ProductsTable(
                              products: products,
                              categories: categoryNames,
                              unitName: unitName,
                              priceLabel: (item) => formatCatalogPrice(
                                item.sellingPrice,
                                currency(item),
                              ),
                              sort: _sort,
                              onSort: (sort) => setState(() => _sort = sort),
                              onAction: (item, action) {
                                switch (action) {
                                  case ProductAction.details:
                                    showProductDetailsDialog(
                                      context,
                                      item,
                                      categoryNames[item.product.categoryId] ??
                                          'غير مصنف',
                                      unitName,
                                      theme.brightness == Brightness.dark,
                                      () => _openProductFormSheet(
                                        context,
                                        item: item,
                                      ),
                                      currency(item),
                                    );
                                  case ProductAction.edit:
                                    _openProductFormSheet(context, item: item);
                                  case ProductAction.stock:
                                    ProductStockCardDialog.show(
                                      context,
                                      productId: item.product.id,
                                      productName: item.product.productName,
                                      productCode: item.product.productCode,
                                    );
                                  case ProductAction.delete:
                                    _confirmDeleteProduct(context, item);
                                }
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _dropdown<T>({
    required IconData icon,
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 19),
          items: [
            for (final option in options.entries)
              DropdownMenuItem(
                value: option.key,
                child: Text(
                  option.value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
        ),
      ),
    );
  }

  Widget _stockChip(
    ProductStockFilter value,
    String label,
    IconData icon,
    int count,
    Color color,
  ) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      selected: _stockFilter == value,
      showCheckmark: false,
      avatar: Icon(icon, color: color, size: 18),
      label: Text('$label ($count)'),
      selectedColor: color.withValues(alpha: 0.10),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: _stockFilter == value
            ? color
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _stockFilter = value),
    ),
  );

  Widget _empty(bool noProducts) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noProducts ? Icons.inventory_2_outlined : Icons.search_off_rounded,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            noProducts ? 'ابدأ بإضافة منتجاتك' : 'لا توجد منتجات تطابق البحث',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            noProducts
                ? 'أضف الاسم والأسعار، ثم أكمل التفاصيل عند الحاجة.'
                : 'جرّب اسماً آخر أو أعد ضبط التصفية.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (noProducts)
            FilledButton.icon(
              onPressed: () => _openProductFormSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة أول منتج'),
            )
          else
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategoryId = null;
                  _stockFilter = ProductStockFilter.all;
                });
              },
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('إعادة ضبط التصفية'),
            ),
        ],
      ),
    ),
  );

  void _openProductFormSheet(BuildContext context, {CatalogProductItem? item}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ProductFormSheet(
          initialCategoryId: _selectedCategoryId,
          onSaveAndAdd: item == null
              ? (data) async {
                  final id = await ref
                      .read(productsNotifierProvider.notifier)
                      .saveProduct(data);
                  if (id == null) {
                    throw StateError('Product save failed');
                  }
                }
              : null,
          product: item != null
              ? {
                  'id': item.product.id,
                  'product_name': item.product.productName,
                  'description': item.product.description,
                  'category_id': item.product.categoryId,
                  'brand_id': item.product.brandId,
                  'is_active': item.product.isActive,
                  'show_in_store': item.product.showInStore,
                  'currency_id': item.product.currencyId,
                  'unit_id': item.baseUnit.unitId,
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
            final id = await ref
                .read(productsNotifierProvider.notifier)
                .saveProduct(productData);
            if (id == null) {
              throw StateError('Product save failed');
            }
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
          },
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, CatalogProductItem item) {
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
}
