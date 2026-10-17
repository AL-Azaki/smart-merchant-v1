import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/product_stock_card_provider.dart';

class ProductStockCardDialog extends ConsumerStatefulWidget {
  final String productId;
  final String productName;
  final String productCode;

  const ProductStockCardDialog({
    super.key,
    required this.productId,
    required this.productName,
    required this.productCode,
  });

  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productName,
    required String productCode,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProductStockCardDialog(
        productId: productId,
        productName: productName,
        productCode: productCode,
      ),
    );
  }

  @override
  ConsumerState<ProductStockCardDialog> createState() =>
      _ProductStockCardDialogState();
}

class _ProductStockCardDialogState
    extends ConsumerState<ProductStockCardDialog> {
  String _directionFilter = 'all'; // 'all', 'inbound', 'outbound'
  String _searchQuery = '';

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd  hh:mm a').format(dt);
  }

  String _resolveTransactionTypeName(
    InventoryTransactionType type,
    InventoryReferenceType? refType,
  ) {
    if (refType != null) {
      switch (refType) {
        case InventoryReferenceType.salesInvoice:
          return 'فاتورة مبيعات POS';
        case InventoryReferenceType.purchaseInvoice:
          return 'فاتورة مشتريات';
        case InventoryReferenceType.salesReturn:
          return 'مرتجع مبيعات';
        case InventoryReferenceType.purchaseReturn:
          return 'مرتجع مشتريات';
        case InventoryReferenceType.transfer:
          return 'تحويل مخزني';
        case InventoryReferenceType.adjustment:
          return 'تسوية جردية';
      }
    }
    switch (type) {
      case InventoryTransactionType.receipt:
        return 'استلام بضاعة (وارد)';
      case InventoryTransactionType.dispatch:
        return 'صرف بضاعة (منصرف)';
      case InventoryTransactionType.adjustmentIn:
        return 'تسوية جردية (إضافة)';
      case InventoryTransactionType.adjustmentOut:
        return 'تسوية جردية (خصم)';
      case InventoryTransactionType.openingBalance:
        return 'رصيد افتتاحي';
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

    final cardAsync = ref.watch(productStockCardProvider(widget.productId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1100,
        height: 750,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_toggle_off,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'كارت حركة الصنف (سجل المخزون)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.productCode.isNotEmpty
                                    ? widget.productCode
                                    : widget.productId.substring(0, 8),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 2. Body
            Expanded(
              child: cardAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text('فشل تحميل حركة الصنف: $err'),
                    ],
                  ),
                ),
                data: (cardData) {
                  // Filter movements
                  final filteredMovements = cardData.movements.where((m) {
                    if (_directionFilter == 'inbound' &&
                        m.direction != InventoryMovementDirection.inbound) {
                      return false;
                    }
                    if (_directionFilter == 'outbound' &&
                        m.direction != InventoryMovementDirection.outbound) {
                      return false;
                    }
                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.trim().toLowerCase();
                      final matchRef =
                          m.referenceId?.toLowerCase().contains(q) ?? false;
                      final matchWh =
                          m.warehouseName.toLowerCase().contains(q);
                      final matchUnit = m.unitName.toLowerCase().contains(q);
                      if (!matchRef && !matchWh && !matchUnit) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  return Column(
                    children: [
                      // KPI Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131D2D)
                              : const Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: 'الرصيد التراكمي الإجمالي',
                                value: _formatNumber(cardData.currentStock),
                                subtitle: 'بالوحدة الأساسية',
                                color: cardData.currentStock > 0
                                    ? AppColors.success
                                    : (cardData.currentStock == 0
                                        ? AppColors.warning
                                        : AppColors.error),
                                icon: Icons.inventory_2,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'إجمالي الوارد (+)',
                                value: _formatNumber(cardData.totalInbound),
                                subtitle: 'مشتريات وتسويات موجبة',
                                color: const Color(0xFF10B981),
                                icon: Icons.arrow_downward,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'إجمالي المنصرف (-)',
                                value: _formatNumber(cardData.totalOutbound),
                                subtitle: 'مبيعات وتسويات عجز',
                                color: const Color(0xFFEF4444),
                                icon: Icons.arrow_upward,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'عدد الحركات المسجلة',
                                value: cardData.movements.length.toString(),
                                subtitle: 'عمليات مخزنية',
                                color: AppColors.primary,
                                icon: Icons.receipt_long_outlined,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filter Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Direction Filter Chips
                            _buildFilterChip('all', 'جميع الحركات', isDark),
                            const SizedBox(width: 8),
                            _buildFilterChip('inbound', 'وارد فقط (+)', isDark,
                                color: const Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            _buildFilterChip('outbound', 'منصرف فقط (-)', isDark,
                                color: const Color(0xFFEF4444)),
                            const Spacer(),
                            // Search box
                            SizedBox(
                              width: 280,
                              height: 38,
                              child: TextField(
                                onChanged: (val) {
                                  setState(() => _searchQuery = val);
                                },
                                decoration: InputDecoration(
                                  hintText: 'بحث برقم المستند أو المستودع...',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 18,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 8,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Movements Table
                      Expanded(
                        child: filteredMovements.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 54,
                                      color: secondaryTextColor.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد حركات مخزنية مسجلة لهذا الصنف',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryTextColor,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                itemCount: filteredMovements.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: borderColor),
                                itemBuilder: (context, index) {
                                  final m = filteredMovements[index];
                                  final isInbound = m.direction ==
                                      InventoryMovementDirection.inbound;
                                  final typeName =
                                      _resolveTransactionTypeName(
                                    m.type,
                                    m.referenceType,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        // Movement Icon & Type
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isInbound
                                                ? const Color(0xFF10B981)
                                                    .withOpacity(0.12)
                                                : const Color(0xFFEF4444)
                                                    .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isInbound
                                                ? Icons.arrow_downward
                                                : Icons.arrow_upward,
                                            size: 18,
                                            color: isInbound
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Movement Type & Date
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                typeName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDateTime(m.date),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: secondaryTextColor,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Warehouse
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.storefront_outlined,
                                                size: 15,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: Text(
                                                  m.warehouseName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: secondaryTextColor,
                                                    fontFamily: 'Cairo',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Reference Document
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.tag,
                                                size: 15,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  m.referenceId != null &&
                                                          m.referenceId!
                                                              .isNotEmpty
                                                      ? m.referenceId!
                                                      : 'تلقائي',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    color: secondaryTextColor,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Unit & Qty
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${_formatNumber(m.quantity)} ${m.unitName}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ),

                                        // In/Out Movement Base Quantity
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            isInbound
                                                ? '+${_formatNumber(m.baseQuantity)}'
                                                : '-${_formatNumber(m.baseQuantity)}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                              color: isInbound
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),

                                        // Running Balance After Movement
                                        Container(
                                          width: 110,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: borderColor,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'الرصيد',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: secondaryTextColor,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                              Text(
                                                _formatNumber(
                                                    m.runningBalance),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                  color: m.runningBalance > 0
                                                      ? AppColors.primary
                                                      : (m.runningBalance == 0
                                                          ? secondaryTextColor
                                                          : AppColors.error),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String filterKey,
    String label,
    bool isDark, {
    Color? color,
  }) {
    final isSelected = _directionFilter == filterKey;
    final activeColor = color ?? AppColors.primary;

    return InkWell(
      onTap: () => setState(() => _directionFilter = filterKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : null,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontFamily: 'Cairo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: color,
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
