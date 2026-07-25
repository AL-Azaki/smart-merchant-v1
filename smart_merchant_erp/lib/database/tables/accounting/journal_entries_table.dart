import 'package:drift/drift.dart';

/// Drift table definition for `journal_entries`.
///
/// Purpose: General ledger journal entry headers. All financial postings flow through this table.
/// Domain: DOMAIN 7 — FINANCE (Journals & General Ledger)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as operational and manual journal entries are generated locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('JournalEntry')
@TableIndex(name: 'idx_je_document', columns: {#documentType, #documentId})
class JournalEntries extends Table {
  @override
  String get tableName => 'journal_entries';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `fiscal_years(business_id, id)` (RESTRICT).
  TextColumn get fiscalYearId => text().named('fiscal_year_id')();

  /// Foreign Key linking to `fiscal_periods.id` (RESTRICT).
  TextColumn get fiscalPeriodId => text()
      .named('fiscal_period_id')
      .customConstraint(
        'NOT NULL REFERENCES fiscal_periods(id) ON DELETE RESTRICT',
      )();

  /// Unique journal tracking number per business.
  TextColumn get journalNumber => text().named('journal_number')();

  /// Date of the financial document (`date` stored as INTEGER/DateTime).
  DateTimeColumn get documentDate => dateTime().named('document_date')();

  /// Date when the journal entry was officially posted (`date` stored as INTEGER/DateTime).
  DateTimeColumn get postingDate =>
      dateTime().named('posting_date').nullable()();

  /// Classification type of the journal entry (`Manual`, `SalesInvoice`, `PurchaseInvoice`, `Payment`, `InventoryAdjustment`, `Reverse`).
  TextColumn get journalType => text().named('journal_type')();

  /// Source document classification (`Manual`, `SalesInvoice`, `PurchaseInvoice`, `Payment`, `InventoryAdjustment`, `Reverse`).
  TextColumn get documentType => text().named('document_type')();

  /// Polymorphic reference UUID linking to the source financial document (e.g., invoice UUID).
  TextColumn get documentId => text().named('document_id').nullable()();

  /// Display reference number of the source financial document.
  TextColumn get documentNumber => text().named('document_number').nullable()();

  /// Self-referential Foreign Key linking to the original journal entry being reversed (`journal_entries.id`, RESTRICT).
  TextColumn get originalJournalId => text()
      .named('original_journal_id')
      .nullable()
      .customConstraint(
        'NULL REFERENCES journal_entries(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to transaction currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency conversion exchange rate applied (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.00000000))();

  /// General description or narration of the journal entry.
  TextColumn get description => text().nullable()();

  /// Lifecycle posting status (`Draft`, `Posted`, `Reversed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// Foreign Key linking to the user who created the journal entry (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to the user who posted the journal entry (`users.id`, RESTRICT).
  TextColumn get postedBy => text()
      .named('posted_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to the user who reversed the journal entry (`users.id`, RESTRICT).
  TextColumn get reversedBy => text()
      .named('reversed_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Timestamp when the entry was posted.
  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  /// Timestamp when the entry was reversed.
  DateTimeColumn get reversedAt => dateTime().named('reversed_at').nullable()();

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

  /// Identifier of the device where the journal entry record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, journalNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, fiscal_year_id) REFERENCES fiscal_years(business_id, id) ON DELETE RESTRICT',
    'CHECK (journal_type IN (\'Manual\', \'SalesInvoice\', \'PurchaseInvoice\', \'Payment\', \'InventoryAdjustment\', \'Reverse\'))',
    'CHECK (document_type IN (\'Manual\', \'SalesInvoice\', \'PurchaseInvoice\', \'Payment\', \'InventoryAdjustment\', \'Reverse\'))',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Reversed\'))',
  ];
}
