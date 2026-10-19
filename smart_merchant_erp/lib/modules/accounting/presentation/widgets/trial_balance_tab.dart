import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/accounting_provider.dart';
import 'financial_report_pdf_service.dart';

/// Interactive, real-time Trial Balance Tab connected to General Ledger.
class TrialBalanceTab extends ConsumerStatefulWidget {
  const TrialBalanceTab({super.key});

  @override
  ConsumerState<TrialBalanceTab> createState() => _TrialBalanceTabState();
}

class _TrialBalanceTabState extends ConsumerState<TrialBalanceTab> {
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
      trialBalanceReportProvider(startDate: _startDate, endDate: _endDate),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: const Color(0xFF3B82F6), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ميزان المراجعة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'تحقق شامل من توازن الأستاذ العام والأرصدة المدينة والدائنة',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Date range picker buttons
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
                  const SizedBox(width: 12),
                  // Print & Export Buttons
                  reportAsync.maybeWhen(
                    data: (report) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('طباعة PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => FinancialReportPdfService.printTrialBalance(
                            context: context,
                            report: report,
                            startDate: _startDate,
                            endDate: _endDate,
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
                          onPressed: () => FinancialReportPdfService.shareTrialBalance(
                            context: context,
                            report: report,
                            startDate: _startDate,
                            endDate: _endDate,
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

            // Report View
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('خطأ في تحميل ميزان المراجعة: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (report) {
                  return Column(
                    children: [
                      // Golden Balance Status Banner
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
                              report.isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: report.isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                report.isBalanced
                                    ? 'الميزان متزن محاسبياً بنسبة 100% — مجموع المدين يطابق مجموع الدائن بدقة.'
                                    : 'تنبيه: يوجد عدم توازن في الميزان! الفارق: ${_moneyFormat.format((report.grandTotalDebit - report.grandTotalCredit).abs())} YER',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: report.isBalanced ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                            Text(
                              'إجمالي المدين: ${_moneyFormat.format(report.grandTotalDebit)}  |  إجمالي الدائن: ${_moneyFormat.format(report.grandTotalCredit)}',
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

                      // Table View
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: report.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 48, color: textSecondary),
                                        const SizedBox(height: 12),
                                        Text('لا توجد حركات مالية مرحلة في هذه الفترة', style: TextStyle(color: textSecondary)),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('كود الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('مجموع المدين', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('مجموع الدائن', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('رصيد مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('رصيد دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: [
                                        ...report.items.map((item) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(item.accountCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                              DataCell(Text(item.accountName)),
                                              DataCell(Text(_moneyFormat.format(item.totalDebit))),
                                              DataCell(Text(_moneyFormat.format(item.totalCredit))),
                                              DataCell(
                                                Text(
                                                  item.netDebit > 0 ? _moneyFormat.format(item.netDebit) : '-',
                                                  style: TextStyle(
                                                    color: item.netDebit > 0 ? const Color(0xFF3B82F6) : textSecondary,
                                                    fontWeight: item.netDebit > 0 ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  item.netCredit > 0 ? _moneyFormat.format(item.netCredit) : '-',
                                                  style: TextStyle(
                                                    color: item.netCredit > 0 ? const Color(0xFF10B981) : textSecondary,
                                                    fontWeight: item.netCredit > 0 ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                        // Total Row
                                        DataRow(
                                          color: WidgetStateProperty.all(
                                            isDark ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0).withOpacity(0.5),
                                          ),
                                          cells: [
                                            const DataCell(Text('المجموع الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                                            const DataCell(Text('')),
                                            DataCell(Text(_moneyFormat.format(report.grandTotalDebit), style: const TextStyle(fontWeight: FontWeight.bold))),
                                            DataCell(Text(_moneyFormat.format(report.grandTotalCredit), style: const TextStyle(fontWeight: FontWeight.bold))),
                                            DataCell(Text(_moneyFormat.format(report.grandNetDebit), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)))),
                                            DataCell(Text(_moneyFormat.format(report.grandNetCredit), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
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
}
