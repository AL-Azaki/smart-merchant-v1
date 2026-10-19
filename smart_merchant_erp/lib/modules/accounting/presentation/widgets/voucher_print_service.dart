import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/utils/arabic_tafqeet.dart';

class VoucherPrintService {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;
  static pw.Font? _cairoSemiBold;

  static bool _isValidTtf(ByteData data) {
    if (data.lengthInBytes < 4) {
      return false;
    }
    final magic = data.getUint32(0);
    return magic == 0x00010000 || magic == 0x4F54544F;
  }

  static pw.Font? _tryLoadTtf(ByteData data) {
    try {
      if (!_isValidTtf(data)) {
        return null;
      }
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

    // 2. محاولة القراءة من rootBundle (لتطبيقات الموبايل المجمعة أندرويد/iOS)
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

    // 3. Fallback احتياطي عبر الإنترنت عند الحاجة
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

  /// طباعة سند قبض أو صرف عبر نافذة الطباعة الرسمية للنظام
  static Future<void> printVoucher({
    required BuildContext context,
    required Payment voucher,
  }) async {
    final pdf = await _generateVoucherPdf(voucher: voucher);

    final isReceipt = voucher.paymentType.toLowerCase() == 'receipt';
    final docTitle = isReceipt ? 'سند_قبض_${voucher.paymentNumber}' : 'سند_صرف_${voucher.paymentNumber}';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: docTitle,
    );
  }

  /// مشاركة ملف PDF للسند عبر التطبيقات ومواقع التواصل
  static Future<void> shareVoucher({
    required BuildContext context,
    required Payment voucher,
  }) async {
    final pdf = await _generateVoucherPdf(voucher: voucher);
    final bytes = await pdf.save();
    final isReceipt = voucher.paymentType.toLowerCase() == 'receipt';
    final docTitle = isReceipt ? 'سند_قبض_${voucher.paymentNumber}.pdf' : 'سند_صرف_${voucher.paymentNumber}.pdf';

    await Printing.sharePdf(
      bytes: bytes,
      filename: docTitle,
    );
  }

  /// مشاركة نصية سريعة للسند عبر واتساب
  static Future<void> shareSummaryText({
    required Payment voucher,
    String companyName = 'التاجر الذكي',
  }) async {
    final isReceipt = voucher.paymentType.toLowerCase() == 'receipt';
    final typeName = isReceipt ? 'سند قبض مالي' : 'سند صرف مالي';
    final dateStr = DateFormat('yyyy/MM/dd').format(voucher.paymentDate);
    final currency = voucher.currencyId == 'YER' ? 'ريال يمني' : voucher.currencyId;
    final tafqeet = ArabicTafqeet.convert(voucher.amount, currencyName: currency);

    final text = '''🧾 *$typeName*
━━━━━━━━━━━━━━━━━━━━
📌 رقم السند: ${voucher.paymentNumber}
📅 التاريخ: $dateStr
🏪 المؤسسة: $companyName
💰 المبلغ: ${NumberFormat('#,##0.00').format(voucher.amount)} $currency
🔤 فقط: $tafqeet
👤 الطرف / المستفيد: ${voucher.contactType ?? 'عميل / مورد'}
📝 البيان: ${voucher.notes ?? 'سند مالي مرحل'}
✅ الحالة: ${voucher.status == 'Posted' ? 'مرحل ومعتمد' : voucher.status}
━━━━━━━━━━━━━━━━━━━━
_نظام التاجر الذكي - Smart Merchant ERP_''';

    await SharePlus.instance.share(ShareParams(text: text, subject: '$typeName ${voucher.paymentNumber}'));
  }

  /// بناء مستند PDF مطابق لهيدر فاتورة المبيعات ونموذج السند المطلوب وبدون أي تكرار
  static Future<pw.Document> _generateVoucherPdf({
    required Payment voucher,
  }) async {
    await _loadFonts();

    final isReceipt = voucher.paymentType.toLowerCase() == 'receipt';
    final docTypeTitle = isReceipt ? 'سند قبض' : 'سند صرف';
    final primaryColor = isReceipt ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#1E3A8A');
    final badgeBgColor = isReceipt ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#EFF6FF');

    final db = getIt<AppDatabase>();

    String businessName = 'التاجر الذكي للأنظمة والحلول';
    String? branchName;
    String? businessPhone;
    String? businessAddress;
    String accountName = isReceipt ? 'الخزينة النقدية الرئيسية' : 'الحساب البنكي الرئيسي';
    String paymentMethodTitle = 'نقداً';
    String contactName = '';
    String accountantName = isReceipt ? 'أمين الصندوق' : 'المحاسب المسؤول';

    // جلب البيانات الحقيقية من قاعدة البيانات عبر Drift
    try {
      // 1. بيانات المنشأة الحقيقية
      var bus = await (db.select(db.businesses)..where((b) => b.id.equals(voucher.businessId))).getSingleOrNull();
      bus ??= await (db.select(db.businesses)..limit(1)).getSingleOrNull();
      if (bus != null) {
        businessName = bus.businessName;
        businessPhone = bus.primaryPhone;
      }

      // 2. بيانات الفرع الحقيقية
      if (voucher.branchId.isNotEmpty) {
        final br = await (db.select(db.branches)..where((b) => b.id.equals(voucher.branchId))).getSingleOrNull();
        if (br != null) {
          branchName = br.branchName;
          if (br.phone != null && br.phone!.isNotEmpty) {
            businessPhone = br.phone;
          }
          if (br.address != null && br.address!.isNotEmpty) {
            businessAddress = br.address;
          }
        }
      }
      if (branchName == null) {
        final anyBr = await (db.select(db.branches)..limit(1)).getSingleOrNull();
        if (anyBr != null) {
          branchName = anyBr.branchName;
          if (anyBr.phone != null && anyBr.phone!.isNotEmpty) {
            businessPhone = anyBr.phone;
          }
          if (anyBr.address != null && anyBr.address!.isNotEmpty) {
            businessAddress = anyBr.address;
          }
        }
      }

      // 3. طريقة الدفع الفعلية
      if (voucher.paymentMethodId.isNotEmpty) {
        final pm = await (db.select(db.paymentMethods)..where((m) => m.id.equals(voucher.paymentMethodId))).getSingleOrNull();
        if (pm != null) {
          paymentMethodTitle = pm.methodName;
        } else {
          final byCode = await (db.select(db.paymentMethods)..where((m) => m.methodCode.equals(voucher.paymentMethodId))).getSingleOrNull();
          if (byCode != null) {
            paymentMethodTitle = byCode.methodName;
          } else {
            final upper = voucher.paymentMethodId.toUpperCase();
            if (upper == 'CASH') {
              paymentMethodTitle = 'نقداً';
            } else if (upper == 'CARD') {
              paymentMethodTitle = 'شبكة / بطاقة';
            } else if (upper.contains('BANK')) {
              paymentMethodTitle = 'تحويل بنكي';
            } else {
              paymentMethodTitle = voucher.paymentMethodId;
            }
          }
        }
      }

      // 4. الحساب البنكي / الصندوق الفعلي
      if (voucher.chartOfAccountId.isNotEmpty) {
        final coa = await (db.select(db.chartOfAccounts)..where((c) => c.id.equals(voucher.chartOfAccountId))).getSingleOrNull();
        if (coa != null) {
          accountName = coa.accountName;
        }
      }

      // 5. الطرف الفعلي (عميل أو مورد)
      if (voucher.contactId != null && voucher.contactId!.isNotEmpty) {
        if (voucher.contactType == 'Customer') {
          final c = await (db.select(db.customers)..where((t) => t.id.equals(voucher.contactId!))).getSingleOrNull();
          if (c != null) {
            contactName = c.customerName;
          }
        } else if (voucher.contactType == 'Supplier') {
          final s = await (db.select(db.suppliers)..where((t) => t.id.equals(voucher.contactId!))).getSingleOrNull();
          if (s != null) {
            contactName = s.supplierName;
          }
        }
      }

      // 6. إذا لم يكن عميل/مورد (مثل المصاريف والإيرادات)، نجلب الحساب المقابل من قيد اليومية
      if (contactName.isEmpty) {
        final je = await (db.select(db.journalEntries)..where((j) => j.documentId.equals(voucher.id))).getSingleOrNull();
        if (je != null) {
          final lines = await (db.select(db.journalEntryLines)..where((l) => l.journalEntryId.equals(je.id))).get();
          final opposing = lines.where((l) => isReceipt ? l.type == 'Credit' : l.type == 'Debit').firstOrNull;
          if (opposing != null) {
            final oppAcc = await (db.select(db.chartOfAccounts)..where((c) => c.id.equals(opposing.chartOfAccountId))).getSingleOrNull();
            if (oppAcc != null) {
              contactName = oppAcc.accountName;
            }
          }
        }
      }

      if (contactName.isEmpty) {
        contactName = isReceipt ? 'عميل نقدي' : 'مصروفات تشغيلية عامة';
      }

      // 7. اسم المحاسب الحقيقي
      if (voucher.createdBy.isNotEmpty) {
        final u = await (db.select(db.usersTable)..where((user) => user.id.equals(voucher.createdBy))).getSingleOrNull();
        if (u != null) {
          final fullName = '${u.firstName} ${u.lastName}'.trim();
          if (fullName.isNotEmpty) {
            accountantName = fullName;
          }
        }
      }
    } catch (_) {}

    final dateStr = DateFormat('yyyy/MM/dd').format(voucher.paymentDate);
    final currency = voucher.currencyId == 'YER' ? 'ريال يمني' : voucher.currencyId;
    final formattedAmount = NumberFormat('#,##0.00').format(voucher.amount);
    final tafqeet = ArabicTafqeet.convert(voucher.amount, currencyName: currency);

    // استخراج رقم المرجع إذا كان مدوناً في الملاحظات أو استخدام رقم السند
    String referenceNumber = voucher.paymentNumber;
    if (voucher.notes != null && voucher.notes!.contains('INV-')) {
      final reg = RegExp(r'INV-\d+');
      final match = reg.firstMatch(voucher.notes!);
      if (match != null) {
        referenceNumber = match.group(0)!;
      }
    }

    // إعداد مستند الـ PDF بالثيم والخط الموحد
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: _cairoRegular,
        bold: _cairoBold,
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ─── 1. ترويسة المنشأة الرسمية (مطابقة تماماً لفاتورة المبيعات وبدون أي تكرار) ───
              pw.Column(
                children: [
                  pw.Text(
                    businessName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 18.0,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if (branchName != null && branchName.isNotEmpty) ...[
                    pw.Text(
                      branchName,
                      style: const pw.TextStyle(fontSize: 10.5),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (businessAddress != null && businessAddress.isNotEmpty) ...[
                    pw.Text(
                      businessAddress,
                      style: const pw.TextStyle(fontSize: 10.5),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (businessPhone != null && businessPhone.isNotEmpty) ...[
                    pw.Text(
                      'هاتف: $businessPhone',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                  ],

                  // شريط نوع السند المعتمد والوحيد (كلمة واحدة واضحة وبدون تكرار سند:)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 2, bottom: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: primaryColor, width: 1.2),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            color: badgeBgColor,
                          ),
                          child: pw.Text(
                            docTypeTitle, // "سند صرف" أو "سند قبض" - كلمة واحدة واضحة بدون تكرار!
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border.fromBorderSide(pw.BorderSide()),
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            color: PdfColors.white,
                          ),
                          child: pw.Text(
                            '($paymentMethodTitle)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10.5,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ─── 2. صندوق بيانات السند الرئيسي (مع تمييز سند القبض عن سند الصرف وبدون تكرار العنوان) ───
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1.2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // الجهة اليمنى: رقم السند والتاريخ والمرجع
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text(
                              isReceipt ? 'رقم سند القبض: ' : 'رقم سند الصرف: ',
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              voucher.paymentNumber,
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Text(
                              isReceipt ? 'تاريخ القبض: ' : 'تاريخ الصرف: ',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Text('رقم المرجع: ', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(referenceNumber, style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),

                    // الوسط: ختم الحالة والاعتماد (بدون تكرار لعنوان السند نهائياً)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: primaryColor, width: 0.9),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: badgeBgColor,
                      ),
                      child: pw.Text(
                        isReceipt ? 'معتمد ومقبوض ✓' : 'معتمد ومصروف ✓',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),

                    // الجهة اليسرى: المبلغ الإجمالي واسم الحساب
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              '$formattedAmount $currency',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              isReceipt ? 'المبلغ المقبوض: ' : 'المبلغ المصروف: ',
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          isReceipt ? 'إيداع في حساب: $accountName' : 'سحب من حساب: $accountName',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ─── 3. صندوق نصوص التفقيط والبيان الرسمي ───
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // سطر 1: اسم المستلم / المستفيد
                    pw.Row(
                      children: [
                        pw.Text(
                          isReceipt ? 'استلمنا من الأخ / السادة: ' : 'صرفنا إلى الأخ / السادة: ',
                          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            contactName,
                            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),

                    // سطر 2: مبلغ وقدره بالأرقام والتفقيط بالعربي
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'مبلغ وقدره: ',
                          style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            '$formattedAmount $currency ($tafqeet)',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),

                    // سطر 3: الحساب المالي المرتبط
                    pw.Row(
                      children: [
                        pw.Text(
                          isReceipt ? 'وذلك إيداع في حساب: ' : 'وذلك سحب من حساب: ',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          accountName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),

                    // ─── 4. جدول البنود والبيان الرسمي ───
                    pw.Table(
                      border: pw.TableBorder.all(width: 0.8),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(28), // م
                        1: pw.FixedColumnWidth(140), // اسم الحساب
                        2: pw.FlexColumnWidth(2.5), // البيان
                        3: pw.FixedColumnWidth(80), // المبلغ
                        4: pw.FixedColumnWidth(65), // العملة
                      },
                      children: [
                        // رأس الجدول
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4),
                              child: pw.Text('م', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: pw.Text(
                                isReceipt ? 'حساب المقبوض منه' : 'حساب المصروف له',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: pw.Text('البيان', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4),
                              child: pw.Text('المبلغ', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4),
                              child: pw.Text('العملة', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                        // صف البيانات الفعلي للسند
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6),
                              child: pw.Text('1', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9.5)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: pw.Text(contactName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                              child: pw.Text(
                                voucher.notes?.isNotEmpty == true
                                    ? voucher.notes!
                                    : (isReceipt ? 'سند قبض نقدية' : 'سند صرف مصروفات'),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6),
                              child: pw.Text(formattedAmount, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 6),
                              child: pw.Text(currency, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),

                    // ─── 5. التوقيعات الرسمية ───
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          isReceipt ? 'أمين الصندوق: $accountantName' : 'المحاسب: $accountantName',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                        if (!isReceipt)
                          pw.Text(
                            'المصرح بالصرف: ..............................',
                            style: const pw.TextStyle(fontSize: 9.5),
                          ),
                        pw.Text(
                          isReceipt
                              ? 'توقيع المسلّم: ..............................'
                              : 'توقيع المستلم: ..............................',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
