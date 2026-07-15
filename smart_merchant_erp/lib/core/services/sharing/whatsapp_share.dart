import 'package:url_launcher/url_launcher.dart';

class WhatsAppShare {
  /// بناء وإرسال رسالة احترافية ومنسقة عبر الواتساب للعميل
  static Future<void> shareInvoice({
    required String invoiceNumber,
    required String customerName,
    required double total,
    required String date,
    required List<Map<String, dynamic>> items,
  }) async {
    final buffer = StringBuffer();
    
    // ترويسة الرسالة
    buffer.writeln('🏢 *مؤسسة التاجر الذكي*');
    buffer.writeln('------------------------');
    buffer.writeln('📄 *فاتورة مبيعات*');
    buffer.writeln('رقم الفاتورة: $invoiceNumber');
    buffer.writeln('التاريخ: $date');
    buffer.writeln('العميل: $customerName');
    buffer.writeln('------------------------');
    
    // قائمة المشتريات
    for (var item in items) {
      buffer.writeln('▪ ${item['name']}');
      buffer.writeln('  الكمية: ${item['qty']}  |  الإجمالي: ${item['total'].toStringAsFixed(2)} ﷼');
    }
    
    // الذيل والإجماليات
    buffer.writeln('------------------------');
    buffer.writeln('💰 *الإجمالي النهائي: ${total.toStringAsFixed(2)} ﷼*');
    buffer.writeln('------------------------');
    buffer.writeln('نشكركم على ثقتكم وتعاملكم معنا! 🙏');
    buffer.writeln('للاستفسار: +967 770 000 000');

    // تشفير النص ليكون متوافقاً مع روابط الويب URL
    final encodedMessage = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$encodedMessage');
    
    // محاولة فتح تطبيق الواتساب أو المتصفح
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}
