import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../application/services/inventory_reports_service.dart';

/// Professional Arabic Inventory Report PDF Builder & Printing Service.
/// Designed to match official commercial stock reports with bilingual headers,
/// itemized valuations, and certified signature blocks.
class InventoryReportPdfService {
  static final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  static final _qtyFormat = NumberFormat('#,##0.##', 'en_US');
  static final _dateFormat = DateFormat('yyyy-MM-dd', 'en_US');

  static pw.Font? _arabicRegular;
  static pw.Font? _arabicBold;

  static Future<void> _loadFonts() async {
    // 1. Try local assets
    try {
      if (_arabicRegular == null) {
        final regData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        _arabicRegular = pw.Font.ttf(regData);
      }
      if (_arabicBold == null) {
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        _arabicBold = pw.Font.ttf(boldData);
      }
    } catch (_) {}

    // 2. Try file system
    try {
      final regFile = File('assets/fonts/Cairo-Regular.ttf');
      if (regFile.existsSync()) {
        _arabicRegular ??= pw.Font.ttf(regFile.readAsBytesSync().buffer.asByteData());
      }
      final boldFile = File('assets/fonts/Cairo-Bold.ttf');
      if (boldFile.existsSync()) {
        _arabicBold ??= pw.Font.ttf(boldFile.readAsBytesSync().buffer.asByteData());
      }
    } catch (_) {}

    // 3. Fallback to Google Fonts
    try {
      _arabicRegular ??= await PdfGoogleFonts.cairoRegular();
      _arabicBold ??= await PdfGoogleFonts.cairoBold();
    } catch (_) {}

    // Final fallback to default if all else fails
    _arabicRegular ??= pw.Font.courier();
    _arabicBold ??= pw.Font.courierBold();
  }

  static pw.TextStyle _ts({
    double size = 9,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        font: bold ? _arabicBold : _arabicRegular,
        fontSize: size,
        color: color ?? PdfColor.fromHex('#1E293B'),
      );

  /// Fetches business & branch info for the corporate header
  static Future<({String nameAr, String? phone, String? address, String currency})>
      _getBusinessInfo() async {
    final db = getIt<AppDatabase>();
    String nameAr = 'التاجر الذكي للأنظمة المحاسبية';
    String? phone;
    String? address;
    String currency = 'ريال يمني (YER)';

    try {
      final bus = await (db.select(db.businesses)..limit(1)).getSingleOrNull();
      if (bus != null) {
        nameAr = bus.businessName;
      }
      final branch = await (db.select(db.branches)..limit(1)).getSingleOrNull();
      if (branch != null) {
        phone = branch.phone;
        address = branch.address;
      }
      final cur = await (db.select(db.currencies)
            ..where((c) => c.isBaseCurrency.equals(true)))
          .getSingleOrNull();
      if (cur != null) {
        currency = '${cur.currencyNameAr} (${cur.currencySymbol})';
      }
    } catch (_) {}

    return (nameAr: nameAr, phone: phone, address: address, currency: currency);
  }

  /// Generates the official multi-page A4 PDF Document
  static Future<pw.Document> generateDocument({
    required InventoryReportSummary summary,
  }) async {
    await _loadFonts();
    final info = await _getBusinessInfo();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _arabicRegular,
        bold: _arabicBold,
      ),
    );

    final dateStr = _dateFormat.format(summary.generatedAt);
    final reportMainTitle =
        '${summary.reportTypeName} - $dateStr في مخزن: ${summary.selectedWarehouseName}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        header: (ctx) => _buildHeader(info, reportMainTitle, ctx.pageNumber, ctx.pagesCount),
        footer: (ctx) => _buildFooter(ctx.pageNumber, ctx.pagesCount),
        build: (ctx) => [
          // Items Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#94A3B8'), width: 0.6),
            headerStyle: _ts(size: 8, bold: true, color: PdfColors.black),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
            cellStyle: _ts(size: 7.5),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4), // رقم الصنف
              1: pw.FlexColumnWidth(3.0), // اسم الصنف
              2: pw.FlexColumnWidth(1.0), // الوحدة
              3: pw.FlexColumnWidth(1.2), // الكمية المتوفرة
              4: pw.FlexColumnWidth(1.2), // سعر التكلفة
              5: pw.FlexColumnWidth(1.4), // إجمالي التكلفة
              6: pw.FlexColumnWidth(1.2), // سعر البيع
              7: pw.FlexColumnWidth(1.4), // إجمالي البيع
            },
            headers: [
              'رقم الصنف',
              'اسم الصنف',
              'الوحدة',
              'الكمية المتوفرة',
              'سعر التكلفة',
              'إجمالي التكلفة',
              'سعر البيع',
              'إجمالي البيع',
            ],
            data: summary.items.map((item) {
              return [
                item.productCode,
                item.productName,
                item.unitName,
                _qtyFormat.format(item.quantity),
                _moneyFormat.format(item.costPrice),
                _moneyFormat.format(item.totalCost),
                _moneyFormat.format(item.sellingPrice),
                _moneyFormat.format(item.totalSelling),
              ];
            }).toList(),
          ),

          // Total Summary Row
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EFF6FF'),
              border: pw.Border.all(color: PdfColor.fromHex('#94A3B8'), width: 0.8),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    'إجمالي القيمة (${summary.items.length} صنف)',
                    style: _ts(size: 9, bold: true, color: PdfColor.fromHex('#0F172A')),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _qtyFormat.format(summary.totalQuantity),
                    style: _ts(size: 8.5, bold: true),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'إجمالي التكلفة: ${_moneyFormat.format(summary.totalCostValue)}',
                    style: _ts(size: 8.5, bold: true, color: PdfColor.fromHex('#DC2626')),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'إجمالي البيع: ${_moneyFormat.format(summary.totalSellingValue)}',
                    style: _ts(size: 8.5, bold: true, color: PdfColor.fromHex('#2563EB')),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Profitability Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('إجمالي عدد الأصناف', '${summary.totalItemsCount} صنف'),
                _buildSummaryItem('إجمالي الكميات المتوفرة', _qtyFormat.format(summary.totalQuantity)),
                _buildSummaryItem('إجمالي التكلفة المخزنية', '${_moneyFormat.format(summary.totalCostValue)} YER', isDanger: true),
                _buildSummaryItem('إجمالي القيمة البيعية', '${_moneyFormat.format(summary.totalSellingValue)} YER', isPrimary: true),
                _buildSummaryItem('هامش الربح المتوقع', '${_moneyFormat.format(summary.totalExpectedProfit)} YER', isSuccess: true),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Certified Signatures Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignatureBlock('أمين المخزن المسؤول'),
              _buildSignatureBlock('إدارة الحسابات والمراجعة'),
              _buildSignatureBlock('المدير العام / الاعتماد'),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    ({String nameAr, String? phone, String? address, String currency}) info,
    String reportTitle,
    int pageNum,
    int totalPages,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Arabic Company Details (Right side in RTL)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(info.nameAr, style: _ts(size: 13, bold: true, color: PdfColor.fromHex('#1E3A8A'))),
                  if (info.address != null) pw.Text('العنوان: ${info.address}', style: _ts(size: 8, color: PdfColor.fromHex('#475569'))),
                  if (info.phone != null) pw.Text('التلفون: ${info.phone}', style: _ts(size: 8, color: PdfColor.fromHex('#475569'))),
                ],
              ),

              // Center Logo / Emblem
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1E3A8A'),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'ERP',
                    style: _ts(size: 14, bold: true, color: PdfColors.white),
                  ),
                ),
              ),

              // English Company Details (Left side in RTL)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Smart Merchant ERP', style: _ts(size: 11, bold: true, color: PdfColor.fromHex('#1E3A8A'))),
                  pw.Text('Inventory & Warehouse System', style: _ts(size: 8, color: PdfColor.fromHex('#475569'))),
                  pw.Text('Yemen - Commercial Division', style: _ts(size: 8, color: PdfColor.fromHex('#475569'))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColor.fromHex('#0F172A'), thickness: 1.2),
          pw.SizedBox(height: 6),

          // Main Title Banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1F5F9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            ),
            child: pw.Center(
              child: pw.Text(
                reportTitle,
                style: _ts(size: 11, bold: true, color: PdfColor.fromHex('#0F172A')),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int pageNum, int totalPages) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('نظام التاجر الذكي لإدارة المخزون والمبيعات', style: _ts(size: 7.5, color: PdfColor.fromHex('#94A3B8'))),
          pw.Text('صفحة $pageNum من $totalPages', style: _ts(size: 7.5, bold: true, color: PdfColor.fromHex('#64748B'))),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, {bool isDanger = false, bool isPrimary = false, bool isSuccess = false}) {
    PdfColor valColor = PdfColor.fromHex('#0F172A');
    if (isDanger) valColor = PdfColor.fromHex('#DC2626');
    if (isPrimary) valColor = PdfColor.fromHex('#2563EB');
    if (isSuccess) valColor = PdfColor.fromHex('#059669');

    return pw.Column(
      children: [
        pw.Text(label, style: _ts(size: 7.5, color: PdfColor.fromHex('#64748B'))),
        pw.SizedBox(height: 2),
        pw.Text(value, style: _ts(size: 9, bold: true, color: valColor)),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(String roleTitle) {
    return pw.Container(
      width: 140,
      child: pw.Column(
        children: [
          pw.Text(roleTitle, style: _ts(size: 8.5, bold: true, color: PdfColor.fromHex('#334155'))),
          pw.SizedBox(height: 30),
          pw.Container(
            height: 1,
            color: PdfColor.fromHex('#94A3B8'),
          ),
          pw.SizedBox(height: 3),
          pw.Text('التوقيع / الختم', style: _ts(size: 7.5, color: PdfColor.fromHex('#94A3B8'))),
        ],
      ),
    );
  }

  /// Opens interactive preview dialog with print, save, and share capability
  static Future<void> showPreviewDialog({
    required BuildContext context,
    required InventoryReportSummary summary,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          width: 900,
          height: 700,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.print_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'معاينة طباعة: ${summary.reportTypeName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
              ),

              // Pdf Preview Body
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: PdfPreview(
                    build: (format) async {
                      final doc = await generateDocument(summary: summary);
                      return doc.save();
                    },
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    allowPrinting: true,
                    allowSharing: true,
                    pdfFileName: 'تقرير_مخزني_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Direct print layout
  static Future<void> printDirect({
    required BuildContext context,
    required InventoryReportSummary summary,
  }) async {
    final doc = await generateDocument(summary: summary);
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'تقرير_مخزني_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  /// Direct share PDF
  static Future<void> shareDirect({
    required BuildContext context,
    required InventoryReportSummary summary,
  }) async {
    final doc = await generateDocument(summary: summary);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'تقرير_مخزني_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
