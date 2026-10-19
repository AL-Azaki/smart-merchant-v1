import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';

/// A comfortable, tactile tile for an individual item inside the POS cart.
/// Optimized for maximum product name visibility without clipping, with steppers on the far side.
class PosCartItemTile extends StatelessWidget {
  final PosCartItem item;
  final String currency;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  const PosCartItemTile({
    required this.item,
    required this.currency,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final lineTotal = item.quantity * item.unitPrice;
    final String formattedQty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. PRODUCT DETAILS (RIGHT IN RTL) - EXPANDED FOR MAXIMUM NAME VISIBILITY
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name (up to 2 lines so it is never truncated)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (item.unitName != null && item.unitName!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.unitName!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),

                // Price & Line Calculation
                Row(
                  children: [
                    Text(
                      '${item.unitPrice.toStringAsFixed(0)} $currency',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      Text(
                        ' × $formattedQty = ',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${lineTotal.toStringAsFixed(0)} $currency',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 2. QUANTITY STEPPERS (- / +) ON THE FAR SIDE (LEFT IN RTL)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrement or Remove
                    InkWell(
                      onTap: () => onQuantityChanged(item.quantity - 1),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        child: Icon(
                          item.quantity <= 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                          size: 16,
                          color: item.quantity <= 1
                              ? AppColors.error
                              : textSecondary,
                        ),
                      ),
                    ),

                    // Quantity Number
                    Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      alignment: Alignment.center,
                      child: Text(
                        formattedQty,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),

                    // Increment Button
                    InkWell(
                      onTap: () => onQuantityChanged(item.quantity + 1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Amount for this item displayed prominently
              const SizedBox(height: 4),
              Text(
                '${lineTotal.toStringAsFixed(0)} $currency',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
