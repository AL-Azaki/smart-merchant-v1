import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../app/di/getit_providers.dart';
import '../../../../../../database/daos/inventory_dao.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';
import '../../../../application/usecases/process_warehouse_transfer_usecase.dart';
import '../../../providers/inventory_provider.dart';

class WarehouseTransferDialog extends ConsumerStatefulWidget {
  const WarehouseTransferDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WarehouseTransferDialog(),
    );
  }

  @override
  ConsumerState<WarehouseTransferDialog> createState() =>
      _WarehouseTransferDialogState();
}

class _TransferItemRow {
  final StockBalanceView stock;
  double transferQty;

  _TransferItemRow({
    required this.stock,
    required this.transferQty,
  });
}

class _WarehouseTransferDialogState
    extends ConsumerState<WarehouseTransferDialog> {
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _sourceWarehouseId;
  String? _destinationWarehouseId;
  final List<_TransferItemRow> _selectedItems = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addItem(StockBalanceView stock) {
    if (_selectedItems.any((i) => i.stock.productUnit.id == stock.productUnit.id)) {
      return;
    }
    setState(() {
      _selectedItems.add(_TransferItemRow(
        stock: stock,
        transferQty: 1.0,
      ));
      _searchController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
    });

    if (_sourceWarehouseId == null) {
      setState(() => _errorMessage = 'يرجى اختيار المستودع المصدر.');
      return;
    }
    if (_destinationWarehouseId == null) {
      setState(() => _errorMessage = 'يرجى اختيار المستودع المستلم.');
      return;
    }
    if (_sourceWarehouseId == _destinationWarehouseId) {
      setState(() =>
          _errorMessage = 'لا يمكن التحويل لنفس المستودع. اختر مستودعاً مختلفاً.');
      return;
    }
    if (_selectedItems.isEmpty) {
      setState(() => _errorMessage = 'يرجى إضافة صنف واحد على الأقل للتحويل.');
      return;
    }

    // Validate quantities
    for (final item in _selectedItems) {
      if (item.transferQty <= 0) {
        setState(() => _errorMessage =
            'الكمية المحولة للصنف (${item.stock.product.productName}) يجب أن تكون أكبر من صفر.');
        return;
      }
      if (item.transferQty > item.stock.inventory.quantity) {
        setState(() => _errorMessage =
            'الكمية المحولة للصنف (${item.stock.product.productName}) تتجاوز الرصيد المتوفر بالمخزن (${item.stock.inventory.quantity}).');
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final useCase = ref.read(processWarehouseTransferUseCaseProvider);
      final command = ProcessWarehouseTransferCommand(
        sourceWarehouseId: _sourceWarehouseId!,
        destinationWarehouseId: _destinationWarehouseId!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        items: _selectedItems.map((item) {
          return WarehouseTransferItemCommand(
            productUnitId: item.stock.productUnit.id,
            quantity: item.transferQty,
          );
        }).toList(),
      );

      final result = await useCase(command);

      result.fold(
        (failure) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = failure.message;
          });
        },
        (transferId) {
          ref.invalidate(warehouseTransfersStreamProvider);
          Navigator.of(context).pop(true);
        },
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final warehouses = warehousesAsync.valueOrNull ?? [];

    // Stocks in source warehouse
    final stockBalancesAsync = _sourceWarehouseId != null
        ? ref.watch(warehouseStockBalancesProvider(_sourceWarehouseId!))
        : null;
    final availableStocks = stockBalancesAsync?.valueOrNull ?? [];

    final filteredAvailableStocks = availableStocks.where((s) {
      if (s.inventory.quantity <= 0) return false;
      if (_selectedItems
          .any((i) => i.stock.productUnit.id == s.productUnit.id)) {
        return false;
      }
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final matchName = s.product.productName.toLowerCase().contains(q);
        final matchCode = s.product.productCode.toLowerCase().contains(q);
        final matchBar = s.productUnit.barcode?.toLowerCase().contains(q) ?? false;
        return matchName || matchCode || matchBar;
      }
      return true;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 950,
        height: 720,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحويل مخزني جديد بين المستودعات',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'نقل بضائع وأصناف من مستودع إلى آخر وتحديث الأرصدة تلقائياً',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إلغاء',
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Error Banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: AppColors.error.withOpacity(0.12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left / Selected Items Column (Flex 3)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Warehouse Selectors Row
                          Row(
                            children: [
                              // Source Warehouse
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'المستودع المصدر (من)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _sourceWarehouseId,
                                      hint: const Text('اختر المستودع المصدر'),
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: warehouses.map((wh) {
                                        return DropdownMenuItem(
                                          value: wh.id,
                                          child: Text(
                                            wh.warehouseName,
                                            style: const TextStyle(
                                                fontFamily: 'Cairo'),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _sourceWarehouseId = val;
                                          _selectedItems.clear();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.arrow_forward,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 14),
                              // Destination Warehouse
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'المستودع المستلم (إلى)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _destinationWarehouseId,
                                      hint: const Text('اختر المستودع المستلم'),
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      items: warehouses.map((wh) {
                                        return DropdownMenuItem(
                                          value: wh.id,
                                          child: Text(
                                            wh.warehouseName,
                                            style: const TextStyle(
                                                fontFamily: 'Cairo'),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _destinationWarehouseId = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Table Title & Count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الأصناف المحددة للتحويل (${_selectedItems.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Table of selected items
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _selectedItems.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.playlist_add,
                                            size: 40,
                                            color: secondaryTextColor
                                                .withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'لم تقم بإضافة أي أصناف بعد',
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                              fontSize: 13,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'اختر الأصناف من القائمة الجانبية',
                                            style: TextStyle(
                                              color: secondaryTextColor
                                                  .withOpacity(0.7),
                                              fontSize: 11,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(10),
                                      itemCount: _selectedItems.length,
                                      separatorBuilder: (_, __) =>
                                          Divider(height: 1, color: borderColor),
                                      itemBuilder: (context, index) {
                                        final item = _selectedItems[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.stock.product
                                                          .productName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                    Text(
                                                      'المتوفر: ${item.stock.inventory.quantity} ${item.stock.productUnit.unitId}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: secondaryTextColor,
                                                        fontFamily: 'Cairo',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Quantity Spinner / Input
                                              SizedBox(
                                                width: 110,
                                                height: 38,
                                                child: TextFormField(
                                                  initialValue: item.transferQty
                                                      .toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: const TextStyle(
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                    labelText: 'الكمية',
                                                    labelStyle: const TextStyle(
                                                      fontSize: 10,
                                                      fontFamily: 'Cairo',
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6,
                                                      ),
                                                    ),
                                                  ),
                                                  onChanged: (val) {
                                                    final d =
                                                        double.tryParse(val) ??
                                                            0.0;
                                                    item.transferQty = d;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'حذف',
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.error,
                                                  size: 20,
                                                ),
                                                onPressed: () =>
                                                    _removeItem(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Notes Field
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'ملاحظات التحويل (اختياري)',
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  VerticalDivider(width: 1, color: borderColor),

                  // Right / Available Items in Source Warehouse (Flex 4)
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الأصناف المتوفرة بالمخزن المصدر',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Search Box
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'بحث باسم الصنف أو الباركود...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontFamily: 'Cairo',
                              ),
                              prefixIcon:
                                  const Icon(Icons.search, size: 18),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Available Items List
                          Expanded(
                            child: _sourceWarehouseId == null
                                ? Center(
                                    child: Text(
                                      'يرجى تحديد المستودع المصدر أولاً لعرض البضائع',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  )
                                : (stockBalancesAsync?.isLoading ?? false)
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : filteredAvailableStocks.isEmpty
                                        ? Center(
                                            child: Text(
                                              'لا توجد أصناف متوفرة بالمخزن',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: 12,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          )
                                        : ListView.separated(
                                            itemCount:
                                                filteredAvailableStocks.length,
                                            separatorBuilder: (_, __) =>
                                                Divider(
                                                    height: 1,
                                                    color: borderColor),
                                            itemBuilder: (context, index) {
                                              final stock =
                                                  filteredAvailableStocks[
                                                      index];
                                              return ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                title: Text(
                                                  stock.product.productName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'المتوفر: ${stock.inventory.quantity}',
                                                  style: const TextStyle(
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  tooltip: 'إضافة للتحويل',
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    color: AppColors.primary,
                                                    size: 22,
                                                  ),
                                                  onPressed: () =>
                                                      _addItem(stock),
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

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Text(
                      _isSubmitting ? 'جاري التحويل...' : 'تأكيد وإتمام التحويل',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
