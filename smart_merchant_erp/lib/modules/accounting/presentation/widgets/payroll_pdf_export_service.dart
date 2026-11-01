import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../kernel/storage/app_database.dart';
import '../services/analytics_pdf_helper.dart';

class EmployeePayrollRecord {
  final Employee employee;
  final double basicSalary;
  final double totalAdvances;
  final double remainingSalary;
  final List<Payment> transactions;

  EmployeePayrollRecord({
    required this.employee,
    required this.basicSalary,
    required this.totalAdvances,
    required this.remainingSalary,
    required this.transactions,
  });
}

class PayrollPdfExportService {
  static pw.Font? _cairoRegular;
  static pw.Font? _cairoBold;

  static Future<void> _loadFonts() async {
    final fonts = await AnalyticsPdfHelper.loadArabicFonts();
    _cairoRegular = fonts.regular;
    _cairoBold = fonts.bold;
  }

  static String _formatNum(double val) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(val);
  }

  /// 1. طباعة كشف حساب شامل لجميع الموظفين (مسير الرواتب)
  static Future<void> exportAllEmployeesPayrollPdf({
    required List<EmployeePayrollRecord> records,
    required String businessName,
    DateTime? periodDate,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();
    final pdfTheme = pw.ThemeData.withFont(
      base: _cairoRegular,
      bold: _cairoBold,
    );
    final pdf = pw.Document(theme: pdfTheme);

    final start = startDate ?? periodDate ?? DateTime.now();
    final end = endDate ?? periodDate ?? DateTime.now();
    final isSameMonth = start.year == end.year && start.month == end.month;
    final periodLabel = isSameMonth
        ? DateFormat('MMMM yyyy', 'ar').format(start)
        : 'من ${DateFormat('yyyy/MM/dd').format(start)} إلى ${DateFormat('yyyy/MM/dd').format(end)}';

    final totalSalaries = records.fold(0.0, (sum, r) => sum + r.basicSalary);
    final totalAdvances = records.fold(0.0, (sum, r) => sum + r.totalAdvances);
    final totalRemaining = records.fold(0.0, (sum, r) => sum + r.remainingSalary);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pdfTheme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'نظام سمارت ميرشانت لإدارة الرواتب والموظفين',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'مسير الرواتب والسلف - $periodLabel',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (context) => [
          // KPI Summary Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildKpiBox('عدد الموظفين', '${records.length} موظف'),
                _buildKpiBox('إجمالي الرواتب', '${_formatNum(totalSalaries)} ر.ي'),
                _buildKpiBox('إجمالي السلف المنصرفة', '${_formatNum(totalAdvances)} ر.ي'),
                _buildKpiBox('صافي الالتزام المتبقي', '${_formatNum(totalRemaining)} ر.ي', isHighlight: true),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Table of Employees
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(font: _cairoBold, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor(0.1, 0.4, 0.6)),
            cellStyle: pw.TextStyle(font: _cairoRegular, fontSize: 9.5),
            cellAlignment: pw.Alignment.centerRight,
            headers: [
              '#',
              'رمز الموظف',
              'اسم الموظف',
              'الهاتف',
              'الراتب المستحق',
              'السلف المسحوبة',
              'المتبقي له (الصافي)',
              'التوقيع / الاستلام',
            ],
            data: records.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final r = entry.value;
              return [
                '$idx',
                r.employee.employeeCode,
                '${r.employee.firstName} ${r.employee.lastName}',
                r.employee.phone ?? '-',
                '${_formatNum(r.basicSalary)} ر.ي',
                '${_formatNum(r.totalAdvances)} ر.ي',
                '${_formatNum(r.remainingSalary)} ر.ي',
                '',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('المسؤول المالي', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 25),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('مدير المنشأة / الاعتماد', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 25),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final filenameDate = isSameMonth
        ? '${start.year}_${start.month}'
        : '${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}';
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'مسير_الرواتب_$filenameDate.pdf',
    );
  }

  /// 2. طباعة كشف حساب فردي لموظف محدد
  static Future<void> exportSingleEmployeeStatementPdf({
    required EmployeePayrollRecord record,
    required String businessName,
    DateTime? periodDate,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _loadFonts();
    final pdfTheme = pw.ThemeData.withFont(
      base: _cairoRegular,
      bold: _cairoBold,
    );
    final pdf = pw.Document(theme: pdfTheme);

    final start = startDate ?? periodDate ?? DateTime.now();
    final end = endDate ?? periodDate ?? DateTime.now();
    final isSameMonth = start.year == end.year && start.month == end.month;
    final periodLabel = isSameMonth
        ? DateFormat('MMMM yyyy', 'ar').format(start)
        : 'من ${DateFormat('yyyy/MM/dd').format(start)} إلى ${DateFormat('yyyy/MM/dd').format(end)}';

    final emp = record.employee;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pdfTheme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('قسم الشؤون المالية والرواتب', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'كشف حساب رواتب وسلف موظف',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),
          ],
        ),
        build: (context) => [
          // Employee Info Card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('اسم الموظف: ${emp.firstName} ${emp.lastName}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('الرقم الوظيفي: ${emp.employeeCode}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الفترة: $periodLabel', style: pw.TextStyle(font: _cairoRegular, fontSize: 10)),
                    pw.Text('رقم الهاتف: ${emp.phone ?? '-'}', style: pw.TextStyle(font: _cairoRegular, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Financial Summary
          pw.Row(
            children: [
              pw.Expanded(child: _buildSummaryCard('الراتب الشهري الأساسي', '${_formatNum(record.basicSalary)} ر.ي', PdfColors.blue700)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildSummaryCard('إجمالي السلف والمسحوبات', '${_formatNum(record.totalAdvances)} ر.ي', PdfColors.orange700)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildSummaryCard('صافي المبلغ المتبقي له', '${_formatNum(record.remainingSalary)} ر.ي', PdfColors.green700)),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Text('تفاصيل الحركات والسلف المستلمة خلال الفترة:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          // Transactions Table
          if (record.transactions.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              alignment: pw.Alignment.center,
              child: pw.Text('لا توجد سلف أو مسحوبات مسجلة لهذا الموظف خلال هذه الفترة',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            )
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(font: _cairoBold, fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor(0.2, 0.3, 0.4)),
              cellStyle: pw.TextStyle(font: _cairoRegular, fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headers: ['#', 'رقم السند', 'التاريخ', 'البيان', 'طريقة الصرف', 'المبلغ'],
              data: record.transactions.asMap().entries.map((e) {
                final idx = e.key + 1;
                final t = e.value;
                final dateStr = DateFormat('yyyy-MM-dd').format(t.paymentDate);
                return [
                  '$idx',
                  t.paymentNumber,
                  dateStr,
                  t.notes ?? 'سلفة على الراتب',
                  t.paymentMethodId,
                  '${_formatNum(t.amount)} ر.ي',
                ];
              }).toList(),
            ),

          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('توقيع الموظف بالاستلام', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('توقيع المحاسب', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  pw.Text('................................', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final filenameDate = isSameMonth
        ? '${start.year}_${start.month}'
        : '${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}';
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'كشف_حساب_${emp.firstName}_${emp.lastName}_$filenameDate.pdf',
    );
  }

  static pw.Widget _buildKpiBox(String title, String val, {bool isHighlight = false}) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(font: _cairoRegular, fontSize: 9, color: PdfColors.grey800)),
        pw.SizedBox(height: 2),
        pw.Text(
          val,
          style: pw.TextStyle(
            font: _cairoBold,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.green800 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(String title, String val, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: _cairoRegular, fontSize: 8.5, color: PdfColors.grey800)),
          pw.SizedBox(height: 3),
          pw.Text(val, style: pw.TextStyle(font: _cairoBold, fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
