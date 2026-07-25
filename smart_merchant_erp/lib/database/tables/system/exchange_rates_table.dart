import 'package:drift/drift.dart';

/// Drift table definition for `exchange_rates`.
///
/// Purpose: Historical exchange rates between currencies per business.
/// Domain: DOMAIN 4 — FINANCE (Currencies & Exchange Rates)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as exchange rates between source/target currencies are maintained locally in SQLite (Source of Truth) and synced across devices.
@DataClassName('ExchangeRate')
class ExchangeRates extends Table {
  @override
  String get tableName => 'exchange_rates';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to source `currencies.id` (RESTRICT).
  TextColumn get sourceCurrencyId => text()
      .named('source_currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to target `currencies.id` (RESTRICT).
  TextColumn get targetCurrencyId => text()
      .named('target_currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Date for which the exchange rate is effective (`date`).
  DateTimeColumn get effectiveDate => dateTime().named('effective_date')();

  /// Exchange conversion rate (`decimal(20,8)`, check `> 0`).
  RealColumn get rate => real()();

  /// Record creation timestamp (`timestamp`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`timestamp`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the exchange rate was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, sourceCurrencyId, targetCurrencyId, effectiveDate},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (source_currency_id <> target_currency_id)',
    'CHECK (rate > 0)',
  ];
}
