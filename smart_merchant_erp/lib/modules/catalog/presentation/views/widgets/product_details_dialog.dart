import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../domain/models/catalog_product_item.dart';
import 'catalog_formatters.dart';

void showProductDetailsDialog(
  BuildContext context,
  CatalogProductItem item,
  String categoryName,
  String Function(String) unitNameResolver,
  bool isDark,
  VoidCallback onEdit,
  String currency,
) {
  String price(double value) => formatCatalogPrice(value, currency);
  final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
  final baseUnitLabel = unitNameResolver(item.baseUnit.unitId);

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'التصنيف: $categoryName | كود: ${item.product.productCode.isNotEmpty ? item.product.productCode : "بدون كود"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Current Inventory Snapshot
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'المتوفر بالمخزن',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCatalogNumber(item.stockQuantity)} $baseUnitLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'عدد الوحدات المعرفة',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.units.length} وحدات',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'تفاصيل وحدات المنتج وأسعارها:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Units Table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                      ),
                      columns: const [
                        DataColumn(label: Text('الوحدة')),
                        DataColumn(label: Text('المعامل')),
                        DataColumn(label: Text('سعر الشراء')),
                        DataColumn(label: Text('سعر البيع')),
                        DataColumn(label: Text('الباركود')),
                        DataColumn(label: Text('المتوفر بالوحدة')),
                      ],
                      rows: item.units.map((unit) {
                        final currentUnitName = unitNameResolver(unit.unitId);
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    currentUnitName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (unit.isBaseUnit) ...[
                                    const SizedBox(width: 4),
                                    const Text(
                                      '(أساسية)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                '×${formatCatalogNumber(unit.conversionFactor)}',
                              ),
                            ),
                            DataCell(Text(price(unit.purchasePrice))),
                            DataCell(
                              Text(
                                price(unit.sellingPrice),
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                unit.barcode ?? '-',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                unit.isBaseUnit
                                    ? '${formatCatalogNumber(item.stockQuantity)} $currentUnitName'
                                    : unit.conversionFactor > 0
                                    ? '${formatCatalogNumber(item.stockQuantity / unit.conversionFactor)} $currentUnitName'
                                    : '-',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل المنتج والوحدات'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
