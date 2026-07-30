import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../kernel/storage/app_database.dart';
import '../providers/hr_provider.dart';
import 'widgets/employee_form_sheet.dart';
import 'widgets/employee_detail_screen.dart';

class EmployeesView extends ConsumerStatefulWidget {
  const EmployeesView({super.key});

  @override
  ConsumerState<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends ConsumerState<EmployeesView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Employee? _selectedEmployee;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEmployee != null) {
      return EmployeeDetailScreen(
        employee: _selectedEmployee!,
        onBack: () => setState(() => _selectedEmployee = null),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final employeesAsync = ref.watch(employeesListProvider);

    return employeesAsync.when(
      data: (employees) {
        final filteredEmployees = employees.where((e) {
          final q = _searchQuery.toLowerCase();
          return e.firstName.toLowerCase().contains(q) ||
              e.lastName.toLowerCase().contains(q) ||
              (e.phone?.contains(q) ?? false) ||
              e.employeeCode.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: surfaceColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الموظفين',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${employees.length} موظف',
                                style: TextStyle(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      text: 'إضافة موظف',
                      icon: Icons.add,
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            child: EmployeeFormSheet(
                              onClose: () => Navigator.pop(ctx),
                              onSave: (data) async {
                                final success = await ref
                                    .read(hrNotifierProvider.notifier)
                                    .saveEmployee(data);
                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Toolbar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText:
                              'البحث عن موظف بالاسم، الرقم، المسمى الوظيفي...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Data List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد موظفين',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'قم بإضافة موظف جديد لعرضه هنا.'
                                  : 'لا توجد نتائج مطابقة للبحث.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: filteredEmployees.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: borderColor),
                        itemBuilder: (context, index) {
                          final emp = filteredEmployees[index];
                          final isActive = emp.status == 'Active';
                          final isOnLeave = emp.status == 'OnLeave';

                          final badgeColor = isActive
                              ? AppColors.success
                              : (isOnLeave
                                    ? AppColors.warning
                                    : AppColors.error);
                          final badgeText = isActive
                              ? 'نشط'
                              : (isOnLeave ? 'في إجازة' : 'موقوف');

                          return ListTile(
                            onTap: () =>
                                setState(() => _selectedEmployee = emp),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              emp.firstName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${emp.employeeCode} • ${emp.phone ?? "بدون رقم"}',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusBadge(badgeText, badgeColor),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  color: Colors.grey,
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 24,
                                            ),
                                        child: EmployeeFormSheet(
                                          employee: {
                                            'id': emp.id,
                                            'name': emp.firstName,
                                            'name_en': emp.lastName,
                                            'employee_code': emp.employeeCode,
                                            'position': emp.employeeCode,
                                            'phone': emp.phone,
                                            'salary': emp.salary,
                                            'status': emp.status == 'Active'
                                                ? 'active'
                                                : (emp.status == 'OnLeave'
                                                      ? 'on_leave'
                                                      : 'inactive'),
                                          },
                                          onClose: () => Navigator.pop(ctx),
                                          onSave: (data) async {
                                            final success = await ref
                                                .read(
                                                  hrNotifierProvider.notifier,
                                                )
                                                .saveEmployee(data);
                                            if (success && ctx.mounted) {
                                              Navigator.pop(ctx);
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
