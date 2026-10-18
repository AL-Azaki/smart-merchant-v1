import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../providers/pos_provider.dart';
import 'customer_add_modal.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../shared/documents/printing/document_printer.dart';
import '../../../../shared/documents/sharing/document_share.dart';

enum PosPaymentMode { cash, bank, split }

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PosPaymentMode _mode = PosPaymentMode.cash;
  double _cashAmount = 0;
  double _bankAmount = 0;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final total = ref.read(posNotifierProvider).totals.grandTotal;
      setState(() {
        _cashAmount = total;
        _bankAmount = 0.0;
        _cashController.text = total.toStringAsFixed(2);
        _bankController.text = '0.00';
      });
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _switchMode(PosPaymentMode newMode, double total) {
    setState(() {
      _mode = newMode;
      if (newMode == PosPaymentMode.cash) {
        _cashAmount = total;
        _bankAmount = 0.0;
        _cashController.text = total.toStringAsFixed(2);
        _bankController.text = '0.00';
      } else if (newMode == PosPaymentMode.bank) {
        _cashAmount = 0.0;
        _bankAmount = total;
        _cashController.text = '0.00';
        _bankController.text = total.toStringAsFixed(2);
      } else {
        // Split mode: split 50/50 by default
        final half = (total / 2.0);
        _cashAmount = half;
        _bankAmount = total - half;
        _cashController.text = _cashAmount.toStringAsFixed(2);
        _bankController.text = _bankAmount.toStringAsFixed(2);
      }
    });
  }

  void _handlePrint(CommercialDocumentData doc) {
    DocumentPrinter.printDocument(doc);
  }

  void _handleShare(CommercialDocumentData doc) {
    DocumentShare.shareDocument(doc);
  }

  void _handleSaleSuccess(String invoiceId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final mapper = getIt<SalesInvoiceDocumentMapper>();
      final docData = await mapper.mapToDocumentData(invoiceId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessDialog(docData);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSuccessDialog(CommercialDocumentData docData) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم إتمام البيع بنجاح!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'رقم الفاتورة: ${docData.documentNumber}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePrint(docData),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('طباعة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleShare(docData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('مشاركة', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CommercialDocumentPreviewScreen(document: docData),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('عرض الفاتورة'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(posNotifierProvider.notifier).clearCart();
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                label: const Text('بيع جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posNotifierProvider);

    ref.listen<PosState>(posNotifierProvider, (previous, next) {
      if (previous?.error == null && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(posNotifierProvider.notifier).clearError();
      }
      if (previous?.successInvoiceId == null && next.successInvoiceId != null) {
        _handleSaleSuccess(next.successInvoiceId!);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = posState.totals.grandTotal;

    final double totalPaid = _mode == PosPaymentMode.cash
        ? _cashAmount
        : (_mode == PosPaymentMode.bank
            ? _bankAmount
            : (_cashAmount + _bankAmount));

    final remaining = (total - totalPaid).clamp(0.0, double.infinity);
    final isOverpaid = totalPaid > total;
    final changeAmount = isOverpaid ? (totalPaid - total) : 0.0;

    final bool hasCredit = remaining > 0.001;
    final bool isValidToPay = (!hasCredit || (hasCredit && posState.customerName != null)) &&
        (totalPaid > 0.001 || posState.customerName != null);

    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return AppModalSheet(
      title: 'الدفع والإصدار',
      icon: Icons.payments_outlined,
      iconColor: AppColors.primary,
      onClose: () => Navigator.pop(context),
      primaryLabel: 'تأكيد وإصدار الفاتورة',
      onPrimary: (!isValidToPay || posState.isSubmitting)
          ? null
          : () {
              final String methodId = _mode == PosPaymentMode.cash
                  ? 'CASH'
                  : (_mode == PosPaymentMode.bank ? 'BANK' : 'SPLIT');

              final double finalCash =
                  _mode == PosPaymentMode.bank ? 0.0 : _cashAmount;
              final double finalBank =
                  _mode == PosPaymentMode.cash ? 0.0 : _bankAmount;

              ref.read(posNotifierProvider.notifier).submitSale(
                    cashReceived: finalCash,
                    bankReceived: finalBank,
                    paymentMethodId: methodId,
                  );
            },
      isLoading: posState.isSubmitting,
      maxHeightFactor: 0.94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Customer Card
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            backgroundColor: posState.customerName == null && hasCredit
                ? AppColors.error.withValues(alpha: 0.08)
                : null,
            borderColor: posState.customerName == null && hasCredit
                ? AppColors.error
                : borderColor,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  color: posState.customerName != null ? AppColors.success : textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        posState.customerName ?? 'عميل نقدي (كاش)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                      ),
                      if (posState.customerName == null && hasCredit)
                        const Text(
                          'يجب اختيار عميل مسجل لتسجيل المتبقي كآجل',
                          style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => CustomerAddModal.show(context),
                  icon: Icon(
                    posState.customerName == null ? Icons.person_add_outlined : Icons.swap_horiz_rounded,
                    size: 16,
                  ),
                  label: Text(
                    posState.customerName == null ? 'إضافة عميل' : 'تغيير',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Compact Payment Mode Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildModeButton(
                  title: 'نقداً',
                  icon: Icons.money_rounded,
                  mode: PosPaymentMode.cash,
                  total: total,
                ),
                _buildModeButton(
                  title: 'شبكة / بنك',
                  icon: Icons.credit_card_rounded,
                  mode: PosPaymentMode.bank,
                  total: total,
                ),
                _buildModeButton(
                  title: 'دفع متعدد',
                  icon: Icons.call_split_rounded,
                  mode: PosPaymentMode.split,
                  total: total,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Amount Inputs based on Mode
          if (_mode == PosPaymentMode.cash) ...[
            AppNumberField(
              label: 'المبلغ المدفوع نقداً',
              hint: total.toStringAsFixed(2),
              controller: _cashController,
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    posState.currencyId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() => _cashAmount = double.tryParse(val) ?? 0);
              },
            ),
          ] else if (_mode == PosPaymentMode.bank) ...[
            AppNumberField(
              label: 'المبلغ المدفوع شبكة / بطاقة',
              hint: total.toStringAsFixed(2),
              controller: _bankController,
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    posState.currencyId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() => _bankAmount = double.tryParse(val) ?? 0);
              },
            ),
          ] else ...[
            // Split mode: Two clean, side-by-side or stacked fields
            Row(
              children: [
                Expanded(
                  child: AppNumberField(
                    label: 'المدفوع نقداً',
                    hint: '0.00',
                    controller: _cashController,
                    onChanged: (val) {
                      setState(() => _cashAmount = double.tryParse(val) ?? 0);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppNumberField(
                    label: 'المدفوع شبكة',
                    hint: '0.00',
                    controller: _bankController,
                    onChanged: (val) {
                      setState(() => _bankAmount = double.tryParse(val) ?? 0);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionChip(
                  label: const Text('مناصفة 50/50', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final half = total / 2;
                    setState(() {
                      _cashAmount = half;
                      _bankAmount = total - half;
                      _cashController.text = _cashAmount.toStringAsFixed(2);
                      _bankController.text = _bankAmount.toStringAsFixed(2);
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // 4. Financial Calculation Card (Live Balance)
          AppCard(
            padding: const EdgeInsets.all(14),
            backgroundColor: remaining > 0
                ? AppColors.error.withValues(alpha: 0.05)
                : AppColors.success.withValues(alpha: 0.05),
            borderColor: remaining > 0
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.success.withValues(alpha: 0.2),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي المدفوع:',
                      style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalPaid.toStringAsFixed(2)} ${posState.currencyId}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                  ],
                ),
                const Divider(height: 14),
                if (remaining > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المتبقي (آجل على العميل):',
                        style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${remaining.toStringAsFixed(2)} ${posState.currencyId}',
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                if (changeAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الباقي للعميل (صرف نقدي):',
                        style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${changeAmount.toStringAsFixed(2)} ${posState.currencyId}',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                if (remaining <= 0 && changeAmount <= 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'حالة الفاتورة:',
                        style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'مدفوعة بالكامل',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Clean Invoice Summary (No Tax!)
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع الفرعي', style: TextStyle(color: textSecondary, fontSize: 13)),
                    Text(
                      '${posState.totals.rawSubtotal.toStringAsFixed(2)} ${posState.currencyId}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                    ),
                  ],
                ),
                if (posState.totals.totalDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي الخصم', style: TextStyle(color: textSecondary, fontSize: 13)),
                      Text(
                        '-${posState.totals.totalDiscount.toStringAsFixed(2)} ${posState.currencyId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي المطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                    Text(
                      '${total.toStringAsFixed(2)} ${posState.currencyId}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required IconData icon,
    required PosPaymentMode mode,
    required double total,
  }) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode, total),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
