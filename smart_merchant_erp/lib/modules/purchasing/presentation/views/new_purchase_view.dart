import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/purchasing_provider.dart';

class NewPurchaseView extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NewPurchaseView({super.key, required this.onBack});

  @override
  ConsumerState<NewPurchaseView> createState() => _NewPurchaseViewState();
}

class _NewPurchaseViewState extends ConsumerState<NewPurchaseView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasingNotifierProvider);
    final notifier = ref.read(purchasingNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'فاتورة مشتريات جديدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await notifier.submitPurchase(
                  referenceNumber: 'REF-${DateTime.now().millisecondsSinceEpoch}',
                  issueDate: DateTime.now(),
                );
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
                    widget.onBack();
                  }
                } else {
                  final error = ref.read(purchasingNotifierProvider).error;
                  if (context.mounted && error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: ${error.message}')));
                  }
                }
              },
              icon: state.isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('حفظ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Main Input Area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'المورد',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '1',
                                child: Text('مورد عام'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) notifier.setSupplier(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'المخزن',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'WH-MAIN',
                                child: Text('المخزن الرئيسي'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) notifier.setWarehouse(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('المنتج')),
                          DataColumn(label: Text('الكمية')),
                          DataColumn(label: Text('سعر الشراء')),
                          DataColumn(label: Text('الإجمالي')),
                          DataColumn(label: Text('')),
                        ],
                        rows: state.items.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(item.productUnitId)),
                              DataCell(Text(item.quantity.toString())),
                              DataCell(Text(item.unitPrice.toString())),
                              DataCell(
                                Text(
                                  (item.quantity * item.unitPrice).toString(),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    // Remove item
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // Add Row Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          // Show add item dialog
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة منتج'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sidebar Totals
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(
                right: 0,
                top: AppSpacing.md,
                bottom: AppSpacing.md,
                left: AppSpacing.md,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص الفاتورة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  _buildSummaryRow('الإجمالي الفرعي:', '0', isDark),
                  const SizedBox(height: 12),
                  _buildSummaryRow('الضريبة:', '0', isDark),
                  const SizedBox(height: 12),
                  _buildSummaryRow('الخصم:', '0', isDark),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الإجمالي النهائي:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '0 ر.ي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'دفع وحفظ',
                      icon: Icons.payment,
                      onPressed: () {
                        // Complete purchase
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
