import 'package:flutter/material.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/documents/presentation/widgets/party_statement_preview_screen.dart';
import '../../../../shared/documents/printing/party_statement_pdf_builder.dart';
import '../../../../shared/utils/arabic_tafqeet.dart';
import '../../application/services/party_statement_service.dart';

class PartyStatementDialog extends StatelessWidget {
  final PartyStatementReport report;
  final String? partyPhone;

  const PartyStatementDialog({
    super.key,
    required this.report,
    this.partyPhone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final isCustomer = report.partyType == 'Customer';
    final absBalance = report.closingBalance.abs();
    final isDebit = report.closingBalance > 0;
    final statusText = isCustomer
        ? (isDebit ? 'عليكم / رصيد' : 'لكم / رصيد')
        : (isDebit ? 'لنا / رصيد' : 'لكم / رصيد علينا');

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with Title & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCustomer ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCustomer ? Icons.person_rounded : Icons.business_rounded,
                          color: isCustomer ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كشف حساب تحليلي: ${report.partyName}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                          Text(
                            'رقم الحساب: ${report.partyId} • العملة: ريال يمني',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // زر إرسال واتساب
                      IconButton(
                        tooltip: 'إرسال ملخص واتساب',
                        icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                        onPressed: () => PartyStatementPdfBuilder.shareViaWhatsApp(
                          report: report,
                          phone: partyPhone,
                        ),
                      ),
                      // زر مشاركة ملف PDF
                      IconButton(
                        tooltip: 'مشاركة ملف PDF',
                        icon: const Icon(Icons.share_rounded, color: Color(0xFF3B82F6)),
                        onPressed: () => PartyStatementPdfBuilder.sharePdf(
                          report: report,
                        ),
                      ),
                      // زر معاينة وطباعة A4
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PartyStatementPreviewScreen(
                                report: report,
                                customerPhone: partyPhone,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('معاينة وطباعة A4'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Summary Cards
              Row(
                children: [
                  _SummaryBox(
                    label: 'رصيد سابق',
                    value: report.openingBalance,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: isCustomer ? 'إجمالي المبيعات (مدين)' : 'إجمالي السدادات (مدين)',
                    value: report.totalDebit,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: isCustomer ? 'إجمالي المقبوضات (دائن)' : 'إجمالي المشتريات (دائن)',
                    value: report.totalCredit,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _SummaryBox(
                    label: statusText,
                    value: absBalance,
                    color: report.closingBalance > 0
                        ? (isCustomer ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                        : (isCustomer ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Classic 8-Columns Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(color: borderColor),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 80, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    SizedBox(width: 90, child: Text('نوع المستند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    SizedBox(width: 70, child: Text('رقم السند', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    SizedBox(width: 60, child: Text('المرجع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    Expanded(child: Text('البيان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                    SizedBox(width: 90, child: Text('المدين (عليه)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFEF4444)), textAlign: TextAlign.center)),
                    SizedBox(width: 90, child: Text('الدائن (له)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF10B981)), textAlign: TextAlign.center)),
                    SizedBox(width: 100, child: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                  ],
                ),
              ),

              // 4. Table Body
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    border: Border(
                      left: BorderSide(color: borderColor),
                      right: BorderSide(color: borderColor),
                      bottom: BorderSide(color: borderColor),
                    ),
                  ),
                  child: report.lines.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد حركات مالية مسجلة في هذه الفترة',
                            style: TextStyle(color: textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: report.lines.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
                          itemBuilder: (context, index) {
                            final line = report.lines[index];
                            final dateStr =
                                '${line.date.year}-${line.date.month.toString().padLeft(2, '0')}-${line.date.day.toString().padLeft(2, '0')}';

                            String typeLabel = line.documentType;
                            Color badgeColor = const Color(0xFF64748B);
                            if (line.documentType == 'Invoice') {
                              typeLabel = isCustomer ? 'مبيعات آجل' : 'فاتورة مشتريات';
                              badgeColor = const Color(0xFF3B82F6);
                            } else if (line.documentType == 'Payment') {
                              typeLabel = isCustomer ? 'سند قبض نقداً' : 'سند صرف نقداً';
                              badgeColor = const Color(0xFF10B981);
                            } else if (line.documentType == 'Return') {
                              typeLabel = isCustomer ? 'مردود مبيعات' : 'مردود مشتريات';
                              badgeColor = const Color(0xFFF59E0B);
                            } else if (line.documentType == 'Opening') {
                              typeLabel = 'رصيد سابق';
                              badgeColor = const Color(0xFF64748B);
                            }

                            final isLineDebit = line.runningBalance > 0;
                            final balanceLabel = line.runningBalance == 0
                                ? ''
                                : (isCustomer ? (isLineDebit ? '(عليكم)' : '(لكم)') : (isLineDebit ? '(لنا)' : '(لهم)'));

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: index % 2 == 1
                                  ? (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFA))
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(dateStr, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        typeLabel,
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text(line.documentNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(line.documentNumber.replaceAll(RegExp(r'[^0-9]'), ''), style: TextStyle(fontSize: 9.5, color: textSecondary), textAlign: TextAlign.center),
                                  ),
                                  Expanded(
                                    child: Text(line.description, style: const TextStyle(fontSize: 11), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      line.debit > 0 ? line.debit.toStringAsFixed(2) : '-',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: line.debit > 0 ? const Color(0xFFEF4444) : textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      line.credit > 0 ? line.credit.toStringAsFixed(2) : '-',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: line.credit > 0 ? const Color(0xFF10B981) : textSecondary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          line.runningBalance.abs().toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        if (balanceLabel.isNotEmpty)
                                          Text(
                                            balanceLabel,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isLineDebit ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // 5. Callout Box with Arabic Tafqeet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F2942) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('المبلغ بالحروف:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 1),
                          Text(
                            ArabicTafqeet.convert(absBalance, currencyName: 'ريال يمني'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(statusText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(
                          '${absBalance.toStringAsFixed(2)} ر.ي',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 6. Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('إغلاق'),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => PartyStatementPdfBuilder.shareViaWhatsApp(
                          report: report,
                          phone: partyPhone,
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF25D366)),
                        label: const Text('إرسال واتساب'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => PartyStatementPdfBuilder.sharePdf(
                          report: report,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('مشاركة ملف PDF'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PartyStatementPreviewScreen(
                                report: report,
                                customerPhone: partyPhone,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('معاينة وطباعة A4'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
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
