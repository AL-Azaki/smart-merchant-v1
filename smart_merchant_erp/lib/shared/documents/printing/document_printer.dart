import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../presentation/models/commercial_document_data.dart';
import 'official_invoice_pdf_builder.dart';

class DocumentPrinter {
  static Future<void> printDocument(
    CommercialDocumentData docData, {
    PdfPageFormat? pageFormat,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final targetFormat = pageFormat ??
            ((format.width > 300) ? PdfPageFormat.a4 : PdfPageFormat.roll80);
        final pdf = await OfficialCommercialDocumentPdfBuilder.build(
          docData,
          pageFormat: targetFormat,
        );
        return pdf.save();
      },
      name: '${docData.documentType}_${docData.documentNumber}',
    );
  }
}
