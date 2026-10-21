import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_instance.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/inventory_reports_service.dart';

/// Filter state for inventory reports
class InventoryReportFilter {
  final String warehouseId; // 'all' or specific UUID
  final String reportType; // 'availableStock', 'lowStock', 'negativeStock', 'allItems'
  final String dateRangePreset; // 'all', 'today', 'week', 'month', 'custom'
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String searchQuery;

  const InventoryReportFilter({
    this.warehouseId = 'all',
    this.reportType = 'availableStock',
    this.dateRangePreset = 'all',
    this.customStartDate,
    this.customEndDate,
    this.searchQuery = '',
  });

  InventoryReportFilter copyWith({
    String? warehouseId,
    String? reportType,
    String? dateRangePreset,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? searchQuery,
  }) {
    return InventoryReportFilter(
      warehouseId: warehouseId ?? this.warehouseId,
      reportType: reportType ?? this.reportType,
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Calculates actual start and end dates based on preset
  ({DateTime? start, DateTime? end, String label}) get resolvedDates {
    final now = DateTime.now();
    switch (dateRangePreset) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return (start: start, end: now, label: 'اليوم');
      case 'week':
        final start = now.subtract(Duration(days: now.weekday % 7));
        return (start: DateTime(start.year, start.month, start.day), end: now, label: 'هذا الأسبوع');
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        return (start: start, end: now, label: 'هذا الشهر');
      case 'custom':
        return (
          start: customStartDate,
          end: customEndDate,
          label: customStartDate != null && customEndDate != null
              ? '${customStartDate!.year}-${customStartDate!.month}-${customStartDate!.day} إلى ${customEndDate!.year}-${customEndDate!.month}-${customEndDate!.day}'
              : 'فترة مخصصة'
        );
      case 'all':
      default:
        return (start: null, end: null, label: 'جميع الفترات');
    }
  }
}

/// Filter state controller
class InventoryReportFilterNotifier extends StateNotifier<InventoryReportFilter> {
  InventoryReportFilterNotifier() : super(const InventoryReportFilter());

  void setWarehouse(String warehouseId) {
    state = state.copyWith(warehouseId: warehouseId);
  }

  void setReportType(String reportType) {
    state = state.copyWith(reportType: reportType);
  }

  void setDatePreset(String preset, {DateTime? start, DateTime? end}) {
    state = state.copyWith(
      dateRangePreset: preset,
      customStartDate: start,
      customEndDate: end,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetFilters() {
    state = const InventoryReportFilter();
  }
}

final inventoryReportFilterProvider =
    StateNotifierProvider.autoDispose<InventoryReportFilterNotifier, InventoryReportFilter>(
  (ref) => InventoryReportFilterNotifier(),
);

/// Report summary data provider that reacts to filter changes
final inventoryReportDataProvider =
    FutureProvider.autoDispose<InventoryReportSummary>((ref) async {
  ref.watch(sessionNotifierProvider);
  final filter = ref.watch(inventoryReportFilterProvider);
  final service = getIt<InventoryReportsService>();

  final dates = filter.resolvedDates;

  return await service.generateReport(
    warehouseId: filter.warehouseId,
    reportType: filter.reportType,
    startDate: dates.start,
    endDate: dates.end,
    dateFilterLabel: dates.label,
    searchQuery: filter.searchQuery,
  );
});
