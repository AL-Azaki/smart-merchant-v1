import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../presentation/models/commercial_document_data.dart';
import '../printing/official_invoice_pdf_builder.dart';

class DocumentShare {
  /// Shares the official compact thermal PDF document natively using the OS share sheet.
  static Future<void> shareDocument(
    CommercialDocumentData docData, {
    PdfPageFormat? pageFormat,
  }) async {
    final pdf = await OfficialCommercialDocumentPdfBuilder.build(
      docData,
      pageFormat: pageFormat ?? PdfPageFormat.roll80,
    );
    final bytes = await pdf.save();

    final safeFilename = '${docData.documentType}_${docData.documentNumber}'
        .replaceAll(' ', '_')
        .replaceAll('/', '-')
        .toLowerCase();

    await Printing.sharePdf(
      bytes: bytes,
      filename: '$safeFilename.pdf',
    );
  }

  /// Optional: Shares a clean text summary via WhatsApp without tax or emojis.
  static Future<void> shareViaWhatsApp(CommercialDocumentData docData) async {
    final buffer = StringBuffer();
    final currency = docData.currencySymbol ?? 'ريال يمني';

    buffer.writeln('*${docData.businessName}*');
    buffer.writeln('------------------------');
    buffer.writeln('*${docData.documentType}*');
    buffer.writeln('رقم المستند: ${docData.documentNumber}');
    buffer.writeln('التاريخ: ${docData.issueDate.toString().split(' ')[0]}');
    buffer.writeln('العميل: ${docData.customerOrSupplierName}');
    buffer.writeln('------------------------');

    for (var item in docData.items) {
      buffer.writeln('- ${item.description}');
      buffer.writeln('  الكمية: ${item.quantity} | الإجمالي: ${item.lineTotal.toStringAsFixed(2)} $currency');
    }

    buffer.writeln('------------------------');
    if (docData.discount > 0) {
      buffer.writeln('المجموع الفرعي: ${docData.subtotal.toStringAsFixed(2)} $currency');
      buffer.writeln('الخصم: ${docData.discount.toStringAsFixed(2)} $currency');
    }
    buffer.writeln('*المبلغ المستحق: ${docData.grandTotal.toStringAsFixed(2)} $currency*');
    if (docData.remainingAmount > 0) {
      if (docData.paidAmount > 0) {
        buffer.writeln('المدفوع: ${docData.paidAmount.toStringAsFixed(2)} $currency');
      }
      buffer.writeln('المتبقي: ${docData.remainingAmount.toStringAsFixed(2)} $currency');
    }
    buffer.writeln('------------------------');
    buffer.writeln('شكراً لتعاملكم معنا');

    final encodedMessage = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$encodedMessage');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp or share intent';
    }
  }
}
