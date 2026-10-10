import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// CurrenciesTable stores supported currencies (Base currency, YER, SAR, USD)
/// along with exchange rates and decimal configuration.
@DataClassName('CurrencyData')
class CurrenciesTable extends Table {
  TextColumn get id => text().clientDefault(() => Uuid().v4())();
  TextColumn get code => text().withLength(min: 3, max: 10)(); // YER, SAR, USD
  TextColumn get nameAr => text().withLength(min: 1, max: 100)();
  TextColumn get symbol => text().withLength(min: 1, max: 10)();
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))();
  
  /// Exchange rate relative to base currency (Base Currency rate is always 1.0)
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();
  
  BoolColumn get isBaseCurrency => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
