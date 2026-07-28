import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../../shared/forms/app_field_config.dart';

class EmployeeFormSheet extends StatefulWidget {
  final Map<String, dynamic>? employee;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const EmployeeFormSheet({
    super.key,
    this.employee,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: (widget.employee?['name'] as String?) ?? '');
    _employeeCodeController = TextEditingController(text: (widget.employee?['employee_code'] as String?) ?? '');
    _phoneController = TextEditingController(text: (widget.employee?['phone'] as String?) ?? '');
    final salary = widget.employee?['salary'] as num?;
    _salaryController = TextEditingController(text: salary != null && salary > 0 ? salary.toString() : '');
    _emailController = TextEditingController(text: (widget.employee?['email'] as String?) ?? '');
    _status = (widget.employee?['status'] as String?) ?? 'active';
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
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? borderColor : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee == null ? 'إضافة موظف جديد' : 'تعديل بيانات الموظف',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أدخل تفاصيل الموظف بدقة',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('المعلومات الأساسية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'اسم الموظف *',
                              controller: _nameController,
                              fieldType: AppFieldType.generalText,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                Widget empCodeField = CustomTextField(
                                  label: 'رمز الموظف (الكود) *',
                                  controller: _employeeCodeController,
                                  fieldType: AppFieldType.generalText,
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                );
                                Widget phoneField = CustomTextField(
                                  label: 'رقم الهاتف',
                                  controller: _phoneController,
                                  fieldType: AppFieldType.phone,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                );
                                if (isMobile) {
                                  return Column(
                                    children: [
                                      empCodeField,
                                      const SizedBox(height: 16),
                                      phoneField,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: empCodeField),
                                    const SizedBox(width: 16),
                                    Expanded(child: phoneField),
                                  ],
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Financial Info Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_money_outlined, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text('التفاصيل الإدارية والمالية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                Widget salaryField = CustomTextField(
                                  label: 'الراتب الشهري (YER) *',
                                  controller: _salaryController,
                                  fieldType: AppFieldType.decimal,
                                  isRequired: true,
                                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                );
                                Widget statusField = DropdownButtonFormField<String>(
                                  initialValue: _status,
                                  decoration: InputDecoration(
                                    labelText: 'الحالة',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                                    DropdownMenuItem(value: 'on_leave', child: Text('في إجازة')),
                                    DropdownMenuItem(value: 'inactive', child: Text('موقوف')),
                                  ],
                                  onChanged: (v) => setState(() => _status = v ?? 'active'),
                                );
                                if (isMobile) {
                                  return Column(
                                    children: [
                                      salaryField,
                                      const SizedBox(height: 16),
                                      statusField,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: salaryField),
                                    const SizedBox(width: 16),
                                    Expanded(child: statusField),
                                  ],
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 60,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: widget.onClose,
                        child: const Text('إلغاء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _submit,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 24),
                            SizedBox(width: 10),
                            Text('حفظ الموظف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
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
