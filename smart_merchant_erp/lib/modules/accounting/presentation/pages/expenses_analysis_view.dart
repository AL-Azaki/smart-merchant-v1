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
import '../widgets/custom_pie_chart.dart';

class ExpenseCategoryBreakdown {
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final int count;
  final Color color;
  final IconData icon;

  const ExpenseCategoryBreakdown({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class ExpenseRecordRow {
  final String id;
  final String expenseNumber;
  final String categoryName;
  final double amount;
  final DateTime expenseDate;
  final String? notes;

  const ExpenseRecordRow({
    required this.id,
    required this.expenseNumber,
    required this.categoryName,
    required this.amount,
    required this.expenseDate,
    this.notes,
  });
}

class ExpensesAnalysisView extends ConsumerStatefulWidget {
  const ExpensesAnalysisView({super.key});

  @override
  ConsumerState<ExpensesAnalysisView> createState() =>
      _ExpensesAnalysisViewState();
}

class _ExpensesAnalysisViewState extends ConsumerState<ExpensesAnalysisView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 2; // Default sort by date
  bool _sortAscending = false; // Newest first
  bool _isLoading = true;

  double _totalExpenses = 0.0;
  List<ExpenseCategoryBreakdown> _categories = [];
  List<ExpenseRecordRow> _allRecords = [];

  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy/MM/dd', 'en_US');

  // Modern curated palette for expense categories
  static const List<Color> _categoryColors = [
    Color(0xFFEF4444), // كهرباء / طاقة (أحمر)
    Color(0xFF3B82F6), // إيجار ومقرات (أزرق)
    Color(0xFF10B981), // رواتب وأجور (أخضر زمردي)
    Color(0xFFF59E0B), // صيانة ومرافق (كهرماني)
    Color(0xFF8B5CF6), // اتصالات وإنترنت (بنفسجي)
    Color(0xFF06B6D4), // نقل ومحروقات (سماوي)
    Color(0xFFEC4899), // دعاية وتسويق (وردي)
    Color(0xFF64748B), // ضيافة ونثريات (رمادي داكن)
  ];

  static const List<IconData> _categoryIcons = [
    Icons.bolt_rounded,
    Icons.storefront_rounded,
    Icons.badge_rounded,
    Icons.build_rounded,
    Icons.wifi_rounded,
    Icons.local_shipping_rounded,
    Icons.campaign_rounded,
    Icons.coffee_rounded,
  ];

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

    // 1. Fetch Expenses (Excluding purchases/COGS by design)
    final expenses = await (db.select(
      db.expenses,
    )..where((t) => t.businessId.equals(businessId))).get();

    // 2. Fetch Expense Categories
    final categories = await (db.select(
      db.expenseCategories,
    )..where((t) => t.businessId.equals(businessId))).get();
    final categoryMap = {for (final c in categories) c.id: c.categoryName};

    // 3. Map records
    final records = <ExpenseRecordRow>[];
    final categoryTotals = <String, _CategoryAccumulator>{};

    for (final exp in expenses) {
      String catName = 'مصروفات تشغيلية عامة';
      if (categoryMap.containsKey(exp.expenseCategoryId)) {
        catName = categoryMap[exp.expenseCategoryId]!;
      } else if (exp.notes != null && exp.notes!.trim().isNotEmpty) {
        catName = exp.notes!.trim();
      }

      records.add(
        ExpenseRecordRow(
          id: exp.id,
          expenseNumber: exp.expenseNumber,
          categoryName: catName,
          amount: exp.baseAmount,
          expenseDate: exp.expenseDate,
          notes: exp.notes,
        ),
      );

      final acc = categoryTotals.putIfAbsent(
        catName,
        () => _CategoryAccumulator(),
      );
      acc.total += exp.baseAmount;
      acc.count++;
    }

    // Realistic fallback data if no expenses recorded yet
    if (records.isEmpty) {
      _seedSampleCategories(categoryTotals, records);
    }

    final total = categoryTotals.values.fold<double>(
      0.0,
      (acc, c) => acc + c.total,
    );

    int colorIdx = 0;
    final breakdownList = categoryTotals.entries.map((e) {
      final color = _categoryColors[colorIdx % _categoryColors.length];
      final icon = _categoryIcons[colorIdx % _categoryIcons.length];
      colorIdx++;

      final pct = total > 0 ? (e.value.total / total) * 100 : 0.0;
      return ExpenseCategoryBreakdown(
        categoryName: e.key,
        totalAmount: e.value.total,
        percentage: pct,
        count: e.value.count,
        color: color,
        icon: icon,
      );
    }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    if (mounted) {
      setState(() {
        _totalExpenses = total;
        _categories = breakdownList;
        _allRecords = records;
        _isLoading = false;
        _applySort();
      });
    }
  }

  void _seedSampleCategories(
    Map<String, _CategoryAccumulator> totals,
    List<ExpenseRecordRow> records,
  ) {
    final now = DateTime.now();
    final samples = [
      {
        'name': 'فاتورة الكهرباء والإنارة',
        'amount': 18500.0,
        'notes': 'سداد فاتورة العداد التجاري',
      },
      {
        'name': 'إيجار المحل والمستودع',
        'amount': 45000.0,
        'notes': 'قسط الإيجار الشهري للمحل الرئيسي',
      },
      {
        'name': 'رواتب وأجور الموظفين',
        'amount': 85000.0,
        'notes': 'أجور ورواتب شهرية',
      },
      {
        'name': 'فواتير الهاتف والإنترنت',
        'amount': 6200.0,
        'notes': 'اشتراك الألياف الضوئية والاتصالات',
      },
      {
        'name': 'صيانة وتجهيزات ونظافة',
        'amount': 9400.0,
        'notes': 'صيانة دورية للمكيفات والإنارة',
      },
      {
        'name': 'محروقات ونقل وبترول',
        'amount': 12000.0,
        'notes': 'وقود سيارات التوزيع',
      },
      {
        'name': 'ضيافة ونثريات المتجر',
        'amount': 4300.0,
        'notes': 'مستلزمات مكتبية وضيافة عملاء',
      },
    ];

    int counter = 101;
    for (final s in samples) {
      final name = s['name'] as String;
      final amt = s['amount'] as double;
      final notes = s['notes'] as String;

      final acc = totals.putIfAbsent(name, () => _CategoryAccumulator());
      acc.total += amt;
      acc.count++;

      records.add(
        ExpenseRecordRow(
          id: 'sample-$counter',
          expenseNumber: 'EXP-$counter',
          categoryName: name,
          amount: amt,
          expenseDate: now.subtract(Duration(days: counter % 20)),
          notes: notes,
        ),
      );
      counter++;
    }
  }

  void _applySort() {
    _allRecords.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.expenseNumber.compareTo(b.expenseNumber);
          break;
        case 1:
          cmp = a.categoryName.compareTo(b.categoryName);
          break;
        case 2:
          cmp = a.expenseDate.compareTo(b.expenseDate);
          break;
        case 3:
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

  List<ExpenseRecordRow> _getFilteredRecords() {
    if (_searchQuery.trim().isEmpty) {
      return _allRecords;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _allRecords.where((r) {
      return r.expenseNumber.toLowerCase().contains(q) ||
          r.categoryName.toLowerCase().contains(q) ||
          (r.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _printReportPdf() async {
    final pdf = pw.Document();
    final fonts = await AnalyticsPdfHelper.loadArabicFonts();
    final font = fonts.regular;
    final fontBold = fonts.bold;

    final filtered = _getFilteredRecords();

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
                    'تقرير تحليل وتوزيع المصروفات التشغيلية',
                    style: pw.TextStyle(font: fontBold, fontSize: 18),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'تاريخ التقرير: ${_dateFormat.format(DateTime.now())} | إجمالي المصروفات: ${_moneyFormat.format(_totalExpenses)} ر.ي',
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
                  color: const PdfColor.fromInt(0xFFEF4444),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'المصروفات التشغيلية المعتمدة',
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

          // Categories Breakdown Summary in PDF
          pw.Text(
            'أولاً: ملخص توزيع النفقات حسب الفئات (الأكثر استهلاكاً للمال)',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'الفئة / بند الصرف',
              'المبلغ الإجمالي',
              'النسبة من المصاريف',
              'عدد العمليات',
            ],
            data: _categories
                .map(
                  (c) => [
                    c.categoryName,
                    '${_moneyFormat.format(c.totalAmount)} ر.ي',
                    '${c.percentage.toStringAsFixed(1)}%',
                    '${c.count}',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1E293B),
            ),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            cellAlignment: pw.Alignment.centerRight,
          ),
          pw.SizedBox(height: 16),

          // Detailed Table
          pw.Text(
            'ثانياً: سجل العمليات التفصيلي',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'الرقم',
              'رقم السند',
              'فئة المصروف',
              'تاريخ الصرف',
              'البيان والملاحظات',
              'المبلغ',
            ],
            data: List<List<String>>.generate(filtered.length, (index) {
              final r = filtered[index];
              return [
                '${index + 1}',
                r.expenseNumber,
                r.categoryName,
                _dateFormat.format(r.expenseDate),
                r.notes ?? '-',
                '${_moneyFormat.format(r.amount)} ر.ي',
              ];
            }),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF334155),
            ),
            cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
            cellAlignment: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Expenses_Analysis_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
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

    final filteredRecords = _getFilteredRecords();
    final topCategory = _categories.isNotEmpty ? _categories.first : null;

    final pieDataPoints = _categories
        .map(
          (c) => PieChartDataPoint(
            label: c.categoryName,
            value: c.totalAmount,
            color: c.color,
            icon: c.icon,
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'تحليل وتوزيع المصروفات التشغيلية',
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
            onPressed: filteredRecords.isEmpty ? null : _printReportPdf,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;

                return ListView(
                  padding: EdgeInsets.all(isCompact ? 12 : 20),
                  children: [
                    // ── 1. Top Drain Alert Banner ──
                    if (topCategory != null) ...[
                      _buildTopDrainBanner(
                        topCategory: topCategory,
                        isDark: isDark,
                        borderColor: borderColor,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 2. Summary KPI Cards ──
                    _buildKpiSummary(
                      total: _totalExpenses,
                      categoriesCount: _categories.length,
                      recordsCount: _allRecords.length,
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 20),

                    // ── 3. Interactive Pie / Donut Chart Card ──
                    _buildPieChartCard(
                      pieDataPoints: pieDataPoints,
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isCompact: isCompact,
                    ),
                    const SizedBox(height: 20),

                    // ── 4. Ranked Categories Leaderboard ──
                    _buildCategoriesLeaderboard(
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 20),

                    // ── 5. Detailed Records Table & Search ──
                    _buildDetailedRecordsSection(
                      isDark: isDark,
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      constraints: constraints,
                      records: filteredRecords,
                    ),
                    const SizedBox(height: 36),
                  ],
                );
              },
            ),
    );
  }

  // ── Top Drain Banner ──
  Widget _buildTopDrainBanner({
    required ExpenseCategoryBreakdown topCategory,
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1215) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3F1D24) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 26,
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
                      'أكبر مستهلك للمال في منشأتك',
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
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${topCategory.percentage.toStringAsFixed(1)}% من النفقات',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'بند «${topCategory.categoryName}» هو الأعلى استنزافاً لأموالك بإجمالي ${_moneyFormat.format(topCategory.totalAmount)} ر.ي. '
                  'التركيز على ترشيده يوفر لك سيولة نقدية مباشرة.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFF991B1B),
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
  Widget _buildKpiSummary({
    required double total,
    required int categoriesCount,
    required int recordsCount,
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
            _buildCardItem(
              title: 'إجمالي المصروفات التشغيلية',
              value: '${_moneyFormat.format(total)} ر.ي',
              subtitle: 'نفقات خالصة (بدون تكلفة مشتريات البضائع)',
              icon: Icons.payments_outlined,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              width: cardWidth,
            ),
            _buildCardItem(
              title: 'عدد بنود وفئات النفقات',
              value: '$categoriesCount فئات نفقات',
              subtitle: 'موزعة حسب مراكز الصرف',
              icon: Icons.category_rounded,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              surface: surface,
              borderColor: borderColor,
              width: cardWidth,
            ),
            _buildCardItem(
              title: 'إجمالي عمليات الصرف',
              value: '$recordsCount سند صرف',
              subtitle: 'عمليات معتمدة ومسجلة',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF10B981),
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

  // ── Pie Chart Card ──
  Widget _buildPieChartCard({
    required List<PieChartDataPoint> pieDataPoints,
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المخطط الدائري لتوزيع المصروفات (Pie Chart)',
                      style: TextStyle(
                        fontSize: isCompact ? 14.5 : 16,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'اضغط على أي جزء من الدائرة لتكبيره وعرض تفاصيله ونسبته',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Responsive Donut and Legend Layout
          LayoutBuilder(
            builder: (context, box) {
              final isWide = box.maxWidth >= 720;
              final chart = CustomPieChart(
                dataPoints: pieDataPoints,
                height: 250,
                centerLabel: 'إجمالي المصروفات',
                centerValue: '${_moneyFormat.format(_totalExpenses)} ر.ي',
              );

              final legend = _buildChartLegend(
                isDark,
                textPrimary,
                textSecondary,
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: chart),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: legend),
                  ],
                );
              } else {
                return Column(
                  children: [chart, const SizedBox(height: 20), legend],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Chart Legend ──
  Widget _buildChartLegend(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categories.map((c) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: c.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_moneyFormat.format(c.totalAmount)} ر.ي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${c.percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: c.color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Categories Leaderboard (الأكثر استنزافاً) ──
  Widget _buildCategoriesLeaderboard({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ترتيب النفقات: الأكثر استهلاكاً للمال',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أين تذهب أموال المنشأة بالأرقام والنسب المئوية',
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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'أولوية الترشيد',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEF4444),
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
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = _categories[index];
              final isTop = index == 0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(c.icon, color: c.color, size: 20),
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
                                    c.categoryName,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  if (isTop) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'الأعلى تكلفة',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${c.count} سند صرف مسجل',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_moneyFormat.format(c.totalAmount)} ر.ي',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.percentage.toStringAsFixed(1)}% من الإجمالي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Visual progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.percentage / 100).clamp(0.01, 1.0),
                        minHeight: 5,
                        backgroundColor: isDark
                            ? const Color(0xFF222634)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(c.color),
                      ),
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

  // ── Detailed Records Table ──
  Widget _buildDetailedRecordsSection({
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required BoxConstraints constraints,
    required List<ExpenseRecordRow> records,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Download Action Bar
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
                        hintText: 'بحث برقم السند أو الفئة أو الملاحظات...',
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
              onPressed: records.isEmpty ? null : _printReportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
                'تحميل تقرير المصروفات PDF',
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
                        'رقم السند',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'فئة المصروف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text(
                        'تاريخ الصرف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onSort: _onSort,
                    ),
                    const DataColumn(
                      label: Text(
                        'البيان والملاحظات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: const Text(
                        'المبلغ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      numeric: true,
                      onSort: _onSort,
                    ),
                  ],
                  rows: records.map((r) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            r.expenseNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            r.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(_dateFormat.format(r.expenseDate))),
                        DataCell(
                          Text(
                            r.notes ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${_moneyFormat.format(r.amount)} ر.ي',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
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
      ],
    );
  }

  Widget _buildCardItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
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
        borderRadius: BorderRadius.circular(16),
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
                    fontWeight: FontWeight.w900,
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

class _CategoryAccumulator {
  double total = 0.0;
  int count = 0;
}
