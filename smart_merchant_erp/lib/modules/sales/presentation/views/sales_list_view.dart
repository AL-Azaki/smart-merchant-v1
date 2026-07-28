import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../providers/sales_provider.dart';
import '../providers/customer_provider.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../kernel/storage/app_database.dart' show SalesInvoice, Customer;

class SalesListView extends ConsumerStatefulWidget {
  const SalesListView({super.key});

  @override
  ConsumerState<SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends ConsumerState<SalesListView> {
  String _searchQuery = '';
  String? _statusFilter;

  void _openInvoice(BuildContext context, SalesInvoice invoice) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final mapper = getIt<SalesInvoiceDocumentMapper>();
      final docData = await mapper.mapToDocumentData(invoice.id);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommercialDocumentPreviewScreen(document: docData),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final invoicesAsync = ref.watch(salesInvoicesNotifierProvider);
    final customersAsync = ref.watch(customersNotifierProvider);
    final customers = customersAsync.asData?.value ?? [];

    return Column(
      children: [
        // Header removed to save vertical space
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
                      hintText: 'ابحث برقم الفاتورة أو العميل...',
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
                    value: 'Unpaid',
                    child: Text('غير مدفوعة'),
                  ),
                  PopupMenuItem(
                    value: 'Paid',
                    child: Text('مدفوعة'),
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
                  final cName = _getCustomerName(i.customerId, customers).toLowerCase();
                  return i.invoiceNumber.toLowerCase().contains(sq) || cName.contains(sq);
                }).toList();
              }
              if (_statusFilter != null) {
                filtered = filtered
                    .where((i) => i.paymentStatus == _statusFilter || i.status == _statusFilter)
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
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد فواتير مبيعات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                        ? _buildTable(filtered, customers, isDark, borderColor)
                        : _buildList(filtered, customers, isDark, borderColor),
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

  String _getCustomerName(String? customerId, List<Customer> customers) {
    if (customerId == null || customerId.isEmpty) return 'عميل نقدي';
    try {
      return customers.firstWhere((c) => c.id == customerId).customerName;
    } catch (_) {
      return 'عميل نقدي';
    }
  }

  String _getStatusText(SalesInvoice invoice) {
    if (invoice.status == 'Draft') return 'مسودة';
    if (invoice.paymentStatus == 'Paid') return 'مدفوعة';
    if (invoice.paymentStatus == 'Partial') return 'جزئي';
    if (invoice.paymentStatus == 'Unpaid') return 'غير مدفوعة';
    return invoice.paymentStatus;
  }

  Color _getStatusColor(SalesInvoice invoice) {
    if (invoice.status == 'Draft') return Colors.orange;
    if (invoice.paymentStatus == 'Paid') return Colors.green;
    if (invoice.paymentStatus == 'Partial') return Colors.blue;
    return Colors.red;
  }

  Widget _buildTable(
    List<SalesInvoice> invoices,
    List<Customer> customers,
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
            DataColumn(label: Text('العميل', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: invoices.map((inv) {
            final cName = _getCustomerName(inv.customerId, customers);
            final statusColor = _getStatusColor(inv);
            return DataRow(
              onSelectChanged: (_) => _openInvoice(context, inv),
              cells: [
                DataCell(Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(DateFormat('yyyy-MM-dd').format(inv.invoiceDate))),
                DataCell(Text(cName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(inv),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
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
    List<SalesInvoice> invoices,
    List<Customer> customers,
    bool isDark,
    Color borderColor,
  ) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final cName = _getCustomerName(invoice.customerId, customers);
        final statusColor = _getStatusColor(invoice);

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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(invoice),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cName,
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
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
