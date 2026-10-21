import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/inventory_reports_service.dart';
import '../providers/inventory_provider.dart';
import '../providers/inventory_reports_provider.dart';
import '../widgets/inventory_report_pdf_service.dart';

/// Responsive & Interactive Inventory Reports View (صفحة التقارير المخزنية وجرد المستودعات).
/// Features fully responsive LayoutBuilder, fluid Wrap containers, horizontal chip scrolling,
/// dynamic warehouse & product filters, and official A4 PDF report generation.
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
    final isMovement = filter.reportType == 'stockMovement';
    final reportAsync = isMovement ? null : ref.watch(inventoryReportDataProvider);
    final movementAsync = isMovement ? ref.watch(stockMovementReportDataProvider) : null;
    final warehousesAsync = ref.watch(activeWarehousesProvider);
    final productsAsync = ref.watch(warehouseProductsProvider(filter.warehouseId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isSmallMobile = constraints.maxWidth < 480;
          final isScrollable = isMobile || constraints.maxHeight < 720;

          final contentWidget = isMovement
              ? movementAsync!.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'خطأ في تحميل كشف حركة المخزون: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (movSummary) => _buildMovementContent(
                    movSummary,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                    isDark,
                    isMobile,
                    isScrollable,
                  ),
                )
              : reportAsync!.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'خطأ في تحميل التقرير المخزني: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (summary) => _buildValuationContent(
                    summary,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                    isDark,
                    isMobile,
                    isScrollable,
                  ),
                );

          if (isScrollable) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 10 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                    isMovement,
                    movementAsync,
                    reportAsync,
                    isMobile,
                    isSmallMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                    isDark,
                    filter,
                    filterNotifier,
                    warehousesAsync,
                    productsAsync,
                    isMovement,
                    isMobile,
                  ),
                  const SizedBox(height: 12),
                  contentWidget,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(
                  surface,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  isMovement,
                  movementAsync,
                  reportAsync,
                  false,
                  false,
                ),
                const SizedBox(height: 14),
                _buildFilterBar(
                  surface,
                  borderColor,
                  textPrimary,
                  textSecondary,
                  isDark,
                  filter,
                  filterNotifier,
                  warehousesAsync,
                  productsAsync,
                  isMovement,
                  false,
                ),
                const SizedBox(height: 14),
                Expanded(child: contentWidget),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 1. Top Header Card ──
  Widget _buildHeaderCard(
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isMovement,
    AsyncValue<StockMovementReportSummary>? movementAsync,
    AsyncValue<InventoryReportSummary>? reportAsync,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 38 : 44,
                height: isMobile ? 38 : 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assessment_rounded, color: Color(0xFF1E3A8A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMovement
                          ? 'تقرير حركة المخزون (كشف الوارد والصادر)'
                          : 'التقارير المخزنية وجرد الكميات',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (!isSmallMobile)
                      Text(
                        isMovement
                            ? 'سجل الحركات التفصيلية للأصناف والمخازن مع رصيد أول المدة، الوارد، الصادر، والرصيد التراكمي'
                            : 'معاينة حية للكميات المتوفرة، تقييم التكلفة والبيع، وطباعة كشوفات الجرد الرسمية',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                  ],
                ),
              ),
              if (!isMobile)
                _buildActionButtons(isMovement, movementAsync, reportAsync, isMobile: false),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 10),
            _buildActionButtons(isMovement, movementAsync, reportAsync, isMobile: true),
          ],
        ],
      ),
    );
  }

  // ── Action Buttons (Preview, Print, Share) ──
  Widget _buildActionButtons(
    bool isMovement,
    AsyncValue<StockMovementReportSummary>? movementAsync,
    AsyncValue<InventoryReportSummary>? reportAsync, {
    required bool isMobile,
  }) {
    if (isMovement) {
      return movementAsync?.maybeWhen(
            data: (movSummary) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.preview_rounded, size: isMobile ? 16 : 18),
                  label: Text(
                    'معاينة قبل الطباعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                  ),
                  onPressed: () => InventoryReportPdfService.showMovementPreviewDialog(
                    context: context,
                    summary: movSummary,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.print_rounded, size: isMobile ? 16 : 18),
                  label: Text(
                    'طباعة فورية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                  ),
                  onPressed: () => InventoryReportPdfService.printMovementDirect(
                    context: context,
                    summary: movSummary,
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                  ),
                  icon: Icon(Icons.share_rounded, size: isMobile ? 16 : 18),
                  tooltip: 'مشاركة PDF',
                  onPressed: () => InventoryReportPdfService.shareMovementDirect(
                    context: context,
                    summary: movSummary,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ) ??
          const SizedBox.shrink();
    } else {
      return reportAsync?.maybeWhen(
            data: (summary) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.preview_rounded, size: isMobile ? 16 : 18),
                  label: Text(
                    'معاينة قبل الطباعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                  ),
                  onPressed: () => InventoryReportPdfService.showPreviewDialog(
                    context: context,
                    summary: summary,
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.print_rounded, size: isMobile ? 16 : 18),
                  label: Text(
                    'طباعة فورية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                  ),
                  onPressed: () => InventoryReportPdfService.printDirect(
                    context: context,
                    summary: summary,
                  ),
                ),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                  ),
                  icon: Icon(Icons.share_rounded, size: isMobile ? 16 : 18),
                  tooltip: 'مشاركة PDF',
                  onPressed: () => InventoryReportPdfService.shareDirect(
                    context: context,
                    summary: summary,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ) ??
          const SizedBox.shrink();
    }
  }

  // ── 2. Responsive Filter Bar ──
  Widget _buildFilterBar(
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    InventoryReportFilter filter,
    InventoryReportFilterNotifier filterNotifier,
    AsyncValue<List<Warehouse>> warehousesAsync,
    AsyncValue<List<({String id, String name, String code})>> productsAsync,
    bool isMovement,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Time Presets with Smooth Horizontal Scroll
          Row(
            children: [
              Text(
                'الفترة:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('الكل', 'all', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('اليوم', 'today', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('هذا الأسبوع', 'week', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildPresetChip('هذا الشهر', 'month', filter.dateRangePreset, filterNotifier),
                      const SizedBox(width: 6),
                      _buildCustomDateChip(filter, filterNotifier, context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Dropdown Selectors wrapped naturally
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                    onChanged: (val) {
                      if (val != null) {
                        filterNotifier.setWarehouse(val);
                      }
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

              // Product Dropdown (Visible only for Movement Ledger)
              if (isMovement)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filter.productId,
                      icon: const Icon(Icons.inventory_2_rounded, size: 18),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      onChanged: (val) {
                        if (val != null) {
                          filterNotifier.setProduct(val);
                        }
                      },
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('جميع أصناف المخزن')),
                        ...?productsAsync.value?.map(
                          (p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.code})')),
                        ),
                      ],
                    ),
                  ),
                ),

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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                    onChanged: (val) {
                      if (val != null) {
                        filterNotifier.setReportType(val);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'availableStock', child: Text('1. تقرير الكميات المتوفرة')),
                      DropdownMenuItem(value: 'unavailableStock', child: Text('2. تقرير الكميات الغير متوفرة (النافدة)')),
                      DropdownMenuItem(value: 'lowStock', child: Text('3. تقرير النواقص وحد الطلب')),
                      DropdownMenuItem(value: 'allItems', child: Text('4. تقرير الجرد الشامل لكافة الأصناف')),
                      DropdownMenuItem(value: 'negativeStock', child: Text('5. تقرير الأصناف ذات الرصيد السالب')),
                      DropdownMenuItem(value: 'stockMovement', child: Text('6. تقرير حركة المخزون / الصنف (وارد / صادر / رصيد)')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Instant Search Field
          SizedBox(
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
        ],
      ),
    );
  }

  // ── 3. Movement Content Layout ──
  Widget _buildMovementContent(
    StockMovementReportSummary summary,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    bool isMobile,
    bool isScrollable,
  ) {
    final tableCard = Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: Color(0xFF1E3A8A), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'كشف حركة المخزون: ${summary.selectedProductName}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'عدد الحركات: ${summary.movements.length}',
                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Table Rows
          if (summary.movements.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'لا توجد حركات مخزنية مسجلة خلال الفترة المحددة',
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
                      DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('التاريخ والوقت', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('نوع الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الصنف / الوحدة', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('الجهة / البيان', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('الوارد (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('الصادر (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(numeric: true, label: Text('الرصيد الحالي', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: summary.movements.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final m = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(m.date),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          )),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.movementType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  m.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                Text(
                                  '${m.productCode} • ${m.unitName}',
                                  style: TextStyle(color: textSecondary, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '${m.partyName} ${m.referenceNumber.isNotEmpty ? "[${m.referenceNumber}]" : ""}',
                              style: TextStyle(color: textPrimary, fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              m.inQty > 0 ? '+${_qtyFormat.format(m.inQty)}' : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.inQty > 0 ? const Color(0xFF16A34A) : textSecondary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              m.outQty > 0 ? '-${_qtyFormat.format(m.outQty)}' : '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.outQty > 0 ? const Color(0xFFDC2626) : textSecondary,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                _qtyFormat.format(m.runningBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: m.runningBalance < 0 ? Colors.red : textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Bottom Sticky Summary Row (Responsive Wrap)
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 6),
                    Text(
                      'ملخص الفترة (${summary.dateFilterTitle}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'رصيد أول المدة: ${_qtyFormat.format(summary.openingBalance)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 11 : 13,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      'إجمالي الوارد: +${_qtyFormat.format(summary.totalIn)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      'إجمالي الصادر: -${_qtyFormat.format(summary.totalOut)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الرصيد الحالي: ${_qtyFormat.format(summary.closingBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 11 : 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMovementKpiRow(summary, surface, borderColor, textPrimary, textSecondary),
        const SizedBox(height: 12),
        if (isScrollable)
          SizedBox(height: 480, child: tableCard)
        else
          Expanded(child: tableCard),
      ],
    );
  }

  // ── 4. Valuation Content Layout ──
  Widget _buildValuationContent(
    InventoryReportSummary summary,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    bool isMobile,
    bool isScrollable,
  ) {
    final tableCard = Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_chart_rounded, color: Color(0xFF1E3A8A), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'معاينة الجدول: ${summary.reportTypeName}',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
                          DataCell(Text(
                            item.productCode,
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          )),
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
                                    child: const Text(
                                      'حد الطلب',
                                      style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                    ),
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

          // Bottom Sticky Summary Row (Responsive Wrap)
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              border: Border(top: BorderSide(color: borderColor, width: 1.5)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'إجمالي القيمة: (${summary.items.length} صنف)',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'إجمالي الكمية: ${_qtyFormat.format(summary.totalQuantity)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'إجمالي التكلفة: ${_moneyFormat.format(summary.totalCostValue)} YER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      'إجمالي البيع: ${_moneyFormat.format(summary.totalSellingValue)} YER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      'الأرباح: ${_moneyFormat.format(summary.totalExpectedProfit)} YER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 11 : 13,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpiRow(summary, surface, borderColor, textPrimary, textSecondary),
        const SizedBox(height: 12),
        if (isScrollable)
          SizedBox(height: 480, child: tableCard)
        else
          Expanded(child: tableCard),
      ],
    );
  }

  // ── 5. Responsive KPI Rows ──
  Widget _buildKpiRow(
    InventoryReportSummary summary,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // On wide screens (>= 950): 5 cards in 1 row
        // On tablet (>= 600): 3 on row 1, 2 on row 2
        // On phones (< 600): 2 cards per row
        final cardWidth = w >= 950
            ? (w - (4 * 10)) / 5
            : w >= 600
                ? (w - (2 * 10)) / 3
                : (w - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
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

  Widget _buildMovementKpiRow(
    StockMovementReportSummary summary,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // On desktop (>= 800): 4 cards in 1 row
        // On mobile (< 800): 2 cards per row
        final cardWidth = w >= 800 ? (w - (3 * 10)) / 4 : (w - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'رصيد أول المدة',
              value: _qtyFormat.format(summary.openingBalance),
              subtitle: 'الرصيد الافتتاحي السابق',
              color: const Color(0xFF64748B),
              icon: Icons.history_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildKpiCard(
              title: 'إجمالي الوارد (+)',
              value: '+${_qtyFormat.format(summary.totalIn)}',
              subtitle: 'المشتريات والتحويلات الواردة',
              color: const Color(0xFF16A34A),
              icon: Icons.arrow_downward_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isHighlight: true,
            ),
            _buildKpiCard(
              title: 'إجمالي الصادر (-)',
              value: '-${_qtyFormat.format(summary.totalOut)}',
              subtitle: 'المبيعات والتحويلات الصادرة',
              color: const Color(0xFFDC2626),
              icon: Icons.arrow_upward_rounded,
              width: cardWidth,
              surface: surface,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            _buildKpiCard(
              title: 'الرصيد الحالي (الختامي)',
              value: _qtyFormat.format(summary.closingBalance),
              subtitle: 'رصيد الصنف نهاية الفترة',
              color: const Color(0xFF1E3A8A),
              icon: Icons.account_balance_wallet_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? color : textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Helper Chips ──
  Widget _buildPresetChip(
    String label,
    String presetKey,
    String activePreset,
    InventoryReportFilterNotifier notifier,
  ) {
    final isSelected = activePreset == presetKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      ),
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
          fontSize: 11,
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
}
