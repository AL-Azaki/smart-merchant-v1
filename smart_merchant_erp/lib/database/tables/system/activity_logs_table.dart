import 'package:drift/drift.dart';

/// Drift table definition for `activity_logs`.
///
/// Purpose: System audit trail and activity log tracking user actions across entities.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (System Administration & Logs)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as user activities and system audit logs are recorded locally in SQLite (Source of Truth) and synced upstream to the cloud.
@DataClassName('ActivityLog')
@TableIndex(
  name: 'idx_activity_logs_lookup',
  columns: {#businessId, #entityType, #entityId},
)
class ActivityLogs extends Table {
  @override
  String get tableName => 'activity_logs';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Optional Foreign Key linking to `users.id` (SET NULL).
  TextColumn get userId => text()
      .named('user_id')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Action performed (`string(100)`, e.g. create, update, post, reverse).
  TextColumn get action => text()();

  /// Polymorphic entity type name (`string(50)`, e.g. Invoice, Expense, Employee).
  TextColumn get entityType => text().named('entity_type')();

  /// Polymorphic entity identifier (`uuid`, nullable).
  TextColumn get entityId => text().named('entity_id').nullable()();

  /// JSONB delta, context, or change details stored as TEXT string (`jsonb`, nullable).
  TextColumn get details => text().nullable()();

  /// IP address of the device/user initiating the action (`string(45)`, nullable).
  TextColumn get ipAddress => text().named('ip_address').nullable()();

  /// Record creation timestamp (`timestamp`, default `CURRENT_TIMESTAMP`).
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the activity log was created (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
