import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../providers/pos_provider.dart';
import '../providers/product_unit_provider.dart';
import '../widgets/voucher_modal.dart';
import '../widgets/returns_modal.dart';
import '../widgets/customer_select_modal.dart';
import '../widgets/customer_add_modal.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/payment_modal.dart';

class PosView extends ConsumerWidget {
  const PosView({super.key});

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildOutlineAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    final bgColor = color.withValues(alpha: isDark ? 0.15 : 0.05);
    final borderColor = color.withValues(alpha: isDark ? 0.3 : 0.5);
    final textColor = isDark && color == AppColors.primary
        ? AppColors.primaryLight
        : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          color: bgColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final posState = ref.watch(posNotifierProvider);
    final int totalItems = posState.cart.fold(
      0,
      (sum, item) => sum + item.quantity.toInt(),
    );
    final productsAsync = ref.watch(posProductsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. TOP ACTION BAR (Invoice Data)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Invoice Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.invoiceNumber,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'سيتم التعيين عند الإصدار',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildVerticalDivider(isDark),

                // Currency Selector
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12, left: 8),
                        child: Icon(
                          Icons.payments_outlined,
                          color: textSecondary,
                          size: 20,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'YER',
                          dropdownColor: surfaceColor,
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.keyboard_arrow_down, size: 16),
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'YER', child: Text('YER')),
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                          ],
                          onChanged: (val) {},
                        ),
                      ),
                    ],
                  ),
                ),

                _buildVerticalDivider(isDark),

                // Customer Selection & Add
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: posState.customerName != null
                        ? AppColors.success.withValues(alpha: 0.05)
                        : bgColor,
                    border: Border.all(
                      color: posState.customerName != null
                          ? AppColors.success.withValues(alpha: 0.3)
                          : borderColor,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => const CustomerSelectModal(),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: posState.customerName != null
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : (isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.borderLight),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: posState.customerName != null
                                      ? AppColors.success
                                      : textSecondary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    posState.customerName ?? loc.chooseCustomer,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: posState.customerName != null
                            ? AppColors.success.withValues(alpha: 0.3)
                            : borderColor,
                      ),
                      InkWell(
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => const CustomerAddModal(),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.add,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24), // Gap before actions
                // Actions: Add Voucher
                _buildOutlineAction(
                  context,
                  Icons.add_circle_outline,
                  loc.addVoucher,
                  AppColors.primary,
                  () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const VoucherModal(),
                    );
                  },
                  isDark,
                ),

                _buildVerticalDivider(isDark),

                // Held & Hold
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pause_circle_outline_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.hold,
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 48, color: borderColor),
                      InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.list_alt_rounded,
                                color: textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.heldInvoices(2),
                                style: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildVerticalDivider(isDark),

                // Returns
                _buildOutlineAction(
                  context,
                  Icons.keyboard_return_rounded,
                  loc.returns,
                  AppColors.error,
                  () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const ReturnsModal(),
                    );
                  },
                  isDark,
                ),
              ],
            ),
          ),
        ),

        // 2. SEARCH, VOICE & FILTERS BAR
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Main Search Field
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.search_rounded, color: textSecondary),
                      ),
                      Expanded(
                        child: TextField(
                          style: TextStyle(color: textColor, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: loc.searchProducts,
                            hintStyle: TextStyle(color: textSecondary),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.only(bottom: 4),
                          ),
                        ),
                      ),
                      // Barcode Icon
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: textSecondary,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Voice Search Button
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),

              // Filter Icon Button
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune_rounded, color: textSecondary),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // TODO: Open categories bottom sheet
                  },
                ),
              ),
            ],
          ),
        ),

        // 3. MAIN PRODUCT GRID (With Floating Cart)
        Expanded(
          child: Stack(
            children: [
              // Products Grid Area
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 5
                        : (constraints.maxWidth > 600 ? 4 : 2);
                    final aspectRatio = constraints.maxWidth > 600 ? 0.8 : 0.7;

                    return productsAsync.when(
                      data: (products) {
                        if (products.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد منتجات',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }
                        return GridView.builder(
                          // Extra bottom padding so floating cart does not hide items
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                            bottom: 200,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(
                              products[index],
                              ref,
                              isDark,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    );
                  },
                ),
              ),

              // Floating Cart Bar
              _buildFloatingCartBar(
                context,
                ref,
                isDark,
                posState,
                totalItems,
                loc,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCartBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    PosState posState,
    int totalItems,
    AppLocalizations loc,
  ) {
    if (totalItems == 0) return const SizedBox.shrink();

    // Sits at bottom 100 to stay above the MainLayout dock
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Max width for large screens
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors
                  .primary, // Solid primary color for extreme premium contrast
              borderRadius: BorderRadius.circular(100), // Pill shape
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cart summary
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CartBottomSheet(),
                      );
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '$totalItems',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.cart,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${posState.totals.grandTotal.toStringAsFixed(2)} YER',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pay Button
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PaymentModal(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.pay,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, bool isDark) {
    final bgColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : Colors.white);
    final textColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(PosProductItem posItem, WidgetRef ref, bool isDark) {
    final product = posItem.product;
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return InkWell(
      onTap: () {
        ref
            .read(posNotifierProvider.notifier)
            .addProduct(
              id: product.id,
              name: product.productName,
              price: posItem.sellingPrice,
              productUnitId: posItem.baseUnit.id,
            );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : const Color(0xFFF3F4F6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ), // Default icon
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'منتج', // Fallback category text, actual logic would require joining categories
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${posItem.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
