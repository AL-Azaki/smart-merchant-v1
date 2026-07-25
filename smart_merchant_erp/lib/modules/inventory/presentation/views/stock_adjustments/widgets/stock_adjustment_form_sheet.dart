import 'package:flutter/material.dart';
import '../../../../../../kernel/storage/app_database.dart' show Product;
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../../shared/design_system/widgets/primary_button.dart';

class StockAdjustmentFormSheet extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const StockAdjustmentFormSheet({
    super.key,
    required this.products,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<StockAdjustmentFormSheet> createState() => _StockAdjustmentFormSheetState();
}

class _AdjustmentLine {
  final String id;
  final Product product;
  final double systemQty;
  double? physicalQty;

  _AdjustmentLine({
    required this.id,
    required this.product,
    required this.systemQty,
    this.physicalQty,
  });

  double get discrepancy => (physicalQty ?? 0) - systemQty;
}

class _StockAdjustmentFormSheetState extends State<StockAdjustmentFormSheet> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();

  final List<_AdjustmentLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _addLine(Product product) {
    if (_lines.any((l) => l.product.id == product.id)) return;
    setState(() {
      _lines.add(_AdjustmentLine(
        id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        systemQty: 100, // Mock for now, would come from actual stock
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
      'lines': validLines.map((l) => {
        'product_id': l.product.id,
        'system_qty': l.systemQty,
        'physical_qty': l.physicalQty,
        'discrepancy': l.discrepancy,
      }).toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filteredProducts = widget.products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.productName.toLowerCase().contains(q) || (p.productCode?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      width: 700,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جرد تصحيحي جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('مطابقة الرصيد الدفتري مع الرصيد الفعلي', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Notes
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(16),
                      color: surfaceColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('سبب التعديل / البيان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            hintText: 'مثال: جرد نهاية الشهر، تسوية نقص مستودع...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.description_outlined),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text('البحث عن المنتجات للجرد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<Product>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<Product>.empty();
                          }
                          final q = textEditingValue.text.toLowerCase();
                          return widget.products.where((p) {
                            final dynamic product = p;
                            final String name = product.productName ?? '';
                            final String? code = product.productCode;
                            return name.toLowerCase().contains(q) || (code?.toLowerCase().contains(q) ?? false);
                          });
                        },
                        displayStringForOption: (dynamic option) => option.productName ?? '',
                        onSelected: (option) {
                          _addLine(option);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'ابحث بالاسم أو الباركود...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Lines
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                              border: Border(bottom: BorderSide(color: borderColor)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('المنتج', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Center(child: Text('النظام', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 1, child: Center(child: Text('الفعلي', style: TextStyle(fontWeight: FontWeight.bold)))),
                                Expanded(flex: 1, child: Center(child: Text('الفارق', style: TextStyle(fontWeight: FontWeight.bold)))),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                          // Table Body
                          Expanded(
                            child: _lines.isEmpty
                                ? const Center(child: Text('ابحث عن المنتجات وأضفها للبدء في الجرد', style: TextStyle(color: Colors.grey)))
                                : ListView.separated(
                                    itemCount: _lines.length,
                                    separatorBuilder: (ctx, i) => Divider(height: 1, color: borderColor),
                                    itemBuilder: (ctx, i) {
                                      final line = _lines[i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(line.product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  if (line.product.productCode != null)
                                                    Text(line.product.productCode!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Center(child: Text(line.systemQty.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                child: TextField(
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  decoration: InputDecoration(
                                                    hintText: '0',
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
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
                                                          color: line.discrepancy > 0 ? Colors.green : (line.discrepancy < 0 ? Colors.red : Colors.grey),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: IconButton(
                                                icon: const Icon(Icons.close, color: Colors.grey),
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
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'حفظ وتسوية الفروقات',
                    icon: Icons.save,
                    onPressed: _handleSave,
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
