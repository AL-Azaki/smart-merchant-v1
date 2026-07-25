import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

class UnitFormSheet extends StatefulWidget {
  final Map<String, dynamic>? unit;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const UnitFormSheet({
    super.key,
    this.unit,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: widget.unit?['unit_name'] ?? '');
    _symbolController = TextEditingController(text: widget.unit?['unit_symbol'] ?? '');
    _descriptionController = TextEditingController(text: widget.unit?['unit_description'] ?? '');
    _isActive = widget.unit?['is_active'] ?? true;
    _isDefault = widget.unit?['is_default'] ?? false;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 500,
      height: MediaQuery.of(context).size.height * 0.7,
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.scale_outlined, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.unit == null ? 'إضافة وحدة جديدة' : 'تعديل الوحدة',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Body
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
                        labelText: 'اسم الوحدة *',
                        border: OutlineInputBorder(),
                        hintText: 'مثال: قطعة، كرتون، كيلو',
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم الوحدة' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _symbolController,
                            decoration: const InputDecoration(
                              labelText: 'الرمز / الاختصار *',
                              border: OutlineInputBorder(),
                              hintText: 'مثال: قطعة، كرتون، كغ',
                            ),
                            validator: (v) => v!.isEmpty ? 'يرجى إدخال رمز الوحدة' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'الوصف',
                              border: OutlineInputBorder(),
                              hintText: 'الوصف أو التفاصيل',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('وحدة نشطة', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: Colors.blue,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('افتراضية النظام', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _isDefault,
                            onChanged: (val) => setState(() => _isDefault = val),
                            activeColor: Colors.blue,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              children: [
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
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: 'حفظ',
                    icon: Icons.check,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
