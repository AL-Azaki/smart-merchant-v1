import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onClose;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.onClose,
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
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final type = transaction['type']?.toString() ?? '';
    final rawAmount = transaction['amount'];
    final num amountNum = rawAmount is num ? rawAmount : 0;
    final isIncome = type == 'income' || amountNum > 0;
    final primaryColor = isIncome ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    final title = isIncome ? 'سند قبض' : 'سند صرف';
    final currency = transaction['currency']?.toString() ?? 'ر.ي';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.description_outlined, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary), overflow: TextOverflow.ellipsis),
                            Text(transaction['id']?.toString() ?? 'TRX-001', style: TextStyle(fontSize: 13, color: textSecondary), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Amount
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              amountNum.abs().toString(),
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: primaryColor),
                            ),
                            const SizedBox(width: 6),
                            Text(currency, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                transaction['date']?.toString() ?? '2026-07-28',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 2.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildInfoItem('التصنيف', _getCategoryName(transaction['category']?.toString()), textPrimary, textSecondary),
                        _buildInfoItem('رقم المرجع', (transaction['ref'] ?? transaction['reference'])?.toString() ?? '---', textPrimary, textSecondary),
                        _buildInfoItem('نوع الجهة', transaction['entityType']?.toString() ?? 'عميل/مورد', textPrimary, textSecondary),
                        _buildInfoItem('اسم الجهة', (transaction['entityName'] ?? transaction['title'])?.toString() ?? '---', textPrimary, textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('البيان / الوصف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary)),
                        const SizedBox(height: 6),
                        Text(
                          (transaction['description'] ?? transaction['title'])?.toString() ?? 'لا يوجد بيان',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري طباعة السند...')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 20),
                      label: Text('طباعة السند', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري المشاركة...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF10B981), size: 20),
                      label: const Text('مشاركة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                    ),
                  ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
