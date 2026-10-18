import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../database/enums/inventory_transaction_type.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/inventory_section_header.dart';
import '../../widgets/inventory_empty_state.dart';
import '../stock_counts/widgets/stock_count_form_sheet.dart';
import '../stock_counts/stock_count_details_view.dart';
import 'widgets/stock_adjustment_details_dialog.dart';

class StockAdjustmentsView extends ConsumerStatefulWidget {
  const StockAdjustmentsView({super.key});
  @override
  ConsumerState<StockAdjustmentsView> createState() =>
      _StockAdjustmentsViewState();
}

class _StockAdjustmentsViewState extends ConsumerState<StockAdjustmentsView> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockAdjustmentsListProvider);
    return Column(
      children: [
        InventorySectionHeader(
          title: 'سجل تسويات المخزون',
          subtitle: 'حركات الزيادة والنقص مرتبطة بالجرد الذي أنشأها',
          icon: Icons.tune_rounded,
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
            label: const Text('جرد تصحيحي جديد'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(
              hintText: 'ابحث بتاريخ الحركة أو مرجعها',
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
                onPressed: () => ref.invalidate(stockAdjustmentsListProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('تعذر تحميل التسويات، أعد المحاولة'),
              ),
            ),
            data: (all) {
              final items = all
                  .where(
                    (i) =>
                        '${i.id} ${i.referenceId ?? ''} ${DateFormat('yyyy-MM-dd').format(i.transactionDate)}'
                            .toLowerCase()
                            .contains(_query),
                  )
                  .toList();
              if (items.isEmpty) {
                return InventoryEmptyState(
                  icon: Icons.tune_rounded,
                  title: all.isEmpty
                      ? 'لا توجد تسويات مخزنية'
                      : 'لا توجد تسويات تطابق البحث',
                  message: 'عند اعتماد الجرد التصحيحي يظهر أثره المخزني هنا.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final tx = items[index];
                  final incoming =
                      tx.transactionType ==
                      InventoryTransactionType.adjustmentIn;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    leading: Icon(
                      incoming
                          ? Icons.add_box_outlined
                          : Icons.indeterminate_check_box_outlined,
                      color: incoming
                          ? const Color(0xFF047857)
                          : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      incoming ? 'زيادة مخزون' : 'نقص مخزون',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(tx.transactionDate),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      if (tx.referenceId?.isNotEmpty ?? false) {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StockCountDetailsView(countId: tx.referenceId!),
                          ),
                        );
                      } else {
                        StockAdjustmentDetailsDialog.show(context, tx);
                      }
                    },
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
