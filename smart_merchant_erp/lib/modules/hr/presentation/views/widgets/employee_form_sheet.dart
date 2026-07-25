import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

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
  late TextEditingController _jobTitleController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;

  String _warehouseName = 'المستودع الرئيسي';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee?['name'] ?? '');
    _jobTitleController = TextEditingController(text: widget.employee?['job_title'] ?? '');
    _phoneController = TextEditingController(text: widget.employee?['phone'] ?? '');
    _salaryController = TextEditingController(text: (widget.employee?['salary'] ?? '').toString());
    _warehouseName = widget.employee?['warehouse_name'] ?? 'المستودع الرئيسي';
    _status = widget.employee?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.employee?['id'],
        'name': _nameController.text,
        'job_title': _jobTitleController.text,
        'phone': _phoneController.text,
        'salary': double.tryParse(_salaryController.text) ?? 0,
        'warehouse_name': _warehouseName,
        'status': _status,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 500,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.employee == null ? 'إضافة موظف جديد' : 'تعديل بيانات الموظف',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          
          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الموظف *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم الموظف' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _jobTitleController,
                            decoration: const InputDecoration(
                              labelText: 'المسمى الوظيفي *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'يرجى إدخال المسمى الوظيفي' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _warehouseName,
                            decoration: const InputDecoration(
                              labelText: 'المستودع/الفرع',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'المستودع الرئيسي', child: Text('المستودع الرئيسي')),
                              DropdownMenuItem(value: 'مستودع الفروع', child: Text('مستودع الفروع')),
                            ],
                            onChanged: (v) => setState(() => _warehouseName = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salaryController,
                            decoration: const InputDecoration(
                              labelText: 'الراتب الشهري (YER)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'الحالة',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('نشط')),
                              DropdownMenuItem(value: 'on_leave', child: Text('في إجازة')),
                              DropdownMenuItem(value: 'inactive', child: Text('موقوف')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'حفظ',
                            onPressed: _submit,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
