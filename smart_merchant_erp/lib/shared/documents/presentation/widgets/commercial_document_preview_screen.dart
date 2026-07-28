import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../models/commercial_document_data.dart';
import '../../printing/official_invoice_pdf_builder.dart';
import '../../printing/document_printer.dart';
import '../../sharing/document_share.dart';

class CommercialDocumentPreviewScreen extends StatelessWidget {
  final CommercialDocumentData document;

  const CommercialDocumentPreviewScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(document.documentType),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'طباعة',
            onPressed: () => DocumentPrinter.printDocument(document),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة',
            onPressed: () => DocumentShare.shareDocument(document),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await OfficialCommercialDocumentPdfBuilder.build(document);
          return doc.save();
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'document_${document.documentNumber}.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
