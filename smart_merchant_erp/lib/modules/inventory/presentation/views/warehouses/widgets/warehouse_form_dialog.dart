import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../../../app/di/getit_instance.dart';
import '../../../../../../kernel/core/application_context.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../domain/repositories/inventory_repository.dart';
import '../../../providers/inventory_provider.dart';

class WarehouseFormDialog extends ConsumerStatefulWidget {
  final Warehouse? warehouse;

  const WarehouseFormDialog({super.key, this.warehouse});

  static Future<bool?> show(BuildContext context, {Warehouse? warehouse}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WarehouseFormDialog(warehouse: warehouse),
    );
  }

  @override
  ConsumerState<WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends ConsumerState<WarehouseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _addressController;

  String? _selectedBranchId;
  List<BranchEntity> _branches = [];
  bool _isLoadingBranches = true;
  late bool _isDefault;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final w = widget.warehouse;
    _nameController = TextEditingController(text: w?.warehouseName ?? '');
    _codeController = TextEditingController(text: w?.warehouseCode ?? '');
    _addressController = TextEditingController(text: w?.address ?? '');
    _selectedBranchId = w?.branchId;
    _isDefault = w?.isDefault ?? false;
    _isActive = w?.isActive ?? true;

    _loadBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final db = getIt<AppDatabase>();
      final appContext = getIt<ApplicationContext>();
      final businessId = appContext.currentBusinessId;

      var branches = await (db.select(db.branches)
            ..where((b) => b.businessId.equals(businessId)))
          .get();

      // Ensure at least one default branch exists if table is empty
      if (branches.isEmpty) {
        final defaultBranchId = 'branch-$businessId';
        await db.into(db.branches).insertOnConflictUpdate(
          BranchesCompanion.insert(
            id: defaultBranchId,
            businessId: businessId,
            branchName: 'الفرع الرئيسي',
            branchCode: 'MAIN',
            isActive: const drift.Value(true),
          ),
        );
        branches = await (db.select(db.branches)
              ..where((b) => b.businessId.equals(businessId)))
            .get();
      }

      if (mounted) {
        setState(() {
          _branches = branches;
          if (_selectedBranchId == null ||
              !branches.any((b) => b.id == _selectedBranchId)) {
            _selectedBranchId = branches.first.id;
          }
          if (widget.warehouse == null && _codeController.text.isEmpty) {
            _codeController.text = 'WH-${(branches.length * 10 + 1).toString().padLeft(2, '0')}';
          }
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
          _errorMessage = 'تعذر تحميل الفروع: $e';
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedBranchId == null || _selectedBranchId!.isEmpty) {
      setState(() => _errorMessage = 'يرجى اختيار الفرع التابع له المخزن');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = getIt<InventoryRepository>();
      final db = getIt<AppDatabase>();
      final appContext = getIt<ApplicationContext>();
      final businessId = appContext.currentBusinessId;
      final isEdit = widget.warehouse != null;

      // If set as default, clear default flag from other warehouses in this business
      if (_isDefault) {
        await (db.update(db.warehouses)
              ..where((w) => w.businessId.equals(businessId)))
            .write(const WarehousesCompanion(isDefault: drift.Value(false)));
      }

      if (isEdit) {
        await repo.updateWarehouse(
          WarehousesCompanion(
            id: drift.Value(widget.warehouse!.id),
            businessId: drift.Value(businessId),
            branchId: drift.Value(_selectedBranchId!),
            warehouseName: drift.Value(_nameController.text.trim()),
            warehouseCode: drift.Value(_codeController.text.trim()),
            address: drift.Value(
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            ),
            isDefault: drift.Value(_isDefault),
            isActive: drift.Value(_isActive),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      } else {
        const uuid = Uuid();
        await repo.insertWarehouse(
          WarehousesCompanion.insert(
            id: uuid.v4(),
            businessId: businessId,
            branchId: _selectedBranchId!,
            warehouseName: _nameController.text.trim(),
            warehouseCode: _codeController.text.trim(),
            address: drift.Value(
              _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            ),
            isDefault: drift.Value(_isDefault),
            isActive: drift.Value(_isActive),
            createdAt: drift.Value(DateTime.now()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      // Invalidate relevant providers for immediate synchronization
      ref.invalidate(activeWarehousesProvider);
      ref.invalidate(warehousesStreamProvider);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'تم تحديث بيانات المخزن بنجاح' : 'تم إضافة المخزن الجديد بنجاح',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'حدث خطأ أثناء الحفظ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isEdit = widget.warehouse != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.warehouse_rounded,
                          color: Color(0xFF3B82F6),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'تعديل بيانات المخزن' : 'إضافة مخزن جديد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'حدد تفاصيل موقع التخزين والفرع التابع له',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        color: textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Warehouse Name Field
                  Text(
                    'اسم المخزن / المستودع *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'مثال: المخزن الرئيسي، مستودع البضاعة 1...',
                      hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم المخزن';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Warehouse Code and Branch in Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'كود المخزن *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                hintText: 'مثال: WH-01',
                                hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'يرجى إدخال كود المخزن';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الفرع التابع له *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _isLoadingBranches
                                ? const Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: _selectedBranchId,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.business_rounded, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: _branches
                                        .map(
                                          (b) => DropdownMenuItem(
                                            value: b.id,
                                            child: Text(
                                              b.branchName,
                                              style: TextStyle(fontSize: 13, color: textPrimary),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedBranchId = val),
                                    validator: (v) => v == null ? 'اختر الفرع' : null,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Physical Address / Location
                  Text(
                    'العنوان / الموقع الجغرافي (اختياري)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'مثال: صنعاء - شارع الزبيري - جوار...',
                      hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Switches: Default Warehouse & Active
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'تعيين كمخزن رئيسي وافتراضي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'المخزن الافتراضي يُحدد تلقائياً في فواتير المشتريات والمبيعات والجرد',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          value: _isDefault,
                          activeColor: const Color(0xFF3B82F6),
                          onChanged: (val) => setState(() => _isDefault = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'حالة المخزن (نشط ومتاح للعمليات)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'إذا تم التعطيل لن يظهر هذا المخزن في إدخال الفواتير الجديدة',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          value: _isActive,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  isEdit ? 'حفظ التعديلات' : 'إضافة المخزن',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
