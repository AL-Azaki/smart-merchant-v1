import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../../shared/design_system/widgets/app_card.dart';
import '../../../../../../shared/design_system/widgets/app_empty_state.dart';
import '../../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../../../database/daos/inventory_dao.dart' show StockBalanceView;
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../application/usecases/save_stock_count_usecase.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/stock_counts_provider.dart';

class StockCountFormSheet extends ConsumerStatefulWidget {
  final StockCount? existingCount;
  final List<StockCountItem>? existingItems;

  const StockCountFormSheet({
    super.key,
    this.existingCount,
    this.existingItems,
  });

  @override
  ConsumerState<StockCountFormSheet> createState() => _StockCountFormSheetState();
}

class _StockCountLine {
  final String id;
  final String productUnitId;
  final String productId;
  final String productName;
  final String productCode;
  final double expectedQuantity;
  double? physicalQty;

  _StockCountLine({
    required this.id,
    required this.productUnitId,
    required this.productId,
    required this.expectedQuantity,
    this.productName = 'منتج',
    this.productCode = '',
    this.physicalQty,
  });

  double get discrepancy => (physicalQty ?? expectedQuantity) - expectedQuantity;
}

class _StockCountFormSheetState extends ConsumerState<StockCountFormSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();

  String? _selectedWarehouseId;
  final List<_StockCountLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    if (widget.existingCount != null) {
      _selectedWarehouseId = widget.existingCount!.warehouseId;
      _notesController.text = widget.existingCount!.notes ?? '';
      
      if (widget.existingItems != null) {
        for (final item in widget.existingItems!) {
          _lines.add(_StockCountLine(
            id: item.id,
            productUnitId: item.productUnitId,
            productId: item.productId,
            expectedQuantity: item.expectedQuantity,
            physicalQty: item.countedQuantity,
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _addLine(StockBalanceView view) {
    if (_lines.any((l) => l.productUnitId == view.productUnit.id)) {
      return;
    }
    setState(() {
      _lines.add(_StockCountLine(
        id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
        productUnitId: view.productUnit.id,
        productId: view.product.id,
        productName: view.product.productName,
        productCode: view.product.productCode,
        expectedQuantity: view.inventory.quantity,
      ));
      _searchController.clear();
      _searchFocus.unfocus();
    });
  }

  void _removeLine(String id) {
    setState(() {
      _lines.removeWhere((l) => l.id == id);
    });
  }

  Future<void> _handleSave() async {
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المستودع أولاً.')),
      );
      return;
    }

    final validLines = _lines.where((l) => l.physicalQty != null).toList();
    if (validLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الجرد الفعلي لمنتج واحد على الأقل.')),
      );
      return;
    }

    final command = SaveStockCountCommand(
      id: widget.existingCount?.id,
      warehouseId: _selectedWarehouseId!,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      items: validLines.map((l) => SaveStockCountItemCommand(
        productId: l.productId,
        productUnitId: l.productUnitId,
        expectedQuantity: l.expectedQuantity,
        countedQuantity: l.physicalQty!,
        differenceQuantity: l.discrepancy,
      )).toList(),
    );

    try {
      await ref.read(stockCountsNotifierProvider.notifier).saveDraft(command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الجرد بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final isEdit = widget.existingCount != null;

    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final warehouses = warehousesAsync.valueOrNull ?? [];
    final selectedWH = warehouses.cast<dynamic>().firstWhere((w) => w.id == _selectedWarehouseId, orElse: () => null);

    return AppModalSheet(
      title: isEdit ? 'تعديل مسودة جرد' : 'جرد مخزون جديد',
      icon: Icons.inventory_2_outlined,
      iconColor: Colors.blue,
      onClose: () => Navigator.pop(context),
      primaryLabel: 'حفظ كمسودة',
      onPrimary: _handleSave,
      maxHeightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'المستودع *',
                  initialValue: selectedWH?.warehouseName?.toString() ?? 'اختر المستودع',
                  readOnly: true,
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: isEdit ? null : (val) {
                      setState(() {
                        if (_selectedWarehouseId != val) {
                          _lines.clear();
                          _selectedWarehouseId = val;
                        }
                      });
                    },
                    itemBuilder: (ctx) => warehouses
                        .map((w) => PopupMenuItem(value: w.id, child: Text(w.warehouseName)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppMultilineField(
                  label: 'الملاحظات',
                  hint: 'أدخل ملاحظات الجرد الدوري...',
                  controller: _notesController,
                  lines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_selectedWarehouseId != null) ...[
            Text(
              'بحث عن منتج لإضافته',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              label: '',
              hint: 'بحث باسم المنتج أو الباركود...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
            if (_searchQuery.isNotEmpty) _buildSearchResultsList(borderColor),
            const SizedBox(height: 16),
          ],

          // Items Counted
          Text(
            'عناصر الجرد الدوري (${_lines.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),

          _lines.isEmpty
              ? const AppEmptyState(
                  title: 'لا يوجد منتجات في قائمة الجرد',
                  subtitle: 'اختر المستودع وابحث عن المنتجات لإدراجها والجرد عليها',
                  icon: Icons.inventory_outlined,
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) {
                    final line = _lines[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'الكمية الدفترية: ${line.expectedQuantity}',
                                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _removeLine(line.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppNumberField(
                                  label: 'الجرد الفعلي',
                                  hint: '0',
                                  initialValue: line.physicalQty?.toString() ?? '',
                                  onChanged: (val) {
                                    setState(() {
                                      line.physicalQty = double.tryParse(val);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (line.physicalQty != null)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('الفرق', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      Text(
                                        '${line.discrepancy > 0 ? '+' : ''}${line.discrepancy.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: line.discrepancy != 0
                                              ? (line.discrepancy > 0 ? Colors.green : Colors.red)
                                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(Color borderColor) {
    final inventoryAsync = ref.watch(warehouseStockBalancesProvider(_selectedWarehouseId!));

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: inventoryAsync.when(
        data: (balances) {
          final results = balances.where((b) {
            final matchesSearch = b.product.productName.contains(_searchQuery) ||
                (b.product.productCode.contains(_searchQuery)) ||
                (b.productUnit.barcode?.contains(_searchQuery) ?? false);
            return matchesSearch;
          }).toList();

          if (results.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('لا توجد منتجات مطابقة في هذا المستودع.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return ListTile(
                title: Text(item.product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('الباركود: ${item.productUnit.barcode ?? "-"} | الدفترية: ${item.inventory.quantity}', style: const TextStyle(fontSize: 11)),
                onTap: () => _addLine(item),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(12.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('خطأ: $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
        ),
      ),
    );
  }
}
