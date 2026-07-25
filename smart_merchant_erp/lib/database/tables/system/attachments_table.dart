import 'package:drift/drift.dart';

/// Drift table definition for `attachments`.
///
/// Purpose: Polymorphic file attachments across all business entities (invoices, contracts, expenses, etc.).
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Supporting Modules & Attachments)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as document attachments are uploaded and managed locally in SQLite (Source of Truth) and synced across devices and backend.
@DataClassName('Attachment')
@TableIndex(
  name: 'idx_attachments_entity',
  columns: {#businessId, #entityType, #entityId},
)
class Attachments extends Table {
  @override
  String get tableName => 'attachments';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Polymorphic entity classification (`string(50)`, e.g. Invoice, Expense, EmployeeDocument).
  TextColumn get entityType => text().named('entity_type')();

  /// Polymorphic target entity UUID identifier (`uuid`).
  TextColumn get entityId => text().named('entity_id')();

  /// Local storage path or synced URL path to the attachment file (`string(500)`).
  TextColumn get filePath => text().named('file_path')();

  /// Original or display filename of the attachment (`string(255)`).
  TextColumn get fileName => text().named('file_name')();

  /// Upload timestamp (`timestamp`, default `CURRENT_TIMESTAMP`).
  DateTimeColumn get uploadDate =>
      dateTime().named('upload_date').withDefault(currentDateAndTime)();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the attachment record was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
