import 'package:drift/drift.dart';
import '../enums/inventory_transfer_status.dart';

/// Drift TypeConverter for [InventoryTransferStatus] enum to/from String.
class InventoryTransferStatusConverter
    extends TypeConverter<InventoryTransferStatus, String> {
  const InventoryTransferStatusConverter();

  @override
  InventoryTransferStatus fromSql(String fromDb) =>
      InventoryTransferStatus.fromValue(fromDb);

  @override
  String toSql(InventoryTransferStatus value) => value.value;
}
