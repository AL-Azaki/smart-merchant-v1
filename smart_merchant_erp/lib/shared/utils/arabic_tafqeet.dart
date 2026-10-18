/// أداة تحويل الأرقام النقدية إلى كلمات باللغة العربية (التفقيط)
/// تدعم الأعداد من الصفر وحتى المليارات مع معالجة الكسور النقدية واسم العملة.
class ArabicTafqeet {
  static const List<String> _ones = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
  ];

  static const List<String> _tens = [
    '',
    'عشرة',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  static const List<String> _teens = [
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const List<String> _hundreds = [
    '',
    'مائة',
    'مئتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// تحويل المبلغ الإجمالي إلى عبارة تفقيط رسمية
  /// مثال: 15400 => "فقط خمسة عشر ألفاً وأربعمائة ريال يمني لا غير"
  static String convert(
    double amount, {
    String currencyName = 'ريال يمني',
    String? subUnitName,
  }) {
    if (amount == 0) {
      return 'فقط صفر $currencyName لا غير';
    }

    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final integerPart = absAmount.truncate();
    final decimalPart = ((absAmount - integerPart) * 100).round();

    final words = _convertInteger(integerPart);

    final buffer = StringBuffer('فقط ');
    if (isNegative) {
      buffer.write('سالب ');
    }
    buffer.write(words);
    buffer.write(' ');
    buffer.write(currencyName);

    if (decimalPart > 0 && subUnitName != null && subUnitName.isNotEmpty) {
      buffer.write(' و');
      buffer.write(_convertInteger(decimalPart));
      buffer.write(' ');
      buffer.write(subUnitName);
    } else if (decimalPart > 0) {
      buffer.write(' و');
      buffer.write(decimalPart.toString());
      buffer.write('/100');
    }

    buffer.write(' لا غير');
    return buffer.toString();
  }

  static String _convertInteger(int number) {
    if (number == 0) {
      return 'صفر';
    }

    final parts = <String>[];

    // المليارات
    final billions = number ~/ 1000000000;
    var remainder = number % 1000000000;
    if (billions > 0) {
      if (billions == 1) {
        parts.add('مليار');
      } else if (billions == 2) {
        parts.add('ملياران');
      } else if (billions >= 3 && billions <= 10) {
        parts.add('${_convertGroup(billions)} مليارات');
      } else {
        parts.add('${_convertGroup(billions)} ملياراً');
      }
    }

    // الملايين
    final millions = remainder ~/ 1000000;
    remainder = remainder % 1000000;
    if (millions > 0) {
      if (millions == 1) {
        parts.add('مليون');
      } else if (millions == 2) {
        parts.add('مليونان');
      } else if (millions >= 3 && millions <= 10) {
        parts.add('${_convertGroup(millions)} ملايين');
      } else {
        parts.add('${_convertGroup(millions)} مليوناً');
      }
    }

    // الآلاف
    final thousands = remainder ~/ 1000;
    remainder = remainder % 1000;
    if (thousands > 0) {
      if (thousands == 1) {
        parts.add('ألف');
      } else if (thousands == 2) {
        parts.add('ألفان');
      } else if (thousands >= 3 && thousands <= 10) {
        parts.add('${_convertGroup(thousands)} آلاف');
      } else {
        parts.add('${_convertGroup(thousands)} ألفاً');
      }
    }

    // المئات والعشرات والآحاد
    if (remainder > 0) {
      parts.add(_convertGroup(remainder));
    }

    return parts.join(' و');
  }

  static String _convertGroup(int number) {
    final parts = <String>[];

    final hundreds = number ~/ 100;
    final tensAndOnes = number % 100;

    if (hundreds > 0) {
      parts.add(_hundreds[hundreds]);
    }

    if (tensAndOnes > 0) {
      if (tensAndOnes < 10) {
        parts.add(_ones[tensAndOnes]);
      } else if (tensAndOnes >= 10 && tensAndOnes < 20) {
        parts.add(_teens[tensAndOnes - 10]);
      } else {
        final ones = tensAndOnes % 10;
        final tens = tensAndOnes ~/ 10;

        if (ones > 0) {
          parts.add('${_ones[ones]} و${_tens[tens]}');
        } else {
          parts.add(_tens[tens]);
        }
      }
    }

    return parts.join(' و');
  }
}
