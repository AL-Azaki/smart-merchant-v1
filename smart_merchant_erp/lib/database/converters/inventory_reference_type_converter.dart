import 'package:drift/drift.dart';
import '../enums/inventory_reference_type.dart';

/// Drift TypeConverter for [InventoryReferenceType] enum to/from String.
class InventoryReferenceTypeConverter
    extends TypeConverter<InventoryReferenceType, String> {
  const InventoryReferenceTypeConverter();

  @override
  InventoryReferenceType fromSql(String fromDb) =>
      InventoryReferenceType.fromValue(fromDb);

  @override
  String toSql(InventoryReferenceType value) => value.value;
}
