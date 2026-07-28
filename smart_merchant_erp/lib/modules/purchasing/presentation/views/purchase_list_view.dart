import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/purchasing_provider.dart';
import 'package:intl/intl.dart';

import '../widgets/purchase_invoice_modal.dart';
import '../../../../app/di/injection.dart';
import '../mappers/purchase_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';

class PurchaseListView extends ConsumerStatefulWidget {
  const PurchaseListView({super.key});

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

    final invoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: surfaceColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                          invoicesAsync.when(
                            data: (invoices) => Text(
                              '${invoices.length} فاتورة',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            loading: () => const Text('جاري التحميل...'),
                            error: (_, __) => const Text('خطأ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth : 250,
                    child: PrimaryButton(
                      text: 'فاتورة مشتريات جديدة',
                      icon: Icons.add,
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const PurchaseInvoiceModal(),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
        ),
        const SizedBox(height: AppSpacing.lg),
        // Data Grid / Empty State
        Expanded(
          child: invoicesAsync.when(
            data: (invoices) {
              var filtered = invoices;
              if (_searchQuery.isNotEmpty) {
                filtered = filtered
                    .where(
                      (i) => i.invoiceNumber.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();
              }
              if (_statusFilter != null) {
                filtered = filtered
                    .where((i) => i.status == _statusFilter)
                    .toList();
              }

              if (filtered.isEmpty) {
                return Container(
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'قم بإنشاء فاتورة مشتريات جديدة لإضافتها هنا.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final invoice = filtered[index];
                    return ListTile(
                      onTap: () async {
                        try {
                          final mapper = getIt<PurchaseInvoiceDocumentMapper>();
                          final document = await mapper.mapToDocumentData(invoice.id);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommercialDocumentPreviewScreen(document: document),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading document: $e')));
                          }
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.receipt,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(invoice.purchaseDate),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${invoice.grandTotal} ر.ي',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: invoice.status == 'Posted'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              invoice.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: invoice.status == 'Posted'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
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
