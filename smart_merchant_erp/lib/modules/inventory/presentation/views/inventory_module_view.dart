import 'package:flutter/material.dart';
import '../../../catalog/presentation/views/products_view.dart';
import '../../../purchasing/presentation/views/purchases_view.dart';
import '../../../crm/presentation/views/contacts_view.dart';
import '../widgets/inventory_navigation_tabs.dart';
import 'inventory_reports_view.dart';
import 'inventory_workspace_view.dart';

class InventoryModuleView extends StatelessWidget {
  const InventoryModuleView({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
    length: 5,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          InventoryNavigationTabs(
            tabs: [
              InventoryTab('المنتجات', Icons.inventory_2_outlined),
              InventoryTab('المشتريات', Icons.shopping_bag_outlined),
              InventoryTab('العملاء والموردين', Icons.people_outline_rounded),
              InventoryTab('المخزن والجرد', Icons.warehouse_outlined),
              InventoryTab('التقارير المخزنية', Icons.assessment_outlined),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                ProductsView(),
                PurchasesView(),
                ContactsView(),
                InventoryWorkspaceView(),
                InventoryReportsView(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
