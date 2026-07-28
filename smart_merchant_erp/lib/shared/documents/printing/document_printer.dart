import 'package:printing/printing.dart';
import '../presentation/models/commercial_document_data.dart';
import 'official_invoice_pdf_builder.dart';

class DocumentPrinter {
  static Future<void> printDocument(CommercialDocumentData docData) async {
    final pdf = await OfficialCommercialDocumentPdfBuilder.build(docData);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${docData.documentType}_${docData.documentNumber}',
    );
  }
}
