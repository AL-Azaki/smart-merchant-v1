import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../modules/treasury/application/services/party_statement_service.dart';
import '../../utils/arabic_tafqeet.dart';

/// منشئ كشف الحساب التحليلي الرسمي للعملاء والموردين بتصميم كلاسيكي محاسبي متوافق مع معايير الأنظمة المالية اليمنية
class PartyStatementPdfBuilder {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;
  static pw.Font? _cairoSemiBold;

  static const PdfColor _headerBg = PdfColor(0.945, 0.961, 0.976);
  static const PdfColor _openingBg = PdfColor(0.98, 0.98, 0.98);
  static const PdfColor _altRowBg = PdfColor(0.984, 0.984, 0.984);
  static const PdfColor _totalBg = PdfColor(0.886, 0.910, 0.941);
  static const PdfColor _calloutBg = PdfColor(0.878, 0.949, 0.996);
  static const PdfColor _calloutBorder = PdfColor(0.22, 0.74, 0.97);

  static bool _isValidTtf(ByteData data) {
    if (data.lengthInBytes < 4) return false;
    final magic = data.getUint32(0);
    return magic == 0x00010000 || magic == 0x4F54544F;
  }

  static pw.Font? _tryLoadTtf(ByteData data) {
    try {
      if (!_isValidTtf(data)) return null;
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _loadFonts() async {
    try {
      final regFile = File('assets/fonts/Cairo-Regular.ttf');
      if (regFile.existsSync()) {
        _cairoRegular ??= _tryLoadTtf(regFile.readAsBytesSync().buffer.asByteData());
      }
      final boldFile = File('assets/fonts/Cairo-Bold.ttf');
      if (boldFile.existsSync()) {
        _cairoBold ??= _tryLoadTtf(boldFile.readAsBytesSync().buffer.asByteData());
      }
      final semiBoldFile = File('assets/fonts/Cairo-SemiBold.ttf');
      if (semiBoldFile.existsSync()) {
        _cairoSemiBold ??= _tryLoadTtf(semiBoldFile.readAsBytesSync().buffer.asByteData());
      }
    } catch (_) {}

    try {
      if (_cairoRegular == null) {
        final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        _cairoRegular ??= _tryLoadTtf(regularData);
      }
      if (_cairoBold == null) {
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        _cairoBold ??= _tryLoadTtf(boldData);
      }
      if (_cairoSemiBold == null) {
        final semiBoldData = await rootBundle.load('assets/fonts/Cairo-SemiBold.ttf');
        _cairoSemiBold ??= _tryLoadTtf(semiBoldData);
      }
    } catch (_) {}

    // Fallbacks
    try {
      _cairoRegular ??= await PdfGoogleFonts.cairoRegular();
    } catch (_) {}
    try {
      _cairoBold ??= await PdfGoogleFonts.cairoBold();
    } catch (_) {}
    try {
      _cairoSemiBold ??= await PdfGoogleFonts.cairoSemiBold();
    } catch (_) {}

    _cairoRegular ??= pw.Font.helvetica();
    _cairoBold ??= pw.Font.helveticaBold();
    _cairoSemiBold ??= pw.Font.helveticaBold();
  }

  static String _formatNum(double val) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(val);
  }

  static String _formatDate(DateTime d) {
    return DateFormat('yyyy-MM-dd').format(d);
  }

  /// بناء وثيقة PDF الرسمية لكشف الحساب مقاس A4
  static Future<pw.Document> build({
    required PartyStatementReport report,
    String businessName = 'التاجر الذكي للحلول التجارية',
    String? branchName = 'الفرع الرئيسي',
    String? businessAddress = 'صنعاء - اليمن',
    String? businessPhone = '777000000',
    String? responsibleUser = 'إدارة الحسابات',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _cairoRegular,
        bold: _cairoBold,
      ),
    );

    final isCustomer = report.partyType == 'Customer';
    final lines = report.lines;

    // حساب تواريخ الفترة
    final startStr = startDate != null
        ? _formatDate(startDate)
        : (lines.isNotEmpty ? _formatDate(lines.first.date) : _formatDate(DateTime.now()));
    final endStr = endDate != null
        ? _formatDate(endDate)
        : (lines.isNotEmpty ? _formatDate(lines.last.date) : _formatDate(DateTime.now()));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        textDirection: pw.TextDirection.rtl,
        maxPages: 100,
        header: (context) => pw.Column(
          children: [
            _buildOfficialHeader(
              businessName: businessName,
              branchName: branchName,
              businessAddress: businessAddress,
              businessPhone: businessPhone,
            ),
            pw.SizedBox(height: 4),
            _buildReportTitleBar(
              isCustomer: isCustomer,
              startStr: startStr,
              endStr: endStr,
            ),
            pw.SizedBox(height: 4),
            _buildMetadataBar(
              report: report,
              isCustomer: isCustomer,
            ),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          padding: const pw.EdgeInsets.only(top: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تم استخراج التقرير في: ${_formatDate(DateTime.now())} - ${DateFormat('HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            _buildClassicLedgerTable(
              report: report,
              isCustomer: isCustomer,
            ),
            pw.SizedBox(height: 8),
            _buildCalloutBox(
              report: report,
              isCustomer: isCustomer,
            ),
            pw.SizedBox(height: 8),
            _buildVerificationAndSignatures(
              report: report,
              isCustomer: isCustomer,
              responsibleUser: responsibleUser,
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // 1. الترويسة المعتمدة في النظام (نفس هيدر الفواتير السابقة)
  static pw.Widget _buildOfficialHeader({
    required String businessName,
    String? branchName,
    String? businessAddress,
    String? businessPhone,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          businessName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (branchName != null && branchName.isNotEmpty) ...[
              pw.Text(branchName, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
              pw.SizedBox(width: 8),
            ],
            if (businessAddress != null && businessAddress.isNotEmpty) ...[
              pw.Text('• $businessAddress', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800)),
              pw.SizedBox(width: 8),
            ],
            if (businessPhone != null && businessPhone.isNotEmpty) ...[
              pw.Text('• هاتف: $businessPhone',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
            ],
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: PdfColors.black),
      ],
    );
  }

  // 2. شريط عنوان التقرير والفترة الزمنية
  static pw.Widget _buildReportTitleBar({
    required bool isCustomer,
    required String startStr,
    required String endStr,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'الفترة من: $startStr إلى: $endStr',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                color: PdfColors.white,
              ),
              child: pw.Text(
                'كشف حساب تحليلي - رصيد نهاية التقرير',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.Text(
              isCustomer ? 'نوع الحساب: عميل' : 'نوع الحساب: مورد',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
          ],
        ),
      ],
    );
  }

  // 3. شريط بيانات العميل / المورد والعملة
  static pw.Widget _buildMetadataBar({
    required PartyStatementReport report,
    required bool isCustomer,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.8),
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '${isCustomer ? "اسم العميل" : "اسم المورد"}: ${report.partyName}',
            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.Text(
            'رقم الحساب: ${report.partyId}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.Text(
            'العملة: ريال يمني',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  // 4. جدول كشف الحساب الكلاسيكي بالأعمدة الـ 8
  static pw.Widget _buildClassicLedgerTable({
    required PartyStatementReport report,
    required bool isCustomer,
  }) {
    const border = pw.TableBorder(
      left: pw.BorderSide(color: PdfColors.black, width: 0.8),
      right: pw.BorderSide(color: PdfColors.black, width: 0.8),
      top: pw.BorderSide(color: PdfColors.black, width: 0.8),
      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
      verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
    );

    final rows = <pw.TableRow>[];

    // رأس الجدول
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _buildTh('التاريخ', flex: 11),
          _buildTh('نوع المستند', flex: 13),
          _buildTh('رقم السند', flex: 9),
          _buildTh('المرجع', flex: 8),
          _buildTh('البيان', flex: 31),
          _buildTh('المدين\n(عليه)', flex: 10),
          _buildTh('الدائن\n(له)', flex: 10),
          _buildTh('الرصيد\n(عليكم/لكم)', flex: 11),
        ],
      ),
    );

    // سطر الرصيد الافتتاحي إذا وجد
    if (report.openingBalance != 0.0) {
      final isDebit = report.openingBalance > 0;
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _openingBg),
          children: [
            _buildTd('-', align: pw.TextAlign.center),
            _buildTd('رصيد سابق', align: pw.TextAlign.center, isBold: true),
            _buildTd('-', align: pw.TextAlign.center),
            _buildTd('-', align: pw.TextAlign.center),
            _buildTd('رصيد افتتاحي مرحل سابق', align: pw.TextAlign.right, isBold: true),
            _buildTd(isDebit ? _formatNum(report.openingBalance) : '', align: pw.TextAlign.center, isBold: isDebit),
            _buildTd(!isDebit ? _formatNum(report.openingBalance.abs()) : '', align: pw.TextAlign.center, isBold: !isDebit),
            _buildBalanceTd(report.openingBalance, isCustomer: isCustomer),
          ],
        ),
      );
    }

    // سطور الحركات
    for (int i = 0; i < report.lines.length; i++) {
      final line = report.lines[i];
      final bg = i % 2 == 0 ? PdfColors.white : _altRowBg;

      // تفصيل نوع المستند بالعربي الكلاسيكي
      String typeLabel = line.documentType;
      String accountHeading = '';
      if (line.documentType == 'Invoice') {
        typeLabel = isCustomer ? 'مبيعات آجل' : 'فاتورة مشتريات';
        accountHeading = isCustomer ? 'إلى ح/ المبيعات' : 'من ح/ المشتريات';
      } else if (line.documentType == 'Payment') {
        typeLabel = isCustomer ? 'سند قبض نقداً' : 'سند صرف نقداً';
        accountHeading = isCustomer ? 'من ح/ الصندوق الخزينة' : 'إلى ح/ الصندوق الخزينة';
      } else if (line.documentType == 'Return') {
        typeLabel = isCustomer ? 'مردود مبيعات' : 'مردود مشتريات';
        accountHeading = isCustomer ? 'من ح/ مردودات المبيعات' : 'إلى ح/ مردودات المشتريات';
      } else if (line.documentType == 'Opening') {
        typeLabel = 'رصيد سابق';
        accountHeading = 'حساب الأرصدة الافتتاحية';
      }

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            _buildTd(_formatDate(line.date), align: pw.TextAlign.center),
            _buildTd(typeLabel, align: pw.TextAlign.center, isBold: true),
            _buildTd(line.documentNumber, align: pw.TextAlign.center),
            _buildTd(line.documentNumber.replaceAll(RegExp(r'[^0-9]'), ''), align: pw.TextAlign.center),
            _buildDescriptionTd(
              accountHeading: accountHeading,
              note: line.description,
              isCredit: line.credit > 0,
            ),
            _buildTd(line.debit > 0 ? _formatNum(line.debit) : '', align: pw.TextAlign.center, isBold: line.debit > 0),
            _buildTd(line.credit > 0 ? _formatNum(line.credit) : '', align: pw.TextAlign.center, isBold: line.credit > 0),
            _buildBalanceTd(line.runningBalance, isCustomer: isCustomer),
          ],
        ),
      );
    }

    // سطر الإجماليات (بيان الأرصدة)
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _totalBg),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'بيان الأرصدة | إجمالي الرصيد (ريال يمني)',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
            ),
          ),
          pw.Container(), // Type
          pw.Container(), // Doc
          pw.Container(), // Ref
          pw.Container(), // Note
          _buildTd(_formatNum(report.totalDebit), align: pw.TextAlign.center, isBold: true),
          _buildTd(_formatNum(report.totalCredit), align: pw.TextAlign.center, isBold: true),
          _buildBalanceTd(report.closingBalance, isCustomer: isCustomer, isFinalTotal: true),
        ],
      ),
    );

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FlexColumnWidth(11), // التاريخ
        1: pw.FlexColumnWidth(13), // نوع المستند
        2: pw.FlexColumnWidth(9),  // رقم السند
        3: pw.FlexColumnWidth(8),  // المرجع
        4: pw.FlexColumnWidth(31), // البيان
        5: pw.FlexColumnWidth(10), // المدين
        6: pw.FlexColumnWidth(10), // الدائن
        7: pw.FlexColumnWidth(11), // الرصيد
      },
      children: rows,
    );
  }

  static pw.Widget _buildTh(String text, {required double flex}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildTd(
    String text, {
    pw.TextAlign align = pw.TextAlign.center,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.0,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildDescriptionTd({
    required String accountHeading,
    required String note,
    required bool isCredit,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (accountHeading.isNotEmpty)
            pw.Text(
              accountHeading,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: isCredit ? const PdfColor(0, 0.5, 0.2) : const PdfColor(0.8, 0, 0),
              ),
            ),
          pw.Text(
            note,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBalanceTd(
    double balance, {
    required bool isCustomer,
    bool isFinalTotal = false,
  }) {
    final absVal = balance.abs();
    final bool isDebit = balance > 0;
    final bool isZero = balance == 0.0;

    String label = '';
    PdfColor labelColor = PdfColors.black;

    if (!isZero) {
      if (isCustomer) {
        label = isDebit ? '(عليكم)' : '(لكم)';
        labelColor = isDebit ? const PdfColor(0.8, 0, 0) : const PdfColor(0, 0.5, 0.2);
      } else {
        label = isDebit ? '(لنا)' : '(لهم)';
        labelColor = isDebit ? const PdfColor(0, 0.5, 0.2) : const PdfColor(0.8, 0, 0);
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _formatNum(absVal),
            style: pw.TextStyle(
              fontSize: 8.0,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          if (label.isNotEmpty)
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7.0,
                fontWeight: pw.FontWeight.bold,
                color: labelColor,
              ),
            ),
        ],
      ),
    );
  }

  // 5. الصندوق البارز للرصيد النهائي والتفقيط بالعربي
  static pw.Widget _buildCalloutBox({
    required PartyStatementReport report,
    required bool isCustomer,
  }) {
    final absBalance = report.closingBalance.abs();
    final isDebit = report.closingBalance > 0;
    final statusText = isCustomer
        ? (isDebit ? 'عليكم / رصيد' : 'لكم / رصيد')
        : (isDebit ? 'لنا / رصيد' : 'لكم / رصيد علينا');

    final tafqeetText = ArabicTafqeet.convert(absBalance, currencyName: 'ريال يمني');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _calloutBg,
        border: pw.Border.all(color: _calloutBorder, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'المبلغ بالحروف:',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  tafqeetText,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  statusText,
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  '${_formatNum(absBalance)} ر.ي',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. صندوق المصادقة والتوقيعات
  static pw.Widget _buildVerificationAndSignatures({
    required PartyStatementReport report,
    required bool isCustomer,
    String? responsibleUser,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'مصادقة الحساب من ${isCustomer ? "العميل" : "المورد"}: ${report.partyName}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('التوقيع: ..............................................................',
                    style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'المسؤول: ${responsibleUser ?? "إدارة الحسابات"}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text('التوقيع والختم: ......................................................',
                    style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// إرسال ومشاركة ملف PDF مباشرة عبر واتساب أو تطبيقات النظام
  static Future<void> sharePdf({
    required PartyStatementReport report,
    String businessName = 'التاجر الذكي للحلول التجارية',
    String? branchName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    final pdf = await build(
      report: report,
      businessName: businessName,
      branchName: branchName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
    );
    final bytes = await pdf.save();
    final filename = 'كشف_حساب_${report.partyName.replaceAll(' ', '_')}.pdf';

    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
  }

  /// إرسال ملخص نصي أنيق لكشف الحساب مباشرة للواتساب
  static Future<void> shareViaWhatsApp({
    required PartyStatementReport report,
    String? phone,
    String businessName = 'التاجر الذكي للحلول التجارية',
  }) async {
    final absBalance = report.closingBalance.abs();
    final isCustomer = report.partyType == 'Customer';
    final isDebit = report.closingBalance > 0;
    final statusText = isCustomer
        ? (isDebit ? '(عليكم)' : '(لكم)')
        : (isDebit ? '(لنا)' : '(لكم)');

    final buf = StringBuffer();
    buf.writeln('*كشف حساب مالي تحليلي*');
    buf.writeln('🏢 *$businessName*');
    buf.writeln('--------------------------------');
    buf.writeln('👤 *${isCustomer ? "العميل" : "المورد"}:* ${report.partyName}');
    buf.writeln('📅 *تاريخ التقرير:* ${_formatDate(DateTime.now())}');
    buf.writeln('--------------------------------');
    buf.writeln('▫️ *إجمالي المدين:* ${_formatNum(report.totalDebit)} ر.ي');
    buf.writeln('▫️ *إجمالي الدائن:* ${_formatNum(report.totalCredit)} ر.ي');
    buf.writeln('--------------------------------');
    buf.writeln('📌 *صافي الرصيد المستحق:* ${_formatNum(absBalance)} ر.ي $statusText');
    buf.writeln('✍️ *المبلغ بالحروف:* ${ArabicTafqeet.convert(absBalance, currencyName: "ريال يمني")}');
    buf.writeln('--------------------------------');
    buf.writeln('يرجى مراجعة الحساب والمصادقة عليه. شاكرين حسن تعاونكم.');

    final encoded = Uri.encodeComponent(buf.toString());
    final cleanPhone = phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final urlStr = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encoded'
        : 'https://wa.me/?text=$encoded';

    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'تعذر فتح تطبيق واتساب';
    }
  }

  /// طباعة كشف الحساب مباشرة
  static Future<void> printStatement({
    required PartyStatementReport report,
    String businessName = 'التاجر الذكي للحلول التجارية',
    String? branchName,
    String? businessAddress,
    String? businessPhone,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = await build(
          report: report,
          businessName: businessName,
          branchName: branchName,
          businessAddress: businessAddress,
          businessPhone: businessPhone,
        );
        return pdf.save();
      },
      name: 'كشف_حساب_${report.partyName}',
    );
  }
}
