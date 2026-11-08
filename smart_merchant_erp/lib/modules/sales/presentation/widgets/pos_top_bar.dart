import '../providers/product_unit_provider.dart';
import '../providers/pos_provider.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../catalog/domain/models/catalog_product_item.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_search_provider.dart';
import 'returns_modal.dart';
import 'voucher_modal.dart';

/// Top minimal action bar for POS.
/// Houses the POS brand pill, permanently complete full search & barcode input,
/// and quick access to vouchers and returns.
class PosTopBar extends ConsumerStatefulWidget {
  const PosTopBar({super.key});

  @override
  ConsumerState<PosTopBar> createState() => _PosTopBarState();
}

class _PosTopBarState extends ConsumerState<PosTopBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleBarcodeSubmit(String code) {
    final query = code.trim().toLowerCase();
    if (query.isEmpty) return;

    final products = ref.read(posProductsNotifierProvider).value ?? [];
    CatalogProductItem? matchedProduct;
    ProductUnit? matchedUnit;

    for (final p in products) {
      final u = p.findUnitByBarcodeOrSku(query);
      if (u != null) {
        matchedProduct = p;
        matchedUnit = u;
        break;
      }
    }

    if (matchedProduct != null && matchedUnit != null) {
      if (matchedProduct.stockQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('نفد المخزون: لا توجد كمية متوفرة من "${matchedProduct.product.productName}".'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final unitsDef = ref.read(unitsNotifierProvider).value ?? [];
      final unitDef = unitsDef.where((u) => u.id == matchedUnit!.unitId).firstOrNull;
      final unitName = matchedUnit.isBaseUnit
          ? (unitDef?.unitName ?? 'حبة')
          : '${unitDef?.unitName ?? 'كرتون'} (${matchedUnit.conversionFactor.toInt()})';

      ref.read(posNotifierProvider.notifier).addProduct(
            id: matchedProduct.product.id,
            name: matchedProduct.product.productName,
            price: matchedUnit.sellingPrice,
            productUnitId: matchedUnit.id,
            unitName: unitName,
            conversionFactor: matchedUnit.conversionFactor,
            availableUnits: matchedProduct.units,
            totalBaseStock: matchedProduct.stockQuantity,
          );

      _searchController.clear();
      setState(() {});
      ref.read(posSearchQueryProvider.notifier).clear();
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final isNarrow = constraints.maxWidth < 500;

          return Row(
            children: [
              // 1. POS Title Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 8 : 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      constraints.maxWidth >= 600
                          ? 'كاشير التجزئة السريع'
                          : 'الكاشير',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 2. Permanently Complete & Open Search & Barcode Input
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(fontSize: 13, color: textColor),
                          decoration: InputDecoration(
                            hintText: isNarrow
                                ? 'ابحث عن صنف أو باركود...'
                                : 'ابحث عن صنف بالاسم أو امسح الباركود مباشرة...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (val) {
                            setState(() {});
                            ref
                                .read(posSearchQueryProvider.notifier)
                                .update(val);
                          },
                          onSubmitted: _handleBarcodeSubmit,
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(posSearchQueryProvider.notifier).clear();
                            _searchFocusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.clear_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      Tooltip(
                        message: 'قارئ الباركود نشط ومستعد للمسح الفوري',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(left: 4, right: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 3. Voucher & Discount Bond (سند وقسائم)
              Tooltip(
                message: 'سند وقسائم الخصم',
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const VoucherModal(),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : (isWide ? 12 : 8),
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 5),
                          Text(
                            isWide ? 'سند وقسائم' : 'السند',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.warning
                                  : const Color(0xFFB45309),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 4. Returns (مرتجع مبيعات)
              Tooltip(
                message: 'مرتجع مبيعات',
                child: InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const ReturnsModal(),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 8 : (isWide ? 12 : 8),
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error
                          .withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.assignment_return_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 5),
                          Text(
                            isWide ? 'مرتجع مبيعات' : 'المرتجع',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
