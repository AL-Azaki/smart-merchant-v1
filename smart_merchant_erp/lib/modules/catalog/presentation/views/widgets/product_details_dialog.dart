import '../../../../inventory/presentation/dialogs/product_stock_card_dialog.dart';
import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../domain/models/catalog_product_item.dart';
import '../../../domain/services/unit_quantity_formatter.dart';
import 'catalog_formatters.dart';

void showProductDetailsDialog(
  BuildContext context,
  CatalogProductItem item,
  String categoryName,
  String Function(String) unitNameResolver,
  bool isDark,
  VoidCallback? onEdit,
  String currency,
) {
  String price(double value) => formatCatalogPrice(value, currency);
  final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
  final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
  final baseUnitLabel = unitNameResolver(item.baseUnit.unitId);

  // Financial calculations
  final effectiveBaseCost = item.baseAverageCost > 0
      ? item.baseAverageCost
      : (item.baseUnit.purchasePrice > 0 ? item.baseUnit.purchasePrice : 0.0);

  final totalInventoryValue = item.stockQuantity * effectiveBaseCost;
  final baseSelling = item.baseUnit.sellingPrice;
  final unitProfit = (baseSelling - effectiveBaseCost).clamp(0.0, double.infinity);
  final profitMarginPercent = effectiveBaseCost > 0
      ? ((unitProfit / effectiveBaseCost) * 100).round()
      : 0;

  final stockBreakdown = item.units.length > 1
      ? UnitQuantityFormatter.formatBreakdown(
          baseQuantity: item.stockQuantity,
          units: item.units,
          unitNameResolver: unitNameResolver,
        )
      : '${formatCatalogNumber(item.stockQuantity)} $baseUnitLabel';

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP HEADER (Icon, Title, Code, Close)
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.productName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                'التصنيف: $categoryName',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white10 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                'كود الصنف: ${item.product.productCode.isNotEmpty ? item.product.productCode : "بدون كود"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 18),

              // 2. FULL-WIDTH KPI DASHBOARD METRIC STRIP (4 Connected Cards)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  final card1 = _buildMetricTile(
                    title: 'الرصيد المتوفر بالمخزن',
                    value: stockBreakdown,
                    subtitle: item.units.length > 1
                        ? '(${formatCatalogNumber(item.stockQuantity)} $baseUnitLabel)'
                        : 'الوحدة الأساسية',
                    icon: Icons.warehouse_rounded,
                    iconColor: AppColors.primary,
                    isDark: isDark,
                    borderColor: borderColor,
                  );
                  final card2 = _buildMetricTile(
                    title: 'إجمالي قيمة المخزون (WAC)',
                    value: price(totalInventoryValue),
                    subtitle: 'التكلفة: ${price(effectiveBaseCost)} / $baseUnitLabel',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    isDark: isDark,
                    borderColor: borderColor,
                  );
                  final card3 = _buildMetricTile(
                    title: 'الوحدات المعرفة للصنف',
                    value: '${item.units.length} وحدات',
                    subtitle: 'الأساسية: $baseUnitLabel',
                    icon: Icons.layers_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    borderColor: borderColor,
                  );
                  final card4 = _buildMetricTile(
                    title: 'هامش الربح (أساسي)',
                    value: profitMarginPercent > 0 ? '+$profitMarginPercent%' : '—',
                    subtitle: 'ربح: ${price(unitProfit)}',
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.success,
                    isDark: isDark,
                    borderColor: borderColor,
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        Row(children: [Expanded(child: card1), const SizedBox(width: 10), Expanded(child: card2)]),
                        const SizedBox(height: 10),
                        Row(children: [Expanded(child: card3), const SizedBox(width: 10), Expanded(child: card4)]),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 12),
                      Expanded(child: card2),
                      const SizedBox(width: 12),
                      Expanded(child: card3),
                      const SizedBox(width: 12),
                      Expanded(child: card4),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // 3. TABLE TITLE STRIP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'تفاصيل وحدات المنتج وأسعارها ومخزونها:',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.units.length} وحدات مسجلة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. FULL-WIDTH DATA TABLE WITH DYNAMIC HORIZONTAL FILL
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: LayoutBuilder(
                    builder: (context, tableConstraints) {
                      final dynamicSpacing = ((tableConstraints.maxWidth - 680) / 7).clamp(16.0, 52.0);

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 46,
                            dataRowMinHeight: 52,
                            dataRowMaxHeight: 56,
                            horizontalMargin: 20,
                            columnSpacing: dynamicSpacing,
                            headingRowColor: WidgetStateProperty.all(
                              isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            ),
                            columns: const [
                              DataColumn(label: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('معامل التحويل', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('متوسط التكلفة WAC', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('سعر الشراء', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('سعر البيع', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('الباركود', style: TextStyle(fontWeight: FontWeight.w900))),
                              DataColumn(label: Text('المتوفر بالوحدة', style: TextStyle(fontWeight: FontWeight.w900))),
                            ],
                            rows: item.units.map((unit) {
                              final currentUnitName = unitNameResolver(unit.unitId);
                              final cost = UnitQuantityFormatter.unitAverageCost(
                                baseAverageCost: effectiveBaseCost,
                                targetUnit: unit,
                              );

                              return DataRow(
                                cells: [
                                  // Unit Name & Badge
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          currentUnitName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (unit.isBaseUnit) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.primary.withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Text(
                                              'أساسية',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Multiplier
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '×${formatCatalogNumber(unit.conversionFactor)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                  ),

                                  // WAC
                                  DataCell(
                                    Text(
                                      price(cost),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),

                                  // Purchase Price
                                  DataCell(
                                    Text(
                                      price(unit.purchasePrice),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  // Selling Price
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        price(unit.sellingPrice),
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Barcode
                                  DataCell(
                                    unit.barcode != null && unit.barcode!.isNotEmpty
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.qr_code_2_rounded,
                                                size: 14,
                                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                unit.barcode!,
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text('—', style: TextStyle(color: Colors.grey)),
                                  ),

                                  // Available in this unit
                                  DataCell(
                                    Builder(
                                      builder: (_) {
                                        if (item.stockQuantity <= 0) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'نفد المخزون',
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          );
                                        }

                                        final qtyInUnit = unit.isBaseUnit
                                            ? item.stockQuantity
                                            : (unit.conversionFactor > 0
                                                ? (item.stockQuantity / unit.conversionFactor)
                                                : 0.0);

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${formatCatalogNumber(qtyInUnit)} $currentUnitName',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 5. BOTTOM ACTION FOOTER (Full Width & Minimal Clicks)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'البيانات متزامنة مع حركات المخازن والمشتريات',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: borderColor),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: borderColor),
                        ),
                        icon: const Icon(Icons.history_toggle_off, size: 18, color: AppColors.primary),
                        label: const Text('كارت حركة الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ProductStockCardDialog.show(
                            context,
                            productId: item.product.id,
                            productName: item.product.productName,
                            productCode: item.product.productCode,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text(
                          'تعديل المنتج والوحدات',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onEdit?.call();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildMetricTile({
  required String title,
  required String value,
  required String subtitle,
  required IconData icon,
  required Color iconColor,
  required bool isDark,
  required Color borderColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
