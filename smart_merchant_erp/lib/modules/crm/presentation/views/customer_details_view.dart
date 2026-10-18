import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../accounting/presentation/widgets/receipt_voucher_dialog.dart';
import '../../../sales/presentation/mappers/sales_invoice_document_mapper.dart';
import '../../../sales/presentation/providers/customer_provider.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../treasury/application/services/party_statement_service.dart';
import '../../../treasury/presentation/widgets/party_statement_dialog.dart';

class CustomerDetailsView extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailsView({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailsView> createState() =>
      _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends ConsumerState<CustomerDetailsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.customer.customerName),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => ReceiptVoucherDialog(
                    initialCustomerId: widget.customer.id,
                  ),
                );
              },
              icon: const Icon(Icons.call_received_rounded, size: 18),
              label: const Text('قبض دفعة من العميل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'كشف الحساب التفصيلي'),
            Tab(text: 'فواتير المبيعات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(surfaceColor, borderColor),
          _buildStatementTab(surfaceColor, borderColor),
          _buildInvoicesTab(surfaceColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Color surfaceColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Card(
            color: surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات الأساسية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('رقم الهاتف'),
                    subtitle: Text(widget.customer.phone ?? 'غير متوفر'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('البريد الإلكتروني'),
                    subtitle: Text(widget.customer.email ?? 'غير متوفر'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('العنوان'),
                    subtitle: Text(widget.customer.address ?? 'غير متوفر'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Info
          Card(
            color: surfaceColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer(
                builder: (context, ref, _) {
                  final balanceAsync =
                      ref.watch(customerBalanceProvider(widget.customer.id));

                  return balanceAsync.when(
                    data: (balance) {
                      final currentBalance = balance?.currentBalance ??
                          widget.customer.openingBalance;
                      final isDebit = balance?.isDebit ??
                          (widget.customer.openingBalanceType != 'credit');
                      final isSettled = balance?.isSettled ?? false;
                      final totalInvoices = balance?.totalReceivables ?? 0.0;
                      final totalPaid = balance?.totalPaid ?? 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'المعلومات المالية والمديونية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (_) => ReceiptVoucherDialog(
                                      initialCustomerId: widget.customer.id,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_card_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                label: const Text(
                                  'تسجيل سند قبض',
                                  style: TextStyle(color: Color(0xFF10B981)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'الرصيد الصافي الحالي',
                                  '${currentBalance.toStringAsFixed(2)} ر.ي',
                                  isSettled
                                      ? const Color(0xFF10B981)
                                      : (isDebit
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF3B82F6)),
                                  surfaceColor,
                                  borderColor,
                                  subtitle: isSettled
                                      ? 'الحساب خالص (صفر)'
                                      : (isDebit
                                          ? 'مدين (مستحق على العميل لنا)'
                                          : 'دائن (رصيد للعميل علينا)'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoBox(
                                  'الحد الائتماني المسموح',
                                  '${widget.customer.creditLimit.toStringAsFixed(2)} ر.ي',
                                  const Color(0xFF8B5CF6),
                                  surfaceColor,
                                  borderColor,
                                  subtitle: 'سقف البيع بالآجل',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'إجمالي المبيعات (الفواتير)',
                                  '${totalInvoices.toStringAsFixed(2)} ر.ي',
                                  const Color(0xFF3B82F6),
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoBox(
                                  'إجمالي المدفوعات والمتحصلات',
                                  '${totalPaid.toStringAsFixed(2)} ر.ي',
                                  const Color(0xFF10B981),
                                  surfaceColor,
                                  borderColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('خطأ في تحميل البيانات المالية: $e'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String title,
    String value,
    Color color,
    Color surfaceColor,
    Color borderColor, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatementTab(Color surfaceColor, Color borderColor) {
    return _CustomerStatementView(customerId: widget.customer.id);
  }

  Widget _buildInvoicesTab(Color surfaceColor, Color borderColor) {
    final invoicesAsync = ref.watch(salesInvoicesNotifierProvider);

    return invoicesAsync.when(
      data: (invoices) {
        final customerInvoices = invoices
            .where((i) => i.customerId == widget.customer.id)
            .toList();

        if (customerInvoices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فواتير لهذا العميل',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: customerInvoices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final invoice = customerInvoices[index];
            return ListTile(
              leading: const Icon(Icons.receipt_rounded, color: Colors.blue),
              title: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)} - الحالة: ${invoice.paymentStatus}',
              ),
              trailing: Text(
                '${invoice.grandTotal.toStringAsFixed(2)} ر.ي',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTap: () async {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  final mapper = getIt<SalesInvoiceDocumentMapper>();
                  final docData = await mapper.mapToDocumentData(invoice.id);
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          CommercialDocumentPreviewScreen(document: docData),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _CustomerStatementView extends ConsumerStatefulWidget {
  final String customerId;

  const _CustomerStatementView({required this.customerId});

  @override
  ConsumerState<_CustomerStatementView> createState() =>
      _CustomerStatementViewState();
}

class _CustomerStatementViewState
    extends ConsumerState<_CustomerStatementView> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  PartyStatementReport? _report;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStatement();
  }

  Future<void> _fetchStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = getIt<PartyStatementService>();
      final report = await service.getCustomerStatement(
        widget.customerId,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Text(
                  _startDate != null && _endDate != null
                      ? 'من ${DateFormat('yyyy-MM-dd').format(_startDate!)} إلى ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                      : 'كامل الفترة التاريخية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _fetchStatement();
                    }
                  },
                  icon: const Icon(Icons.filter_alt_outlined, size: 16),
                  label: const Text('تحديد فترة'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (_startDate != null || _endDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'إعادة ضبط لكامل الفترة',
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _fetchStatement();
                    },
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _report == null
                      ? null
                      : () {
                          showDialog<void>(
                            context: context,
                            builder: (_) =>
                                PartyStatementDialog(report: _report!),
                          );
                        },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('طباعة الكشف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Loading / Error / Content
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text('خطأ في تحميل كشف الحساب: $_errorMessage'),
              ),
            )
          else if (_report != null) ...[
            // KPI Summary Cards
            Row(
              children: [
                _CustomerSummaryMetricBox(
                  title: 'رصيد سابق',
                  value: _report!.openingBalance,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                _CustomerSummaryMetricBox(
                  title: 'إجمالي المبيعات (مدين)',
                  value: _report!.totalDebit,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _CustomerSummaryMetricBox(
                  title: 'إجمالي السدادات والمردودات (دائن)',
                  value: _report!.totalCredit,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _CustomerSummaryMetricBox(
                  title: _report!.closingBalance >= 0
                      ? 'الرصيد المستحق (على العميل لنا)'
                      : 'الرصيد الدائن (للعميل علينا)',
                  value: _report!.closingBalance.abs(),
                  color: _report!.closingBalance > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Entries List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: _report!.lines.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد حركات مسجلة لهذا العميل في الفترة المحددة',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '#',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'التاريخ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'نوع المستند',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'رقم السند/الفاتورة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'البيان والشرح',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'مدين (+)',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'دائن (-)',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'الرصيد التراكمي',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Table Lines
                          Expanded(
                            child: ListView.separated(
                              itemCount: _report!.lines.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: borderColor),
                              itemBuilder: (context, index) {
                                final line = _report!.lines[index];
                                final isInvoice =
                                    line.documentType == 'Invoice';
                                final isPayment =
                                    line.documentType == 'Payment';
                                final isReturn =
                                    line.documentType == 'Return';

                                Color badgeColor = const Color(0xFF64748B);
                                String typeLabel = line.documentType;
                                if (isInvoice) {
                                  badgeColor = const Color(0xFF3B82F6);
                                  typeLabel = 'فاتورة مبيعات';
                                } else if (isPayment) {
                                  badgeColor = const Color(0xFF10B981);
                                  typeLabel = 'سند قبض';
                                } else if (isReturn) {
                                  badgeColor = const Color(0xFFF59E0B);
                                  typeLabel = 'مرتجع مبيعات';
                                } else if (line.documentType == 'Opening') {
                                  typeLabel = 'رصيد افتتاحي';
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          DateFormat('yyyy-MM-dd')
                                              .format(line.date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          line.documentNumber.isEmpty
                                              ? '-'
                                              : line.documentNumber,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          line.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          line.debit > 0
                                              ? line.debit
                                                  .toStringAsFixed(2)
                                              : '-',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFEF4444),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          line.credit > 0
                                              ? line.credit
                                                  .toStringAsFixed(2)
                                              : '-',
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${line.runningBalance.toStringAsFixed(2)} ${line.runningBalance >= 0 ? '(مدين)' : '(دائن)'}',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            color: line.runningBalance >= 0
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerSummaryMetricBox extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _CustomerSummaryMetricBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(2)} ر.ي',
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
    );
  }
}
