import 'package:drift/drift.dart';
import '../enums/inventory_movement_direction.dart';

/// Drift TypeConverter for [InventoryMovementDirection] enum to/from String.
class InventoryMovementDirectionConverter
    extends TypeConverter<InventoryMovementDirection, String> {
  const InventoryMovementDirectionConverter();

  @override
  InventoryMovementDirection fromSql(String fromDb) =>
      InventoryMovementDirection.fromValue(fromDb);

  @override
  String toSql(InventoryMovementDirection value) => value.value;
}
