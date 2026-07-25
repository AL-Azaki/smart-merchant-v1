import 'package:drift/drift.dart';

/// Drift ORM table definition for `channels` (Domain 5 - Sales).
///
/// Sales channel definitions (POS, Ecommerce, B2B, etc.).
@DataClassName('ChannelEntity')
class Channels extends Table {
  @override
  String get tableName => 'channels';

  /// Primary key (`uuid`).
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (CASCADE).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Channel name (`string(100)`).
  TextColumn get channelName =>
      text().named('channel_name').withLength(min: 1, max: 100)();

  /// Channel code (`string(50)`).
  TextColumn get channelCode =>
      text().named('channel_code').withLength(min: 1, max: 50)();

  /// Channel classification/type (`string(50)`, check: POS, Ecommerce, B2B, Marketplace, Other).
  TextColumn get channelType =>
      text().named('channel_type').withLength(min: 1, max: 50)();

  /// Operational activity status flag (`is_active`).
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

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
    {businessId, channelCode},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (channel_type IN (\'POS\', \'Ecommerce\', \'B2B\', \'Marketplace\', \'Other\'))',
  ];
}
