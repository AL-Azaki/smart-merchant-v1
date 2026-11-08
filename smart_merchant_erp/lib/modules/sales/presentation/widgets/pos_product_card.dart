import '../../../catalog/presentation/providers/catalog_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String _formatUnitLabel(ProductUnit unit, List<Unit> unitsDef) {
    final def = unitsDef.where((u) => u.id == unit.unitId).firstOrNull;
    final name = def?.unitName ?? (unit.isBaseUnit ? 'حبة' : 'عبوة');
    if (unit.conversionFactor > 1) {
      return '$name (${unit.conversionFactor.toInt()})';
    }
    return name;
  }

  void _addToCart(List<Unit> unitsDef) {
    final factor = _selectedUnit.conversionFactor > 0 ? _selectedUnit.conversionFactor : 1.0;
    final cart = ref.read(posNotifierProvider).cart;
    final totalInCartBase = cart
        .where((c) => c.id == widget.posItem.product.id)
        .fold<double>(0.0, (sum, item) => sum + (item.quantity * (item.conversionFactor > 0 ? item.conversionFactor : 1.0)));

    final remainingStock = widget.posItem.stockQuantity - totalInCartBase;

    if (widget.posItem.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، هذا المنتج غير متوفر في المخزن حالياً (نفد المخزون).'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (remainingStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حجز كامل المخزون المتوفر في السلة (${widget.posItem.stockQuantity.toInt()} حبة). لا يمكن إضافة المزيد.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (remainingStock < factor) {
      final unitLabel = _formatUnitLabel(_selectedUnit, unitsDef);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الكمية المتبقية (${remainingStock.toInt()} حبة) لا تكفي لبيع $unitLabel كامل (${factor.toInt()} حبة).',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ref.read(posNotifierProvider.notifier).addProduct(
          id: widget.posItem.product.id,
          name: widget.posItem.product.productName,
          price: _selectedUnit.sellingPrice,
          productUnitId: _selectedUnit.id,
          unitName: _formatUnitLabel(_selectedUnit, unitsDef),
          conversionFactor: _selectedUnit.conversionFactor,
          availableUnits: widget.posItem.units,
          totalBaseStock: widget.posItem.stockQuantity,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.posItem.product;
    final units = widget.posItem.units;
    final unitsDef = ref.watch(unitsNotifierProvider).value ?? [];

    final factor = _selectedUnit.conversionFactor > 0 ? _selectedUnit.conversionFactor : 1.0;
    
    // Calculate total base quantity currently reserved in cart for this product
    final totalInCartBase = ref.watch(posNotifierProvider.select((state) {
      return state.cart
          .where((c) => c.id == product.id)
          .fold<double>(0.0, (sum, item) => sum + (item.quantity * (item.conversionFactor > 0 ? item.conversionFactor : 1.0)));
    }));

    final remainingStock = (widget.posItem.stockQuantity - totalInCartBase).clamp(0.0, double.infinity);
    final isCompletelyExhausted = widget.posItem.stockQuantity <= 0 || remainingStock <= 0;
    final isShortStock = remainingStock < factor;

    String stockBadgeText;
    if (widget.posItem.stockQuantity <= 0) {
      stockBadgeText = 'نفد المخزون';
    } else if (remainingStock <= 0) {
      stockBadgeText = 'تم حجز الكل بالسلة';
    } else if (_selectedUnit.conversionFactor > 1) {
      final fullUnits = remainingStock ~/ factor;
      final rem = (remainingStock % factor).toInt();
      final unitDef = unitsDef.where((u) => u.id == _selectedUnit.unitId).firstOrNull;
      final uName = unitDef?.unitName ?? 'كرتون';
      stockBadgeText = fullUnits > 0
          ? 'المتبقي: $fullUnits $uName' + (rem > 0 ? ' و $rem' : '')
          : 'المتبقي ($rem حبة) لا يكفي لـ $uName';
    } else {
      final unitDef = unitsDef.where((u) => u.id == _selectedUnit.unitId).firstOrNull;
      final uName = unitDef?.unitName ?? 'حبة';
      stockBadgeText = 'المتبقي: ${remainingStock % 1 == 0 ? remainingStock.toInt() : remainingStock.toStringAsFixed(1)} $uName';
    }

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

    return Opacity(
      opacity: widget.posItem.stockQuantity <= 0 ? 0.65 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: () => _addToCart(unitsDef),
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
                            color: (widget.posItem.stockQuantity <= 0 || remainingStock <= 0 || isShortStock)
                                ? AppColors.error.withValues(alpha: 0.88)
                                : (isDark
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (widget.posItem.stockQuantity <= 0 || remainingStock <= 0 || isShortStock)
                                  ? AppColors.error
                                  : borderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            stockBadgeText,
                            style: TextStyle(
                              color: (widget.posItem.stockQuantity <= 0 || remainingStock <= 0 || isShortStock)
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
                                  _formatUnitLabel(unit, unitsDef),
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
                        _formatUnitLabel(_selectedUnit, unitsDef),
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
                            color: isCompletelyExhausted
                                ? (isDark ? Colors.grey.shade800 : Colors.grey.shade400)
                                : (hasInCart ? AppColors.success : AppColors.primary),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: isCompletelyExhausted
                                ? []
                                : [
                                    BoxShadow(
                                      color: (hasInCart ? AppColors.success : AppColors.primary)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            isCompletelyExhausted
                                ? Icons.block_rounded
                                : (hasInCart ? Icons.done_rounded : Icons.add_rounded),
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
    ));
  }
}
