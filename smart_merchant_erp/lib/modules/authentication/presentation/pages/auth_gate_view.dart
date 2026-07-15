import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../kernel/locale/locale_provider.dart';
import '../../../../shared/design_system/theme/theme_provider.dart';

class AuthGateView extends ConsumerWidget {
  const AuthGateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Background gradient that adapts slightly based on theme
    final bgColors = isDark 
        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
        : [const Color(0xFF4F46E5), const Color(0xFF0EA5E9)];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Gradient Hero
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar (Toggles)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Empty space to balance
                      const SizedBox(width: 48),
                      // Toggles
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              ref.read(localeNotifierProvider.notifier).toggleLocale();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ref.read(localeNotifierProvider).languageCode == 'ar' ? 'EN' : 'عربي',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(themeNotifierProvider.notifier).toggleTheme();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Hero Texts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8))
                          ]
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc.appTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.authGateSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Interactive Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 40,
                          offset: const Offset(0, -10),
                        )
                      ]
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            loc.authGateWelcome,
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Primary CTA
                          ElevatedButton(
                            onPressed: () {
                              context.push('/register');
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                                const SizedBox(width: 12),
                                Text(loc.startFreeTrial, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Secondary CTA
                          OutlinedButton(
                            onPressed: () {
                              context.push('/login');
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              side: BorderSide(color: AppColors.borderLight, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, color: isDark ? Colors.white : AppColors.textPrimaryLight, size: 22),
                                const SizedBox(width: 12),
                                Text(
                                  loc.login, 
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight, 
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w800
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // Trust Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTrustBadge(Icons.security_rounded, 'آمن ومشفر', isDark),
                              const SizedBox(width: 24),
                              _buildTrustBadge(Icons.cloud_sync_rounded, 'مزامنة سحابية', isDark),
                              const SizedBox(width: 24),
                              _buildTrustBadge(Icons.support_agent_rounded, 'دعم فني', isDark),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
