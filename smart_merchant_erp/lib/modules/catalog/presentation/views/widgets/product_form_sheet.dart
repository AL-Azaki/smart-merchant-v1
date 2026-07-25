import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../../shared/forms/app_field_config.dart';
import '../../../../../shared/forms/app_input_formatters.dart';

class ProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const ProductFormSheet({
    super.key,
    this.product,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionController;

  String _categoryId = '';
  String _brandId = '';
  bool _isActive = true;
  bool _trackStock = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['product_name'] ?? '');
    _nameEnController = TextEditingController(text: widget.product?['name_en'] ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _categoryId = widget.product?['category_id'] ?? '';
    _brandId = widget.product?['brand_id'] ?? '';
    _isActive = widget.product?['is_active'] ?? true;
    _trackStock = widget.product?['track_stock'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.product?['id'],
        'product_name': _nameController.text,
        'name_en': _nameEnController.text,
        'description': _descriptionController.text,
        'category_id': _categoryId,
        'brand_id': _brandId,
        'is_active': _isActive,
        'track_stock': _trackStock,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 850,
      height: MediaQuery.of(context).size.height * 0.9,
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text('إدخال سريع وسلس عبر شاشة اللمس', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.red),
                  style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. المعلومات الأساسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'اسم المنتج *',
                            controller: _nameController,
                            fieldType: AppFieldType.generalText,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CustomTextField(
                            label: 'الاسم بالإنجليزية',
                            controller: _nameEnController,
                            fieldType: AppFieldType.generalText,
                            inputFormatters: [AppInputFormatters.englishOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoryId.isEmpty ? null : _categoryId,
                            decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'cat1', child: Text('تصنيف 1')),
                              DropdownMenuItem(value: 'cat2', child: Text('تصنيف 2')),
                            ],
                            onChanged: (v) => setState(() => _categoryId = v ?? ''),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _brandId.isEmpty ? null : _brandId,
                            decoration: const InputDecoration(labelText: 'العلامة التجارية', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'brand1', child: Text('علامة 1')),
                              DropdownMenuItem(value: 'brand2', child: Text('علامة 2')),
                            ],
                            onChanged: (v) => setState(() => _brandId = v ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('نشط'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      title: const Text('تتبع المخزون'),
                      value: _trackStock,
                      onChanged: (v) => setState(() => _trackStock = v),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  text: 'حفظ المنتج',
                  icon: Icons.check,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
