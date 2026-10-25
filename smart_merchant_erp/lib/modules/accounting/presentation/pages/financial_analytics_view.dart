import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/financial_analytics_provider.dart';
import '../widgets/custom_line_chart.dart';
import 'customer_debts_analysis_view.dart';
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

    final period = ref.watch(analyticsPeriodProvider);
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
          padding: const EdgeInsets.all(20),
          children: [
            // ── 1. Top Controls Bar: Periods & Refresh ──
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة التحليلات والمؤشرات المالية',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ملخص تفصيلي للمبيعات، الأرباح، حركة السيولة والتزامات ومديونيات العمل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'تحديث البيانات',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF6366F1),
                        ),
                        onPressed: () =>
                            ref.invalidate(financialAnalyticsProvider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Period Selection Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AnalyticsPeriod.values.map((p) {
                        final isSelected = p == period;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            onTap: () {
                              ref.read(analyticsPeriodProvider.notifier).state =
                                  p;
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6366F1)
                                      : borderColor,
                                ),
                              ),
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
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
                ],
              ),
            ),

            const SizedBox(height: 24),

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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section 1: KPI Cards Grid ──
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossCount = width > 1100 ? 3 : (width > 680 ? 2 : 1);
            final aspect = width > 1100 ? 1.8 : (width > 680 ? 1.6 : 2.2);

            return GridView.count(
              crossAxisCount: crossCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspect,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
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
                ),

                // 2. صافي الأرباح
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
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
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // ── Section 2: Financial Ratio Strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _FinancialRatioItem(
                    label: 'نسبة الأمان والسيولة',
                    value:
                        '${data.liquidityCoverageRatio.clamp(0, 999).toStringAsFixed(1)}%',
                    description: 'النقدية المتوفرة مقارنة بالالتزامات',
                    icon: Icons.shield_outlined,
                    color: const Color(0xFF10B981),
                  ),
                  if (isWide)
                    const SizedBox(height: 40, child: VerticalDivider())
                  else
                    const Divider(height: 24),
                  _FinancialRatioItem(
                    label: 'هامش الربحية الصافي',
                    value: '${data.profitMargin.toStringAsFixed(1)}%',
                    description: 'نسبة الأرباح من المبيعات الكلية',
                    icon: Icons.pie_chart_outline_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  if (isWide)
                    const SizedBox(height: 40, child: VerticalDivider())
                  else
                    const Divider(height: 24),
                  _FinancialRatioItem(
                    label: 'توازن الذمم (عملاء / موردين)',
                    value:
                        '${data.receivablesToPayablesRatio.clamp(0, 999).toStringAsFixed(1)}%',
                    description: 'مستحقات السوق مقابل التزامات الموردين',
                    icon: Icons.compare_arrows_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 28),

        // ── Section 3: Line Charts (المخططات الخطية) ──

        // Chart 1: Cash Flow Line Chart (التدفق النقدي)
        _ChartContainer(
          title: 'مخطط مسار التدفق النقدي (Cash Flow Trend Line)',
          subtitle:
              'المقبوضات النقدية الداخلة مقابل المدفوعات والمصروفات الخارجة عبر الزمن',
          icon: Icons.waterfall_chart_rounded,
          iconColor: const Color(0xFF10B981),
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          child: CustomLineChart(
            seriesList: data.cashFlowSeries,
            height: 240,
            valueSuffix: 'ر.ي',
          ),
        ),

        const SizedBox(height: 20),

        // Chart 2: Revenue vs Costs Line Chart (المبيعات مقابل التكاليف)
        _ChartContainer(
          title: 'مخطط المبيعات مقابل التكاليف والمصروفات',
          subtitle:
              'مقارنة حجم المبيعات بتكلفة المشتريات والمصروفات التشغيلية المباشرة',
          icon: Icons.show_chart_rounded,
          iconColor: const Color(0xFF3B82F6),
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          child: CustomLineChart(
            seriesList: data.revenueCostSeries,
            height: 240,
            valueSuffix: 'ر.ي',
          ),
        ),

        const SizedBox(height: 20),

        // Chart 3: Net Profit Trajectory Line Chart (مسار صافي الربح)
        _ChartContainer(
          title: 'منحنى تطور صافي الربح (Net Profit Trajectory)',
          subtitle:
              'مسار الأرباح المحققة بعد خصم جميع تكاليف البضائع والمصروفات',
          icon: Icons.auto_graph_rounded,
          iconColor: const Color(0xFF8B5CF6),
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          child: CustomLineChart(
            seriesList: data.profitSeries,
            height: 240,
            valueSuffix: 'ر.ي',
          ),
        ),

        const SizedBox(height: 20),

        // Chart 4: Receivables vs Payables Trend (توازن المديونية والالتزامات)
        _ChartContainer(
          title: 'مخطط توازن المديونية والالتزامات (Receivables vs Payables)',
          subtitle:
              'تتبع مستحقاتك لدى العملاء في السوق مقارنة بالتزاماتك الواجبة للموردين',
          icon: Icons.account_balance_rounded,
          iconColor: const Color(0xFF06B6D4),
          surface: surface,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          child: CustomLineChart(
            seriesList: data.debtBalanceSeries,
            height: 240,
            valueSuffix: 'ر.ي',
          ),
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          fontSize: 10.5,
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

  const _FinancialRatioItem({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
