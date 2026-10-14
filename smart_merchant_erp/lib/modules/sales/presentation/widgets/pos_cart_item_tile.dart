import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';

/// A comfortable, tactile tile for an individual item inside the POS cart.
/// Features large touch targets (+ / -) to prevent miss-clicks during rush hours.
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // 1. PRODUCT DETAILS & UNIT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (item.unitName != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.unitName!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.unitPrice.toStringAsFixed(0)} $currency',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 2. COMPACT TACTILE STEPPERS (- / +)
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrement Button
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
                      size: 15,
                      color: item.quantity <= 1
                          ? AppColors.error
                          : textSecondary,
                    ),
                  ),
                ),

                // Quantity Number
                Container(
                  constraints: const BoxConstraints(minWidth: 26),
                  alignment: Alignment.center,
                  child: Text(
                    item.quantity.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 13,
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
                      size: 15,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3. LINE TOTAL
          SizedBox(
            width: 65,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                lineTotal.toStringAsFixed(0),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
