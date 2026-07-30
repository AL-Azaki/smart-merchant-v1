import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class WarehouseFormSheet extends StatefulWidget {
  final Map<String, dynamic>? warehouse;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const WarehouseFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.warehouse,
  });

  @override
  State<WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<WarehouseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _addressController;
  bool _isActive = true;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse?['warehouse_name']?.toString() ?? '');
    _codeController = TextEditingController(text: widget.warehouse?['warehouse_code']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.warehouse?['address']?.toString() ?? '');
    _isActive = (widget.warehouse?['is_active'] as bool?) ?? true;
    _isDefault = (widget.warehouse?['is_default'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.warehouse?['id'],
        'warehouse_name': _nameController.text,
        'warehouse_code': _codeController.text,
        'address': _addressController.text,
        'is_active': _isActive,
        'is_default': _isDefault,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final isEdit = widget.warehouse != null;

    return AppModalSheet(
      title: isEdit ? 'تعديل المستودع' : 'إضافة مستودع جديد',
      icon: Icons.warehouse_outlined,
      iconColor: Colors.purple,
      onClose: widget.onClose,
      primaryLabel: 'حفظ',
      onPrimary: _submit,
      maxHeightFactor: 0.75,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم المستودع *',
              hint: 'مثال: المستودع الرئيسي',
              controller: _nameController,
              prefixIcon: const Icon(Icons.business),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المستودع' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'رمز المستودع *',
              hint: 'مثال: WH-01',
              controller: _codeController,
              prefixIcon: const Icon(Icons.numbers),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رمز المستودع' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'العنوان',
              hint: 'عنوان المستودع ورقم المنطقة',
              controller: _addressController,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('مستودع نشط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeThumbColor: Colors.purple,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('المستودع الافتراضي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val),
                    activeThumbColor: Colors.purple,
                    contentPadding: EdgeInsets.zero,
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
