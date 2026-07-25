/// System setting data type enum.
enum SystemSettingType {
  string('string'),
  integer('integer'),
  boolean('boolean'),
  json('json'),
  decimal('decimal');

  final String value;
  const SystemSettingType(this.value);

  static SystemSettingType fromValue(String value) {
    return SystemSettingType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => SystemSettingType.string,
    );
  }
}
