import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../database/enums/stock_count_status.dart';
import '../../providers/stock_counts_provider.dart';
import 'widgets/stock_count_form_sheet.dart';

import '../../../../../app/di/getit_instance.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../../application/usecases/get_stock_count_details_usecase.dart';

class StockCountDetailsView extends ConsumerWidget {
  final String countId;

  const StockCountDetailsView({super.key, required this.countId});

  Future<Map<String, dynamic>> _loadDetails(WidgetRef ref) async {
    final details = await ref
        .read(stockCountsNotifierProvider.notifier)
        .getDetails(countId);
    final db = getIt<AppDatabase>();
    final productIds = details.items.map((i) => i.productId).toSet().toList();
    final products = await (db.select(db.products)
          ..where((p) => p.id.isIn(productIds)))
        .get();
    final productMap = {for (var p in products) p.id: p};
    return {'details': details, 'productMap': productMap};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadDetails(ref),
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

        final data = snapshot.data!;
        final details = data['details'] as StockCountDetails;
        final productMap = data['productMap'] as Map<String, Product>;
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
                    if (count.notes != null && count.notes!.isNotEmpty)
                      Text('ملاحظات: ${count.notes}'),
                    const SizedBox(height: 16),
                    Text(
                      'الأصناف المجرودة (${items.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = productMap[item.productId];
                    final productName =
                        product?.productName ?? 'صنف (${item.productId.substring(0, 8)})';
                    final productCode = product?.productCode ?? '';

                    final diff = item.differenceQuantity;
                    final diffColor = diff > 0
                        ? AppColors.success
                        : diff < 0
                            ? AppColors.error
                            : Colors.grey;
                    final diffStr = diff > 0 ? '+$diff' : '$diff';

                    return ListTile(
                      title: Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          if (productCode.isNotEmpty) ...[
                            Text(
                              'كود: $productCode',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('|'),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'الفعلي: ${item.countedQuantity} | الدفتري: ${item.expectedQuantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'الفرق: $diffStr',
                          style: TextStyle(
                            color: diffColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
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
