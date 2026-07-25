import 'package:drift/drift.dart';

/// Drift table definition for `departments`.
///
/// Purpose: Human Resources departments hierarchy per business.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as administrative departments and manager assignments are maintained locally inside SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Department')
class Departments extends Table {
  @override
  String get tableName => 'departments';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Official name of the department (`string(100)`).
  TextColumn get departmentName => text().named('department_name')();

  /// Short code or identifier for the department (`string(50)`, nullable).
  TextColumn get departmentCode => text().named('department_code').nullable()();

  /// Composite self-referential Foreign Key linking to parent department `departments(business_id, id)` (RESTRICT, nullable).
  TextColumn get parentId => text().named('parent_id').nullable()();

  /// Composite Foreign Key linking to the department manager `employees(business_id, id)` (SET NULL, nullable initially).
  TextColumn get managerId => text().named('manager_id').nullable()();

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

  /// Identifier of the device where the department record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, departmentName},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, parent_id) REFERENCES departments(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, manager_id) REFERENCES employees(business_id, id) ON DELETE SET NULL',
  ];
}
