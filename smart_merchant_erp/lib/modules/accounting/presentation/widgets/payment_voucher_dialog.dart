import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../database/daos/purchasing_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../purchasing/domain/repositories/purchasing_repository.dart';
import '../providers/accounting_provider.dart';
import '../../../treasury/application/usecases/record_disbursement_usecase.dart';

class PaymentVoucherDialog extends ConsumerStatefulWidget {
  final String? initialSupplierId;

  const PaymentVoucherDialog({super.key, this.initialSupplierId});

  @override
  ConsumerState<PaymentVoucherDialog> createState() =>
      _PaymentVoucherDialogState();
}

class _PaymentVoucherDialogState extends ConsumerState<PaymentVoucherDialog> {
  final _formKey = GlobalKey<FormState>();

  DisbursementType _disbursementType = DisbursementType.supplierPayment;
  String? _selectedSupplierId;
  String? _selectedExpenseAccountId;
  String? _selectedSourceAccountId; // Cash/Bank ChartOfAccount
  String _paymentMethod = 'CASH';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Supplier> _suppliers = [];
  SupplierBalanceSummary? _supplierBalance;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    try {
      final purchasingRepo = getIt<PurchasingRepository>();
      final suppliers = await purchasingRepo.listSuppliers(
        SupplierFilter(businessId: session.businessId!, isActive: true),
      );
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _isLoadingData = false;
        });
        if (widget.initialSupplierId != null) {
          _onSupplierChanged(widget.initialSupplierId);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _onSupplierChanged(String? supplierId) async {
    setState(() {
      _selectedSupplierId = supplierId;
      _supplierBalance = null;
    });

    if (supplierId != null) {
      final session = ref.read(sessionNotifierProvider);
      if (session.businessId != null) {
        final purchasingRepo = getIt<PurchasingRepository>();
        final summary = await purchasingRepo.getSupplierBalanceSummary(
          supplierId,
          session.businessId!,
        );
        if (mounted) {
          setState(() => _supplierBalance = summary);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSourceAccountId == null) {
      _showSnack('يرجى اختيار الصندوق أو الحساب البنكي المصروف منه');
      return;
    }
    if (_disbursementType == DisbursementType.supplierPayment &&
        _selectedSupplierId == null) {
      _showSnack('يرجى اختيار المورد');
      return;
    }
    if (_disbursementType == DisbursementType.expense &&
        _selectedExpenseAccountId == null) {
      _showSnack('يرجى اختيار بند المصروف');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = getIt<RecordDisbursementUseCase>();
    final session = ref.read(sessionNotifierProvider);

    final command = RecordDisbursementCommand(
      type: _disbursementType,
      amount: amount,
      currencyId: 'YER',
      paymentMethodId: _paymentMethod,
      chartOfAccountId: _selectedSourceAccountId!,
      supplierId: _selectedSupplierId,
      expenseAccountId: _selectedExpenseAccountId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final result = await useCase(command);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => _showSnack('فشل الحفظ: ${failure.message}'),
      (paymentId) {
        Navigator.of(context).pop(true);
        _showSnack('تم تسجيل وترحيل سند الصرف بنجاح');
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
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);

    final List<ChartOfAccount> availableAccounts =
        accountsAsync.asData?.value ?? [];
    // Postable cash/bank accounts (11101, 11102...)
    final sourceAccounts = availableAccounts
        .where((a) =>
            a.allowPosting && (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .toList();
    // Expense accounts (5...)
    final expenseAccounts = availableAccounts
        .where((a) => a.allowPosting && a.accountTypeId == 5)
        .toList();

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoadingData
              ? const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Form(
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
                                color:
                                    const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.south_west_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'سند صرف جديد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Voucher Type Segment
                        SegmentedButton<DisbursementType>(
                          segments: const [
                            ButtonSegment(
                              value: DisbursementType.supplierPayment,
                              label: Text('سداد لمورد'),
                              icon: Icon(Icons.business_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: DisbursementType.expense,
                              label: Text('مصروف تشغيلي'),
                              icon: Icon(Icons.receipt_long_rounded, size: 18),
                            ),
                          ],
                          selected: {_disbursementType},
                          onSelectionChanged: (val) {
                            setState(() => _disbursementType = val.first);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Party / Expense Selector
                        if (_disbursementType ==
                            DisbursementType.supplierPayment) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'المورد *',
                              prefixIcon: Icon(Icons.business_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _suppliers.map((s) {
                              return DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.supplierName),
                              );
                            }).toList(),
                            onChanged: _onSupplierChanged,
                            validator: (val) =>
                                val == null ? 'مطلوب اختيار المورد' : null,
                          ),
                          if (_supplierBalance != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'مستحقات المورد الحالية:',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_supplierBalance!.totalRemaining.toStringAsFixed(2)} ر.ي',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: _selectedExpenseAccountId,
                            decoration: const InputDecoration(
                              labelText: 'بند المصروف *',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: expenseAccounts.map((a) {
                              return DropdownMenuItem<String>(
                                value: a.id,
                                child: Text('${a.accountCode} - ${a.accountName}'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedExpenseAccountId = val),
                            validator: (val) =>
                                val == null ? 'مطلوب اختيار بند المصروف' : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Source Account (Cash/Bank)
                        DropdownButtonFormField<String>(
                          value: _selectedSourceAccountId,
                          decoration: const InputDecoration(
                            labelText: 'الصندوق / الحساب البنكي المصروف منه *',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: sourceAccounts.map((a) {
                            return DropdownMenuItem<String>(
                              value: a.id,
                              child: Text('${a.accountCode} - ${a.accountName}'),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSourceAccountId = val),
                          validator: (val) =>
                              val == null ? 'مطلوب اختيار حساب الصرف' : null,
                        ),
                        const SizedBox(height: 16),

                        // Amount & Payment Method
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'المبلغ المصروف *',
                                  prefixIcon: Icon(Icons.attach_money_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'مطلوب إدخال المبلغ';
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num <= 0) {
                                    return 'مبلغ غير صالح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _paymentMethod,
                                decoration: const InputDecoration(
                                  labelText: 'طريقة الدفع',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'CASH', child: Text('نقداً')),
                                  DropdownMenuItem(
                                      value: 'CARD', child: Text('بطاقة/شبكة')),
                                  DropdownMenuItem(
                                      value: 'BANK_TRANSFER',
                                      child: Text('تحويل بنكي')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _paymentMethod = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'البيان / ملاحظات الصرف',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isSubmitting ? null : _submit,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded,
                                      size: 18),
                              label: Text(_isSubmitting
                                  ? 'جاري الترحيل...'
                                  : 'حفظ وترحيل السند'),
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
