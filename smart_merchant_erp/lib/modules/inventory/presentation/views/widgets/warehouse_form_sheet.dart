import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

class WarehouseFormSheet extends StatefulWidget {
  final Map<String, dynamic>? warehouse;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const WarehouseFormSheet({
    super.key,
    this.warehouse,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: widget.warehouse?['warehouse_name'] ?? '');
    _codeController = TextEditingController(text: widget.warehouse?['warehouse_code'] ?? '');
    _addressController = TextEditingController(text: widget.warehouse?['address'] ?? '');
    _isActive = widget.warehouse?['is_active'] ?? true;
    _isDefault = widget.warehouse?['is_default'] ?? false;
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

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
              border: Border(bottom: BorderSide(color: borderColor)),
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
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warehouse_outlined, color: Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.warehouse == null ? 'إضافة مستودع جديد' : 'تعديل المستودع',
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
                      decoration: InputDecoration(
                        labelText: 'اسم المستودع *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'مثال: المستودع الرئيسي',
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم المستودع' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'رمز المستودع *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'مثال: WH-01',
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال رمز المستودع' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'العنوان',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'عنوان المستودع',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('مستودع نشط', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: Colors.purple,
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile(
                            title: const Text('المستودع الافتراضي', style: TextStyle(fontWeight: FontWeight.bold)),
                            value: _isDefault,
                            onChanged: (val) => setState(() => _isDefault = val),
                            activeColor: Colors.purple,
                            contentPadding: EdgeInsets.zero,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
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
