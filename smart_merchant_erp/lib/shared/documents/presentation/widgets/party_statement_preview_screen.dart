import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../modules/treasury/application/services/party_statement_service.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../printing/party_statement_pdf_builder.dart';

/// شاشة معاينة وطباعة ومشاركة كشف الحساب التحليلي للعميل أو المورد
class PartyStatementPreviewScreen extends StatelessWidget {
  final PartyStatementReport report;
  final String? customerPhone;
  final String businessName;
  final String? branchName;
  final String? businessAddress;
  final String? businessPhone;
  final DateTime? startDate;
  final DateTime? endDate;

  const PartyStatementPreviewScreen({
    super.key,
    required this.report,
    this.customerPhone,
    this.businessName = 'التاجر الذكي للحلول التجارية',
    this.branchName = 'الفرع الرئيسي',
    this.businessAddress = 'صنعاء - اليمن',
    this.businessPhone = '777000000',
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCustomer = report.partyType == 'Customer';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(isCustomer ? 'كشف حساب عميل: ${report.partyName}' : 'كشف حساب مورد: ${report.partyName}'),
        centerTitle: true,
        actions: [
          // زر إرسال ملخص واتساب
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
            tooltip: 'إرسال ملخص عبر واتساب',
            onPressed: () => PartyStatementPdfBuilder.shareViaWhatsApp(
              report: report,
              phone: customerPhone,
              businessName: businessName,
            ),
          ),
          // زر مشاركة ملف PDF
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة ملف PDF',
            onPressed: () => PartyStatementPdfBuilder.sharePdf(
              report: report,
              businessName: businessName,
              branchName: branchName,
              businessAddress: businessAddress,
              businessPhone: businessPhone,
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async {
          final doc = await PartyStatementPdfBuilder.build(
            report: report,
            businessName: businessName,
            branchName: branchName,
            businessAddress: businessAddress,
            businessPhone: businessPhone,
            startDate: startDate,
            endDate: endDate,
          );
          return doc.save();
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'كشف_حساب_${report.partyName.replaceAll(' ', '_')}.pdf',
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('جاري إعداد كشف الحساب الكلاسيكي A4...'),
            ],
          ),
        ),
      ),
    );
  }
}
