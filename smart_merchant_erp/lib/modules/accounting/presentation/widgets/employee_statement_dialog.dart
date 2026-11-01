import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import 'payroll_pdf_export_service.dart';
import 'record_employee_advance_dialog.dart';

class EmployeeStatementDialog extends StatelessWidget {
  final EmployeePayrollRecord record;
  final DateTime selectedMonth;
  final VoidCallback onDataChanged;

  const EmployeeStatementDialog({
    required this.record,
    required this.selectedMonth,
    required this.onDataChanged,
    super.key,
  });

  String _formatNum(double val) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);

    final emp = record.employee;
    final percentDrawn = record.basicSalary > 0
        ? (record.totalAdvances / record.basicSalary).clamp(0.0, 1.0)
        : 0.0;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كشف حساب: ${emp.firstName} ${emp.lastName}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
                        ),
                        Text(
                          'الرمز: ${emp.employeeCode} | الهاتف: ${emp.phone ?? '-'}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Print PDF Button
                  IconButton.filledTonal(
                    tooltip: 'طباعة / تصدير PDF',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF6366F1),
                    ),
                    onPressed: () {
                      PayrollPdfExportService.exportSingleEmployeeStatementPdf(
                        record: record,
                        periodDate: selectedMonth,
                        businessName: 'منشأة سمارت ميرشانت',
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 20),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Summary Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'الراتب المستحق',
                      value: '${_formatNum(record.basicSalary)} ر.ي',
                      color: const Color(0xFF3B82F6),
                      surface: surface,
                      borderColor: borderColor,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'المسحوب (سلف)',
                      value: '${_formatNum(record.totalAdvances)} ر.ي',
                      color: const Color(0xFFF59E0B),
                      surface: surface,
                      borderColor: borderColor,
                      textSecondary: textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'المتبقي له (التزام)',
                      value: '${_formatNum(record.remainingSalary)} ر.ي',
                      color: const Color(0xFF10B981),
                      surface: surface,
                      borderColor: borderColor,
                      textSecondary: textSecondary,
                      isBoldHighlight: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'نسبة ما أخذه الموظف: ${(percentDrawn * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'المتبقي: ${((1.0 - percentDrawn) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentDrawn,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentDrawn > 0.8 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Title of Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سجل السلف والمصروفات المستلمة (${record.transactions.length}):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'ar').format(selectedMonth),
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transactions List
              Expanded(
                child: record.transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 44, color: textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text(
                              'لم يسحب الموظف أي سلفة خلال هذا الشهر',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: record.transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final t = record.transactions[index];
                          final dateStr = DateFormat('yyyy/MM/dd').format(t.paymentDate);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFF59E0B)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.notes ?? 'سلفة نقدية على الراتب',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'رقم السند: ${t.paymentNumber} • $dateStr',
                                        style: TextStyle(fontSize: 10, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '- ${_formatNum(t.amount)} ر.ي',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  // Fast Advance
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final res = await showDialog<bool>(
                          context: context,
                          builder: (_) => RecordEmployeeAdvanceDialog(
                            preselectedEmployee: emp,
                            currentRemainingSalary: record.remainingSalary,
                          ),
                        );
                        if (res == true) {
                          onDataChanged();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('تسجيل سلفة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Settle Remaining Salary
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: record.remainingSalary <= 0
                          ? null
                          : () async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => RecordEmployeeAdvanceDialog(
                                  preselectedEmployee: emp,
                                  isAdvance: false,
                                  currentRemainingSalary: record.remainingSalary,
                                ),
                              );
                              if (res == true) {
                                onDataChanged();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('صرف وتصفية الراتب',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color surface,
    required Color borderColor,
    required Color textSecondary,
    bool isBoldHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isBoldHighlight ? color : borderColor),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 9.5, color: textSecondary)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
