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
import '../services/analytics_pdf_helper.dart';

class SalesInvoiceRow {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final DateTime invoiceDate;
  final String paymentType; // 'cash' or 'credit'
  final String status;
  final double totalAmount;

  const SalesInvoiceRow({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.invoiceDate,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
  });
}

class SalesAnalysisView extends ConsumerStatefulWidget {
  const SalesAnalysisView({super.key});

  @override
  ConsumerState<SalesAnalysisView> createState() => _SalesAnalysisViewState();
}

class _SalesAnalysisViewState extends ConsumerState<SalesAnalysisView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 2; // Default sort by date
  bool _sortAscending = false; // Newest first
  bool _isLoading = true;
  List<SalesInvoiceRow> _allRows = [];

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

    // 1. Fetch Sales Invoices
    final invoices = await (db.select(
      db.salesInvoices,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Customers for mapping names
    final customers = await (db.select(
      db.customers,
    )..where((t) => t.businessId.equals(businessId))).get();
    final customerMap = {for (final c in customers) c.id: c.customerName};

    final rows = invoices.map((inv) {
      final custName = inv.customerId != null
          ? (customerMap[inv.customerId] ?? 'عميل نقدي')
          : 'عميل نقدي';

      final isCash = inv.paymentStatus.toLowerCase() == 'paid';
      return SalesInvoiceRow(
        id: inv.id,
        invoiceNumber: inv.invoiceNumber,
        customerName: custName,
        invoiceDate: inv.invoiceDate,
        paymentType: isCash ? 'cash' : 'credit',
        status: inv.status,
        totalAmount: inv.baseGrandTotal,
      );
    }).toList();

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
          cmp = a.invoiceNumber.compareTo(b.invoiceNumber);
          break;
        case 1:
          cmp = a.customerName.compareTo(b.customerName);
          break;
        case 2:
          cmp = a.invoiceDate.compareTo(b.invoiceDate);
          break;
        case 3:
          cmp = a.paymentType.compareTo(b.paymentType);
          break;
        case 4:
          cmp = a.totalAmount.compareTo(b.totalAmount);
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

  List<SalesInvoiceRow> _getFilteredRows() {
    if (_searchQuery.trim().isEmpty) return _allRows;
    final q = _searchQuery.toLowerCase().trim();
    return _allRows.where((r) {
      return r.invoiceNumber.toLowerCase().contains(q) ||
          r.customerName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _printReportPdf() async {
    final pdf = pw.Document();
    final fonts = await AnalyticsPdfHelper.loadArabicFonts();
    final font = fonts.regular;
    final fontBold = fonts.bold;

    final filtered = _getFilteredRows();
    final totalSales = filtered.fold<double>(
      0.0,
      (acc, r) => acc + r.totalAmount,
    );
    final cashSales = filtered
        .where((r) => r.paymentType.toLowerCase() == 'cash')
        .fold<double>(0.0, (acc, r) => acc + r.totalAmount);
    final creditSales = totalSales - cashSales;

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
                    'تقرير سجل وتحليل فواتير المبيعات',
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
                  color: const PdfColor.fromInt(0xFF3B82F6),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'نظام التاجر الذكي ERP',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: PdfColors.white,
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
              'رقم الفاتورة',
              'اسم العميل',
              'تاريخ الفاتورة',
              'نوع السداد',
              'الحالة',
              'المبلغ الإجمالي',
            ],
            data: List<List<String>>.generate(filtered.length, (index) {
              final r = filtered[index];
              final isCash = r.paymentType.toLowerCase() == 'cash';
              return [
                '${index + 1}',
                r.invoiceNumber,
                r.customerName,
                _dateFormat.format(r.invoiceDate),
                isCash ? 'نقدي (Cash)' : 'آجل (Credit)',
                r.status,
                '${_moneyFormat.format(r.totalAmount)} ر.ي',
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

          // Summary Box
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
                  'عدد الفواتير: ${filtered.length}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'مبيعات نقدية: ${_moneyFormat.format(cashSales)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'مبيعات آجلة: ${_moneyFormat.format(creditSales)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المبيعات: ${_moneyFormat.format(totalSales)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFF3B82F6),
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
      name: 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final filteredRows = _getFilteredRows();
    final totalSales = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.totalAmount,
    );
    final cashSales = filteredRows
        .where((r) => r.paymentType.toLowerCase() == 'cash')
        .fold<double>(0.0, (acc, r) => acc + r.totalAmount);
    final creditSales = totalSales - cashSales;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تحليل وسجل المبيعات',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
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
                    // ── 1. Summary Quick Cards (Responsive) ──
                    LayoutBuilder(
                      builder: (context, box) {
                        final w = box.maxWidth;
                        final int crossCount = w >= 950
                            ? 3
                            : (w >= 600 ? 2 : 1);
                        final cardWidth = crossCount == 1
                            ? w
                            : (w - ((crossCount - 1) * 12)) / crossCount;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildSummaryCard(
                              title: 'إجمالي المبيعات الكلية',
                              value: '${_moneyFormat.format(totalSales)} ر.ي',
                              icon: Icons.shopping_bag_rounded,
                              color: const Color(0xFF3B82F6),
                              subtitle: '${filteredRows.length} فاتورة مسجلة',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'المبيعات النقدية (الكاش)',
                              value: '${_moneyFormat.format(cashSales)} ر.ي',
                              icon: Icons.payments_rounded,
                              color: const Color(0xFF10B981),
                              subtitle: 'مقبوضة فوراً في الخزينة',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'المبيعات الآجلة (بالدين)',
                              value: '${_moneyFormat.format(creditSales)} ر.ي',
                              icon: Icons.receipt_long_rounded,
                              color: const Color(0xFF8B5CF6),
                              subtitle: 'ذمم مدينة قيد التحصيل',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // ── 2. Search & Report Action Bar (Responsive) ──
                    LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final isMobile = boxConstraints.maxWidth < 650;
                        final searchBar = Container(
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
                                    hintText:
                                        'بحث برقم الفاتورة أو اسم العميل...',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                            ],
                          ),
                        );

                        final pdfButton = ElevatedButton.icon(
                          onPressed: filteredRows.isEmpty
                              ? null
                              : _printReportPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'عرض وتحميل التقرير PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchBar,
                              const SizedBox(height: 10),
                              pdfButton,
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: searchBar),
                              const SizedBox(width: 12),
                              pdfButton,
                            ],
                          );
                        }
                      },
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
                                    'رقم الفاتورة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
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
                                    'تاريخ الفاتورة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'نوع السداد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                              ],
                              rows: filteredRows.map((r) {
                                final isCash =
                                    r.paymentType.toLowerCase() == 'cash';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        r.invoiceNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(r.customerName)),
                                    DataCell(
                                      Text(_dateFormat.format(r.invoiceDate)),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCash
                                              ? const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.12)
                                              : const Color(
                                                  0xFF8B5CF6,
                                                ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          isCash ? 'نقدي' : 'آجل',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isCash
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.totalAmount)} ر.ي',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
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
    required double width,
  }) {
    return Container(
      width: width,
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
