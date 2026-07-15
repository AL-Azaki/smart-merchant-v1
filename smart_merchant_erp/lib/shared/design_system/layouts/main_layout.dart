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
          padding: const EdgeInsets.only(top: 40, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User & Business Info
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Text('B', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            'المدير العام', 
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('مسؤول', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      Text(
                        loc.appTitle + ' • الفرع الرئيسي', 
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11)
                      ),
                    ],
                  ),
                ],
              ),
              // Status & Notifications
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), spreadRadius: 2)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'متصل', 
                          style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  )
                ],
              )
            ],
          ),
        ),
      ),
      
      // 2. Main Content & Floating Dock
      body: Stack(
        children: [
          // Content Area
          Positioned.fill(
            child: child,
          ),
          
          // Floating Bottom Navigation (Glassmorphism Effect)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), 
                        blurRadius: 20, 
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final activeModules = ref.watch(modulesNotifierProvider);
                      // In Flutter, Row automatically reverses order if Directionality is RTL.
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNavItem(context, 0, Icons.home_rounded, loc.home, isDark),
                          if (activeModules.contains(ErpModule.sales))
                            _buildNavItem(context, 1, Icons.shopping_cart_rounded, loc.sales, isDark),
                          if (activeModules.contains(ErpModule.inventory))
                            _buildNavItem(context, 2, Icons.inventory_2_rounded, loc.inventory, isDark),
                          if (activeModules.contains(ErpModule.accounting))
                            _buildNavItem(context, 3, Icons.account_balance_wallet_rounded, loc.accounting, isDark),
                          if (activeModules.contains(ErpModule.settings))
                            _buildNavItem(context, 4, Icons.settings_rounded, loc.settings, isDark),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, bool isDark) {
    final isActive = currentIndex == index;
    final color = isActive 
        ? AppColors.primary 
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return GestureDetector(
      onTap: () => _onNavigate(context, index),
      behavior: HitTestBehavior.opaque, // Ensures the whole area is clickable
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            )
          ],
        ),
      ),
    );
  }
}
