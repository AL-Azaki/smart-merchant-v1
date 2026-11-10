import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../sales/presentation/providers/online_orders_provider.dart';
import '../providers/storefront_settings_provider.dart';
import 'business_profile_view.dart';
import 'storefront_settings_view.dart';
import 'tabs/storefront_catalog_tab.dart';
import 'tabs/storefront_customer_simulator_tab.dart';
import 'tabs/storefront_orders_tab.dart';

class StorefrontHubView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const StorefrontHubView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<StorefrontHubView> createState() => _StorefrontHubViewState();
}

class _StorefrontHubViewState extends ConsumerState<StorefrontHubView>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 4;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabCount - 1),
    );
  }

  void _rebuildControllerIfNeeded({int? targetIndex}) {
    if (_tabController.length != _tabCount) {
      final oldIndex = targetIndex ?? _tabController.index.clamp(0, _tabCount - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: _tabCount,
        vsync: this,
        initialIndex: oldIndex,
      );
    }
  }

  @override
  void didUpdateWidget(StorefrontHubView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildControllerIfNeeded();
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final target = widget.initialTabIndex.clamp(0, _tabCount - 1);
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _rebuildControllerIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToTab(int index) {
    _rebuildControllerIfNeeded();
    final target = index.clamp(0, _tabController.length - 1);
    if (_tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  Future<void> _copyStoreUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'تم نسخ رابط المتجر الإلكتروني بنجاح',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  Future<void> _shareStoreUrl(String url, String storeName) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'تسوق الآن أونلاين من $storeName عبر الرابط المباشر:\n$url',
        subject: 'رابط $storeName',
      ),
    );
  }

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _switchToTab(2);
    }
  }

  Widget _buildStoreLogoAvatar(String? logoPath, String storeName, bool isDark) {
    if (logoPath != null && logoPath.trim().isNotEmpty) {
      final path = logoPath.trim();
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            path,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackInitial(storeName),
          ),
        );
      }
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackInitial(storeName),
          ),
        );
      }
    }
    return _buildFallbackInitial(storeName);
  }

  Widget _buildFallbackInitial(String storeName) {
    final initial =
        storeName.trim().isNotEmpty ? storeName.trim().substring(0, 1) : 'م';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),
            Color(0xFF0D9488),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _rebuildControllerIfNeeded();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final unselectedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final currentBusiness =
        ref.watch(currentBusinessEntityProvider).valueOrNull;
    final settingsState = ref.watch(storefrontSettingsProvider);
    final settings = settingsState.settings;
    final isStoreActive = settings?.storefrontActive ?? true;

    final storeName = (currentBusiness?.businessName.trim().isNotEmpty ?? false)
        ? currentBusiness!.businessName.trim()
        : (settings?.storefrontDisplayName?.trim().isNotEmpty ?? false
            ? settings!.storefrontDisplayName!.trim()
            : 'متجري الإلكتروني');

    final storeUrl = settings?.storeUrl ??
        'http://localhost:3000/store/${settings?.storefrontSlug ?? 'smart-store'}';
    final logoPath = currentBusiness?.logoPath;

    final ordersAsync = ref.watch(onlineOrdersNotifierProvider);
    final pendingOrdersCount = ordersAsync.valueOrNull
            ?.where(
              (o) =>
                  o.status.toUpperCase() == 'PENDING' && o.deletedAt == null,
            )
            .length ??
        0;

    final productsAsync = ref.watch(productsNotifierProvider);
    final publishedProductsCount = productsAsync.valueOrNull
            ?.where((p) => p.showInStore && p.isActive && p.deletedAt == null)
            .length ??
        0;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Top Command Bar + Tabs
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1.5),
              ),
            ),
            child: Column(
              children: [
                // Store Identity & Quick Actions Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStoreLogoAvatar(logoPath, storeName, isDark),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    storeName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isStoreActive
                                          ? AppColors.success
                                              .withValues(alpha: 0.14)
                                          : const Color(0xFF64748B)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isStoreActive
                                                ? AppColors.success
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isStoreActive
                                              ? 'متجر معتمد ومُدار مركزياً'
                                              : 'بانتظار تفعيل الإدارة',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isStoreActive
                                                ? AppColors.success
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storeUrl,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Quick Storefront Actions
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyStoreUrl(storeUrl),
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text(
                              'نسخ الرابط',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _shareStoreUrl(storeUrl, storeName),
                            icon: const Icon(Icons.share_rounded, size: 15),
                            label: const Text(
                              'مشاركة',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openInBrowser(storeUrl),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                            ),
                            label: const Text(
                              'فتح بالمتصفح',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3 Focused Operational Tabs
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: MediaQuery.of(context).size.width < 640,
                    tabAlignment: MediaQuery.of(context).size.width < 640
                        ? TabAlignment.start
                        : TabAlignment.fill,
                    indicator: BoxDecoration(
                      color: AppColors.primary
                          .withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: unselectedColor,
                    labelStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: unselectedColor,
                      fontFamily: 'Cairo',
                    ),
                    tabs: [
                      // Tab 0: Orders & Overview
                      Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_rounded, size: 18),
                            const SizedBox(width: 6),
                            const Text('الطلبات والأداء'),
                            if (pendingOrdersCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$pendingOrdersCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Tab 1: Store Catalog
                      Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_rounded, size: 18),
                            const SizedBox(width: 6),
                            const Text('منتجات المتجر'),
                            if (publishedProductsCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$publishedProductsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Tab 2: Live Customer Simulator
                      const Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('معاينة المتجر كعميل'),
                          ],
                        ),
                      ),

                      // Tab 3: Storefront Settings
                      const Tab(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('إعدادات المتجر'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StorefrontOrdersTab(
                  onOpenSimulator: () => _switchToTab(2),
                  onOpenCatalog: () => _switchToTab(1),
                ),
                StorefrontCatalogTab(
                  onOpenSimulator: () => _switchToTab(2),
                ),
                StorefrontCustomerSimulatorTab(
                  onNavigateToOrders: () => _switchToTab(0),
                  onNavigateToCatalog: () => _switchToTab(1),
                ),
                StorefrontSettingsView(
                  isEmbedded: true,
                  onOpenLiveSimulator: () => _switchToTab(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
