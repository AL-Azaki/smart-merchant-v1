import 'package:drift/drift.dart';
import '../enums/stock_count_status.dart';

class StockCountStatusConverter extends TypeConverter<StockCountStatus, String> {
  const StockCountStatusConverter();

  @override
  StockCountStatus fromSql(String fromDb) {
    switch (fromDb) {
      case 'Draft':
        return StockCountStatus.draft;
      case 'Posted':
        return StockCountStatus.posted;
      case 'Cancelled':
        return StockCountStatus.cancelled;
      default:
        throw ArgumentError('Unknown StockCountStatus value from database: $fromDb');
    }
  }

  @override
  String toSql(StockCountStatus value) {
    switch (value) {
      case StockCountStatus.draft:
        return 'Draft';
      case StockCountStatus.posted:
        return 'Posted';
      case StockCountStatus.cancelled:
        return 'Cancelled';
    }
  }
}
