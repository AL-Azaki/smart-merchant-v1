import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../providers/pos_provider.dart';
import 'customer_select_modal.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../shared/documents/printing/document_printer.dart';
import '../../../../shared/documents/sharing/document_share.dart';

enum PosPaymentMode { cash, bank, credit, split }

class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PosPaymentMode _mode = PosPaymentMode.cash;
  double _cashAmount = 0;
  double _bankAmount = 0;
  String _selectedBankWallet = 'kuraimi';
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();

  static const List<Map<String, dynamic>> _bankWalletList = [
    {
      'id': 'kuraimi',
      'name': 'الكريمي',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF1E40AF),
    },
    {
      'id': 'tadhamon',
      'name': 'التضامن',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF047857),
    },
    {
      'id': 'onecash',
      'name': 'ون كاش',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFD97706),
    },
    {
      'id': 'jawali',
      'name': 'جوالي',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'id': 'jeeb',
      'name': 'جيب',
      'icon': Icons.wallet_rounded,
      'color': Color(0xFFDC2626),
    },
    {
      'id': 'mada',
      'name': 'شبكة / مدى',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF0284C7),
    },
  ];

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
      } else if (newMode == PosPaymentMode.credit) {
        _cashAmount = 0.0;
        _bankAmount = 0.0;
        _cashController.text = '0.00';
        _bankController.text = '0.00';
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

  void _openCustomerSelect() {
    showDialog<void>(
      context: context,
      builder: (_) => const CustomerSelectModal(),
    );
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
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessDialog(docData);
    } catch (e) {
      if (!mounted) {
        return;
      }
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

  Widget _buildBankWalletSelector({
    required bool isDark,
    required Color borderColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'اختر البنك أو المحفظة الإلكترونية:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
            const Text(
              'اختياري لتحديد الوجهة',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
          ),
          itemCount: _bankWalletList.length,
          itemBuilder: (context, index) {
            final item = _bankWalletList[index];
            final isSelected = _selectedBankWallet == item['id'];
            final Color itemColor = item['color'] as Color;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedBankWallet = item['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? itemColor.withValues(alpha: isDark ? 0.22 : 0.08)
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? itemColor : borderColor,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: itemColor.withValues(alpha: 0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? itemColor
                            : itemColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : item['icon'] as IconData,
                        size: 13,
                        color: isSelected ? Colors.white : itemColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : itemColor)
                              : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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

    final isRegisteredCustomer = posState.customerName != null &&
        posState.customerName!.isNotEmpty &&
        posState.customerName != 'عميل نقدي';

    final double totalPaid = _mode == PosPaymentMode.cash
        ? _cashAmount
        : (_mode == PosPaymentMode.bank
            ? _bankAmount
            : (_mode == PosPaymentMode.credit
                ? 0.0
                : (_cashAmount + _bankAmount)));

    final remaining = (total - totalPaid).clamp(0.0, double.infinity);
    final isOverpaid = totalPaid > total;
    final changeAmount = isOverpaid ? (totalPaid - total) : 0.0;

    final bool hasCredit = _mode == PosPaymentMode.credit || remaining > 0.001;
    final bool isValidToPay = (!hasCredit || isRegisteredCustomer) &&
        (totalPaid > 0.001 || isRegisteredCustomer);

    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header (اسم المودال: «الدفع» فقط)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الدفع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'إغلاق',
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Customer Selection Card
                    InkWell(
                      onTap: _openCustomerSelect,
                      borderRadius: BorderRadius.circular(12),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        backgroundColor: !isRegisteredCustomer && hasCredit
                            ? AppColors.error.withValues(alpha: 0.08)
                            : null,
                        borderColor: !isRegisteredCustomer && hasCredit
                            ? AppColors.error
                            : borderColor,
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: isRegisteredCustomer ? AppColors.success : textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRegisteredCustomer
                                        ? posState.customerName!
                                        : 'عميل نقدي (كاش)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  if (!isRegisteredCustomer && hasCredit)
                                    const Text(
                                      'يجب اختيار عميل مسجل لتسجيل المتبقي كآجل',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isRegisteredCustomer) ...[
                              IconButton(
                                tooltip: 'إلغاء التحديد (عميل نقدي)',
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                onPressed: () {
                                  ref.read(posNotifierProvider.notifier).setCustomer('', 'عميل نقدي');
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            TextButton.icon(
                              onPressed: _openCustomerSelect,
                              icon: Icon(
                                isRegisteredCustomer ? Icons.swap_horiz_rounded : Icons.person_search_rounded,
                                size: 16,
                              ),
                              label: Text(
                                isRegisteredCustomer ? 'تغيير' : 'تحديد عميل',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // B. Payment Mode Selector (يشمل النقداً، الشبكة، الآجل، والدفع المتعدد/الجزئي)
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
                            title: 'شبكة / محفظة',
                            icon: Icons.credit_card_rounded,
                            mode: PosPaymentMode.bank,
                            total: total,
                          ),
                          _buildModeButton(
                            title: 'آجل',
                            icon: Icons.receipt_long_rounded,
                            mode: PosPaymentMode.credit,
                            total: total,
                          ),
                          _buildModeButton(
                            title: 'متعدد / جزئي',
                            icon: Icons.call_split_rounded,
                            mode: PosPaymentMode.split,
                            total: total,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // C. Payment Details according to Mode
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
                        label: 'المبلغ المدفوع شبكة / محفظة',
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
                      const SizedBox(height: 12),
                      // مربعات البنوك والمحافظ
                      _buildBankWalletSelector(
                        isDark: isDark,
                        borderColor: borderColor,
                        textColor: textColor,
                      ),
                    ] else if (_mode == PosPaymentMode.credit) ...[
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isRegisteredCustomer
                                    ? 'سيتم تسجيل كامل قيمة الفاتورة (${total.toStringAsFixed(2)} ${posState.currencyId}) كحساب آجل على العميل "${posState.customerName}".'
                                    : 'تنبيه: يجب اختيار عميل مسجل لتتمكن من تسجيل الفاتورة كآجل.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Split mode: cash & bank fields
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
                              label: 'المدفوع شبكة/محفظة',
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
                      const SizedBox(height: 10),
                      // مربعات البنوك والمحافظ
                      _buildBankWalletSelector(
                        isDark: isDark,
                        borderColor: borderColor,
                        textColor: textColor,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // D. Financial Calculation Card
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

                    // E. Clean Invoice Summary (No Tax!)
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
              ),
            ),

            // 3. Bottom Action Confirmation Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (!isValidToPay || posState.isSubmitting)
                      ? null
                      : () {
                          final String methodId = _mode == PosPaymentMode.cash
                              ? 'CASH'
                              : (_mode == PosPaymentMode.bank
                                  ? 'BANK'
                                  : (_mode == PosPaymentMode.credit
                                      ? 'CREDIT'
                                      : 'SPLIT'));

                          final double finalCash = (_mode == PosPaymentMode.bank || _mode == PosPaymentMode.credit)
                              ? 0.0
                              : _cashAmount;
                          final double finalBank = (_mode == PosPaymentMode.cash || _mode == PosPaymentMode.credit)
                              ? 0.0
                              : _bankAmount;

                          ref.read(posNotifierProvider.notifier).submitSale(
                                cashReceived: finalCash,
                                bankReceived: finalBank,
                                paymentMethodId: methodId,
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: posState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    posState.isSubmitting ? 'جاري المعالجة...' : 'تأكيد وإصدار الفاتورة',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                size: 15,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
