import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../presentation/models/commercial_document_data.dart';

class OfficialCommercialDocumentPdfBuilder {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;
  static pw.Font? _cairoSemiBold;

  static bool _isValidTtf(ByteData data) {
    if (data.lengthInBytes < 4) return false;
    final magic = data.getUint32(0);
    return magic == 0x00010000 || magic == 0x4F54544F;
  }

  static Future<void> _loadFonts() async {
    try {
      if (_cairoRegular == null) {
        final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        if (!_isValidTtf(regularData)) throw Exception('Invalid TTF format');
        _cairoRegular = pw.Font.ttf(regularData);
      }
    } catch (e) {
      _cairoRegular ??= await PdfGoogleFonts.cairoRegular();
    }

    try {
      if (_cairoBold == null) {
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        if (!_isValidTtf(boldData)) throw Exception('Invalid TTF format');
        _cairoBold = pw.Font.ttf(boldData);
      }
    } catch (e) {
      _cairoBold ??= await PdfGoogleFonts.cairoBold();
    }

    try {
      if (_cairoSemiBold == null) {
        final semiBoldData = await rootBundle.load('assets/fonts/Cairo-SemiBold.ttf');
        if (!_isValidTtf(semiBoldData)) throw Exception('Invalid TTF format');
        _cairoSemiBold = pw.Font.ttf(semiBoldData);
      }
    } catch (e) {
      _cairoSemiBold ??= await PdfGoogleFonts.cairoSemiBold();
    }
  }

  static Future<pw.Document> build(CommercialDocumentData docData) async {
    await _loadFonts();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _cairoRegular,
        bold: _cairoBold,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(top: 57, bottom: 43, left: 43, right: 43),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            _buildHeader(docData),
            pw.SizedBox(height: 16),
            _buildCustomerInfo(docData),
            pw.SizedBox(height: 16),
            _buildItemsTable(docData),
            pw.SizedBox(height: 16),
            _buildTotalsAndTerms(docData),
            pw.SizedBox(height: 24),
            _buildSignatures(),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(CommercialDocumentData docData) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Right (Business Info)
            pw.Expanded(
              flex: 32,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    docData.businessName,
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF1C3A82),
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 2,
                  ),
                  pw.SizedBox(height: 4),
                  if (docData.businessPhone != null && docData.businessPhone!.isNotEmpty) _buildMetaRow('هاتف:', docData.businessPhone!),
                  if (docData.businessAddress != null && docData.businessAddress!.isNotEmpty) _buildMetaRow('العنوان:', docData.businessAddress!),
                  if (docData.taxNumber != null && docData.taxNumber!.isNotEmpty) _buildMetaRow('الرقم الضريبي:', docData.taxNumber!),
                ],
              ),
            ),

            // Center (Title & Status)
            pw.Expanded(
              flex: 28,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    docData.documentType,
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF1C3A82),
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _getStatusBgColor(docData.paymentStatus),
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: pw.Text(
                      docData.paymentStatus,
                      style: pw.TextStyle(
                        color: _getStatusTextColor(docData.paymentStatus),
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Left (Metadata)
            pw.Expanded(
              flex: 40,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          docData.documentNumber, 
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A)), 
                          textDirection: pw.TextDirection.ltr,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.SizedBox(
                        width: 75,
                        child: pw.Text(
                          'رقم الفاتورة:', 
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF475569)),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  _buildMetaRowReverse('تاريخ الإصدار:', docData.issueDate.toIso8601String().split('T')[0]),
                  _buildMetaRowReverse('وقت الإصدار:', docData.issueDate.toIso8601String().split('T')[1].substring(0, 5)),
                  if (docData.branchName != null) _buildMetaRowReverse('الفرع:', docData.branchName!),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1), thickness: 1),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(CommercialDocumentData docData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'معلومات الفاتورة والعميل',
          style: pw.TextStyle(
            color: const PdfColor.fromInt(0xFF1C3A82),
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Right Box: Customer
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildMetaRowBox('اسم العميل:', (docData.customerOrSupplierName.isNotEmpty) ? docData.customerOrSupplierName : 'عميل نقدي'),
                  if (docData.customerOrSupplierPhone != null && docData.customerOrSupplierPhone!.isNotEmpty)
                    _buildMetaRowBox('الهاتف:', docData.customerOrSupplierPhone!),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            // Left Box: Payment & Cashier
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildMetaRowBox('طريقة الدفع:', docData.paymentMethod ?? 'نقداً'),
                  pw.SizedBox(height: 4),
                  _buildMetaRowBox('البائع/المندوب:', docData.createdBy ?? 'مستخدم النظام'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(CommercialDocumentData docData) {
    final formatCurrency = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final formatQty = NumberFormat.decimalPattern();

    // Enforce strict LTR on the table and explicitly map columns right-to-left
    // 0: Net, 1: Tax, 2: Discount, 3: Price, 4: Qty, 5: Unit, 6: SKU, 7: Desc, 8: #
    
    pw.Widget cell(String text, {pw.Alignment alignment = pw.Alignment.center, bool isHeader = false, bool isRtl = true, double hPad = 4}) {
      return pw.Container(
        alignment: alignment,
        padding: pw.EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
        child: pw.Directionality(
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Text(
            text,
            textAlign: alignment == pw.Alignment.centerRight 
                ? pw.TextAlign.right 
                : alignment == pw.Alignment.centerLeft 
                    ? pw.TextAlign.left 
                    : pw.TextAlign.center,
            style: pw.TextStyle(
              color: isHeader ? PdfColors.white : const PdfColor.fromInt(0xFF1E293B),
              fontSize: isHeader ? 11 : 10.5,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Table(
        border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(12),
          1: const pw.FlexColumnWidth(9),
          2: const pw.FlexColumnWidth(9),
          3: const pw.FlexColumnWidth(12),
          4: const pw.FlexColumnWidth(7),
          5: const pw.FlexColumnWidth(7),
          6: const pw.FlexColumnWidth(17),
          7: const pw.FlexColumnWidth(22),
          8: const pw.FlexColumnWidth(5),
        },
        children: [
          pw.TableRow(
            repeat: true, // Crucial for multi-page invoices
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1C3A82)),
            children: [
              cell('الإجمالي', isHeader: true, hPad: 4),
              cell('الضريبة', isHeader: true, hPad: 4),
              cell('الخصم', isHeader: true, hPad: 4),
              cell('سعر الوحدة', isHeader: true, hPad: 4),
              cell('الكمية', isHeader: true, hPad: 2),
              cell('الوحدة', isHeader: true, hPad: 2),
              cell('الباركود / SKU', isHeader: true, hPad: 6),
              cell('وصف المنتج', alignment: pw.Alignment.centerRight, isHeader: true, hPad: 6),
              cell('#', isHeader: true, hPad: 2),
            ],
          ),
          ...List<pw.TableRow>.generate(docData.items.length, (index) {
            final item = docData.items[index];
            return pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF1F5F9), width: 0.5),
                ),
              ),
              children: [
                cell(formatCurrency.format(item.lineTotal), isRtl: false, hPad: 4),
                cell(formatCurrency.format(item.tax), isRtl: false, hPad: 4),
                cell(formatCurrency.format(item.discount), isRtl: false, hPad: 4),
                cell(formatCurrency.format(item.unitPrice), isRtl: false, hPad: 4),
                cell(formatQty.format(item.quantity), isRtl: false, hPad: 2),
                cell(item.unitName ?? '—', hPad: 2),
                cell(item.sku ?? item.barcode ?? '—', isRtl: false, hPad: 6),
                cell(item.description, alignment: pw.Alignment.centerRight, hPad: 6),
                cell('${index + 1}', isRtl: false, hPad: 2),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalsAndTerms(CommercialDocumentData docData) {
    final currency = docData.currencySymbol ?? docData.currencyCode;
    final formatCurrency = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Terms
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (docData.notes != null && docData.notes!.isNotEmpty) ...[
                pw.Text('ملاحظات الفاتورة والشروط:', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1C3A82), fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(docData.notes!, style: const pw.TextStyle(color: PdfColor.fromInt(0xFF475569), fontSize: 10)),
                pw.SizedBox(height: 10),
              ],
              if (docData.terms != null && docData.terms!.isNotEmpty) ...[
                pw.Text('سياسة الاسترجاع والاستبدال:', style: pw.TextStyle(color: const PdfColor.fromInt(0xFF1C3A82), fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text(docData.terms!, style: const pw.TextStyle(color: PdfColor.fromInt(0xFF475569), fontSize: 10)),
              ]
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // Totals
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              _buildTotalRow('إجمالي المنتجات:', '${docData.items.length}', isBold: true),
              pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5),
              _buildTotalRow('المجموع الفرعي:', '${formatCurrency.format(docData.subtotal)} $currency'),
              if (docData.discount > 0)
                _buildTotalRow('الخصم:', '${formatCurrency.format(docData.discount)} $currency'),
              if (docData.tax > 0)
                _buildTotalRow('الضريبة:', '${formatCurrency.format(docData.tax)} $currency'),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1C3A82),
                  borderRadius: pw.BorderRadius.circular(6)
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الإجمالي النهائي:', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 15)),
                    pw.Text('${formatCurrency.format(docData.grandTotal)} $currency', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 15), textDirection: pw.TextDirection.ltr),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              if (docData.paidAmount > 0 || docData.paymentStatus == 'Paid' || docData.paymentStatus == 'مدفوعة')
                _buildTotalRow('المبلغ المدفوع:', '${formatCurrency.format(docData.paidAmount)} $currency', valueColor: const PdfColor.fromInt(0xFF16A34A), isBold: true),
              if (docData.remainingAmount > 0)
                _buildTotalRow('المبلغ المتبقي:', '${formatCurrency.format(docData.remainingAmount)} $currency', valueColor: const PdfColor.fromInt(0xFFDC2626), isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSignatureBox('ختم الشركة'),
        _buildSignatureBox('اعتماد الإدارة'),
        _buildSignatureBox('توقيع المستلم/العميل'),
        _buildSignatureBox('توقيع البائع/المندوب'),
      ],
    );
  }

  static pw.Widget _buildSignatureBox(String title) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: const PdfColor.fromInt(0xFF475569))),
          pw.SizedBox(height: 40),
          pw.Container(
            width: 80,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF94A3B8), width: 1)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 75, child: pw.Text(label, style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 11))),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: const PdfColor.fromInt(0xFF334155)),
              textDirection: _isMostlyEnglish(value) ? pw.TextDirection.ltr : pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRowReverse(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: const PdfColor.fromInt(0xFF334155)),
              textAlign: pw.TextAlign.right,
              textDirection: _isMostlyEnglish(value) ? pw.TextDirection.ltr : pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(width: 75, child: pw.Text(label, style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 11), textAlign: pw.TextAlign.left)),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRowBox(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 75, child: pw.Text(label, style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 11))),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: const PdfColor.fromInt(0xFF0F172A)),
              textDirection: _isMostlyEnglish(value) ? pw.TextDirection.ltr : pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isBold = false, PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: const PdfColor.fromInt(0xFF475569), fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(
            value,
            style: pw.TextStyle(color: valueColor ?? const PdfColor.fromInt(0xFF0F172A), fontSize: 11, fontWeight: pw.FontWeight.bold),
            textDirection: pw.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  static bool _isMostlyEnglish(String text) {
    if (text.isEmpty) return false;
    final englishChars = RegExp(r'[a-zA-Z0-9-]').allMatches(text).length;
    return (englishChars / text.length) > 0.5;
  }

  static PdfColor _getStatusBgColor(String status) {
    switch (status) {
      case 'Paid':
      case 'مدفوعة':
        return const PdfColor.fromInt(0xFFDCFCE7);
      case 'Partial':
      case 'مدفوعة جزئياً':
        return const PdfColor.fromInt(0xFFFEF9C3);
      case 'Unpaid':
      case 'غير مدفوعة':
      case 'آجلة':
        return const PdfColor.fromInt(0xFFFEE2E2);
      case 'Draft':
      case 'مسودة':
        return const PdfColor.fromInt(0xFFF1F5F9);
      case 'Reversed':
      case 'ملغاة':
        return const PdfColor.fromInt(0xFFE2E8F0);
      default:
        return const PdfColor.fromInt(0xFFDBEAFE);
    }
  }

  static PdfColor _getStatusTextColor(String status) {
    switch (status) {
      case 'Paid':
      case 'مدفوعة':
        return const PdfColor.fromInt(0xFF166534);
      case 'Partial':
      case 'مدفوعة جزئياً':
        return const PdfColor.fromInt(0xFF854D0E);
      case 'Unpaid':
      case 'غير مدفوعة':
      case 'آجلة':
        return const PdfColor.fromInt(0xFF991B1B);
      case 'Draft':
      case 'مسودة':
        return const PdfColor.fromInt(0xFF1E293B);
      case 'Reversed':
      case 'ملغاة':
        return const PdfColor.fromInt(0xFF334155);
      default:
        return const PdfColor.fromInt(0xFF1E40AF);
    }
  }
}
