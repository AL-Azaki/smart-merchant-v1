import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../hr/presentation/providers/hr_provider.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../widgets/add_employee_quick_dialog.dart';
import '../widgets/employee_statement_dialog.dart';
import '../widgets/payroll_pdf_export_service.dart';
import '../widgets/record_employee_advance_dialog.dart';

class EmployeesPayrollView extends ConsumerStatefulWidget {
  const EmployeesPayrollView({super.key});

  @override
  ConsumerState<EmployeesPayrollView> createState() => _EmployeesPayrollViewState();
}

class _EmployeesPayrollViewState extends ConsumerState<EmployeesPayrollView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double val) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(val);
  }

  Future<void> _pickCustomDateRange() async {
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
      } else if (preset == 'current_year') {
        _startDate = DateTime(now.year);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
    });
  }

  Future<void> _openAddEmployeeDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const AddEmployeeQuickDialog(),
    );
    if (res == true && mounted) {
      ref.invalidate(employeesListProvider);
    }
  }

  Future<void> _openRecordAdvanceDialog({Employee? employee, bool isAdvance = true, double remaining = 0.0}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => RecordEmployeeAdvanceDialog(
        preselectedEmployee: employee,
        isAdvance: isAdvance,
        currentRemainingSalary: remaining,
      ),
    );
    if (res == true && mounted) {
      ref.invalidate(paymentVouchersStreamProvider);
    }
  }

  Future<void> _accrueAllSalariesDialog(double totalSalaries, int employeeCount, String periodLabel) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('استحقاق رواتب الفترة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفترة: $periodLabel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('عدد الموظفين المستحقين: $employeeCount موظف'),
            Text('إجمالي مبلغ الاستحقاق: ${_formatAmount(totalSalaries)} ر.ي'),
            const SizedBox(height: 12),
            const Text(
              'نظام الاستحقاق يثبت الرواتب كالتزام في ميزان المراجعة ليتم خصم السلف منها تلقائياً.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم احتساب وتثبيت استحقاقات الرواتب لفترة $periodLabel بنجاح',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('تأكيد الاستحقاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final employeesAsync = ref.watch(employeesListProvider);
    final paymentsAsync = ref.watch(paymentVouchersStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0F14) : const Color(0xFFF8FAFC),
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('حدث خطأ أثناء تحميل بيانات الموظفين: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (employees) {
          final payments = paymentsAsync.asData?.value ?? [];

          // Filter payments belonging to current selected date range
          final startBound = DateTime(_startDate.year, _startDate.month, _startDate.day);
          final endBound = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

          final periodPayments = payments.where((p) {
            return !p.paymentDate.isBefore(startBound) && !p.paymentDate.isAfter(endBound);
          }).toList();

          final days = _endDate.difference(_startDate).inDays + 1;
          final int monthsCount = (days > 31)
              ? ((_endDate.year - _startDate.year) * 12 + _endDate.month - _startDate.month + 1).clamp(1, 120)
              : 1;

          final isSameMonth = _startDate.year == _endDate.year && _startDate.month == _endDate.month;
          final periodLabel = isSameMonth
              ? DateFormat('MMMM yyyy', 'ar').format(_startDate)
              : 'من ${DateFormat('yyyy/MM/dd').format(_startDate)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate)}';

          // Build payroll records per employee
          final List<EmployeePayrollRecord> payrollRecords = employees.map((emp) {
            final empPayments = periodPayments.where((p) {
              final isEmpContact = p.contactType == 'Employee' && p.contactId == emp.id;
              final isEmpNotes = p.notes?.contains(emp.firstName) ?? false;
              return isEmpContact || isEmpNotes;
            }).toList();

            final totalAdvances = empPayments.fold(0.0, (sum, p) => sum + p.amount);
            final basicSalary = emp.salary * monthsCount;
            final remainingSalary = (basicSalary - totalAdvances).clamp(0.0, double.infinity);

            return EmployeePayrollRecord(
              employee: emp,
              basicSalary: basicSalary,
              totalAdvances: totalAdvances,
              remainingSalary: remainingSalary,
              transactions: empPayments,
            );
          }).toList();

          // Overall Totals
          final double totalSalaries = payrollRecords.fold(0.0, (sum, r) => sum + r.basicSalary);
          final double totalAdvances = payrollRecords.fold(0.0, (sum, r) => sum + r.totalAdvances);
          final double totalRemaining = payrollRecords.fold(0.0, (sum, r) => sum + r.remainingSalary);

          // Filter by search query
          final filteredRecords = payrollRecords.where((r) {
            final q = _searchQuery.toLowerCase();
            if (q.isEmpty) {
              return true;
            }
            final name = '${r.employee.firstName} ${r.employee.lastName}'.toLowerCase();
            final code = r.employee.employeeCode.toLowerCase();
            final phone = r.employee.phone ?? '';
            return name.contains(q) || code.contains(q) || phone.contains(q);
          }).toList();

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'إدارة الموظفين',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              // ── 1. Top 4 KPI Summary Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDarkKpiCard(
                              title: 'عدد الموظفين',
                              value: '${employees.length}',
                              isDark: isDark,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDarkKpiCard(
                              title: monthsCount > 1 ? 'مستحق الراتب ($monthsCount أشهر)' : 'مستحق الراتب',
                              value: _formatAmount(totalSalaries),
                              isDark: isDark,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDarkKpiCard(
                              title: 'السلف المسحوبة',
                              value: _formatAmount(totalAdvances),
                              isDark: isDark,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDarkKpiCard(
                              title: 'الرواتب غير المصروفة',
                              value: _formatAmount(totalRemaining),
                              isDark: isDark,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. Quick Actions Header & 2x2 Grid ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العمليات السريعة',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'إضافة موظف',
                              icon: Icons.person_add_outlined,
                              isDark: isDark,
                              onTap: _openAddEmployeeDialog,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'تسجيل سلفة',
                              icon: Icons.account_balance_wallet_outlined,
                              isDark: isDark,
                              onTap: () => _openRecordAdvanceDialog(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'استحقاق راتب',
                              icon: Icons.calendar_month_outlined,
                              isDark: isDark,
                              onTap: () => _accrueAllSalariesDialog(totalSalaries, employees.length, periodLabel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              title: 'صرف راتب',
                              icon: Icons.price_check_rounded,
                              isDark: isDark,
                              onTap: () => _openRecordAdvanceDialog(
                                isAdvance: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 3. Filters Section: Statement Print + Date Range + Search Bar ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E222D) : surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row A: Statement Download Button (Full Width & Clean)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            PayrollPdfExportService.exportAllEmployeesPayrollPdf(
                              records: payrollRecords,
                              startDate: _startDate,
                              endDate: _endDate,
                              businessName: 'منشأة سمارت ميرشانت',
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text(
                            'كشف حساب للكل (PDF)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Row B: Quick Period Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPeriodChip('الشهر الحالي', () => _setDatePreset('current_month'), isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip('الشهر السابق', () => _setDatePreset('prev_month'), isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip('آخر 3 أشهر', () => _setDatePreset('last_3_months'), isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip('السنة الحالية', () => _setDatePreset('current_year'), isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip('تحديد تاريخ محدد 📅', _pickCustomDateRange, isDark, isHighlight: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Row C: Search Box
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث باسم الموظف أو هاتفه أو رمزه...',
                          hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 4. Employees List (Cards with Salary, Advances, Remaining & Progress Bar) ──
              if (filteredRecords.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.badge_outlined, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 10),
                          Text(
                            employees.isEmpty
                                ? 'لا يوجد موظفون مسجلون حالياً'
                                : 'لا توجد نتائج مطابقة لبحثك',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textSecondary),
                          ),
                          const SizedBox(height: 6),
                          if (employees.isEmpty)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                              onPressed: _openAddEmployeeDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('إضافة أول موظف الآن'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = filteredRecords[index];
                        final emp = record.employee;
                        final percent = record.basicSalary > 0
                            ? (record.totalAdvances / record.basicSalary).clamp(0.0, 1.0)
                            : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1D24) : surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Row 1: Employee Info & Code
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                    child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF3B82F6)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${emp.firstName} ${emp.lastName}',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${emp.employeeCode} • ${emp.phone ?? "بدون هاتف"}',
                                          style: TextStyle(fontSize: 11, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Individual Statement (PDF & Details)
                                  IconButton.filledTonal(
                                    tooltip: 'كشف حساب الموظف (PDF / عرض)',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                      foregroundColor: const Color(0xFF3B82F6),
                                    ),
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => EmployeeStatementDialog(
                                          initialRecord: record,
                                          initialStartDate: _startDate,
                                          initialEndDate: _endDate,
                                          allEmployeePayments: payments.where((p) {
                                            final isEmpContact = p.contactType == 'Employee' && p.contactId == emp.id;
                                            final isEmpNotes = p.notes?.contains(emp.firstName) ?? false;
                                            return isEmpContact || isEmpNotes;
                                          }).toList(),
                                          onDataChanged: () => ref.invalidate(paymentVouchersStreamProvider),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Row 2: 3 Metrics (الراتب المستحق، المسحوب، المتبقي له)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF121419) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildPillColumn(
                                      monthsCount > 1 ? 'الراتب ($monthsCount أشهر)' : 'الراتب المستحق',
                                      '${_formatAmount(record.basicSalary)} ر.ي',
                                      textSecondary,
                                      textPrimary,
                                    ),
                                    Container(width: 1, height: 28, color: borderColor),
                                    _buildPillColumn(
                                      'السلف المسحوبة',
                                      '${_formatAmount(record.totalAdvances)} ر.ي',
                                      textSecondary,
                                      const Color(0xFFF59E0B),
                                    ),
                                    Container(width: 1, height: 28, color: borderColor),
                                    _buildPillColumn(
                                      'المتبقي له (التزام)',
                                      '${_formatAmount(record.remainingSalary)} ر.ي',
                                      textSecondary,
                                      const Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Row 3: Progress Bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ما تم سحبه: ${(percent * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: textSecondary),
                                      ),
                                      Text(
                                        'المتبقي: ${((1.0 - percent) * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 6,
                                      backgroundColor: isDark ? const Color(0xFF2C3140) : const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        percent > 0.8 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Row 4: Quick Action Buttons per Employee
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _openRecordAdvanceDialog(
                                        employee: emp,
                                        remaining: record.remainingSalary,
                                      ),
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                      label: const Text('إعطاء سلفة', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: record.remainingSalary <= 0
                                          ? null
                                          : () => _openRecordAdvanceDialog(
                                                employee: emp,
                                                isAdvance: false,
                                                remaining: record.remainingSalary,
                                              ),
                                      icon: const Icon(Icons.price_check_rounded, size: 16),
                                      label: const Text('صرف المتبقي', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: filteredRecords.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodChip(String label, VoidCallback onTap, bool isDark, {bool isHighlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isHighlight
              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF262A38) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: isHighlight ? Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF6366F1) : null,
          ),
        ),
      ),
    );
  }

  /// 4 Dark KPI Cards
  Widget _buildDarkKpiCard({
    required String title,
    required String value,
    required bool isDark,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmallText ? 15 : 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 4 Quick Action Buttons
  Widget _buildQuickActionButton({
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111215),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF26282E)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillColumn(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}
