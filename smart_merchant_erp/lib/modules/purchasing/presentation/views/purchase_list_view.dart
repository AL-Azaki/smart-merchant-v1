import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/purchasing_provider.dart';
import 'package:intl/intl.dart';

import '../widgets/purchase_invoice_modal.dart';
import '../widgets/purchase_return_modal.dart';
import '../dialogs/purchase_invoice_details_dialog.dart';
import '../../../accounting/presentation/widgets/payment_voucher_dialog.dart';
import '../../domain/repositories/purchasing_repository.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../../app/di/getit_instance.dart';
import '../mappers/purchase_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../kernel/storage/app_database.dart'
    show PurchaseInvoice, Supplier;

class PurchaseListView extends ConsumerStatefulWidget {
  const PurchaseListView({super.key});

  @override
  ConsumerState<PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends ConsumerState<PurchaseListView> {
  String _searchQuery = '';
  String? _statusFilter;
  String? _paymentStatusFilter;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading document: $e')));
      }
    }
  }

  void _showInvoiceDetails(
    BuildContext context,
    PurchaseInvoice invoice,
    List<Supplier> suppliers,
  ) {
    final sName = _getSupplierName(invoice.supplierId, suppliers);
    showDialog(
      context: context,
      builder: (_) => PurchaseInvoiceDetailsDialog(
        invoice: invoice,
        supplierName: sName,
      ),
    );
  }

  Future<void> _createReturnForInvoice(
    BuildContext context,
    PurchaseInvoice invoice,
  ) async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    final repo = getIt<PurchasingRepository>();
    final withItems = await repo.getInvoiceWithItemsById(
      invoice.id,
      session.businessId!,
    );
    if (context.mounted && withItems != null) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: PurchaseReturnModal(
            initialInvoice: withItems,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final invoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);
    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    final suppliers = suppliersAsync.asData?.value ?? [];

    return Column(
      children: [
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: surfaceColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Align(
                alignment: isNarrow
                    ? Alignment.center
                    : AlignmentDirectional.centerEnd,
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

        // KPI Summary Banner
        invoicesAsync.when(
          data: (allInvoices) {
            final activeInvoices = allInvoices
                .where((i) => i.status != 'Cancelled')
                .toList();
            final totalPurchases = activeInvoices.fold(
              0.0,
              (sum, i) => sum + i.grandTotal,
            );
            final unpaidInvoices = activeInvoices
                .where((i) => i.paymentStatus != 'Paid')
                .toList();
            final unpaidTotal = unpaidInvoices.fold(
              0.0,
              (sum, i) => sum + i.grandTotal,
            );
            final paidInvoices = activeInvoices
                .where((i) => i.paymentStatus == 'Paid')
                .toList();
            final paidTotal = paidInvoices.fold(
              0.0,
              (sum, i) => sum + i.grandTotal,
            );

            return Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  _PurchaseKpiBox(
                    label: 'إجمالي المشتريات',
                    value: '${NumberFormat('#,##0.00').format(totalPurchases)} ر.ي',
                    subtitle: '${activeInvoices.length} فاتورة',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(width: 8),
                  _PurchaseKpiBox(
                    label: 'مشتريات آجلة (غير مسددة)',
                    value: '${NumberFormat('#,##0.00').format(unpaidTotal)} ر.ي',
                    subtitle: '${unpaidInvoices.length} مستحقة',
                    color: const Color(0xFFEF4444),
                    icon: Icons.pending_actions_outlined,
                  ),
                  const SizedBox(width: 8),
                  _PurchaseKpiBox(
                    label: 'مشتريات مسددة بالكامل',
                    value: '${NumberFormat('#,##0.00').format(paidTotal)} ر.ي',
                    subtitle: '${paidInvoices.length} مسددة',
                    color: const Color(0xFF10B981),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
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
              // فلتر حالة الترحيل
              PopupMenuButton<String?>(
                initialValue: _statusFilter,
                onSelected: (value) => setState(() => _statusFilter = value),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text('جميع الحالات')),
                  PopupMenuItem(value: 'Draft', child: Text('مسودة')),
                  PopupMenuItem(value: 'Posted', child: Text('مرحلة')),
                  PopupMenuItem(value: 'Cancelled', child: Text('ملغاة')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        Icons.filter_list,
                        size: 18,
                        color: _statusFilter == null
                            ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusFilter == null
                            ? 'الحالة'
                            : (_statusFilter == 'Posted'
                                ? 'مرحلة'
                                : (_statusFilter == 'Draft' ? 'مسودة' : 'ملغاة')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _statusFilter == null
                              ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // فلتر حالة السداد
              PopupMenuButton<String?>(
                initialValue: _paymentStatusFilter,
                onSelected: (value) =>
                    setState(() => _paymentStatusFilter = value),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: null, child: Text('جميع السدادات')),
                  PopupMenuItem(value: 'Paid', child: Text('مدفوعة بالكامل')),
                  PopupMenuItem(value: 'Partial', child: Text('مدفوعة جزئياً')),
                  PopupMenuItem(value: 'Unpaid', child: Text('غير مدفوعة (آجلة)')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _paymentStatusFilter == null
                        ? surfaceColor
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _paymentStatusFilter == null
                          ? borderColor
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: _paymentStatusFilter == null
                            ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _paymentStatusFilter == null
                            ? 'السداد'
                            : (_paymentStatusFilter == 'Paid'
                                ? 'مدفوعة'
                                : (_paymentStatusFilter == 'Partial'
                                    ? 'جزئية'
                                    : 'آجلة')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _paymentStatusFilter == null
                              ? (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Data Grid / Empty State
        Expanded(
          child: invoicesAsync.when(
            data: (invoices) {
              var filtered = invoices;
              if (_searchQuery.isNotEmpty) {
                final sq = _searchQuery.toLowerCase();
                filtered = filtered.where((i) {
                  final sName = _getSupplierName(
                    i.supplierId,
                    suppliers,
                  ).toLowerCase();
                  return i.invoiceNumber.toLowerCase().contains(sq) ||
                      sName.contains(sq);
                }).toList();
              }
              if (_statusFilter != null) {
                filtered = filtered
                    .where((i) => i.status == _statusFilter)
                    .toList();
              }
              if (_paymentStatusFilter != null) {
                filtered = filtered
                    .where((i) => i.paymentStatus == _paymentStatusFilter)
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
                          'لا توجد فواتير مشتريات تطابق البحث',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'قم بتغيير خيارات التصفية أو إنشاء فاتورة مشتريات جديدة.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 850;
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
            error: (err, stack) => Center(child: Text('خطأ: $err')),
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
        constraints: const BoxConstraints(minWidth: 950),
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
                'المورد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الحالة',
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
            final sName = _getSupplierName(inv.supplierId, suppliers);
            final isPosted = inv.status == 'Posted';

            Color payColor;
            String payLabel;
            switch (inv.paymentStatus.toLowerCase()) {
              case 'paid':
                payColor = const Color(0xFF10B981);
                payLabel = 'مدفوعة بالكامل';
                break;
              case 'partial':
                payColor = const Color(0xFFF59E0B);
                payLabel = 'مدفوعة جزئياً';
                break;
              default:
                payColor = const Color(0xFFEF4444);
                payLabel = 'غير مدفوعة (آجلة)';
            }

            return DataRow(
              onSelectChanged: (_) => _showInvoiceDetails(context, inv, suppliers),
              cells: [
                DataCell(
                  Text(
                    inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(DateFormat('yyyy-MM-dd').format(inv.purchaseDate)),
                ),
                DataCell(Text(sName)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPosted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
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
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: payColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      payLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: payColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${NumberFormat('#,##0.00').format(inv.grandTotal)} ر.ي',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'تفاصيل الفاتورة',
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        onPressed: () =>
                            _showInvoiceDetails(context, inv, suppliers),
                      ),
                      IconButton(
                        tooltip: 'معاينة وطباعة',
                        icon: const Icon(Icons.print_outlined, size: 18),
                        onPressed: () => _openInvoice(context, inv),
                      ),
                      IconButton(
                        tooltip: 'إنشاء مرتجع',
                        icon: const Icon(
                          Icons.keyboard_return_rounded,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        onPressed: () => _createReturnForInvoice(context, inv),
                      ),
                      IconButton(
                        tooltip: 'سداد دفعة للمورد',
                        icon: const Icon(
                          Icons.call_made_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => PaymentVoucherDialog(
                              initialSupplierId: inv.supplierId,
                            ),
                          );
                        },
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
    List<PurchaseInvoice> invoices,
    List<Supplier> suppliers,
    bool isDark,
    Color borderColor,
  ) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: borderColor),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final sName = _getSupplierName(invoice.supplierId, suppliers);
        final isPosted = invoice.status == 'Posted';

        Color payColor;
        String payLabel;
        switch (invoice.paymentStatus.toLowerCase()) {
          case 'paid':
            payColor = const Color(0xFF10B981);
            payLabel = 'مدفوعة بالكامل';
            break;
          case 'partial':
            payColor = const Color(0xFFF59E0B);
            payLabel = 'مدفوعة جزئياً';
            break;
          default:
            payColor = const Color(0xFFEF4444);
            payLabel = 'غير مدفوعة (آجلة)';
        }

        return InkWell(
          onTap: () => _showInvoiceDetails(context, invoice, suppliers),
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
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isPosted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPosted ? 'مرحلة' : 'مسودة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPosted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: payColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: payColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sName,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(invoice.purchaseDate),
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      children: [
                        IconButton(
                          tooltip: 'طباعة',
                          icon: const Icon(Icons.print_outlined, size: 18),
                          onPressed: () => _openInvoice(context, invoice),
                        ),
                        IconButton(
                          tooltip: 'إنشاء مرتجع',
                          icon: const Icon(
                            Icons.keyboard_return_rounded,
                            size: 18,
                            color: Color(0xFFF59E0B),
                          ),
                          onPressed: () =>
                              _createReturnForInvoice(context, invoice),
                        ),
                        IconButton(
                          tooltip: 'سداد دفعة',
                          icon: const Icon(
                            Icons.call_made_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentVoucherDialog(
                                initialSupplierId: invoice.supplierId,
                              ),
                            );
                          },
                        ),
                      ],
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

class _PurchaseKpiBox extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _PurchaseKpiBox({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withOpacity(0.8),
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
}
