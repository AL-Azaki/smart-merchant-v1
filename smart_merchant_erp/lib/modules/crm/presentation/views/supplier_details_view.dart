import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../purchasing/presentation/providers/purchasing_provider.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../purchasing/presentation/mappers/purchase_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../accounting/presentation/widgets/payment_voucher_dialog.dart';
import '../../../treasury/application/services/party_statement_service.dart';
import '../../../treasury/presentation/widgets/party_statement_dialog.dart';

class SupplierDetailsView extends ConsumerStatefulWidget {
  final Supplier supplier;

  const SupplierDetailsView({super.key, required this.supplier});

  @override
  ConsumerState<SupplierDetailsView> createState() =>
      _SupplierDetailsViewState();
}

class _SupplierDetailsViewState extends ConsumerState<SupplierDetailsView>
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
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.supplier.supplierName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'كشف الحساب'),
            Tab(text: 'فواتير المشتريات'),
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
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('الشخص المسؤول'),
                    subtitle: Text(
                      widget.supplier.contactPerson ?? 'غير متوفر',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('رقم الهاتف'),
                    subtitle: Text(widget.supplier.phone ?? 'غير متوفر'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('العنوان'),
                    subtitle: Text(
                      widget.supplier.supplierAddress ?? 'غير متوفر',
                    ),
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
                  final summaryAsync = ref.watch(
                    supplierBalanceSummaryProvider(widget.supplier.id),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المعلومات المالية والرصيد',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => PaymentVoucherDialog(
                                  initialSupplierId: widget.supplier.id,
                                ),
                              );
                            },
                            icon: const Icon(Icons.call_made_rounded, size: 16),
                            label: const Text('سداد دفعة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      summaryAsync.when(
                        data: (summary) {
                          final currentBalance = summary?.currentBalance ??
                              widget.supplier.openingBalance;
                          final isCredit = summary?.isCredit ??
                              (widget.supplier.openingBalanceType == 'credit');
                          final totalInvoices = summary?.totalPayables ?? 0.0;
                          final totalPaid = summary?.totalPaid ?? 0.0;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoBox(
                                      'الرصيد الصافي الحالي',
                                      '${currentBalance.abs().toStringAsFixed(2)} ر.ي',
                                      isCredit
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                      surfaceColor,
                                      borderColor,
                                      subtitle: isCredit
                                          ? 'دائن (مستحق للمورد علينا)'
                                          : (currentBalance.abs() < 0.01
                                              ? 'الحساب خالص'
                                              : 'مدين (مستحق لنا)'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoBox(
                                      'الحد الائتماني',
                                      '${widget.supplier.creditLimit.toStringAsFixed(2)} ر.ي',
                                      const Color(0xFF3B82F6),
                                      surfaceColor,
                                      borderColor,
                                      subtitle: 'المسموح به',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoBox(
                                      'إجمالي فواتير المشتريات',
                                      '${totalInvoices.toStringAsFixed(2)} ر.ي',
                                      const Color(0xFF8B5CF6),
                                      surfaceColor,
                                      borderColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInfoBox(
                                      'إجمالي المسدد والمردود',
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
                        error: (_, __) => Row(
                          children: [
                            Expanded(
                              child: _buildInfoBox(
                                'الرصيد الافتتاحي',
                                '${widget.supplier.openingBalance.toStringAsFixed(2)} ر.ي',
                                Colors.red,
                                surfaceColor,
                                borderColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    return _SupplierStatementView(supplierId: widget.supplier.id);
  }

  Widget _buildInvoicesTab(Color surfaceColor, Color borderColor) {
    final invoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);

    return invoicesAsync.when(
      data: (invoices) {
        final supplierInvoices = invoices
            .where((i) => i.supplierId == widget.supplier.id)
            .toList();

        if (supplierInvoices.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد فواتير مشتريات لهذا المورد',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: supplierInvoices.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final invoice = supplierInvoices[index];
            return ListTile(
              onTap: () async {
                try {
                  final mapper = getIt<PurchaseInvoiceDocumentMapper>();
                  final document = await mapper.mapToDocumentData(invoice.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CommercialDocumentPreviewScreen(document: document),
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
              },
              leading: const Icon(Icons.receipt_rounded, color: Colors.orange),
              title: Text(
                invoice.invoiceNumber,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${invoice.purchaseDate.toString().split(' ')[0]} - الحالة: ${invoice.paymentStatus}',
              ),
              trailing: Text(
                '${invoice.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _SupplierStatementView extends ConsumerStatefulWidget {
  final String supplierId;

  const _SupplierStatementView({required this.supplierId});

  @override
  ConsumerState<_SupplierStatementView> createState() =>
      _SupplierStatementViewState();
}

class _SupplierStatementViewState extends ConsumerState<_SupplierStatementView> {
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
      final report = await service.getSupplierStatement(
        widget.supplierId,
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
                const Icon(Icons.date_range_rounded, size: 20, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text(
                  _startDate != null && _endDate != null
                      ? 'من ${_startDate!.toString().split(' ')[0]} إلى ${_endDate!.toString().split(' ')[0]}'
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          showDialog(
                            context: context,
                            builder: (_) => PartyStatementDialog(report: _report!),
                          );
                        },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('طباعة الكشف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                _SummaryMetricBox(
                  title: 'رصيد سابق',
                  value: _report!.openingBalance,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                _SummaryMetricBox(
                  title: 'إجمالي المشتريات (دائن)',
                  value: _report!.totalCredit,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _SummaryMetricBox(
                  title: 'إجمالي السدادات والمردودات (مدين)',
                  value: _report!.totalDebit,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _SummaryMetricBox(
                  title: _report!.closingBalance >= 0
                      ? 'الرصيد المستحق (للمورد علينا)'
                      : 'الرصيد المدين (لنا)',
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
                          'لا توجد حركات مالية مسجلة في هذه الفترة',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _report!.lines.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final line = _report!.lines[index];
                          final dateStr =
                              '${line.date.year}/${line.date.month.toString().padLeft(2, '0')}/${line.date.day.toString().padLeft(2, '0')}';

                          Color badgeColor;
                          String badgeLabel;
                          switch (line.documentType.toLowerCase()) {
                            case 'return':
                              badgeColor = const Color(0xFFF59E0B);
                              badgeLabel = 'مردود';
                              break;
                            case 'payment':
                              badgeColor = const Color(0xFF10B981);
                              badgeLabel = 'سند صرف';
                              break;
                            case 'invoice':
                              badgeColor = const Color(0xFF3B82F6);
                              badgeLabel = 'فاتورة';
                              break;
                            default:
                              badgeColor = const Color(0xFF64748B);
                              badgeLabel = 'افتتاحي';
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Date & Doc
                                SizedBox(
                                  width: 160,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badgeLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              line.documentNumber,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                                fontFamily: 'monospace',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Description
                                Expanded(
                                  child: Text(
                                    line.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Debit
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'مدين (لنا)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        line.debit > 0
                                            ? line.debit.toStringAsFixed(2)
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Credit
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'دائن (علينا)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        line.credit > 0
                                            ? line.credit.toStringAsFixed(2)
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Running Balance
                                SizedBox(
                                  width: 120,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'الرصيد التراكمي',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${line.runningBalance.toStringAsFixed(2)} ر.ي',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetricBox extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _SummaryMetricBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(2)} ر.ي',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
