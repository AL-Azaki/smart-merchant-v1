import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../providers/pos_provider.dart';
import 'payment_modal.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posNotifierProvider);
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    final int totalItems = posState.cart.fold(0, (sum, item) => sum + item.quantity.toInt());

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ]
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      loc.cart,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text('$totalItems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),
          
          // Cart Items
          Expanded(
            child: posState.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.remove_shopping_cart_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 24),
                        Text(loc.cartEmpty, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('أضف منتجات للسلة للبدء في البيع', style: TextStyle(color: textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: posState.cart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = posState.cart[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Row(
                          children: [
                            // Image Placeholder
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                              ),
                              child: Icon(Icons.image_outlined, color: textSecondary.withValues(alpha: 0.5), size: 28),
                            ),
                            const SizedBox(width: 16),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text('${item.unitPrice} YER', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => ref.read(posNotifierProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                                    borderRadius: BorderRadius.circular(100),
                                    child: Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.remove, size: 20, color: textSecondary)),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 30),
                                    alignment: Alignment.center,
                                    child: Text('${item.quantity.toInt()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                                  ),
                                  InkWell(
                                    onTap: () => ref.read(posNotifierProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                                    borderRadius: BorderRadius.circular(100),
                                    child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.add, size: 20, color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete Button
                            InkWell(
                              onTap: () => ref.read(posNotifierProvider.notifier).updateQuantity(item.id, 0),
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Cart Totals & Checkout
          Container(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).padding.bottom + 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
              ]
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.total, style: TextStyle(fontSize: 20, color: textSecondary, fontWeight: FontWeight.bold)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${posState.totals.grandTotal.toStringAsFixed(2)} YER', style: TextStyle(fontSize: 28, color: textColor, fontWeight: FontWeight.w900)),
                        Text(loc.vat, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: posState.cart.isEmpty ? null : () {
                    Navigator.pop(context); // Close cart sheet
                    showModalBottomSheet<void>(
                      context: context, 
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PaymentModal()
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: borderColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // Pill shape
                    elevation: posState.cart.isEmpty ? 0 : 8,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(loc.pay, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
