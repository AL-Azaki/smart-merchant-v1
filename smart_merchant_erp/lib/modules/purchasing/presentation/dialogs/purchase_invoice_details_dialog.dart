import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../accounting/presentation/widgets/payment_voucher_dialog.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../domain/repositories/purchasing_repository.dart';
import '../mappers/purchase_invoice_document_mapper.dart';
import '../widgets/purchase_return_modal.dart';

class PurchaseInvoiceDetailsDialog extends ConsumerStatefulWidget {
  final PurchaseInvoice invoice;
  final String supplierName;

  const PurchaseInvoiceDetailsDialog({
    super.key,
    required this.invoice,
    required this.supplierName,
  });

  @override
  ConsumerState<PurchaseInvoiceDetailsDialog> createState() =>
      _PurchaseInvoiceDetailsDialogState();
}

class _PurchaseInvoiceDetailsDialogState
    extends ConsumerState<PurchaseInvoiceDetailsDialog> {
  CommercialDocumentData? _docData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final mapper = getIt<PurchaseInvoiceDocumentMapper>();
      final doc = await mapper.mapToDocumentData(widget.invoice.id);
      if (mounted) {
        setState(() {
          _docData = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isPosted = widget.invoice.status == 'Posted';
    final paymentStatus = widget.invoice.paymentStatus;
    Color paymentColor;
    String paymentText;
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        paymentColor = const Color(0xFF10B981);
        paymentText = 'مدفوعة بالكامل';
        break;
      case 'partial':
        paymentColor = const Color(0xFFF59E0B);
        paymentText = 'مدفوعة جزئياً';
        break;
      default:
        paymentColor = const Color(0xFFEF4444);
        paymentText = 'غير مدفوعة (آجلة)';
    }

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'فاتورة مشتريات: ${widget.invoice.invoiceNumber}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isPosted
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPosted ? 'مرحلة' : 'مسودة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPosted ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: paymentColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  paymentText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: paymentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المورد: ${widget.supplierName} • التاريخ: ${DateFormat('yyyy-MM-dd').format(widget.invoice.purchaseDate)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content / Items Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(
                            child: Text(
                              'خطأ في تحميل تفاصيل الفاتورة: $_errorMessage',
                            ),
                          )
                        : _docData == null || _docData!.items.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد أصناف في هذه الفاتورة',
                                  style: TextStyle(color: textSecondary),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                                .withOpacity(0.5)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '#',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              'اسم الصنف',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'الوحدة',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'الكمية',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'سعر الشراء',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'الإجمالي',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    // Table Lines
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _docData!.items.length,
                                        separatorBuilder: (_, __) =>
                                            Divider(height: 1, color: borderColor),
                                        itemBuilder: (context, index) {
                                          final line = _docData!.items[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 32,
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    line.description,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    line.unitName ?? '-',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    line.quantity.toStringAsFixed(
                                                      line.quantity % 1 == 0
                                                          ? 0
                                                          : 2,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    line.unitPrice.toStringAsFixed(2),
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    '${line.lineTotal.toStringAsFixed(2)} ر.ي',
                                                    textAlign: TextAlign.end,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
              ),
              const SizedBox(height: 16),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المجموع الفرعي: ${widget.invoice.subTotal.toStringAsFixed(2)} ر.ي',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        if (widget.invoice.discountTotal > 0)
                          Text(
                            'الخصم المكتسب: -${widget.invoice.discountTotal.toStringAsFixed(2)} ر.ي',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        if (widget.invoice.taxTotal > 0)
                          Text(
                            'الضريبة: +${widget.invoice.taxTotal.toStringAsFixed(2)} ر.ي',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'الإجمالي النهائي: ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.invoice.grandTotal.toStringAsFixed(2)} ر.ي',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                children: [
                  // معاينة وطباعة الفاتورة
                  ElevatedButton.icon(
                    onPressed: _docData == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CommercialDocumentPreviewScreen(
                                  document: _docData!,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('معاينة وطباعة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // إنشاء مرتجع مشتريات
                  OutlinedButton.icon(
                    onPressed: () async {
                      final session = ref.read(sessionNotifierProvider);
                      if (!session.isActive || session.businessId == null) {
                        return;
                      }

                      final repo = getIt<PurchasingRepository>();
                      final invoiceWithItems =
                          await repo.getInvoiceWithItemsById(
                        widget.invoice.id,
                        session.businessId!,
                      );

                      if (context.mounted && invoiceWithItems != null) {
                        Navigator.of(context).pop(); // Close details dialog
                        await showDialog<void>(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(24),
                            child: PurchaseReturnModal(
                              initialInvoice: invoiceWithItems,
                              onClose: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.keyboard_return_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text(
                      'إنشاء مرتجع مشتريات',
                      style: TextStyle(color: Color(0xFFF59E0B)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // سداد دفعة للمورد
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => PaymentVoucherDialog(
                          initialSupplierId: widget.invoice.supplierId,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.call_made_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'سداد دفعة للمورد',
                      style: TextStyle(color: Color(0xFFEF4444)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
