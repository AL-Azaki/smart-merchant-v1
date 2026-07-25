import 'package:drift/drift.dart';

/// Drift table definition for `fixed_assets`.
///
/// Purpose: Fixed assets register tracking acquisition, useful life, and depreciation methods.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS (Fixed Assets)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as fixed assets acquisitions, register tracking, and statuses are managed locally in SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('FixedAsset')
class FixedAssets extends Table {
  @override
  String get tableName => 'fixed_assets';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT, nullable).
  TextColumn get branchId => text().named('branch_id').nullable()();

  /// Foreign Key or reference linking to asset classification (`asset_categories.id`, nullable).
  TextColumn get assetCategoryId =>
      text().named('asset_category_id').nullable()();

  /// Foreign Key linking to operating/acquisition currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Unique internal code or tag identifier for the fixed asset (`string(50)`).
  TextColumn get assetCode => text().named('asset_code')();

  /// Official name or description of the fixed asset (`string(255)`).
  TextColumn get assetName => text().named('asset_name')();

  /// Date when the fixed asset was acquired (`date`).
  DateTimeColumn get acquisitionDate => dateTime().named('acquisition_date')();

  /// Original acquisition cost in transaction currency (`decimal(18,2)`, check `>= 0`).
  RealColumn get acquisitionCost => real().named('acquisition_cost')();

  /// Original acquisition cost converted to system base currency (`decimal(18,2)`, check `>= 0`).
  RealColumn get baseAcquisitionCost => real().named('base_acquisition_cost')();

  /// Estimated useful life duration in depreciation periods/months (`integer`, check `> 0`).
  IntColumn get usefulLife => integer().named('useful_life')();

  /// Estimated salvage/residual value at the end of useful life in transaction currency (`decimal(18,2)`, default `0.00`, check `>= 0`).
  RealColumn get residualValue =>
      real().named('residual_value').withDefault(const Constant(0.00))();

  /// Estimated salvage/residual value in system base currency (`decimal(18,2)`, default `0.00`, check `>= 0`).
  RealColumn get baseResidualValue =>
      real().named('base_residual_value').withDefault(const Constant(0.00))();

  /// Applied depreciation calculation method (`string(50)`, e.g. StraightLine).
  TextColumn get depreciationMethod => text().named('depreciation_method')();

  /// Date when periodic depreciation starts running (`date`).
  DateTimeColumn get depreciationStartDate =>
      dateTime().named('depreciation_start_date')();

  /// Operational lifecycle status (`Draft`, `Active`, `Depreciating`, `Fully Depreciated`, `Disposed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Draft'))();

  /// Optional Foreign Key linking to the user responsible for managing/custody of the asset (`users.id`, SET NULL).
  TextColumn get responsibleUserId => text()
      .named('responsible_user_id')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Foreign Key linking to the user who created the asset record (`users.id`, RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to the user who last updated the asset record (`users.id`, SET NULL).
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

  /// Identifier of the device where the fixed asset record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, assetCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Draft\', \'Active\', \'Depreciating\', \'Fully Depreciated\', \'Disposed\'))',
    'CHECK (acquisition_cost >= 0 AND base_acquisition_cost >= 0)',
    'CHECK (useful_life > 0)',
    'CHECK (residual_value >= 0 AND base_residual_value >= 0)',
  ];
}
