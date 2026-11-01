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
  final ValueChanged<double>? onDiscountChanged;

  const PosCartItemTile({
    required this.item,
    required this.currency,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onDiscountChanged,
    super.key,
  });

  void _showDiscountDialog(BuildContext context) {
    if (onDiscountChanged == null) return;
    final total = item.quantity * item.unitPrice;
    final controller = TextEditingController(
      text: item.discount > 0 ? item.discount.toStringAsFixed(0) : '',
    );
    bool isPercentage = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.discount_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خصم على: ${item.name}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الصنف قبل الخصم: ${total.toStringAsFixed(0)} $currency',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isPercentage ? 'نسبة الخصم (%)' : 'مبلغ الخصم ($currency)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('مبلغ')),
                        ButtonSegment(value: true, label: Text('%')),
                      ],
                      selected: {isPercentage},
                      onSelectionChanged: (val) {
                        setDialogState(() {
                          isPercentage = val.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('5%'),
                      onPressed: () {
                        controller.text = (total * 0.05).toStringAsFixed(0);
                        setDialogState(() => isPercentage = false);
                      },
                    ),
                    ActionChip(
                      label: const Text('10%'),
                      onPressed: () {
                        controller.text = (total * 0.10).toStringAsFixed(0);
                        setDialogState(() => isPercentage = false);
                      },
                    ),
                    ActionChip(
                      label: const Text('20%'),
                      onPressed: () {
                        controller.text = (total * 0.20).toStringAsFixed(0);
                        setDialogState(() => isPercentage = false);
                      },
                    ),
                    if (item.discount > 0)
                      ActionChip(
                        avatar: const Icon(Icons.clear, size: 14, color: AppColors.error),
                        label: const Text('إلغاء الخصم', style: TextStyle(color: AppColors.error)),
                        onPressed: () {
                          onDiscountChanged!(0.0);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = double.tryParse(controller.text.trim()) ?? 0.0;
                  double calculatedDiscount = 0.0;
                  if (isPercentage) {
                    calculatedDiscount = (total * (input / 100.0)).clamp(0.0, total);
                  } else {
                    calculatedDiscount = input.clamp(0.0, total);
                  }
                  onDiscountChanged!(calculatedDiscount);
                  Navigator.pop(ctx);
                },
                child: const Text('تطبيق الخصم'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final grossLineTotal = item.quantity * item.unitPrice;
    final netLineTotal = (grossLineTotal - item.discount).clamp(0.0, double.infinity);
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

                // Price & Line Calculation & Discount Trigger
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
                        '${grossLineTotal.toStringAsFixed(0)} $currency',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          decoration:
                              item.discount > 0 ? TextDecoration.lineThrough : null,
                          color: item.discount > 0
                              ? textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    if (onDiscountChanged != null)
                      InkWell(
                        onTap: () => _showDiscountDialog(context),
                        borderRadius: BorderRadius.circular(6),
                        child: item.discount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber
                                      .withValues(alpha: isDark ? 0.25 : 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Colors.amber.shade700
                                        .withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.discount_outlined,
                                      size: 11,
                                      color: isDark
                                          ? Colors.amber.shade300
                                          : Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '-${item.discount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.amber.shade300
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Tooltip(
                                message: 'إضافة خصم للصنف',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Icon(
                                    Icons.discount_outlined,
                                    size: 14,
                                    color:
                                        textSecondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                      ),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.discount > 0) ...[
                    Text(
                      grossLineTotal.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 10.5,
                        decoration: TextDecoration.lineThrough,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${netLineTotal.toStringAsFixed(0)} $currency',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: item.discount > 0
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
