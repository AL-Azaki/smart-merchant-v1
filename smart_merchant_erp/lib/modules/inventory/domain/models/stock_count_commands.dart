class SaveStockCountItemCommand {
  final String productId;
  final String productUnitId;
  final double expectedQuantity;
  final double countedQuantity;
  final double differenceQuantity;

  SaveStockCountItemCommand({
    required this.productId,
    required this.productUnitId,
    required this.expectedQuantity,
    required this.countedQuantity,
    required this.differenceQuantity,
  });
}

class SaveStockCountCommand {
  final String? id; // null if new
  final String warehouseId;
  final String? notes;
  final List<SaveStockCountItemCommand> items;

  SaveStockCountCommand({
    required this.warehouseId, required this.items, this.id,
    this.notes,
  });
}
