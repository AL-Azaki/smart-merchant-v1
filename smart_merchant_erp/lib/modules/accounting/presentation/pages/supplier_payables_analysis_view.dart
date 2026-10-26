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

class SupplierPayableRow {
  final String id;
  final String name;
  final String? phone;
  final double totalPurchases;
  final double totalPaid;
  final double currentPayable;
  final DateTime? lastPurchaseDate;
  final DateTime? lastPaymentDate;

  const SupplierPayableRow({
    required this.id,
    required this.name,
    required this.totalPurchases,
    required this.totalPaid,
    required this.currentPayable,
    this.phone,
    this.lastPurchaseDate,
    this.lastPaymentDate,
  });
}

class SupplierPayablesAnalysisView extends ConsumerStatefulWidget {
  const SupplierPayablesAnalysisView({super.key});

  @override
  ConsumerState<SupplierPayablesAnalysisView> createState() =>
      _SupplierPayablesAnalysisViewState();
}

class _SupplierPayablesAnalysisViewState
    extends ConsumerState<SupplierPayablesAnalysisView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 3; // Default sort by remaining payable
  bool _sortAscending = false; // Descending (highest payable first)
  bool _isLoading = true;
  List<SupplierPayableRow> _allRows = [];

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

    // 1. Fetch Suppliers
    final suppliers = await (db.select(
      db.suppliers,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Purchase Invoices
    final purchaseInvoices = await (db.select(
      db.purchaseInvoices,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 3. Fetch Supplier Payables
    final payables = await (db.select(
      db.supplierPayables,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 4. Fetch Payments made to Suppliers
    final payments = await (db.select(
      db.payments,
    )..where((t) => t.businessId.equals(businessId))).get();

    final rows = <SupplierPayableRow>[];

    for (final supplier in suppliers) {
      final suppPurchases = purchaseInvoices
          .where((p) => p.supplierId == supplier.id)
          .toList();
      final suppPayables = payables
          .where((p) => p.supplierId == supplier.id)
          .toList();
      final suppPayments = payments
          .where((p) => p.contactId == supplier.id)
          .toList();

      final totalPurchases = suppPurchases.fold<double>(
        0.0,
        (acc, p) => acc + p.baseGrandTotal,
      );
      final currentPayable = suppPayables.fold<double>(
        0.0,
        (acc, p) =>
            acc +
            (p.status.toLowerCase() != 'paid' ? p.baseRemainingAmount : 0.0),
      );

      double totalPaid = suppPayments.fold<double>(
        0.0,
        (acc, p) => acc + p.baseAmount,
      );
      if (totalPaid == 0.0) {
        totalPaid = suppPayables.fold<double>(
          0.0,
          (acc, p) => acc + p.basePaidAmount,
        );
      }

      DateTime? lastPurchase;
      if (suppPurchases.isNotEmpty) {
        suppPurchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
        lastPurchase = suppPurchases.first.purchaseDate;
      }

      DateTime? lastPayment;
      if (suppPayments.isNotEmpty) {
        suppPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        lastPayment = suppPayments.first.paymentDate;
      } else {
        final withDates = suppPayables
            .where((p) => p.lastPaymentDate != null)
            .toList();
        if (withDates.isNotEmpty) {
          withDates.sort(
            (a, b) => b.lastPaymentDate!.compareTo(a.lastPaymentDate!),
          );
          lastPayment = withDates.first.lastPaymentDate;
        }
      }

      rows.add(
        SupplierPayableRow(
          id: supplier.id,
          name: supplier.supplierName,
          phone: supplier.phone,
          totalPurchases: totalPurchases,
          totalPaid: totalPaid,
          currentPayable: currentPayable,
          lastPurchaseDate: lastPurchase,
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
          cmp = a.totalPurchases.compareTo(b.totalPurchases);
          break;
        case 2:
          cmp = a.totalPaid.compareTo(b.totalPaid);
          break;
        case 3:
          cmp = a.currentPayable.compareTo(b.currentPayable);
          break;
        case 4:
          if (a.lastPurchaseDate == null && b.lastPurchaseDate == null)
            cmp = 0;
          else if (a.lastPurchaseDate == null)
            cmp = -1;
          else if (b.lastPurchaseDate == null)
            cmp = 1;
          else
            cmp = a.lastPurchaseDate!.compareTo(b.lastPurchaseDate!);
          break;
        case 5:
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
    final fonts = await AnalyticsPdfHelper.loadArabicFonts();
    final font = fonts.regular;
    final fontBold = fonts.bold;

    final filtered = _getFilteredRows();
    final totalPayable = filtered.fold<double>(
      0.0,
      (acc, r) => acc + r.currentPayable,
    );
    final totalPurchases = filtered.fold<double>(
      0.0,
      (acc, r) => acc + r.totalPurchases,
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
                    'تقرير مراقبة وتحليل التزامات الموردين',
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
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'إجمالي الالتزامات الواجبة: ${_moneyFormat.format(totalPayable)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.red800,
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
              'اسم المورد',
              'رقم الهاتف',
              'إجمالي المشتريات',
              'إجمالي المسدد له',
              'الالتزام المتبقي علينا',
              'آخر حركة شراء',
              'آخر سداد له',
            ],
            data: List<List<String>>.generate(filtered.length, (index) {
              final r = filtered[index];
              return [
                '${index + 1}',
                r.name,
                r.phone ?? '—',
                _moneyFormat.format(r.totalPurchases),
                _moneyFormat.format(r.totalPaid),
                _moneyFormat.format(r.currentPayable),
                r.lastPurchaseDate != null
                    ? _dateFormat.format(r.lastPurchaseDate!)
                    : '—',
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
                  'عدد الموردين: ${filtered.length}',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المشتريات: ${_moneyFormat.format(totalPurchases)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'إجمالي المسدد: ${_moneyFormat.format(totalPaid)} ر.ي',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.Text(
                  'صافي المتبقي علينا: ${_moneyFormat.format(totalPayable)} ر.ي',
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
          'Supplier_Payables_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  List<SupplierPayableRow> _getFilteredRows() {
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
    final totalPayable = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.currentPayable,
    );
    final totalPurchases = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.totalPurchases,
    );
    final totalPaid = filteredRows.fold<double>(
      0.0,
      (acc, r) => acc + r.totalPaid,
    );
    final duesCount = filteredRows.where((r) => r.currentPayable > 0).length;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'مراقبة وتحليل التزامات الموردين',
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
                              title: 'إجمالي الالتزامات الواجبة علينا',
                              value: '${_moneyFormat.format(totalPayable)} ر.ي',
                              icon: Icons.inventory_2_rounded,
                              color: const Color(0xFFF43F5E),
                              subtitle: '$duesCount مورد يطالبنا بمستحقات',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'إجمالي المشتريات من الموردين',
                              value:
                                  '${_moneyFormat.format(totalPurchases)} ر.ي',
                              icon: Icons.shopping_cart_outlined,
                              color: const Color(0xFF3B82F6),
                              subtitle: 'لكافة الموردين المسجلين',
                              isDark: isDark,
                              surface: surface,
                              borderColor: borderColor,
                              width: cardWidth,
                            ),
                            _buildSummaryCard(
                              title: 'إجمالي المسدد للموردين',
                              value: '${_moneyFormat.format(totalPaid)} ر.ي',
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF10B981),
                              subtitle: 'سدادات مسجلة بسندات الصرف',
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
                                        'بحث باسم المورد أو رقم الهاتف...',
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
                            backgroundColor: const Color(0xFFF43F5E),
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
                                    'اسم المورد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'إجمالي المشتريات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'إجمالي المسدد له',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn(
                                  label: const Text(
                                    'المتبقي علينا (الالتزام)',
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
                                    'آخر دفعة سداد',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onSort: _onSort,
                                ),
                              ],
                              rows: filteredRows.map((r) {
                                final hasDues = r.currentPayable > 0;
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
                                    // 1. Total Purchases
                                    DataCell(
                                      Text(
                                        '${_moneyFormat.format(r.totalPurchases)} ر.ي',
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
                                    // 3. Current Payable
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasDues
                                              ? const Color(
                                                  0xFFF43F5E,
                                                ).withValues(alpha: 0.12)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${_moneyFormat.format(r.currentPayable)} ر.ي',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: hasDues
                                                ? const Color(0xFFF43F5E)
                                                : textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 4. Last Purchase Date
                                    DataCell(
                                      Text(
                                        r.lastPurchaseDate != null
                                            ? _dateFormat.format(
                                                r.lastPurchaseDate!,
                                              )
                                            : '—',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    // 5. Last Payment Date
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
