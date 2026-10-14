import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import 'journal_entry_print_service.dart';
import 'original_invoice_paper_widget.dart';

class JournalEntryDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> entry;
  final List<Map<String, dynamic>> lines;
  final VoidCallback onClose;

  const JournalEntryDetailsSheet({
    required this.entry,
    required this.lines,
    required this.onClose,
    super.key,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? entry,
    List<Map<String, dynamic>>? lines,
    String? entryId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalEntryDetailsSheet(
        entry: entry ?? {'id': entryId ?? '', 'number': entryId ?? ''},
        lines: lines ?? const [],
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<JournalEntryDetailsSheet> createState() => _JournalEntryDetailsSheetState();
}

class _JournalEntryDetailsSheetState extends State<JournalEntryDetailsSheet> {
  int _activeTab = 0; // 0 = عرض القيد, 1 = الفاتورة الأصلية

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final journalNumber = widget.entry['number']?.toString() ??
        widget.entry['journal_number']?.toString() ??
        'JE-2024-001';
    final dateStr = widget.entry['date']?.toString() ?? '2024/06/25';
    final status = widget.entry['status']?.toString() ?? 'Posted';
    final isPosted = status == 'Posted' || status == 'مُرحَّل' || status == 'مُرحّل';
    final operationType = widget.entry['refType'] == 'Sales'
        ? 'فاتورة مبيعات'
        : (widget.entry['refType'] == 'Expense' ? 'مصروف' : 'قيد يدوي');

    double totalDebit = 0;
    double totalCredit = 0;
    for (var l in widget.lines) {
      final rawDb = l['debit'] ?? l['debit_amount'];
      final rawCr = l['credit'] ?? l['credit_amount'];
      totalDebit += (rawDb is num ? rawDb : 0).toDouble();
      totalCredit += (rawCr is num ? rawCr : 0).toDouble();
    }
    if (totalDebit == 0) totalDebit = 8700;
    if (totalCredit == 0) totalCredit = 8700;

    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;
    final lineCount = widget.lines.isNotEmpty ? widget.lines.length : 2;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      child: Column(
        children: [
          // ── Responsive Header Banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                    if (!isMobile) ...[
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTabBtn('عرض القيد', 0),
                            _buildTabBtn('الفاتورة الأصلية', 1),
                          ],
                        ),
                      ),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'تفاصيل القيد المحاسبي',
                            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            journalNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Center(child: _buildTabBtn('عرض القيد', 0))),
                        Expanded(child: Center(child: _buildTabBtn('الفاتورة الأصلية', 1))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Scrollable Body Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => JournalEntryPrintService.shareOnWhatsApp(
                            entry: widget.entry,
                            isInvoiceTab: _activeTab == 1,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('مشاركة واتساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => JournalEntryPrintService.printDocument(
                            context: context,
                            entry: widget.entry,
                            lines: widget.lines,
                            isInvoiceTab: _activeTab == 1,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: surface,
                            foregroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: borderColor, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF2563EB)),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _activeTab == 0 ? 'طباعة القيد' : 'طباعة الفاتورة',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _activeTab == 0
                      ? _buildJournalEntryPaper(
                          surface,
                          borderColor,
                          textPrimary,
                          textSecondary,
                          journalNumber,
                          dateStr,
                          isPosted,
                          operationType,
                          totalDebit,
                          totalCredit,
                          isBalanced,
                          lineCount,
                          isMobile,
                        )
                      : OriginalInvoicePaperWidget(
                          surface: surface,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          journalNumber: journalNumber,
                          dateStr: dateStr,
                          totalDebit: totalDebit,
                          isMobile: isMobile,
                        ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildBottomStatCard('نوع العملية', operationType, isDark ? Colors.white : const Color(0xFF1E3A8A))),
                      const SizedBox(width: 6),
                      Expanded(child: _buildBottomStatCard('عدد الأسطر', '$lineCount سطر', const Color(0xFF2563EB))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBottomStatCard(
                          'التوازن',
                          isBalanced ? 'متوازن ✓' : 'غير متوازن',
                          isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildJournalEntryPaper(
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    String journalNumber,
    String dateStr,
    bool isPosted,
    String operationType,
    double totalDebit,
    double totalCredit,
    bool isBalanced,
    int lineCount,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('متجر النور', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('رقم القيد: $journalNumber  •  التاريخ: $dateStr', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1E3A8A), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('قيد محاسبي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPosted ? 'مُرحَّل' : 'مسودة',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Text('معلومات التدقيق والعملية (AUDIT INFORMATION)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          if (isMobile) ...[
            _buildInfoCard('مصدر القيد', operationType, 'رقم المرجع', 'si_001', 'الفرع/الشركة', 'متجر النور', 'نوع العملة', 'ر.ي', textSecondary, textPrimary),
            const SizedBox(height: 8),
            _buildInfoCard('أنشئ بواسطة', 'محمد أحمد', 'تاريخ الإنشاء', dateStr, 'وقت الإنشاء', '01:30 م', 'آخر تعديل', '2024/06/25 01:30 م', textSecondary, textPrimary),
            const SizedBox(height: 8),
            _buildInfoCard('تم الترحيل بواسطة', 'مدير الحسابات', 'وقت الترحيل', '01:30 م', 'حالة التوازن', isBalanced ? 'متوازن ✓' : 'غير متوازن', 'إجمالي الأسطر', '$lineCount', textSecondary, textPrimary),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoCard('مصدر القيد', operationType, 'رقم المرجع', 'si_001', 'الفرع/الشركة', 'متجر النور', 'نوع العملة', 'ر.ي', textSecondary, textPrimary)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoCard('أنشئ بواسطة', 'محمد أحمد', 'تاريخ الإنشاء', dateStr, 'وقت الإنشاء', '01:30 م', 'آخر تعديل', '2024/06/25 01:30 م', textSecondary, textPrimary)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoCard('تم الترحيل بواسطة', 'مدير الحسابات', 'وقت الترحيل', '01:30 م', 'حالة التوازن', isBalanced ? 'متوازن ✓' : 'غير متوازن', 'إجمالي الأسطر', '$lineCount', textSecondary, textPrimary)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text('تفاصيل الأسطر (المدين والدائن)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: isMobile ? 500 : 600),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                  columnWidths: const {
                    0: FixedColumnWidth(36),
                    1: FixedColumnWidth(90),
                    2: FlexColumnWidth(1.8),
                    3: FlexColumnWidth(2.0),
                    4: FixedColumnWidth(90),
                    5: FixedColumnWidth(90),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                      children: [
                        _buildTableCell('رقم', isHeader: true),
                        _buildTableCell('رمز الحساب', isHeader: true),
                        _buildTableCell('اسم الحساب', isHeader: true),
                        _buildTableCell('البيان', isHeader: true),
                        _buildTableCell('مدين (ر.ي)', isHeader: true),
                        _buildTableCell('دائن (ر.ي)', isHeader: true),
                      ],
                    ),
                    if (widget.lines.isNotEmpty)
                      ...widget.lines.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final l = entry.value;
                        final num debit = ((l['debit'] ?? l['debit_amount'] ?? 0) as num);
                        final num credit = ((l['credit'] ?? l['credit_amount'] ?? 0) as num);
                        return TableRow(
                          children: [
                            _buildTableCell('$idx'),
                            _buildTableCell(l['account_code']?.toString() ?? '---'),
                            _buildTableCell(l['account_name']?.toString() ?? '---', isBold: true),
                            _buildTableCell(l['description']?.toString() ?? '---'),
                            _buildTableCell(debit > 0 ? '$debit' : '—', color: debit > 0 ? const Color(0xFF10B981) : Colors.grey, isBold: debit > 0),
                            _buildTableCell(credit > 0 ? '$credit' : '—', color: credit > 0 ? const Color(0xFFEF4444) : Colors.grey, isBold: credit > 0),
                          ],
                        );
                      })
                    else ...[
                      TableRow(
                        children: [
                          _buildTableCell('1'),
                          _buildTableCell('COA_111'),
                          _buildTableCell('الصندوق (النقدي)', isBold: true),
                          _buildTableCell('استلام نقدية مبيعات'),
                          _buildTableCell('${totalDebit.toInt()}', color: const Color(0xFF10B981), isBold: true),
                          _buildTableCell('—', color: Colors.grey),
                        ],
                      ),
                      TableRow(
                        children: [
                          _buildTableCell('2'),
                          _buildTableCell('COA_41'),
                          _buildTableCell('إيرادات المبيعات', isBold: true),
                          _buildTableCell('إيراد مبيعات فاتورة INV-2024-001'),
                          _buildTableCell('—', color: Colors.grey),
                          _buildTableCell('${totalCredit.toInt()}', color: const Color(0xFFEF4444), isBold: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي المدين: ${totalDebit.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                Text('إجمالي الدائن: ${totalCredit.toStringAsFixed(2)} ر.ي', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label1, String val1,
    String label2, String val2,
    String label3, String val3,
    String label4, String val4,
    Color textSecondary, Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoPair(label1, val1, textSecondary, textPrimary),
              _buildInfoPair(label2, val2, textSecondary, textPrimary),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoPair(label3, val3, textSecondary, textPrimary),
              _buildInfoPair(label4, val4, textSecondary, textPrimary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPair(String label, String value, Color textSecondary, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: (isHeader || isBold) ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? Colors.white : (color ?? const Color(0xFF1E293B)),
          height: 1.3,
        ),
        textAlign: TextAlign.center,
        softWrap: true,
      ),
    );
  }

  Widget _buildBottomStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }
}
