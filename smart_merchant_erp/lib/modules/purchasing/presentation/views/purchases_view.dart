import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import 'purchase_list_view.dart';
import 'new_purchase_view.dart';
import 'purchase_returns_view.dart';

class PurchasesView extends ConsumerStatefulWidget {
  const PurchasesView({super.key});

  @override
  ConsumerState<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends ConsumerState<PurchasesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCreatingNew) {
      return NewPurchaseView(
        onBack: () => setState(() => _isCreatingNew = false),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                tabs: const [
                  Tab(text: 'فواتير المشتريات'),
                  Tab(text: 'مرتجع المشتريات'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              PurchaseListView(
                onNewPurchase: () => setState(() => _isCreatingNew = true),
              ),
              const PurchaseReturnsView(),
            ],
          ),
        ),
      ],
    );
  }
}
