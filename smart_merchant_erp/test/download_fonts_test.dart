import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

void main() {
  test('Download Cairo fonts', () async {
    final regular = await PdfGoogleFonts.cairoRegular();
    File('assets/fonts/Cairo-Regular.ttf').writeAsBytesSync(regular.data.buffer.asUint8List());

    final bold = await PdfGoogleFonts.cairoBold();
    File('assets/fonts/Cairo-Bold.ttf').writeAsBytesSync(bold.data.buffer.asUint8List());

    final semiBold = await PdfGoogleFonts.cairoSemiBold();
    File('assets/fonts/Cairo-SemiBold.ttf').writeAsBytesSync(semiBold.data.buffer.asUint8List());
    
    print('Successfully downloaded and saved TTF fonts.');
  });
}
