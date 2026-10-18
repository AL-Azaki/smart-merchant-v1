import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/profit_loss_service.dart';
import '../providers/accounting_provider.dart';

/// Real Income Statement (Profit & Loss / P&L) Tab computed dynamically from ledger transactions.
class ProfitLossTab extends ConsumerStatefulWidget {
  const ProfitLossTab({super.key});

  @override
  ConsumerState<ProfitLossTab> createState() => _ProfitLossTabState();
}

class _ProfitLossTabState extends ConsumerState<ProfitLossTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final reportAsync = ref.watch(
      profitLossReportProvider(startDate: _startDate, endDate: _endDate),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.query_stats_rounded, color: const Color(0xFF10B981), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قائمة الدخل - الأرباح والخسائر',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'صافي ومجمل الأرباح، الإيرادات، تكلفة البضاعة المباعة والمصروفات التشغيلية',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _startDate == null ? 'من البداية' : _dateFormat.format(_startDate!),
                      style: const TextStyle(fontSize: 13),
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
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _endDate == null ? 'إلى اليوم' : _dateFormat.format(_endDate!),
                      style: const TextStyle(fontSize: 13),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('خطأ في تحميل قائمة الدخل: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (report) {
                  return ListView(
                    children: [
                      // KPI Summary Row
                      Row(
                        children: [
                          _buildKpiCard('إجمالي المبيعات', report.totalRevenue, const Color(0xFF3B82F6), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('تكلفة البضاعة المباعة', report.totalCogs, const Color(0xFFF59E0B), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('مجمل الربح', report.grossProfit, const Color(0xFF8B5CF6), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard('المصروفات التشغيلية', report.totalExpenses, const Color(0xFFEF4444), surface, borderColor, textPrimary),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            'صافي الربح التشغيلي',
                            report.netProfit,
                            report.netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                            surface,
                            borderColor,
                            textPrimary,
                            isHighlight: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Breakdown Cards
                      _buildSection('1. الإيرادات والمبيعات', report.revenueItems, report.totalRevenue, surface, borderColor, textPrimary, textSecondary, const Color(0xFF3B82F6)),
                      const SizedBox(height: 16),
                      _buildSection('2. تكلفة البضاعة المباعة', report.cogsItems, report.totalCogs, surface, borderColor, textPrimary, textSecondary, const Color(0xFFF59E0B)),
                      const SizedBox(height: 16),
                      _buildSection('3. المصروفات التشغيلية', report.expenseItems, report.totalExpenses, surface, borderColor, textPrimary, textSecondary, const Color(0xFFEF4444)),
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
    Color accentColor,
    Color surface,
    Color borderColor,
    Color textPrimary, {
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlight ? accentColor.withOpacity(0.08) : surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isHighlight ? accentColor : borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              '${_moneyFormat.format(value)} YER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isHighlight ? accentColor : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<ProfitLossCategoryItem> items,
    double total,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(width: 4, height: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                const Spacer(),
                Text(
                  'المجموع: ${_moneyFormat.format(total)} YER',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('لا توجد حركات مسجلة تحت هذا القسم', style: TextStyle(color: textSecondary, fontSize: 13)),
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(item.accountCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.accountName, style: TextStyle(color: textPrimary, fontSize: 13))),
                    Text('${_moneyFormat.format(item.amount)} YER', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
