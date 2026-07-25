import 'package:drift/drift.dart';

/// Drift table definition for `depreciation_schedules`.
///
/// Purpose: Periodic depreciation schedule entries for fixed assets over their useful life.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Fixed Assets)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as depreciation schedules, book values, and posting readiness are managed locally in SQLite (Source of Truth) and synced to the cloud.
@DataClassName('DepreciationSchedule')
class DepreciationSchedules extends Table {
  @override
  String get tableName => 'depreciation_schedules';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key component linking to business (`businesses.id`).
  TextColumn get businessId => text().named('business_id')();

  /// Composite Foreign Key linking to parent asset `fixed_assets(business_id, id)` (CASCADE).
  TextColumn get fixedAssetId => text().named('fixed_asset_id')();

  /// Sequential period number across the asset useful life (`integer`).
  IntColumn get depreciationPeriod => integer().named('depreciation_period')();

  /// Scheduled target date for posting the depreciation entry (`date`).
  DateTimeColumn get scheduledPostingDate =>
      dateTime().named('scheduled_posting_date')();

  /// Depreciation installment amount in transaction currency (`decimal(18,2)`, check `>= 0`).
  RealColumn get depreciationAmount => real().named('depreciation_amount')();

  /// Depreciation installment amount in system base currency (`decimal(18,2)`, check `>= 0`).
  RealColumn get baseDepreciationAmount =>
      real().named('base_depreciation_amount')();

  /// Total accumulated depreciation up to and including this period in transaction currency (`decimal(18,2)`).
  RealColumn get accumulatedDepreciation =>
      real().named('accumulated_depreciation')();

  /// Total accumulated depreciation up to and including this period in system base currency (`decimal(18,2)`).
  RealColumn get baseAccumulatedDepreciation =>
      real().named('base_accumulated_depreciation')();

  /// Net remaining book value after applying this period depreciation in transaction currency (`decimal(18,2)`).
  RealColumn get remainingBookValue => real().named('remaining_book_value')();

  /// Net remaining book value after applying this period depreciation in system base currency (`decimal(18,2)`).
  RealColumn get baseRemainingBookValue =>
      real().named('base_remaining_book_value')();

  /// Schedule entry lifecycle status (`Pending`, `Ready`, `Posted`, `Cancelled`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Pending'))();

  /// Foreign Key linking to the user who generated the schedule (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to the user who last updated or posted the schedule (`users.id`, SET NULL).
  TextColumn get updatedBy => text()
      .named('updated_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

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

  /// Identifier of the device where the schedule entry was modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, fixedAssetId, depreciationPeriod},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, fixed_asset_id) REFERENCES fixed_assets(business_id, id) ON DELETE CASCADE',
    'CHECK (status IN (\'Pending\', \'Ready\', \'Posted\', \'Cancelled\'))',
    'CHECK (depreciation_amount >= 0 AND base_depreciation_amount >= 0)',
  ];
}
