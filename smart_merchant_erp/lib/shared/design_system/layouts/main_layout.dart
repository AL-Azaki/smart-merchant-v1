import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../kernel/security/permissions_provider.dart';
import '../../../kernel/sync/coordinator/sync_coordinator.dart';
import '../../../modules/platform/presentation/providers/sync_provider.dart';
import '../../../modules/authentication/presentation/providers/session_provider.dart';
import '../../../modules/authentication/presentation/providers/auth_provider.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/subscription_warning_banner.dart';

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
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // 1. Premium Top Bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: Container(
          padding: const EdgeInsets.only(
            top: 32,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: 10,
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
              // User Profile Avatar with active user initial & Quick Menu (Right on RTL)
              Consumer(
                builder: (context, ref, _) {
                  final activeUser = ref.watch(activeUserProvider);
                  final initial = activeUser.name.trim().isNotEmpty
                      ? activeUser.name.trim().substring(0, 1)
                      : 'م';
                  return Tooltip(
                    message: '${activeUser.name} (${activeUser.roleTitle}) - اضغط للتبديل أو تسجيل الخروج',
                    child: InkWell(
                      onTap: () => _showUserAccountMenu(context, ref),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEDE9FE),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeUser.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  activeUser.roleTitle,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Center Brand Title & Connectivity Status
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
                  const SizedBox(height: 2),
                  Consumer(
                    builder: (context, ref, _) {
                      final session = ref.watch(sessionNotifierProvider);
                      final syncState = ref.watch(syncNotifierProvider);
                      final isOffline = (session.isOffline == true) || (syncState.status == SyncStatus.offline);

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOffline ? 'وضع محلي (بدون خادم)' : 'متصل بالسحابة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isOffline ? const Color(0xFFD97706) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              // Action icons (Sync + Notifications)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync Button
                  Consumer(
                    builder: (context, ref, _) {
                      final syncState = ref.watch(syncNotifierProvider);
                      final isSyncing = syncState.status == SyncStatus.syncing;

                      return Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: IconButton(
                          icon: isSyncing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 22),
                          onPressed: isSyncing
                              ? null
                              : () async {
                                  await ref.read(syncNotifierProvider.notifier).syncNow();
                                  if (context.mounted) {
                                    final currentSync = ref.read(syncNotifierProvider);
                                    if (currentSync.status == SyncStatus.offline || currentSync.status == SyncStatus.failure) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text('السيرفر غير متصل حالياً - النظام يعمل بكامل وظائفه محلياً وبياناتك محفوظة بأمان'),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Color(0xFF334155),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text('تمت مزامنة البيانات والطلبات بنجاح مع السيرفر'),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Color(0xFF10B981),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                          color: AppColors.primary,
                          tooltip: 'مزامنة السحابة والطلبات',
                        ),
                      );
                    },
                  ),

                  // Notification Bell
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

                  // Dedicated Logout Button (Prominent & Clear)
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D1515) : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      onPressed: () => _confirmLogout(context, ref),
                      color: const Color(0xFFDC2626),
                      tooltip: 'تسجيل الخروج',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // 2. Main Content & Floating Dock
      extendBody: false,
      body: Column(
        children: [
          const SubscriptionWarningBanner(),
          Consumer(
            builder: (context, ref, _) {
              final session = ref.watch(sessionNotifierProvider);
              final syncState = ref.watch(syncNotifierProvider);
              final isOffline = (session.isOffline == true) || (syncState.status == SyncStatus.offline);
              if (!isOffline) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الوضع المحلي: التطبيق يعمل بكفاءة بدون خادم، وبياناتك ومبيعاتك محفوظة بأمان',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: child),
        ],
      ),
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
                    final currentUser = ref.watch(activeUserProvider);
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
                        if (activeModules.contains(ErpModule.sales) && currentUser.canView(SystemModules.sales))
                          _buildNavItem(
                            context,
                            1,
                            Icons.shopping_cart_rounded,
                            loc.sales,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.inventory) && currentUser.canView(SystemModules.inventory))
                          _buildNavItem(
                            context,
                            2,
                            Icons.inventory_2_rounded,
                            loc.inventory,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.accounting) && currentUser.canView(SystemModules.finance))
                          _buildNavItem(
                            context,
                            3,
                            Icons.attach_money_rounded,
                            loc.accounting,
                            isDark,
                          ),
                        if (activeModules.contains(ErpModule.settings) && currentUser.canView(SystemModules.settings))
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

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final activeUser = ref.read(activeUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'هل تريد تسجيل الخروج من حساب (${activeUser.name}) والعودة لشاشة الدخول؟',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _showUserAccountMenu(BuildContext context, WidgetRef ref) {
    final activeUser = ref.read(activeUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // User Info Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        activeUser.name.isNotEmpty ? activeUser.name.substring(0, 1) : 'م',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                activeUser.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activeUser.roleTitle,
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${activeUser.username} • ${activeUser.branch}',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Switch user section
                Text(
                  'تبديل سريع للمستخدم',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),

                FutureBuilder<List<AppUserModel>>(
                  future: UserPermissionsService.loadUsers(),
                  builder: (context, snapshot) {
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: users.map((u) {
                        final isCurrent = u.id == activeUser.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF3B82F6)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isCurrent ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                              child: Text(
                                u.name.isNotEmpty ? u.name.substring(0, 1) : 'م',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              u.name,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text('${u.roleTitle} (@${u.username})', style: const TextStyle(fontSize: 11)),
                            trailing: isCurrent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('الحالي', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                  )
                                : TextButton(
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      await ref.read(activeUserProvider.notifier).switchUser(u.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('تم التبديل إلى المستخدم: ${u.name} (${u.roleTitle})'),
                                            backgroundColor: const Color(0xFF10B981),
                                          ),
                                        );
                                        if (!u.can(SystemModules.settings, 'view')) {
                                          context.go('/');
                                        }
                                      }
                                    },
                                    child: const Text('تبديل'),
                                  ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Logout button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmLogout(context, ref);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('تسجيل الخروج والعودة لشاشة الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

}
