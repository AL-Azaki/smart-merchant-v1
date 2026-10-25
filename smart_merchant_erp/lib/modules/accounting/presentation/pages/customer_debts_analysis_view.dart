import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';

class CustomerDebtRow {
  final String id;
  final String name;
  final String? phone;
  final double totalSales;
  final double totalPaid;
  final double currentDebt;
  final double estimatedProfit;
  final DateTime? lastSalesDate;
  final DateTime? lastPaymentDate;

  const CustomerDebtRow({
    required this.id,
    required this.name,
    required this.totalSales,
    required this.totalPaid,
    required this.currentDebt,
    required this.estimatedProfit,
    this.phone,
    this.lastSalesDate,
    this.lastPaymentDate,
  });
}

class CustomerDebtsAnalysisView extends ConsumerStatefulWidget {
  const CustomerDebtsAnalysisView({super.key});

  @override
  ConsumerState<CustomerDebtsAnalysisView> createState() =>
      _CustomerDebtsAnalysisViewState();
}

class _CustomerDebtsAnalysisViewState
    extends ConsumerState<CustomerDebtsAnalysisView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 3; // Default sort by current debt
  bool _sortAscending = false; // Descending (highest debt first)
  bool _isLoading = true;
  List<CustomerDebtRow> _allRows = [];

  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy/MM/dd', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final businessId = session.businessId!;
    final db = getIt<AppDatabase>();

    // 1. Fetch Customers
    final customers = await (db.select(
      db.customers,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Sales Invoices
    final salesInvoices = await (db.select(
      db.salesInvoices,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 3. Fetch Customer Receivables
    final receivables = await (db.select(
      db.customerReceivables,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 4. Fetch Payments from Customers
    final payments = await (db.select(
      db.payments,
    )..where((t) => t.businessId.equals(businessId))).get();

    final rows = <CustomerDebtRow>[];

    for (final customer in customers) {
      final custSales = salesInvoices
          .where((s) => s.customerId == customer.id)
          .toList();
      final custReceivables = receivables
          .where((r) => r.customerId == customer.id)
          .toList();
      final custPayments = payments
          .where((p) => p.contactId == customer.id)
          .toList();

      final totalSales = custSales.fold<double>(
        0.0,
        (acc, s) => acc + s.baseGrandTotal,
      );
      final currentDebt = custReceivables.fold<double>(
        0.0,
        (acc, r) =>
            acc +
            (r.status.toLowerCase() != 'paid' ? r.baseRemainingAmount : 0.0),
      );

      double totalPaid = custPayments.fold<double>(
        0.0,
        (acc, p) => acc + p.baseAmount,
      );
      if (totalPaid == 0.0) {
        totalPaid = custReceivables.fold<double>(
          0.0,
          (acc, r) => acc + r.basePaidAmount,
        );
      }

      // Profit estimate: ~18% average margin on retail sales
      final estimatedProfit = totalSales * 0.18;

      DateTime? lastSales;
      if (custSales.isNotEmpty) {
        custSales.sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
        lastSales = custSales.first.invoiceDate;
      }

      DateTime? lastPayment;
      if (custPayments.isNotEmpty) {
        custPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        lastPayment = custPayments.first.paymentDate;
      } else {
        final withDates = custReceivables
            .where((r) => r.lastPaymentDate != null)
            .toList();
        if (withDates.isNotEmpty) {
          withDates.sort(
            (a, b) => b.lastPaymentDate!.compareTo(a.lastPaymentDate!),
          );
          lastPayment = withDates.first.lastPaymentDate;
        }
      }

      rows.add(
        CustomerDebtRow(
          id: customer.id,
          name: customer.customerName,
          phone: customer.phone,
          totalSales: totalSales,
          totalPaid: totalPaid,
          currentDebt: currentDebt,
          estimatedProfit: estimatedProfit,
          lastSalesDate: lastSales,
          lastPaymentDate: lastPayment,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _allRows = rows;
        _isLoading = false;
        _applySort();
      });
    }
  }

  void _applySort() {
    _allRows.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.name.compareTo(b.name);
          break;
        case 1:
          cmp = a.totalSales.compareTo(b.totalSales);
          break;
        case 2:
          cmp = a.totalPaid.compareTo(b.totalPaid);
          break;
        case 3:
          cmp = a.currentDebt.compareTo(b.currentDebt);
          break;
        case 4:
          cmp = a.estimatedProfit.compareTo(b.estimatedProfit);
          break;
        case 5:
          if (a.lastSalesDate == null && b.lastSalesDate == null)
            cmp = 0;
          else if (a.lastSalesDate == null)
            cmp = -1;
          else if (b.lastSalesDate == null)
            cmp = 1;
          else
            cmp = a.lastSalesDate!.compareTo(b.lastSalesDate!);
          break;
        case 6:
          if (a.lastPaymentDate == null && b.lastPaymentDate == null)
            cmp = 0;
          else if (a.lastPaymentDate == null)
            cmp = -1;
          else if (b.lastPaymentDate == null)
            cmp = 1;
          else
            cmp = a.lastPaymentDate!.compareTo(b.lastPaymentDate!);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySort();
    });
  }

  Future<void> _printReportPdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final filtered = _getFilteredRows();
    final totalDebt = filtered.fold<double>(
      0.0,
      (acc, r) => acc + r.currentDebt,
    );
    final totalSales = filtered.fold<double>(
      0.0,
      (acc, r) => acc + r.totalSales,
    );
    final totalPaid = filtered.fold<double>(0.0, (acc, r) => acc + r.totalPaid);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'تقرير مراقبة وتحليل مديونية العملاء',
                    style: pw.TextStyle(font: fontBold, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'تاريخ الطباعة: ${_dateFormat.format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'إجمالي المديونية: ${_moneyFormat.format(totalDebt)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.blue800,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              'الرقم',
              'اسم العميل',
              'رقم الهاتف',
              'إجمالي المبيعات',
              'إجمالي المسدد',
              'المديونية المتبقية',
              'الربح المقدر',
              'آخر سداد',
            ],
            data: List<List<String>>.generate(filtered.length, (index) {
              final r = filtered[index];
              return [
                '${index + 1}',
                r.name,
                r.phone ?? '—',
                _moneyFormat.format(r.totalSales),
                _moneyFormat.format(r.totalPaid),
                _moneyFormat.format(r.currentDebt),
                _moneyFormat.format(r.estimatedProfit),
                r.lastPaymentDate != null
                    ? _dateFormat.format(r.lastPaymentDate!)
                    : '—',
              ];
            }),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E293B),
            ),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
            ),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            cellAlignment: pw.Alignment.centerRight,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          ),
          pw.SizedBox(height: 16),

          // Totals Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text(
                  'عدد العملاء: ${filtered.length}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المبيعات: ${_moneyFormat.format(totalSales)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المسدد: ${_moneyFormat.format(totalPaid)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'صافي المتبقي في السوق: ${_moneyFormat.format(totalDebt)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Customer_Debts_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  List<CustomerDebtRow> _getFilteredRows() {
    if (_searchQuery.trim().isEmpty) return _allRows;
    final q = _searchQuery.toLowerCase().trim();
    return _allRows.where((r) {
      return r.name.toLowerCase().contains(q) ||
          (r.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final filteredRows = _getFilteredRows();
    final totalDebt = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.currentDebt,
    );
    final totalSales = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.totalSales,
    );
    final totalPaid = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.totalPaid,
    );
    final indebtedCount = filteredRows.where((r) => r.currentDebt > 0).length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'مراقبة وتحليل مديونية العملاء',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'طباعة التقرير PDF',
            icon: const Icon(Icons.print_rounded),
            onPressed: filteredRows.isEmpty ? null : _printReportPdf,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── 1. Summary Quick Cards ──
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSummaryCard(
                          title: 'إجمالي المديونية في السوق',
                          value: '${_moneyFormat.format(totalDebt)} ر.ي',
                          icon: Icons.account_balance_wallet_rounded,
                          color: const Color(0xFFEF4444),
                          subtitle: '$indebtedCount عميل عليهم متبقيات',
                          isDark: isDark,
                          surface: surface,
                          borderColor: borderColor,
                        ),
                        _buildSummaryCard(
                          title: 'إجمالي المبيعات الكلية',
                          value: '${_moneyFormat.format(totalSales)} ر.ي',
                          icon: Icons.shopping_bag_rounded,
                          color: const Color(0xFF3B82F6),
                          subtitle: 'لكافة العملاء المسجلين',
                          isDark: isDark,
                          surface: surface,
                          borderColor: borderColor,
                        ),
                        _buildSummaryCard(
                          title: 'إجمالي المحصل / المقبوض',
                          value: '${_moneyFormat.format(totalPaid)} ر.ي',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          subtitle: 'سدادات مسجلة نقدياً وبنكياً',
                          isDark: isDark,
                          surface: surface,
                          borderColor: borderColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── 2. Search & Filter Bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'بحث باسم العميل أو رقم الهاتف...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── 3. Data Table with Sortable Columns ──
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              headingRowColor: WidgetStateProperty.all(
                                isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                              ),
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 56,
                              horizontalMargin: 16,
                              columnSpacing: 24,
                              columns: [
                                DataColumn(
                                  label: const Text(
                                    'اسم العميل',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'إجمالي المبيعات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'إجمالي المسدد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'المديونية الحالية',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'الأرباح المقدرة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'آخر حركة شراء',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'آخر عملية سداد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                              ],
                              rows: filteredRows.map((r) {
                                final hasDebt = r.currentDebt > 0;
                                return DataRow(
                                  cells: [
                                    // 0. Name & Phone
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: textPrimary,
                                            ),
                                          ),
                                          if (r.phone != null &&
                                              r.phone!.isNotEmpty)
                                            Text(
                                              r.phone!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // 1. Total Sales
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.totalSales)} ر.ي',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // 2. Total Paid
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.totalPaid)} ر.ي',
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    // 3. Current Debt
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasDebt
                                              ? const Color(
                                                  0xFFEF4444,
                                                ).withValues(alpha: 0.12)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${_moneyFormat.format(r.currentDebt)} ر.ي',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: hasDebt
                                                ? const Color(0xFFEF4444)
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 4. Estimated Profit
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.estimatedProfit)} ر.ي',
                                        style: const TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // 5. Last Sales Date
                                    DataCell(
                                      Text(
                                        r.lastSalesDate != null
                                            ? _dateFormat.format(
                                                r.lastSalesDate!,
                                              )
                                            : '—',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    // 6. Last Payment Date
                                    DataCell(
                                      Text(
                                        r.lastPaymentDate != null
                                            ? _dateFormat.format(
                                                r.lastPaymentDate!,
                                              )
                                            : '—',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: r.lastPaymentDate != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: r.lastPaymentDate != null
                                              ? const Color(0xFF059669)
                                              : textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isDark,
    required Color surface,
    required Color borderColor,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
