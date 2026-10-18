import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../../../database/enums/inventory_transfer_status.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/inventory_section_header.dart';
import '../../widgets/inventory_empty_state.dart';
import '../../widgets/inventory_record_dialog.dart';
import 'widgets/warehouse_transfer_dialog.dart';

class WarehouseTransfersView extends ConsumerStatefulWidget {
  const WarehouseTransfersView({super.key});
  @override
  ConsumerState<WarehouseTransfersView> createState() =>
      _WarehouseTransfersViewState();
}

class _WarehouseTransfersViewState
    extends ConsumerState<WarehouseTransfersView> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(warehouseTransfersStreamProvider);
    final names = {
      for (final w
          in ref.watch(activeWarehousesProvider).valueOrNull ?? <Warehouse>[])
        w.id: w.warehouseName,
    };
    return Column(
      children: [
        InventorySectionHeader(
          title: 'التحويلات بين المستودعات',
          subtitle: 'نقل الكميات وتكلفتها مع سجل واضح لكل تحويل',
          icon: Icons.swap_horiz_rounded,
          action: FilledButton.icon(
            onPressed: () => WarehouseTransferDialog.show(context),
            icon: const Icon(Icons.add),
            label: const Text('تحويل مخزني جديد'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'ابحث برقم التحويل أو المستودع أو الملاحظات',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton.icon(
                onPressed: () =>
                    ref.invalidate(warehouseTransfersStreamProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('تعذر تحميل التحويلات، أعد المحاولة'),
              ),
            ),
            data: (all) {
              final items = all
                  .where(
                    (t) =>
                        '${t.transferNumber} ${t.notes ?? ''} ${names[t.fromWarehouseId] ?? ''} ${names[t.toWarehouseId] ?? ''}'
                            .toLowerCase()
                            .contains(_query),
                  )
                  .toList();
              if (items.isEmpty) {
                return InventoryEmptyState(
                  icon: Icons.swap_horiz_rounded,
                  title: all.isEmpty
                      ? 'لا توجد تحويلات مخزنية مسجلة'
                      : 'لا توجد تحويلات تطابق البحث',
                  message:
                      'انقل البضاعة بين المستودعات وتابع تفاصيل التحويل هنا.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final t = items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    leading: Icon(
                      Icons.swap_horiz_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      '${names[t.fromWarehouseId] ?? 'مستودع المصدر'} ← ${names[t.toWarehouseId] ?? 'مستودع المستلم'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${t.transferNumber} · ${DateFormat('yyyy/MM/dd HH:mm').format(t.transferDate)}\n${t.status == InventoryTransferStatus.completed
                          ? 'مكتمل'
                          : t.status == InventoryTransferStatus.cancelled
                          ? 'ملغي'
                          : 'قيد الانتظار'}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => InventoryRecordDialog(
                        title: 'تفاصيل التحويل',
                        load: (workflow) => workflow.loadTransfer(t.id),
                      ),
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
