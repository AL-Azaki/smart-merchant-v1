import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import 'payroll_pdf_export_service.dart';
import 'record_employee_advance_dialog.dart';

class EmployeeStatementDialog extends StatefulWidget {
  final EmployeePayrollRecord initialRecord;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final List<Payment> allEmployeePayments;
  final VoidCallback onDataChanged;

  const EmployeeStatementDialog({
    required this.initialRecord,
    required this.allEmployeePayments,
    required this.onDataChanged,
    this.initialStartDate,
    this.initialEndDate,
    super.key,
  });

  @override
  State<EmployeeStatementDialog> createState() => _EmployeeStatementDialogState();
}

class _EmployeeStatementDialogState extends State<EmployeeStatementDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime(DateTime.now().year, DateTime.now().month);
    _endDate = widget.initialEndDate ?? DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  }

  String _formatNum(double val) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(val);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      if (preset == 'current_month') {
        _startDate = DateTime(now.year, now.month);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == 'prev_month') {
        _startDate = DateTime(now.year, now.month - 1);
        _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (preset == 'last_3_months') {
        _startDate = DateTime(now.year, now.month - 2);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);

    final emp = widget.initialRecord.employee;

    // Filter payments by date range
    final startBound = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endBound = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final filteredTransactions = widget.allEmployeePayments.where((p) {
      return !p.paymentDate.isBefore(startBound) && !p.paymentDate.isAfter(endBound);
    }).toList();

    // Calculate months count
    final days = _endDate.difference(_startDate).inDays + 1;
    final int monthsCount = (days > 31)
        ? ((_endDate.year - _startDate.year) * 12 + _endDate.month - _startDate.month + 1).clamp(1, 120)
        : 1;

    final basicSalary = emp.salary * monthsCount;
    final totalAdvances = filteredTransactions.fold(0.0, (sum, p) => sum + p.amount);
    final remainingSalary = (basicSalary - totalAdvances).clamp(0.0, double.infinity);

    final currentRecord = EmployeePayrollRecord(
      employee: emp,
      basicSalary: basicSalary,
      totalAdvances: totalAdvances,
      remainingSalary: remainingSalary,
      transactions: filteredTransactions,
    );

    final percentDrawn = basicSalary > 0
        ? (totalAdvances / basicSalary).clamp(0.0, 1.0)
        : 0.0;

    final isSameMonth = _startDate.year == _endDate.year && _startDate.month == _endDate.month;
    final periodLabel = isSameMonth
        ? DateFormat('MMMM yyyy', 'ar').format(_startDate)
        : 'من ${DateFormat('yyyy/MM/dd').format(_startDate)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate)}';

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                          'الرمز: ${emp.employeeCode} | الهاتف: ${emp.phone ?? "-"}',
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
                        record: currentRecord,
                        startDate: _startDate,
                        endDate: _endDate,
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
              const SizedBox(height: 12),

              // Quick Filter Chips Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('الشهر الحالي', () => _setDatePreset('current_month'), isDark),
                      const SizedBox(width: 6),
                      _buildQuickChip('الشهر السابق', () => _setDatePreset('prev_month'), isDark),
                      const SizedBox(width: 6),
                      _buildQuickChip('3 أشهر', () => _setDatePreset('last_3_months'), isDark),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _pickDateRange,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_calendar_rounded, size: 13, color: Color(0xFF6366F1)),
                              SizedBox(width: 4),
                              Text(
                                'تخصيص 📅',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Summary Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: monthsCount > 1 ? 'الراتب ($monthsCount أشهر)' : 'الراتب المستحق',
                      value: '${_formatNum(basicSalary)} ر.ي',
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
                      value: '${_formatNum(totalAdvances)} ر.ي',
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
                      value: '${_formatNum(remainingSalary)} ر.ي',
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
                children: [
                  Expanded(
                    child: Text(
                      'سجل السلف والمصروفات المستلمة (${filteredTransactions.length}):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    periodLabel,
                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Transactions List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 44, color: textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text(
                              'لم يسحب الموظف أي سلفة خلال هذه الفترة',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredTransactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final t = filteredTransactions[index];
                          final dateStr = DateFormat('yyyy/MM/dd').format(t.paymentDate);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1D24) : surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFF59E0B)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.notes ?? 'سلفة على الراتب',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                      ),
                                      Text(
                                        'سند #${t.paymentNumber} • $dateStr',
                                        style: TextStyle(fontSize: 10, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_formatNum(t.amount)} ر.ي',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Buttons
              Row(
                children: [
                  // Record Advance
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
                            currentRemainingSalary: remainingSalary,
                          ),
                        );
                        if (res == true) {
                          widget.onDataChanged();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('تسجيل سلفة جديدة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      onPressed: remainingSalary <= 0
                          ? null
                          : () async {
                              final res = await showDialog<bool>(
                                context: context,
                                builder: (_) => RecordEmployeeAdvanceDialog(
                                  preselectedEmployee: emp,
                                  isAdvance: false,
                                  currentRemainingSalary: remainingSalary,
                                ),
                              );
                              if (res == true) {
                                widget.onDataChanged();
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

  Widget _buildQuickChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B3040) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
