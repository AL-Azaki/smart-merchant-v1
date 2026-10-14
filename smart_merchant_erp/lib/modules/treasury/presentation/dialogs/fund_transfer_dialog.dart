import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../accounting/presentation/providers/accounting_provider.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/usecases/internal_fund_transfer_usecase.dart';

class FundTransferDialog extends ConsumerStatefulWidget {
  const FundTransferDialog({super.key});

  @override
  ConsumerState<FundTransferDialog> createState() => _FundTransferDialogState();
}

class _FundTransferDialogState extends ConsumerState<FundTransferDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _fromAccountId;
  String? _toAccountId;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == null || _toAccountId == null) {
      _showSnack('يرجى تحديد حساب المصدر وحساب الوجهة');
      return;
    }
    if (_fromAccountId == _toAccountId) {
      _showSnack('لا يمكن التحويل إلى نفس الحساب');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = getIt<InternalFundTransferUseCase>();
    final session = ref.read(sessionNotifierProvider);

    final command = InternalFundTransferCommand(
      fromAccountId: _fromAccountId!,
      toAccountId: _toAccountId!,
      amount: amount,
      currencyId: 'YER',
      paymentMethodId: 'INTERNAL_TRANSFER',
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = await useCase(command);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => _showSnack('فشل التحويل: ${failure.message}'),
      (_) {
        Navigator.of(context).pop(true);
        _showSnack('تم التحويل المالي الداخلي وترحيل القيد بنجاح');
      },
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);
    final availableAccounts = accountsAsync.asData?.value ?? [];
    // Cash & Bank postable accounts (11101, 11102...)
    final fundAccounts = availableAccounts
        .where((a) => a.allowPosting && (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .toList();

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'تحويل مالي داخلي (بين الصناديق/البنوك)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // From Account
                  DropdownButtonFormField<String>(
                    value: _fromAccountId,
                    decoration: const InputDecoration(
                      labelText: 'من حساب (المصدر) *',
                      prefixIcon: Icon(Icons.outbox_rounded, color: Color(0xFFEF4444)),
                      border: OutlineInputBorder(),
                    ),
                    items: fundAccounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.accountCode} - ${a.accountName}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _fromAccountId = val),
                    validator: (val) => val == null ? 'مطلوب اختيار الحساب المصدر' : null,
                  ),
                  const SizedBox(height: 16),

                  // To Account
                  DropdownButtonFormField<String>(
                    value: _toAccountId,
                    decoration: const InputDecoration(
                      labelText: 'إلى حساب (الوجهة) *',
                      prefixIcon: Icon(Icons.move_to_inbox_rounded, color: Color(0xFF10B981)),
                      border: OutlineInputBorder(),
                    ),
                    items: fundAccounts.map((a) {
                      return DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.accountCode} - ${a.accountName}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _toAccountId = val),
                    validator: (val) => val == null ? 'مطلوب اختيار الحساب الوجهة' : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المحوّل *',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'مطلوب إدخال المبلغ';
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) return 'مبلغ غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'البيان / سبب التحويل',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(_isSubmitting ? 'جاري التحويل...' : 'تأكيد وترحيل التحويل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
