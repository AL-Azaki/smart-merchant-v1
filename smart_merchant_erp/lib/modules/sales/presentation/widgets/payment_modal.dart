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

    final remaining = (total - cashAmount).clamp(0.0, double.infinity);
    final isOverpaid = cashAmount > total;
    final changeAmount = isOverpaid ? (cashAmount - total) : 0.0;

    final bool hasCredit = remaining > 0;
    final bool isValidToPay = !hasCredit || (hasCredit && posState.customerName != null);

    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return AppModalSheet(
      title: 'الدفع والإصدار',
      icon: Icons.credit_card_outlined,
      iconColor: AppColors.primary,
      onClose: () => Navigator.pop(context),
      primaryLabel: 'تأكيد وإصدار الفاتورة',
      onPrimary: (!isValidToPay || posState.isSubmitting)
          ? null
          : () {
              ref.read(posNotifierProvider.notifier).submitSale(
                    cashReceived: cashAmount,
                    paymentMethodId: 'CASH',
                  );
            },
      isLoading: posState.isSubmitting,
      maxHeightFactor: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Card
          AppCard(
            padding: const EdgeInsets.all(12),
            backgroundColor: posState.customerName == null && hasCredit
                ? AppColors.error.withValues(alpha: 0.08)
                : null,
            borderColor: posState.customerName == null && hasCredit
                ? AppColors.error
                : borderColor,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: posState.customerName != null ? AppColors.success : textSecondary,
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
                          'يجب اختيار عميل للبيع الآجل',
                          style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                if (posState.customerName == null)
                  TextButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const CustomerAddModal(),
                      );
                    },
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('إضافة عميل', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cash Input
          AppNumberField(
            label: 'المبلغ المدفوع (نقداً)',
            hint: total.toStringAsFixed(2),
            controller: _cashController,
            suffixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('YER', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            onChanged: (val) {
              setState(() => cashAmount = double.tryParse(val) ?? 0);
            },
          ),
          const SizedBox(height: 16),

          // Calculation Card
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
                    const Text('المتبقي (آجل):', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '${remaining.toStringAsFixed(2)} YER',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الباقي للعميل (صرف):', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '${changeAmount.toStringAsFixed(2)} YER',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Card
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملخص الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع الفرعي', style: TextStyle(color: textSecondary, fontSize: 12)),
                    Text('${posState.totals.rawSubtotal.toStringAsFixed(2)} YER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الضريبة (15%)', style: TextStyle(color: textSecondary, fontSize: 12)),
                    Text('${posState.totals.taxTotal.toStringAsFixed(2)} YER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الإجمالي المطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    Text(
                      '${total.toStringAsFixed(2)} YER',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
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
}
