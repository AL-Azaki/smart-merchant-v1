import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../providers/purchasing_provider.dart';
import '../../../sales/presentation/providers/product_unit_provider.dart'
    show posProductsNotifierProvider, PosProductItem;
import '../../../../kernel/storage/app_database.dart'
    show Supplier, Warehouse, CurrencyEntity;
import '../../../../app/di/injection.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../shared/documents/printing/document_printer.dart';
import '../../../../shared/documents/sharing/document_share.dart';
import '../mappers/purchase_invoice_document_mapper.dart';

class NewPurchaseView extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NewPurchaseView({super.key, required this.onBack});

  @override
  ConsumerState<NewPurchaseView> createState() => _NewPurchaseViewState();
}

class _NewPurchaseViewState extends ConsumerState<NewPurchaseView> {
  bool _showPaymentModal = false;
  List<String> _activeMethods = ['Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchasingNotifierProvider.notifier).clearForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasingNotifierProvider);
    final notifier = ref.read(purchasingNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    final productsAsync = ref.watch(posProductsNotifierProvider);
    final warehousesAsync = ref.watch(activeWarehousesStreamProvider);
    final currenciesAsync = ref.watch(availableCurrenciesFutureProvider);

    if (state.successInvoiceId != null) {
      return _buildSuccessScreen(isDark, surfaceColor, borderColor, textColor);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'فاتورة مشتريات (إدخال سريع)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onBack,
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Header Settings
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: surfaceColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Currency
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : 150,
                          child: currenciesAsync.when(
                            data: (currencies) => DropdownButtonFormField<String>(
                              value: state.currencyId.isEmpty
                                  ? (currencies.isNotEmpty
                                      ? currencies.firstWhere((c) => c.isBaseCurrency, orElse: () => currencies.first).id
                                      : null)
                                  : state.currencyId,
                              decoration: InputDecoration(
                                labelText: 'العملة',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              items: currencies
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text('${c.currencyNameAr} (${c.currencyCode})', overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final cur = currencies.firstWhere(
                                    (c) => c.id == val,
                                  );
                                  notifier.changeCurrency(val, cur.exchangeRate);
                                }
                              },
                            ),
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('خطأ بالعملة'),
                          ),
                        ),
                        // Supplier
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : 250,
                          child: suppliersAsync.when(
                            data: (suppliers) => DropdownButtonFormField<String>(
                              value: state.supplierId.isEmpty
                                  ? null
                                  : state.supplierId,
                              decoration: InputDecoration(
                                labelText: 'المورد',
                                prefixIcon: const Icon(Icons.store),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              items: suppliers
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.supplierName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  notifier.updateState(
                                    state.copyWith(supplierId: val),
                                  );
                                }
                              },
                            ),
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('خطأ بالموردين'),
                          ),
                        ),
                        // Warehouse
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : 200,
                          child: warehousesAsync.when(
                            data: (warehouses) {
                              if (warehouses.isNotEmpty &&
                                  state.warehouseId.isEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    notifier.updateState(
                                      state.copyWith(
                                        warehouseId: warehouses.first.id,
                                      ),
                                    );
                                  }
                                });
                              }
                              return DropdownButtonFormField<String>(
                                value: state.warehouseId.isEmpty
                                    ? null
                                    : state.warehouseId,
                                decoration: InputDecoration(
                                  labelText: 'المخزن',
                                  prefixIcon: const Icon(Icons.warehouse),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                items: warehouses
                                    .map(
                                      (w) => DropdownMenuItem(
                                        value: w.id,
                                        child: Text(w.warehouseName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    notifier.updateState(
                                      state.copyWith(warehouseId: val),
                                    );
                                  }
                                },
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Text('خطأ بالمخازن'),
                          ),
                        ),
                        // Reference
                        SizedBox(
                          width: isSmall ? constraints.maxWidth : 200,
                          child: TextFormField(
                            initialValue: state.invoiceRef,
                            decoration: InputDecoration(
                              labelText: 'مرجع المورد',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (val) => notifier.updateState(
                              state.copyWith(invoiceRef: val),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Data Grid
              Expanded(
                child: Container(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1400, // 140+250+140+100+100+120+120+120+120+60+paddings
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              color: surfaceColor,
                              child: Row(
                                children: [
                                  _headerCell('الباركود/SKU', 140),
                                  const SizedBox(width: 8),
                                  _headerCell('المنتج', 250),
                                  const SizedBox(width: 8),
                                  _headerCell('التصنيف', 140),
                                  const SizedBox(width: 8),
                                  _headerCell('الوحدة', 100),
                                  const SizedBox(width: 8),
                                  _headerCell('الكمية', 100),
                                  const SizedBox(width: 8),
                                  _headerCell('سعر الشراء', 120),
                                  const SizedBox(width: 8),
                                  _headerCell('سعر البيع', 120),
                                  const SizedBox(width: 8),
                                  _headerCell('تاريخ الانتهاء', 120),
                                  const SizedBox(width: 8),
                                  _headerCell('الإجمالي', 120),
                                  const SizedBox(width: 8),
                                  const SizedBox(width: 60), // Actions
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Rows
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final row = state.items[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: surfaceColor,
                                  child: Row(
                                    children: [
                                      // Barcode
                                      SizedBox(
                                        width: 140,
                                        child: _buildInput(
                                          value: row.barcode,
                                          onChanged: (v) {
                                            var newRow = row.copyWith(
                                              barcode: v,
                                            );
                                            productsAsync.whenData((products) {
                                              final match = products
                                                  .where(
                                                    (p) =>
                                                        p.baseUnit.barcode ==
                                                            v ||
                                                        p.baseUnit.sku == v,
                                                  )
                                                  .firstOrNull;
                                              if (match != null) {
                                                newRow = newRow.copyWith(
                                                  productUnitId:
                                                      match.baseUnit.id,
                                                  productId: match.product.id,
                                                  categoryId: match.product.categoryId,
                                                  productName:
                                                      match.product.productName,
                                                  purchasePrice: match
                                                      .baseUnit
                                                      .purchasePrice,
                                                  sellingPrice: match
                                                      .baseUnit
                                                      .sellingPrice,
                                                );
                                              }
                                            });
                                            notifier.updateRow(row.id, newRow);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Product Name
                                      SizedBox(
                                        width: 250,
                                        child: Autocomplete<PosProductItem>(
                                          initialValue: TextEditingValue(
                                            text: row.productName,
                                          ),
                                          displayStringForOption: (option) =>
                                              option.product.productName,
                                          optionsBuilder: (textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<
                                                PosProductItem
                                              >.empty();
                                            }
                                            final products =
                                                productsAsync.value ?? [];
                                            return products.where(
                                              (p) => p.product.productName
                                                  .toLowerCase()
                                                  .contains(
                                                    textEditingValue.text
                                                        .toLowerCase(),
                                                  ),
                                            );
                                          },
                                          onSelected: (option) {
                                            notifier.updateRow(
                                              row.id,
                                              row.copyWith(
                                                productName:
                                                    option.product.productName,
                                                productUnitId:
                                                    option.baseUnit.id,
                                                productId: option.product.id,
                                                categoryId: option.product.categoryId,
                                                purchasePrice: option
                                                    .baseUnit
                                                    .purchasePrice,
                                                sellingPrice: option
                                                    .baseUnit
                                                    .sellingPrice,
                                              ),
                                            );
                                          },
                                          optionsViewBuilder: (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4.0,
                                                borderRadius: BorderRadius.circular(8),
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width * 0.9 > 400 ? 400 : MediaQuery.of(context).size.width * 0.9),
                                                  child: ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                                    itemBuilder: (context, index) {
                                                      final option = options.elementAt(index);
                                                      return InkWell(
                                                        onTap: () => onSelected(option),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(12.0),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(option.product.productName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                              const SizedBox(height: 4),
                                                              Wrap(
                                                                spacing: 12,
                                                                runSpacing: 4,
                                                                children: [
                                                                  Text('SKU: ${(option.baseUnit.sku?.isNotEmpty ?? false) ? option.baseUnit.sku : '-'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                                  Text('السعر: ${option.baseUnit.purchasePrice}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          fieldViewBuilder:
                                              (
                                                context,
                                                controller,
                                                focusNode,
                                                onEditingComplete,
                                              ) {
                                                if (controller.text !=
                                                    row.productName) {
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        if (mounted &&
                                                            controller.text !=
                                                                row.productName) {
                                                          controller.text =
                                                              row.productName;
                                                        }
                                                      });
                                                }
                                                return TextField(
                                                  controller: controller,
                                                  focusNode: focusNode,
                                                  onEditingComplete:
                                                      onEditingComplete,
                                                  decoration: _inputDeco(),
                                                  onChanged: (v) =>
                                                      notifier.updateRow(
                                                        row.id,
                                                        row.copyWith(
                                                          productName: v,
                                                        ),
                                                      ),
                                                );
                                              },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Category
                                      SizedBox(
                                        width: 140,
                                        child: _buildInput(
                                          value: row.categoryId,
                                          hint: 'التصنيف',
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(categoryId: v),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Unit
                                      SizedBox(
                                        width: 100,
                                        child: _buildInput(
                                          value: row.unitId,
                                          hint: 'الوحدة',
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(unitId: v),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Quantity
                                      SizedBox(
                                        width: 100,
                                        child: _buildInput(
                                          value: row.quantity.toString(),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(
                                              quantity: double.tryParse(v) ?? 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Purchase Price
                                      SizedBox(
                                        width: 120,
                                        child: _buildInput(
                                          value: row.purchasePrice.toString(),
                                          keyboardType: TextInputType.number,
                                          textColor: AppColors.error,
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(
                                              purchasePrice:
                                                  double.tryParse(v) ?? 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Selling Price
                                      SizedBox(
                                        width: 120,
                                        child: _buildInput(
                                          value: row.sellingPrice.toString(),
                                          keyboardType: TextInputType.number,
                                          textColor: AppColors.success,
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(
                                              sellingPrice:
                                                  double.tryParse(v) ?? 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Expiry
                                      SizedBox(
                                        width: 120,
                                        child: _buildInput(
                                          value: row.expiryDate,
                                          hint: 'YYYY-MM-DD',
                                          onChanged: (v) => notifier.updateRow(
                                            row.id,
                                            row.copyWith(expiryDate: v),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Total
                                      SizedBox(
                                        width: 120,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            (row.quantity * row.purchasePrice)
                                                .toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Actions
                                      SizedBox(
                                        width: 60,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: AppColors.error,
                                          ),
                                          onPressed: state.items.length > 1
                                              ? () => notifier.removeRow(row.id)
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Add Row Button
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: 250,
                              child: OutlinedButton.icon(
                                onPressed: notifier.addRow,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة سطر جديد'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(250, 50),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Footer
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 16,
                    children: [
                      Wrap(
                        spacing: 32,
                        runSpacing: 16,
                        children: [
                          _buildSummaryStat(
                            'عدد الأصناف',
                            state.items
                                .where((r) => r.productName.isNotEmpty)
                                .length
                                .toString(),
                            textColor,
                          ),
                          _buildSummaryStat(
                            'الأصناف الجديدة',
                            state.items
                                .where(
                                  (r) =>
                                      r.productName.isNotEmpty &&
                                      r.productId == null,
                                )
                                .length
                                .toString(),
                            AppColors.success,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'الإجمالي الكلي',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.items.fold(0.0, (sum, r) => sum + (r.quantity * r.purchasePrice)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 200,
                            child: PrimaryButton(
                              text: 'الدفع والحفظ',
                              icon: Icons.check,
                              onPressed: () {
                                if (state.items
                                    .where(
                                      (r) =>
                                          r.productName.isNotEmpty &&
                                          r.quantity > 0,
                                    )
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى إضافة أصناف'),
                                    ),
                                  );
                                  return;
                                }
                                if (state.supplierId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى اختيار المورد'),
                                    ),
                                  );
                                  return;
                                }
                                if (state.warehouseId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يرجى اختيار المخزن'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _showPaymentModal = true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_showPaymentModal)
            _buildPaymentModal(
              context,
              state,
              notifier,
              surfaceColor,
              borderColor,
              textColor,
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width, {int? flex}) {
    final t = Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
    if (flex != null) return Expanded(flex: flex, child: t);
    return SizedBox(width: width, child: t);
  }

  InputDecoration _inputDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }

  Widget _buildInput({
    required String value,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    Color? textColor,
    String? hint,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      decoration: _inputDeco(hint: hint),
      onChanged: onChanged,
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModal(
    BuildContext context,
    PurchasingState state,
    PurchasingNotifier notifier,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    double grandTotal = state.items.fold(
      0.0,
      (sum, r) => sum + (r.quantity * r.purchasePrice),
    );
    double totalPaid = 0;
    state.paymentAmounts.forEach((key, val) {
      if (key != 'Other') totalPaid += double.tryParse(val) ?? 0;
    });
    double remaining = grandTotal - totalPaid;
    if (remaining < 0) remaining = 0;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPaymentModal = false),
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'طرق الدفع',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _showPaymentModal = false),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Methods
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _paymentMethodBtn(
                            'Cash',
                            'نقداً',
                            Icons.money,
                            Colors.green,
                          ),
                          _paymentMethodBtn(
                            'Card',
                            'بطاقة',
                            Icons.credit_card,
                            Colors.blue,
                          ),
                          _paymentMethodBtn(
                            'Other',
                            'آجل',
                            Icons.access_time,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Inputs
                      if (_activeMethods.contains('Cash'))
                        _paymentInput(
                          'نقداً',
                          'Cash',
                          grandTotal,
                          state,
                          notifier,
                        ),
                      if (_activeMethods.contains('Card'))
                        _paymentInput(
                          'بطاقة',
                          'Card',
                          grandTotal,
                          state,
                          notifier,
                        ),

                      const SizedBox(height: 24),
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي المطلوب:'),
                                Text(
                                  grandTotal.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('المدفوع:'),
                                Text(
                                  totalPaid.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            if (remaining > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('المتبقي (آجل):'),
                                  Text(
                                    remaining.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  final success = await notifier
                                      .submitPurchase();
                                  if (!success && mounted) {
                                    final error = ref
                                        .read(purchasingNotifierProvider)
                                        .error;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'فشل الحفظ: ${error?.message ?? 'خطأ'}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: state.isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'إتمام عملية الشراء',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
        ),
      ],
    );
  }

  Widget _paymentMethodBtn(
    String key,
    String label,
    IconData icon,
    Color color,
  ) {
    final isActive = _activeMethods.contains(key);
    return InkWell(
      onTap: () {
        setState(() {
          if (key == 'Other') {
            _activeMethods = ['Other'];
            ref
                .read(purchasingNotifierProvider.notifier)
                .updateState(
                  ref
                      .read(purchasingNotifierProvider)
                      .copyWith(paymentAmounts: {}),
                );
          } else {
            if (_activeMethods.contains(key))
              _activeMethods.remove(key);
            else
              _activeMethods.add(key);
            _activeMethods.remove('Other');
            if (_activeMethods.isEmpty) _activeMethods.add(key);
          }
        });
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isActive ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentInput(
    String label,
    String key,
    double total,
    PurchasingState state,
    PurchasingNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: state.paymentAmounts[key] ?? '',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'المبلغ المدفوع ($label)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: total.toString(),
        ),
        onChanged: (val) {
          final newMap = Map<String, String>.from(state.paymentAmounts);
          newMap[key] = val;
          notifier.updateState(state.copyWith(paymentAmounts: newMap));
        },
      ),
    );
  }

  Widget _buildSuccessScreen(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    final state = ref.watch(purchasingNotifierProvider);
    final notifier = ref.read(purchasingNotifierProvider.notifier);
    
    if (state.successInvoiceId == null) return const SizedBox();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: FutureBuilder<CommercialDocumentData>(
          future: getIt<PurchaseInvoiceDocumentMapper>().mapToDocumentData(state.successInvoiceId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
               return Container(
                 constraints: const BoxConstraints(maxWidth: 400),
                 padding: const EdgeInsets.all(48),
                 child: const Center(child: CircularProgressIndicator()),
               );
            }
            if (snapshot.hasError) {
               return Container(
                 constraints: const BoxConstraints(maxWidth: 400),
                 padding: const EdgeInsets.all(32),
                 decoration: BoxDecoration(
                   color: surfaceColor,
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: borderColor),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.error, color: AppColors.error, size: 48),
                     const SizedBox(height: 16),
                     Text('حدث خطأ أثناء تحميل الفاتورة: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                     const SizedBox(height: 24),
                     ElevatedButton(
                        onPressed: () => notifier.clearForm(),
                        child: const Text('رجوع'),
                     )
                   ]
                 )
               );
            }

            final docData = snapshot.data!;

            return Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'تم إتمام عملية الشراء بنجاح!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'رقم الفاتورة: ${docData.documentNumber}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => DocumentPrinter.printDocument(docData),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.print_rounded),
                          label: const Text(
                            'طباعة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => DocumentShare.shareDocument(docData),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF25D366),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          label: const Text(
                            'مشاركة',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommercialDocumentPreviewScreen(document: docData),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text(
                      'عرض الفاتورة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      notifier.clearForm();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                    label: const Text(
                      'فاتورة شراء جديدة',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text(
                      'العودة للقائمة',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
