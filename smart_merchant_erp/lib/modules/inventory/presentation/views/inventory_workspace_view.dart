import 'package:flutter/material.dart';
import '../widgets/inventory_navigation_tabs.dart';
import 'warehouses/warehouses_view.dart';
import 'stock_counts/stock_counts_view.dart';
import 'stock_adjustments/stock_adjustments_view.dart';
import 'transfers/warehouse_transfers_view.dart';

class InventoryWorkspaceView extends StatefulWidget {
  const InventoryWorkspaceView({super.key});
  @override
  State<InventoryWorkspaceView> createState() => _InventoryWorkspaceViewState();
}

class _InventoryWorkspaceViewState extends State<InventoryWorkspaceView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const DefaultTabController(
      length: 4,
      child: Column(
        children: [
          InventoryNavigationTabs(
            compact: true,
            tabs: [
              InventoryTab('المستودعات والمخازن', Icons.warehouse_rounded),
              InventoryTab('الجرد التصحيحي', Icons.fact_check_outlined),
              InventoryTab('التحويلات', Icons.swap_horiz_rounded),
              InventoryTab('التسويات', Icons.tune_rounded),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                WarehousesView(),
                StockCountsView(),
                WarehouseTransfersView(),
                StockAdjustmentsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
