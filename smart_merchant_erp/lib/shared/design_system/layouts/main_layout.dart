import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../kernel/security/permissions_provider.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/sales');
        break;
      case 2:
        context.go('/inventory');
        break;
      case 3:
        context.go('/accounting');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 1. Premium Top Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.only(
            top: 40,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notification Bell (Right on RTL)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 22),
                  onPressed: () {},
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  tooltip: 'الإشعارات',
                ),
              ),

              // Center Brand Title ("Smart Merchant \n التاجر الذكي")
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Smart Merchant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'التاجر الذكي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // User Profile Avatar "B" (Left on RTL)
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'B',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 2. Main Content & Floating Dock
      extendBody: false,
      body: child,
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final activeModules = ref.watch(modulesNotifierProvider);
                    // In Flutter, Row automatically reverses order if Directionality is RTL.
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(
                          context,
                          0,
                          Icons.home_rounded,
                          loc.home,
                          isDark,
                        ),
                        if (activeModules.contains(ErpModule.sales))
                          _buildNavItem(
                            context,
                            1,
                            Icons.shopping_cart_rounded,
                            loc.sales,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.inventory))
                          _buildNavItem(
                            context,
                            2,
                            Icons.inventory_2_rounded,
                            loc.inventory,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.accounting))
                          _buildNavItem(
                            context,
                            3,
                            Icons.attach_money_rounded,
                            loc.accounting,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.settings))
                          _buildNavItem(
                            context,
                            4,
                            Icons.settings_rounded,
                            loc.settings,
                            isDark,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isDark,
  ) {
    final isActive = currentIndex == index;
    final color = isActive
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return GestureDetector(
      onTap: () => _onNavigate(context, index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
