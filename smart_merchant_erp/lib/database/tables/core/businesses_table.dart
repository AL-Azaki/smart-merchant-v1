import 'package:drift/drift.dart';

/// Drift ORM table definition for `businesses` (Domain 1 - Core).
///
/// A business entity within an account. Central tenant-isolation node.
@DataClassName('BusinessEntity')
class Businesses extends Table {
  @override
  String get tableName => 'businesses';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Foreign Key linking to `accounts.id` (RESTRICT).
  TextColumn get accountId => text()
      .named('account_id')
      .customConstraint(
        'NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT',
      )();

  /// Business name (`string(255)`).
  TextColumn get businessName =>
      text().named('business_name').withLength(min: 1, max: 255)();

  /// Business classification/type (`string(100)`).
  TextColumn get businessType =>
      text().named('business_type').nullable().withLength(min: 1, max: 100)();

  /// Primary contact phone number (`string(30)`).
  TextColumn get primaryPhone =>
      text().named('primary_phone').nullable().withLength(min: 1, max: 30)();

  /// Primary contact email address (`string(255)`).
  TextColumn get primaryEmail =>
      text().named('primary_email').nullable().withLength(min: 1, max: 255)();

  /// Storage path or URL for business logo (`string(500)`).
  TextColumn get logoPath =>
      text().named('logo_path').nullable().withLength(min: 1, max: 500)();

  /// Operational status (`Active` or `Inactive`).
  TextColumn get status => text().withDefault(const Constant('Active'))();

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
    {accountId, id},
    {accountId, businessName},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (status IN (\'Active\', \'Inactive\'))',
  ];
}
