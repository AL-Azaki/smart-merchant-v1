import 'package:flutter/material.dart';
import 'package:smart_merchant_erp/l10n/app_localizations.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/typography.dart';
import '../views/pos_view.dart';
import '../views/sales_list_view.dart';
import '../views/orders_list_view.dart';

class SalesLayout extends StatefulWidget {
  final int initialTabIndex;
  const SalesLayout({super.key, this.initialTabIndex = 0});

  @override
  State<SalesLayout> createState() => _SalesLayoutState();
}

class _SalesLayoutState extends State<SalesLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final unselectedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        toolbarHeight: 0, // إخفاء العنوان بالكامل لتوفير مساحة
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: MediaQuery.of(context).size.width < 600,
              tabAlignment: MediaQuery.of(context).size.width < 600 ? TabAlignment.start : TabAlignment.fill,
              indicatorColor: AppColors.primary,
              indicatorWeight: 4,
              labelColor: AppColors.primary,
              unselectedLabelColor: unselectedColor,
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
              unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              tabs: [
                Tab(
                  iconMargin: const EdgeInsets.only(bottom: 4), 
                  child: Row(children: [const Icon(Icons.add_shopping_cart_rounded, size: 20), const SizedBox(width: 8), Text(loc.newInvoicePos)])
                ),
                Tab(
                  iconMargin: const EdgeInsets.only(bottom: 4), 
                  child: Row(children: [const Icon(Icons.receipt_long_rounded, size: 20), const SizedBox(width: 8), Text(loc.salesInvoices)])
                ),
                Tab(
                  iconMargin: const EdgeInsets.only(bottom: 4), 
                  child: Row(children: [const Icon(Icons.shopping_bag_rounded, size: 20), const SizedBox(width: 8), Text(loc.ecommerceOrders)])
                ),
              ],
            ),
          ),
        ),
      ),
      // المحتوى الخاص بالتبويبات
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // منع السحب باليد لمنع أخطاء الكاشير أثناء البيع
        children: const [
          PosView(),
          SalesListView(),
          OrdersListView(),
        ],
      ),
    );
  }
}

