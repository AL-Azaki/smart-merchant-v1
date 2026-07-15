import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/stat_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Consistent text colors based on theme
    final titleColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SingleChildScrollView(
      // Padding bottom 120 ensures content doesn't hide behind the floating dock
      padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.md, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Financial Snapshot (Horizontal Scroll)
          Text(
            loc.financialSnapshot, 
            style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w800)
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 135,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildStatWrapper(
                  StatCard(
                    title: loc.todaysSales, 
                    value: '45,000 ﷼', 
                    icon: Icons.shopping_cart_rounded, 
                    iconColor: isDark ? AppColors.primaryLight : AppColors.primary, 
                    iconBackgroundColor: isDark ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFEEECFC), 
                    trendText: '+5%', 
                    isTrendPositive: true
                  ),
                ),
                _buildStatWrapper(
                  StatCard(
                    title: loc.cashBalance, 
                    value: '150,000 ﷼', 
                    icon: Icons.account_balance_wallet_rounded, 
                    iconColor: AppColors.success, 
                    iconBackgroundColor: isDark ? AppColors.success.withValues(alpha: 0.2) : const Color(0xFFE7F8F3)
                  ),
                ),
                _buildStatWrapper(
                  StatCard(
                    title: loc.payables, 
                    value: '420,000 ﷼', 
                    icon: Icons.trending_up_rounded, 
                    iconColor: AppColors.error, 
                    iconBackgroundColor: isDark ? AppColors.error.withValues(alpha: 0.2) : const Color(0xFFFDECEE), 
                    trendText: '!', 
                    isTrendPositive: false
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Section 2: Quick Actions
          Text(
            loc.quickActions, 
            style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w800)
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.quickActionsSubtitle, 
            style: TextStyle(color: subtitleColor, fontSize: 13)
          ),
          const SizedBox(height: AppSpacing.lg),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.15, 
            children: [
              _buildQuickActionCard(context, loc.salesInvoice, loc.salesInvoiceDesc, Icons.add_shopping_cart_rounded, AppColors.primary, isDark, route: '/sales'),
              _buildQuickActionCard(context, loc.purchaseInvoice, loc.purchaseInvoiceDesc, Icons.inventory_rounded, const Color(0xFFEC4899), isDark),
              _buildQuickActionCard(context, loc.receiptVoucher, loc.receiptVoucherDesc, Icons.move_to_inbox_rounded, AppColors.success, isDark),
              _buildQuickActionCard(context, loc.paymentVoucher, loc.paymentVoucherDesc, Icons.outbox_rounded, AppColors.error, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatWrapper(Widget child) {
    return Container(
      width: 250, // Slightly wider for better text fit
      margin: const EdgeInsets.only(left: AppSpacing.md),
      child: child,
    );
  }

  Widget _buildQuickActionCard(BuildContext context, String title, String subtitle, IconData icon, Color baseColor, bool isDark, {String? route}) {
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final titleColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    // We adjust the icon color to be lighter on dark themes for better contrast if it's primary.
    final iconColor = (isDark && baseColor == AppColors.primary) ? AppColors.primaryLight : baseColor;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 2, // Soft elevation for light mode
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () {
          if (route != null) {
            GoRouter.of(context).push(route);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title, 
                style: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 14)
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: TextStyle(color: subtitleColor, fontSize: 11), 
                textAlign: TextAlign.center
              ),
            ],
          ),
        ),
      ),
    );
  }
}
