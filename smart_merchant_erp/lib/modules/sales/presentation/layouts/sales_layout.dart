import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/online_orders_provider.dart';
import '../providers/pos_provider.dart';
import '../views/pos_view.dart';
import '../views/sales_list_view.dart';
import '../views/orders_list_view.dart';

/// InheritedWidget that exposes the tab controller for child widgets
/// (e.g., Online Orders → POS handoff navigation).
class SalesTabScope extends InheritedWidget {
  final TabController tabController;

  const SalesTabScope({
    super.key,
    required this.tabController,
    required super.child,
  });

  static SalesTabScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SalesTabScope>();
  }

  @override
  bool updateShouldNotify(SalesTabScope oldWidget) {
    return tabController != oldWidget.tabController;
  }
}

class SalesLayout extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const SalesLayout({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<SalesLayout> createState() => _SalesLayoutState();
}

class _SalesLayoutState extends ConsumerState<SalesLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final unselectedColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    // Dynamic Live State Badges
    final posState = ref.watch(posNotifierProvider);
    final int cartItemsCount = posState.cart.fold(
      0,
      (sum, item) => sum + item.quantity.toInt(),
    );

    final ordersAsync = ref.watch(onlineOrdersNotifierProvider);
    final int pendingOrdersCount = ordersAsync.asData?.value
            .where((o) => o.status.toUpperCase() == 'PENDING' && o.deletedAt == null)
            .length ??
        0;

    return SalesTabScope(
      tabController: _tabController,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.5),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: MediaQuery.of(context).size.width < 600,
                tabAlignment: MediaQuery.of(context).size.width < 600
                    ? TabAlignment.start
                    : TabAlignment.fill,
                indicator: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: unselectedColor,
                  fontFamily: 'Cairo',
                ),
                tabs: [
                  // Tab 1: New Invoice / POS
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.point_of_sale_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(loc.newInvoicePos),
                        if (cartItemsCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$cartItemsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 2: Sales Invoices
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(loc.salesInvoices),
                      ],
                    ),
                  ),

                  // Tab 3: Online Store Orders
                  Tab(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(loc.ecommerceOrders),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [PosView(), SalesListView(), OrdersListView()],
        ),
      ),
    );
  }
}
