/// Paper size enum for print settings.
enum PrintPaperSize {
  a4('A4'),
  a5('A5'),
  thermal80mm('Thermal80mm'),
  thermal58mm('Thermal58mm');

  final String value;
  const PrintPaperSize(this.value);

  static PrintPaperSize fromValue(String value) {
    return PrintPaperSize.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => PrintPaperSize.a4,
    );
  }
}
