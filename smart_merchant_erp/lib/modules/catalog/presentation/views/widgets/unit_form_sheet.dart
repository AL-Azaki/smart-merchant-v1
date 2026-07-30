import 'package:flutter/material.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class UnitFormSheet extends StatefulWidget {
  final Map<String, dynamic>? unit;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const UnitFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.unit,
  });

  @override
  State<UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<UnitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?['unit_name']?.toString() ?? '');
    _symbolController = TextEditingController(text: widget.unit?['unit_symbol']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.unit?['unit_description']?.toString() ?? '');
    _isActive = (widget.unit?['is_active'] as bool?) ?? true;
    _isDefault = (widget.unit?['is_default'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.unit?['id'],
        'unit_name': _nameController.text,
        'unit_symbol': _symbolController.text,
        'unit_description': _descriptionController.text,
        'is_active': _isActive,
        'is_default': _isDefault,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.unit != null;

    return AppModalSheet(
      title: isEdit ? 'تعديل الوحدة' : 'إضافة وحدة جديدة',
      icon: Icons.scale_outlined,
      iconColor: Colors.blue,
      onClose: widget.onClose,
      primaryLabel: 'حفظ',
      onPrimary: _submit,
      maxHeightFactor: 0.7,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم الوحدة *',
              hint: 'مثال: قطعة، كرتون، كيلو',
              controller: _nameController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الوحدة' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'الرمز / الاختصار *',
                    hint: 'مثال: قطعة، كرتون، كغ',
                    controller: _symbolController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال رمز الوحدة' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'الوصف',
                    hint: 'الوصف أو التفاصيل',
                    controller: _descriptionController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('وحدة نشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeThumbColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('افتراضية النظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val),
                    activeThumbColor: Colors.blue,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
