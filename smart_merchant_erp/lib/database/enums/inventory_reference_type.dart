/// Inventory reference document type enum.
enum InventoryReferenceType {
  salesInvoice('SalesInvoice'),
  salesReturn('SalesReturn'),
  purchaseInvoice('PurchaseInvoice'),
  purchaseReturn('PurchaseReturn'),
  transfer('Transfer'),
  adjustment('Adjustment');

  final String value;
  const InventoryReferenceType(this.value);

  static InventoryReferenceType fromValue(String value) {
    return InventoryReferenceType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => InventoryReferenceType.adjustment,
    );
  }
}
