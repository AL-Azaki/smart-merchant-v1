import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class JournalEntryDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> entry;
  final List<Map<String, dynamic>> lines;
  final VoidCallback onClose;

  const JournalEntryDetailsSheet({
    super.key,
    required this.entry,
    required this.lines,
    required this.onClose,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> entry,
    required List<Map<String, dynamic>> lines,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalEntryDetailsSheet(
        entry: entry,
        lines: lines,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final journalNumber = entry['number']?.toString() ?? entry['journal_number']?.toString() ?? 'JV-001';
    final dateStr = entry['date']?.toString() ?? '2026-07-28';
    final status = entry['status']?.toString() ?? 'Posted';
    final isPosted = status == 'Posted' || status == 'مُرحّل';

    double totalDebit = 0;
    double totalCredit = 0;
    for (var l in lines) {
      final rawDb = l['debit'] ?? l['debit_amount'];
      final rawCr = l['credit'] ?? l['credit_amount'];
      totalDebit += (rawDb is num ? rawDb : 0).toDouble();
      totalCredit += (rawCr is num ? rawCr : 0).toDouble();
    }
    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;

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
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(journalNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(dateStr, style: TextStyle(fontSize: 12, color: textSecondary)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPosted ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPosted ? 'مُرحّل' : 'مسودة',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                  ),
                                ),
                              ],
                            ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
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
                        Text('البيان العام للقيد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary)),
                        const SizedBox(height: 6),
                        Text(
                          entry['notes']?.toString() ?? entry['description']?.toString() ?? 'لا يوجد بيان',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lines Table
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('الحساب / البيان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary))),
                              Expanded(child: Text('مدين (Debit)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary), textAlign: TextAlign.left)),
                              Expanded(child: Text('دائن (Credit)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary), textAlign: TextAlign.left)),
                            ],
                          ),
                        ),

                        // Table Rows
                        ...lines.map((line) {
                          final rawDb = line['debit'] ?? line['debit_amount'];
                          final rawCr = line['credit'] ?? line['credit_amount'];
                          final double debit = (rawDb is num ? rawDb : 0).toDouble();
                          final double credit = (rawCr is num ? rawCr : 0).toDouble();
                          final accName = line['account_name']?.toString() ?? line['account_code']?.toString() ?? 'حساب';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(accName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                                      if (line['description'] != null)
                                        Text(line['description'].toString(), style: TextStyle(fontSize: 12, color: textSecondary)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    debit > 0 ? debit.toStringAsFixed(0) : '0',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: debit > 0 ? const Color(0xFF10B981) : textSecondary),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    credit > 0 ? credit.toStringAsFixed(0) : '0',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: credit > 0 ? const Color(0xFFEF4444) : textSecondary),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Table Footer Totals
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            border: Border(top: BorderSide(color: borderColor, width: 2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('الإجمالي:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textPrimary))),
                              Expanded(child: Text(totalDebit.toStringAsFixed(0), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textPrimary), textAlign: TextAlign.left)),
                              Expanded(child: Text(totalCredit.toStringAsFixed(0), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textPrimary), textAlign: TextAlign.left)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!isBalanced) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '⚠️ تنبيه: القيد غير متوازن',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
                          const SnackBar(content: Text('جاري طباعة القيد...')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 20),
                      label: Text('طباعة القيد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
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
                        backgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF3B82F6), size: 20),
                      label: const Text('مشاركة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6))),
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
}
