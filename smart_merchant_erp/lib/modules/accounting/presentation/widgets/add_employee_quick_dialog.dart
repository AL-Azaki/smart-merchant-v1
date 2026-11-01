import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../hr/domain/repositories/hr_repository.dart';

class AddEmployeeQuickDialog extends ConsumerStatefulWidget {
  const AddEmployeeQuickDialog({super.key});

  @override
  ConsumerState<AddEmployeeQuickDialog> createState() => _AddEmployeeQuickDialogState();
}

class _AddEmployeeQuickDialogState extends ConsumerState<AddEmployeeQuickDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  final _jobTitleController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final salary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد راتب شهري أساسي صحيح أكبر من الصفر')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appContext = getIt<ApplicationContext>();
      final businessId = appContext.currentBusinessId;
      if (businessId.isEmpty) {
        throw Exception('لم يتم العثور على معرّف المنشأة النشطة');
      }

      final hrRepo = getIt<HrRepository>();
      final uuid = const Uuid().v4();
      final code = 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      final fullName = _nameController.text.trim();
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final companion = EmployeesCompanion(
        id: drift.Value(uuid),
        businessId: drift.Value(businessId),
        employeeCode: drift.Value(code),
        firstName: drift.Value(firstName),
        lastName: drift.Value(lastName),
        phone: drift.Value(_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()),
        hireDate: drift.Value(DateTime.now()),
        currencyId: const drift.Value('YER'),
        status: const drift.Value('Active'),
        salary: drift.Value(salary),
        syncStatus: const drift.Value('pending'),
      );

      await hrRepo.insertEmployee(companion);

      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الموظف وتحديد راتبه بنجاح')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة الموظف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة موظف جديد',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
                            ),
                            const Text(
                              'تسجيل موظف جديد وتحديد الراتب الأساسي الشهري',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // الاسم الكامل
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'اسم الموظف الكامل *',
                      hintText: 'مثال: محمد أحمد العولقي',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال اسم الموظف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // الراتب الشهري
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'الراتب الشهري الأساسي (ر.ي) *',
                      hintText: 'مثال: 150000',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      suffixText: 'ر.ي',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال الراتب الشهري';
                      }
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'الراتب يجب أن يكون أكبر من الصفر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // رقم الهاتف
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      hintText: 'مثال: 777123456',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // المسمى الوظيفي
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: InputDecoration(
                      labelText: 'المسمى الوظيفي (اختياري)',
                      hintText: 'مثال: محاسب، بائع، أمين مخزن',
                      prefixIcon: const Icon(Icons.work_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // زر الحفظ
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      _isSubmitting ? 'جاري الحفظ...' : 'حفظ الموظف',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
