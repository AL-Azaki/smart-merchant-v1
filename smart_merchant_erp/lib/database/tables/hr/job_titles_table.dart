import 'package:drift/drift.dart';

/// Drift table definition for `job_titles`.
///
/// Purpose: Employee job titles classification per business.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as job title definitions are created and managed locally in SQLite (Source of Truth) and synced across branches/server.
@DataClassName('JobTitle')
class JobTitles extends Table {
  @override
  String get tableName => 'job_titles';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Official title name (`string(100)`).
  TextColumn get titleName => text().named('title_name')();

  /// Descriptive details regarding the job title and responsibilities (`text`, nullable).
  TextColumn get description => text().nullable()();

  /// Active status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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

  /// Identifier of the device where the job title record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, titleName},
  ];
}
