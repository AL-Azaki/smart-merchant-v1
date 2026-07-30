import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../../shared/design_system/widgets/app_empty_state.dart';
import '../../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../../../../database/daos/inventory_dao.dart' show StockBalanceView;
import '../../../providers/inventory_provider.dart';

class StockAdjustmentFormSheet extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const StockAdjustmentFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
  });

  @override
  ConsumerState<StockAdjustmentFormSheet> createState() => _StockAdjustmentFormSheetState();
}

class _AdjustmentLine {
  final String id;
  final StockBalanceView stockView;
  double? physicalQty;

  _AdjustmentLine({
    required this.id,
    required this.stockView,
    this.physicalQty,
  });

  double get systemQty => stockView.inventory.quantity;
  double get discrepancy => (physicalQty ?? 0) - systemQty;
}

class _StockAdjustmentFormSheetState extends ConsumerState<StockAdjustmentFormSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String? _selectedWarehouseId;
  final List<_AdjustmentLine> _lines = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _addLine(StockBalanceView view) {
    if (_lines.any((l) => l.stockView.productUnit.id == view.productUnit.id)) {
      return;
    }
    setState(() {
      _lines.add(_AdjustmentLine(
        id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
        stockView: view,
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

  void _handleSave() {
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
    
    widget.onSave({
      'adjustment_number': 'SA-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'date': DateTime.now().toIso8601String(),
      'notes': _notesController.text,
      'warehouse_id': _selectedWarehouseId,
      'lines': validLines.map((l) => {
        'product_id': l.stockView.product.id,
        'product_unit_id': l.stockView.productUnit.id,
        'system_qty': l.systemQty,
        'physical_qty': l.physicalQty,
        'discrepancy': l.discrepancy,
      }).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final warehouses = warehousesAsync.valueOrNull ?? [];

    List<StockBalanceView> availableStocks = [];
    if (_selectedWarehouseId != null) {
      final stockAsync = ref.watch(warehouseStockBalancesProvider(_selectedWarehouseId!));
      availableStocks = stockAsync.valueOrNull ?? [];
    }

    final selectedWH = warehouses.cast<dynamic>().firstWhere((w) => w.id == _selectedWarehouseId, orElse: () => null);

    return AppModalSheet(
      title: 'جرد تصحيحي جديد',
      icon: Icons.inventory_outlined,
      iconColor: Colors.amber,
      onClose: widget.onClose,
      primaryLabel: 'حفظ وتسوية الفروقات',
      onPrimary: _handleSave,
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
                    onSelected: (val) {
                      setState(() {
                        _selectedWarehouseId = val;
                        _lines.clear();
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
                child: AppTextField(
                  label: 'سبب التعديل / البيان',
                  hint: 'أدخل ملاحظات الجرد...',
                  controller: _notesController,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_selectedWarehouseId != null) ...[
            Text(
              'البحث عن المنتجات للجرد',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Autocomplete<StockBalanceView>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<StockBalanceView>.empty();
                }
                final q = textEditingValue.text.toLowerCase();
                return availableStocks.where((s) {
                  final name = s.product.productName.toLowerCase();
                  final code = s.product.productCode.toLowerCase();
                  return name.contains(q) || code.contains(q);
                });
              },
              displayStringForOption: (StockBalanceView option) => option.product.productName,
              onSelected: (option) {
                _addLine(option);
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return AppTextField(
                  label: '',
                  hint: 'ابحث بالاسم أو الباركود...',
                  controller: textEditingController,
                  prefixIcon: const Icon(Icons.search),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Lines Table Card
          Container(
            height: 320,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Center(child: Text('النظام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                      Expanded(flex: 1, child: Center(child: Text('الفعلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                      Expanded(flex: 1, child: Center(child: Text('الفارق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                      SizedBox(width: 36),
                    ],
                  ),
                ),
                Expanded(
                  child: _lines.isEmpty
                      ? const AppEmptyState(
                          title: 'لا يوجد عناصر في الجرد',
                          subtitle: 'اختر المستودع وابحث عن المنتجات لإضافتها لقائمة الجرد',
                          icon: Icons.inventory_2_outlined,
                        )
                      : ListView.separated(
                          itemCount: _lines.length,
                          separatorBuilder: (ctx, i) => Divider(height: 1, color: borderColor),
                          itemBuilder: (ctx, i) {
                            final line = _lines[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(line.stockView.product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(line.stockView.product.productCode, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Text(
                                        line.systemQty.toStringAsFixed(0),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: AppNumberField(
                                        label: '',
                                        hint: '0',
                                        onChanged: (val) {
                                          setState(() {
                                            line.physicalQty = double.tryParse(val);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: line.physicalQty == null
                                          ? const Text('-', style: TextStyle(color: Colors.grey))
                                          : Text(
                                              '${line.discrepancy > 0 ? '+' : ''}${line.discrepancy.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: line.discrepancy > 0
                                                    ? Colors.green
                                                    : (line.discrepancy < 0 ? Colors.red : Colors.grey),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                      onPressed: () => _removeLine(line.id),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
