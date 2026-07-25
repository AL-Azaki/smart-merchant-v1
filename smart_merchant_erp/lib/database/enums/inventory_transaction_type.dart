/// Inventory transaction type enum.
enum InventoryTransactionType {
  receipt('Receipt'),
  dispatch('Dispatch'),
  adjustmentIn('Adjustment In'),
  adjustmentOut('Adjustment Out'),
  openingBalance('Opening Balance');

  final String value;
  const InventoryTransactionType(this.value);

  static InventoryTransactionType fromValue(String value) {
    return InventoryTransactionType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InventoryTransactionType.adjustmentIn,
    );
  }
}
