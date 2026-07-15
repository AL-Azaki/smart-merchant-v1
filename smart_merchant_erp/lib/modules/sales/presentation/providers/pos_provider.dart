import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/sales_calculator.dart';

part 'pos_provider.g.dart';

// النموذج الخاص بعنصر السلة داخل واجهة الكاشير
class PosCartItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final double taxRate;

  PosCartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.taxRate = 0,
  });

  PosCartItem copyWith({double? quantity}) {
    return PosCartItem(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      taxRate: taxRate,
    );
  }
}

// حالة نقطة البيع (تحتوي على السلة وإجمالي الحسابات الدقيقة والعميل)
class PosState {
  final List<PosCartItem> cart;
  final InvoiceTotals totals;
  final String? customerName; // لدعم الدفع الآجل (يجب اختيار عميل)

  PosState({required this.cart, required this.totals, this.customerName});
  
  factory PosState.initial() {
    return PosState(
      cart: [],
      totals: InvoiceTotals(rawSubtotal: 0, totalDiscount: 0, taxableAmount: 0, taxTotal: 0, grandTotal: 0),
      customerName: null,
    );
  }
}

// العقل المدبر للحالة (ViewModel)
@riverpod
class PosNotifier extends _$PosNotifier {
  @override
  PosState build() {
    return PosState.initial(); // يبدأ بسلة فارغة ومجاميع صفرية
  }

  // إضافة منتج للسلة (أو زيادة كميته إذا كان موجوداً مسبقاً)
  void addProduct({required String id, required String name, required double price, double taxRate = 0.15}) {
    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere((item) => item.id == id);

    if (existingIndex >= 0) {
      // زيادة الكمية بدلاً من إضافة صف جديد
      final existing = currentCart[existingIndex];
      currentCart[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      // إضافة منتج جديد
      currentCart.add(PosCartItem(id: id, name: name, quantity: 1, unitPrice: price, taxRate: taxRate));
    }

    _recalculate(currentCart);
  }

  void updateQuantity(String id, double newQuantity) {
    if (newQuantity <= 0) {
      final currentCart = state.cart.where((item) => item.id != id).toList();
      _recalculate(currentCart);
      return;
    }
    
    final currentCart = List<PosCartItem>.from(state.cart);
    final existingIndex = currentCart.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      final existing = currentCart[existingIndex];
      currentCart[existingIndex] = existing.copyWith(quantity: newQuantity);
      _recalculate(currentCart);
    }
  }

  // إعادة الحساب فوراً باستخدام العقل المحاسبي الدقيق
  void _recalculate(List<PosCartItem> newCart) {
    // تحويل عناصر السلة إلى صيغة مقبولة للـ SalesCalculator
    final salesItems = newCart.map((c) => SalesItem(
      quantity: c.quantity,
      unitPrice: c.unitPrice,
      taxRate: c.taxRate,
    )).toList();

    // استدعاء العملية الحسابية الآمنة
    final totals = SalesCalculator.calculate(items: salesItems);
    
    // تحديث واجهة المستخدم فوراً بالنتائج الجديدة
    state = PosState(cart: newCart, totals: totals, customerName: state.customerName);
  }

  void setCustomer(String name) {
    state = PosState(cart: state.cart, totals: state.totals, customerName: name);
  }

  void clearCart() {
    state = PosState.initial();
  }
}
