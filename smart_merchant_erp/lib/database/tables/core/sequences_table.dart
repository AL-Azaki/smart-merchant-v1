import 'package:drift/drift.dart';
import '../../converters/sequence_reset_frequency_converter.dart';
import '../../enums/sequence_reset_frequency.dart';

/// Drift table definition for `sequences`.
///
/// Purpose: Sequential document numbering generators (e.g., INV-2026-00001) per business and branch.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Local Only (does not require `sync_status`, `version`, `device_id`).
/// Kept exclusively local to prevent document numbering conflicts across devices.
@DataClassName('Sequence')
class Sequences extends Table {
  @override
  String get tableName => 'sequences';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (NULL = global business sequence).
  TextColumn get branchId => text().named('branch_id').nullable()();

  /// Document type string classification (`SalesInvoice`, `PurchaseInvoice`, etc.).
  TextColumn get documentType => text().named('document_type')();

  /// Optional prefix string prepended to document numbers (e.g., `INV-`).
  TextColumn get prefix => text().nullable()();

  /// Optional suffix string appended to document numbers (e.g., `-2026`).
  TextColumn get suffix => text().nullable()();

  /// Current sequential value counter (64-bit integer, check >= 0).
  IntColumn get currentValue =>
      integer().named('current_value').withDefault(const Constant(0))();

  /// Increment step value per document generation (check > 0).
  IntColumn get step => integer().withDefault(const Constant(1))();

  /// Zero-padding width for document number string formatting (check > 0).
  IntColumn get padding => integer().withDefault(const Constant(5))();

  /// Sequence counter reset frequency interval (`Never`, `Daily`, `Monthly`, `Yearly`).
  TextColumn get resetFrequency => text()
      .named('reset_frequency')
      .map(const SequenceResetFrequencyConverter())
      .withDefault(const Constant('Never'))();

  /// Date when the sequence counter was last reset to starting value.
  DateTimeColumn get lastResetDate =>
      dateTime().named('last_reset_date').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE CASCADE',
    'CHECK (current_value >= 0)',
    'CHECK (step > 0)',
    'CHECK (padding > 0)',
    'CHECK (reset_frequency IN (\'Never\', \'Daily\', \'Monthly\', \'Yearly\'))',
  ];
}
