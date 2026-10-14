import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/daos/catalog_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';
import '../providers/product_unit_provider.dart';

/// A spacious, tactile product card for retail POS touchscreens.
/// Features in-card unit switching (piece / carton) and large tap targets.
class PosProductCard extends ConsumerStatefulWidget {
  final PosProductItem posItem;

  const PosProductCard({
    super.key,
    required this.posItem,
  });

  @override
  ConsumerState<PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends ConsumerState<PosProductCard> {
  late ProductUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.posItem.baseUnit;
  }

  @override
  void didUpdateWidget(covariant PosProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posItem.product.id != widget.posItem.product.id) {
      _selectedUnit = widget.posItem.baseUnit;
    }
  }

  String _formatUnitLabel(ProductUnit unit) {
    if (unit.isBaseUnit) return 'حبة';
    if (unit.conversionFactor > 1) {
      return 'كرتون (${unit.conversionFactor.toInt()})';
    }
    return 'عبوة';
  }

  void _addToCart() {
    ref.read(posNotifierProvider.notifier).addProduct(
          id: widget.posItem.product.id,
          name: widget.posItem.product.productName,
          price: _selectedUnit.sellingPrice,
          productUnitId: _selectedUnit.id,
          unitName: _formatUnitLabel(_selectedUnit),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.posItem.product;
    final units = widget.posItem.units;

    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final hash = product.productName.hashCode.abs();
    final lightTints = [
      const Color(0xFFEEF2FF),
      const Color(0xFFECFDF5),
      const Color(0xFFFFFBEB),
      const Color(0xFFEFF6FF),
      const Color(0xFFFAF5FF),
    ];
    final darkTints = [
      const Color(0xFF1E1B4B),
      const Color(0xFF064E3B),
      const Color(0xFF451A03),
      const Color(0xFF172554),
      const Color(0xFF3B0764),
    ];
    final accentColors = [
      AppColors.primary,
      AppColors.success,
      const Color(0xFFD97706),
      const Color(0xFF2563EB),
      const Color(0xFF9333EA),
    ];
    final paletteIdx = hash % lightTints.length;
    final topAreaBg = isDark ? darkTints[paletteIdx] : lightTints[paletteIdx];
    final topIconColor = isDark
        ? accentColors[paletteIdx].withValues(alpha: 0.9)
        : accentColors[paletteIdx];

    final inCartQuantity = ref.watch(posNotifierProvider.select((state) {
      final items = state.cart.where(
        (c) =>
            c.id == product.id &&
            (c.productUnitId == null || c.productUnitId == _selectedUnit.id),
      );
      if (items.isEmpty) return 0.0;
      return items.fold<double>(0.0, (acc, item) => acc + item.quantity);
    }));

    final hasInCart = inCartQuantity > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addToCart,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasInCart
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              width: hasInCart ? 2.0 : 1.2,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: hasInCart
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: hasInCart ? 8 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP IMAGE / ICON SECTION (Bolder tinted catalog with in-cart badge)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: topAreaBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 26,
                          color: topIconColor,
                        ),
                      ),
                      // Available Stock Badge (Top Left)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.posItem.stockQuantity <= 0
                                ? AppColors.error.withValues(alpha: 0.85)
                                : (isDark
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: widget.posItem.stockQuantity <= 0
                                  ? AppColors.error
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.posItem.stockQuantity <= 0
                                ? 'نفذت الكمية'
                                : 'المتوفر: ${widget.posItem.stockQuantity % 1 == 0 ? widget.posItem.stockQuantity.toInt() : widget.posItem.stockQuantity.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: widget.posItem.stockQuantity <= 0
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (hasInCart)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${inCartQuantity % 1 == 0 ? inCartQuantity.toInt() : inCartQuantity}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. PRODUCT DETAILS & MULTI-UNIT CHIPS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Title
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textColor,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Multi-Unit Switcher (If multiple units exist)
                    if (units.length > 1)
                      SizedBox(
                        height: 20,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: units.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final unit = units[index];
                            final isUnitSelected = _selectedUnit.id == unit.id;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedUnit = unit;
                                });
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnitSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.backgroundDark
                                          : const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatUnitLabel(unit),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: isUnitSelected
                                        ? FontWeight.w900
                                        : FontWeight.normal,
                                    color: isUnitSelected
                                        ? Colors.white
                                        : textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Text(
                        _formatUnitLabel(_selectedUnit),
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Price & Add Tap Target (High Conviction CTA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedUnit.sellingPrice.toStringAsFixed(0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: hasInCart ? AppColors.success : AppColors.primary,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: (hasInCart ? AppColors.success : AppColors.primary)
                                    .withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            hasInCart ? Icons.done_rounded : Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
