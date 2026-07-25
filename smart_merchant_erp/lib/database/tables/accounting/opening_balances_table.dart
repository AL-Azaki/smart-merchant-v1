import 'package:drift/drift.dart';

/// Drift table definition for `opening_balances`.
///
/// Purpose: Opening balance entries per fiscal year per chart of account, with multi-currency support.
/// Domain: DOMAIN 7 — FINANCE (Journals & General Ledger)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as opening balances are recorded locally inside SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('OpeningBalance')
class OpeningBalances extends Table {
  @override
  String get tableName => 'opening_balances';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `fiscal_years(business_id, id)`.
  TextColumn get fiscalYearId => text().named('fiscal_year_id')();

  /// Composite Foreign Key linking to `chart_of_accounts(business_id, id)`.
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Foreign Key linking to transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Opening debit amount in transaction currency (`decimal(18,2)`).
  RealColumn get debitAmount =>
      real().named('debit_amount').withDefault(const Constant(0.00))();

  /// Opening credit amount in transaction currency (`decimal(18,2)`).
  RealColumn get creditAmount =>
      real().named('credit_amount').withDefault(const Constant(0.00))();

  /// Opening debit amount converted to system base currency (`decimal(18,2)`).
  RealColumn get baseDebitAmount =>
      real().named('base_debit_amount').withDefault(const Constant(0.00))();

  /// Opening credit amount converted to system base currency (`decimal(18,2)`).
  RealColumn get baseCreditAmount =>
      real().named('base_credit_amount').withDefault(const Constant(0.00))();

  /// Foreign Key linking to the user who recorded the opening balance (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the opening balance record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {fiscalYearId, chartOfAccountId},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id)',
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id)',
    'CHECK ((debit_amount = 0 AND credit_amount >= 0) OR (debit_amount >= 0 AND credit_amount = 0))',
    'CHECK ((base_debit_amount = 0 AND base_credit_amount >= 0) OR (base_debit_amount >= 0 AND base_credit_amount = 0))',
  ];
}
