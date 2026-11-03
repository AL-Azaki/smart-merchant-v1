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

/// Professional, distilled and streamlined Employees & Payroll management view.
/// Focused on scanability, low cognitive load, and instant access to employee records.
class EmployeesPayrollView extends ConsumerStatefulWidget {
  const EmployeesPayrollView({super.key});

  @override
  ConsumerState<EmployeesPayrollView> createState() => _EmployeesPayrollViewState();
}

class _EmployeesPayrollViewState extends ConsumerState<EmployeesPayrollView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activePreset = 'current_month';

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
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _activePreset = 'custom';
        _startDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
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

  Future<void> _openAddEmployeeDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const AddEmployeeQuickDialog(),
    );
    if (res == true && mounted) {
      ref.invalidate(employeesListProvider);
    }
  }

  Future<void> _openRecordAdvanceDialog({
    Employee? employee,
    bool isAdvance = true,
    double remaining = 0.0,
  }) async {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final background = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final employeesAsync = ref.watch(employeesListProvider);
    final paymentsAsync = ref.watch(paymentVouchersStreamProvider);

    return Scaffold(
      backgroundColor: background,
      body: employeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'حدث خطأ أثناء تحميل بيانات الموظفين: $err',
            style: const TextStyle(color: AppColors.error),
          ),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isCompact = constraints.maxWidth < 650;

              return CustomScrollView(
                slivers: [
                  // ── 1. Clean Operational Header ──
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: surface,
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildHeaderTitle(
                                        employeesCount: employees.length,
                                        periodLabel: periodLabel,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      tooltip: 'طباعة مسير الرواتب (PDF)',
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        foregroundColor: AppColors.primary,
                                      ),
                                      onPressed: () {
                                        PayrollPdfExportService.exportAllEmployeesPayrollPdf(
                                          records: payrollRecords,
                                          startDate: _startDate,
                                          endDate: _endDate,
                                          businessName: 'منشأة سمارت ميرشانت',
                                        );
                                      },
                                      icon: const Icon(Icons.print_rounded, size: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: _openAddEmployeeDialog,
                                        icon: const Icon(Icons.person_add_rounded, size: 18),
                                        label: const Text(
                                          'إضافة موظف',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: textPrimary,
                                          side: BorderSide(color: borderColor),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _openRecordAdvanceDialog(),
                                        icon: const Icon(Icons.payments_outlined, size: 18),
                                        label: const Text(
                                          'تسجيل سلفة',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildHeaderTitle(
                                    employeesCount: employees.length,
                                    periodLabel: periodLabel,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.surfaceVariantDark
                                        : const Color(0xFFF1F5F9),
                                    foregroundColor: textPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    PayrollPdfExportService.exportAllEmployeesPayrollPdf(
                                      records: payrollRecords,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                      businessName: 'منشأة سمارت ميرشانت',
                                    );
                                  },
                                  icon: const Icon(Icons.print_outlined, size: 18),
                                  label: const Text(
                                    'مسير الرواتب (PDF)',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: BorderSide(color: borderColor),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => _openRecordAdvanceDialog(),
                                  icon: const Icon(Icons.payments_outlined, size: 18),
                                  label: const Text(
                                    'تسجيل سلفة',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _openAddEmployeeDialog,
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text(
                                    'إضافة موظف',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── 2. Unified Quiet Summary Strip (Single Sleek Bar) ──
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 20,
                        vertical: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: isCompact
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricItem(
                                        label: 'عدد الموظفين',
                                        value: '${employees.length} موظف',
                                        valueColor: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                    Container(width: 1, height: 28, color: borderColor),
                                    Expanded(
                                      child: _buildMetricItem(
                                        label: monthsCount > 1
                                            ? 'الرواتب ($monthsCount أشهر)'
                                            : 'الرواتب المستحقة',
                                        value: '${_formatAmount(totalSalaries)} ر.ي',
                                        valueColor: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, thickness: 1, color: borderColor),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricItem(
                                        label: 'السلف المسحوبة',
                                        value: '${_formatAmount(totalAdvances)} ر.ي',
                                        valueColor: AppColors.warning,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                    Container(width: 1, height: 28, color: borderColor),
                                    Expanded(
                                      child: _buildMetricItem(
                                        label: 'صافي المستحق للموظفين',
                                        value: '${_formatAmount(totalRemaining)} ر.ي',
                                        valueColor: AppColors.success,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildMetricItem(
                                    label: 'الموظفون النشطون',
                                    value: '${employees.length} موظف',
                                    valueColor: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                Container(width: 1, height: 32, color: borderColor),
                                Expanded(
                                  child: _buildMetricItem(
                                    label: monthsCount > 1
                                        ? 'الرواتب ($monthsCount أشهر)'
                                        : 'إجمالي الرواتب',
                                    value: '${_formatAmount(totalSalaries)} ر.ي',
                                    valueColor: textPrimary,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                Container(width: 1, height: 32, color: borderColor),
                                Expanded(
                                  child: _buildMetricItem(
                                    label: 'السلف المسحوبة',
                                    value: '${_formatAmount(totalAdvances)} ر.ي',
                                    valueColor: AppColors.warning,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                                Container(width: 1, height: 32, color: borderColor),
                                Expanded(
                                  child: _buildMetricItem(
                                    label: 'صافي الالتزام المتبقي',
                                    value: '${_formatAmount(totalRemaining)} ر.ي',
                                    valueColor: AppColors.success,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── 3. Filters & Search Strip ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 20,
                        vertical: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'بحث باسم الموظف، الرمز، أو الهاتف...',
                                    hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
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
                                    filled: true,
                                    fillColor: surface,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                    ),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quick Period Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  label: 'الشهر الحالي',
                                  isSelected: _activePreset == 'current_month',
                                  onTap: () => _setDatePreset('current_month'),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: 'الشهر السابق',
                                  isSelected: _activePreset == 'prev_month',
                                  onTap: () => _setDatePreset('prev_month'),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: 'آخر 3 أشهر',
                                  isSelected: _activePreset == 'last_3_months',
                                  onTap: () => _setDatePreset('last_3_months'),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  label: _activePreset == 'custom'
                                      ? 'فترة مخصصة: $periodLabel'
                                      : 'فترة مخصصة...',
                                  isSelected: _activePreset == 'custom',
                                  icon: Icons.date_range_rounded,
                                  onTap: _pickCustomDateRange,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // ── 4. Employees List (Clean Grid or List) ──
                  if (filteredRecords.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 48,
                                color: textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                employees.isEmpty
                                    ? 'لا يوجد موظفون مسجلون حالياً'
                                    : 'لا توجد نتائج مطابقة للبحث',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (employees.isEmpty)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _openAddEmployeeDialog,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('إضافة أول موظف الآن'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (isWide)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 200,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildEmployeeCard(
                            record: filteredRecords[index],
                            monthsCount: monthsCount,
                            surface: surface,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                            payments: payments,
                          ),
                          childCount: filteredRecords.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(isCompact ? 12 : 20, 4, isCompact ? 12 : 20, 60),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildEmployeeCard(
                              record: filteredRecords[index],
                              monthsCount: monthsCount,
                              surface: surface,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              payments: payments,
                            ),
                          ),
                          childCount: filteredRecords.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle({
    required int employeesCount,
    required String periodLabel,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الموظفون والرواتب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                periodLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'متابعة مستحقات الموظفين وصرف السلف وتصفية الرواتب بدقة ووضوح',
          style: TextStyle(fontSize: 11.5, color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color valueColor,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard({
    required EmployeePayrollRecord record,
    required int monthsCount,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required List<Payment> payments,
  }) {
    final emp = record.employee;
    final percent = record.basicSalary > 0
        ? (record.totalAdvances / record.basicSalary).clamp(0.0, 1.0)
        : 0.0;
    final isFullyPaid = record.remainingSalary <= 0 && record.basicSalary > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Header (Avatar, Name, Code, Statement action) ──
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  emp.firstName.isNotEmpty ? emp.firstName.characters.first : 'م',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${emp.firstName} ${emp.lastName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${emp.employeeCode}${emp.phone != null && emp.phone!.isNotEmpty ? " • ${emp.phone}" : ""}',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),
              // Statement Button
              IconButton.filledTonal(
                tooltip: 'عرض كشف الحساب والطباعة',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                  foregroundColor: textPrimary,
                  visualDensity: VisualDensity.compact,
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
                icon: const Icon(Icons.receipt_long_rounded, size: 17),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Metrics Strip (الأساسي، المسحوب، المتبقي) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131824) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildColumnData(
                  label: monthsCount > 1 ? 'الراتب ($monthsCount أشهر)' : 'الراتب المستحق',
                  val: '${_formatAmount(record.basicSalary)} ر.ي',
                  valColor: textPrimary,
                  textSecondary: textSecondary,
                ),
                Container(width: 1, height: 26, color: borderColor),
                _buildColumnData(
                  label: 'السلف المسحوبة',
                  val: '${_formatAmount(record.totalAdvances)} ر.ي',
                  valColor: AppColors.warning,
                  textSecondary: textSecondary,
                ),
                Container(width: 1, height: 26, color: borderColor),
                _buildColumnData(
                  label: 'صافي المتبقي',
                  val: '${_formatAmount(record.remainingSalary)} ر.ي',
                  valColor: isFullyPaid ? textSecondary : AppColors.success,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Row 3: Progress Bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: isDark ? AppColors.surfaceVariantDark : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullyPaid
                    ? AppColors.success
                    : (percent > 0.85 ? AppColors.error : AppColors.warning),
              ),
            ),
          ),

          const Spacer(),

          // ── Row 4: Action Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _openRecordAdvanceDialog(
                    employee: emp,
                    remaining: record.remainingSalary,
                  ),
                  child: const Text(
                    'تسجيل سلفة',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isFullyPaid ? AppColors.surfaceVariantDark : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: record.remainingSalary <= 0
                      ? null
                      : () => _openRecordAdvanceDialog(
                            employee: emp,
                            isAdvance: false,
                            remaining: record.remainingSalary,
                          ),
                  child: Text(
                    isFullyPaid ? 'مكتمل الصرف' : 'صرف المتبقي',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumnData({
    required String label,
    required String val,
    required Color valColor,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: valColor),
        ),
      ],
    );
  }
}
