import 'package:drift/drift.dart';

/// Drift table definition for `employee_documents`.
///
/// Purpose: Employee files, identification documents, and certificates storage tracking.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as employee document records and metadata are created locally in SQLite (Source of Truth) and synced across devices.
@DataClassName('EmployeeDocument')
class EmployeeDocuments extends Table {
  @override
  String get tableName => 'employee_documents';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to parent employee `employees(business_id, id)` (CASCADE).
  TextColumn get employeeId => text().named('employee_id')();

  /// Classification of the document (`string(50)`, e.g. ID, Passport, Contract).
  TextColumn get documentType => text().named('document_type')();

  /// Official identification code or registration number on the document (`string(100)`, nullable).
  TextColumn get documentNumber => text().named('document_number').nullable()();

  /// Local storage or synced URL path to the document file (`string(500)`).
  TextColumn get filePath => text().named('file_path')();

  /// Date when the document was issued (`date`, nullable).
  DateTimeColumn get issueDate => dateTime().named('issue_date').nullable()();

  /// Date when the document expires (`date`, nullable).
  DateTimeColumn get expiryDate => dateTime().named('expiry_date').nullable()();

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

  /// Identifier of the device where the document record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, employee_id) REFERENCES employees(business_id, id) ON DELETE CASCADE',
  ];
}
