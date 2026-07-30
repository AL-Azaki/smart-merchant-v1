import 'package:flutter/material.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class CategoryFormSheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const CategoryFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.category,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?['name']?.toString() ?? '');
    _nameEnController = TextEditingController(text: widget.category?['name_en']?.toString() ?? '');
    _isActive = (widget.category?['is_active'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.category?['id'],
        'category_name': _nameController.text,
        'name_en': _nameEnController.text,
        'is_active': _isActive,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return AppModalSheet(
      title: isEdit ? 'تعديل الفئة' : 'إضافة فئة جديدة',
      icon: Icons.account_tree_outlined,
      iconColor: Colors.green,
      onClose: widget.onClose,
      primaryLabel: 'حفظ',
      onPrimary: _submit,
      maxHeightFactor: 0.65,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم الفئة (عربي) *',
              hint: 'مثال: المواد الغذائية',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الفئة' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'اسم الفئة (إنجليزي)',
              hint: 'e.g. Groceries',
              controller: _nameEnController,
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('فئة نشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeThumbColor: Colors.green,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
