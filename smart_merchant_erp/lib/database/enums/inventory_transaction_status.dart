/// Inventory transaction lifecycle status enum.
enum InventoryTransactionStatus {
  draft('Draft'),
  posted('Posted'),
  reversed('Reversed');

  final String value;
  const InventoryTransactionStatus(this.value);

  static InventoryTransactionStatus fromValue(String value) {
    return InventoryTransactionStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InventoryTransactionStatus.draft,
    );
  }
}
