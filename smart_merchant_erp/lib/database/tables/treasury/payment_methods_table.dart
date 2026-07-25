import 'package:drift/drift.dart';

/// Drift table definition for `payment_methods`.
///
/// Purpose: Payment method definitions linked to a chart of account (e.g., Cash, Bank, Card, DigitalWallet).
/// Domain: DOMAIN 4 — FINANCE (Structure & Cash/Bank)
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as payment methods direct all POS receipts and treasury payouts locally in SQLite (Source of Truth) and sync bidirectionally.
@DataClassName('PaymentMethod')
class PaymentMethods extends Table {
  @override
  String get tableName => 'payment_methods';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE RESTRICT',
      )();

  /// Composite Foreign Key linking to `chart_of_accounts(business_id, id)` (RESTRICT).
  TextColumn get chartOfAccountId => text().named('chart_of_account_id')();

  /// Unique short identifier code for the payment method (e.g., CASH-01, POS-CARD).
  TextColumn get methodCode => text().named('method_code')();

  /// Descriptive name of the payment method.
  TextColumn get methodName => text().named('method_name')();

  /// Classification type (`Cash`, `Bank`, `Card`, `DigitalWallet`, `Other`).
  TextColumn get paymentType => text().named('payment_type')();

  /// Active operational flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  // --- Offline-First Sync Metadata Columns ---

  /// Offline sync status tracking (`sync_status`).
  TextColumn get syncStatus =>
      text().named('sync_status').withDefault(const Constant('pending'))();

  /// Local record modification version counter (`version`).
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Identifier of the device where the payment method record was created or modified (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, methodCode},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (business_id, chart_of_account_id) REFERENCES chart_of_accounts(business_id, id) ON DELETE RESTRICT',
    'CHECK (payment_type IN (\'Cash\', \'Bank\', \'Card\', \'DigitalWallet\', \'Other\'))',
  ];
}
