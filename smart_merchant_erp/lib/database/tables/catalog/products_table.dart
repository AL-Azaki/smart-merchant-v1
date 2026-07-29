import 'package:drift/drift.dart';

/// Drift table definition for `products`.
///
/// Purpose: Master product definitions with category, brand, and tax linkage.
/// Domain: DOMAIN 2 — CATALOG
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as products are created and managed locally inside Flutter SQLite (Source of Truth) and synced bidirectionally.
@DataClassName('Product')
class Products extends Table {
  @override
  String get tableName => 'products';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `categories(business_id, id)` (RESTRICT).
  TextColumn get categoryId => text().named('category_id').nullable()();

  /// Composite Foreign Key linking to `brands(business_id, id)` (RESTRICT).
  TextColumn get brandId => text().named('brand_id').nullable()();

  /// Reference to default applied tax (`taxes.id`, nullable UUID string).
  TextColumn get taxId => text().named('tax_id').nullable()();

  /// Foreign Key linking to default pricing currency (`currencies.id`, RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .nullable()
      .customConstraint(
        'REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Product type classification (`standard`, `service`, `composite`).
  TextColumn get productType =>
      text().named('product_type').withDefault(const Constant('standard'))();

  /// Unique internal item reference code within the business.
  TextColumn get productCode => text().named('product_code')();

  /// Item full descriptive display name.
  TextColumn get productName => text().named('product_name')();

  /// Detailed product notes or description.
  TextColumn get description => text().nullable()();

  /// Operational activity status flag.
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// Storefront visibility flag.
  BoolColumn get showInStore =>
      boolean().named('show_in_store').withDefault(const Constant(false))();

  /// Record creation timestamp.
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  /// Record last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  /// Soft delete timestamp (`deleted_at`).
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the product record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, productCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, category_id) REFERENCES categories(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, brand_id) REFERENCES brands(business_id, id) ON DELETE RESTRICT',
    'CHECK (product_type IN (\'standard\', \'service\', \'composite\'))',
  ];
}
