import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Helper to load Arabic Cairo fonts for PDF reports 100% offline.
class AnalyticsPdfHelper {
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  static Future<({pw.Font regular, pw.Font bold})> loadArabicFonts() async {
    if (_cachedRegular != null && _cachedBold != null) {
      return (regular: _cachedRegular!, bold: _cachedBold!);
    }

    // 1. Try loading from bundled app assets (Offline first)
    try {
      final regData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _cachedRegular = pw.Font.ttf(regData);
      _cachedBold = pw.Font.ttf(boldData);
      return (regular: _cachedRegular!, bold: _cachedBold!);
    } catch (_) {}

    // 2. Try loading from local file system (Desktop/Testing)
    try {
      final regFile = File('assets/fonts/Cairo-Regular.ttf');
      final boldFile = File('assets/fonts/Cairo-Bold.ttf');
      if (regFile.existsSync() && boldFile.existsSync()) {
        _cachedRegular = pw.Font.ttf(
          regFile.readAsBytesSync().buffer.asByteData(),
        );
        _cachedBold = pw.Font.ttf(
          boldFile.readAsBytesSync().buffer.asByteData(),
        );
        return (regular: _cachedRegular!, bold: _cachedBold!);
      }
    } catch (_) {}

    // 3. Fallback to Google Fonts if connected
    try {
      _cachedRegular = await PdfGoogleFonts.cairoRegular();
      _cachedBold = await PdfGoogleFonts.cairoBold();
      return (regular: _cachedRegular!, bold: _cachedBold!);
    } catch (_) {}

    // 4. Ultimate fallback to standard fonts
    return (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold());
  }
}
