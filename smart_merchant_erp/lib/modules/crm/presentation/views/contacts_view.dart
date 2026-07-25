import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import 'customers_list_view.dart';
import 'suppliers_list_view.dart';

class ContactsView extends ConsumerStatefulWidget {
  const ContactsView({super.key});

  @override
  ConsumerState<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends ConsumerState<ContactsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                  Tab(text: 'العملاء'),
                  Tab(text: 'الموردين'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [CustomersListView(), SuppliersListView()],
          ),
        ),
      ],
    );
  }
}
