import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../kernel/security/subscription_lease_guard.dart';
import '../../../kernel/security/subscription_lease_provider.dart';

/// In-App Subscription Expiry Warning Banner.
///
/// Automatically appears at the top of POS / Dashboard when the merchant's
/// subscription installment is due within 7 days or currently in grace period.
class SubscriptionWarningBanner extends ConsumerWidget {
  const SubscriptionWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaseAsync = ref.watch(subscriptionLeaseCheckProvider);

    return leaseAsync.when(
      data: (check) {
        if (!check.shouldShowWarningBanner) {
          return const SizedBox.shrink();
        }

        final isGrace = check.status == SubscriptionLeaseStatus.gracePeriod;
        final bgColor = isGrace ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
        final borderColor = isGrace ? const Color(0xFFF87171) : const Color(0xFFFCD34D);
        final textColor = isGrace ? const Color(0xFF991B1B) : const Color(0xFF92400E);
        final iconColor = isGrace ? Colors.red.shade700 : const Color(0xFFD97706);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isGrace ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isGrace ? 'تنبيه انتهاء مهلة القسط (فترة السماح)' : 'تذكير موعد سداد القسط',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      check.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showInstallmentDetailsSheet(context, check),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGrace ? Colors.red.shade700 : const Color(0xFF14233B),
                  foregroundColor: isGrace ? Colors.white : const Color(0xFFB3945B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('تفاصيل السداد'),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  void _showInstallmentDetailsSheet(BuildContext context, SubscriptionLeaseCheck check) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14233B).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF14233B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كشف استحقاق القسط القادم',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        check.planName ?? 'خطة الاشتراك',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _infoRow('المبلغ المطلوب سداده:', '${check.amountDue.toStringAsFixed(2)} YER', isBold: true),
            const SizedBox(height: 8),
            _infoRow(
              'تاريخ استحقاق القسط:',
              check.nextDueDate != null
                  ? '${check.nextDueDate!.year}-${check.nextDueDate!.month.toString().padLeft(2, '0')}-${check.nextDueDate!.day.toString().padLeft(2, '0')}'
                  : '—',
            ),
            const SizedBox(height: 8),
            _infoRow('الأيام المتبقية:', '${check.daysRemaining} أيام'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طرق السداد المعتمدة:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• حوالة بنك الكريمي (حساب: 123456789 - باسم منصة تاجركم)\n• ون كاش (OneCash)\n• السداد المباشر عبر إدارة المبيعات',
                    style: TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14233B),
                foregroundColor: const Color(0xFFB3945B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إغلاق وتذكيري لاحقاً', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF047857) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
