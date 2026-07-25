import 'package:drift/drift.dart';
import '../../converters/inventory_transfer_status_converter.dart';
import '../../enums/inventory_transfer_status.dart';

/// Drift table definition for `inventory_transfers`.
///
/// Purpose: Header for stock transfer between warehouses within the same business.
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as warehouse transfers occur locally across branch devices and require bidirectional cloud sync.
@DataClassName('InventoryTransfer')
class InventoryTransfers extends Table {
  @override
  String get tableName => 'inventory_transfers';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to source `warehouses.id` (RESTRICT).
  TextColumn get fromWarehouseId => text()
      .named('from_warehouse_id')
      .customConstraint(
        'NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT',
      )();

  /// Foreign Key linking to destination `warehouses.id` (RESTRICT).
  TextColumn get toWarehouseId => text()
      .named('to_warehouse_id')
      .customConstraint(
        'NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT',
      )();

  /// Unique human-readable transfer document number within the business.
  TextColumn get transferNumber => text().named('transfer_number')();

  /// Date and time when the transfer was initiated (default `CURRENT_TIMESTAMP`).
  DateTimeColumn get transferDate =>
      dateTime().named('transfer_date').withDefault(currentDateAndTime)();

  /// Workflow state (`Pending`, `Completed`, `Cancelled`) mapped to `InventoryTransferStatus` enum.
  TextColumn get status => text()
      .map(const InventoryTransferStatusConverter())
      .withDefault(const Constant('Pending'))();

  /// Optional notes or comments regarding the stock transfer.
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to `users.id` indicating who created the transfer (RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

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

  /// Identifier of the device where the transfer record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, transferNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, from_warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, to_warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'CHECK (status IN (\'Pending\', \'Completed\', \'Cancelled\'))',
    'CHECK (from_warehouse_id != to_warehouse_id)',
  ];
}
