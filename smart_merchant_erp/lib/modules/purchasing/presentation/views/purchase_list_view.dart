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
import '../../../../kernel/storage/app_database.dart' show PurchaseInvoice, Supplier;

class PurchaseListView extends ConsumerStatefulWidget {
  const PurchaseListView({super.key});

  @override
  ConsumerState<PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends ConsumerState<PurchaseListView> {
  String _searchQuery = '';
  String? _statusFilter;

  void _openInvoice(BuildContext context, PurchaseInvoice invoice) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final invoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);
    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    final suppliers = suppliersAsync.asData?.value ?? [];

    return Column(
      children: [
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: surfaceColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Align(
                alignment: isNarrow ? Alignment.center : AlignmentDirectional.centerEnd,
                child: SizedBox(
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
              PopupMenuButton<String?>(
                initialValue: _statusFilter,
                onSelected: (value) => setState(() => _statusFilter = value),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: null,
                    child: Text('الكل'),
                  ),
                  PopupMenuItem(
                    value: 'Draft',
                    child: Text('مسودة'),
                  ),
                  PopupMenuItem(
                    value: 'Posted',
                    child: Text('مرحلة'),
                  ),
                  PopupMenuItem(
                    value: 'Cancelled',
                    child: Text('ملغاة'),
                  ),
                ],
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _statusFilter == null ? surfaceColor : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusFilter == null ? borderColor : AppColors.primary,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _statusFilter == null 
                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Data Grid / Empty State
        Expanded(
          child: invoicesAsync.when(
            data: (invoices) {
              var filtered = invoices;
              if (_searchQuery.isNotEmpty) {
                final sq = _searchQuery.toLowerCase();
                filtered = filtered.where((i) {
                  final sName = _getSupplierName(i.supplierId, suppliers).toLowerCase();
                  return i.invoiceNumber.toLowerCase().contains(sq) || sName.contains(sq);
                }).toList();
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
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
                    child: isDesktop
                        ? _buildTable(filtered, suppliers, isDark, borderColor)
                        : _buildList(filtered, suppliers, isDark, borderColor),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  String _getSupplierName(String? supplierId, List<Supplier> suppliers) {
    if (supplierId == null || supplierId.isEmpty) return 'مورد غير معروف';
    try {
      return suppliers.firstWhere((s) => s.id == supplierId).supplierName;
    } catch (_) {
      return 'مورد غير معروف';
    }
  }

  Widget _buildTable(
    List<PurchaseInvoice> invoices,
    List<Supplier> suppliers,
    bool isDark,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 800),
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(
            isDark ? AppColors.surfaceDark.withOpacity(0.5) : const Color(0xFFF8FAFC),
          ),
          columns: const [
            DataColumn(label: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المورد', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: invoices.map((inv) {
            final sName = _getSupplierName(inv.supplierId, suppliers);
            final isPosted = inv.status == 'Posted';
            return DataRow(
              onSelectChanged: (_) => _openInvoice(context, inv),
              cells: [
                DataCell(Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(DateFormat('yyyy-MM-dd').format(inv.purchaseDate))),
                DataCell(Text(sName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPosted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv.status == 'Posted' ? 'مرحلة' : 'مسودة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPosted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(
                  '${NumberFormat('#,##0.00').format(inv.grandTotal)} ر.ي',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildList(
    List<PurchaseInvoice> invoices,
    List<Supplier> suppliers,
    bool isDark,
    Color borderColor,
  ) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final sName = _getSupplierName(invoice.supplierId, suppliers);
        final isPosted = invoice.status == 'Posted';

        return InkWell(
          onTap: () => _openInvoice(context, invoice),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPosted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPosted ? 'مرحلة' : 'مسودة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPosted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sName,
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(invoice.purchaseDate),
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    Text(
                      '${NumberFormat('#,##0.00').format(invoice.grandTotal)} ر.ي',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}
