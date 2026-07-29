import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../../shared/design_system/widgets/primary_button.dart';
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
    this.productName = 'منتج',
    this.productCode = '',
    required this.expectedQuantity,
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
    if (_lines.any((l) => l.productUnitId == view.productUnit.id)) return;
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

  void _handleSave() async {
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
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.viewInsets.bottom;
    
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    return Container(
      height: mq.size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWarehouseSelector(warehousesAsync),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        if (_selectedWarehouseId != null)
                          _buildProductSearch(),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildLineItemCard(_lines[index]);
                    },
                    childCount: _lines.length,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomPadding + 80), 
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.existingCount != null ? 'تعديل مسودة جرد' : 'جرد مخزون جديد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelector(AsyncValue<List<Warehouse>> asyncWarehouses) {
    return asyncWarehouses.when(
      data: (warehouses) {
        return DropdownButtonFormField<String>(
          value: _selectedWarehouseId,
          decoration: const InputDecoration(
            labelText: 'المستودع',
            border: OutlineInputBorder(),
          ),
          items: warehouses.map((w) {
            return DropdownMenuItem(
              value: w.id,
              child: Text(w.warehouseName),
            );
          }).toList(),
          onChanged: widget.existingCount != null ? null : (val) { // Disabled if editing
            setState(() {
              if (_selectedWarehouseId != val) {
                _lines.clear(); 
                _selectedWarehouseId = val;
              }
            });
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('خطأ في تحميل المستودعات: $e'),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'الملاحظات',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildProductSearch() {
    final inventoryAsync = ref.watch(warehouseStockBalancesProvider(_selectedWarehouseId!));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            labelText: 'بحث عن منتج لإضافته...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
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
                    padding: EdgeInsets.all(16.0),
                    child: Text('لا توجد منتجات مطابقة في هذا المستودع.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return ListTile(
                      title: Text(item.product.productName),
                      subtitle: Text('الباركود: ${item.productUnit.barcode ?? "-"} | الدفترية: ${item.inventory.quantity}'),
                      onTap: () => _addLine(item),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('خطأ: $e'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLineItemCard(_StockCountLine line) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الكمية الدفترية: ${line.expectedQuantity}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeLine(line.id),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: Text('الجرد الفعلي:'),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: line.physicalQty?.toString() ?? '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        line.physicalQty = double.tryParse(val);
                      });
                    },
                  ),
                ),
              ],
            ),
            if (line.physicalQty != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'الفرق: ${line.discrepancy}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: line.discrepancy != 0
                          ? (line.discrepancy > 0 ? AppColors.success : AppColors.error)
                          : (Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: PrimaryButton(
          onPressed: _handleSave,
          text: 'حفظ كمسودة',
          icon: Icons.save,
        ),
      ),
    );
  }
}
