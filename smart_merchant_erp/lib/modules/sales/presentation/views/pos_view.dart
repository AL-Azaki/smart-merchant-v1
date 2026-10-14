import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/pos_provider.dart';
import '../widgets/pos_cart_panel.dart';
import '../widgets/pos_products_grid.dart';
import '../widgets/pos_sale_success_dialog.dart';
import '../widgets/pos_top_bar.dart';

/// The redesigned, high-agency POS interface.
/// Adapts gracefully between Tablet/Desktop Split-Screen (65/35) and Mobile Single Column.
class PosView extends ConsumerWidget {
  const PosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Listen for state mutations (Success or Error)
    ref.listen<PosState>(posNotifierProvider, (previous, next) {
      if (previous?.error == null && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(posNotifierProvider.notifier).clearError();
      }

      if (previous?.successInvoiceId == null && next.successInvoiceId != null) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PosSaleSuccessDialog(
            invoiceId: next.successInvoiceId!,
          ),
        ).then((_) {
          ref.read(posNotifierProvider.notifier).clearSuccess();
        });
      }
    });

    final posState = ref.watch(posNotifierProvider);
    final int totalCartItems = posState.cart.fold(
      0,
      (sum, item) => sum + item.quantity.toInt(),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // 1. TOP MINIMAL ACTION BAR WITH INTEGRATED SEARCH
          const PosTopBar(),

          // 2. MAIN ADAPTIVE BODY
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 768;

                if (isTablet) {
                  // DUAL-COLUMN SPLIT SCREEN (TABLET / POS TERMINAL)
                  return Row(
                    children: [
                      // Products Catalog Grid (65% width)
                      const Expanded(
                        flex: 65,
                        child: PosProductsGrid(),
                      ),

                      // Permanent Docked Cart Panel (35% width, min 340dp)
                      Container(
                        width: 1,
                        color: borderColor,
                      ),
                      const Expanded(
                        flex: 35,
                        child: PosCartPanel(),
                      ),
                    ],
                  );
                } else {
                  // SINGLE-COLUMN WITH BOTTOM DRAWER (MOBILE SMARTPHONE)
                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: PosProductsGrid(),
                      ),

                      // Floating Bottom Cart Bar for Mobile
                      if (posState.cart.isNotEmpty)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => Container(
                                  height: MediaQuery.of(context).size.height * 0.85,
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: const ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                    child: PosCartPanel(),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$totalCartItems قطع في السلة',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${posState.totals.grandTotal.toStringAsFixed(0)} ${posState.currencyId}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Quick Cash Button inside the mobile bar
                                  ElevatedButton.icon(
                                    onPressed: posState.isSubmitting
                                        ? null
                                        : () {
                                            ref.read(posNotifierProvider.notifier).submitSale(
                                                  cashReceived: posState.totals.grandTotal,
                                                  paymentMethodId: 'CASH',
                                                );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                    label: const Text(
                                      'كاش فوري',
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
}
}
