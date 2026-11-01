import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Helper to load Arabic Cairo fonts for PDF reports 100% offline.
class AnalyticsPdfHelper {
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

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

  static Future<({pw.Font regular, pw.Font bold})> loadArabicFonts() async {
    if (_cachedRegular != null && _cachedBold != null) {
      return (regular: _cachedRegular!, bold: _cachedBold!);
    }

    // 1. Try loading from bundled app assets (Offline first for Android/iOS)
    try {
      final regData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _cachedRegular ??= _tryLoadTtf(regData);
      _cachedBold ??= _tryLoadTtf(boldData);
      if (_cachedRegular != null && _cachedBold != null) {
        return (regular: _cachedRegular!, bold: _cachedBold!);
      }
    } catch (_) {}

    // 2. Try loading from local file system (Desktop / Windows / Testing)
    try {
      final regFile = File('assets/fonts/Cairo-Regular.ttf');
      final boldFile = File('assets/fonts/Cairo-Bold.ttf');
      if (regFile.existsSync()) {
        _cachedRegular ??= _tryLoadTtf(regFile.readAsBytesSync().buffer.asByteData());
      }
      if (boldFile.existsSync()) {
        _cachedBold ??= _tryLoadTtf(boldFile.readAsBytesSync().buffer.asByteData());
      }
      if (_cachedRegular != null && _cachedBold != null) {
        return (regular: _cachedRegular!, bold: _cachedBold!);
      }
    } catch (_) {}

    // 3. Fallback to Google Fonts if connected
    try {
      _cachedRegular ??= await PdfGoogleFonts.cairoRegular();
      _cachedBold ??= await PdfGoogleFonts.cairoBold();
      if (_cachedRegular != null && _cachedBold != null) {
        return (regular: _cachedRegular!, bold: _cachedBold!);
      }
    } catch (_) {}

    // 4. Ultimate fallback to standard fonts
    return (regular: _cachedRegular ?? pw.Font.helvetica(), bold: _cachedBold ?? pw.Font.helveticaBold());
  }
}
