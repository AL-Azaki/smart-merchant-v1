import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../core/services/printing/receipt_printer.dart';
import '../../../../core/services/sharing/whatsapp_share.dart';
import '../providers/pos_provider.dart';

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  double cashAmount = 0;
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final total = ref.read(posNotifierProvider).totals.grandTotal;
      setState(() {
        cashAmount = total;
        _cashController.text = total.toStringAsFixed(2);
      });
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _handlePrint(PosState state) {
    ReceiptPrinter.printInvoice(
      invoiceNumber: 'INV-001',
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      customerName: state.customerName ?? 'عميل نقدي',
      items: state.cart.map((i) => {
        'name': i.name,
        'qty': i.quantity.toInt(),
        'total': i.quantity * i.unitPrice,
      }).toList(),
      total: state.totals.grandTotal,
      tax: state.totals.taxTotal,
      discount: state.totals.totalDiscount,
    );
  }

  void _handleShare(PosState state) {
    WhatsAppShare.shareInvoice(
      invoiceNumber: 'INV-001',
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      customerName: state.customerName ?? 'عميل نقدي',
      items: state.cart.map((i) => {
        'name': i.name,
        'qty': i.quantity.toInt(),
        'total': i.quantity * i.unitPrice,
      }).toList(),
      total: state.totals.grandTotal,
    );
  }

  void _showSuccessDialog(PosState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('تم إتمام البيع بنجاح!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('رقم الفاتورة: INV-001', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePrint(state),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('طباعة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleShare(state),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('مشاركة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(posNotifierProvider.notifier).clearCart();
                  Navigator.of(ctx).pop(); 
                  Navigator.of(context).pop(); 
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                label: const Text('فاتورة جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = posState.totals.grandTotal;
    
    // قواعد الحسابات المالية (منع الدفع الآجل لغير المسجلين)
    final remaining = (total - cashAmount).clamp(0.0, double.infinity);
    final isOverpaid = cashAmount > total;
    final changeAmount = isOverpaid ? (cashAmount - total) : 0.0;
    
    // هل العميل مؤهل لدفع جزء من المبلغ فقط؟
    final bool hasCredit = remaining > 0;
    final bool isValidToPay = !hasCredit || (hasCredit && posState.customerName != null);

    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10)
        ]
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48, height: 6,
              decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text('الدفع والإصدار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          
          // Body (Responsive Layout)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                
                final paymentSection = _buildPaymentSection(posState, remaining, changeAmount, hasCredit, isValidToPay, isDark, textColor, textSecondary, borderColor);
                final summarySection = _buildSummarySection(posState, total, isDark, textColor, textSecondary, borderColor);
                
                if (isWide) {
                  // Tablet/Desktop Split View
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 1, child: summarySection),
                      Container(width: 1, color: borderColor),
                      Expanded(flex: 1, child: paymentSection),
                    ],
                  );
                } else {
                  // Mobile Scrollable View
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        summarySection,
                        Divider(height: 1, color: borderColor, thickness: 8), // Thick divider between sections on mobile
                        paymentSection,
                      ],
                    ),
                  );
                }
              }
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummarySection(PosState posState, double total, bool isDark, Color textColor, Color textSecondary, Color borderColor) {
    return Container(
      color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Allow shrink on mobile
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: textSecondary, size: 20),
                const SizedBox(width: 8),
                Text('ملخص الفاتورة', style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            // Cart Items
            ...posState.cart.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${item.name} × ${item.quantity.toInt()}', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Text('${(item.quantity * item.unitPrice).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: textColor)),
                ],
              ),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: borderColor),
            ),
            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المجموع الفرعي', style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${posState.totals.rawSubtotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الضريبة (15%)', style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${posState.totals.taxTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الإجمالي المطلوب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor)),
                  Text('${total.toStringAsFixed(2)} YER', style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(PosState posState, double remaining, double changeAmount, bool hasCredit, bool isValidToPay, bool isDark, Color textColor, Color textSecondary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Alert
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: posState.customerName == null && hasCredit ? AppColors.error.withValues(alpha: 0.1) : (isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)),
              border: Border.all(color: posState.customerName == null && hasCredit ? AppColors.error : borderColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: posState.customerName != null ? AppColors.success.withValues(alpha: 0.2) : borderColor, borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.person_rounded, color: posState.customerName != null ? AppColors.success : textSecondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posState.customerName ?? 'عميل نقدي (كاش)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      if (posState.customerName == null && hasCredit)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('لا يمكن تسجيل آجل لعميل غير مسجل', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Cash Input
          Text('المبلغ المدفوع (نقداً)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: _cashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFEFF6FF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Icon(Icons.payments_rounded, color: AppColors.primary, size: 32),
              ),
              suffixText: 'YER',
              suffixStyle: TextStyle(color: textSecondary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onChanged: (val) {
              setState(() => cashAmount = double.tryParse(val) ?? 0);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Direct Calculations (Remaining / Change)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: remaining > 0 ? AppColors.error.withValues(alpha: 0.05) : AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: remaining > 0 ? AppColors.error.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المتبقي (آجل):', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${remaining.toStringAsFixed(2)} YER', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الباقي للعميل (صرف):', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('${changeAmount.toStringAsFixed(2)} YER', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Confirm Button
          ElevatedButton(
            onPressed: !isValidToPay ? null : () {
              _showSuccessDialog(posState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: borderColor,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), // Premium pill shape
              elevation: isValidToPay ? 8 : 0,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            child: const Text('تأكيد وإصدار الفاتورة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 24), // Extra bottom padding
        ],
      ),
    );
  }
}
