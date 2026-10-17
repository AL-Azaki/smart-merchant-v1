import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../../../app/di/getit_instance.dart';
import '../../../../../../database/enums/inventory_transaction_status.dart';
import '../../../../../../database/enums/inventory_transaction_type.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../../../shared/design_system/tokens/colors.dart';

class StockAdjustmentDetailsDialog extends ConsumerWidget {
  final InventoryTransaction transaction;

  const StockAdjustmentDetailsDialog({
    super.key,
    required this.transaction,
  });

  static Future<void> show(
    BuildContext context,
    InventoryTransaction transaction,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => StockAdjustmentDetailsDialog(
        transaction: transaction,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadLines() async {
    final db = getIt<AppDatabase>();
    final query = db.select(db.inventoryTransactionLines).join([
      drift.innerJoin(
        db.productUnits,
        db.productUnits.id.equalsExp(db.inventoryTransactionLines.productUnitId),
      ),
      drift.innerJoin(
        db.products,
        db.products.id.equalsExp(db.productUnits.productId),
      ),
      drift.innerJoin(
        db.units,
        db.units.id.equalsExp(db.productUnits.unitId),
      ),
    ])
      ..where(
        db.inventoryTransactionLines.inventoryTransactionId
            .equals(transaction.id) &
            db.inventoryTransactionLines.businessId
                .equals(transaction.businessId),
      );

    final rows = await query.get();
    return rows.map((r) {
      final line = r.readTable(db.inventoryTransactionLines);
      final product = r.readTable(db.products);
      final unit = r.readTable(db.units);
      final pUnit = r.readTable(db.productUnits);

      return {
        'productName': product.productName,
        'productCode': product.productCode,
        'unitName': unit.unitName,
        'quantity': line.quantity,
        'unitCost': line.unitCost,
        'conversionFactor': pUnit.conversionFactor,
      };
    }).toList();
  }

  String _formatType(InventoryTransactionType type) {
    switch (type) {
      case InventoryTransactionType.adjustmentIn:
        return 'تسوية جردية (فائض - إضافة للمخزن)';
      case InventoryTransactionType.adjustmentOut:
        return 'تسوية جردية (عجز - خصم من المخزن)';
      default:
        return 'تسوية مخزنية';
    }
  }

  String _formatStatus(InventoryTransactionStatus status) {
    switch (status) {
      case InventoryTransactionStatus.posted:
        return 'معتمد ومرحل';
      case InventoryTransactionStatus.draft:
        return 'مسودة';
      case InventoryTransactionStatus.reversed:
        return 'ملغي / معكوس';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isInbound =
        transaction.transactionType == InventoryTransactionType.adjustmentIn;
    final accentColor =
        isInbound ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 800,
        height: 550,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fact_check_outlined,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatType(transaction.transactionType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'رقم المستند: ${transaction.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('yyyy/MM/dd  hh:mm a')
                                  .format(transaction.transactionDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _formatStatus(transaction.status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Table of Lines
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadLines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('خطأ في تحميل تفاصيل التسوية: ${snapshot.error}'),
                    );
                  }

                  final lines = snapshot.data ?? [];
                  if (lines.isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد أصناف مسجلة في هذه التسوية',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
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
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'الصنف / المنتج',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'الوحدة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                isInbound ? 'كمية الفائض (+)' : 'كمية العجز (-)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: accentColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lines List
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: lines.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            final qty = (line['quantity'] as num).toDouble();
                            final qtyStr = qty == qty.roundToDouble()
                                ? qty.toInt().toString()
                                : qty.toStringAsFixed(2);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line['productName'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                        if ((line['productCode'] as String)
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'كود: ${line['productCode']}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: secondaryTextColor,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      line['unitName'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      isInbound ? '+$qtyStr' : '-$qtyStr',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: accentColor,
                                      ),
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
}
