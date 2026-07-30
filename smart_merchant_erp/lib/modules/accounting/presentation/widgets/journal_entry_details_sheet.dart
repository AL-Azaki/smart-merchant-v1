import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/tokens/colors.dart';

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
  State<JournalEntryDetailsSheet> createState() => _JournalEntryDetailsSheetState();
}

class _JournalEntryDetailsSheetState extends State<JournalEntryDetailsSheet> {
  int _activeTab = 0; // 0 = عرض القيد, 1 = الفاتورة الأصلية

  // ── طباعة PDF ──────────────────────────────────────────────────────────────
  Future<void> _printDocument(BuildContext context) async {
    final journalNumber = widget.entry['number']?.toString() ?? 'JE-2024-001';
    final dateStr = widget.entry['date']?.toString() ?? '2024/06/25';
    final status = widget.entry['status']?.toString() ?? 'Posted';
    final isInvoiceTab = _activeTab == 1;

    // تحميل خط عربي Cairo لدعم النصوص العربية
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pw.TextStyle ts({double size = 11, bool bold = false, PdfColor? color}) => pw.TextStyle(
          font: bold ? arabicFontBold : arabicFont,
          fontSize: size,
          color: color,
        );

    final tableHeaders = isInvoiceTab
        ? ['رقم', 'وصف المنتج', 'الكمية', 'السعر', 'الخصم', 'الضريبة', 'الإجمالي', 'الصافي']
        : ['رقم', 'رمز الحساب', 'اسم الحساب', 'البيان', 'مدين', 'دائن'];

    final tableData = isInvoiceTab
        ? [
            ['1', 'منتج مباع', '10', '80', '0', '0', '800', '800'],
            ['2', 'منتج مباع', '5', '180', '0', '0', '900', '900'],
          ]
        : widget.lines.isNotEmpty
            ? widget.lines.asMap().entries.map((e) {
                final i = e.key + 1;
                final l = e.value;
                return [
                  '$i',
                  l['account_code']?.toString() ?? '---',
                  l['account_name']?.toString() ?? '---',
                  l['description']?.toString() ?? '---',
                  l['debit']?.toString() ?? '0',
                  l['credit']?.toString() ?? '0',
                ];
              }).toList()
            : [
                ['1', 'COA_111', 'الصندوق النقدي', 'استلام نقدية', '8,700', '--'],
                ['2', 'COA_41', 'إيرادات المبيعات', 'إيراد مبيعات', '--', '8,700'],
              ];

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // هيدر أزرق
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('متجر النور', style: ts(size: 16, bold: true, color: PdfColors.white)),
                      pw.Text('+967771234567', style: ts(size: 9, color: PdfColors.white)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isInvoiceTab ? 'فاتورة مبيعات' : 'قيد محاسبي',
                        style: ts(size: 18, bold: true, color: PdfColors.white),
                      ),
                      pw.Text('رقم: $journalNumber', style: ts(size: 10, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // معلومات الفاتورة/القيد
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('التاريخ: $dateStr', style: ts(size: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('الحالة: $status', style: ts(size: 10, bold: true)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    if (isInvoiceTab) ...[
                      pw.Text('العميل: محمد علي سالم', style: ts(size: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('طريقة الدفع: آجل', style: ts(size: 10)),
                    ] else ...[
                      pw.Text('نوع العملية: فاتورة مبيعات', style: ts(size: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text('العملة: ريال يمني', style: ts(size: 10)),
                    ],
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // عنوان الجدول
            pw.Text(
              isInvoiceTab ? 'بنود الفاتورة:' : 'أسطر القيد المحاسبي:',
              style: ts(size: 12, bold: true),
            ),
            pw.SizedBox(height: 6),

            // الجدول
            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
              headerStyle: ts(size: 10, bold: true, color: PdfColors.white),
              cellStyle: ts(size: 10),
              cellAlignments: {for (var i = 0; i < tableHeaders.length; i++) i: pw.Alignment.center},
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headers: tableHeaders,
              data: tableData,
            ),
            pw.SizedBox(height: 14),

            // الإجماليات
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.SizedBox(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('المجموع الفرعي:', style: ts(size: 10)),
                        pw.Text(isInvoiceTab ? '1,700 ر.ي' : '8,700 ر.ي', style: ts(size: 10, bold: true)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('الخصم:', style: ts(size: 10)),
                        pw.Text('0 ر.ي', style: ts(size: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الإجمالي النهائي:', style: ts(size: 11, bold: true, color: PdfColors.white)),
                          pw.Text(
                            isInvoiceTab ? '1,700 ر.ي' : '8,700 ر.ي',
                            style: ts(size: 12, bold: true, color: PdfColors.white),
                          ),
                        ],
                      ),
                    ),
                    if (isInvoiceTab) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ المدفوع:', style: ts(size: 10, color: PdfColor.fromHex('#10B981'))),
                          pw.Text('1,700 ر.ي', style: ts(size: 10, bold: true, color: PdfColor.fromHex('#10B981'))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            pw.Spacer(),

            // توقيعات
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                for (final label in ['توقيع البائع/المندوب', 'توقيع المستلم/العميل', 'اعتماد الإدارة', 'ختم الشركة'])
                  pw.Column(children: [
                    pw.Text(label, style: ts(size: 9)),
                    pw.SizedBox(height: 16),
                    pw.Text('.....................', style: ts(size: 9, color: PdfColors.grey)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: isInvoiceTab ? 'فاتورة_$journalNumber' : 'قيد_$journalNumber',
    );
  }

  // ── مشاركة واتساب ──────────────────────────────────────────────────────────

  Future<void> _shareOnWhatsApp() async {
    final journalNumber = widget.entry['number']?.toString() ?? 'JE-2024-001';
    final dateStr = widget.entry['date']?.toString() ?? '2024/06/25';
    final isInvoiceTab = _activeTab == 1;

    final text = isInvoiceTab
        ? '''🧾 *فاتورة مبيعات*
━━━━━━━━━━━━━━
📌 رقم الفاتورة: $journalNumber
📅 التاريخ: $dateStr
🏪 الشركة: متجر النور
👤 العميل: محمد علي سالم

📦 *بنود الفاتورة:*
• منتج مباع × 10 وحدة = 800 ر.ي
• منتج مباع × 5 وحدة = 900 ر.ي

━━━━━━━━━━━━━━
💰 *الإجمالي النهائي: 1,700 ر.ي*
✅ الحالة: مدفوعة

_Smart Merchant ERP_'''
        : '''📒 *قيد محاسبي*
━━━━━━━━━━━━━━
📌 رقم القيد: $journalNumber
📅 التاريخ: $dateStr
🏪 الشركة: متجر النور

📊 *أسطر القيد:*
• الصندوق النقدي (مدين): 8,700 ر.ي
• إيرادات المبيعات (دائن): 8,700 ر.ي

━━━━━━━━━━━━━━
⚖️ *الحالة: متوازن ✓*
✅ مُرحَّل

_Smart Merchant ERP_''';

    // محاولة فتح واتساب مباشرة
    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      // fallback: مشاركة عامة عبر share_plus
      await SharePlus.instance.share(ShareParams(text: text, subject: isInvoiceTab ? 'فاتورة $journalNumber' : 'قيد $journalNumber'));
    }
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

    final journalNumber = widget.entry['number']?.toString() ?? widget.entry['journal_number']?.toString() ?? 'JE-2024-001';
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
          // ── 1. Responsive Header Banner ──
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
                      // Segmented Tab Toggle for Desktop/Tablet
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
                  // Segmented Tab Toggle full width for Mobile
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

          // ── 2. Scrollable Body Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Action buttons row (Print & Whatsapp Share)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareOnWhatsApp(),
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
                          onPressed: () => _printDocument(context),
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
                            child: Text(_activeTab == 0 ? 'طباعة القيد' : 'طباعة الفاتورة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Document Paper View (Journal Entry vs Invoice)
                  _activeTab == 0
                      ? _buildJournalEntryPaper(surface, borderColor, textPrimary, textSecondary, journalNumber, dateStr, isPosted, operationType, totalDebit, totalCredit, isBalanced, lineCount, isMobile)
                      : _buildOriginalInvoicePaper(surface, borderColor, textPrimary, textSecondary, journalNumber, dateStr, totalDebit, isMobile),

                  const SizedBox(height: 14),

                  // Bottom Stat Summary Bar (3 Cards)
                  Row(
                    children: [
                      Expanded(child: _buildBottomStatCard('نوع العملية', operationType, isDark ? Colors.white : const Color(0xFF1E3A8A))),
                      const SizedBox(width: 6),
                      Expanded(child: _buildBottomStatCard('عدد الأسطر', '$lineCount سطر', const Color(0xFF2563EB))),
                      const SizedBox(width: 6),
                      Expanded(child: _buildBottomStatCard('التوازن', isBalanced ? 'متوازن ✓' : 'غير متوازن', isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
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
          // Header company title & Badge
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

          // Section 1: Audit Information
          const Text('معلومات التدقيق والعملية (AUDIT INFORMATION)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),

          if (isMobile) ...[
            // Stacked Audit Info Cards for Mobile
            _buildInfoCard('مصدر القيد', operationType, 'رقم المرجع', 'si_001', 'الفرع/الشركة', 'متجر النور', 'نوع العملة', 'ر.ي', textSecondary, textPrimary),
            const SizedBox(height: 8),
            _buildInfoCard('أنشئ بواسطة', 'محمد أحمد', 'تاريخ الإنشاء', dateStr, 'وقت الإنشاء', '01:30 م', 'آخر تعديل', '2024/06/25 01:30 م', textSecondary, textPrimary),
            const SizedBox(height: 8),
            _buildInfoCard('تم الترحيل بواسطة', 'مدير الحسابات', 'وقت الترحيل', '01:30 م', 'حالة التوازن', isBalanced ? 'متوازن ✓' : 'غير متوازن', 'إجمالي الأسطر', '$lineCount', textSecondary, textPrimary),
          ] else ...[
            // Side-by-side Audit Info Cards for Desktop
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

          // Section 2: Table of Lines (Horizontal Scrollable for Clean Table Render)
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
                    // Header
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
                    // Rows
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
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Statistics and Totals Box (Responsive Stack for Mobile)
          if (isMobile) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إحصائيات إضافية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('عدد الحسابات المستخدمة: $lineCount حسابات  •  نوع العملية: $operationType', style: TextStyle(fontSize: 11, color: textSecondary)),
                  const SizedBox(height: 4),
                  Text('ملاحظات القيد والبيان العام: إثبات مبيعات يومية - فاتورة رقم INV-2024-001', style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي المدين:', style: TextStyle(fontSize: 11, color: textSecondary)),
                      Text('${totalDebit.toInt()} ر.ي', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي الدائن:', style: TextStyle(fontSize: 11, color: textSecondary)),
                      Text('${totalCredit.toInt()} ر.ي', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'الفرق: 0 ر.ي',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إحصائيات إضافية:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 4),
                        Text('عدد الحسابات المستخدمة: $lineCount حسابات  •  نوع العملية: $operationType', style: TextStyle(fontSize: 11, color: textSecondary)),
                        const SizedBox(height: 4),
                        Text('ملاحظات القيد والبيان العام: إثبات مبيعات يومية - فاتورة رقم INV-2024-001', style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('إجمالي المدين:', style: TextStyle(fontSize: 11, color: textSecondary)),
                            Text('${totalDebit.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('إجمالي الدائن:', style: TextStyle(fontSize: 11, color: textSecondary)),
                            Text('${totalCredit.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'الفرق: 0 ر.ي',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalInvoicePaper(
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    String journalNumber,
    String dateStr,
    double totalDebit,
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('متجر النور', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  SizedBox(height: 2),
                  Text('هاتف: +967771234567  •  العنوان: صنعاء، اليمن', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('فاتورة مبيعات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('مدفوعة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Customer Info
          const Text('معلومات الفاتورة والعميل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          const SizedBox(height: 6),

          if (isMobile) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('اسم العميل:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('محمد علي سالم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('طريقة الدفع:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('آجل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('اسم العميل:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('محمد علي سالم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('طريقة الدفع:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('آجل', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Invoice Items Table (Horizontal Scrollable for Mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                  columnWidths: const {
                    0: FixedColumnWidth(36),   // #
                    1: FixedColumnWidth(140),  // وصف المنتج
                    2: FixedColumnWidth(90),   // الباركود/SKU
                    3: FixedColumnWidth(64),   // الوحدة
                    4: FixedColumnWidth(56),   // الكمية
                    5: FixedColumnWidth(80),   // سعر الوحدة
                    6: FixedColumnWidth(56),   // الخصم
                    7: FixedColumnWidth(62),   // الضريبة
                    8: FixedColumnWidth(70),   // الإجمالي
                    9: FixedColumnWidth(66),   // الصافي
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                      children: [
                        _buildTableCell('رقم', isHeader: true),
                        _buildTableCell('وصف المنتج', isHeader: true),
                        _buildTableCell('الباركود/SKU', isHeader: true),
                        _buildTableCell('الوحدة', isHeader: true),
                        _buildTableCell('الكمية', isHeader: true),
                        _buildTableCell('سعر الوحدة', isHeader: true),
                        _buildTableCell('الخصم', isHeader: true),
                        _buildTableCell('الضريبة', isHeader: true),
                        _buildTableCell('الإجمالي', isHeader: true),
                        _buildTableCell('الصافي', isHeader: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('1'),
                        _buildTableCell('منتج مباع', isBold: true),
                        _buildTableCell('---'),
                        _buildTableCell('---'),
                        _buildTableCell('10'),
                        _buildTableCell('80'),
                        _buildTableCell('0'),
                        _buildTableCell('0'),
                        _buildTableCell('800', isBold: true),
                        _buildTableCell('800', color: const Color(0xFF10B981), isBold: true),
                      ],
                    ),
                    TableRow(
                      children: [
                        _buildTableCell('2'),
                        _buildTableCell('منتج مباع', isBold: true),
                        _buildTableCell('---'),
                        _buildTableCell('---'),
                        _buildTableCell('5'),
                        _buildTableCell('180'),
                        _buildTableCell('0'),
                        _buildTableCell('0'),
                        _buildTableCell('900', isBold: true),
                        _buildTableCell('900', color: const Color(0xFF10B981), isBold: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Invoice Totals Box (Responsive Stack for Mobile)
          if (isMobile) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملاحظات الفاتورة والشروط:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('لا توجد ملاحظات إضافية.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // إجمالي المنتجات
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي المنتجات:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('2 (15 وحدة)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  // المجموع الفرعي
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع الفرعي:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('1,700 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الخصم:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('0 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الضريبة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('0 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // الإجمالي النهائي
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الإجمالي النهائي:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('1,700 ر.ي', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // المبلغ المدفوع
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المبلغ المدفوع:', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      Text('1,700 ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ملاحظات الفاتورة والشروط:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('لا توجد ملاحظات إضافية.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // إجمالي المنتجات
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('إجمالي المنتجات:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('٢ (١٥ وحدة)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 5),
                        // المجموع الفرعي
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المجموع الفرعي:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('١،٧٠٠ ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الخصم:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('٠ ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('الضريبة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('٠ ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // الإجمالي النهائي
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الإجمالي النهائي:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('١،٧٠٠ ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        // المبلغ المدفوع
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('المبلغ المدفوع:', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            Text('١،٧٠٠ ر.ي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Signatures Responsive Grid for Mobile
          const Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 12,
            children: [
              _SignatureCol(title: 'توقيع البائع/المندوب'),
              _SignatureCol(title: 'توقيع المستلم/العميل'),
              _SignatureCol(title: 'اعتماد الإدارة'),
              _SignatureCol(title: 'ختم الشركة'),
            ],
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

class _SignatureCol extends StatelessWidget {
  final String title;
  const _SignatureCol({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        const Text('...........................', style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
