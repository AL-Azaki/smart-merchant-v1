import 'package:drift/drift.dart';

/// Drift ORM table definition for `branches` (Domain 1 - Core).
///
/// Physical or logical branch within a business. Used for location-based operations.
@DataClassName('BranchEntity')
class Branches extends Table {
  @override
  String get tableName => 'branches';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Branch name (`string(255)`).
  TextColumn get branchName =>
      text().named('branch_name').withLength(min: 1, max: 255)();

  /// Branch code (`string(50)`).
  TextColumn get branchCode =>
      text().named('branch_code').withLength(min: 1, max: 50)();

  /// Contact phone number (`string(30)`).
  TextColumn get phone => text().nullable().withLength(min: 1, max: 30)();

  /// Contact email address (`string(255)`).
  TextColumn get email => text().nullable().withLength(min: 1, max: 255)();

  /// Physical address (`text`).
  TextColumn get address => text().nullable()();

  /// Flag indicating if this is the default branch for the business (`is_default`).
  BoolColumn get isDefault =>
      boolean().named('is_default').withDefault(const Constant(false))();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Record creation timestamp (`created_at`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`updated_at`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, branchCode},
  ];
}
