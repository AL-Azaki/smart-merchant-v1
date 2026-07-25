import 'package:drift/drift.dart';

/// Drift ORM table definition for `currencies` (Domain 1 - Core).
///
/// Global currency definitions with exchange rates. Shared across businesses.
@DataClassName('CurrencyEntity')
class Currencies extends Table {
  @override
  String get tableName => 'currencies';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// ISO Currency Code (`string(10)`, unique).
  TextColumn get currencyCode =>
      text().named('currency_code').withLength(min: 1, max: 10).unique()();

  /// Arabic name of the currency (`string(100)`).
  TextColumn get currencyNameAr =>
      text().named('currency_name_ar').withLength(min: 1, max: 100)();

  /// English name of the currency (`string(100)`).
  TextColumn get currencyNameEn =>
      text().named('currency_name_en').withLength(min: 1, max: 100)();

  /// Currency symbol e.g., '$', 'SAR' (`string(10)`).
  TextColumn get currencySymbol =>
      text().named('currency_symbol').withLength(min: 1, max: 10)();

  /// Number of decimal places (`integer`, check: 0-6, default: 2).
  IntColumn get decimalPlaces =>
      integer().named('decimal_places').withDefault(const Constant(2))();

  /// Base exchange rate relative to the system base currency (`decimal(18,8)`, check: > 0).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.0))();

  /// Flag indicating if this is the system base currency (`is_base_currency`).
  BoolColumn get isBaseCurrency =>
      boolean().named('is_base_currency').withDefault(const Constant(false))();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (decimal_places >= 0 AND decimal_places <= 6)',
    'CHECK (exchange_rate > 0)',
  ];
}
