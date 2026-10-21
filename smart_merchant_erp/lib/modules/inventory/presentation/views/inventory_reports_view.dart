import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/inventory_reports_service.dart';
import '../providers/inventory_provider.dart';
import '../providers/inventory_reports_provider.dart';
import '../widgets/inventory_report_pdf_service.dart';

/// Interactive Inventory Reports View (صفحة التقارير المخزنية وجرد المستودعات).
/// Features time filters, warehouse selector, report types, instant preview,
/// and official corporate PDF generation matching standard commercial reports.
class InventoryReportsView extends ConsumerStatefulWidget {
  const InventoryReportsView({super.key});

  @override
  ConsumerState<InventoryReportsView> createState() => _InventoryReportsViewState();
}

class _InventoryReportsViewState extends ConsumerState<InventoryReportsView> {
  final _searchController = TextEditingController();
  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _qtyFormat = NumberFormat('#,##0.##', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final filter = ref.watch(inventoryReportFilterProvider);
    final filterNotifier = ref.read(inventoryReportFilterProvider.notifier);
    final reportAsync = ref.watch(inventoryReportDataProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header & Actions ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assessment_rounded, color: Color(0xFF1E3A8A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التقارير المخزنية وجرد الكميات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        Text(
                          'معاينة حية للكميات المتوفرة، تقييم التكلفة والبيع، وطباعة كشوفات الجرد الرسمية',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Actions: Print Preview & Direct Print
                  reportAsync.maybeWhen(
                    data: (summary) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.preview_rounded, size: 18),
                          label: const Text('معاينة قبل الطباعة', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => InventoryReportPdfService.showPreviewDialog(
                            context: context,
                            summary: summary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: const Text('طباعة فورية', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => InventoryReportPdfService.printDirect(
                            context: context,
                            summary: summary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          tooltip: 'مشاركة PDF',
                          onPressed: () => InventoryReportPdfService.shareDirect(
                            context: context,
                            summary: summary,
                          ),
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Comprehensive Filter Control Bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Time Presets
                      Text('الفترة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                      const SizedBox(width: 8),
                      _buildPresetChip('الكل', 'all', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('اليوم', 'today', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('هذا الأسبوع', 'week', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('هذا الشهر', 'month', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildCustomDateChip(filter, filterNotifier, context),

                      const Spacer(),

                      // Warehouse Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filter.warehouseId,
                            icon: const Icon(Icons.warehouse_rounded, size: 18),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            onChanged: (val) {
                              if (val != null) filterNotifier.setWarehouse(val);
                            },
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('جميع المخازن والمستودعات')),
                              ...?warehousesAsync.value?.map(
                                (w) => DropdownMenuItem(value: w.id, child: Text(w.warehouseName)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Report Type Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filter.reportType,
                            icon: const Icon(Icons.category_rounded, size: 18),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            onChanged: (val) {
                              if (val != null) filterNotifier.setReportType(val);
                            },
                            items: const [
                              DropdownMenuItem(value: 'availableStock', child: Text('1. تقرير الكميات المتوفرة')),
                              DropdownMenuItem(value: 'unavailableStock', child: Text('2. تقرير الكميات الغير متوفرة (النافدة)')),
                              DropdownMenuItem(value: 'lowStock', child: Text('3. تقرير النواقص وحد الطلب')),
                              DropdownMenuItem(value: 'allItems', child: Text('4. تقرير الجرد الشامل لكافة الأصناف')),
                              DropdownMenuItem(value: 'negativeStock', child: Text('5. تقرير الأصناف ذات الرصيد السالب')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'البحث السريع برقم الصنف، الاسم، أو الباركود...',
                              hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        filterNotifier.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                            onChanged: (val) => filterNotifier.setSearchQuery(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Main Content Area ──
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('خطأ في تحميل التقرير المخزني: $err', style: const TextStyle(color: Colors.red)),
                ),
                data: (summary) {
                  return Column(
                    children: [
                      // KPI Metrics Row
                      _buildKpiRow(summary, surface, borderColor, textPrimary, textSecondary),
                      const SizedBox(height: 14),

                      // Interactive Data Table Card
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  border: Border(bottom: BorderSide(color: borderColor)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.table_chart_rounded, color: Color(0xFF1E3A8A), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'معاينة الجدول: ${summary.reportTypeName} (${summary.selectedWarehouseName})',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'عدد السجلات: ${summary.items.length}',
                                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Records
                              if (summary.items.isEmpty)
                                const Expanded(
                                  child: Center(
                                    child: Text(
                                      'لا توجد أصناف مطابقة لمعايير الفلترة المحددة',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                )
                              else
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowHeight: 42,
                                        dataRowMinHeight: 44,
                                        dataRowMaxHeight: 44,
                                        headingRowColor: WidgetStateProperty.all(
                                          isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('رقم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('اسم الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text('الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(numeric: true, label: Text('الكمية المتوفرة', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(numeric: true, label: Text('سعر التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(numeric: true, label: Text('إجمالي التكلفة', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(numeric: true, label: Text('سعر البيع', style: TextStyle(fontWeight: FontWeight.bold))),
                                          DataColumn(numeric: true, label: Text('إجمالي البيع', style: TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: summary.items.map((item) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(item.productCode, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                    if (item.isLowStock) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                                                        ),
                                                        child: const Text('حد الطلب', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(item.unitName)),
                                              DataCell(
                                                Text(
                                                  _qtyFormat.format(item.quantity),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: item.quantity <= 0 ? Colors.red : textPrimary,
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(_moneyFormat.format(item.costPrice))),
                                              DataCell(
                                                Text(
                                                  _moneyFormat.format(item.totalCost),
                                                  style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              DataCell(Text(_moneyFormat.format(item.sellingPrice))),
                                              DataCell(
                                                Text(
                                                  _moneyFormat.format(item.totalSelling),
                                                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),

                              // Bottom Sticky Total Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                                  border: Border(top: BorderSide(color: borderColor, width: 1.5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'إجمالي القيمة: (${summary.items.length} صنف)',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'إجمالي الكمية: ${_qtyFormat.format(summary.totalQuantity)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          'إجمالي التكلفة: ${_moneyFormat.format(summary.totalCostValue)} YER',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          'إجمالي البيع: ${_moneyFormat.format(summary.totalSellingValue)} YER',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          'الأرباح المتوقعة: ${_moneyFormat.format(summary.totalExpectedProfit)} YER',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669)),
                                        ),
                                      ],
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    String presetKey,
    String activePreset,
    InventoryReportFilterNotifier notifier,
  ) {
    final isSelected = activePreset == presetKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade700),
      onSelected: (_) => notifier.setDatePreset(presetKey),
    );
  }

  Widget _buildCustomDateChip(
    InventoryReportFilter filter,
    InventoryReportFilterNotifier notifier,
    BuildContext context,
  ) {
    final isCustom = filter.dateRangePreset == 'custom';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: isCustom ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.transparent,
        side: BorderSide(color: isCustom ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: const Icon(Icons.date_range_rounded, size: 16),
      label: Text(
        filter.customStartDate != null && filter.customEndDate != null
            ? '${_dateFormat.format(filter.customStartDate!)} - ${_dateFormat.format(filter.customEndDate!)}'
            : 'فترة محددة',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
          color: isCustom ? const Color(0xFF1E3A8A) : Colors.grey.shade800,
        ),
      ),
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          initialDateRange: filter.customStartDate != null && filter.customEndDate != null
              ? DateTimeRange(start: filter.customStartDate!, end: filter.customEndDate!)
              : null,
        );
        if (picked != null) {
          notifier.setDatePreset('custom', start: picked.start, end: picked.end);
        }
      },
    );
  }

  Widget _buildKpiRow(
    InventoryReportSummary summary,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (4 * 10)) / 5;
        return Row(
          children: [
            _buildKpiCard(
              title: 'عدد الأصناف',
              value: '${summary.totalItemsCount}',
              subtitle: '${summary.lowStockCount} صنف بحاجة للطلب',
              color: const Color(0xFF3B82F6),
              icon: Icons.inventory_2_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'إجمالي الكميات',
              value: _qtyFormat.format(summary.totalQuantity),
              subtitle: 'رصيد حقيقي بالمستودعات',
              color: const Color(0xFF8B5CF6),
              icon: Icons.warehouse_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'إجمالي التكلفة',
              value: '${_moneyFormat.format(summary.totalCostValue)} YER',
              subtitle: 'متوسط التكلفة المرجح',
              color: const Color(0xFFDC2626),
              icon: Icons.monetization_on_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'إجمالي البيع',
              value: '${_moneyFormat.format(summary.totalSellingValue)} YER',
              subtitle: 'القيمة السوقية للبضاعة',
              color: const Color(0xFF2563EB),
              icon: Icons.storefront_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'الربح المتوقع',
              value: '${_moneyFormat.format(summary.totalExpectedProfit)} YER',
              subtitle: summary.totalSellingValue > 0
                  ? 'الهامش: ${((summary.totalExpectedProfit / summary.totalSellingValue) * 100).toStringAsFixed(1)}%'
                  : 'هامش الربح',
              color: const Color(0xFF059669),
              icon: Icons.trending_up_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isHighlight: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required double width,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    bool isHighlight = false,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.08) : surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? color : borderColor, width: isHighlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isHighlight ? color : textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }
}
