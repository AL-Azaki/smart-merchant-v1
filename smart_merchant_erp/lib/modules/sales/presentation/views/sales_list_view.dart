import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../kernel/storage/app_database.dart'
    show Customer, SalesInvoice;
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../providers/customer_provider.dart';
import '../providers/sales_provider.dart';
import '../widgets/returns_modal.dart';

class SalesListView extends ConsumerStatefulWidget {
  const SalesListView({super.key});

  @override
  ConsumerState<SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends ConsumerState<SalesListView> {
  String _searchQuery = '';
  String? _statusFilter;

  void _openInvoice(BuildContext context, SalesInvoice invoice) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final mapper = getIt<SalesInvoiceDocumentMapper>();
      final docData = await mapper.mapToDocumentData(invoice.id);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CommercialDocumentPreviewScreen(document: docData),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openReturnForInvoice(SalesInvoice invoice) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    final repo = ref.read(salesRepositoryProvider);
    final withItems = await repo.getInvoiceWithItemsById(
      invoice.id,
      session.businessId!,
    );
    if (withItems != null && mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => ReturnsModal(initialInvoice: withItems),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final invoicesAsync = ref.watch(salesInvoicesNotifierProvider);
    final customersAsync = ref.watch(customersNotifierProvider);
    final customers = customersAsync.asData?.value ?? [];

    return Column(
      children: [
        // KPI Summary Cards
        invoicesAsync.maybeWhen(
          data: (invoices) {
            double totalSales = 0;
            double paidSales = 0;
            double unpaidSales = 0;

            for (final inv in invoices) {
              totalSales += inv.grandTotal;
              if (inv.paymentStatus.toLowerCase() == 'paid') {
                paidSales += inv.grandTotal;
              } else if (inv.paymentStatus.toLowerCase() == 'unpaid') {
                unpaidSales += inv.grandTotal;
              } else {
                paidSales += inv.grandTotal / 2;
                unpaidSales += inv.grandTotal / 2;
              }
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  _buildKpiCard(
                    'إجمالي المبيعات',
                    '${NumberFormat('#,##0.00').format(totalSales)} ر.ي',
                    const Color(0xFF3B82F6),
                    Icons.point_of_sale_rounded,
                    isDark,
                    borderColor,
                    surfaceColor,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    'المبيعات المسددة (نقد)',
                    '${NumberFormat('#,##0.00').format(paidSales)} ر.ي',
                    const Color(0xFF10B981),
                    Icons.check_circle_rounded,
                    isDark,
                    borderColor,
                    surfaceColor,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    'مبيعات آجلة (ذمم عملاء)',
                    '${NumberFormat('#,##0.00').format(unpaidSales)} ر.ي',
                    const Color(0xFFEF4444),
                    Icons.pending_actions_rounded,
                    isDark,
                    borderColor,
                    surfaceColor,
                  ),
                  const SizedBox(width: 10),
                  _buildKpiCard(
                    'عدد الفواتير',
                    '${invoices.length}',
                    const Color(0xFF8B5CF6),
                    Icons.receipt_long_rounded,
                    isDark,
                    borderColor,
                    surfaceColor,
                  ),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
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
                      hintText: 'ابحث برقم الفاتورة أو اسم العميل...',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text('كافة الفواتير')),
                  PopupMenuItem(value: 'Paid', child: Text('مدفوعة بالكامل')),
                  PopupMenuItem(value: 'Partial', child: Text('مدفوعة جزئياً')),
                  PopupMenuItem(value: 'Unpaid', child: Text('غير مدفوعة (آجلة)')),
                  PopupMenuItem(value: 'Draft', child: Text('مسودات')),
                ],
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _statusFilter == null
                        ? surfaceColor
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusFilter == null
                          ? borderColor
                          : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: _statusFilter == null
                            ? textSecondary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusFilter == null
                            ? 'تصفية الحالة'
                            : (_statusFilter == 'Paid'
                                ? 'مدفوعة'
                                : (_statusFilter == 'Unpaid'
                                    ? 'غير مدفوعة'
                                    : _statusFilter!)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _statusFilter == null
                              ? textPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // زر مرتجعات المبيعات
              ElevatedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const ReturnsModal(),
                  );
                },
                icon: const Icon(Icons.assignment_return_rounded, size: 18),
                label: const Text('مرتجعات المبيعات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Data Grid / Empty State
        Expanded(
          child: invoicesAsync.when(
            data: (invoices) {
              var filtered = invoices;
              if (_searchQuery.isNotEmpty) {
                final sq = _searchQuery.toLowerCase();
                filtered = filtered.where((i) {
                  final cName = _getCustomerName(
                    i.customerId,
                    customers,
                  ).toLowerCase();
                  return i.invoiceNumber.toLowerCase().contains(sq) ||
                      cName.contains(sq);
                }).toList();
              }
              if (_statusFilter != null) {
                filtered = filtered
                    .where(
                      (i) =>
                          i.paymentStatus == _statusFilter ||
                          i.status == _statusFilter,
                    )
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد فواتير مبيعات مطابقة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textSecondary,
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
                        ? _buildTable(filtered, customers, isDark, borderColor, textPrimary, textSecondary)
                        : _buildList(filtered, customers, isDark, borderColor, textPrimary, textSecondary),
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

  Widget _buildKpiCard(
    String title,
    String value,
    Color color,
    IconData icon,
    bool isDark,
    Color borderColor,
    Color surfaceColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    if (invoice.paymentStatus.toLowerCase() == 'paid') return 'مدفوعة بالكامل';
    if (invoice.paymentStatus.toLowerCase() == 'partial') return 'مدفوعة جزئياً';
    if (invoice.paymentStatus.toLowerCase() == 'unpaid') return 'غير مدفوعة (آجلة)';
    return invoice.paymentStatus;
  }

  Color _getStatusColor(SalesInvoice invoice) {
    if (invoice.status == 'Draft') return Colors.orange;
    if (invoice.paymentStatus.toLowerCase() == 'paid') return const Color(0xFF10B981);
    if (invoice.paymentStatus.toLowerCase() == 'partial') return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildTable(
    List<SalesInvoice> invoices,
    List<Customer> customers,
    bool isDark,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 900),
        child: DataTable(
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(
            isDark
                ? AppColors.surfaceDark.withOpacity(0.5)
                : const Color(0xFFF8FAFC),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'رقم الفاتورة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'التاريخ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'العميل',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'حالة السداد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الإجمالي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'الإجراءات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: invoices.map((inv) {
            final cName = _getCustomerName(inv.customerId, customers);
            final statusColor = _getStatusColor(inv);
            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => _openInvoice(context, inv),
                    child: Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    DateFormat('yyyy-MM-dd').format(inv.invoiceDate),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                DataCell(Text(cName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(inv),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${NumberFormat('#,##0.00').format(inv.grandTotal)} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر معاينة وطباعة الفاتورة
                      IconButton(
                        tooltip: 'معاينة وطباعة الفاتورة',
                        icon: const Icon(
                          Icons.print_rounded,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                        onPressed: () => _openInvoice(context, inv),
                      ),
                      // زر مرتجع مبيعات
                      IconButton(
                        tooltip: 'إنشاء مرتجع لهذه الفاتورة',
                        icon: const Icon(
                          Icons.keyboard_return_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        onPressed: () => _openReturnForInvoice(inv),
                      ),
                    ],
                  ),
                ),
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
    Color textPrimary,
    Color textSecondary,
  ) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: borderColor),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final cName = _getCustomerName(invoice.customerId, customers);
        final statusColor = _getStatusColor(invoice);

        return Padding(
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cName,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${NumberFormat('#,##0.00').format(invoice.grandTotal)} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openInvoice(context, invoice),
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('طباعة'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: () => _openReturnForInvoice(invoice),
                        icon: const Icon(
                          Icons.keyboard_return_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'مرتجع',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
