import 'package:drift/drift.dart';
import '../../converters/inventory_movement_direction_converter.dart';
import '../../converters/inventory_reference_type_converter.dart';
import '../../converters/inventory_transaction_status_converter.dart';
import '../../converters/inventory_transaction_type_converter.dart';
import '../../enums/inventory_movement_direction.dart';
import '../../enums/inventory_reference_type.dart';
import '../../enums/inventory_transaction_status.dart';
import '../../enums/inventory_transaction_type.dart';

/// Drift table definition for `inventory_transactions`.
///
/// Purpose: Header record for inventory movements (receipts, dispatches, adjustments, opening balances).
/// Domain: DOMAIN 3 — INVENTORY
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as inventory transactions are generated continuously on local POS/branches and synced bidirectionally.
@DataClassName('InventoryTransaction')
class InventoryTransactions extends Table {
  @override
  String get tableName => 'inventory_transactions';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT).
  TextColumn get branchId => text()
      .named('branch_id')
      .customConstraint(
        'NOT NULL REFERENCES branches(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `warehouses(business_id, id)` (RESTRICT).
  TextColumn get warehouseId => text()
      .named('warehouse_id')
      .customConstraint(
        'NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT',
      )();

  /// Functional classification of stock movement mapped to `InventoryTransactionType` enum.
  TextColumn get transactionType => text()
      .named('transaction_type')
      .map(const InventoryTransactionTypeConverter())();

  /// Physical direction of stock flow (`IN`, `OUT`) mapped to `InventoryMovementDirection` enum.
  TextColumn get movementDirection => text()
      .named('movement_direction')
      .map(const InventoryMovementDirectionConverter())();

  /// Workflow state (`Draft`, `Posted`, `Reversed`) mapped to `InventoryTransactionStatus` enum.
  TextColumn get status => text()
      .map(const InventoryTransactionStatusConverter())
      .withDefault(const Constant('Draft'))();

  /// Polymorphic reference document type mapped to `InventoryReferenceType` enum (or NULL if standalone).
  TextColumn get referenceType => text()
      .named('reference_type')
      .map(const InventoryReferenceTypeConverter())
      .nullable()();

  /// Polymorphic reference document UUID (e.g., invoice UUID or transfer UUID).
  TextColumn get referenceId => text().named('reference_id').nullable()();

  /// Date and time when the inventory transaction occurred (default `CURRENT_TIMESTAMP`).
  DateTimeColumn get transactionDate =>
      dateTime().named('transaction_date').withDefault(currentDateAndTime)();

  /// Foreign Key linking to `users.id` indicating who created the transaction (RESTRICT).
  TextColumn get createdBy => text()
      .named('created_by')
      .customConstraint('NOT NULL REFERENCES users(id) ON DELETE RESTRICT')();

  /// Foreign Key linking to `users.id` indicating who posted the transaction (RESTRICT).
  TextColumn get postedBy => text()
      .named('posted_by')
      .customConstraint('REFERENCES users(id) ON DELETE RESTRICT')
      .nullable()();

  /// Timestamp when the transaction was posted.
  DateTimeColumn get postedAt => dateTime().named('posted_at').nullable()();

  /// Foreign Key linking to `users.id` indicating who reversed the transaction (RESTRICT).
  TextColumn get reversedBy => text()
      .named('reversed_by')
      .customConstraint('REFERENCES users(id) ON DELETE RESTRICT')
      .nullable()();

  /// Timestamp when the transaction was reversed.
  DateTimeColumn get reversedAt => dateTime().named('reversed_at').nullable()();

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

  /// Identifier of the device where the transaction record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, warehouse_id) REFERENCES warehouses(business_id, id) ON DELETE RESTRICT',
    'CHECK (transaction_type IN (\'Receipt\', \'Dispatch\', \'Adjustment In\', \'Adjustment Out\', \'Opening Balance\'))',
    'CHECK (movement_direction IN (\'IN\', \'OUT\'))',
    'CHECK (status IN (\'Draft\', \'Posted\', \'Reversed\'))',
    'CHECK (reference_type IS NULL OR reference_type IN (\'SalesInvoice\', \'SalesReturn\', \'PurchaseInvoice\', \'PurchaseReturn\', \'Transfer\', \'Adjustment\'))',
  ];
}
