import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../application/services/balance_sheet_service.dart';
import '../../application/services/cash_flow_service.dart';
import '../../application/services/trial_balance_service.dart';

/// Professional Arabic PDF Print and Share Service for all Financial Reports.
class FinancialReportPdfService {
  static final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  static final _dateFormat = DateFormat('yyyy/MM/dd', 'en_US');

  static pw.Font? _arabicRegular;
  static pw.Font? _arabicBold;

  static Future<void> _loadFonts() async {
    _arabicRegular ??= await PdfGoogleFonts.cairoRegular();
    _arabicBold ??= await PdfGoogleFonts.cairoBold();
  }

  static pw.TextStyle _ts({
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.TextStyle(
        font: bold ? _arabicBold : _arabicRegular,
        fontSize: size,
        color: color ?? PdfColor.fromHex('#1E293B'),
      );

  // --------------------------------------------------------------------------
  // BUSINESS DATA FETCHER
  // --------------------------------------------------------------------------
  static Future<({String name, String? phone, String? address, String currency})>
      _getBusinessInfo() async {
    final db = getIt<AppDatabase>();
    String name = 'التاجر الذكي للأنظمة المحاسبية';
    String? phone;
    String? address;
    String currency = 'ريال يمني (YER)';

    try {
      final bus = await (db.select(db.businesses)..limit(1)).getSingleOrNull();
      if (bus != null) {
        name = bus.businessName;
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

    return (name: name, phone: phone, address: address, currency: currency);
  }

  // --------------------------------------------------------------------------
  // 1. TRIAL BALANCE PRINT & SHARE (ميزان المراجعة)
  // --------------------------------------------------------------------------
  static Future<void> printTrialBalance({
    required BuildContext context,
    required TrialBalanceReport report,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _generateTrialBalancePdf(
      report: report,
      startDate: startDate,
      endDate: endDate,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ميزان_المراجعة_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static Future<void> shareTrialBalance({
    required BuildContext context,
    required TrialBalanceReport report,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = await _generateTrialBalancePdf(
      report: report,
      startDate: startDate,
      endDate: endDate,
    );
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'ميزان_المراجعة_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<pw.Document> _generateTrialBalancePdf({
    required TrialBalanceReport report,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();
    final info = await _getBusinessInfo();
    final pdf = pw.Document();

    final dateRangeStr =
        'الفترة: من ${startDate != null ? _dateFormat.format(startDate) : "بداية النشاط"} إلى ${endDate != null ? _dateFormat.format(endDate) : "تاريخ اليوم"}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildReportHeader(
          businessName: info.name,
          phone: info.phone,
          address: info.address,
          reportTitle: 'ميزان المراجعة بالأرصدة والمجاميع',
          subTitle: dateRangeStr,
          currency: info.currency,
          pageNumber: ctx.pageNumber,
          totalPages: ctx.pagesCount,
        ),
        footer: (ctx) => _buildReportFooter(ctx.pageNumber, ctx.pagesCount),
        build: (ctx) => [
          // Balance Badge Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: report.isBalanced ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#FEF2F2'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: report.isBalanced ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#EF4444'),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  report.isBalanced
                      ? '✓ الميزان متزن محاسبياً بنسبة 100% (إجمالي المدين = إجمالي الدائن)'
                      : '⚠ تنبيه: يوجد عدم اتزان بقيمة: ${_moneyFormat.format((report.grandTotalDebit - report.grandTotalCredit).abs())}',
                  style: _ts(
                    size: 9.5,
                    bold: true,
                    color: report.isBalanced ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#B91C1C'),
                  ),
                ),
                pw.Text(
                  'عدد الحسابات النشطة: ${report.items.length}',
                  style: _ts(size: 9, bold: true, color: PdfColor.fromHex('#475569')),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Items Table
          pw.TableHelper.fromTextArray(
            headers: ['كود الحساب', 'اسم الحساب المالي', 'مجموع المدين', 'مجموع الدائن', 'رصيد مدين', 'رصيد دائن'],
            headerStyle: _ts(size: 8.5, bold: true, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
            cellStyle: _ts(size: 8),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            data: [
              ...report.items.map((item) => [
                    item.accountCode,
                    item.accountName,
                    _moneyFormat.format(item.totalDebit),
                    _moneyFormat.format(item.totalCredit),
                    item.netDebit > 0 ? _moneyFormat.format(item.netDebit) : '-',
                    item.netCredit > 0 ? _moneyFormat.format(item.netCredit) : '-',
                  ]),
              // Grand Totals Row
              [
                'المجموع الكلي',
                '---',
                _moneyFormat.format(report.grandTotalDebit),
                _moneyFormat.format(report.grandTotalCredit),
                _moneyFormat.format(report.grandNetDebit),
                _moneyFormat.format(report.grandNetCredit),
              ],
            ],
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
            ),
          ),
          pw.SizedBox(height: 18),

          // Signatures Section
          _buildSignaturesBlock(),
        ],
      ),
    );

    return pdf;
  }

  // --------------------------------------------------------------------------
  // 2. BALANCE SHEET PRINT & SHARE (الميزانية العمومية)
  // --------------------------------------------------------------------------
  static Future<void> printBalanceSheet({
    required BuildContext context,
    required BalanceSheetReport report,
  }) async {
    final pdf = await _generateBalanceSheetPdf(report: report);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'الميزانية_العمومية_${DateFormat('yyyyMMdd').format(report.asOfDate)}',
    );
  }

  static Future<void> shareBalanceSheet({
    required BuildContext context,
    required BalanceSheetReport report,
  }) async {
    final pdf = await _generateBalanceSheetPdf(report: report);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'الميزانية_العمومية_${DateFormat('yyyyMMdd').format(report.asOfDate)}.pdf',
    );
  }

  static Future<pw.Document> _generateBalanceSheetPdf({
    required BalanceSheetReport report,
  }) async {
    await _loadFonts();
    final info = await _getBusinessInfo();
    final pdf = pw.Document();

    final dateStr = 'كما في تاريخ: ${_dateFormat.format(report.asOfDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildReportHeader(
          businessName: info.name,
          phone: info.phone,
          address: info.address,
          reportTitle: 'الميزانية العمومية (المركز المالي)',
          subTitle: dateStr,
          currency: info.currency,
          pageNumber: ctx.pageNumber,
          totalPages: ctx.pagesCount,
        ),
        footer: (ctx) => _buildReportFooter(ctx.pageNumber, ctx.pagesCount),
        build: (ctx) => [
          // Balanced Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: report.isBalanced ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#FEF2F2'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: report.isBalanced ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#EF4444'),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  report.isBalanced
                      ? '✓ الميزانية متوازنة بدقة: إجمالي الأصول = إجمالي الخصوم وحقوق الملكية'
                      : '⚠ تنبيه: فارق التوازن = ${_moneyFormat.format((report.totalAssets - report.totalLiabilitiesAndEquity).abs())}',
                  style: _ts(
                    size: 9.5,
                    bold: true,
                    color: report.isBalanced ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#B91C1C'),
                  ),
                ),
                pw.Text(
                  'صافي أرباح الفترة: ${_moneyFormat.format(report.currentPeriodNetProfit)}',
                  style: _ts(size: 9, bold: true, color: PdfColor.fromHex('#1E3A8A')),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Two-column or Sequential sections: 1. Assets, 2. Liabilities & Equity
          _buildBalanceSectionHeader('أولاً: الأصول والموجودات (Assets)', PdfColor.fromHex('#1E3A8A')),
          _buildBalanceSubHeader('الأصول المتداولة (Current Assets)', report.totalCurrentAssets),
          _buildBalanceTable(report.currentAssets),
          pw.SizedBox(height: 6),

          if (report.nonCurrentAssets.isNotEmpty) ...[
            _buildBalanceSubHeader('الأصول الثابتة وغير المتداولة (Non-Current Assets)', report.totalNonCurrentAssets),
            _buildBalanceTable(report.nonCurrentAssets),
            pw.SizedBox(height: 6),
          ],

          _buildTotalHighlightRow('إجمالي الأصول (Total Assets)', report.totalAssets, PdfColor.fromHex('#1E3A8A')),
          pw.SizedBox(height: 16),

          _buildBalanceSectionHeader('ثانياً: الخصوم والالتزامات (Liabilities)', PdfColor.fromHex('#B45309')),
          _buildBalanceSubHeader('الخصوم المتداولة (Current Liabilities)', report.totalCurrentLiabilities),
          _buildBalanceTable(report.currentLiabilities),
          pw.SizedBox(height: 6),

          if (report.nonCurrentLiabilities.isNotEmpty) ...[
            _buildBalanceSubHeader('الخصوم غير المتداولة (Non-Current Liabilities)', report.totalNonCurrentLiabilities),
            _buildBalanceTable(report.nonCurrentLiabilities),
            pw.SizedBox(height: 6),
          ],

          _buildTotalHighlightRow('إجمالي الخصوم والالتزامات', report.totalLiabilities, PdfColor.fromHex('#B45309')),
          pw.SizedBox(height: 14),

          _buildBalanceSectionHeader('ثالثاً: حقوق الملكية (Owner\'s Equity)', PdfColor.fromHex('#047857')),
          _buildBalanceTable(report.equityItems),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: PdfColor.fromHex('#F8FAFC'),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('صافي أرباح / (خسائر) الفترة الحالية (من قائمة الدخل)', style: _ts(size: 8.5, bold: true)),
                pw.Text(_moneyFormat.format(report.currentPeriodNetProfit), style: _ts(size: 8.5, bold: true, color: report.currentPeriodNetProfit >= 0 ? PdfColor.fromHex('#047857') : PdfColor.fromHex('#DC2626'))),
              ],
            ),
          ),
          _buildTotalHighlightRow('إجمالي حقوق الملكية', report.totalEquity, PdfColor.fromHex('#047857')),
          pw.SizedBox(height: 10),

          _buildTotalHighlightRow('إجمالي الخصوم وحقوق الملكية', report.totalLiabilitiesAndEquity, PdfColor.fromHex('#0F172A')),
          pw.SizedBox(height: 20),

          // Signatures
          _buildSignaturesBlock(),
        ],
      ),
    );

    return pdf;
  }

  // --------------------------------------------------------------------------
  // 3. CASH FLOW STATEMENT PRINT & SHARE (قائمة التدفق المالي)
  // --------------------------------------------------------------------------
  static Future<void> printCashFlow({
    required BuildContext context,
    required CashFlowReport report,
  }) async {
    final pdf = await _generateCashFlowPdf(report: report);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'قائمة_التدفق_النقدي_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  static Future<void> shareCashFlow({
    required BuildContext context,
    required CashFlowReport report,
  }) async {
    final pdf = await _generateCashFlowPdf(report: report);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'قائمة_التدفق_النقدي_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<pw.Document> _generateCashFlowPdf({
    required CashFlowReport report,
  }) async {
    await _loadFonts();
    final info = await _getBusinessInfo();
    final pdf = pw.Document();

    final dateRangeStr =
        'الفترة: من ${report.startDate != null ? _dateFormat.format(report.startDate!) : "بداية النشاط"} إلى ${report.endDate != null ? _dateFormat.format(report.endDate!) : "تاريخ اليوم"}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => _buildReportHeader(
          businessName: info.name,
          phone: info.phone,
          address: info.address,
          reportTitle: 'قائمة التدفقات النقدية والمالية (Cash Flow)',
          subTitle: dateRangeStr,
          currency: info.currency,
          pageNumber: ctx.pageNumber,
          totalPages: ctx.pagesCount,
        ),
        footer: (ctx) => _buildReportFooter(ctx.pageNumber, ctx.pagesCount),
        build: (ctx) => [
          // Cash Flow KPI Cards
          pw.Row(
            children: [
              _buildKpiPdfBox('رصيد النقدية أول المدة', report.openingCashBalance, PdfColor.fromHex('#3B82F6')),
              pw.SizedBox(width: 8),
              _buildKpiPdfBox('صافي التدفق التشغيلي', report.netOperatingCashFlow, report.netOperatingCashFlow >= 0 ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#EF4444')),
              pw.SizedBox(width: 8),
              _buildKpiPdfBox('صافي التدفق الاستثماري', report.netInvestingCashFlow, PdfColor.fromHex('#8B5CF6')),
              pw.SizedBox(width: 8),
              _buildKpiPdfBox('رصيد النقدية آخر المدة', report.closingCashBalance, PdfColor.fromHex('#047857'), isHighlight: true),
            ],
          ),
          pw.SizedBox(height: 16),

          // 1. Operating Activities
          _buildBalanceSectionHeader('أولاً: التدفقات النقدية من الأنشطة التشغيلية (Operating Activities)', PdfColor.fromHex('#1E3A8A')),
          _buildActivitiesTable(report.operatingActivities),
          _buildTotalHighlightRow('صافي التدفقات النقدية من الأنشطة التشغيلية', report.netOperatingCashFlow, PdfColor.fromHex('#1E3A8A')),
          pw.SizedBox(height: 12),

          // 2. Investing Activities
          _buildBalanceSectionHeader('ثانياً: التدفقات النقدية من الأنشطة الاستثمارية (Investing Activities)', PdfColor.fromHex('#8B5CF6')),
          _buildActivitiesTable(report.investingActivities),
          _buildTotalHighlightRow('صافي التدفقات النقدية من الأنشطة الاستثمارية', report.netInvestingCashFlow, PdfColor.fromHex('#8B5CF6')),
          pw.SizedBox(height: 12),

          // 3. Financing Activities
          _buildBalanceSectionHeader('ثالثاً: التدفقات النقدية من الأنشطة التمويلية (Financing Activities)', PdfColor.fromHex('#B45309')),
          _buildActivitiesTable(report.financingActivities),
          _buildTotalHighlightRow('صافي التدفقات النقدية من الأنشطة التمويلية', report.netFinancingCashFlow, PdfColor.fromHex('#B45309')),
          pw.SizedBox(height: 14),

          // Cash Summary Block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1F5F9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            ),
            child: pw.Column(
              children: [
                _buildSummaryLine('صافي التغير في النقدية خلال الفترة', report.netChangeInCash, bold: true),
                pw.Divider(color: PdfColor.fromHex('#CBD5E1'), height: 10),
                _buildSummaryLine('رصيد النقدية وما في حكمها في بداية الفترة', report.openingCashBalance),
                pw.Divider(color: PdfColor.fromHex('#CBD5E1'), height: 10),
                _buildSummaryLine('رصيد النقدية وما في حكمها في نهاية الفترة', report.closingCashBalance, bold: true, color: PdfColor.fromHex('#047857')),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // 4. Accounts Breakdown Table
          _buildBalanceSectionHeader('تفاصيل أرصدة الصناديق والبنوك والمحافظ', PdfColor.fromHex('#0F172A')),
          pw.TableHelper.fromTextArray(
            headers: ['كود الحساب', 'اسم الصندوق / البنك', 'التصنيف', 'رصيد أول المدة', 'إجمالي المقبوضات', 'إجمالي المدفوعات', 'رصيد آخر المدة'],
            headerStyle: _ts(size: 8, bold: true, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#334155')),
            cellStyle: _ts(size: 8),
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            data: report.cashAccounts
                .map((a) => [
                      a.accountCode,
                      a.accountName,
                      a.category,
                      _moneyFormat.format(a.openingBalance),
                      _moneyFormat.format(a.totalInflow),
                      _moneyFormat.format(a.totalOutflow),
                      _moneyFormat.format(a.closingBalance),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 18),

          // Signatures
          _buildSignaturesBlock(),
        ],
      ),
    );

    return pdf;
  }

  // --------------------------------------------------------------------------
  // HELPER PDF WIDGETS
  // --------------------------------------------------------------------------
  static pw.Widget _buildReportHeader({
    required String businessName,
    required String reportTitle,
    required String subTitle,
    required String currency,
    required int pageNumber,
    required int totalPages,
    String? phone,
    String? address,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1E3A8A'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(businessName, style: _ts(size: 14, bold: true, color: PdfColors.white)),
              if (phone != null) pw.Text('هاتف: $phone', style: _ts(size: 8.5, color: PdfColors.grey200)),
              if (address != null) pw.Text('العنوان: $address', style: _ts(size: 8.5, color: PdfColors.grey200)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(reportTitle, style: _ts(size: 15, bold: true, color: PdfColors.white)),
              pw.Text(subTitle, style: _ts(size: 8.5, color: PdfColor.fromHex('#93C5FD'))),
              pw.Text('العملة: $currency', style: _ts(size: 8, color: PdfColors.grey200)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportFooter(int pageNumber, int totalPages) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('نظام التاجر الذكي - Smart Merchant ERP', style: _ts(size: 8, color: PdfColors.grey600)),
          pw.Text('تاريخ الطباعة: ${_dateFormat.format(DateTime.now())}', style: _ts(size: 8, color: PdfColors.grey600)),
          pw.Text('صفحة $pageNumber من $totalPages', style: _ts(size: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildSignaturesBlock() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSignatureColumn('إعداد: المحاسب المالي'),
          _buildSignatureColumn('مراجعة: المدير المالي'),
          _buildSignatureColumn('اعتماد: الإدارة العامة'),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureColumn(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: _ts(size: 8.5, bold: true)),
        pw.SizedBox(height: 22),
        pw.Container(width: 110, height: 1, color: PdfColor.fromHex('#94A3B8')),
      ],
    );
  }

  static pw.Widget _buildBalanceSectionHeader(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
      child: pw.Text(title, style: _ts(size: 9.5, bold: true, color: PdfColors.white)),
    );
  }

  static pw.Widget _buildBalanceSubHeader(String title, double total) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4, bottom: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: PdfColor.fromHex('#F1F5F9'),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: _ts(size: 8.5, bold: true, color: PdfColor.fromHex('#334155'))),
          pw.Text(_moneyFormat.format(total), style: _ts(size: 8.5, bold: true, color: PdfColor.fromHex('#334155'))),
        ],
      ),
    );
  }

  static pw.Widget _buildBalanceTable(List<BalanceSheetItem> items) {
    if (items.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Text('لا توجد أرصدة مرحلة في هذا القسم', style: _ts(size: 7.5, color: PdfColors.grey500)),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: ['كود الحساب', 'اسم الحساب المالي', 'التصنيف', 'الرصيد الصافي'],
      headerStyle: _ts(size: 7.5, bold: true, color: PdfColor.fromHex('#475569')),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
      cellStyle: _ts(size: 7.5),
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.centerRight,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      data: items
          .map((i) => [
                i.accountCode,
                i.accountName,
                i.accountCategory ?? '---',
                _moneyFormat.format(i.balance),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildActivitiesTable(List<CashFlowActivityItem> activities) {
    if (activities.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Text('لا توجد تدفقات نقدية مسجلة في هذا النشاط خلال الفترة', style: _ts(size: 7.5, color: PdfColors.grey500)),
      );
    }
    return pw.TableHelper.fromTextArray(
      headers: ['بيان الحركة النقدية', 'طبيعة التدفق', 'المبلغ'],
      headerStyle: _ts(size: 7.5, bold: true, color: PdfColor.fromHex('#475569')),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
      cellStyle: _ts(size: 7.5),
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.centerRight,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      data: activities
          .map((a) => [
                a.title,
                a.isInflow ? 'تدفق وارد (+)' : 'تدفق صادر (-)',
                (a.isInflow ? '+ ' : '- ') + _moneyFormat.format(a.amount),
              ])
          .toList(),
    );
  }

  static pw.Widget _buildTotalHighlightRow(String label, double value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color.luminance > 0.5 ? color : color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _ts(size: 9, bold: true, color: PdfColors.white)),
          pw.Text(_moneyFormat.format(value), style: _ts(size: 9, bold: true, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryLine(String title, double amount, {bool bold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(title, style: _ts(size: 8.5, bold: bold)),
        pw.Text(_moneyFormat.format(amount), style: _ts(size: 8.5, bold: bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildKpiPdfBox(String title, double amount, PdfColor color, {bool isHighlight = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: isHighlight ? color : PdfColor.fromHex('#F8FAFC'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: _ts(size: 7.5, color: isHighlight ? PdfColors.white : PdfColor.fromHex('#64748B'))),
            pw.SizedBox(height: 3),
            pw.Text(
              _moneyFormat.format(amount),
              style: _ts(
                size: 9.5,
                bold: true,
                color: isHighlight ? PdfColors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
