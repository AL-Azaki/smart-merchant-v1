import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/hr_provider.dart';
import 'widgets/employee_form_sheet.dart';

class EmployeesView extends ConsumerStatefulWidget {
  const EmployeesView({super.key});

  @override
  ConsumerState<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends ConsumerState<EmployeesView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الموظفين',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '0 موظف',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PrimaryButton(
                text: 'إضافة موظف',
                icon: Icons.add,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: EmployeeFormSheet(
                        onClose: () => Navigator.pop(ctx),
                        onSave: (data) async {
                          final success = await ref.read(hrNotifierProvider.notifier).saveEmployee(data);
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم الموظف، المسمى الوظيفي...',
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
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
        // Data Grid / Empty State
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
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد موظفين',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'قم بإضافة موظف جديد لعرضه هنا.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
