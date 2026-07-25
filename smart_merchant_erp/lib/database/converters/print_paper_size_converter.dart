import 'package:drift/drift.dart';
import '../enums/print_paper_size.dart';

/// Drift TypeConverter for [PrintPaperSize] enum to/from String (`paper_size`).
class PrintPaperSizeConverter extends TypeConverter<PrintPaperSize, String> {
  const PrintPaperSizeConverter();

  @override
  PrintPaperSize fromSql(String fromDb) => PrintPaperSize.fromValue(fromDb);

  @override
  String toSql(PrintPaperSize value) => value.value;
}
