import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/shared/documents/presentation/models/commercial_document_data.dart';
import 'package:smart_merchant_erp/shared/documents/presentation/models/commercial_document_line.dart';
import 'package:smart_merchant_erp/shared/documents/printing/official_invoice_pdf_builder.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfficialCommercialDocumentPdfBuilder Tests', () {
    final sampleInvoice = CommercialDocumentData(
      documentType: 'فاتورة مبيعات',
      documentNumber: 'INV-2026-0001',
      issueDate: DateTime(2026, 10, 18, 14, 30),
      businessName: 'مؤسسة البركة للتجارة',
      businessPhone: '777123456',
      businessAddress: 'صنعاء - شارع تعز',
      branchName: 'المركز الرئيسي',
      customerOrSupplierName: 'محمد أحمد علي',
      customerOrSupplierPhone: '771000222',
      currencyCode: 'YER',
      currencySymbol: 'ريال يمني',
      paymentMethod: 'نقداً',
      paymentStatus: 'مدفوعة',
      items: const [
        CommercialDocumentLine(
          description: 'سكر برازيلي 50 كجم',
          unitName: 'كيس',
          quantity: 2,
          unitPrice: 15000,
          discount: 0,
          tax: 0,
          lineTotal: 30000,
        ),
        CommercialDocumentLine(
          description: 'أرز تايلندي بسمتي',
          unitName: 'قطمة 10 كجم',
          quantity: 3,
          unitPrice: 8500,
          discount: 500,
          tax: 0,
          lineTotal: 25000,
        ),
      ],
      subtotal: 55500,
      discount: 500,
      tax: 0,
      grandTotal: 55000,
      paidAmount: 55000,
      remainingAmount: 0,
      notes: 'شكراً لاختياركم متجرنا',
      terms: 'البضاعة المباعة لا تُرد ولا تُستبدل إلا بموجب أصل الفاتورة',
      createdBy: 'أحمد الكاشير',
    );

    final sampleReturn = CommercialDocumentData(
      documentType: 'فاتورة مرتجع مبيعات',
      documentNumber: 'RET-2026-0005',
      issueDate: DateTime(2026, 10, 18, 15, 10),
      businessName: 'مؤسسة البركة للتجارة',
      businessPhone: '777123456',
      businessAddress: 'صنعاء - شارع تعز',
      branchName: 'المركز الرئيسي',
      customerOrSupplierName: 'محمد أحمد علي',
      customerOrSupplierPhone: '771000222',
      currencyCode: 'YER',
      currencySymbol: 'ريال يمني',
      paymentMethod: 'استرداد نقدي',
      paymentStatus: 'مرحل ومقيد',
      items: const [
        CommercialDocumentLine(
          description: 'سكر برازيلي 50 كجم',
          unitName: 'كيس',
          quantity: 1,
          unitPrice: 15000,
          discount: 0,
          tax: 0,
          lineTotal: 15000,
        ),
      ],
      subtotal: 15000,
      discount: 0,
      tax: 0,
      grandTotal: 15000,
      paidAmount: 15000,
      remainingAmount: 0,
      notes: 'مرتجع من فاتورة رقم: INV-2026-0001',
      terms: 'سند إرجاع بضاعة معتمد - تم استلام البضاعة وتحديث الحساب المالي',
      createdBy: 'أحمد الكاشير',
    );

    test('builds thermal 80mm sales invoice PDF without errors', () async {
      final pdf = await OfficialCommercialDocumentPdfBuilder.build(
        sampleInvoice,
        pageFormat: PdfPageFormat.roll80,
      );
      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('builds thermal 80mm sales return PDF without errors', () async {
      final pdf = await OfficialCommercialDocumentPdfBuilder.build(
        sampleReturn,
        pageFormat: PdfPageFormat.roll80,
      );
      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
    });

    test('builds A4 format document without errors', () async {
      final pdf = await OfficialCommercialDocumentPdfBuilder.build(
        sampleInvoice,
        pageFormat: PdfPageFormat.a4,
      );
      final bytes = await pdf.save();
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
