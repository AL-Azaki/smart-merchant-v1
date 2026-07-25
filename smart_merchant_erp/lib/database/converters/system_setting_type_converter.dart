import 'package:drift/drift.dart';
import '../enums/system_setting_type.dart';

/// Drift TypeConverter for [SystemSettingType] enum to/from String.
class SystemSettingTypeConverter
    extends TypeConverter<SystemSettingType, String> {
  const SystemSettingTypeConverter();

  @override
  SystemSettingType fromSql(String fromDb) =>
      SystemSettingType.fromValue(fromDb);

  @override
  String toSql(SystemSettingType value) => value.value;
}
