import 'package:drift/drift.dart';
import '../enums/inventory_transaction_type.dart';

/// Drift TypeConverter for [InventoryTransactionType] enum to/from String.
class InventoryTransactionTypeConverter
    extends TypeConverter<InventoryTransactionType, String> {
  const InventoryTransactionTypeConverter();

  @override
  InventoryTransactionType fromSql(String fromDb) =>
      InventoryTransactionType.fromValue(fromDb);

  @override
  String toSql(InventoryTransactionType value) => value.value;
}
