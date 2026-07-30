import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onClose;

  const TransactionDetailsSheet({
    required this.transaction,
    required this.onClose,
    super.key,
  });

  static void show(BuildContext context, {required Map<String, dynamic> transaction}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionDetailsSheet(
        transaction: transaction,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  String _getCategoryName(String? key) {
    const categories = {
      'sales': 'إيرادات مبيعات',
      'services': 'إيرادات خدمات',
      'investments': 'عوائد استثمار',
      'other_income': 'إيرادات أخرى',
      'salaries': 'رواتب وأجور',
      'rent': 'إيجارات',
      'utilities': 'فواتير خدمات',
      'marketing': 'تسويق وإعلان',
      'maintenance': 'صيانة وإصلاح',
      'office_supplies': 'مستلزمات مكتبية',
      'other_expense': 'مصروفات أخرى',
    };
    return categories[key] ?? key ?? 'عام';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final type = transaction['type']?.toString() ?? '';
    final rawAmount = transaction['amount'];
    final num amountNum = rawAmount is num ? rawAmount : 0;
    final isIncome = type == 'income' || amountNum > 0;
    final primaryColor = isIncome ? Colors.blue : Colors.red;
    final title = isIncome ? 'تفاصيل سند القبض' : 'تفاصيل سند الصرف';
    final currency = transaction['currency']?.toString() ?? 'YER';

    return AppModalSheet(
      title: title,
      icon: Icons.receipt_long_outlined,
      iconColor: primaryColor,
      onClose: onClose,
      primaryLabel: 'طباعة السند',
      onPrimary: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري طباعة السند...')),
        );
      },
      child: Column(
        children: [
          // Amount Header Card
          AppCard(
            padding: const EdgeInsets.all(20),
            backgroundColor: primaryColor.withValues(alpha: 0.08),
            borderColor: primaryColor.withValues(alpha: 0.2),
            child: Column(
              children: [
                Text(
                  '${amountNum.abs().toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      transaction['date']?.toString() ?? '2026-07-28',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details Grid Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('التصنيف المالي', _getCategoryName(transaction['category']?.toString()), textPrimary, textSecondary)),
                    Expanded(child: _buildInfoItem('رقم المرجع', (transaction['ref'] ?? transaction['reference'])?.toString() ?? '---', textPrimary, textSecondary)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('نوع الجهة', transaction['entityType']?.toString() ?? 'عام', textPrimary, textSecondary)),
                    Expanded(child: _buildInfoItem('اسم الجهة', (transaction['entityName'] ?? transaction['title'])?.toString() ?? '---', textPrimary, textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('البيان / الوصف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary)),
                const SizedBox(height: 6),
                Text(
                  (transaction['description'] ?? transaction['title'])?.toString() ?? 'لا يوجد بيان',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
