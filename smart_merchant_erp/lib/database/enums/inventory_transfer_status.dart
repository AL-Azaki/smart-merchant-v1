/// Inventory transfer lifecycle status enum.
enum InventoryTransferStatus {
  pending('Pending'),
  completed('Completed'),
  cancelled('Cancelled');

  final String value;
  const InventoryTransferStatus(this.value);

  static InventoryTransferStatus fromValue(String value) {
    return InventoryTransferStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InventoryTransferStatus.pending,
    );
  }
}
