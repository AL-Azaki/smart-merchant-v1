import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class JournalEntryPrintService {
  static Future<void> printDocument({
    required BuildContext context,
    required Map<String, dynamic> entry,
    required List<Map<String, dynamic>> lines,
    required bool isInvoiceTab,
  }) async {
    final journalNumber = entry['number']?.toString() ?? 'JE-2024-001';
    final dateStr = entry['date']?.toString() ?? '2024/06/25';
    final status = entry['status']?.toString() ?? 'Posted';

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
        : lines.isNotEmpty
            ? lines.asMap().entries.map((e) {
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
            pw.Text(
              isInvoiceTab ? 'بنود الفاتورة:' : 'أسطر القيد المحاسبي:',
              style: ts(size: 12, bold: true),
            ),
            pw.SizedBox(height: 6),
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

  static Future<void> shareOnWhatsApp({
    required Map<String, dynamic> entry,
    required bool isInvoiceTab,
  }) async {
    final journalNumber = entry['number']?.toString() ?? 'JE-2024-001';
    final dateStr = entry['date']?.toString() ?? '2024/06/25';

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

    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text)}',
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      await SharePlus.instance.share(ShareParams(text: text, subject: isInvoiceTab ? 'فاتورة $journalNumber' : 'قيد $journalNumber'));
    }
  }
}
