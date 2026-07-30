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
import '../../../../app/di/getit_instance.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../shared/documents/printing/document_printer.dart';
import '../../../../shared/documents/sharing/document_share.dart';
import '../mappers/purchase_invoice_document_mapper.dart';
import '../../../crm/presentation/providers/crm_provider.dart';
import '../../../crm/presentation/views/widgets/contact_form_sheet.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../catalog/presentation/views/widgets/category_form_sheet.dart';
import '../../../catalog/presentation/views/widgets/product_form_sheet.dart';

class PurchaseInvoiceModal extends ConsumerStatefulWidget {
  const PurchaseInvoiceModal({super.key});

  @override
  ConsumerState<PurchaseInvoiceModal> createState() =>
      _PurchaseInvoiceModalState();
}

class _PurchaseInvoiceModalState extends ConsumerState<PurchaseInvoiceModal> {
  bool _showPaymentModal = false;
  List<String> _activeMethods = ['Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchasingNotifierProvider.notifier).clearForm();
    });
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(purchasingNotifierProvider);
    final hasData =
        state.items.any((r) => r.productName.isNotEmpty || r.quantity > 0) ||
        state.supplierId.isNotEmpty ||
        state.invoiceRef.isNotEmpty;

    if (!hasData || state.successInvoiceId != null) {
      return true;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد الإغلاق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'لديك تغييرات غير محفوظة. هل تريد إغلاق الفاتورة؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('متابعة التعديل', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('تجاهل وإغلاق', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    return confirm ?? false;
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

    if (state.successInvoiceId != null) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        child: _buildSuccessScreen(
          isDark,
          surfaceColor,
          borderColor,
          textColor,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_showPaymentModal) {
          setState(() => _showPaymentModal = false);
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleHeader(context, surfaceColor, borderColor, isDark),
                  Flexible(
                    child: Container(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSettingsForm(
                              context,
                              state,
                              notifier,
                              surfaceColor,
                              borderColor,
                              isDark,
                            ),
                            const Divider(height: 1),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (MediaQuery.of(context).size.width < 800) {
                                  return _buildMobileBody(
                                    context,
                                    state,
                                    notifier,
                                    surfaceColor,
                                    borderColor,
                                  );
                                } else {
                                  return _buildDesktopBody(
                                    context,
                                    state,
                                    notifier,
                                    surfaceColor,
                                    borderColor,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildFooter(
                    context,
                    state,
                    notifier,
                    surfaceColor,
                    borderColor,
                    textColor,
                  ),
                ],
              ),
              if (_showPaymentModal)
                Positioned.fill(
                  child: _buildPaymentModal(
                    context,
                    state,
                    notifier,
                    surfaceColor,
                    borderColor,
                    textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleHeader(
    BuildContext context,
    Color surfaceColor,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
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
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'فاتورة مشتريات جديدة',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'إدخال سريع وسلس للفاتورة',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              if (await _onWillPop() && mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close, color: Colors.red),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm(
    BuildContext context,
    PurchasingState state,
    PurchasingNotifier notifier,
    Color surfaceColor,
    Color borderColor,
    bool isDark,
  ) {
    final suppliersAsync = ref.watch(suppliersNotifierProvider);
    final warehousesAsync = ref.watch(activeWarehousesStreamProvider);
    final currenciesAsync = ref.watch(availableCurrenciesFutureProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: surfaceColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = MediaQuery.of(context).size.width < 600;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isSmall ? constraints.maxWidth : 150,
                child: currenciesAsync.when(
                  data: (currencies) {
                    if (currencies.isNotEmpty && state.currencyId.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          final cur = currencies.firstWhere(
                            (c) => c.isBaseCurrency,
                            orElse: () => currencies.first,
                          );
                          notifier.updateState(
                            state.copyWith(
                              currencyId: cur.id,
                              exchangeRate: cur.exchangeRate,
                            ),
                          );
                        }
                      });
                    }
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: state.currencyId.isEmpty
                          ? (currencies.isNotEmpty
                                ? currencies
                                      .firstWhere(
                                        (c) => c.isBaseCurrency,
                                        orElse: () => currencies.first,
                                      )
                                      .id
                                : null)
                          : state.currencyId,
                      decoration: _inputDeco(hint: 'العملة'),
                      items: currencies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                '${c.currencyNameAr} (${c.currencyCode})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final cur = currencies.firstWhere((c) => c.id == val);
                          notifier.changeCurrency(val, cur.exchangeRate);
                        }
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('خطأ'),
                ),
              ),
              currenciesAsync.when(
                data: (currencies) {
                  if (currencies.isEmpty || state.currencyId.isEmpty)
                    return const SizedBox.shrink();
                  final baseCurrency = currencies.firstWhere(
                    (c) => c.isBaseCurrency,
                    orElse: () => currencies.first,
                  );
                  if (state.currencyId == baseCurrency.id)
                    return const SizedBox.shrink();

                  final currentCurrency = currencies.firstWhere(
                    (c) => c.id == state.currencyId,
                    orElse: () => baseCurrency,
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.currency_exchange,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'سعر الصرف: 1 ${currentCurrency.currencySymbol} = ${state.exchangeRate.toStringAsFixed(2)} ${baseCurrency.currencySymbol}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              SizedBox(
                width: isSmall ? constraints.maxWidth : 250,
                child: suppliersAsync.when(
                  data: (suppliers) {
                    final currentSupplier = suppliers
                        .where((s) => s.id == state.supplierId)
                        .firstOrNull;
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => _SupplierSelectionDialog(
                            suppliers: suppliers,
                            onSelected: (s) {
                              notifier.updateState(
                                state.copyWith(supplierId: s.id),
                              );
                            },
                            onAddNew: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (formCtx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 24,
                                  ),
                                  child: ContactFormSheet(
                                    isCustomer: false,
                                    onClose: () => Navigator.pop(formCtx),
                                    onSave: (data) async {
                                      // Note: We need crmNotifierProvider to save
                                      final successId = await ref
                                          .read(crmNotifierProvider.notifier)
                                          .saveSupplier(
                                            data.cast<String, dynamic>(),
                                          );
                                      if (successId != null &&
                                          formCtx.mounted) {
                                        Navigator.pop(formCtx);
                                        // Select newly created supplier
                                        notifier.updateState(
                                          state.copyWith(supplierId: successId),
                                        );
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
                        decoration: _inputDeco(
                          hint: 'المورد',
                        ).copyWith(prefixIcon: const Icon(Icons.store)),
                        child: Text(
                          currentSupplier?.supplierName ?? 'اختر المورد',
                          style: TextStyle(
                            color: currentSupplier == null ? Colors.grey : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('خطأ'),
                ),
              ),
              SizedBox(
                width: isSmall ? constraints.maxWidth : 200,
                child: warehousesAsync.when(
                  data: (warehouses) {
                    if (warehouses.isNotEmpty && state.warehouseId.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          notifier.updateState(
                            state.copyWith(warehouseId: warehouses.first.id),
                          );
                      });
                    }
                    return DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: state.warehouseId.isEmpty
                          ? null
                          : state.warehouseId,
                      decoration: _inputDeco(
                        hint: 'المخزن',
                      ).copyWith(prefixIcon: const Icon(Icons.warehouse)),
                      items: warehouses
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                w.warehouseName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          notifier.updateState(
                            state.copyWith(warehouseId: val),
                          );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('خطأ'),
                ),
              ),
              SizedBox(
                width: isSmall ? constraints.maxWidth : 200,
                child: TextFormField(
                  initialValue: state.invoiceRef,
                  decoration: _inputDeco(hint: 'مرجع المورد'),
                  onChanged: (val) =>
                      notifier.updateState(state.copyWith(invoiceRef: val)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopBody(
    BuildContext context,
    PurchasingState state,
    PurchasingNotifier notifier,
    Color surfaceColor,
    Color borderColor,
  ) {
    final productsAsync = ref.watch(posProductsNotifierProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 1400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const SizedBox(width: 60),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
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
                      SizedBox(
                        width: 140,
                        child: _buildInput(
                          value: row.barcode,
                          onChanged: (v) {
                            var newRow = row.copyWith(barcode: v);
                            productsAsync.whenData((products) {
                              final match = products
                                  .where(
                                    (p) =>
                                        p.baseUnit.barcode == v ||
                                        p.baseUnit.sku == v,
                                  )
                                  .firstOrNull;
                              if (match != null) {
                                newRow = newRow.copyWith(
                                  productUnitId: match.baseUnit.id,
                                  productId: match.product.id,
                                  categoryId: match.product.categoryId,
                                  productName: match.product.productName,
                                  purchasePrice: match.baseUnit.purchasePrice,
                                  sellingPrice: match.baseUnit.sellingPrice,
                                );
                              }
                            });
                            notifier.updateRow(row.id, newRow);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 250,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Autocomplete<PosProductItem>(
                                    initialValue: TextEditingValue(
                                      text: row.productName,
                                    ),
                                    displayStringForOption: (option) =>
                                        option.product.productName,
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty)
                                        return const Iterable<
                                          PosProductItem
                                        >.empty();
                                      final q = textEditingValue.text
                                          .toLowerCase();
                                      final products =
                                          productsAsync.value ?? [];
                                      return products.where((p) {
                                        final name = p.product.productName
                                            .toLowerCase();
                                        final barcode =
                                            p.baseUnit.barcode?.toLowerCase() ??
                                            '';
                                        final sku =
                                            p.baseUnit.sku?.toLowerCase() ?? '';
                                        return name.contains(q) ||
                                            barcode.contains(q) ||
                                            sku.contains(q);
                                      });
                                    },
                                    onSelected: (option) {
                                      notifier.updateRow(
                                        row.id,
                                        row.copyWith(
                                          productName:
                                              option.product.productName,
                                          productUnitId: option.baseUnit.id,
                                          productId: option.product.id,
                                          categoryId: option.product.categoryId,
                                          purchasePrice:
                                              option.baseUnit.purchasePrice,
                                          sellingPrice:
                                              option.baseUnit.sellingPrice,
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
                                                .addPostFrameCallback((_) {
                                                  if (mounted &&
                                                      controller.text !=
                                                          row.productName)
                                                    controller.text =
                                                        row.productName;
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
                                                  row.copyWith(productName: v),
                                                ),
                                          );
                                        },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (formCtx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 24,
                                            ),
                                        child: ProductFormSheet(
                                          hideOpeningStock: true,
                                          onClose: () => Navigator.pop(formCtx),
                                          onSave: (data) async {
                                            final successId = await ref
                                                .read(
                                                  productsNotifierProvider
                                                      .notifier,
                                                )
                                                .saveProduct(data);
                                            if (successId != null &&
                                                formCtx.mounted) {
                                              Navigator.pop(formCtx);
                                              notifier.updateRow(
                                                row.id,
                                                row.copyWith(
                                                  productId: successId,
                                                  productName:
                                                      data['product_name']
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: _CategorySelectionWidget(
                          categoryId: row.categoryId,
                          onChanged: (v) => notifier.updateRow(
                            row.id,
                            row.copyWith(categoryId: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                      SizedBox(
                        width: 100,
                        child: _buildInput(
                          value: row.quantity.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => notifier.updateRow(
                            row.id,
                            row.copyWith(quantity: double.tryParse(v) ?? 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: _buildInput(
                          value: row.purchasePrice.toString(),
                          keyboardType: TextInputType.number,
                          textColor: AppColors.error,
                          onChanged: (v) => notifier.updateRow(
                            row.id,
                            row.copyWith(
                              purchasePrice: double.tryParse(v) ?? 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: _buildInput(
                          value: row.sellingPrice.toString(),
                          keyboardType: TextInputType.number,
                          textColor: AppColors.success,
                          onChanged: (v) => notifier.updateRow(
                            row.id,
                            row.copyWith(sellingPrice: double.tryParse(v) ?? 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                      SizedBox(
                        width: 120,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (row.quantity * row.purchasePrice).toStringAsFixed(
                              2,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBody(
    BuildContext context,
    PurchasingState state,
    PurchasingNotifier notifier,
    Color surfaceColor,
    Color borderColor,
  ) {
    final productsAsync = ref.watch(posProductsNotifierProvider);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            child: OutlinedButton.icon(
              onPressed: notifier.addRow,
              icon: const Icon(Icons.add),
              label: const Text('إضافة سطر جديد'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          );
        }

        final row = state.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المنتج',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.error,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: state.items.length > 1
                        ? () => notifier.removeRow(row.id)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: Autocomplete<PosProductItem>(
                          initialValue: TextEditingValue(text: row.productName),
                          displayStringForOption: (option) =>
                              option.product.productName,
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty)
                              return const Iterable<PosProductItem>.empty();
                            final q = textEditingValue.text.toLowerCase();
                            final products = productsAsync.value ?? [];
                            return products.where((p) {
                              final name = p.product.productName.toLowerCase();
                              final barcode =
                                  p.baseUnit.barcode?.toLowerCase() ?? '';
                              final sku = p.baseUnit.sku?.toLowerCase() ?? '';
                              return name.contains(q) ||
                                  barcode.contains(q) ||
                                  sku.contains(q);
                            });
                          },
                          onSelected: (option) {
                            notifier.updateRow(
                              row.id,
                              row.copyWith(
                                productName: option.product.productName,
                                productUnitId: option.baseUnit.id,
                                productId: option.product.id,
                                categoryId: option.product.categoryId,
                                purchasePrice: option.baseUnit.purchasePrice,
                                sellingPrice: option.baseUnit.sellingPrice,
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
                                if (controller.text != row.productName) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted &&
                                        controller.text != row.productName)
                                      controller.text = row.productName;
                                  });
                                }
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onEditingComplete: onEditingComplete,
                                  decoration: _inputDeco(hint: 'اسم المنتج'),
                                  onChanged: (v) => notifier.updateRow(
                                    row.id,
                                    row.copyWith(productName: v),
                                  ),
                                );
                              },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (formCtx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              child: ProductFormSheet(
                                hideOpeningStock: true,
                                onClose: () => Navigator.pop(formCtx),
                                onSave: (data) async {
                                  final successId = await ref
                                      .read(productsNotifierProvider.notifier)
                                      .saveProduct(data);
                                  if (successId != null && formCtx.mounted) {
                                    Navigator.pop(formCtx);
                                    notifier.updateRow(
                                      row.id,
                                      row.copyWith(
                                        productId: successId,
                                        productName:
                                            data['product_name']?.toString() ??
                                            '',
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CategorySelectionWidget(
                      categoryId: row.categoryId,
                      onChanged: (v) => notifier.updateRow(
                        row.id,
                        row.copyWith(categoryId: v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInput(
                      value: row.unitId,
                      hint: 'الوحدة',
                      onChanged: (v) =>
                          notifier.updateRow(row.id, row.copyWith(unitId: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      value: row.quantity.toString(),
                      hint: 'الكمية',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => notifier.updateRow(
                        row.id,
                        row.copyWith(quantity: double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInput(
                      value: row.purchasePrice.toString(),
                      hint: 'سعر الشراء',
                      keyboardType: TextInputType.number,
                      textColor: AppColors.error,
                      onChanged: (v) => notifier.updateRow(
                        row.id,
                        row.copyWith(purchasePrice: double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      value: row.sellingPrice.toString(),
                      hint: 'سعر البيع',
                      keyboardType: TextInputType.number,
                      textColor: AppColors.success,
                      onChanged: (v) => notifier.updateRow(
                        row.id,
                        row.copyWith(sellingPrice: double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInput(
                      value: row.barcode,
                      hint: 'الباركود/SKU',
                      onChanged: (v) {
                        var newRow = row.copyWith(barcode: v);
                        productsAsync.whenData((products) {
                          final match = products
                              .where(
                                (p) =>
                                    p.baseUnit.barcode == v ||
                                    p.baseUnit.sku == v,
                              )
                              .firstOrNull;
                          if (match != null) {
                            newRow = newRow.copyWith(
                              productUnitId: match.baseUnit.id,
                              productId: match.product.id,
                              categoryId: match.product.categoryId,
                              productName: match.product.productName,
                              purchasePrice: match.baseUnit.purchasePrice,
                              sellingPrice: match.baseUnit.sellingPrice,
                            );
                          }
                        });
                        notifier.updateRow(row.id, newRow);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      value: row.expiryDate,
                      hint: 'تاريخ الانتهاء',
                      onChanged: (v) => notifier.updateRow(
                        row.id,
                        row.copyWith(expiryDate: v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'إجمالي: ${(row.quantity * row.purchasePrice).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    PurchasingState state,
    PurchasingNotifier notifier,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
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
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        spacing: 16,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 8,
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
                      (r) => r.productName.isNotEmpty && r.productId == null,
                    )
                    .length
                    .toString(),
                AppColors.success,
              ),
            ],
          ),
          Wrap(
            spacing: 16,
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 150,
                child: PrimaryButton(
                  text: 'حفظ ومتابعة',
                  icon: Icons.check,
                  onPressed: () {
                    if (state.items
                        .where(
                          (r) => r.productName.isNotEmpty && r.quantity > 0,
                        )
                        .isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إضافة أصناف')),
                      );
                      return;
                    }
                    if (state.supplierId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى اختيار المورد')),
                      );
                      return;
                    }
                    if (state.warehouseId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى اختيار المخزن')),
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

    final paymentMethodsAsync = ref.watch(
      availablePaymentMethodsFutureProvider,
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPaymentModal = false),
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
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
                          paymentMethodsAsync.when(
                            data: (methods) {
                              return Column(
                                children: [
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ...methods.map(
                                        (pm) => _paymentMethodBtn(
                                          pm.id,
                                          pm.methodName,
                                          pm.methodCode.toUpperCase().contains(
                                                'BANK',
                                              )
                                              ? Icons.credit_card
                                              : Icons.money,
                                          pm.methodCode.toUpperCase().contains(
                                                'BANK',
                                              )
                                              ? Colors.blue
                                              : Colors.green,
                                        ),
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
                                  ...methods.map((pm) {
                                    if (_activeMethods.contains(pm.id)) {
                                      return _paymentInput(
                                        pm.methodName,
                                        pm.id,
                                        grandTotal,
                                        state,
                                        notifier,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                  if (state.error != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              state.error!.message,
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () async {
                                              await notifier.submitPurchase();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) =>
                                const Text('خطأ في تحميل طرق الدفع'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

    return FutureBuilder<CommercialDocumentData>(
      future: getIt<PurchaseInvoiceDocumentMapper>().mapToDocumentData(
        state.successInvoiceId!,
      ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ أثناء تحميل الفاتورة: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => notifier.clearForm(),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          );
        }

        final docData = snapshot.data!;

        return Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
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
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'مشاركة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                        builder: (_) =>
                            CommercialDocumentPreviewScreen(document: docData),
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
                  icon: const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'فاتورة شراء جديدة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
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
        width: 90,
        height: 90,
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
            Icon(icon, size: 28, color: isActive ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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

  InputDecoration _inputDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      labelText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
}

class _SupplierSelectionDialog extends StatefulWidget {
  final List<Supplier> suppliers;
  final Function(Supplier) onSelected;
  final VoidCallback onAddNew;

  const _SupplierSelectionDialog({
    required this.suppliers,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  State<_SupplierSelectionDialog> createState() =>
      _SupplierSelectionDialogState();
}

class _SupplierSelectionDialogState extends State<_SupplierSelectionDialog> {
  String _searchQuery = '';
  late List<Supplier> _filteredSuppliers;

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = widget.suppliers;
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      final q = query.toLowerCase();
      _filteredSuppliers = widget.suppliers.where((s) {
        return s.supplierName.toLowerCase().contains(q) ||
            (s.phone?.contains(q) ?? false);
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
                  'اختيار مورد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث باسم المورد أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredSuppliers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = _filteredSuppliers[index];
                  return ListTile(
                    title: Text(
                      s.supplierName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: s.phone != null ? Text(s.phone!) : null,
                    onTap: () {
                      widget.onSelected(s);
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
                  'إضافة مورد جديد',
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

class _CategorySelectionWidget extends ConsumerWidget {
  final String categoryId;
  final Function(String) onChanged;

  const _CategorySelectionWidget({
    required this.categoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    return categoriesAsync.when(
      data: (categories) {
        final currentCategory = categories
            .where((c) => c.id == categoryId)
            .firstOrNull;
        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => _CategorySelectionDialog(
                categories: categories,
                onSelected: (c) => onChanged(c.id as String),
                onAddNew: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (formCtx) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: CategoryFormSheet(
                        onClose: () => Navigator.pop(formCtx),
                        onSave: (data) async {
                          final successId = await ref
                              .read(categoriesNotifierProvider.notifier)
                              .saveCategory(data.cast<String, dynamic>());
                          if (successId != null && formCtx.mounted) {
                            Navigator.pop(formCtx);
                            onChanged(successId);
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
            decoration: InputDecoration(
              hintText: 'التصنيف',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            child: Text(
              currentCategory?.categoryName ?? 'التصنيف',
              style: TextStyle(
                color: currentCategory == null ? Colors.grey : null,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const Text('خطأ'),
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
  State<_CategorySelectionDialog> createState() =>
      _CategorySelectionDialogState();
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
        return (c.categoryName as String).toLowerCase().contains(q);
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
            TextField(
              decoration: InputDecoration(
                hintText: 'بحث باسم التصنيف...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                    title: Text(
                      (c.categoryName as String?) ?? '',
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
