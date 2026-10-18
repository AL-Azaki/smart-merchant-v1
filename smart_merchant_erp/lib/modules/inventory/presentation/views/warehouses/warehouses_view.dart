import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../../app/di/getit_instance.dart';
import '../../../../../kernel/core/application_context.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../widgets/inventory_section_header.dart';
import '../../widgets/inventory_empty_state.dart';
import '../../providers/inventory_provider.dart';
import '../../../domain/repositories/inventory_repository.dart';
import 'widgets/warehouse_form_dialog.dart';

class WarehousesView extends ConsumerStatefulWidget {
  final bool showAppBar;

  const WarehousesView({super.key, this.showAppBar = false});

  @override
  ConsumerState<WarehousesView> createState() => _WarehousesViewState();
}

class _WarehousesViewState extends ConsumerState<WarehousesView> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'default'

  Future<void> _setDefaultWarehouse(Warehouse warehouse) async {
    try {
      final db = getIt<AppDatabase>();
      final repo = getIt<InventoryRepository>();
      final appContext = getIt<ApplicationContext>();
      final businessId = appContext.currentBusinessId;

      // 1. Unset existing default
      await (db.update(db.warehouses)
            ..where((w) => w.businessId.equals(businessId)))
          .write(const WarehousesCompanion(isDefault: drift.Value(false)));

      // 2. Set this one as default
      await repo.updateWarehouse(
        WarehousesCompanion(
          id: drift.Value(warehouse.id),
          businessId: drift.Value(businessId),
          branchId: drift.Value(warehouse.branchId),
          warehouseName: drift.Value(warehouse.warehouseName),
          warehouseCode: drift.Value(warehouse.warehouseCode),
          isDefault: const drift.Value(true),
          isActive: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      ref.invalidate(activeWarehousesProvider);
      ref.invalidate(warehousesStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعيين "${warehouse.warehouseName}" كمخزن رئيسي بنجاح'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التعيين: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _toggleWarehouseActive(Warehouse warehouse) async {
    try {
      final repo = getIt<InventoryRepository>();
      final appContext = getIt<ApplicationContext>();
      final businessId = appContext.currentBusinessId;
      final newStatus = !warehouse.isActive;

      await repo.updateWarehouse(
        WarehousesCompanion(
          id: drift.Value(warehouse.id),
          businessId: drift.Value(businessId),
          branchId: drift.Value(warehouse.branchId),
          warehouseName: drift.Value(warehouse.warehouseName),
          warehouseCode: drift.Value(warehouse.warehouseCode),
          isDefault: drift.Value(warehouse.isDefault && newStatus),
          isActive: drift.Value(newStatus),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      ref.invalidate(activeWarehousesProvider);
      ref.invalidate(warehousesStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'تم تفعيل المخزن بنجاح'
                  : 'تم تعطيل المخزن بنجاح',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تغيير الحالة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B);
    final textSecondary = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final warehousesAsync = ref.watch(warehousesStreamProvider);

    Widget content = Column(
      children: [
        if (!widget.showAppBar)
          InventorySectionHeader(
            title: 'المستودعات والمخازن',
            subtitle: 'إدارة مواقع التخزين، تعيين المخزن الافتراضي، وإدارة الفروع',
            icon: Icons.warehouse_rounded,
            action: FilledButton.icon(
              onPressed: () => WarehouseFormDialog.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة مخزن جديد',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

        // Search & Filters Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'البحث باسم المخزن أو كود المستودع...',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    filled: true,
                    fillColor: surface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('الكل', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'active', label: Text('النشطة', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'default', label: Text('الرئيسي', style: TextStyle(fontSize: 12))),
                ],
                selected: {_statusFilter},
                onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
                  selectedForegroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),

        // Warehouses List
        Expanded(
          child: warehousesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'حدث خطأ في تحميل المخازن: $err',
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
            data: (warehouses) {
              final filtered = warehouses.where((w) {
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final matchName = w.warehouseName.toLowerCase().contains(q);
                  final matchCode = w.warehouseCode.toLowerCase().contains(q);
                  if (!matchName && !matchCode) {
                    return false;
                  }
                }
                if (_statusFilter == 'active' && !w.isActive) {
                  return false;
                }
                if (_statusFilter == 'default' && !w.isDefault) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return InventoryEmptyState(
                  icon: Icons.warehouse_outlined,
                  title: 'لا توجد مخازن مطابقة',
                  message: warehouses.isEmpty
                      ? 'لم يتم إنشاء أي مخزن بعد. أضف المخزن الرئيسي لبدء إدارة المخزون.'
                      : 'لا توجد مخازن تطابق معايير البحث والفلترة المحددة.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final wh = filtered[index];
                  return _buildWarehouseCard(
                    wh,
                    isDark,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: const Text(
            'المستودعات والمخازن',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          backgroundColor: surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'إضافة مخزن جديد',
              onPressed: () => WarehouseFormDialog.show(context),
            ),
          ],
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildWarehouseCard(
    Warehouse wh,
    bool isDark,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wh.isDefault ? const Color(0xFF3B82F6).withOpacity(0.5) : borderColor,
          width: wh.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: wh.isDefault
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: wh.isDefault
                  ? const Color(0xFF3B82F6).withOpacity(0.12)
                  : (wh.isActive
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.warehouse_rounded,
              color: wh.isDefault
                  ? const Color(0xFF3B82F6)
                  : (wh.isActive ? const Color(0xFF10B981) : Colors.grey),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      wh.warehouseName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        wh.warehouseCode,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    if (wh.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'المخزن الرئيسي',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      wh.address != null && wh.address!.isNotEmpty
                          ? wh.address!
                          : 'الموقع غير محدد',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      wh.isActive ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                      size: 14,
                      color: wh.isActive ? const Color(0xFF10B981) : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      wh.isActive ? 'متاح للعمليات' : 'معطل مؤقتاً',
                      style: TextStyle(
                        fontSize: 12,
                        color: wh.isActive ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'edit') {
                WarehouseFormDialog.show(context, warehouse: wh);
              } else if (val == 'default') {
                _setDefaultWarehouse(wh);
              } else if (val == 'toggle') {
                _toggleWarehouseActive(wh);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('تعديل البيانات', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              if (!wh.isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('تعيين كمخزن رئيسي', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      wh.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: wh.isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      wh.isActive ? 'تعطيل المخزن' : 'تفعيل المخزن',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
