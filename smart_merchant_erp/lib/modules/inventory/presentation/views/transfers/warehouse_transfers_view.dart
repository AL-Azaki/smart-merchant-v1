import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../database/enums/inventory_transfer_status.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../providers/inventory_provider.dart';
import 'widgets/warehouse_transfer_dialog.dart';

class WarehouseTransfersView extends ConsumerStatefulWidget {
  const WarehouseTransfersView({super.key});

  @override
  ConsumerState<WarehouseTransfersView> createState() =>
      _WarehouseTransfersViewState();
}

class _WarehouseTransfersViewState
    extends ConsumerState<WarehouseTransfersView> {
  String _searchQuery = '';

  String _formatStatus(InventoryTransferStatus status) {
    switch (status) {
      case InventoryTransferStatus.completed:
        return 'مكتمل ومرحل';
      case InventoryTransferStatus.pending:
        return 'قيد الانتظار';
      case InventoryTransferStatus.cancelled:
        return 'ملغي';
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

    final transfersAsync = ref.watch(warehouseTransfersStreamProvider);
    final warehousesAsync = ref.watch(activeWarehousesProvider);

    final warehouseMap = <String, String>{};
    for (final wh in warehousesAsync.valueOrNull ?? <Warehouse>[]) {
      warehouseMap[wh.id] = wh.warehouseName;
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: surfaceColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التحويلات بين المستودعات',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                ),
                      ),
                      Text(
                        'سجل حركة نقل البضائع بين الفروع والمستودعات',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => WarehouseTransferDialog.show(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'تحويل مخزني جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 320,
                height: 40,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'بحث برقم التحويل أو الملاحظات...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontFamily: 'Cairo',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
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

        // List / Table
        Expanded(
          child: transfersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'خطأ في تحميل سجل التحويلات: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (transfers) {
              final filtered = transfers.where((t) {
                if (_searchQuery.trim().isEmpty) return true;
                final q = _searchQuery.trim().toLowerCase();
                final matchNum = t.transferNumber.toLowerCase().contains(q);
                final matchNotes =
                    t.notes?.toLowerCase().contains(q) ?? false;
                return matchNum || matchNotes;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 56,
                        color: secondaryTextColor.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد تحويلات مخزنية مسجلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryTextColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'اضغط على "تحويل مخزني جديد" لنقل بضاعة بين المستودعات',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor.withValues(alpha: 0.8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: filtered.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  final fromName =
                      warehouseMap[t.fromWarehouseId] ?? 'مستودع مصدر';
                  final toName =
                      warehouseMap[t.toWarehouseId] ?? 'مستودع مستلم';

                  final isCompleted =
                      t.status == InventoryTransferStatus.completed;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.swap_horiz,
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : AppColors.warning,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.transferNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.1)
                                          : AppColors.warning
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _formatStatus(t.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? const Color(0xFF10B981)
                                            : AppColors.warning,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    fromName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    toName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      fontFamily: 'Cairo',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (t.notes != null &&
                                      t.notes!.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: Text(
                                        '(${t.notes})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondaryTextColor,
                                          fontFamily: 'Cairo',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Date & Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('yyyy/MM/dd')
                                  .format(t.transferDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: secondaryTextColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              DateFormat('hh:mm a')
                                  .format(t.transferDate),
                              style: TextStyle(
                                fontSize: 10,
                                color: secondaryTextColor.withValues(alpha: 0.8),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
