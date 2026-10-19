import 'package:flutter/material.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';

class OriginalInvoicePaperWidget extends StatelessWidget {
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final String journalNumber;
  final String dateStr;
  final double totalDebit;
  final bool isMobile;
  final CommercialDocumentData? documentData;
  final bool isLoading;

  const OriginalInvoicePaperWidget({
    super.key,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.journalNumber,
    required this.dateStr,
    required this.totalDebit,
    required this.isMobile,
    this.documentData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'جاري جلب بيانات الفاتورة الأصلية من النظام...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (documentData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text(
                'لم يتم العثور على الفاتورة الأصلية أو لا توجد فاتورة مرتبطة بهذا القيد',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final doc = documentData!;
    final currency = doc.currencyCode;

    final formattedDate =
        '${doc.issueDate.year}/${doc.issueDate.month.toString().padLeft(2, '0')}/${doc.issueDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.businessName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'هاتف: ${doc.businessPhone ?? "---"}  •  العنوان: ${doc.businessAddress ?? "المركز الرئيسي"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
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
                    Text(
                      doc.documentType,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc.paymentStatus == 'Paid'
                            ? 'مدفوعة'
                            : (doc.paymentStatus == 'Partial' ? 'مدفوعة جزئياً' : 'آجلة'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Invoice & Customer Info
          const Text(
            'معلومات الفاتورة والعميل',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('اسم العميل / الطرف:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(doc.customerOrSupplierName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('رقم الفاتورة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(doc.documentNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تاريخ الفاتورة:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(formattedDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Items Table
          const Text(
            'بنود وأصناف الفاتورة الفعلية',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 700),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFCBD5E1)),
                  columnWidths: const {
                    0: FixedColumnWidth(40),
                    1: FlexColumnWidth(2.5),
                    2: FixedColumnWidth(80),
                    3: FixedColumnWidth(70),
                    4: FixedColumnWidth(100),
                    5: FixedColumnWidth(90),
                    6: FixedColumnWidth(110),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                      children: [
                        _cell('م', isHeader: true),
                        _cell('اسم الصنف / المنتج', isHeader: true),
                        _cell('الوحدة', isHeader: true),
                        _cell('الكمية', isHeader: true),
                        _cell('سعر الوحدة', isHeader: true),
                        _cell('الخصم', isHeader: true),
                        _cell('الإجمالي ($currency)', isHeader: true),
                      ],
                    ),
                    if (doc.items.isNotEmpty)
                      ...doc.items.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final item = entry.value;
                        return TableRow(
                          children: [
                            _cell('$idx'),
                            _cell(item.description, isBold: true),
                            _cell(item.unitName ?? 'قطعة'),
                            _cell('${item.quantity}'),
                            _cell(item.unitPrice.toStringAsFixed(2)),
                            _cell(item.discount.toStringAsFixed(2)),
                            _cell(item.lineTotal.toStringAsFixed(2), color: const Color(0xFF10B981), isBold: true),
                          ],
                        );
                      })
                    else
                      TableRow(
                        children: [
                          _cell('1'),
                          _cell('بدون بنود مسجلة', isBold: true),
                          _cell('—'),
                          _cell('—'),
                          _cell('—'),
                          _cell('—'),
                          _cell(doc.grandTotal.toStringAsFixed(2), color: const Color(0xFF10B981), isBold: true),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Financial Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المجموع: ${doc.subtotal.toStringAsFixed(2)} $currency',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                if (doc.discount > 0)
                  Text(
                    'الخصم: -${doc.discount.toStringAsFixed(2)} $currency',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                Text(
                  'الإجمالي النهائي: ${doc.grandTotal.toStringAsFixed(2)} $currency',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF10B981)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 11 : 12,
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : (color ?? const Color(0xFF1E293B)),
        ),
      ),
    );
  }
}
