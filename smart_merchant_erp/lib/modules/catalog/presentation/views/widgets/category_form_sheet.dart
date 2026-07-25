import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

class CategoryFormSheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const CategoryFormSheet({
    super.key,
    this.category,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: widget.category?['name'] ?? '');
    _nameEnController = TextEditingController(text: widget.category?['name_en'] ?? '');
    _isActive = widget.category?['is_active'] ?? true;
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
        'name': _nameController.text,
        'name_en': _nameEnController.text,
        'is_active': _isActive,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 500,
      height: MediaQuery.of(context).size.height * 0.6,
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
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_tree_outlined, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.category == null ? 'إضافة فئة جديدة' : 'تعديل الفئة',
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
                        labelText: 'اسم الفئة (عربي) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم الفئة' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameEnController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الفئة (إنجليزي)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('فئة نشطة', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
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
