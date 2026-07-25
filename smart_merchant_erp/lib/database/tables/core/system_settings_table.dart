import 'package:drift/drift.dart';
import '../../converters/json_converter.dart';
import '../../converters/system_setting_type_converter.dart';
import '../../enums/system_setting_type.dart';

/// Drift table definition for `system_settings`.
///
/// Purpose: Key-value system configuration store per business with JSONB type-safe storage.
/// Domain: DOMAIN 8 — EXTENDED DOMAINS
/// Database Owner: SQLite (ERP)
/// Offline Metadata: Requires sync tracking columns (`sync_status`, `version`, `device_id`)
/// as configuration can be modified locally across branches and synced bidirectionally.
@DataClassName('SystemSetting')
class SystemSettings extends Table {
  @override
  String get tableName => 'system_settings';

  /// Primary Key — UUID string stored as TEXT.
  TextColumn get id => text()();

  /// Foreign Key linking to `businesses.id` (RESTRICT/CASCADE per extraction).
  TextColumn get businessId => text()
      .named('business_id')
      .customConstraint(
        'NOT NULL REFERENCES businesses(id) ON DELETE CASCADE',
      )();

  /// Configuration setting key string (e.g., `default_tax_rate`).
  TextColumn get settingKey => text().named('setting_key')();

  /// Configuration setting value stored as JSON string in SQLite, converted to Map/List in Dart.
  TextColumn get settingValue =>
      text().named('setting_value').map(const JsonConverter()).nullable()();

  /// Data type classification of the setting value (`string`, `integer`, `boolean`, `json`).
  TextColumn get settingType => text()
      .named('setting_type')
      .map(const SystemSettingTypeConverter())
      .withDefault(const Constant('string'))();

  /// Visibility flag indicating if the setting is publicly exposed or restricted.
  BoolColumn get isPublic =>
      boolean().named('is_public').withDefault(const Constant(false))();

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

  /// Identifier of the device where the setting record was created or last mutated (`device_id`).
  TextColumn get deviceId => text().named('device_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {businessId, id},
    {businessId, settingKey},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (setting_type IN (\'string\', \'integer\', \'boolean\', \'json\'))',
  ];
}
