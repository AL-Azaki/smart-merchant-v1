import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/di/getit_providers.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_card.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../../shared/forms/app_input_formatters.dart';
import '../../providers/catalog_provider.dart';
import '../../../../authentication/presentation/providers/session_provider.dart';
import '../../../../purchasing/presentation/providers/purchasing_provider.dart' show availableCurrenciesFutureProvider;
import '../../../../inventory/presentation/providers/inventory_provider.dart' show activeWarehousesProvider;
import 'category_form_sheet.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;
  final bool hideOpeningStock;

  const ProductFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.product,
    this.hideOpeningStock = false,
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
  late TextEditingController _openingQuantityController;

  String _categoryId = '';
  String _brandId = '';
  String _unitId = '';
  String _currencyId = '';
  String? _openingWarehouseId;
  bool _isActive = true;
  bool _showInStore = false;
  bool _trackStock = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['product_name']?.toString() ?? '');
    _nameEnController = TextEditingController(text: widget.product?['name_en']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description']?.toString() ?? '');
    _barcodeController = TextEditingController(text: widget.product?['barcode']?.toString() ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?['purchase_price']?.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?['selling_price']?.toString() ?? '');
    _openingQuantityController = TextEditingController(text: widget.product?['opening_quantity']?.toString() ?? '0');
    
    _categoryId = widget.product?['category_id']?.toString() ?? '';
    _brandId = widget.product?['brand_id']?.toString() ?? '';
    _unitId = widget.product?['unit_id']?.toString() ?? '';
    _currencyId = widget.product?['currency_id']?.toString() ?? '';
    _openingWarehouseId = widget.product?['opening_warehouse_id']?.toString();
    _isActive = (widget.product?['is_active'] as bool?) ?? true;
    _showInStore = (widget.product?['show_in_store'] as bool?) ?? false;
    _trackStock = (widget.product?['track_stock'] as bool?) ?? true;

    if (widget.product != null && widget.product!['image_url'] != null && widget.product!['image_url'].toString().isNotEmpty) {
      _selectedImage = File(widget.product!['image_url'].toString());
    }

    if (widget.product != null && widget.product!['id'] != null) {
      _loadProductDetails(widget.product!['id'].toString());
    }
  }

  Future<void> _loadProductDetails(String productId) async {
    setState(() => _isLoadingDetails = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final session = ref.read(sessionNotifierProvider);
      final businessId = session.businessId!;
      
      final images = await repo.getProductImagesByProductId(productId);
      if (images.isNotEmpty) {
        _selectedImage = File(images.first.imagePath);
      }
      
      final units = await repo.listProductUnitsByProductId(productId, businessId);
      if (units.isNotEmpty) {
        final baseUnit = units.firstWhere((u) => u.isBaseUnit, orElse: () => units.first);
        _unitId = baseUnit.unitId;
        _barcodeController.text = baseUnit.barcode ?? '';
        _purchasePriceController.text = baseUnit.purchasePrice.toString();
        _sellingPriceController.text = baseUnit.sellingPrice.toString();
      }
    } catch (e) {
      // ignore errors
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _openingQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التقاط الصورة: $e')));
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار صورة من المعرض'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveFileLocally(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final productDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await productDir.exists()) {
        await productDir.create(recursive: true);
      }
      final ext = p.extension(file.path);
      final newFileName = '${const Uuid().v4()}$ext';
      final savedFile = await file.copy(p.join(productDir.path, newFileName));
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار التصنيف')));
        return;
      }
      if (_unitId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الوحدة الافتراضية')));
        return;
      }

      String? imagePath;
      if (_selectedImage != null && !(_selectedImage!.path == widget.product?['image_url'])) {
        imagePath = await _saveFileLocally(_selectedImage!);
      } else if (_selectedImage != null) {
        imagePath = widget.product?['image_url']?.toString();
      }

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
        'show_in_store': _showInStore,
        'track_stock': _trackStock,
        'image_url': imagePath,
        'currency_id': _currencyId,
        'opening_warehouse_id': _openingWarehouseId,
        'opening_quantity': _openingQuantityController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    final isEdit = widget.product != null;

    if (_isLoadingDetails) {
      return AppModalSheet(
        title: isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد',
        icon: Icons.inventory_2_outlined,
        iconColor: Colors.indigo,
        onClose: widget.onClose,
        primaryLabel: 'حفظ',
        child: const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppModalSheet(
      title: isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد',
      icon: Icons.inventory_2_outlined,
      iconColor: Colors.indigo,
      onClose: widget.onClose,
      primaryLabel: 'حفظ',
      onPrimary: _submit,
      maxHeightFactor: 0.9,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. المعلومات الأساسية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final nameField = AppTextField(
                  label: 'اسم المنتج *',
                  hint: 'أدخل اسم المنتج بالعربي',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم المنتج' : null,
                );
                final nameEnField = AppTextField(
                  label: 'الاسم بالإنجليزية',
                  hint: 'Product name in English',
                  controller: _nameEnController,
                  inputFormatters: [AppInputFormatters.englishOnly],
                );

                if (isMobile) {
                  return Column(
                    children: [
                      nameField,
                      const SizedBox(height: 14),
                      nameEnField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 12),
                    Expanded(child: nameEnField),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final catDropdown = categoriesAsync.when(
                  data: (categories) {
                    final currentCategory = categories.cast<dynamic>().firstWhere((c) => c.id == _categoryId, orElse: () => null);
                    return AppTextField(
                      label: 'التصنيف *',
                      initialValue: currentCategory?.categoryName?.toString() ?? 'اختر التصنيف',
                      readOnly: true,
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => _CategorySelectionDialog(
                            categories: categories,
                            onSelected: (c) {
                              setState(() => _categoryId = c.id.toString());
                            },
                            onAddNew: () {
                              Navigator.pop(ctx);
                              showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (formCtx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                  child: CategoryFormSheet(
                                    onClose: () => Navigator.pop(formCtx),
                                    onSave: (data) async {
                                      try {
                                        final successId = await ref.read(categoriesNotifierProvider.notifier).saveCategory(data);
                                        if (successId != null && formCtx.mounted) {
                                          Navigator.pop(formCtx);
                                          setState(() => _categoryId = successId.toString());
                                        }
                                      } catch (e) {
                                        if (formCtx.mounted) {
                                          ScaffoldMessenger.of(formCtx).showSnackBar(const SnackBar(content: Text('تعذر حفظ التصنيف، حاول مرة أخرى')));
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('خطأ في تحميل التصنيفات'),
                );

                final brandDropdown = AppTextField(
                  label: 'العلامة التجارية',
                  initialValue: _brandId == 'b1' ? 'Apple' : (_brandId == 'b2' ? 'Samsung' : 'اختر العلامة'),
                  readOnly: true,
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (val) => setState(() => _brandId = val),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'b1', child: Text('Apple')),
                      PopupMenuItem(value: 'b2', child: Text('Samsung')),
                    ],
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      catDropdown,
                      const SizedBox(height: 14),
                      brandDropdown,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: catDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: brandDropdown),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            AppMultilineField(
              label: 'الوصف',
              hint: 'أدخل تفاصيل ومواصفات المنتج',
              controller: _descriptionController,
              lines: 2,
            ),
            
            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            
            const Text('2. التسعير والوحدة الافتراضية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final currenciesAsync = ref.watch(availableCurrenciesFutureProvider);
                
                final unitDropdown = unitsAsync.when(
                  data: (units) {
                    final currentUnit = units.cast<dynamic>().firstWhere((u) => u.id == _unitId, orElse: () => null);
                    return AppTextField(
                      label: 'الوحدة الافتراضية *',
                      initialValue: currentUnit?.unitName?.toString() ?? 'اختر الوحدة',
                      readOnly: true,
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (val) => setState(() => _unitId = val),
                        itemBuilder: (ctx) => units
                            .map((u) => PopupMenuItem(value: u.id, child: Text(u.unitName)))
                            .toList(),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('خطأ في تحميل الوحدات'),
                );
                
                final currencyDropdown = currenciesAsync.when(
                  data: (currencies) {
                    if (currencies.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final baseCurrency = currencies.firstWhere((c) => c.isBaseCurrency, orElse: () => currencies.first);
                    if (_currencyId.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _currencyId = baseCurrency.id);
                        }
                      });
                    }
                    final selectedCurr = currencies.firstWhere((c) => c.id == _currencyId, orElse: () => baseCurrency);
                    return AppTextField(
                      label: 'عملة التسعير *',
                      initialValue: '${selectedCurr.currencyNameAr} (${selectedCurr.currencyCode})',
                      readOnly: true,
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (val) => setState(() => _currencyId = val),
                        itemBuilder: (ctx) => currencies
                            .map((c) => PopupMenuItem(value: c.id, child: Text('${c.currencyNameAr} (${c.currencyCode})')))
                            .toList(),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('خطأ في تحميل العملات'),
                );

                final barcodeField = AppTextField(
                  label: 'الباركود',
                  hint: 'امسح أو أدخل الباركود',
                  controller: _barcodeController,
                  suffixIcon: const Icon(Icons.qr_code_scanner_outlined, size: 20),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      unitDropdown,
                      const SizedBox(height: 14),
                      currencyDropdown,
                      const SizedBox(height: 14),
                      barcodeField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: unitDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: currencyDropdown),
                    const SizedBox(width: 12),
                    Expanded(child: barcodeField),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final purchasePriceCard = AppCard(
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                  borderColor: Colors.red.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(14),
                  child: AppNumberField(
                    label: 'سعر الشراء / التكلفة *',
                    hint: '0.00',
                    controller: _purchasePriceController,
                  ),
                );
                final sellingPriceCard = AppCard(
                  backgroundColor: Colors.green.withValues(alpha: 0.05),
                  borderColor: Colors.green.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(14),
                  child: AppNumberField(
                    label: 'سعر البيع الافتراضي *',
                    hint: '0.00',
                    controller: _sellingPriceController,
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      purchasePriceCard,
                      const SizedBox(height: 14),
                      sellingPriceCard,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: purchasePriceCard),
                    const SizedBox(width: 12),
                    Expanded(child: sellingPriceCard),
                  ],
                );
              },
            ),
            
            if (widget.product?['id'] == null && !widget.hideOpeningStock) ...[
              const SizedBox(height: 24),
              Divider(color: borderColor),
              const SizedBox(height: 16),
              const Text('3. المخزون الافتتاحي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('كمية المنتج الموجودة لديك حالياً عند إدخاله للنظام', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 14),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  
                  final warehouseField = warehousesAsync.when(
                    data: (warehouses) {
                      if (warehouses.isEmpty) {
                        return const Text('لا توجد مستودعات');
                      }
                      if (_openingWarehouseId == null && warehouses.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _openingWarehouseId = warehouses.first.id);
                          }
                        });
                      }
                      final selectedWH = warehouses.firstWhere((w) => w.id == _openingWarehouseId, orElse: () => warehouses.first);
                      return AppTextField(
                        label: 'المستودع الافتتاحي',
                        initialValue: selectedWH.warehouseName,
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _openingWarehouseId = val),
                          itemBuilder: (ctx) => warehouses
                              .map((w) => PopupMenuItem(value: w.id, child: Text(w.warehouseName)))
                              .toList(),
                        ),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => Text('Error loading warehouses: $err'),
                  );
                  
                  final quantityField = AppNumberField(
                    label: 'الكمية الافتتاحية',
                    hint: '0',
                    controller: _openingQuantityController,
                  );

                  if (isMobile) {
                    return Column(
                      children: [
                        warehouseField,
                        const SizedBox(height: 14),
                        quantityField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 2, child: warehouseField),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: quantityField),
                    ],
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            const Text('4. صورة المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('التقط صورة للمنتج أو اخترها من المعرض', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: _selectedImage == null ? 110 : 200,
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(14),
                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.contain),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.8)),
                                  onPressed: _showImageSourceDialog,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.8)),
                                  onPressed: () => setState(() => _selectedImage = null),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 30),
                          const SizedBox(height: 6),
                          Text('إضافة صورة', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            const Text('5. البيع والمتجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('متاح للبيع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('يسمح ببيع هذا المنتج في نقاط البيع', style: TextStyle(color: Colors.grey, fontSize: 12)),
              value: _isActive,
              onChanged: (val) => setState(() => _isActive = val),
              activeThumbColor: Colors.green,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('إظهار في المتجر الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('نشر المنتج وعرضه في المتجر للعملاء', style: TextStyle(color: Colors.grey, fontSize: 12)),
              value: _showInStore,
              onChanged: (val) => setState(() => _showInStore = val),
              activeThumbColor: Colors.green,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelectionDialog extends StatefulWidget {
  final List<dynamic> categories;
  final void Function(dynamic category) onSelected;
  final VoidCallback onAddNew;

  const _CategorySelectionDialog({
    required this.categories,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  State<_CategorySelectionDialog> createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<_CategorySelectionDialog> {
  late List<dynamic> _filteredCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  void _filter(String query) {
    setState(() {
      final q = query.toLowerCase();
      _filteredCategories = widget.categories.where((c) {
        return (c.categoryName?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('اختيار تصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: '',
              hint: 'بحث باسم التصنيف...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredCategories.length,
                separatorBuilder: (ctx, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = _filteredCategories[index];
                  return ListTile(
                    title: Text(c.categoryName?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      widget.onSelected(c);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAddNew,
                icon: const Icon(Icons.add),
                label: const Text('إضافة تصنيف جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
