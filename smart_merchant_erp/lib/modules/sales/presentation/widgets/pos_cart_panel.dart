import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';
import 'pos_cart_item_tile.dart';
import 'pos_compact_checkout_dock.dart';
import 'quick_checkout_bar.dart';
import 'customer_select_modal.dart';

/// A full-featured, persistent cart panel for POS screens.
/// Streamlined to maximize vertical room for invoice items (up to 7+ visible items).
class PosCartPanel extends ConsumerWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SLEEK COMPACT CART HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                // Customer Selector Chip
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => const CustomerSelectModal(),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: posState.customerName != null
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (isDark
                                ? AppColors.backgroundDark
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: posState.customerName != null
                              ? AppColors.primary
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: posState.customerName != null
                                ? AppColors.primary
                                : textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              posState.customerName ?? 'عميل نقدي (كاش)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: posState.customerName != null
                                    ? AppColors.primary
                                    : textColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Clear Cart Button (Only if cart not empty, with confirmation guard for multiple items)
                if (posState.cart.isNotEmpty)
                  InkWell(
                    onTap: () {
                      if (posState.cart.length <= 1) {
                        ref.read(posNotifierProvider.notifier).clearCart();
                      } else {
                        showDialog<void>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            backgroundColor: surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.error,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تفريغ السلة؟',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'هل أنت متأكد من حذف جميع الأصناف (${posState.cart.length} أصناف) من السلة الحالية؟',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ref
                                      .read(posNotifierProvider.notifier)
                                      .clearCart();
                                  Navigator.of(dialogCtx).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'نعم، إفراغ السلة',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. ITEMS LIST / EMPTY STATE
          Expanded(
            child: posState.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'السلة فارغة',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اضغط على المنتجات لإضافتها للفاتورة',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: posState.cart.length,
                    itemBuilder: (context, index) {
                      final item = posState.cart[index];
                      return PosCartItemTile(
                        item: item,
                        currency: posState.currencyId,
                        onQuantityChanged: (newQty) {
                          ref
                              .read(posNotifierProvider.notifier)
                              .updateQuantity(
                                item.productUnitId ?? item.id,
                                newQty,
                              );
                        },
                        onRemove: () {
                          ref
                              .read(posNotifierProvider.notifier)
                              .removeProduct(item.productUnitId ?? item.id);
                        },
                      );
                    },
                  ),
          ),

          // 3. ULTRA-COMPACT INTEGRATED CHECKOUT DOCK (~92dp total height)
          const QuickCheckoutBar(),
        ],
      ),
    );
  }
}

