import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../database/enums/stock_count_status.dart';
import '../../providers/stock_counts_provider.dart';
import 'widgets/stock_count_form_sheet.dart';

class StockCountDetailsView extends ConsumerWidget {
  final String countId;

  const StockCountDetailsView({super.key, required this.countId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref
          .read(stockCountsNotifierProvider.notifier)
          .getDetails(countId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل الجرد')),
            body: Center(child: Text('خطأ: ${snapshot.error}')),
          );
        }

        final details = snapshot.data!;
        final count = details.count;
        final items = details.items;
        final isDraft = count.status == StockCountStatus.draft;

        return Scaffold(
          appBar: AppBar(
            title: Text('جرد رقم: ${count.countNumber}'),
            actions: [
              if (isDraft)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => StockCountFormSheet(
                        existingCount: count,
                        existingItems: items,
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ الجرد: ${DateFormat('yyyy/MM/dd HH:mm').format(count.countDate)}',
                    ),
                    const SizedBox(height: 8),
                    if (count.notes != null) Text('ملاحظات: ${count.notes}'),
                    const SizedBox(height: 16),
                    Text(
                      'العناصر (${items.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(
                        'المنتج: ${item.productId}',
                      ), // ideally we fetch product name
                      subtitle: Text(
                        'الكمية الفعلية: ${item.countedQuantity} | الدفترية: ${item.expectedQuantity}',
                      ),
                      trailing: Text(
                        'الفرق: ${item.differenceQuantity}',
                        style: TextStyle(
                          color: item.differenceQuantity > 0
                              ? AppColors.success
                              : item.differenceQuantity < 0
                              ? AppColors.error
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isDraft)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _postCount(context, ref),
                    child: const Text(
                      'اعتماد الجرد',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _postCount(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاعتماد'),
        content: const Text(
          'هل أنت متأكد من اعتماد هذا الجرد؟ سيتم إنشاء حركات تسوية مخزنية للفروقات ولن تتمكن من تعديله بعد ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('اعتماد'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(stockCountsNotifierProvider.notifier).postCount(countId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم اعتماد الجرد بنجاح')));
        Navigator.pop(context); // go back
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
