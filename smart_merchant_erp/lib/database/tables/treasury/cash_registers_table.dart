import 'cash_registers_table.dart';
import 'package:drift/drift.dart';
import '../accounting/chart_of_accounts_table.dart';
import '../core/currencies_table.dart';
import '../core/businesses_table.dart';
import '../core/branches_table.dart';

/// Drift table definition for `cash_registers`.
///
/// Purpose: Physical or logical cash registers per branch for POS operations and cash management.
/// Domain: DOMAIN 4 â€” FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as opening/closing registers and tracking live cash balances happen locally inside SQLite (Source of Truth) and sync bidirectionally.
@DataClassName('CashRegister')
class CashRegisters extends Table {
  @override
  String get tableName => 'cash_registers';

  /// Primary Key â€” UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT).
  TextColumn get branchId => text().named('branch_id')();

  /// Foreign Key linking to register operating currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Display name of the cash register (e.g., Main POS Counter 1).
  TextColumn get registerName => text().named('register_name')();

  /// Operational shift status (`Open` or `Closed`).
  TextColumn get status =>
      text().named('status').withDefault(const Constant('Closed'))();

  /// Current live cash balance (`decimal(15,4)`).
  RealColumn get currentBalance =>
      real().named('current_balance').withDefault(const Constant(0.0))();

  /// Foreign Key linking to the user who created the register (`users.id`, SET NULL).
  TextColumn get createdBy => text()
      .named('created_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Foreign Key linking to the user who last updated the register (`users.id`, SET NULL).
  TextColumn get updatedBy => text()
      .named('updated_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the cash register record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, registerName},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Open\', \'Closed\'))',
  ];
}

