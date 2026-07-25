/// Inventory movement direction enum.
enum InventoryMovementDirection {
  inbound('IN'),
  outbound('OUT');

  final String value;
  const InventoryMovementDirection(this.value);

  static InventoryMovementDirection fromValue(String value) {
    return InventoryMovementDirection.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InventoryMovementDirection.inbound,
    );
  }
}
