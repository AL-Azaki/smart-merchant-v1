import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/di/getit_providers.dart';
import '../../../../../kernel/storage/app_database.dart' show Category, Unit;
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../../shared/forms/app_input_formatters.dart';
import '../../providers/catalog_provider.dart';
import '../../../../authentication/presentation/providers/session_provider.dart';
import '../../../../purchasing/presentation/providers/purchasing_provider.dart'
    show availableCurrenciesFutureProvider;
import '../../../../inventory/presentation/providers/inventory_provider.dart'
    show activeWarehousesProvider;
import 'category_form_sheet.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onClose;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final Future<void> Function(Map<String, dynamic> data)? onSaveAndAdd;
  final String? initialCategoryId;
  final bool hideOpeningStock;

  const ProductFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.product,
    this.onSaveAndAdd,
    this.initialCategoryId,
    this.hideOpeningStock = false,
  });

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}


class _AdditionalUnitRow {
  final String? id;
  String unitId;
  final TextEditingController factorController;
  final TextEditingController barcodeController;
  final TextEditingController purchasePriceController;
  final TextEditingController sellingPriceController;

  _AdditionalUnitRow({
    required this.unitId,
    required double factor,
    this.id,
    String? barcode,
    double purchasePrice = 0.0,
    double sellingPrice = 0.0,
  })  : factorController = TextEditingController(
          text: factor > 0
              ? (factor % 1 == 0
                  ? factor.toInt().toString()
                  : factor.toString())
              : '1',
        ),
        barcodeController = TextEditingController(text: barcode ?? ''),
        purchasePriceController = TextEditingController(
          text: purchasePrice > 0 ? purchasePrice.toString() : '',
        ),
        sellingPriceController = TextEditingController(
          text: sellingPrice > 0 ? sellingPrice.toString() : '',
        );

  void dispose() {
    factorController.dispose();
    barcodeController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
  }
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
  bool _showInStore = true;
  bool _trackStock = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingDetails = false;
  bool _detailsLoadFailed = false;
  String? _originalImagePath;
  bool _isSaving = false;
  int _savedCount = 0;
  final _nameFocus = FocusNode();
  final _nameFieldKey = GlobalKey();
  final List<_AdditionalUnitRow> _additionalUnits = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.product?['product_name']?.toString() ?? '',
    );
    _nameEnController = TextEditingController(
      text: widget.product?['name_en']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?['description']?.toString() ?? '',
    );
    _barcodeController = TextEditingController(
      text: widget.product?['barcode']?.toString() ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product?['purchase_price']?.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.product?['selling_price']?.toString() ?? '',
    );
    _openingQuantityController = TextEditingController(
      text: widget.product?['opening_quantity']?.toString() ?? '0',
    );

    _categoryId =
        widget.product?['category_id']?.toString() ??
        widget.initialCategoryId ??
        '';
    _brandId = widget.product?['brand_id']?.toString() ?? '';
    _unitId = widget.product?['unit_id']?.toString() ?? '';
    _currencyId = widget.product?['currency_id']?.toString() ?? '';
    _openingWarehouseId = widget.product?['opening_warehouse_id']?.toString();
    _isActive = (widget.product?['is_active'] as bool?) ?? true;
    _showInStore = (widget.product?['show_in_store'] as bool?) ?? true;
    _trackStock = (widget.product?['track_stock'] as bool?) ?? true;

    if (widget.product != null &&
        widget.product!['image_url'] != null &&
        widget.product!['image_url'].toString().isNotEmpty) {
      _originalImagePath = widget.product!['image_url'].toString();
      _selectedImage = File(_originalImagePath!);
    }

    if (widget.product != null && widget.product!['id'] != null) {
      _loadProductDetails(widget.product!['id'].toString());
    }
  }

  Future<void> _loadProductDetails(String productId) async {
    setState(() {
      _isLoadingDetails = true;
      _detailsLoadFailed = false;
    });
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final session = ref.read(sessionNotifierProvider);
      final businessId = session.businessId!;

      final images = await repo.getProductImagesByProductId(productId);
      if (!mounted) {
        return;
      }
      if (images.isNotEmpty) {
        _originalImagePath = images.first.imagePath;
        _selectedImage = File(_originalImagePath!);
      }

      final units = await repo.listProductUnitsByProductId(
        productId,
        businessId,
      );
      if (!mounted) {
        return;
      }
      if (units.isNotEmpty) {
        final baseUnit = units.firstWhere(
          (u) => u.isBaseUnit,
          orElse: () => units.first,
        );
        _unitId = baseUnit.unitId;
        _barcodeController.text = baseUnit.barcode ?? '';
        _purchasePriceController.text = baseUnit.purchasePrice.toString();
        _sellingPriceController.text = baseUnit.sellingPrice.toString();

        for (final row in _additionalUnits) {
          row.dispose();
        }
        _additionalUnits.clear();
        for (final u in units.where((u) => !u.isBaseUnit)) {
          _additionalUnits.add(
            _AdditionalUnitRow(
              id: u.id,
              unitId: u.unitId,
              factor: u.conversionFactor,
              barcode: u.barcode,
              purchasePrice: u.purchasePrice,
              sellingPrice: u.sellingPrice,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _detailsLoadFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _openingQuantityController.dispose();
    for (final row in _additionalUnits) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في التقاط الصورة: $e')));
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
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
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

  String _defaultCategoryId() {
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    if (categories.isEmpty) {
      return '';
    }
    return categories
        .firstWhere(
          (c) => ['عام', 'عامة'].contains(c.categoryName.trim()),
          orElse: () => categories.first,
        )
        .id;
  }

  String _defaultUnitId() {
    final units = ref.read(unitsNotifierProvider).value ?? [];
    if (units.isEmpty) {
      return '';
    }
    return units
        .firstWhere(
          (u) => ['قطعة', 'حبة', 'حبه'].contains(u.unitName.trim()),
          orElse: () => units.first,
        )
        .id;
  }

  String? _validateAmount(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'أدخل سعر البيع' : null;
    }
    final amount = double.tryParse(value);
    return amount == null || !amount.isFinite || amount < 0
        ? 'أدخل رقماً صحيحاً أو عشرياً موجباً'
        : null;
  }

  Future<void> _submit({bool addAnother = false}) async {
    if (_isSaving || _isLoadingDetails) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final categoryId = _categoryId.isEmpty ? _defaultCategoryId() : _categoryId;
    final unitId = _unitId.isEmpty ? _defaultUnitId() : _unitId;
    if (unitId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف وحدة بيع من الإعدادات أولاً')),
      );
      return;
    }
    final currencies = ref.read(availableCurrenciesFutureProvider).value ?? [];
    final currencyId = _currencyId.isNotEmpty
        ? _currencyId
        : currencies.isEmpty
        ? null
        : currencies
              .firstWhere(
                (c) => c.isBaseCurrency,
                orElse: () => currencies.first,
              )
              .id;
    final warehouses = ref.read(activeWarehousesProvider).value ?? [];
    final warehouseId =
        _openingWarehouseId ??
        (warehouses.isEmpty ? null : warehouses.first.id);
    if (!widget.hideOpeningStock &&
        widget.product == null &&
        (double.tryParse(_openingQuantityController.text) ?? 0) > 0 &&
        warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر مستودعاً لحفظ الكمية الافتتاحية')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? imagePath;
      if (_selectedImage != null) {
        imagePath = _selectedImage!.path == _originalImagePath
            ? _selectedImage!.path
            : await _saveFileLocally(_selectedImage!);
        if (imagePath == null) {
          throw StateError('image save failed');
        }
      }
      final data = <String, dynamic>{
        'id': widget.product?['id'],
        'sku': widget.product?['sku'],
        'product_name': _nameController.text.trim(),
        'name_en': _nameEnController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category_id': categoryId,
        'brand_id': _brandId,
        'unit_id': unitId,
        'barcode': _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        'purchase_price': _purchasePriceController.text.trim().isEmpty
            ? '0'
            : _purchasePriceController.text.trim(),
        'selling_price': _sellingPriceController.text.trim(),
        'is_active': _isActive,
        'show_in_store': _showInStore,
        'track_stock': _trackStock,
        'image_url': imagePath,
        'currency_id': currencyId,
        'opening_warehouse_id': warehouseId,
        'opening_quantity': widget.hideOpeningStock
            ? '0'
            : _openingQuantityController.text,
        'additional_units': _additionalUnits
            .where((u) => u.unitId.isNotEmpty)
            .map((u) => {
                  'id': u.id,
                  'unit_id': u.unitId,
                  'conversion_factor':
                      double.tryParse(u.factorController.text.trim()) ?? 1.0,
                  'barcode': u.barcodeController.text.trim().isEmpty
                      ? null
                      : u.barcodeController.text.trim(),
                  'purchase_price':
                      double.tryParse(u.purchasePriceController.text.trim()) ??
                          0.0,
                  'selling_price':
                      double.tryParse(u.sellingPriceController.text.trim()) ??
                          0.0,
                })
            .toList(),
      };
      await (addAnother ? widget.onSaveAndAdd!(data) : widget.onSave(data));
      if (!mounted) {
        return;
      }
      if (addAnother) {
        _formKey.currentState!.reset();
        setState(() {
          _savedCount++;
          _unitId = unitId;
          _currencyId = currencyId ?? '';
          _openingWarehouseId = warehouseId;
          _nameController.clear();
          _nameEnController.clear();
          _descriptionController.clear();
          _barcodeController.clear();
          _purchasePriceController.clear();
          _sellingPriceController.clear();
          _openingQuantityController.text = '0';
          _selectedImage = null;
          _originalImagePath = null;
          _isActive = true;
          _showInStore = true;
          for (final row in _additionalUnits) {
            row.dispose();
          }
          _additionalUnits.clear();
        });
        _nameFocus.requestFocus();
        final fieldContext = _nameFieldKey.currentContext;
        if (fieldContext != null && fieldContext.mounted) {
          await Scrollable.ensureVisible(
            fieldContext,
            duration: const Duration(milliseconds: 180),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حفظ المنتج. بياناتك محفوظة هنا، حاول مرة أخرى.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  void _addAdditionalUnit(List<Unit> allUnits) {
    final usedUnitIds = {
      _unitId,
      ..._additionalUnits.map((u) => u.unitId),
    };
    final available = allUnits.where((u) => !usedUnitIds.contains(u.id)).toList();
    final selectedUnitId = available.isNotEmpty ? available.first.id : (allUnits.isNotEmpty ? allUnits.first.id : '');
    final basePurchase = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final baseSelling = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    const factor = 12.0;

    setState(() {
      _additionalUnits.add(
        _AdditionalUnitRow(
          unitId: selectedUnitId.toString(),
          factor: factor,
          purchasePrice: basePurchase * factor,
          sellingPrice: baseSelling * factor,
        ),
      );
    });
  }

  void _removeAdditionalUnit(int index) {
    setState(() {
      final row = _additionalUnits.removeAt(index);
      row.dispose();
    });
  }

  void _generateBarcodeForUnit(_AdditionalUnitRow row) {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final generated = '29${now.substring(now.length - 10)}';
    setState(() {
      row.barcodeController.text = generated;
    });
  }

  void _recomputeRowPrices(_AdditionalUnitRow row) {
    final factor = double.tryParse(row.factorController.text.trim()) ?? 1.0;
    final basePurchase = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final baseSelling = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    setState(() {
      if (basePurchase > 0) {
        row.purchasePriceController.text = (basePurchase * factor).toStringAsFixed(2);
      }
      if (baseSelling > 0) {
        row.sellingPriceController.text = (baseSelling * factor).toStringAsFixed(2);
      }
    });
  }

  Widget _buildAdditionalUnitCard(
    int index,
    _AdditionalUnitRow row,
    List<Unit> units,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'وحدة تعبئة #${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _recomputeRowPrices(row),
                icon: const Icon(Icons.calculate_outlined, size: 16),
                label: const Text('حساب الأسعار تلقائياً', style: TextStyle(fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                tooltip: 'حذف هذه الوحدة',
                onPressed: () => _removeAdditionalUnit(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fields([
            _select(
              label: 'نوع الوحدة *',
              value: row.unitId.isNotEmpty ? row.unitId : null,
              options: {for (final u in units) u.id.toString(): u.unitName.toString()},
              validator: (v) => v == null ? 'اختر الوحدة' : null,
              onChanged: (v) => setState(() => row.unitId = v ?? ''),
            ),
            AppNumberField(
              label: 'معامل التحويل (كم حبة تحتوي؟) *',
              controller: row.factorController,
              hint: 'مثال: 12 أو 24',
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) {
                  return 'أدخل معامل تحويل أكبر من 0';
                }
                return null;
              },
            ),
          ]),
          const SizedBox(height: 10),
          _fields([
            AppTextField(
              label: 'باركود هذه الوحدة',
              controller: row.barcodeController,
              hint: 'امسح أو ولّد باركود الكرتون',
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                tooltip: 'توليد باركود تلقائي',
                onPressed: () => _generateBarcodeForUnit(row),
              ),
            ),
            AppNumberField(
              label: 'سعر شراء هذه الوحدة',
              controller: row.purchasePriceController,
              hint: 'اختياري',
              validator: (v) => _validateAmount(v),
            ),
          ]),
          const SizedBox(height: 10),
          AppNumberField(
            label: 'سعر بيع هذه الوحدة *',
            controller: row.sellingPriceController,
            hint: 'سعر البيع للعميل',
            validator: (v) => _validateAmount(v, required: true),
          ),
        ],
      ),
    );
  }

  Widget _fields(List<Widget> children, {int columns = 2}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 600
            ? columns
            : constraints.maxWidth >= 340
            ? 2
            : 1;
        final width = (constraints.maxWidth - (count - 1) * 12) / count;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }

  Widget _select({
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('$label:$value'),
          initialValue: options.containsKey(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            hintText: 'اختر',
          ),
          items: options.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          validator: validator,
          onChanged: _isSaving ? null : onChanged,
        ),
      ],
    );
  }

  Future<void> _chooseCategory(List<Category> categories) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CategorySelectionDialog(
        categories: categories,
        onSelected: (c) => setState(() => _categoryId = c.id.toString()),
        onAddNew: () {
          Navigator.pop(ctx);
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (formCtx) => Dialog(
              backgroundColor: Colors.transparent,
              child: CategoryFormSheet(
                onClose: () => Navigator.pop(formCtx),
                onSave: (data) async {
                  final id = await ref
                      .read(categoriesNotifierProvider.notifier)
                      .saveCategory(data);
                  if (id != null && formCtx.mounted && mounted) {
                    Navigator.pop(formCtx);
                    setState(() => _categoryId = id);
                  } else if (formCtx.mounted) {
                    ScaffoldMessenger.of(formCtx).showSnackBar(
                      const SnackBar(
                        content: Text('تعذر حفظ التصنيف، حاول مرة أخرى'),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final unitsAsync = ref.watch(unitsNotifierProvider);
    final currenciesAsync = ref.watch(availableCurrenciesFutureProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final categories = categoriesAsync.value ?? [];
    final units = unitsAsync.value ?? [];
    final currencies = currenciesAsync.value ?? [];
    final warehouses = warehousesAsync.value ?? [];
    final unitId = _unitId.isEmpty && !isEdit ? _defaultUnitId() : _unitId;
    final currencyId = _currencyId.isNotEmpty
        ? _currencyId
        : currencies.isEmpty
        ? null
        : currencies
              .firstWhere(
                (c) => c.isBaseCurrency,
                orElse: () => currencies.first,
              )
              .id;
    final warehouseId =
        _openingWarehouseId ??
        (warehouses.isEmpty ? null : warehouses.first.id);
    final ready =
        !_isLoadingDetails &&
        !categoriesAsync.isLoading &&
        !unitsAsync.isLoading &&
        !currenciesAsync.isLoading &&
        (isEdit || widget.hideOpeningStock || !warehousesAsync.isLoading);
    final hasError =
        _detailsLoadFailed ||
        categoriesAsync.hasError ||
        unitsAsync.hasError ||
        currenciesAsync.hasError ||
        (!isEdit && !widget.hideOpeningStock && warehousesAsync.hasError);
    final canRepeat = !isEdit && widget.onSaveAndAdd != null;
    final effectiveCategoryId =
        _categoryId.isEmpty && !isEdit ? _defaultCategoryId() : _categoryId;
    final currentCategory = categories
        .where((c) => c.id == effectiveCategoryId)
        .firstOrNull;

    return PopScope(
      canPop: !_isSaving,
      child: AppModalSheet(
        title: isEdit ? 'تعديل المنتج' : 'إضافة منتج',
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.primary,
        primaryColor: AppColors.primary,
        onClose: _isSaving ? () {} : widget.onClose,
        primaryLabel: canRepeat ? 'حفظ وإضافة التالي' : 'حفظ المنتج',
        onPrimary: ready && !hasError
            ? () => _submit(addAnother: canRepeat)
            : null,
        secondaryLabel: canRepeat ? 'حفظ وإغلاق' : null,
        onSecondary: ready && !hasError ? () => _submit() : null,
        cancelLabel: 'إغلاق',
        isLoading: _isSaving,
        maxWidth: 880,
        maxHeightFactor: 0.94,
        showDragHandle: false,
        padKeyboard: false,
        borderRadius: BorderRadius.circular(20),
        child: _isLoadingDetails
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: AbsorbPointer(
                  absorbing: _isSaving,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _savedCount > 0
                            ? 'تم حفظ $_savedCount منتج • جاهز للمنتج التالي'
                            : 'أدخل البيانات الأساسية، وأكمل التفاصيل عند الحاجة.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!ready)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'تعذر تحميل خيارات المنتج. أعد المحاولة.',
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_detailsLoadFailed) {
                                    _loadProductDetails(
                                      widget.product!['id'].toString(),
                                    );
                                  }
                                  ref.invalidate(categoriesNotifierProvider);
                                  ref.invalidate(unitsNotifierProvider);
                                  ref.invalidate(
                                    availableCurrenciesFutureProvider,
                                  );
                                  ref.invalidate(activeWarehousesProvider);
                                },
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      AppTextField(
                        key: _nameFieldKey,
                        label: 'اسم المنتج *',
                        hint: 'مثال: حليب كامل الدسم 1 لتر',
                        controller: _nameController,
                        focusNode: _nameFocus,
                        autofocus: !isEdit,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'أدخل اسم المنتج'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _fields([
                        AppTextField(
                          key: ValueKey(
                            'category:$effectiveCategoryId:${currentCategory?.categoryName}',
                          ),
                          label: 'التصنيف *',
                          readOnly: true,
                          initialValue: currentCategory?.categoryName,
                          hint: categories.isEmpty
                              ? 'أضف تصنيفاً'
                              : 'اختر التصنيف',
                          suffixIcon: const Icon(Icons.expand_more),
                          validator: (_) =>
                              effectiveCategoryId.isEmpty ? 'اختر التصنيف' : null,
                          onTap: () => _chooseCategory(categories),
                        ),
                        _select(
                          label: 'وحدة البيع *',
                          value: unitId,
                          options: {for (final u in units) u.id: u.unitName},
                          validator: (v) => v == null ? 'اختر الوحدة' : null,
                          onChanged: (v) => setState(() => _unitId = v ?? ''),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _fields([
                        AppNumberField(
                          label: 'سعر الشراء',
                          controller: _purchasePriceController,
                          validator: (v) => _validateAmount(v),
                        ),
                        AppNumberField(
                          label: 'سعر البيع *',
                          controller: _sellingPriceController,
                          validator: (v) => _validateAmount(v, required: true),
                        ),
                        if (!isEdit && !widget.hideOpeningStock)
                          AppNumberField(
                            label: 'الكمية الافتتاحية',
                            controller: _openingQuantityController,
                            validator: (v) => _validateAmount(v),
                          ),
                      ], columns: !isEdit && !widget.hideOpeningStock ? 3 : 2),
                      const SizedBox(height: 14),
                      _fields([
                        if (currencies.isNotEmpty)
                          _select(
                            label: 'العملة',
                            value: currencyId,
                            options: {
                              for (final c in currencies)
                                c.id: '${c.currencyNameAr} (${c.currencyCode})',
                            },
                            onChanged: (v) =>
                                setState(() => _currencyId = v ?? ''),
                          ),
                        if (!isEdit && !widget.hideOpeningStock)
                          _select(
                            label: 'المستودع',
                            value: warehouseId,
                            options: {
                              for (final w in warehouses) w.id: w.warehouseName,
                            },
                            onChanged: (v) =>
                                setState(() => _openingWarehouseId = v),
                          ),
                      ]),
                      const SizedBox(height: 16),
                      // Multi-Unit / Packaging Section
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'وحدات التعبئة والتجزئة الإضافية (كرتون، باكت...)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _addAdditionalUnit(units),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('إضافة وحدة أخرى'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الوحدة الأساسية الحالية هي أصغر وحدة تباع بها السلعة. يمكنك هنا إضافة عبوات كبرى (مثل كرتون أو درزن) مع تحديد كم حبة تحتوي عليها وسعرها وباركود خاص بها.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_additionalUnits.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              for (int i = 0; i < _additionalUnits.length; i++)
                                _buildAdditionalUnitCard(
                                  i,
                                  _additionalUnits[i],
                                  units,
                                  theme,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _showInStore
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _showInStore
                                ? theme.colorScheme.primary.withValues(alpha: 0.35)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.storefront_rounded,
                            color: _showInStore
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 26,
                          ),
                          title: const Text(
                            'إظهار في المتجر الإلكتروني',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'نشر هذا المنتج في المتجر الإلكتروني ليظهر لجميع العملاء فور المزامنة',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _showInStore,
                          onChanged: (v) => setState(() => _showInStore = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 16),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: const Text(
                          'تفاصيل إضافية',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'الباركود، الوصف، الصورة وخيارات البيع',
                          style: TextStyle(fontSize: 12),
                        ),
                        children: [
                          _fields([
                            AppTextField(
                              label: 'الباركود',
                              hint: 'امسح أو أدخل الباركود',
                              controller: _barcodeController,
                              textInputAction: TextInputAction.next,
                            ),
                            AppTextField(
                              label: 'الاسم بالإنجليزية',
                              controller: _nameEnController,
                              inputFormatters: [AppInputFormatters.englishOnly],
                              textInputAction: TextInputAction.next,
                            ),
                          ]),
                          const SizedBox(height: 14),
                          AppMultilineField(
                            label: 'الوصف',
                            controller: _descriptionController,
                            lines: 2,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (_selectedImage != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              OutlinedButton.icon(
                                onPressed: _showImageSourceDialog,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                ),
                                label: Text(
                                  _selectedImage == null
                                      ? 'إضافة صورة'
                                      : 'تغيير الصورة',
                                ),
                              ),
                              if (_selectedImage != null)
                                IconButton(
                                  tooltip: 'إزالة الصورة',
                                  onPressed: () =>
                                      setState(() => _selectedImage = null),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('متاح للبيع'),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('إظهار في المتجر الإلكتروني'),
                            value: _showInStore,
                            onChanged: (v) => setState(() => _showInStore = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CategorySelectionDialog extends StatefulWidget {
  final List<Category> categories;
  final void Function(Category category) onSelected;
  final VoidCallback onAddNew;

  const _CategorySelectionDialog({
    required this.categories,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  State<_CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<_CategorySelectionDialog> {
  late List<Category> _filteredCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
  }

  void _filter(String query) {
    setState(() {
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
                const Text(
                  'اختيار تصنيف',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
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
                    title: Text(
                      c.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                label: const Text(
                  'إضافة تصنيف جديد',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
