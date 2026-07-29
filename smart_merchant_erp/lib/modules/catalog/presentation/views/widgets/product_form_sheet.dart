import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../../shared/forms/app_field_config.dart';
import '../../../../../shared/forms/app_input_formatters.dart';
import '../../providers/catalog_provider.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../../authentication/presentation/providers/session_provider.dart';
import '../../../../../app/di/getit_providers.dart';
import 'category_form_sheet.dart';
import '../../../../purchasing/presentation/providers/purchasing_provider.dart' show availableCurrenciesFutureProvider;
import '../../../../inventory/presentation/providers/inventory_provider.dart' show activeWarehousesProvider;

class ProductFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;
  final bool hideOpeningStock;

  const ProductFormSheet({
    super.key,
    this.product,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: widget.product?['product_name'] ?? '');
    _nameEnController = TextEditingController(text: widget.product?['name_en'] ?? '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _barcodeController = TextEditingController(text: widget.product?['barcode'] ?? '');
    _purchasePriceController = TextEditingController(text: widget.product?['purchase_price']?.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?['selling_price']?.toString() ?? '');
    _openingQuantityController = TextEditingController(text: widget.product?['opening_quantity']?.toString() ?? '0');
    
    _categoryId = widget.product?['category_id'] ?? '';
    _brandId = widget.product?['brand_id'] ?? '';
    _unitId = widget.product?['unit_id'] ?? '';
    _currencyId = widget.product?['currency_id'] ?? '';
    _openingWarehouseId = widget.product?['opening_warehouse_id'];
    _isActive = widget.product?['is_active'] ?? true;
    _showInStore = widget.product?['show_in_store'] ?? false;
    _trackStock = widget.product?['track_stock'] ?? true;

    if (widget.product != null && widget.product!['image_url'] != null && widget.product!['image_url'].toString().isNotEmpty) {
      _selectedImage = File(widget.product!['image_url']);
    }

    if (widget.product != null && widget.product!['id'] != null) {
      _loadProductDetails(widget.product!['id']);
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
    } catch(e) {
      // ignore errors, let user fill manually if fetch fails
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
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
    showModalBottomSheet(
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

  void _submit() async {
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
        imagePath = widget.product?['image_url'];
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 850),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _isLoadingDetails 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
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
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('إدخال سريع وسلس عبر شاشة اللمس', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                          final isMobile = MediaQuery.of(context).size.width < 600;
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
                          final isMobile = MediaQuery.of(context).size.width < 600;
                          Widget catDropdown = categoriesAsync.when(
                            data: (categories) {
                              final currentCategory = categories.cast<dynamic>().firstWhere((c) => c.id == _categoryId, orElse: () => null);
                              return InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => _CategorySelectionDialog(
                                      categories: categories,
                                      onSelected: (c) {
                                        setState(() => _categoryId = c.id);
                                      },
                                      onAddNew: () {
                                        Navigator.pop(ctx);
                                        showDialog(
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
                                                    setState(() => _categoryId = successId);
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
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'التصنيف *', border: OutlineInputBorder()),
                                  child: Text(
                                    currentCategory?.categoryName ?? 'اختر التصنيف',
                                    style: TextStyle(color: currentCategory == null ? Colors.grey : null, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const Text('خطأ في تحميل التصنيفات'),
                          );
                          Widget brandDropdown = DropdownButtonFormField<String>(
                            value: _brandId.isEmpty ? null : _brandId,
                            decoration: const InputDecoration(labelText: 'العلامة التجارية', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'b1', child: Text('Apple', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'b2', child: Text('Samsung', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (v) => setState(() => _brandId = v ?? ''),
                            isExpanded: true, // Fixes overflow for long brand names
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
                          final isMobile = MediaQuery.of(context).size.width < 600;
                          final currenciesAsync = ref.watch(availableCurrenciesFutureProvider);
                          
                          Widget unitDropdown = unitsAsync.when(
                            data: (units) => DropdownButtonFormField<String>(
                              value: units.any((u) => u.id == _unitId) ? _unitId : null,
                              decoration: const InputDecoration(labelText: 'الوحدة الافتراضية *', border: OutlineInputBorder()),
                              items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.unitName, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _unitId = v ?? ''),
                              validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                              isExpanded: true,
                            ),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const Text('خطأ في تحميل الوحدات'),
                          );
                          
                          Widget currencyDropdown = currenciesAsync.when(
                            data: (currencies) {
                               if (currencies.isEmpty) return const SizedBox.shrink();
                               final baseCurrency = currencies.firstWhere((c) => c.isBaseCurrency, orElse: () => currencies.first);
                               if (_currencyId.isEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                     if (mounted) setState(() => _currencyId = baseCurrency.id);
                                  });
                               }
                               return DropdownButtonFormField<String>(
                                 value: currencies.any((c) => c.id == _currencyId) ? _currencyId : baseCurrency.id,
                                 decoration: const InputDecoration(labelText: 'عملة التسعير *', border: OutlineInputBorder()),
                                 items: currencies.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.currencyNameAr} (${c.currencyCode})', overflow: TextOverflow.ellipsis))).toList(),
                                 onChanged: (v) => setState(() => _currencyId = v ?? ''),
                                 isExpanded: true,
                               );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => const Text('خطأ في تحميل العملات'),
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
                                currencyDropdown,
                                const SizedBox(height: 16),
                                barcodeField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: unitDropdown),
                              const SizedBox(width: 16),
                              Expanded(child: currencyDropdown),
                              const SizedBox(width: 16),
                              Expanded(child: barcodeField),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = MediaQuery.of(context).size.width < 600;
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

                      if (widget.product?['id'] == null && !widget.hideOpeningStock) ...[
                        const Text('3. المخزون الافتتاحي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('كمية المنتج الموجودة لديك حالياً عند إدخاله للنظام', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = MediaQuery.of(context).size.width < 600;
                          
                          Widget warehouseField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('المستودع', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              warehousesAsync.when(
                                data: (warehouses) {
                                  if (warehouses.isEmpty) return const Text('لا توجد مستودعات');
                                  if (_openingWarehouseId == null && warehouses.isNotEmpty) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) setState(() => _openingWarehouseId = warehouses.first.id);
                                    });
                                  }
                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _openingWarehouseId ?? warehouses.first.id,
                                    hint: const Text('المستودع الرئيسي', overflow: TextOverflow.ellipsis),
                                    items: warehouses.map((w) => DropdownMenuItem(
                                      value: w.id,
                                      child: Text(w.warehouseName, overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _openingWarehouseId = val);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                  );
                                },
                                loading: () => const CircularProgressIndicator(),
                                error: (err, stack) => Text('Error loading warehouses: $err'),
                              ),
                            ],
                          );
                          
                          Widget quantityField = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الكمية الافتتاحية', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              CustomTextField(
                                label: '',
                                controller: _openingQuantityController,
                                fieldType: AppFieldType.decimal,
                              ),
                            ],
                          );

                          if (isMobile) {
                            return Column(
                              children: [
                                warehouseField,
                                const SizedBox(height: 16),
                                quantityField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(flex: 2, child: warehouseField),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: quantityField),
                            ],
                          );
                        }
                      ),
                        
                        const SizedBox(height: 32),
                        Divider(color: borderColor),
                        const SizedBox(height: 32),
                      ],
                      
                      const Text('4. صورة المنتج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('التقط صورة للمنتج أو اخترها من المعرض', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _showImageSourceDialog,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: _selectedImage == null ? 120 : 240,
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
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
                                            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.8)),
                                            onPressed: _showImageSourceDialog,
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.8)),
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
                                    Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                                    const SizedBox(height: 8),
                                    Text('إضافة صورة', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Divider(color: borderColor),
                      const SizedBox(height: 32),

                      const Text('5. البيع والمتجر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('متاح للبيع', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('يسمح ببيع هذا المنتج في نقاط البيع', style: TextStyle(color: Colors.grey)),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeColor: Colors.green,
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('إظهار في المتجر الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('نشر المنتج وعرضه في المتجر للعملاء', style: TextStyle(color: Colors.grey)),
                        value: _showInStore,
                        onChanged: (val) => setState(() => _showInStore = val),
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
                            Text('حفظ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}

class _CategorySelectionDialog extends StatefulWidget {
  final List<dynamic> categories;
  final Function(dynamic) onSelected;
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
  String _searchQuery = '';
  late List<dynamic> _filteredCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase();
      _filteredCategories = widget.categories.where((c) {
        return c.categoryName.toLowerCase().contains(q);
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
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث باسم التصنيف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredCategories.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = _filteredCategories[index];
                  return ListTile(
                    title: Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
