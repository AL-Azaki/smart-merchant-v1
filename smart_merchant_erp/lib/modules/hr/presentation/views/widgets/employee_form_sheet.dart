import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class EmployeeFormSheet extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const EmployeeFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.employee,
  });

  @override
  State<EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends State<EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _employeeCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;
  late TextEditingController _emailController;

  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?['name']?.toString() ?? '');
    _employeeCodeController = TextEditingController(text: widget.employee?['employee_code']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.employee?['phone']?.toString() ?? '');
    final salary = widget.employee?['salary'] as num?;
    _salaryController = TextEditingController(text: salary != null && salary > 0 ? salary.toString() : '');
    _emailController = TextEditingController(text: widget.employee?['email']?.toString() ?? '');
    _status = widget.employee?['status']?.toString() ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeCodeController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.employee?['id'],
        'name': _nameController.text,
        'employee_code': _employeeCodeController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'status': _status,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final isEdit = widget.employee != null;

    return AppModalSheet(
      title: isEdit ? 'تعديل بيانات الموظف' : 'إضافة موظف جديد',
      icon: Icons.badge_outlined,
      onClose: widget.onClose,
      primaryLabel: 'حفظ الموظف',
      onPrimary: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // المعلومات الأساسية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('المعلومات الأساسية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'اسم الموظف *',
                    hint: 'أدخل الاسم الكامل للموظف',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الموظف' : null,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final empCodeField = AppTextField(
                        label: 'رمز الموظف (الكود) *',
                        hint: 'EMP-01',
                        controller: _employeeCodeController,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال كود الموظف' : null,
                      );
                      final phoneField = AppTextField(
                        label: 'رقم الهاتف',
                        hint: '05xxxxxxxx',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            empCodeField,
                            const SizedBox(height: 14),
                            phoneField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: empCodeField),
                          const SizedBox(width: 12),
                          Expanded(child: phoneField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // التفاصيل الإدارية والمالية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_money_outlined, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('التفاصيل الإدارية والمالية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final salaryField = AppNumberField(
                        label: 'الراتب الشهري (YER) *',
                        hint: '0.00',
                        controller: _salaryController,
                        suffixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الراتب' : null,
                      );
                      final statusField = AppTextField(
                        label: 'الحالة',
                        initialValue: _status == 'active'
                            ? 'نشط'
                            : (_status == 'on_leave' ? 'في إجازة' : 'موقوف'),
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _status = val),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'active', child: Text('نشط')),
                            PopupMenuItem(value: 'on_leave', child: Text('في إجازة')),
                            PopupMenuItem(value: 'inactive', child: Text('موقوف')),
                          ],
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            salaryField,
                            const SizedBox(height: 14),
                            statusField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: salaryField),
                          const SizedBox(width: 12),
                          Expanded(child: statusField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
