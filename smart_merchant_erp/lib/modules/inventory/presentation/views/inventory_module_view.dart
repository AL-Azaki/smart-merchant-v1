import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../catalog/presentation/views/products_view.dart';
import '../../../purchasing/presentation/views/purchases_view.dart';
import '../../../crm/presentation/views/contacts_view.dart';
import '../../../hr/presentation/views/employees_view.dart';
import '../../../fixed_assets/presentation/views/fixed_assets_view.dart';
import '../../../documents/presentation/views/documents_view.dart';
import 'stock_adjustments/stock_adjustments_view.dart';
import 'stock_counts/stock_counts_view.dart';

class InventoryModuleView extends ConsumerStatefulWidget {
  const InventoryModuleView({super.key});

  @override
  ConsumerState<InventoryModuleView> createState() =>
      _InventoryModuleViewState();
}

class _InventoryModuleViewState extends ConsumerState<InventoryModuleView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'id': 'products', 'label': 'المنتجات', 'icon': Icons.inventory_2_outlined},
    {
      'id': 'purchases',
      'label': 'المشتريات',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'id': 'contacts',
      'label': 'العملاء والموردين',
      'icon': Icons.people_outline,
    },
    {'id': 'employees', 'label': 'الموظفين', 'icon': Icons.badge_outlined},
    {
      'id': 'assets',
      'label': 'الأصول الثابتة',
      'icon': Icons.business_center_outlined,
    },
    {
      'id': 'documents',
      'label': 'الأرشيف والمستندات',
      'icon': Icons.folder_open_outlined,
    },
    {
      'id': 'adjustments',
      'label': 'تسوية وجرد المخزون',
      'icon': Icons.fact_check_outlined,
    },
    {
      'id': 'stock_counts',
      'label': 'جلسات الجرد',
      'icon': Icons.inventory_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
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
            indicatorColor: AppColors.primary,
            indicatorWeight: 4,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            tabs: _tabs.map((tab) {
              return Tab(
                iconMargin: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(tab['icon'] as IconData, size: 20),
                    const SizedBox(width: 8),
                    Text(tab['label'] as String),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductsView(),
          PurchasesView(),
          ContactsView(),
          EmployeesView(),
          FixedAssetsView(),
          DocumentsView(),
          StockAdjustmentsView(),
          StockCountsView(),
        ],
      ),
    );
  }
}
