import 'package:drift/drift.dart';

/// Drift ORM table definition for `payment_terms` (Domain - Finance/Accounting).
///
/// Payment term definitions (e.g., Net 30, Net 60) for customers and suppliers.
@DataClassName('PaymentTermEntity')
class PaymentTerms extends Table {
  @override
  String get tableName => 'payment_terms';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Term name (`string(100)` e.g., 'Net 30').
  TextColumn get termName =>
      text().named('term_name').withLength(min: 1, max: 100)();

  /// Number of days until payment is due (`integer`, check >= 0, default: 0).
  IntColumn get daysToDue =>
      integer().named('days_to_due').withDefault(const Constant(0))();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Record creation timestamp (`created_at`).
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp (`updated_at`).
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

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
    {businessId, termName},
  ];

  @override
  List<String> get customConstraints => ['CHECK (days_to_due >= 0)'];
}
