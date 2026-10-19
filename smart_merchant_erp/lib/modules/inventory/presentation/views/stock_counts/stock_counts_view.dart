import '../../../../../kernel/storage/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../database/enums/stock_count_status.dart';
import '../../providers/stock_counts_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/inventory_section_header.dart';
import '../../widgets/inventory_empty_state.dart';
import 'widgets/stock_count_form_sheet.dart';
import 'stock_count_details_view.dart';

String stockCountStatusLabel(
  bool draft,
  String financial, {
  bool cancelled = false,
}) => cancelled
    ? 'ملغي'
    : draft
    ? 'مسودة'
    : switch (financial) {
        'Pending' => 'بانتظار المعالجة',
        'PendingFinancialSetup' => 'بانتظار التهيئة المالية',
        'Settled' => 'مكتمل',
        'NotRequired' => 'دون فروقات مالية',
        _ => 'جرد سابق',
      };

class StockCountsView extends ConsumerStatefulWidget {
  const StockCountsView({super.key});
  @override
  ConsumerState<StockCountsView> createState() => _StockCountsViewState();
}

class _StockCountsViewState extends ConsumerState<StockCountsView> {
  String _query = '', _filter = 'all';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockCountsNotifierProvider);
    final warehouseNames = {
      for (final w
          in ref.watch(activeWarehousesProvider).valueOrNull ?? <Warehouse>[])
        w.id: w.warehouseName,
    };
    final theme = Theme.of(context);
    return Column(
      children: [
        InventorySectionHeader(
          title: 'الجرد التصحيحي',
          subtitle: 'عدّ المنتجات، صحّح الرصيد، ثم عالج الفروقات',
          icon: Icons.fact_check_outlined,
          action: FilledButton.icon(
            onPressed: () async {
              final id = await StockCountFormSheet.show(context);
              if (id != null && context.mounted) {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockCountDetailsView(countId: id),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('جرد جديد'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'ابحث برقم الجرد أو المستودع أو الملاحظات',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in {
                  'all': 'الكل',
                  'draft': 'المسودات',
                  'pending': 'بانتظار المعالجة',
                  'done': 'المكتمل',
                }.entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(option.value),
                      selected: _filter == option.key,
                      onSelected: (_) => setState(() => _filter = option.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton.icon(
                onPressed: () => ref.invalidate(stockCountsNotifierProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('تعذر تحميل الجرد، أعد المحاولة'),
              ),
            ),
            data: (counts) {
              final filtered = counts.where((c) {
                final draft = c.status == StockCountStatus.draft;
                if (_filter == 'draft' && !draft ||
                    _filter == 'pending' &&
                        (c.status != StockCountStatus.posted ||
                            !['Pending', 'PendingFinancialSetup'].contains(c.financialStatus)) ||
                    _filter == 'done' &&
                        (c.status != StockCountStatus.posted ||
                            ![
                              'Settled',
                              'NotRequired',
                            ].contains(c.financialStatus))) {
                  return false;
                }
                return '${c.countNumber} ${c.notes ?? ''} ${warehouseNames[c.warehouseId] ?? ''}'
                    .toLowerCase()
                    .contains(_query);
              }).toList();
              if (filtered.isEmpty) {
                return InventoryEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: counts.isEmpty
                      ? 'ابدأ الجرد التصحيحي الأول'
                      : 'لا يوجد جرد يطابق التصفية',
                  message: counts.isEmpty
                      ? 'أدخل الكمية الفعلية لكل منتج ثم راجع الفروقات قبل التصحيح.'
                      : 'جرّب بحثاً آخر أو اختر عرض الكل.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final c = filtered[index],
                      draft = c.status == StockCountStatus.draft;
                  final color = !draft &&
                          (c.financialStatus == 'Pending' ||
                              c.financialStatus == 'PendingFinancialSetup')
                      ? (theme.brightness == Brightness.dark
                            ? const Color(0xFFFCD34D)
                            : const Color(0xFF92400E))
                      : theme.colorScheme.primary;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    leading: Icon(
                      c.status == StockCountStatus.cancelled
                          ? Icons.block
                          : draft
                          ? Icons.edit_note
                          : c.financialStatus == 'Pending'
                          ? Icons.pending_actions
                          : Icons.task_alt,
                      color: color,
                    ),
                    title: Text(
                      warehouseNames[c.warehouseId] ?? 'جرد مستودع',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${c.countNumber} · ${DateFormat('yyyy/MM/dd').format(c.countDate)}\n${stockCountStatusLabel(draft, c.financialStatus, cancelled: c.status == StockCountStatus.cancelled)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockCountDetailsView(countId: c.id),
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
