import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';

class PurchaseListView extends ConsumerStatefulWidget {
  final VoidCallback onNewPurchase;

  const PurchaseListView({super.key, required this.onNewPurchase});

  @override
  ConsumerState<PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends ConsumerState<PurchaseListView> {
  String _searchQuery = '';
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فواتير المشتريات',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '0 فاتورة',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PrimaryButton(
                text: 'فاتورة مشتريات جديدة',
                icon: Icons.add,
                onPressed: widget.onNewPurchase,
              ),
            ],
          ),
        ),
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'ابحث برقم الفاتورة أو المورد...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
        // Status Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _buildFilterChip('الكل', null, isDark),
              const SizedBox(width: 8),
              _buildFilterChip('مسودة', 'Draft', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('مرحلة', 'Posted', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('ملغاة', 'Cancelled', isDark),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Data Grid / Empty State
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد فواتير مشتريات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'قم بإنشاء فاتورة مشتريات جديدة لإضافتها هنا.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? statusId, bool isDark) {
    final active = _statusFilter == statusId;
    return InkWell(
      onTap: () => setState(() => _statusFilter = statusId),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          border: Border.all(
            color: active
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? AppColors.primary
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
