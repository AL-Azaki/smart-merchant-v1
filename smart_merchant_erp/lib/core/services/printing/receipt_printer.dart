import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/arabic_tafqeet.dart';

class ReceiptPrinter {
  /// توليد وطباعة الفاتورة الحرارية الكلاسيكية (متوافقة مع طابعات الكاشير 80mm)
  static Future<void> printInvoice({
    required String invoiceNumber,
    required String date,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double total,
    double tax = 0.0,
    required double discount,
    String businessName = 'مؤسسة التاجر الذكي',
    String? phone,
    String? address,
    String currencyName = 'ريال يمني',
    String documentType = 'مبيعات',
    String paymentMethod = 'نقداً',
  }) async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          final isReturn = documentType.contains('مرتجع');

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // اسم المؤسسة
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (address != null && address.isNotEmpty)
                pw.Text(
                  address,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                ),
              if (phone != null && phone.isNotEmpty)
                pw.Text(
                  'هاتف: $phone',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              pw.SizedBox(height: 3),

              // نوع الفاتورة وطريقة الدفع
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 1),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                        right: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                      borderRadius: pw.BorderRadius.horizontal(right: pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'فاتورة: $documentType',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 1),
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                        left: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                      borderRadius: pw.BorderRadius.horizontal(left: pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      '($paymentMethod)',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),

              // بيانات الفاتورة والعميل
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('العميل: $customerName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          isReturn ? 'رقم المرتجع: $invoiceNumber' : 'رقم الفاتورة: $invoiceNumber',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('التاريخ: $date', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text('العملة: $currencyName', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),

              // عناوين الجدول
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
                columnWidths: const {
                  0: pw.FlexColumnWidth(44),
                  1: pw.FlexColumnWidth(16),
                  2: pw.FlexColumnWidth(20),
                  3: pw.FlexColumnWidth(20),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _buildHeaderCell('الصنف', pw.TextAlign.right),
                      _buildHeaderCell('الكمية', pw.TextAlign.center),
                      _buildHeaderCell('السعر', pw.TextAlign.center),
                      _buildHeaderCell('الإجمالي', pw.TextAlign.left),
                    ],
                  ),
                  ...items.map((item) {
                    final q = (item['qty'] is num) ? (item['qty'] as num).toDouble() : 1.0;
                    final price = (item['price'] is num)
                        ? (item['price'] as num).toDouble()
                        : (item['total'] is num ? (item['total'] as num).toDouble() / q : 0.0);
                    final rowTotal = (item['total'] is num) ? (item['total'] as num).toDouble() : (price * q);

                    return pw.TableRow(
                      children: [
                        _buildCell(item['name']?.toString() ?? '', pw.TextAlign.right, isBold: true),
                        _buildCell(q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2), pw.TextAlign.center, isBold: true),
                        _buildCell(NumberFormat('#,##0.##', 'en_US').format(price), pw.TextAlign.center),
                        _buildCell(NumberFormat('#,##0.##', 'en_US').format(rowTotal), pw.TextAlign.left, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 5),

              // المجاميع
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                  ),
                ),
                child: pw.Column(
                  children: [
                    if (discount > 0) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('إجمالي الأصناف:', style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('${NumberFormat('#,##0.##', 'en_US').format(total + discount)} $currencyName', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الخصم:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text('( ${NumberFormat('#,##0.##', 'en_US').format(discount)} - ) $currencyName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                    ],
                    // برواز الإجمالي الصافي
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1.5),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            isReturn ? 'المبلغ المسترد:' : 'المبلغ المستحق:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                          ),
                          pw.Text(
                            '${NumberFormat('#,##0.##', 'en_US').format(total)} $currencyName',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '(${ArabicTafqeet.convert(total, currencyName: currencyName)})',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // التذييل
              pw.Text(
                isReturn ? 'سند إرجاع بضاعة رسمي ومقيد بالحساب' : 'شكراً لتسوقكم معنا',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
              ),
              pw.Text(
                isReturn
                    ? 'تم استلام البضاعة وإعادتها للمخزن وتحديث الحساب المالي'
                    : 'البضاعة المباعة لا تُرد ولا تُستبدل إلا بموجب أصل الفاتورة',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice_$invoiceNumber',
    );
  }

  static pw.Widget _buildHeaderCell(String title, pw.TextAlign align) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.left
              ? pw.Alignment.centerLeft
              : pw.Alignment.center,
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildCell(String text, pw.TextAlign align, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.left
              ? pw.Alignment.centerLeft
              : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
