import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../sales/presentation/mappers/sales_invoice_document_mapper.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
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
  CommercialDocumentData? _invoiceDocument;
  bool _isLoadingInvoice = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedDocument();
  }

  void _loadLinkedDocument() async {
    final docId = widget.entry['documentId']?.toString();
    final docType = (widget.entry['documentType']?.toString() ??
            widget.entry['refType']?.toString() ??
            '')
        .toLowerCase();

    if (docId == null || docId.isEmpty || docType == 'manual') return;

    setState(() => _isLoadingInvoice = true);
    try {
      if (docType.contains('sales')) {
        final mapper = getIt<SalesInvoiceDocumentMapper>();
        final doc = await mapper.mapToDocumentData(docId);
        if (mounted) {
          setState(() => _invoiceDocument = doc);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvoice = false);
      }
    }
  }

  String _statusArabic(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return 'مرحل';
      case 'draft':
        return 'مسودة';
      case 'reversed':
        return 'معكوس';
      default:
        return status;
    }
  }

  String _operationTypeArabic(String? type) {
    if (type == null) return 'قيد محاسبي عام';
    final lower = type.toLowerCase();
    if (lower.contains('salesinvoice') || lower == 'sales') return 'فاتورة مبيعات';
    if (lower.contains('purchaseinvoice') || lower == 'purchase') return 'فاتورة مشتريات';
    if (lower.contains('salesreturn')) return 'مردود مبيعات';
    if (lower.contains('purchasereturn')) return 'مردود مشتريات';
    if (lower.contains('payment') || lower.contains('receipt')) return 'سند قبض';
    if (lower.contains('disbursement')) return 'سند صرف';
    if (lower.contains('transfer')) return 'تحويل مالي بين الصناديق';
    if (lower.contains('closing')) return 'إقفال سنوي';
    if (lower.contains('manual')) return 'قيد يومية يدوي';
    return type;
  }

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
        '---';
    final dateStr = widget.entry['date']?.toString() ?? '';
    final status = widget.entry['status']?.toString() ?? 'Posted';
    final isPosted = status.toLowerCase() == 'posted' || status == 'مرحل';
    final operationType = _operationTypeArabic(widget.entry['refType']?.toString() ?? widget.entry['documentType']?.toString());

    final docId = widget.entry['documentId']?.toString();
    final docType = (widget.entry['documentType']?.toString() ?? widget.entry['refType']?.toString() ?? '').toLowerCase();
    final bool hasLinkedInvoice = docId != null &&
        docId.isNotEmpty &&
        docType != 'manual' &&
        (docType.contains('sales') || docType.contains('purchase') || docType.contains('return'));

    double totalDebit = 0;
    double totalCredit = 0;
    for (var l in widget.lines) {
      final rawDb = l['debit'] ?? l['debit_amount'];
      final rawCr = l['credit'] ?? l['credit_amount'];
      totalDebit += (rawDb is num ? rawDb : 0).toDouble();
      totalCredit += (rawCr is num ? rawCr : 0).toDouble();
    }

    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;
    final lineCount = widget.lines.length;

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
          // ── Header Banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
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
                if (hasLinkedInvoice && !isMobile)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabBtn('عرض القيد المحاسبي', 0),
                        _buildTabBtn('الفاتورة الأصلية', 1),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'تفاصيل القيد المحاسبي',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      journalNumber,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Mobile Tab Bar (if invoice linked) ──
          if (hasLinkedInvoice && isMobile)
            Container(
              color: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabBtn('عرض القيد المحاسبي', 0),
                  const SizedBox(width: 8),
                  _buildTabBtn('الفاتورة الأصلية', 1),
                ],
              ),
            ),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Action Buttons (مشاركة، طباعة)
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
                          label: const Text('مشاركة عبر واتساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          label: Text(
                            _activeTab == 0 ? 'طباعة القيد' : 'طباعة الفاتورة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                          documentData: _invoiceDocument,
                          isLoading: _isLoadingInvoice,
                        ),

                  const SizedBox(height: 14),

                  // Bottom Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildBottomStatCard(
                          'إجمالي المدين',
                          '${totalDebit.toStringAsFixed(2)} ر.ي',
                          const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBottomStatCard(
                          'إجمالي الدائن',
                          '${totalCredit.toStringAsFixed(2)} ر.ي',
                          const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBottomStatCard('عدد الأسطر', '$lineCount سطر', const Color(0xFF2563EB)),
                      ),
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
    final refDocNumber = widget.entry['documentNumber']?.toString() ??
        widget.entry['reference']?.toString() ??
        'لا يوجد';

    return Container(
      padding: const EdgeInsets.all(16),
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
                  const Text('الفرع الرئيسي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
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
                        color: (isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusArabic(widget.entry['status']?.toString() ?? 'Posted'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPosted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Audit Info (بدون أي نصوص إنجليزية)
          const Text('معلومات القيد والتدقيق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مصدر العملية:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(operationType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('رقم المرجع / الفاتورة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(refDocNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('حالة التوازن:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        isBalanced ? 'متوازن ✓' : 'غير متوازن',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (widget.entry['description'] != null && widget.entry['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'البيان العام: ${widget.entry['description']}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Lines Table
          const Text('تفاصيل أسطر القيد (المدين والدائن)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: isMobile ? 550 : 680),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                  columnWidths: const {
                    0: FixedColumnWidth(36),
                    1: FixedColumnWidth(90),
                    2: FlexColumnWidth(1.8),
                    3: FlexColumnWidth(2.0),
                    4: FixedColumnWidth(95),
                    5: FixedColumnWidth(95),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                      children: [
                        _buildTableCell('م', isHeader: true),
                        _buildTableCell('رمز الحساب', isHeader: true),
                        _buildTableCell('اسم الحساب', isHeader: true),
                        _buildTableCell('البيان الخاص بالسطر', isHeader: true),
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
                            _buildTableCell(l['account_name']?.toString() ?? 'حساب محاسبي', isBold: true),
                            _buildTableCell(l['description']?.toString() ?? '—'),
                            _buildTableCell(
                              debit > 0 ? debit.toStringAsFixed(2) : '—',
                              color: debit > 0 ? const Color(0xFF10B981) : Colors.grey,
                              isBold: debit > 0,
                            ),
                            _buildTableCell(
                              credit > 0 ? credit.toStringAsFixed(2) : '—',
                              color: credit > 0 ? const Color(0xFFEF4444) : Colors.grey,
                              isBold: credit > 0,
                            ),
                          ],
                        );
                      })
                    else
                      TableRow(
                        children: [
                          _buildTableCell('1'),
                          _buildTableCell('---'),
                          _buildTableCell('لا توجد أسطر مسجلة', isBold: true),
                          _buildTableCell('—'),
                          _buildTableCell('0.00'),
                          _buildTableCell('0.00'),
                        ],
                      ),
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
                Text(
                  'إجمالي المدين: ${totalDebit.toStringAsFixed(2)} ر.ي',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
                Text(
                  'إجمالي الدائن: ${totalCredit.toStringAsFixed(2)} ر.ي',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : (color ?? const Color(0xFF1E293B)),
        ),
      ),
    );
  }

  Widget _buildBottomStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
