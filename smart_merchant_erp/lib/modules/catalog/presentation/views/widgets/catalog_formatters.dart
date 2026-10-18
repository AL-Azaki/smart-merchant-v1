String formatCatalogNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
String formatCatalogPrice(double value, [String currency = 'ر.ي']) =>
    '${formatCatalogNumber(value)} $currency';

/// Display the Arabic side of legacy bilingual labels; keep custom names intact.
String catalogDisplayName(String value) {
  final parts = value.split('/').map((part) => part.trim()).toList();
  if (parts.length != 2) {
    return value;
  }
  final arabic = RegExp(r'[\u0600-\u06FF]');
  final localized = parts.where(arabic.hasMatch).toList();
  final other = parts.where((part) => !arabic.hasMatch(part)).toList();
  if (localized.length == 1 &&
      other.length == 1 &&
      RegExp(r'[A-Za-z]').hasMatch(other.single)) {
    return localized.single;
  }
  return value;
}
