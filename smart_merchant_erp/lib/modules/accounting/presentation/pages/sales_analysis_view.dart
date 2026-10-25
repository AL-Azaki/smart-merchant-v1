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
import '../widgets/custom_line_chart.dart';

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

class ProductProfitRow {
  final String productName;
  final double quantity;
  final double totalSales;
  final double totalProfit;
  final double marginPercent;

  const ProductProfitRow({
    required this.productName,
    required this.quantity,
    required this.totalSales,
    required this.totalProfit,
    required this.marginPercent,
  });
}

class CustomerProfitRow {
  final String customerName;
  final int invoicesCount;
  final double totalPurchases;
  final double totalProfit;
  final double cashRatio;

  const CustomerProfitRow({
    required this.customerName,
    required this.invoicesCount,
    required this.totalPurchases,
    required this.totalProfit,
    required this.cashRatio,
  });
}

class BranchPerformanceRow {
  final String branchName;
  final int invoicesCount;
  final double totalSales;
  final double totalProfit;
  final double sharePercent;

  const BranchPerformanceRow({
    required this.branchName,
    required this.invoicesCount,
    required this.totalSales,
    required this.totalProfit,
    required this.sharePercent,
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
  int _activeInsightTab = 0; // 0: المنتجات, 1: العملاء, 2: الفروع, 3: الفواتير

  List<SalesInvoiceRow> _allRows = [];
  List<ProductProfitRow> _productRows = [];
  List<CustomerProfitRow> _customerRows = [];
  List<BranchPerformanceRow> _branchRows = [];
  List<ChartLineSeries> _chartSeries = [];

  // MoM metrics
  double _thisMonthSales = 0;
  double _lastMonthSales = 0;
  double _salesGrowthPercent = 0;
  double _thisMonthProfit = 0;
  double _lastMonthProfit = 0;
  double _profitGrowthPercent = 0;

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final businessId = session.businessId!;
    final db = getIt<AppDatabase>();

    // 1. Fetch Sales Invoices
    final invoices = await (db.select(
      db.salesInvoices,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Customers
    final customers = await (db.select(
      db.customers,
    )..where((t) => t.businessId.equals(businessId))).get();
    final customerMap = {for (final c in customers) c.id: c.customerName};

    // 3. Fetch Branches
    final branches = await (db.select(
      db.branches,
    )..where((t) => t.businessId.equals(businessId))).get();
    final branchMap = {for (final b in branches) b.id: b.branchName};

    // 4. Fetch Products and ProductUnits
    final products = await (db.select(
      db.products,
    )..where((t) => t.businessId.equals(businessId))).get();
    final productMap = {for (final p in products) p.id: p.productName};

    final productUnits = await (db.select(
      db.productUnits,
    )..where((t) => t.businessId.equals(businessId))).get();
    final unitToProductName = {
      for (final u in productUnits)
        u.id: (productMap[u.productId] ?? 'منتج عام'),
    };

    // 5. Fetch Sales Invoice Items
    final invoiceItems = await (db.select(
      db.salesInvoiceItems,
    )..where((t) => t.businessId.equals(businessId))).get();

    final itemsByInvoice = <String, List<SalesInvoiceItem>>{};
    for (final item in invoiceItems) {
      itemsByInvoice.putIfAbsent(item.salesInvoiceId, () => []).add(item);
    }

    // 6. Map SalesInvoiceRow
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

    // 7. Calculate Month-over-Month (MoM)
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double thisMonthSales = 0;
    double lastMonthSales = 0;
    double thisMonthProfit = 0;
    double lastMonthProfit = 0;

    for (final inv in invoices) {
      final isThisMonth =
          inv.invoiceDate.isAfter(thisMonthStart) ||
          inv.invoiceDate.isAtSameMomentAs(thisMonthStart);
      final isLastMonth =
          inv.invoiceDate.isAfter(lastMonthStart) &&
          inv.invoiceDate.isBefore(lastMonthEnd);

      final items = itemsByInvoice[inv.id] ?? const [];
      double invProfit = 0;
      for (final item in items) {
        invProfit += (item.baseLineTotal - item.costTotal);
      }
      if (items.isEmpty && inv.baseGrandTotal > 0) {
        invProfit = inv.baseGrandTotal * 0.22; // Conservative fallback margin
      }

      if (isThisMonth) {
        thisMonthSales += inv.baseGrandTotal;
        thisMonthProfit += invProfit;
      } else if (isLastMonth) {
        lastMonthSales += inv.baseGrandTotal;
        lastMonthProfit += invProfit;
      }
    }

    final salesGrowth = lastMonthSales > 0
        ? ((thisMonthSales - lastMonthSales) / lastMonthSales) * 100
        : (thisMonthSales > 0 ? 100.0 : 0.0);
    final profitGrowth = lastMonthProfit > 0
        ? ((thisMonthProfit - lastMonthProfit) / lastMonthProfit) * 100
        : (thisMonthProfit > 0 ? 100.0 : 0.0);

    // 8. Aggregate Product Profitability
    final productAccumulator = <String, _ProductAcc>{};
    for (final item in invoiceItems) {
      final name = unitToProductName[item.productUnitId] ?? 'منتج عام';
      final acc = productAccumulator.putIfAbsent(name, () => _ProductAcc());
      acc.quantity += item.quantity;
      acc.totalSales += item.baseLineTotal;
      acc.totalProfit += (item.baseLineTotal - item.costTotal);
    }

    final productRows = productAccumulator.entries.map((e) {
      final margin = e.value.totalSales > 0
          ? (e.value.totalProfit / e.value.totalSales) * 100
          : 0.0;
      return ProductProfitRow(
        productName: e.key,
        quantity: e.value.quantity,
        totalSales: e.value.totalSales,
        totalProfit: e.value.totalProfit,
        marginPercent: margin,
      );
    }).toList()..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

    // 9. Aggregate Customer Profitability
    final customerAccumulator = <String, _CustomerAcc>{};
    for (final inv in invoices) {
      final name = inv.customerId != null
          ? (customerMap[inv.customerId] ?? 'عميل نقدي')
          : 'عميل نقدي';
      final acc = customerAccumulator.putIfAbsent(name, () => _CustomerAcc());
      acc.invoicesCount++;
      acc.totalPurchases += inv.baseGrandTotal;
      if (inv.paymentStatus.toLowerCase() == 'paid') {
        acc.cashPurchases += inv.baseGrandTotal;
      }
      final items = itemsByInvoice[inv.id] ?? const [];
      double invProfit = 0;
      for (final item in items) {
        invProfit += (item.baseLineTotal - item.costTotal);
      }
      if (items.isEmpty && inv.baseGrandTotal > 0) {
        invProfit = inv.baseGrandTotal * 0.22;
      }
      acc.totalProfit += invProfit;
    }

    final customerRows = customerAccumulator.entries.map((e) {
      final cashRatio = e.value.totalPurchases > 0
          ? (e.value.cashPurchases / e.value.totalPurchases) * 100
          : 100.0;
      return CustomerProfitRow(
        customerName: e.key,
        invoicesCount: e.value.invoicesCount,
        totalPurchases: e.value.totalPurchases,
        totalProfit: e.value.totalProfit,
        cashRatio: cashRatio,
      );
    }).toList()..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

    // 10. Aggregate Branch Performance
    final branchAccumulator = <String, _BranchAcc>{};
    double allBranchesTotalSales = 0;
    for (final inv in invoices) {
      final name = branchMap[inv.branchId] ?? 'الفرع الرئيسي';
      final acc = branchAccumulator.putIfAbsent(name, () => _BranchAcc());
      acc.invoicesCount++;
      acc.totalSales += inv.baseGrandTotal;
      allBranchesTotalSales += inv.baseGrandTotal;
      final items = itemsByInvoice[inv.id] ?? const [];
      double invProfit = 0;
      for (final item in items) {
        invProfit += (item.baseLineTotal - item.costTotal);
      }
      if (items.isEmpty && inv.baseGrandTotal > 0) {
        invProfit = inv.baseGrandTotal * 0.22;
      }
      acc.totalProfit += invProfit;
    }

    final branchRows = branchAccumulator.entries.map((e) {
      final share = allBranchesTotalSales > 0
          ? (e.value.totalSales / allBranchesTotalSales) * 100
          : 100.0;
      return BranchPerformanceRow(
        branchName: e.key,
        invoicesCount: e.value.invoicesCount,
        totalSales: e.value.totalSales,
        totalProfit: e.value.totalProfit,
        sharePercent: share,
      );
    }).toList()..sort((a, b) => b.totalSales.compareTo(a.totalSales));

    // 11. Generate Daily Line Chart Series (Past 14 days)
    final salesPoints = <ChartDataPoint>[];
    final profitPoints = <ChartDataPoint>[];
    for (int i = 13; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayLabel = '${day.day}/${day.month}';

      double daySales = 0;
      double dayProfit = 0;
      for (final inv in invoices) {
        if (inv.invoiceDate.year == day.year &&
            inv.invoiceDate.month == day.month &&
            inv.invoiceDate.day == day.day) {
          daySales += inv.baseGrandTotal;
          final items = itemsByInvoice[inv.id] ?? const [];
          double p = 0;
          for (final item in items) {
            p += (item.baseLineTotal - item.costTotal);
          }
          if (items.isEmpty && inv.baseGrandTotal > 0) {
            p = inv.baseGrandTotal * 0.22;
          }
          dayProfit += p;
        }
      }
      salesPoints.add(
        ChartDataPoint(label: dayLabel, value: daySales, date: day),
      );
      profitPoints.add(
        ChartDataPoint(label: dayLabel, value: dayProfit, date: day),
      );
    }

    final chartSeries = [
      ChartLineSeries(
        name: 'إجمالي المبيعات',
        color: const Color(0xFF6366F1),
        points: salesPoints,
      ),
      ChartLineSeries(
        name: 'صافي الأرباح',
        color: const Color(0xFF10B981),
        points: profitPoints,
      ),
    ];

    if (mounted) {
      setState(() {
        _allRows = rows;
        _productRows = productRows;
        _customerRows = customerRows;
        _branchRows = branchRows;
        _chartSeries = chartSeries;
        _thisMonthSales = thisMonthSales;
        _lastMonthSales = lastMonthSales;
        _salesGrowthPercent = salesGrowth;
        _thisMonthProfit = thisMonthProfit;
        _lastMonthProfit = lastMonthProfit;
        _profitGrowthPercent = profitGrowth;
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
    if (_searchQuery.trim().isEmpty) {
      return _allRows;
    }
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

          // Summary Boxes
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'المبيعات النقدية: ${_moneyFormat.format(cashSales)} ر.ي',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'المبيعات الآجلة: ${_moneyFormat.format(creditSales)} ر.ي',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEFF6FF),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFF3B82F6),
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'إجمالي المبيعات المحققة: ${_moneyFormat.format(totalSales)} ر.ي',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: const PdfColor.fromInt(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Sales_Analysis_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

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
          'تحليل وتفاصيل المبيعات',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'تصدير التقرير PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: filteredRows.isEmpty ? null : _printReportPdf,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;
                return ListView(
                  padding: EdgeInsets.all(isCompact ? 12 : 18),
                  children: [
                    // ── 1. Month-over-Month (MoM) Growth Banner ──
                    _buildMoMGrowthBanner(isDark, borderColor),
                    const SizedBox(height: 16),

                    // ── 2. Summary Quick KPI Cards ──
                    _buildSummaryKpis(
                      totalSales: totalSales,
                      cashSales: cashSales,
                      creditSales: creditSales,
                      count: filteredRows.length,
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 18),

                    // ── 3. Interactive Line Chart (Daily Sales & Profit) ──
                    if (_chartSeries.isNotEmpty) ...[
                      _buildLineChartSection(
                        isDark: isDark,
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── 4. Smart Insights Navigation Tabs ──
                    _buildInsightTabSelector(isDark, borderColor),
                    const SizedBox(height: 16),

                    // ── 5. Active Tab View Content ──
                    _buildActiveTabContent(
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      constraints: constraints,
                      filteredRows: filteredRows,
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  // ── Growth Banner ──
  Widget _buildMoMGrowthBanner(bool isDark, Color borderColor) {
    final isPositiveSales = _salesGrowthPercent >= 0;
    final isPositiveProfit = _profitGrowthPercent >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13151D) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262A38) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF5B4DF5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF5B4DF5),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'مؤشر النمو الشهري (MoM)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isPositiveSales
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isPositiveSales ? '+' : ''}${_salesGrowthPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isPositiveSales
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'مبيعات الشهر ${_moneyFormat.format(_thisMonthSales)} ر.ي '
                  '(السابق: ${_moneyFormat.format(_lastMonthSales)} ر.ي) | '
                  'الأرباح: ${_moneyFormat.format(_thisMonthProfit)} ر.ي '
                  '(السابق: ${_moneyFormat.format(_lastMonthProfit)} ر.ي) '
                  '(${isPositiveProfit ? '+' : ''}${_profitGrowthPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary KPI Cards ──
  Widget _buildSummaryKpis({
    required double totalSales,
    required double cashSales,
    required double creditSales,
    required int count,
    required bool isDark,
    required Color surface,
    required Color borderColor,
  }) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final int crossCount = w >= 950 ? 3 : (w >= 600 ? 2 : 1);
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
              color: const Color(0xFF5B4DF5),
              subtitle: '$count فاتورة مسجلة',
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
    );
  }

  // ── Line Chart Section ──
  Widget _buildLineChartSection({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DF5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF5B4DF5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مسار المبيعات وصافي الأرباح اليومية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'متابعة لحظية ومقارنة حجم المبيعات بصافي الربح المحقق لآخر 14 يوماً',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          CustomLineChart(seriesList: _chartSeries, height: 220),
        ],
      ),
    );
  }

  // ── Tab Selector ──
  Widget _buildInsightTabSelector(bool isDark, Color borderColor) {
    final tabs = [
      {'label': '🏆 الأكثر ربحية من المنتجات', 'index': 0},
      {'label': '👥 العملاء الأكثر ربحية', 'index': 1},
      {'label': '🏢 مقارنة الفروع', 'index': 2},
      {'label': '📋 سجل الفواتير والتحميل', 'index': 3},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeInsightTab == t['index'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () =>
                  setState(() => _activeInsightTab = t['index'] as int),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5B4DF5)
                      : (isDark
                            ? const Color(0xFF1E2230)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5B4DF5) : borderColor,
                  ),
                ),
                child: Text(
                  t['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Active Tab View Content ──
  Widget _buildActiveTabContent({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required BoxConstraints constraints,
    required List<SalesInvoiceRow> filteredRows,
  }) {
    switch (_activeInsightTab) {
      case 0:
        return _buildTopProductsTab(
          isDark: isDark,
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 1:
        return _buildTopCustomersTab(
          isDark: isDark,
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 2:
        return _buildBranchesTab(
          isDark: isDark,
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 3:
      default:
        return _buildInvoicesTableTab(
          isDark: isDark,
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          constraints: constraints,
          filteredRows: filteredRows,
        );
    }
  }

  // ── Tab 0: Top Profitable Products ──
  Widget _buildTopProductsTab({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_productRows.isEmpty) {
      return _buildEmptyState(
        'لا توجد بيانات تفصيلية للمنتجات بعد',
        surface,
        borderColor,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتجات الأكثر تحقيقاً للأرباح',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مرتبة بحسب صافي المكسب الفعلي وهامش الربح المحقق',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_productRows.length} منتج نشط',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productRows.length > 8 ? 8 : _productRows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = _productRows[index];
              final isTop3 = index < 3;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isTop3
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (isDark
                                  ? const Color(0xFF232733)
                                  : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isTop3
                              ? const Color(0xFFF59E0B)
                              : textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.productName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الكمية المباعة: ${p.quantity.toStringAsFixed(0)} وحدة | المبيعات: ${_moneyFormat.format(p.totalSales)} ر.ي',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_moneyFormat.format(p.totalProfit)} ر.ي',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'هامش ${p.marginPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Top Profitable Customers ──
  Widget _buildTopCustomersTab({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_customerRows.isEmpty) {
      return _buildEmptyState(
        'لا توجد بيانات عملاء مسجلة بعد',
        surface,
        borderColor,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العملاء الأكثر تحقيقاً للأرباح',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'كبار صانعي الأرباح ونسبة التزامهم بالسداد النقدي',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B4DF5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_customerRows.length} عميل',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B4DF5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customerRows.length > 8 ? 8 : _customerRows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = _customerRows[index];
              final isGold = index == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isGold
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : (isDark
                                  ? const Color(0xFF232733)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isGold ? Icons.star_rounded : Icons.person_rounded,
                        color: isGold
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.customerName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              if (isGold) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'عميل ذهبي',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.invoicesCount} فاتورة | مشتريات: ${_moneyFormat.format(c.totalPurchases)} ر.ي',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_moneyFormat.format(c.totalProfit)} ر.ي',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.cashRatio.toStringAsFixed(0)}% نقدي',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: c.cashRatio >= 70
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Branches Comparison ──
  Widget _buildBranchesTab({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_branchRows.isEmpty) {
      return _buildEmptyState('لا توجد فروع مسجلة بعد', surface, borderColor);
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مقارنة أداء الفروع ومنافذ البيع',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'حجم المبيعات وصافي الأرباح والحصة السوقية لكل فرع',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _branchRows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final b = _branchRows[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.branchName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.invoicesCount} فاتورة | مبيعات: ${_moneyFormat.format(b.totalSales)} ر.ي',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_moneyFormat.format(b.totalProfit)} ر.ي أرباح',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الحصة: ${b.sharePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Detailed Invoices Table ──
  Widget _buildInvoicesTableTab({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required BoxConstraints constraints,
    required List<SalesInvoiceRow> filteredRows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & PDF Download
        LayoutBuilder(
          builder: (context, boxConstraints) {
            final isMobile = boxConstraints.maxWidth < 650;
            final searchBar = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'بحث برقم الفاتورة أو اسم العميل...',
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
            );

            final pdfButton = ElevatedButton.icon(
              onPressed: filteredRows.isEmpty ? null : _printReportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B4DF5),
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
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'عرض وتحميل التقرير PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [searchBar, const SizedBox(height: 10), pdfButton],
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
        const SizedBox(height: 16),

        // Data Table
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
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  ),
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: const Text(
                        'رقم الفاتورة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'اسم العميل',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'تاريخ الفاتورة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'نوع السداد',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'الإجمالي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                      onSort: _onSort,
                    ),
                  ],
                  rows: filteredRows.map((r) {
                    final isCash = r.paymentType.toLowerCase() == 'cash';
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B4DF5),
                            ),
                          ),
                        ),
                        DataCell(Text(r.customerName)),
                        DataCell(Text(_dateFormat.format(r.invoiceDate))),
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
                              borderRadius: BorderRadius.circular(6),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      ],
    );
  }

  Widget _buildEmptyState(String msg, Color surface, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
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

class _ProductAcc {
  double quantity = 0;
  double totalSales = 0;
  double totalProfit = 0;
}

class _CustomerAcc {
  int invoicesCount = 0;
  double totalPurchases = 0;
  double totalProfit = 0;
  double cashPurchases = 0;
}

class _BranchAcc {
  int invoicesCount = 0;
  double totalSales = 0;
  double totalProfit = 0;
}
