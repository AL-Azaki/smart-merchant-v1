import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../presentation/models/commercial_document_data.dart';
import '../../utils/arabic_tafqeet.dart';

/// منشئ مستندات الفواتير الرسمية والحرارية (طابعات 80mm وورق A4)
/// بتصميم كلاسيكي احترافي عالي الوضوح مخصص للتجار، بدون ضرائب وبدون باركود
class OfficialCommercialDocumentPdfBuilder {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;
  static pw.Font? _cairoSemiBold;

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
    // 1. محاولة القراءة المباشرة من نظام الملفات (لويندوز والاختبارات الأوفلاين)
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

    // 2. محاولة القراءة من rootBundle (لتطبيقات الموبايل المجمعة)
    try {
      if (_cairoRegular == null) {
        final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        _cairoRegular ??= _tryLoadTtf(regularData);
      }
    } catch (_) {}

    try {
      if (_cairoBold == null) {
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        _cairoBold ??= _tryLoadTtf(boldData);
      }
    } catch (_) {}

    try {
      if (_cairoSemiBold == null) {
        final semiBoldData = await rootBundle.load('assets/fonts/Cairo-SemiBold.ttf');
        _cairoSemiBold ??= _tryLoadTtf(semiBoldData);
      }
    } catch (_) {}

    // 3. Fallback احتياطي في حال عدم العثور على الخط محلياً
    try {
      _cairoRegular ??= await PdfGoogleFonts.cairoRegular();
    } catch (_) {}
    try {
      _cairoBold ??= await PdfGoogleFonts.cairoBold();
    } catch (_) {}
    try {
      _cairoSemiBold ??= await PdfGoogleFonts.cairoSemiBold();
    } catch (_) {}

    // 4. أقصى درجات الأمان في الاختبارات الأوفلاين
    _cairoRegular ??= pw.Font.helvetica();
    _cairoBold ??= pw.Font.helveticaBold();
    _cairoSemiBold ??= pw.Font.helveticaBold();
  }

  /// بناء مستند PDF للفاتورة (افتراضياً بمقاس الرول الحراري 80mm أو A4 حسب الاختيار)
  static Future<pw.Document> build(
    CommercialDocumentData docData, {
    PdfPageFormat? pageFormat,
  }) async {
    await _loadFonts();

    final isA4 = pageFormat != null && pageFormat.width > 300;
    final targetFormat = isA4 ? PdfPageFormat.a4 : PdfPageFormat.roll80;

    final margin = isA4
        ? const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24)
        : const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _cairoRegular,
        bold: _cairoBold,
      ),
    );

    if (isA4) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: targetFormat,
          margin: margin,
          textDirection: pw.TextDirection.rtl,
          maxPages: 100,
          build: (pw.Context context) {
            return [
              _buildHeader(docData, isA4: true),
              pw.SizedBox(height: 10),
              _buildMetadataBox(docData, isA4: true),
              pw.SizedBox(height: 10),
              _buildItemsTable(docData, isA4: true),
              pw.SizedBox(height: 10),
              _buildTotalsSection(docData, isA4: true),
              pw.SizedBox(height: 10),
              _buildFooter(docData, isA4: true),
              pw.SizedBox(height: 20),
              _buildA4Signatures(),
            ];
          },
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          pageFormat: targetFormat,
          margin: margin,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _buildHeader(docData, isA4: false),
                pw.SizedBox(height: 6),
                _buildMetadataBox(docData, isA4: false),
                pw.SizedBox(height: 6),
                _buildItemsTable(docData, isA4: false),
                pw.SizedBox(height: 6),
                _buildTotalsSection(docData, isA4: false),
                pw.SizedBox(height: 6),
                _buildFooter(docData, isA4: false),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  // --- 1. ترويسة الفاتورة (مريحة وفسيحة وكلاسيكية) ---
  static pw.Widget _buildHeader(CommercialDocumentData docData, {required bool isA4}) {
    final titleSize = isA4 ? 18.0 : 14.5;
    final subSize = isA4 ? 10.5 : 9.0;
    final badgeSize = isA4 ? 11.0 : 9.5;

    final isReturn = docData.documentType.contains('مرتجع');
    final docTitle = isReturn ? 'مرتجع مبيعات' : 'مبيعات';
    final paymentTitle = docData.paymentMethod ?? (isReturn ? 'استرداد نقدي' : 'نقداً');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // اسم المنشأة / المحل
        pw.Text(
          docData.businessName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: titleSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 2),

        // بيانات الفرع والعنوان والهاتف
        if (docData.branchName != null && docData.branchName!.isNotEmpty) ...[
          pw.Text(
            docData.branchName!,
            style: pw.TextStyle(fontSize: subSize, color: PdfColors.black),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 1),
        ],

        if (docData.businessAddress != null && docData.businessAddress!.isNotEmpty) ...[
          pw.Text(
            docData.businessAddress!,
            style: pw.TextStyle(fontSize: subSize, color: PdfColors.black),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 1),
        ],

        if (docData.businessPhone != null && docData.businessPhone!.isNotEmpty) ...[
          pw.Text(
            'هاتف: ${docData.businessPhone!}',
            style: pw.TextStyle(
              fontSize: subSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
        ],

        // شريط نوع الفاتورة وطريقة الدفع الكلاسيكي المحدد ببرواز أسود
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: isA4 ? 12 : 8,
                  vertical: isA4 ? 3 : 2,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  color: PdfColors.white,
                ),
                child: pw.Text(
                  'فاتورة: $docTitle',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: badgeSize,
                    color: PdfColors.black,
                  ),
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: isA4 ? 12 : 8,
                  vertical: isA4 ? 3 : 2,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  color: PdfColors.white,
                ),
                child: pw.Text(
                  '($paymentTitle)',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: badgeSize,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. تفاصيل الفاتورة والعميل والتواريخ (محاطة بحدود متقطعة) ---
  static pw.Widget _buildMetadataBox(CommercialDocumentData docData, {required bool isA4}) {
    final metaSize = isA4 ? 10.0 : 8.8;
    final currency = _resolveCurrency(docData);
    final isReturn = docData.documentType.contains('مرتجع');

    final dateStr = _formatDate(docData.issueDate);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
        ),
      ),
      child: pw.Column(
        children: [
          // سطر 1: العميل | رقم الفاتورة
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('العميل: ', style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black)),
                  pw.Text(
                    docData.customerOrSupplierName.isNotEmpty
                        ? docData.customerOrSupplierName
                        : 'عميل نقدي',
                    style: pw.TextStyle(
                      fontSize: metaSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    isReturn ? 'رقم المرتجع: ' : 'رقم الفاتورة: ',
                    style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black),
                  ),
                  pw.Text(
                    docData.documentNumber,
                    style: pw.TextStyle(
                      fontSize: metaSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 3),

          // سطر 2: التاريخ | العملة
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('التاريخ: ', style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black)),
                  pw.Text(
                    dateStr,
                    style: pw.TextStyle(
                      fontSize: metaSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('العملة: ', style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black)),
                  pw.Text(
                    currency,
                    style: pw.TextStyle(
                      fontSize: metaSize,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // سطر اختياري: هاتف العميل إن وجد
          if (docData.customerOrSupplierPhone != null && docData.customerOrSupplierPhone!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('هاتف العميل: ', style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black)),
                    pw.Text(
                      docData.customerOrSupplierPhone!,
                      style: pw.TextStyle(
                        fontSize: metaSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      textDirection: pw.TextDirection.ltr,
                    ),
                  ],
                ),
                if (docData.createdBy != null && docData.createdBy!.isNotEmpty)
                  pw.Text(
                    'الكاشير: ${docData.createdBy}',
                    style: pw.TextStyle(fontSize: metaSize, color: PdfColors.black),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 3. جدول الأصناف (حدود سوداء واضحة جداً، بدون ضريبة وبدون باركود) ---
  static pw.Widget _buildItemsTable(CommercialDocumentData docData, {required bool isA4}) {
    final fontSize = isA4 ? 10.0 : 8.8;

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 0.8,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(44), // الصنف
        1: pw.FlexColumnWidth(16), // الكمية
        2: pw.FlexColumnWidth(20), // السعر
        3: pw.FlexColumnWidth(20), // الإجمالي
      },
      children: [
        // ترويسة الجدول
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.white),
          children: [
            _buildCell('الصنف', isHeader: true, align: pw.TextAlign.right, fontSize: fontSize),
            _buildCell('الكمية', isHeader: true, align: pw.TextAlign.center, fontSize: fontSize),
            _buildCell('السعر', isHeader: true, align: pw.TextAlign.center, fontSize: fontSize),
            _buildCell('الإجمالي', isHeader: true, align: pw.TextAlign.left, fontSize: fontSize),
          ],
        ),

        // صفوف الأصناف
        ...docData.items.map((item) {
          final unitSuffix = (item.unitName != null && item.unitName!.isNotEmpty)
              ? ' (${item.unitName})'
              : '';

          return pw.TableRow(
            children: [
              _buildCell(
                '${item.description}$unitSuffix',
                align: pw.TextAlign.right,
                fontSize: fontSize,
                isBold: true,
              ),
              _buildCell(
                _formatQty(item.quantity),
                align: pw.TextAlign.center,
                fontSize: fontSize,
                isBold: true,
              ),
              _buildCell(
                _formatMoney(item.unitPrice),
                align: pw.TextAlign.center,
                fontSize: fontSize,
              ),
              _buildCell(
                _formatMoney(item.lineTotal),
                align: pw.TextAlign.left,
                fontSize: fontSize,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  // --- 4. قسم الإجمالي والمجاميع (ببرواز أسود صريح وتفقيط عربي) ---
  static pw.Widget _buildTotalsSection(CommercialDocumentData docData, {required bool isA4}) {
    final currency = _resolveCurrency(docData);
    final rowSize = isA4 ? 10.5 : 9.0;
    final totalSize = isA4 ? 13.0 : 11.5;
    final isReturn = docData.documentType.contains('مرتجع');

    final totalWord = ArabicTafqeet.convert(docData.grandTotal, currencyName: currency);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
        ),
      ),
      child: pw.Column(
        children: [
          // إجمالي الأصناف والخصم إن وجد خصم
          if (docData.discount > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('إجمالي الأصناف:', style: pw.TextStyle(fontSize: rowSize, color: PdfColors.black)),
                pw.Text(
                  '${_formatMoney(docData.subtotal)} $currency',
                  style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('الخصم:', style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.Text(
                  '( ${_formatMoney(docData.discount)} - ) $currency',
                  style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
          ],

          // الإجمالي الصافي المميز والمحاط ببرواز واضح وجريء
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              color: PdfColors.white,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isReturn ? 'المبلغ المسترد:' : 'المبلغ المستحق:',
                  style: pw.TextStyle(
                    fontSize: totalSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      _formatMoney(docData.grandTotal),
                      style: pw.TextStyle(
                        fontSize: totalSize + 1,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      currency,
                      style: pw.TextStyle(
                        fontSize: rowSize,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // المدفوع والمتبقي إذا كان هناك مبلغ متبقي أو آجل
          if (docData.remainingAmount > 0) ...[
            pw.SizedBox(height: 3),
            if (docData.paidAmount > 0) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المبلغ المدفوع:', style: pw.TextStyle(fontSize: rowSize, color: PdfColors.black)),
                  pw.Text(
                    '${_formatMoney(docData.paidAmount)} $currency',
                    style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('المبلغ المتبقي (آجل):', style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.Text(
                  '${_formatMoney(docData.remainingAmount)} $currency',
                  style: pw.TextStyle(fontSize: rowSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                ),
              ],
            ),
          ],

          // التفقيط باللغة العربية
          pw.SizedBox(height: 4),
          pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '($totalWord)',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: isA4 ? 9.5 : 8.2,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),

          // ملاحظات الفاتورة إن وجدت
          if (docData.notes != null && docData.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.only(top: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 0.5, style: pw.BorderStyle.dashed),
                ),
              ),
              child: pw.Text(
                'ملاحظات: ${docData.notes!.trim()}',
                style: pw.TextStyle(fontSize: rowSize - 0.5, color: PdfColors.black),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 5. تذييل الفاتورة الرسمي الكلاسيكي ---
  static pw.Widget _buildFooter(CommercialDocumentData docData, {required bool isA4}) {
    final isReturn = docData.documentType.contains('مرتجع');
    final footerTitle = isReturn
        ? 'سند إرجاع بضاعة رسمي ومقيد بالحساب'
        : 'شكراً لتعاملكم معنا';
    final policyText = docData.terms ??
        (isReturn
            ? 'تم استلام البضاعة وإعادتها للمخزن وتحديث الحساب المالي'
            : 'البضاعة المباعة لا تُرد ولا تُستبدل إلا بموجب أصل الفاتورة');

    final cashierName = docData.createdBy ?? 'مستخدم النظام';
    final printTime = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          footerTitle,
          style: pw.TextStyle(
            fontSize: isA4 ? 11.0 : 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          policyText,
          style: pw.TextStyle(
            fontSize: isA4 ? 9.5 : 8.0,
            color: PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 0.6, style: pw.BorderStyle.dashed),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المحاسب: $cashierName',
                style: pw.TextStyle(
                  fontSize: isA4 ? 9.5 : 8.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              pw.Text(
                printTime,
                style: pw.TextStyle(
                  fontSize: isA4 ? 9.5 : 8.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- تذييل التوقيعات لأوراق A4 فقط ---
  static pw.Widget _buildA4Signatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSignatureLine('ختم المؤسسة / المحل'),
        _buildSignatureLine('توقيع المستلم / العميل'),
        _buildSignatureLine('توقيع البائع / المحاسب'),
      ],
    );
  }

  static pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Container(
          width: 120,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
          ),
        ),
      ],
    );
  }

  // --- أدوات مساعدة ---
  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.right,
    double fontSize = 8.8,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
      alignment: align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : align == pw.TextAlign.left
              ? pw.Alignment.centerLeft
              : pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static String _formatMoney(double val) {
    if (val == val.roundToDouble()) {
      return NumberFormat('#,##0', 'en_US').format(val);
    }
    return NumberFormat('#,##0.00', 'en_US').format(val);
  }

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }

  static String _formatDate(DateTime date) {
    final ymd = DateFormat('yyyy-MM-dd').format(date);
    final time = DateFormat('hh:mm a').format(date)
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م');
    return '$ymd ($time)';
  }

  static String _resolveCurrency(CommercialDocumentData docData) {
    if (docData.currencySymbol != null &&
        docData.currencySymbol!.isNotEmpty &&
        docData.currencySymbol != 'YER') {
      return docData.currencySymbol!;
    }
    if (docData.currencyCode == 'SAR' || docData.currencySymbol == 'SAR') {
      return 'ريال سعودي';
    }
    if (docData.currencyCode == 'USD' || docData.currencySymbol == '\$') {
      return 'دولار';
    }
    return 'ريال يمني';
  }
}
