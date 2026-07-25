import 'package:drift/drift.dart';

/// Drift ORM table definition for `orders` (Domain 5 - Sales).
///
/// Sales orders from channels, optionally linked to a customer.
@DataClassName('OrderEntity')
class Orders extends Table {
  @override
  String get tableName => 'orders';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `branches(business_id, id)` (RESTRICT).
  TextColumn get branchId => text().named('branch_id')();

  /// Composite Foreign Key linking to `channels(business_id, id)` (RESTRICT).
  TextColumn get channelId => text().named('channel_id')();

  /// Composite Foreign Key linking to `customers(business_id, id)` (RESTRICT).
  TextColumn get customerId => text().named('customer_id').nullable()();

  /// Order human-readable reference number (`string(50)`).
  TextColumn get orderNumber =>
      text().named('order_number').withLength(min: 1, max: 50)();

  /// Date and time when the order was placed (`timestamp`).
  DateTimeColumn get orderDate =>
      dateTime().named('order_date').withDefault(currentDateAndTime)();

  /// Foreign Key linking to `currencies.id` (RESTRICT).
  TextColumn get currencyId => text()
      .named('currency_id')
      .customConstraint(
        'NOT NULL REFERENCES currencies(id) ON DELETE RESTRICT',
      )();

  /// Currency exchange rate at the time of order (`decimal(18,8)`).
  RealColumn get exchangeRate =>
      real().named('exchange_rate').withDefault(const Constant(1.0))();

  /// Subtotal amount before discount and tax (`decimal(18,2)`).
  RealColumn get subTotal =>
      real().named('sub_total').withDefault(const Constant(0.00))();

  /// Total discount amount applied (`decimal(18,2)`).
  RealColumn get discountTotal =>
      real().named('discount_total').withDefault(const Constant(0.00))();

  /// Total tax amount applied (`decimal(18,2)`).
  RealColumn get taxTotal =>
      real().named('tax_total').withDefault(const Constant(0.00))();

  /// Final total order amount (`decimal(18,2)`).
  RealColumn get grandTotal =>
      real().named('grand_total').withDefault(const Constant(0.00))();

  /// Subtotal amount converted to the base currency (`decimal(18,2)`).
  RealColumn get baseSubTotal =>
      real().named('base_sub_total').withDefault(const Constant(0.00))();

  /// Total discount amount converted to the base currency (`decimal(18,2)`).
  RealColumn get baseDiscountTotal =>
      real().named('base_discount_total').withDefault(const Constant(0.00))();

  /// Total tax amount converted to the base currency (`decimal(18,2)`).
  RealColumn get baseTaxTotal =>
      real().named('base_tax_total').withDefault(const Constant(0.00))();

  /// Final grand total amount converted to the base currency (`decimal(18,2)`).
  RealColumn get baseGrandTotal =>
      real().named('base_grand_total').withDefault(const Constant(0.00))();

  /// Payment status (`Unpaid`, `Partial`, or `Paid`).
  TextColumn get paymentStatus =>
      text().named('payment_status').withDefault(const Constant('Unpaid'))();

  /// Order lifecycle status (`Pending`, `Confirmed`, `Shipped`, `Delivered`, `Cancelled`).
  TextColumn get status => text().withDefault(const Constant('Pending'))();

  /// Free-form notes (`text`).
  TextColumn get notes => text().nullable()();

  /// Foreign Key linking to `users.id` (`created_by`, SET NULL).
  TextColumn get createdBy => text()
      .named('created_by')
      .nullable()
      .customConstraint('NULL REFERENCES users(id) ON DELETE SET NULL')();

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
    {businessId, orderNumber},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, branch_id) REFERENCES branches(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, channel_id) REFERENCES channels(business_id, id) ON DELETE RESTRICT',
    'FOREIGN KEY (business_id, customer_id) REFERENCES customers(business_id, id) ON DELETE RESTRICT',
  ];
}
