import 'package:flutter/material.dart';
import '../../../domain/models/catalog_product_item.dart';
import '../../providers/product_list_filters.dart';
import 'product_thumbnail.dart';

enum ProductAction { details, edit, stock, delete }

class ProductsTable extends StatefulWidget {
  final List<CatalogProductItem> products;
  final Map<String, String> categories;
  final String Function(String) unitName;
  final String Function(CatalogProductItem) priceLabel;
  final void Function(CatalogProductItem, ProductAction) onAction;
  final ProductSort sort;
  final ValueChanged<ProductSort> onSort;

  const ProductsTable({
    required this.products,
    required this.categories,
    required this.unitName,
    required this.priceLabel,
    required this.onAction,
    required this.sort,
    required this.onSort,
    super.key,
  });
  @override
  State<ProductsTable> createState() => _ProductsTableState();
}

class _ProductsTableState extends State<ProductsTable> {
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth < 740 ? 740.0 : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: constraints.maxWidth < width,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  ColoredBox(
                    color: theme.colorScheme.primary.withValues(alpha: 0.045),
                    child: _Columns(
                      verticalPadding: 0,
                      product: _heading(
                        'المنتج',
                        Icons.inventory_2_outlined,
                        ProductSort.name,
                      ),
                      category: _label('التصنيف', Icons.category_outlined),
                      price: _heading(
                        'سعر البيع',
                        Icons.sell_outlined,
                        widget.sort == ProductSort.priceLow
                            ? ProductSort.priceHigh
                            : ProductSort.priceLow,
                      ),
                      stock: _heading(
                        'المخزون',
                        Icons.layers_outlined,
                        ProductSort.stockLow,
                      ),
                      actions: const Text(
                        'الإجراءات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.12),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: widget.products.length,
                      separatorBuilder: (_, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      itemBuilder: (_, index) =>
                          _row(widget.products[index], index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text, IconData icon) => Row(
    children: [
      Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _heading(String text, IconData icon, ProductSort sort) => Semantics(
    header: true,
    child: InkWell(
      onTap: () => widget.onSort(sort),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Flexible(child: _label(text, icon)),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(CatalogProductItem item, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockColor = item.stockQuantity <= 0
        ? (isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C))
        : item.stockQuantity <= 5
        ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E))
        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857));
    final stockText = item.stockQuantity < 0
        ? 'رصيد سالب'
        : item.stockQuantity == 0
        ? 'نفد المخزون'
        : item.stockQuantity <= 5
        ? 'مخزون منخفض'
        : 'متوفر';
    final unit = widget.unitName(item.baseUnit.unitId);
    final quantity = item.stockQuantity == item.stockQuantity.roundToDouble()
        ? item.stockQuantity.toInt().toString()
        : item.stockQuantity.toStringAsFixed(2);
    return Material(
      color: index.isOdd
          ? theme.colorScheme.primary.withValues(alpha: 0.018)
          : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onAction(item, ProductAction.details),
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: _Columns(
            product: Row(
              children: [
                ProductThumbnail(
                  productId: item.product.id,
                  name: item.product.productName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.units.length > 1
                            ? '$unit • ${item.units.length} وحدات بيع'
                            : 'وحدة البيع: $unit',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            category: Text(
              widget.categories[item.product.categoryId] ?? 'غير مصنف',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            price: Text(
              widget.priceLabel(item),
              maxLines: 2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            stock: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$quantity $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.stockQuantity <= 0
                            ? Icons.remove_shopping_cart_outlined
                            : item.stockQuantity <= 5
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 13,
                        color: stockColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          stockText,
                          style: TextStyle(
                            fontSize: 11,
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'تعديل المنتج',
                  onPressed: () => widget.onAction(item, ProductAction.edit),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                PopupMenuButton<ProductAction>(
                  tooltip: 'خيارات المنتج',
                  onSelected: (action) => widget.onAction(item, action),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: ProductAction.details,
                      child: _MenuLabel(Icons.info_outline, 'تفاصيل المنتج'),
                    ),
                    PopupMenuItem(
                      value: ProductAction.stock,
                      child: _MenuLabel(Icons.history_rounded, 'حركة المخزون'),
                    ),
                    PopupMenuItem(
                      value: ProductAction.delete,
                      child: _MenuLabel(Icons.delete_outline, 'حذف المنتج'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Columns extends StatelessWidget {
  final Widget product, category, price, stock, actions;
  final double verticalPadding;
  const _Columns({
    required this.product,
    required this.category,
    required this.price,
    required this.stock,
    required this.actions,
    this.verticalPadding = 10,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
    child: Row(
      children: [
        Expanded(flex: 40, child: product),
        const SizedBox(width: 16),
        Expanded(flex: 16, child: category),
        const SizedBox(width: 12),
        Expanded(flex: 20, child: price),
        const SizedBox(width: 12),
        Expanded(flex: 24, child: stock),
        const SizedBox(width: 8),
        SizedBox(width: 96, child: actions),
      ],
    ),
  );
}

class _MenuLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuLabel(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Row(
    children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)],
  );
}
