import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../treasury/presentation/dialogs/fund_transfer_dialog.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../widgets/payment_voucher_dialog.dart';

class PaymentVouchersView extends ConsumerStatefulWidget {
  const PaymentVouchersView({super.key});

  @override
  ConsumerState<PaymentVouchersView> createState() => _PaymentVouchersViewState();
}

class _PaymentVouchersViewState extends ConsumerState<PaymentVouchersView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final vouchersAsync = ref.watch(paymentVouchersStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('سندات الصرف (Payment Vouchers)'),
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'تحويل مالي بين الصناديق',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const FundTransferDialog(),
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(paymentVouchersStreamProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند صرف جديد'),
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const PaymentVoucherDialog(),
          );
          if (created == true) {
            ref.invalidate(paymentVouchersStreamProvider);
          }
        },
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            color: surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'البحث برقم السند أو الملاحظات...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _search = val.trim()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main List
          Expanded(
            child: vouchersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('خطأ في تحميل السندات: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (vouchers) {
                final filtered = vouchers.where((v) {
                  if (_search.isEmpty) return true;
                  final matchNumber = v.paymentNumber.toLowerCase().contains(_search.toLowerCase());
                  final matchNotes = (v.notes ?? '').toLowerCase().contains(_search.toLowerCase());
                  return matchNumber || matchNotes;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد سندات صرف مسجلة',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط على "سند صرف جديد" لسداد مورد أو تقييد مصروف تشغيلي',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _PaymentVoucherCard(item: item, surface: surface, borderColor: borderColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentVoucherCard extends StatelessWidget {
  final Payment item;
  final Color surface;
  final Color borderColor;

  const _PaymentVoucherCard({
    required this.item,
    required this.surface,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final dateStr =
        '${item.paymentDate.year}/${item.paymentDate.month.toString().padLeft(2, '0')}/${item.paymentDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.south_west_rounded, color: Color(0xFFEF4444), size: 22),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.paymentNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.contactType == 'Supplier' ? 'سداد مورد' : 'مصروف تشغيلي',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.notes?.isNotEmpty == true ? item.notes! : 'سند صرف مرحل',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(dateStr, style: TextStyle(fontSize: 10, color: textSecondary)),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.amount.toStringAsFixed(2)} ${item.currencyId}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status == 'Posted' ? 'مرحل' : item.status,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
