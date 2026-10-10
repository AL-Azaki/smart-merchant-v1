import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// FiscalYearsTable defines accounting years and period locking.
/// When isClosed is true, any modifications or entries in this period are strictly rejected.
@DataClassName('FiscalYearData')
class FiscalYearsTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get yearName => text().withLength(min: 1, max: 50)(); // e.g. "2026"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
