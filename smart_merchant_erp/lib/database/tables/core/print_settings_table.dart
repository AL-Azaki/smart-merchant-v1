import 'package:drift/drift.dart';
import '../../converters/print_paper_size_converter.dart';
import '../../enums/print_paper_size.dart';

/// Drift table definition for `print_settings`.
///
/// Purpose: Document printing and layout configurations per business or specific branch.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as print layouts are branch-specific and require bidirectional cloud sync.
@DataClassName('PrintSetting')
class PrintSettings extends Table {
  @override
  String get tableName => 'print_settings';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (NULL = global business setting).
  TextColumn get branchId => text().named('branch_id').nullable()();

  /// Document type string classification (e.g., `SalesInvoice`, `Receipt`).
  TextColumn get documentType => text().named('document_type')();

  /// Layout template name identifier.
  TextColumn get templateName =>
      text().named('template_name').withDefault(const Constant('default'))();

  /// Custom header text to display on printed documents.
  TextColumn get headerText => text().named('header_text').nullable()();

  /// Custom footer text to display on printed documents.
  TextColumn get footerText => text().named('footer_text').nullable()();

  /// Flag indicating whether the business logo should be displayed on prints.
  BoolColumn get showLogo =>
      boolean().named('show_logo').withDefault(const Constant(true))();

  /// Flag indicating whether the tax breakdown summary should be displayed on prints.
  BoolColumn get showTaxSummary =>
      boolean().named('show_tax_summary').withDefault(const Constant(true))();

  /// Flag indicating whether a QR code should be generated and printed on documents.
  BoolColumn get showQrCode =>
      boolean().named('show_qr_code').withDefault(const Constant(true))();

  /// Paper size format (`A4`, `A5`, `Thermal80mm`, `Thermal58mm`) mapped to `PrintPaperSize` enum.
  TextColumn get paperSize => text()
      .named('paper_size')
      .map(const PrintPaperSizeConverter())
      .withDefault(const Constant('A4'))();

  /// Top print margin in millimeters.
  IntColumn get marginTop =>
      integer().named('margin_top').withDefault(const Constant(10))();

  /// Bottom print margin in millimeters.
  IntColumn get marginBottom =>
      integer().named('margin_bottom').withDefault(const Constant(10))();

  /// Left print margin in millimeters.
  IntColumn get marginLeft =>
      integer().named('margin_left').withDefault(const Constant(10))();

  /// Right print margin in millimeters.
  IntColumn get marginRight =>
      integer().named('margin_right').withDefault(const Constant(10))();

  /// Base font size for document layout.
  IntColumn get fontSize =>
      integer().named('font_size').withDefault(const Constant(12))();

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

  /// Identifier of the device where the print layout record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE CASCADE',
    'CHECK (paper_size IN (\'A4\', \'A5\', \'Thermal80mm\', \'Thermal58mm\'))',
  ];
}
