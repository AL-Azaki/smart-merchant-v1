import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/cash_flow_service.dart';
import '../providers/accounting_provider.dart';
import 'financial_report_pdf_service.dart';

/// Interactive, real-time Cash Flow Statement Tab (قائمة التدفق المالي / النقدي).
class CashFlowTab extends ConsumerStatefulWidget {
  const CashFlowTab({super.key});

  @override
  ConsumerState<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends ConsumerState<CashFlowTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final reportAsync = ref.watch(
      cashFlowReportProvider((startDate: _startDate, endDate: _endDate)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter & Action Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.waves_rounded, color: Color(0xFF047857), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قائمة التدفق المالي والسيولة النقدية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'تتبع دقيق لحركة المقبوضات والمدفوعات ومصادر النقدية التشغيلية والاستثمارية',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Date range picker buttons
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _startDate == null ? 'من البداية' : _dateFormat.format(_startDate!),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _endDate == null ? 'إلى اليوم' : _dateFormat.format(_endDate!),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                  if (_startDate != null || _endDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'إعادة ضبط التواريخ',
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                    ),
                  ],

                  const SizedBox(width: 12),

                  // Print & Export Buttons
                  reportAsync.maybeWhen(
                    data: (report) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('طباعة PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => FinancialReportPdfService.printCashFlow(
                            context: context,
                            report: report,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          tooltip: 'مشاركة ملف PDF',
                          onPressed: () => FinancialReportPdfService.shareCashFlow(
                            context: context,
                            report: report,
                          ),
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('خطأ في تحميل قائمة التدفق المالي: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (report) {
                  return ListView(
                    children: [
                      // Net Change Banner
                      _buildNetChangeBanner(report, isDark),
                      const SizedBox(height: 16),

                      // KPI Cards
                      _buildKpiCards(report, surface, borderColor, textPrimary, textSecondary),
                      const SizedBox(height: 16),

                      // Activities Sections
                      _buildActivityCard(
                        title: '1. الأنشطة التشغيلية (Operating Activities)',
                        subtitle: 'مقبوضات المبيعات والعملاء، مدفوعات الموردين والمصاريف التشغيلية',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF1E3A8A),
                        activities: report.operatingActivities,
                        netAmount: report.netOperatingCashFlow,
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),

                      _buildActivityCard(
                        title: '2. الأنشطة الاستثمارية (Investing Activities)',
                        subtitle: 'حركات شراء وبيع الأصول الثابتة والاستثمارات الرأسمالية',
                        icon: Icons.precision_manufacturing_rounded,
                        color: const Color(0xFF8B5CF6),
                        activities: report.investingActivities,
                        netAmount: report.netInvestingCashFlow,
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),

                      _buildActivityCard(
                        title: '3. الأنشطة التمويلية (Financing Activities)',
                        subtitle: 'رأس المال، المسحوبات الشخصية، القروض والتمويلات',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFFD97706),
                        activities: report.financingActivities,
                        netAmount: report.netFinancingCashFlow,
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),

                      // Detailed Cash and Bank Accounts Breakdown
                      _buildCashAccountsTable(
                        report.cashAccounts,
                        surface,
                        borderColor,
                        textPrimary,
                        textSecondary,
                        isDark,
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetChangeBanner(CashFlowReport report, bool isDark) {
    final isPositive = report.netChangeInCash >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive
                    ? 'صافي التدفق النقدي إيجابي — زيادة في السيولة النقدية خلال الفترة المحددة'
                    : 'تنبيه: صافي التدفق النقدي سلبي — انخفاض في السيولة النقدية خلال الفترة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isPositive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  'رصيد النقدية أول المدة: ${_moneyFormat.format(report.openingCashBalance)} YER  →  رصيد آخر المدة: ${_moneyFormat.format(report.closingCashBalance)} YER',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isPositive ? "+" : ""}${_moneyFormat.format(report.netChangeInCash)} YER',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(
    CashFlowReport report,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (3 * 12)) / 4;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'رصيد أول المدة',
              subtitle: 'السيولة في بداية الفترة',
              amount: report.openingCashBalance,
              color: const Color(0xFF3B82F6),
              icon: Icons.account_balance_wallet_outlined,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildKpiCard(
              title: 'صافي التدفق التشغيلي',
              subtitle: 'المبيعات ناقص المصاريف والموردين',
              amount: report.netOperatingCashFlow,
              color: report.netOperatingCashFlow >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              icon: Icons.storefront_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildKpiCard(
              title: 'الأنشطة الاستثمارية والتمويلية',
              subtitle: 'الأصول الثابتة ورأس المال',
              amount: report.netInvestingCashFlow + report.netFinancingCashFlow,
              color: const Color(0xFF8B5CF6),
              icon: Icons.hub_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildKpiCard(
              title: 'رصيد آخر المدة (النهائي)',
              subtitle: 'إجمالي السيولة المتاحة فعلياً',
              amount: report.closingCashBalance,
              color: const Color(0xFF047857),
              icon: Icons.savings_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isHighlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required double amount,
    required Color color,
    required IconData icon,
    required double width,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool isHighlight = false,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? color.withOpacity(0.08) : surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHighlight ? color : borderColor, width: isHighlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_moneyFormat.format(amount)} YER',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlight ? color : textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<CashFlowActivityItem> activities,
    required double netAmount,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الصافي: ${_moneyFormat.format(netAmount)} YER',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('لا توجد حركات مسجلة تحت هذا النشاط في الفترة المحددة', style: TextStyle(color: textSecondary, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
              itemBuilder: (context, index) {
                final item = activities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: item.isInflow
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFEF4444).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          size: 14,
                          color: item.isInflow ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${item.isInflow ? "+" : "-"}${_moneyFormat.format(item.amount)} YER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: item.isInflow ? const Color(0xFF047857) : const Color(0xFFDC2626),
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

  Widget _buildCashAccountsTable(
    List<CashFlowAccountItem> accounts,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تفاصيل أرصدة الصناديق والبنوك والمحافظ النقدية (مطابقة السيولة)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                  ),
                ),
                Text(
                  'عدد الحسابات: ${accounts.length}',
                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Table Content
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('لم يتم العثور على حسابات نقدية أو بنكية مسجلة في شجرة الحسابات', style: TextStyle(color: textSecondary)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 46,
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                columns: const [
                  DataColumn(label: Text('كود الحساب')),
                  DataColumn(label: Text('اسم الحساب / الصندوق')),
                  DataColumn(label: Text('التصنيف')),
                  DataColumn(numeric: true, label: Text('رصيد أول المدة')),
                  DataColumn(numeric: true, label: Text('إجمالي المقبوضات (+)')),
                  DataColumn(numeric: true, label: Text('إجمالي المدفوعات (-)')),
                  DataColumn(numeric: true, label: Text('رصيد آخر المدة')),
                ],
                rows: accounts.map((acc) {
                  return DataRow(
                    cells: [
                      DataCell(Text(acc.accountCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                      DataCell(Text(acc.accountName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            acc.category,
                            style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      DataCell(Text(_moneyFormat.format(acc.openingBalance))),
                      DataCell(
                        Text(
                          _moneyFormat.format(acc.totalInflow),
                          style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          _moneyFormat.format(acc.totalOutflow),
                          style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          _moneyFormat.format(acc.closingBalance),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
