class SalesItem {
  final double quantity;
  final double unitPrice;
  final double discountAmount; // Line discount
  final double taxRate; // e.g. 0.15 for 15% VAT

  SalesItem({
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    this.taxRate = 0,
  });
}

class InvoiceTotals {
  final double rawSubtotal;
  final double totalDiscount;
  final double taxableAmount;
  final double taxTotal;
  final double grandTotal;

  InvoiceTotals({
    required this.rawSubtotal,
    required this.totalDiscount,
    required this.taxableAmount,
    required this.taxTotal,
    required this.grandTotal,
  });
}

class SalesCalculator {
  // ⚠️ CRITICAL FIX: Floating Point Precision 
  // Dart (and JS) uses Double Precision IEEE 754.
  // 10.99 * 3 in code equals 32.970000000000006.
  // This causes database drift in accounting. We MUST round to cents at every mathematical step.
  static double _roundToCents(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static InvoiceTotals calculate({
    required List<SalesItem> items,
    double globalDiscountValue = 0,
    bool isGlobalDiscountPercentage = false,
  }) {
    double rawSubtotal = 0;
    double itemsDiscountTotal = 0;
    
    // 1. Calculate Line Items
    for (var item in items) {
      double lineGross = _roundToCents(item.quantity * item.unitPrice);
      rawSubtotal += lineGross;
      itemsDiscountTotal += item.discountAmount;
    }
    
    rawSubtotal = _roundToCents(rawSubtotal);
    itemsDiscountTotal = _roundToCents(itemsDiscountTotal);

    // 2. Net Subtotal before global discount
    double netSubtotal = _roundToCents(rawSubtotal - itemsDiscountTotal);

    // 3. Global Discount Calculation
    double globalDiscountAmount = 0;
    if (isGlobalDiscountPercentage) {
      globalDiscountAmount = _roundToCents(netSubtotal * (globalDiscountValue / 100));
    } else {
      globalDiscountAmount = globalDiscountValue;
    }
    
    // Ensure discount doesn't exceed net subtotal
    if (globalDiscountAmount > netSubtotal) {
      globalDiscountAmount = netSubtotal;
    }

    double totalDiscount = _roundToCents(itemsDiscountTotal + globalDiscountAmount);
    
    // 4. Taxable Amount (Amount subject to Tax)
    double taxableAmount = _roundToCents(rawSubtotal - totalDiscount);
    
    // 5. Tax Calculation (Legal Compliance Fix)
    // Tax MUST be calculated AFTER discounts are applied.
    // If items have different taxes, we must distribute the global discount proportionally.
    double taxTotal = 0;
    for (var item in items) {
      double lineGross = _roundToCents(item.quantity * item.unitPrice);
      double lineNet = _roundToCents(lineGross - item.discountAmount);
      
      // Distribute global discount proportionally to this line to calculate accurate tax
      double lineWeight = netSubtotal > 0 ? (lineNet / netSubtotal) : 0;
      double lineGlobalDiscount = _roundToCents(globalDiscountAmount * lineWeight);
      
      double lineTaxable = _roundToCents(lineNet - lineGlobalDiscount);
      double lineTax = _roundToCents(lineTaxable * item.taxRate);
      taxTotal += lineTax;
    }
    
    taxTotal = _roundToCents(taxTotal);
    
    // 6. Grand Total
    double grandTotal = _roundToCents(taxableAmount + taxTotal);

    return InvoiceTotals(
      rawSubtotal: rawSubtotal,
      totalDiscount: totalDiscount,
      taxableAmount: taxableAmount,
      taxTotal: taxTotal,
      grandTotal: grandTotal,
    );
  }
}
