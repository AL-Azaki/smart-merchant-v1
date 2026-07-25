import 'package:drift/drift.dart';

/// Drift table definition for `journal_entry_lines`.
///
/// Purpose: Individual debit/credit lines within a journal entry.
/// Domain: DOMAIN 7 — FINANCE (Journals & General Ledger)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as journal entry lines are created locally in SQLite (Source of Truth) and synced bidirectionally to maintain General Ledger consistency.
@DataClassName('JournalEntryLine')
class JournalEntryLines extends Table {
  @override
  String get tableName => 'journal_entry_lines';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to `journal_entries(business_id, id)` (CASCADE).
  TextColumn get journalEntryId => text().named('journal_entry_id')();

  /// Line order sequence number inside the parent journal entry (`line_number`).
  IntColumn get lineNumber => integer().named('line_number')();

  /// Composite Foreign Key linking to `chart_of_accounts(business_id, id)` (RESTRICT).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Detailed description or narration specific to this line item.
  TextColumn get description => text().nullable()();

  /// Foreign Key linking to line transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied to this line (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// Accounting entry classification (`Debit` or `Credit`).
  TextColumn get type => text().named('type')();

  /// Line amount in foreign transaction currency (`decimal(18,2)`, check >= 0).
  RealColumn get foreignAmount =>
      real().named('foreign_amount').withDefault(const Constant(0.00))();

  /// Line amount converted to system base currency (`decimal(18,2)`, check >= 0).
  RealColumn get baseAmount =>
      real().named('base_amount').withDefault(const Constant(0.00))();

  /// Polymorphic document type reference linking line item to operational source document (`document_type`).
  TextColumn get documentType => text().named('document_type').nullable()();

  /// Polymorphic document ID reference linking line item to operational source document (`document_id`).
  TextColumn get documentId => text().named('document_id').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the journal entry line record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {journalEntryId, lineNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, journal_entry_id) REFERENCES journal_entries(business_id, id) ON DELETE CASCADE',
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
    'CHECK (type IN (\'Debit\', \'Credit\'))',
    'CHECK (foreign_amount >= 0)',
    'CHECK (base_amount >= 0)',
  ];
}
