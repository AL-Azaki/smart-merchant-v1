import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/balance_sheet_service.dart';
import '../providers/accounting_provider.dart';
import 'financial_report_pdf_service.dart';

/// Interactive, real-time Balance Sheet Tab (الميزانية العمومية / ميزان العمومية).
class BalanceSheetTab extends ConsumerStatefulWidget {
  const BalanceSheetTab({super.key});

  @override
  ConsumerState<BalanceSheetTab> createState() => _BalanceSheetTabState();
}

class _BalanceSheetTabState extends ConsumerState<BalanceSheetTab> {
  DateTime _asOfDate = DateTime.now();
  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final reportAsync = ref.watch(balanceSheetReportProvider(_asOfDate));

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
                      color: const Color(0xFF1E3A8A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF1E3A8A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الميزانية العمومية (ميزان العمومية)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'تقرير المركز المالي: الأصول = الخصوم والالتزامات + حقوق الملكية',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Date Picker
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      'كما في: ${_dateFormat.format(_asOfDate)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _asOfDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _asOfDate = picked);
                      }
                    },
                  ),
                  const SizedBox(width: 10),

                  // Print & Export Buttons
                  reportAsync.maybeWhen(
                    data: (report) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('طباعة PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => FinancialReportPdfService.printBalanceSheet(
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
                          onPressed: () => FinancialReportPdfService.shareBalanceSheet(
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
                  child: Text('خطأ في تحميل الميزانية العمومية: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (report) {
                  return ListView(
                    children: [
                      // Golden Balanced Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: report.isBalanced
                              ? const Color(0xFF10B981).withOpacity(0.12)
                              : const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: report.isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              report.isBalanced ? Icons.verified_rounded : Icons.warning_amber_rounded,
                              color: report.isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                report.isBalanced
                                    ? 'الميزانية العمومية متوازنة محاسبياً بدقة — إجمالي الأصول يطابق تماماً مجموع الخصوم وحقوق الملكية.'
                                    : 'تنبيه: عدم توازن في الميزانية! الفارق: ${_moneyFormat.format((report.totalAssets - report.totalLiabilitiesAndEquity).abs())} YER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: report.isBalanced ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            Text(
                              'إجمالي الأصول: ${_moneyFormat.format(report.totalAssets)}  =  الخصوم والملكية: ${_moneyFormat.format(report.totalLiabilitiesAndEquity)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // KPI Cards
                      Row(
                        children: [
                          _buildKpiCard('إجمالي الأصول', report.totalAssets, const Color(0xFF1E3A8A), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('الأصول المتداولة', report.totalCurrentAssets, const Color(0xFF3B82F6), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('إجمالي الخصوم', report.totalLiabilities, const Color(0xFFB45309), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('حقوق الملكية', report.totalEquity, const Color(0xFF047857), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            'أرباح الفترة الحالية',
                            report.currentPeriodNetProfit,
                            report.currentPeriodNetProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                            surface,
                            borderColor,
                            textPrimary,
                            isHighlight: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Main Sections: 1. Assets, 2. Liabilities, 3. Equity
                      _buildSectionCard(
                        title: '1. الأصول والموجودات (Assets)',
                        badge: 'الإجمالي: ${_moneyFormat.format(report.totalAssets)}',
                        badgeColor: const Color(0xFF1E3A8A),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        children: [
                          _buildSubHeader('الأصول المتداولة (النقدية، البنوك، العملاء، المخزون)', report.totalCurrentAssets),
                          _buildItemsTable(report.currentAssets, surface, borderColor, textPrimary, textSecondary),
                          if (report.nonCurrentAssets.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSubHeader('الأصول غير المتداولة (الأصول الثابتة، التجهيزات)', report.totalNonCurrentAssets),
                            _buildItemsTable(report.nonCurrentAssets, surface, borderColor, textPrimary, textSecondary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: '2. الخصوم والالتزامات (Liabilities)',
                        badge: 'الإجمالي: ${_moneyFormat.format(report.totalLiabilities)}',
                        badgeColor: const Color(0xFFB45309),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        children: [
                          _buildSubHeader('الخصوم والالتزامات المتداولة (الموردون، أوراق الدفع، الأرصدة الدائنة)', report.totalCurrentLiabilities),
                          _buildItemsTable(report.currentLiabilities, surface, borderColor, textPrimary, textSecondary),
                          if (report.nonCurrentLiabilities.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildSubHeader('الخصوم طويلة الأجل (القروض والالتزامات غير المتداولة)', report.totalNonCurrentLiabilities),
                            _buildItemsTable(report.nonCurrentLiabilities, surface, borderColor, textPrimary, textSecondary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: '3. حقوق الملكية (Owner\'s Equity)',
                        badge: 'الإجمالي: ${_moneyFormat.format(report.totalEquity)}',
                        badgeColor: const Color(0xFF047857),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        children: [
                          _buildItemsTable(report.equityItems, surface, borderColor, textPrimary, textSecondary),
                          const Divider(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: report.currentPeriodNetProfit >= 0
                                  ? const Color(0xFF10B981).withOpacity(0.08)
                                  : const Color(0xFFDC2626).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      report.currentPeriodNetProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                                      color: report.currentPeriodNetProfit >= 0 ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'صافي أرباح / (خسائر) الفترة الحالية (من قائمة الدخل)',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                  ],
                                ),
                                Text(
                                  _moneyFormat.format(report.currentPeriodNetProfit),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: report.currentPeriodNetProfit >= 0 ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildKpiCard(
    String title,
    double value,
    Color color,
    Color surface,
    Color borderColor,
    Color textPrimary, {
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlight ? color : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isHighlight ? color : borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isHighlight ? Colors.white.withOpacity(0.9) : color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _moneyFormat.format(value),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isHighlight ? Colors.white : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          Text(_moneyFormat.format(total), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        ],
      ),
    );
  }

  Widget _buildItemsTable(
    List<BalanceSheetItem> items,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('لا توجد أرصدة مسجلة في هذا البند', style: TextStyle(color: textSecondary, fontSize: 12)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.5),
          1: FlexColumnWidth(4),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2.5),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text('كود الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(8), child: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          ...items.map(
            (i) => TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor, width: 0.5))),
              children: [
                Padding(padding: const EdgeInsets.all(8), child: Text(i.accountCode, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                Padding(padding: const EdgeInsets.all(8), child: Text(i.accountName, style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(8), child: Text(i.accountCategory ?? '---', style: TextStyle(fontSize: 11, color: textSecondary))),
                Padding(padding: const EdgeInsets.all(8), child: Text(_moneyFormat.format(i.balance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
