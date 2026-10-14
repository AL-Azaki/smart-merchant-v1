import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/documents/presentation/models/commercial_document_data.dart';
import '../../../../shared/documents/presentation/widgets/commercial_document_preview_screen.dart';
import '../../../../shared/documents/printing/document_printer.dart';
import '../../../../shared/documents/sharing/document_share.dart';
import '../mappers/sales_invoice_document_mapper.dart';
import '../providers/pos_provider.dart';

/// Lightweight, immediate success dialog displayed after a sale is completed.
/// Offers quick thermal printing and WhatsApp sharing without blocking cashier rhythm.
class PosSaleSuccessDialog extends ConsumerStatefulWidget {
  final String invoiceId;

  const PosSaleSuccessDialog({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<PosSaleSuccessDialog> createState() =>
      _PosSaleSuccessDialogState();
}

class _PosSaleSuccessDialogState extends ConsumerState<PosSaleSuccessDialog> {
  CommercialDocumentData? _docData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  Future<void> _loadDocumentData() async {
    try {
      final mapper = getIt<SalesInvoiceDocumentMapper>();
      final data = await mapper.mapToDocumentData(widget.invoiceId);
      if (mounted) {
        setState(() {
          _docData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _finishAndNewSale() {
    ref.read(posNotifierProvider.notifier).clearCart();
    ref.read(posNotifierProvider.notifier).clearSuccess();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        ref.read(posNotifierProvider.notifier).clearCart();
        ref.read(posNotifierProvider.notifier).clearSuccess();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar with Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _finishAndNewSale,
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                    tooltip: 'إغلاق',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // 1. SUCCESS BADGE
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'تم إتمام البيع بنجاح!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 6),

              if (_isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_docData != null) ...[
                Text(
                  'فاتورة رقم: ${_docData!.documentNumber}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'المبلغ: ${_docData!.grandTotal.toStringAsFixed(0)} ${_docData!.currencyCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),


            // 2. QUICK ACTIONS (Print & Share)
            if (_docData != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          DocumentPrinter.printDocument(_docData!),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 20),
                      label: const Text(
                        'طباعة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          DocumentShare.shareDocument(_docData!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text(
                        'واتساب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CommercialDocumentPreviewScreen(
                        document: _docData!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('معاينة تفاصيل الفاتورة'),
              ),
              const SizedBox(height: 10),
            ],

            // 3. READY FOR NEXT SALE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _finishAndNewSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'فاتورة جديدة (جاهز للزبون التالي)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
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

