import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../application/services/stock_count_workflow.dart';
import '../providers/stock_counts_provider.dart';
import 'inventory_dialog_frame.dart';

class InventoryRecordDialog extends ConsumerStatefulWidget {
  final String title;
  final Future<InventoryRecordData> Function(StockCountWorkflow) load;
  const InventoryRecordDialog({
    required this.title, required this.load, super.key,
  });
  @override
  ConsumerState<InventoryRecordDialog> createState() =>
      _InventoryRecordDialogState();
}

class _InventoryRecordDialogState extends ConsumerState<InventoryRecordDialog> {
  late Future<InventoryRecordData> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.load(ref.read(stockCountWorkflowProvider));
  }

  @override
  Widget build(BuildContext context) => InventoryDialogFrame(
    title: widget.title,
    actionLabel: 'إغلاق',
    icon: Icons.receipt_long_outlined,
    showCancel: false,
    onClose: () => Navigator.pop(context),
    onAction: () => Navigator.pop(context),
    child: FutureBuilder<InventoryRecordData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(
                () =>
                    _future = widget.load(ref.read(stockCountWorkflowProvider)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('تعذر تحميل التفاصيل، أعد المحاولة'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snapshot.data!;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.reference,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(doc.location),
                    const SizedBox(height: 8),
                    Text(DateFormat('yyyy/MM/dd HH:mm').format(doc.date)),
                    if (doc.notes?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(doc.notes!),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      '${doc.lines.length} منتج',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: doc.lines.length,
              itemBuilder: (_, i) {
                final line = doc.lines[i];
                return ListTile(
                  title: Text(
                    line.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(catalogDisplayName(line.unit)),
                  trailing: Text(
                    formatCatalogNumber(line.quantity),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
