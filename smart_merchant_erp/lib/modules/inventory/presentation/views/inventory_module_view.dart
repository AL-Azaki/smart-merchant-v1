import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/presentation/views/products_view.dart';
import '../../../crm/presentation/views/contacts_view.dart';
import '../../../purchasing/presentation/views/purchases_view.dart';
import '../../../../kernel/security/permissions_provider.dart';
import '../widgets/inventory_navigation_tabs.dart';
import 'inventory_workspace_view.dart';

class InventoryModuleView extends ConsumerWidget {
  const InventoryModuleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);

    final tabs = <InventoryTab>[];
    final views = <Widget>[];

    // 1. Products (Inventory module)
    if (activeUser.canView(SystemModules.inventory)) {
      tabs.add(const InventoryTab('المنتجات', Icons.inventory_2_outlined));
      views.add(const ProductsView());
    }

    // 2. Purchases (Purchases module)
    if (activeUser.canView(SystemModules.purchases)) {
      tabs.add(const InventoryTab('المشتريات', Icons.shopping_bag_outlined));
      views.add(const PurchasesView());
    }

    // 3. Customers & Suppliers (Sales module)
    if (activeUser.canView(SystemModules.sales)) {
      tabs.add(const InventoryTab('العملاء والموردين', Icons.people_outline_rounded));
      views.add(const ContactsView());
    }

    // 4. Warehouse & Stock Counts (Inventory module)
    if (activeUser.canView(SystemModules.inventory)) {
      tabs.add(const InventoryTab('المخزن والجرد', Icons.warehouse_outlined));
      views.add(const InventoryWorkspaceView());
    }

    if (tabs.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'عفواً، ليس لديك صلاحية عرض أي قسم في هذه الشاشة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            InventoryNavigationTabs(tabs: tabs),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: views,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
