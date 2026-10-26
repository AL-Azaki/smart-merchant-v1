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

class CashMovementRow {
  final String id;
  final String referenceNumber;
  final String partyName;
  final DateTime date;
  final String type; // 'inflow' or 'outflow'
  final double amount;
  final String method;

  const CashMovementRow({
    required this.id,
    required this.referenceNumber,
    required this.partyName,
    required this.date,
    required this.type,
    required this.amount,
    required this.method,
  });
}

class CashFlowAnalysisView extends ConsumerStatefulWidget {
  const CashFlowAnalysisView({super.key});

  @override
  ConsumerState<CashFlowAnalysisView> createState() =>
      _CashFlowAnalysisViewState();
}

class _CashFlowAnalysisViewState extends ConsumerState<CashFlowAnalysisView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 2; // Default sort by date
  bool _sortAscending = false; // Newest first
  bool _isLoading = true;
  List<CashMovementRow> _allRows = [];

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

    // 1. Fetch Payments (Receipts and Payment Vouchers)
    final payments = await (db.select(
      db.payments,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Expenses (Operating Outflows)
    final expenses = await (db.select(
      db.expenses,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 3. Fetch Customers & Suppliers for party names
    final customers = await (db.select(
      db.customers,
    )..where((t) => t.businessId.equals(businessId))).get();
    final custMap = {for (final c in customers) c.id: c.customerName};

    final suppliers = await (db.select(
      db.suppliers,
    )..where((t) => t.businessId.equals(businessId))).get();
    final suppMap = {for (final s in suppliers) s.id: s.supplierName};

    final rows = <CashMovementRow>[];

    for (final p in payments) {
      final isReceipt =
          p.paymentType.toLowerCase() == 'receipt' ||
          p.paymentType.toLowerCase() == 'inflow';
      String party = isReceipt ? 'عميل مقبوضات' : 'مورد مدفوعات';
      if (p.contactId != null) {
        party = custMap[p.contactId] ?? suppMap[p.contactId] ?? party;
      }

      rows.add(
        CashMovementRow(
          id: p.id,
          referenceNumber: p.paymentNumber,
          partyName: party,
          date: p.paymentDate,
          type: isReceipt ? 'inflow' : 'outflow',
          amount: p.baseAmount,
          method: p.notes != null && p.notes!.isNotEmpty
              ? p.notes!
              : 'سند مالي',
        ),
      );
    }

    for (final e in expenses) {
      rows.add(
        CashMovementRow(
          id: e.id,
          referenceNumber: e.expenseNumber,
          partyName: 'مصروف: ${e.notes ?? "تشغيلي"}',
          date: e.expenseDate,
          type: 'outflow',
          amount: e.baseAmount,
          method: e.paymentMethodId.isNotEmpty ? e.paymentMethodId : 'نقداً',
        ),
      );
    }

    // 4. Fetch Cash Sales if no payments exist
    if (rows.isEmpty) {
      final sales = await (db.select(
        db.salesInvoices,
      )..where((t) => t.businessId.equals(businessId))).get();
      for (final s in sales) {
        if (s.paymentStatus.toLowerCase() == 'paid') {
          rows.add(
            CashMovementRow(
              id: s.id,
              referenceNumber: s.invoiceNumber,
              partyName: 'مبيعات نقدية مباشرة',
              date: s.invoiceDate,
              type: 'inflow',
              amount: s.baseGrandTotal,
              method: 'نقداً',
            ),
          );
        }
      }
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
          cmp = a.referenceNumber.compareTo(b.referenceNumber);
          break;
        case 1:
          cmp = a.partyName.compareTo(b.partyName);
          break;
        case 2:
          cmp = a.date.compareTo(b.date);
          break;
        case 3:
          cmp = a.type.compareTo(b.type);
          break;
        case 4:
          cmp = a.amount.compareTo(b.amount);
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

  List<CashMovementRow> _getFilteredRows() {
    if (_searchQuery.trim().isEmpty) return _allRows;
    final q = _searchQuery.toLowerCase().trim();
    return _allRows.where((r) {
      return r.referenceNumber.toLowerCase().contains(q) ||
          r.partyName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _printReportPdf() async {
    final pdf = pw.Document();
    final fonts = await AnalyticsPdfHelper.loadArabicFonts();
    final font = fonts.regular;
    final fontBold = fonts.bold;

    final filtered = _getFilteredRows();
    final totalInflow = filtered
        .where((r) => r.type == 'inflow')
        .fold<double>(0.0, (acc, r) => acc + r.amount);
    final totalOutflow = filtered
        .where((r) => r.type == 'outflow')
        .fold<double>(0.0, (acc, r) => acc + r.amount);
    final netFlow = totalInflow - totalOutflow;

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
                    'تقرير سجل وحركة التدفق النقدي (Inflows vs Outflows)',
                    style: pw.TextStyle(font: fontBold, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'تاريخ التقرير: ${_dateFormat.format(DateTime.now())}',
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
                  color: const PdfColor.fromInt(0xFF10B981),
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
              'رقم الحركة / السند',
              'الجهة / البيان',
              'التاريخ',
              'طريقة الدفع',
              'النوع',
              'المبلغ',
            ],
            data: List<List<String>>.generate(filtered.length, (index) {
              final r = filtered[index];
              final isInflow = r.type == 'inflow';
              return [
                '${index + 1}',
                r.referenceNumber,
                r.partyName,
                _dateFormat.format(r.date),
                r.method,
                isInflow ? 'مقبوضات واردة (+)' : 'مدفوعات خارجة (-)',
                '${_moneyFormat.format(r.amount)} ر.ي',
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
                  'عدد الحركات: ${filtered.length}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المقبوضات: ${_moneyFormat.format(totalInflow)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFF10B981),
                  ),
                ),
                pw.Text(
                  'إجمالي المدفوعات: ${_moneyFormat.format(totalOutflow)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.red800,
                  ),
                ),
                pw.Text(
                  'صافي التدفق: ${_moneyFormat.format(netFlow)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: netFlow >= 0
                        ? const PdfColor.fromInt(0xFF10B981)
                        : PdfColors.red800,
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
          'Cash_Flow_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
    final totalInflow = filteredRows
        .where((r) => r.type == 'inflow')
        .fold<double>(0.0, (acc, r) => acc + r.amount);
    final totalOutflow = filteredRows
        .where((r) => r.type == 'outflow')
        .fold<double>(0.0, (acc, r) => acc + r.amount);
    final netFlow = totalInflow - totalOutflow;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'سجل وحركات التدفق النقدي',
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
                              title: 'صافي التدفق النقدي',
                              value: '${_moneyFormat.format(netFlow)} ر.ي',
                              icon: Icons.swap_horiz_rounded,
                              color: netFlow >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              subtitle: netFlow >= 0
                                  ? 'فائض نقدي متاح'
                                  : 'عجز نقدي مؤقت',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'إجمالي المقبوضات النقدية (داخلة)',
                              value: '${_moneyFormat.format(totalInflow)} ر.ي',
                              icon: Icons.arrow_downward_rounded,
                              color: const Color(0xFF10B981),
                              subtitle: 'مبيعات وسندات قبض عملاء',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'إجمالي المدفوعات والمصروفات (خارجة)',
                              value: '${_moneyFormat.format(totalOutflow)} ر.ي',
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFEF4444),
                              subtitle: 'سدادات موردين ومصروفات تشغيلية',
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
                                    hintText: 'بحث برقم السند أو الجهة...',
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
                            backgroundColor: const Color(0xFF10B981),
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
                                    'رقم الحركة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'الجهة / البيان',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'التاريخ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'النوع',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'المبلغ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                              ],
                              rows: filteredRows.map((r) {
                                final isInflow = r.type == 'inflow';
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        r.referenceNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(r.partyName)),
                                    DataCell(Text(_dateFormat.format(r.date))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isInflow
                                              ? const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.12)
                                              : const Color(
                                                  0xFFEF4444,
                                                ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          isInflow ? 'وارد (+)' : 'صادر (-)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isInflow
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.amount)} ر.ي',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isInflow
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
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
