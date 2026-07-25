import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../catalog/presentation/providers/catalog_provider.dart';
import '../../providers/inventory_provider.dart';
import 'widgets/stock_adjustment_form_sheet.dart';

class StockAdjustmentsView extends ConsumerStatefulWidget {
  const StockAdjustmentsView({super.key});

  @override
  ConsumerState<StockAdjustmentsView> createState() =>
      _StockAdjustmentsViewState();
}

class _StockAdjustmentsViewState extends ConsumerState<StockAdjustmentsView> {
  String _searchQuery = '';

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
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تسوية وجرد المخزون',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '0 تسوية',
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
                text: 'تسوية جديدة',
                icon: Icons.add,
                onPressed: () {
                  // Fetch products from provider to pass to the form
                  final productsAsync = ref.read(productsNotifierProvider);
                  final products = productsAsync.valueOrNull ?? [];
                  
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: StockAdjustmentFormSheet(
                        products: products,
                        onClose: () => Navigator.pop(ctx),
                        onSave: (data) async {
                          // The form requires a warehouse id, let's inject a default one or get from context
                          // For now, assume data contains warehouse_id or we provide a dummy to prevent errors
                          if (data['warehouse_id'] == null) {
                            // Fetch default warehouse if not provided, for this implementation mock it
                            data['warehouse_id'] = 'wh-1'; 
                          }
                          
                          final success = await ref.read(stockAdjustmentNotifierProvider.notifier).submitAdjustment(data);
                          if (success) {
                            if (ctx.mounted) Navigator.pop(ctx);
                          } else {
                            final error = ref.read(stockAdjustmentNotifierProvider).error;
                            if (ctx.mounted && error != null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: ${error.message}')));
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
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
                      hintText: 'ابحث برقم التسوية، التاريخ...',
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
                    'لا توجد تسويات مخزنية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'قم بإنشاء تسوية جديدة لعرضها هنا.',
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
}
