import 'package:drift/drift.dart';
import '../enums/inventory_transaction_status.dart';

/// Drift TypeConverter for [InventoryTransactionStatus] enum to/from String.
class InventoryTransactionStatusConverter
    extends TypeConverter<InventoryTransactionStatus, String> {
  const InventoryTransactionStatusConverter();

  @override
  InventoryTransactionStatus fromSql(String fromDb) =>
      InventoryTransactionStatus.fromValue(fromDb);

  @override
  String toSql(InventoryTransactionStatus value) => value.value;
}
