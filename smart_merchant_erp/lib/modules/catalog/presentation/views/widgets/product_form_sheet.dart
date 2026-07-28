import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../../shared/forms/app_field_config.dart';
import '../../../../../shared/forms/app_input_formatters.dart';
import '../../providers/catalog_provider.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;

  String _categoryId = '';
  String _brandId = '';
  String _unitId = '';
  bool _isActive = true;
  bool _trackStock = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['product_name'] ?? '');
    _nameEnController = TextEditingController(text: widget.product?['name_en'] ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _barcodeController = TextEditingController(text: widget.product?['barcode'] ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?['purchase_price']?.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?['selling_price']?.toString() ?? '');
    
    _categoryId = widget.product?['category_id'] ?? '';
    _brandId = widget.product?['brand_id'] ?? '';
    _unitId = widget.product?['unit_id'] ?? '';
    _isActive = widget.product?['is_active'] ?? true;
    _trackStock = widget.product?['track_stock'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
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
        'unit_id': _unitId,
        'barcode': _barcodeController.text,
        'purchase_price': _purchasePriceController.text,
        'selling_price': _sellingPriceController.text,
        'is_active': _isActive,
        'track_stock': _trackStock,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 850),
      width: double.infinity,
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
              border: Border(bottom: BorderSide(color: borderColor)),
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
                        const Text('إدخال سريع وسلس عبر شاشة اللمس', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            children: [
                              CustomTextField(
                                label: 'اسم المنتج *',
                                controller: _nameController,
                                fieldType: AppFieldType.generalText,
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'الاسم بالإنجليزية',
                                controller: _nameEnController,
                                fieldType: AppFieldType.generalText,
                                inputFormatters: [AppInputFormatters.englishOnly],
                              ),
                            ],
                          );
                        }
                        return Row(
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
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        Widget catDropdown = categoriesAsync.when(
                          data: (categories) => DropdownButtonFormField<String>(
                            value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                            decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.categoryName))).toList(),
                            onChanged: (v) => setState(() => _categoryId = v ?? ''),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const Text('خطأ في تحميل التصنيفات'),
                        );
                        Widget brandDropdown = DropdownButtonFormField<String>(
                          value: _brandId.isEmpty ? null : _brandId,
                          decoration: const InputDecoration(labelText: 'الماركة (Brand)', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'b1', child: Text('Apple')),
                            DropdownMenuItem(value: 'b2', child: Text('Samsung')),
                          ],
                          onChanged: (v) => setState(() => _brandId = v ?? ''),
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              catDropdown,
                              const SizedBox(height: 16),
                              brandDropdown,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: catDropdown),
                            const SizedBox(width: 20),
                            Expanded(child: brandDropdown),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Divider(color: borderColor),
                    const SizedBox(height: 32),
                    
                    const Text('2. التسعير والوحدة الافتراضية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        Widget unitDropdown = unitsAsync.when(
                          data: (units) => DropdownButtonFormField<String>(
                            value: units.any((u) => u.id == _unitId) ? _unitId : null,
                            decoration: const InputDecoration(labelText: 'الوحدة الافتراضية *', border: OutlineInputBorder()),
                            items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.unitName))).toList(),
                            onChanged: (v) => setState(() => _unitId = v ?? ''),
                            validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const Text('خطأ في تحميل الوحدات'),
                        );
                        Widget barcodeField = CustomTextField(
                          label: 'الباركود',
                          controller: _barcodeController,
                          fieldType: AppFieldType.generalText,
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              unitDropdown,
                              const SizedBox(height: 16),
                              barcodeField,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: unitDropdown),
                            const SizedBox(width: 20),
                            Expanded(child: barcodeField),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        Widget purchasePriceCard = Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سعر الشراء / التكلفة *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: '',
                                controller: _purchasePriceController,
                                fieldType: AppFieldType.decimal,
                                isRequired: true,
                              ),
                            ],
                          ),
                        );
                        Widget sellingPriceCard = Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('سعر البيع الافتراضي *', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: '',
                                controller: _sellingPriceController,
                                fieldType: AppFieldType.decimal,
                                isRequired: true,
                              ),
                            ],
                          ),
                        );

                        if (isMobile) {
                          return Column(
                            children: [
                              purchasePriceCard,
                              const SizedBox(height: 16),
                              sellingPriceCard,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: purchasePriceCard),
                            const SizedBox(width: 20),
                            Expanded(child: sellingPriceCard),
                          ],
                        );
                      }
                    ),
                    
                    const SizedBox(height: 32),
                    Divider(color: borderColor),
                    const SizedBox(height: 32),
                    
                    const Text('3. صورة المنتج (واجهة عرض)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, style: BorderStyle.solid, width: 2),
                        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 32, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('رفع صورة', style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
              color: surfaceColor,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _submit,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 24),
                          SizedBox(width: 12),
                          Text('حفظ المنتج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}
