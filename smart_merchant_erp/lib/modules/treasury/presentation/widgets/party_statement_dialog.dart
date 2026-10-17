import 'package:flutter/material.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../application/services/party_statement_service.dart';

class PartyStatementDialog extends StatelessWidget {
  final PartyStatementReport report;

  const PartyStatementDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final isCustomer = report.partyType == 'Customer';

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isCustomer ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCustomer ? Icons.person_rounded : Icons.business_rounded,
                          color: isCustomer ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كشف حساب: ${report.partyName}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                          ),
                          Text(
                            isCustomer ? 'كشف حساب عميل مفصل' : 'كشف حساب مورد مفصل',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Cards
              Row(
                children: [
                  _SummaryBox(
                    label: 'رصيد سابق',
                    value: report.openingBalance,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: isCustomer ? 'إجمالي المبيعات (مدين)' : 'إجمالي السدادات والمردودات (مدين)',
                    value: report.totalDebit,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: isCustomer ? 'إجمالي المقبوضات والمردودات (دائن)' : 'إجمالي المشتريات (دائن)',
                    value: report.totalCredit,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: isCustomer
                        ? (report.closingBalance >= 0 ? 'الرصيد المستحق (لنا)' : 'الرصيد الدائن (للعميل)')
                        : (report.closingBalance >= 0 ? 'الرصيد المستحق (للمورد علينا)' : 'الرصيد المدين (لنا)'),
                    value: report.closingBalance.abs(),
                    color: report.closingBalance > 0
                        ? (isCustomer ? const Color(0xFF3B82F6) : const Color(0xFFEF4444))
                        : const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Table Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: report.lines.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد حركات مالية مسجلة',
                            style: TextStyle(color: textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: report.lines.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final line = report.lines[index];
                            final dateStr =
                                '${line.date.year}/${line.date.month.toString().padLeft(2, '0')}/${line.date.day.toString().padLeft(2, '0')}';

                            Color badgeColor;
                            String badgeLabel;
                            switch (line.documentType.toLowerCase()) {
                              case 'return':
                                badgeColor = const Color(0xFFF59E0B);
                                badgeLabel = 'مردود';
                                break;
                              case 'payment':
                                badgeColor = const Color(0xFF10B981);
                                badgeLabel = isCustomer ? 'قبض' : 'صرف';
                                break;
                              case 'invoice':
                                badgeColor = const Color(0xFF3B82F6);
                                badgeLabel = 'فاتورة';
                                break;
                              default:
                                badgeColor = const Color(0xFF64748B);
                                badgeLabel = 'افتتاحي';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Date & Ref
                                  SizedBox(
                                    width: 140,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(fontSize: 11, color: textSecondary),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                badgeLabel,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: badgeColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                line.documentNumber,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: textPrimary,
                                                  fontFamily: 'monospace',
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Description
                                  Expanded(
                                    child: Text(
                                      line.description,
                                      style: TextStyle(fontSize: 13, color: textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Debit
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      line.debit > 0 ? line.debit.toStringAsFixed(2) : '-',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                  // Credit
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      line.credit > 0 ? line.credit.toStringAsFixed(2) : '-',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  // Running Balance
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      '${line.runningBalance.toStringAsFixed(2)} ر.ي',
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              '${value.toStringAsFixed(2)} ر.ي',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
