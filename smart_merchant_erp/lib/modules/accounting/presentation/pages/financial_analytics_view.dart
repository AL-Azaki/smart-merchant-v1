import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/financial_analytics_provider.dart';
import '../widgets/custom_line_chart.dart';
import 'cash_flow_analysis_view.dart';
import 'customer_debts_analysis_view.dart';
import 'expenses_analysis_view.dart';
import 'liquidity_analysis_view.dart';
import 'net_profit_analysis_view.dart';
import 'sales_analysis_view.dart';
import 'supplier_payables_analysis_view.dart';

class FinancialAnalyticsView extends ConsumerStatefulWidget {
  const FinancialAnalyticsView({super.key});

  @override
  ConsumerState<FinancialAnalyticsView> createState() =>
      _FinancialAnalyticsViewState();
}

class _FinancialAnalyticsViewState
    extends ConsumerState<FinancialAnalyticsView> {
  String _formatCurrency(double n) {
    final s = n
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$s ر.ي';
  }

  String _formatArabicMonth(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  String _formatPeriodRange(
    AnalyticsPeriod period,
    DateTimeRange? customRange,
  ) {
    final now = DateTime.now();
    switch (period) {
      case AnalyticsPeriod.today:
        return '${now.day} ${_formatArabicMonth(now.month)} ${now.year}';
      case AnalyticsPeriod.thisWeek:
        final start = now.subtract(Duration(days: now.weekday % 7));
        if (start.month == now.month) {
          return '${start.day} – ${now.day} ${_formatArabicMonth(now.month)} ${now.year}';
        } else {
          return '${start.day} ${_formatArabicMonth(start.month)} – ${now.day} ${_formatArabicMonth(now.month)} ${now.year}';
        }
      case AnalyticsPeriod.thisMonth:
        return '1 – ${now.day} ${_formatArabicMonth(now.month)} ${now.year}';
      case AnalyticsPeriod.thisYear:
        return '1 يناير – ${now.day} ${_formatArabicMonth(now.month)} ${now.year}';
      case AnalyticsPeriod.custom:
        if (customRange != null) {
          final s = customRange.start;
          final e = customRange.end;
          if (s.year == e.year && s.month == e.month) {
            return '${s.day} – ${e.day} ${_formatArabicMonth(e.month)} ${e.year}';
          } else if (s.year == e.year) {
            return '${s.day} ${_formatArabicMonth(s.month)} – ${e.day} ${_formatArabicMonth(e.month)} ${e.year}';
          } else {
            return '${s.day}/${s.month}/${s.year} – ${e.day}/${e.month}/${e.year}';
          }
        }
        return 'حدد نطاق مخصص';
    }
  }

  Future<void> _pickCustomDateRange(
    BuildContext context,
    DateTimeRange? currentRange,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange:
          currentRange ??
          DateTimeRange(start: DateTime(now.year, now.month), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF5B4DF5),
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      ref.read(analyticsCustomDateRangeProvider.notifier).state = picked;
      ref.read(analyticsPeriodProvider.notifier).state = AnalyticsPeriod.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF101115) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF22242D)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    final period = ref.watch(analyticsPeriodProvider);
    final customRange = ref.watch(analyticsCustomDateRangeProvider);
    final analyticsAsync = ref.watch(financialAnalyticsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financialAnalyticsProvider);
        },
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: isCompact ? 12 : 20,
          ),
          children: [
            // ── 1. Top Filter Card (Matching Exact Reference Design) ──
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 18,
                  vertical: isCompact ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.05,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Title on right, Chart Icon on left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التحليلات المالية',
                          style: TextStyle(
                            fontSize: isCompact ? 19 : 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Tooltip(
                          message: 'تحديث البيانات',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                ref.invalidate(financialAnalyticsProvider),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.insights_rounded,
                                color: const Color(0xFF5B4DF5),
                                size: isCompact ? 22 : 26,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 12 : 16),

                    // Middle Row: Capsule Filter with 5 Options
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF22232A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: AnalyticsPeriod.values.map((p) {
                          final isSelected = p == period;
                          return Expanded(
                            child: InkWell(
                              onTap: () async {
                                if (p == AnalyticsPeriod.custom) {
                                  await _pickCustomDateRange(
                                    context,
                                    customRange,
                                  );
                                } else {
                                  ref
                                          .read(
                                            analyticsPeriodProvider.notifier,
                                          )
                                          .state =
                                      p;
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeInOut,
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompact ? 8 : 10,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5B4DF5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF5B4DF5,
                                            ).withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  p.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 12 : 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600,
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
                    ),
                    SizedBox(height: isCompact ? 12 : 16),

                    // Bottom Row: Date Range Text on right, Calendar Icon on left
                    InkWell(
                      onTap: () => _pickCustomDateRange(context, customRange),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الفترة: ${_formatPeriodRange(period, customRange)}',
                              style: TextStyle(
                                fontSize: isCompact ? 13 : 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              color: const Color(0xFF5B4DF5),
                              size: isCompact ? 20 : 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: isCompact ? 16 : 24),

            // ── 2. Content Handling (Loading / Error / Data) ──
            analyticsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 3),
                      SizedBox(height: 16),
                      Text(
                        'جاري جلب وتحليل البيانات المالية الحية...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'حدث خطأ أثناء تحميل التحليلات المالية: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(financialAnalyticsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (data) => _buildAnalyticsBody(
                context,
                data: data,
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsBody(
    BuildContext context, {
    required FinancialAnalyticsData data,
    required bool isDark,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section 1: KPI Cards Grid (Dynamic Responsive Grid) ──
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int crossCount;
            final double mainAxisExtent;
            final double spacing = width < 640 ? 12 : 16;

            if (width >= 1150) {
              crossCount = 3;
              mainAxisExtent = 142;
            } else if (width >= 640) {
              crossCount = 2;
              mainAxisExtent = 140;
            } else {
              crossCount = 1;
              mainAxisExtent = 136;
            }

            final cards = [
              // 1. إجمالي المبيعات
              _KpiMetricCard(
                title: 'إجمالي المبيعات',
                value: _formatCurrency(data.totalSales),
                subtitle: 'صافي الفواتير في فترة ${data.period.label}',
                icon: Icons.shopping_bag_rounded,
                iconColor: const Color(0xFF3B82F6),
                badgeText: 'إيراد رئيسي',
                badgeColor: const Color(0xFF3B82F6),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SalesAnalysisView(),
                    ),
                  );
                },
              ),

              // 2. المصروفات التشغيلية (فئات ونفقات عامة دون مشتريات)
              _KpiMetricCard(
                title: 'المصروفات التشغيلية',
                value: _formatCurrency(data.totalExpenses),
                subtitle: 'كهرباء، إيجارات، طاقة ونفقات عامة',
                icon: Icons.pie_chart_rounded,
                iconColor: const Color(0xFFEF4444),
                badgeText: 'نفقات تشغيل',
                badgeColor: const Color(0xFFEF4444),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ExpensesAnalysisView(),
                    ),
                  );
                },
              ),

              // 3. صافي الأرباح
              _KpiMetricCard(
                title: 'صافي الأرباح المحققة',
                value: _formatCurrency(data.netProfit),
                subtitle:
                    'هامش الربح: ${data.profitMargin.toStringAsFixed(1)}%',
                icon: Icons.trending_up_rounded,
                iconColor: data.netProfit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                badgeText: data.netProfit >= 0 ? 'ربح صافي' : 'عجز مؤقت',
                badgeColor: data.netProfit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NetProfitAnalysisView(),
                    ),
                  );
                },
              ),

              // 3. السيولة والنقدية المتاحة
              _KpiMetricCard(
                title: 'السيولة النقدية والبنكية',
                value: _formatCurrency(data.cashAndBankBalance),
                subtitle:
                    'تغطية الالتزامات: ${data.liquidityCoverageRatio.toStringAsFixed(0)}%',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF06B6D4),
                badgeText: 'أرصدة فورية',
                badgeColor: const Color(0xFF06B6D4),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LiquidityAnalysisView(),
                    ),
                  );
                },
              ),

              // 4. مديونية العملاء (الذمم المدينة)
              _KpiMetricCard(
                title: 'مديونية العملاء (لنا)',
                value: _formatCurrency(data.customerReceivables),
                subtitle: '${data.activeCustomersWithDebt} عميل مدين حالياً',
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF8B5CF6),
                badgeText: 'ذمم مدينة',
                badgeColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomerDebtsAnalysisView(),
                    ),
                  );
                },
              ),

              // 5. التزامات الموردين (الذمم الدائنة)
              _KpiMetricCard(
                title: 'التزامات الموردين (علينا)',
                value: _formatCurrency(data.supplierPayables),
                subtitle: '${data.activeSuppliersWithDues} مورد دائن مستحق',
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFFF43F5E),
                badgeText: 'ذمم دائنة واجبة',
                badgeColor: const Color(0xFFF43F5E),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SupplierPayablesAnalysisView(),
                    ),
                  );
                },
              ),

              // 6. صافي التدفق النقدي
              _KpiMetricCard(
                title: 'صافي التدفق النقدي',
                value: _formatCurrency(data.netCashFlow),
                subtitle:
                    'مقبوضات: ${_formatCurrency(data.cashInflow)} | مدفوعات: ${_formatCurrency(data.cashOutflow)}',
                icon: Icons.swap_horiz_rounded,
                iconColor: data.netCashFlow >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                badgeText: data.netCashFlow >= 0 ? 'فائض نقدي' : 'تدفق سالب',
                badgeColor: data.netCashFlow >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                isDark: isDark,
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isCompact: isCompact,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CashFlowAnalysisView(),
                    ),
                  );
                },
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: mainAxisExtent,
              ),
              itemBuilder: (context, i) => cards[i],
            );
          },
        ),

        SizedBox(height: isCompact ? 18 : 28),

        // ── Section 2: Financial Ratio Strip (Fully Responsive) ──
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 20,
            vertical: isCompact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _FinancialRatioItem(
                        label: 'نسبة الأمان والسيولة',
                        value:
                            '${data.liquidityCoverageRatio.clamp(0, 999).toStringAsFixed(1)}%',
                        description: 'النقدية المتوفرة مقارنة بالالتزامات',
                        icon: Icons.shield_outlined,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                      child: VerticalDivider(width: 28),
                    ),
                    Expanded(
                      child: _FinancialRatioItem(
                        label: 'هامش الربحية الصافي',
                        value: '${data.profitMargin.toStringAsFixed(1)}%',
                        description: 'نسبة الأرباح من المبيعات الكلية',
                        icon: Icons.pie_chart_outline_rounded,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                      child: VerticalDivider(width: 28),
                    ),
                    Expanded(
                      child: _FinancialRatioItem(
                        label: 'توازن الذمم (عملاء / موردين)',
                        value:
                            '${data.receivablesToPayablesRatio.clamp(0, 999).toStringAsFixed(1)}%',
                        description: 'مستحقات السوق مقابل التزامات الموردين',
                        icon: Icons.compare_arrows_rounded,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _FinancialRatioItem(
                      label: 'نسبة الأمان والسيولة',
                      value:
                          '${data.liquidityCoverageRatio.clamp(0, 999).toStringAsFixed(1)}%',
                      description: 'النقدية المتوفرة مقارنة بالالتزامات',
                      icon: Icons.shield_outlined,
                      color: const Color(0xFF10B981),
                      isCompact: isCompact,
                    ),
                    const Divider(height: 20),
                    _FinancialRatioItem(
                      label: 'هامش الربحية الصافي',
                      value: '${data.profitMargin.toStringAsFixed(1)}%',
                      description: 'نسبة الأرباح من المبيعات الكلية',
                      icon: Icons.pie_chart_outline_rounded,
                      color: const Color(0xFF6366F1),
                      isCompact: isCompact,
                    ),
                    const Divider(height: 20),
                    _FinancialRatioItem(
                      label: 'توازن الذمم (عملاء / موردين)',
                      value:
                          '${data.receivablesToPayablesRatio.clamp(0, 999).toStringAsFixed(1)}%',
                      description: 'مستحقات السوق مقابل التزامات الموردين',
                      icon: Icons.compare_arrows_rounded,
                      color: const Color(0xFF06B6D4),
                      isCompact: isCompact,
                    ),
                  ],
                );
              }
            },
          ),
        ),

        SizedBox(height: isCompact ? 18 : 28),

        // ── Section 3: Line Charts (Desktop 2x2 Grid, Mobile 1-Column) ──
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1050;
            final chartHeight = isCompact ? 195.0 : 230.0;

            final chart1 = _ChartContainer(
              title: 'مخطط مسار التدفق النقدي (Cash Flow Trend)',
              subtitle:
                  'المقبوضات النقدية الداخلة مقابل المدفوعات والمصروفات الخارجة عبر الزمن',
              icon: Icons.waterfall_chart_rounded,
              iconColor: const Color(0xFF10B981),
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isCompact: isCompact,
              child: CustomLineChart(
                seriesList: data.cashFlowSeries,
                height: chartHeight,
              ),
            );

            final chart2 = _ChartContainer(
              title: 'مخطط المبيعات مقابل التكاليف والمصروفات',
              subtitle:
                  'مقارنة حجم المبيعات بتكلفة المشتريات والمصروفات التشغيلية المباشرة',
              icon: Icons.show_chart_rounded,
              iconColor: const Color(0xFF3B82F6),
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isCompact: isCompact,
              child: CustomLineChart(
                seriesList: data.revenueCostSeries,
                height: chartHeight,
              ),
            );

            final chart3 = _ChartContainer(
              title: 'منحنى تطور صافي الربح (Net Profit Trajectory)',
              subtitle:
                  'مسار الأرباح المحققة بعد خصم جميع تكاليف البضائع والمصروفات',
              icon: Icons.auto_graph_rounded,
              iconColor: const Color(0xFF8B5CF6),
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isCompact: isCompact,
              child: CustomLineChart(
                seriesList: data.profitSeries,
                height: chartHeight,
              ),
            );

            final chart4 = _ChartContainer(
              title:
                  'مخطط توازن المديونية والالتزامات (Receivables vs Payables)',
              subtitle:
                  'تتبع مستحقاتك لدى العملاء في السوق مقارنة بالتزاماتك الواجبة للموردين',
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xFF06B6D4),
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isCompact: isCompact,
              child: CustomLineChart(
                seriesList: data.debtBalanceSeries,
                height: chartHeight,
              ),
            );

            if (isDesktop) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: chart1),
                      const SizedBox(width: 20),
                      Expanded(child: chart2),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: chart3),
                      const SizedBox(width: 20),
                      Expanded(child: chart4),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  chart1,
                  const SizedBox(height: 18),
                  chart2,
                  const SizedBox(height: 18),
                  chart3,
                  const SizedBox(height: 18),
                  chart4,
                ],
              );
            }
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Supporting UI Components ──────────────────────────────────────────────────

class _KpiMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String badgeText;
  final Color badgeColor;
  final bool isDark;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isCompact;
  final VoidCallback? onTap;

  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
    required this.badgeColor,
    required this.isDark,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 13 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6 : 8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: isCompact ? 18 : 20,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 7 : 8,
                            vertical: isCompact ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: isCompact ? 12 : 13,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 10.5 : 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 10.5,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialRatioItem extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCompact;

  const _FinancialRatioItem({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: isCompact ? 18 : 22),
        ),
        SizedBox(width: isCompact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Widget child;
  final bool isCompact;

  const _ChartContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.child,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 18 : 20),
              ),
              SizedBox(width: isCompact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 13.5 : 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isCompact ? 10.5 : 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 18),
          const Divider(height: 1),
          SizedBox(height: isCompact ? 12 : 18),
          child,
        ],
      ),
    );
  }
}
