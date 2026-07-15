import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPrinter {
  /// توليد وطباعة الفاتورة (متوافقة مع طابعات الكاشير الحرارية 80mm)
  static Future<void> printInvoice({
    required String invoiceNumber,
    required String date,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double total,
    required double tax,
    required double discount,
  }) async {
    // جلب خط عربي مدعوم من Google Fonts بشكل ديناميكي (بدون تعقيد الأصول)
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // مقاس الرول الافتراضي للكاشير
        textDirection: pw.TextDirection.rtl, // دعم كامل للغة العربية
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('مؤسسة التاجر الذكي', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('الرقم الضريبي: 3004005001', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Text('فاتورة مبيعات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('رقم الفاتورة:'),
                  pw.Text(invoiceNumber),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('العميل:'),
                  pw.Text(customerName),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('التاريخ:'),
                  pw.Text(date),
                ],
              ),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              // عناوين الجدول
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('الصنف', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('الكمية', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('الإجمالي', textAlign: pw.TextAlign.left, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.SizedBox(height: 5),
              
              // الأصناف
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item['name'], maxLines: 1)),
                      pw.Expanded(flex: 1, child: pw.Text(item['qty'].toString(), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text(item['total'].toStringAsFixed(2), textAlign: pw.TextAlign.left)),
                    ],
                  ),
                );
              }),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              // المجاميع
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المجموع الفرعي:'),
                  pw.Text((total - tax + discount).toStringAsFixed(2)),
                ],
              ),
              if (discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الخصم:'),
                    pw.Text(discount.toStringAsFixed(2)),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الضريبة (15%):'),
                  pw.Text(tax.toStringAsFixed(2)),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي المستحق:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('${total.toStringAsFixed(2)} ﷼', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('شكراً لتسوقكم معنا!', textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 10),
              
              // باركود هيئة الزكاة والضريبة (مؤقت لحين برمجته Base64 TLV)
              pw.BarcodeWidget(
                data: 'https://zatca.gov.sa/invoice/$invoiceNumber',
                barcode: pw.Barcode.qrCode(),
                width: 60,
                height: 60,
              ),
            ],
          );
        },
      ),
    );

    // استدعاء نافذة الطباعة الخاصة بنظام التشغيل
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_$invoiceNumber',
    );
  }
}
