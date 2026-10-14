import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../providers/accounting_provider.dart';
import '../../../sales/domain/repositories/sales_repository.dart';
import '../../../treasury/application/usecases/receive_payment_usecase.dart';

class ReceiptVoucherDialog extends ConsumerStatefulWidget {
  const ReceiptVoucherDialog({super.key});

  @override
  ConsumerState<ReceiptVoucherDialog> createState() =>
      _ReceiptVoucherDialogState();
}

class _ReceiptVoucherDialogState extends ConsumerState<ReceiptVoucherDialog> {
  final _formKey = GlobalKey<FormState>();

  String _voucherType = 'customer'; // 'customer' or 'revenue'
  String? _selectedCustomerId;
  String? _selectedIncomeAccountId;
  String? _selectedTargetAccountId; // Cash/Bank ChartOfAccount
  String _paymentMethod = 'CASH';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Customer> _customers = [];
  CustomerBalanceSummary? _customerBalance;
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
      final salesRepo = getIt<SalesRepository>();
      final customers = await salesRepo.listCustomers(
        CustomerFilter(businessId: session.businessId!, isActive: true),
      );
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _onCustomerChanged(String? customerId) async {
    setState(() {
      _selectedCustomerId = customerId;
      _customerBalance = null;
    });

    if (customerId != null) {
      final session = ref.read(sessionNotifierProvider);
      if (session.businessId != null) {
        final salesRepo = getIt<SalesRepository>();
        final summary = await salesRepo.getCustomerBalanceSummary(
          customerId,
          session.businessId!,
        );
        if (mounted) {
          setState(() => _customerBalance = summary);
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTargetAccountId == null) {
      _showSnack('يرجى اختيار الصندوق أو الحساب البنكي المستلم');
      return;
    }
    if (_voucherType == 'customer' && _selectedCustomerId == null) {
      _showSnack('يرجى اختيار العميل');
      return;
    }
    if (_voucherType == 'revenue' && _selectedIncomeAccountId == null) {
      _showSnack('يرجى اختيار حساب الإيراد');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = getIt<ReceivePaymentUseCase>();
    final session = ref.read(sessionNotifierProvider);

    final command = ReceivePaymentCommand(
      customerId: _voucherType == 'customer' ? _selectedCustomerId : null,
      incomeAccountId: _voucherType == 'revenue' ? _selectedIncomeAccountId : null,
      amount: amount,
      currencyId: 'YER',
      paymentMethodId: _paymentMethod,
      chartOfAccountId: _selectedTargetAccountId!,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = await useCase(command);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => _showSnack('فشل الحفظ: ${failure.message}'),
      (paymentId) {
        Navigator.of(context).pop(true);
        _showSnack('تم تسجيل وترحيل سند القبض بنجاح');
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

    final List<ChartOfAccount> availableAccounts =
        accountsAsync.asData?.value ?? [];
    // Postable cash/bank accounts (11101, 11102...)
    final receivingAccounts = availableAccounts
        .where((a) => a.allowPosting && (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .toList();
    // Revenue/Income accounts (4...)
    final incomeAccounts = availableAccounts
        .where((a) => a.allowPosting && (a.accountTypeId == 4 || a.accountTypeId == 3))
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
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'سند قبض جديد',
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
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'customer',
                              label: Text('قبض من عميل'),
                              icon: Icon(Icons.person_outline_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: 'revenue',
                              label: Text('إيراد عام / أخرى'),
                              icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                            ),
                          ],
                          selected: {_voucherType},
                          onSelectionChanged: (val) {
                            setState(() => _voucherType = val.first);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Party Selector
                        if (_voucherType == 'customer') ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'العميل *',
                              prefixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _customers.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.customerName),
                              );
                            }).toList(),
                            onChanged: _onCustomerChanged,
                            validator: (val) => val == null ? 'مطلوب اختيار العميل' : null,
                          ),
                          if (_customerBalance != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'إجمالي المديونية المستحقة:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${_customerBalance!.totalRemaining.toStringAsFixed(2)} ر.ي',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          DropdownButtonFormField<String>(
                            value: _selectedIncomeAccountId,
                            decoration: const InputDecoration(
                              labelText: 'حساب الإيراد *',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: incomeAccounts.map((a) {
                              return DropdownMenuItem<String>(
                                value: a.id,
                                child: Text('${a.accountCode} - ${a.accountName}'),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedIncomeAccountId = val),
                            validator: (val) => val == null ? 'مطلوب اختيار حساب الإيراد' : null,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Receiving Account (Cash/Bank)
                        DropdownButtonFormField<String>(
                          value: _selectedTargetAccountId,
                          decoration: const InputDecoration(
                            labelText: 'الصندوق / الحساب البنكي المستلم *',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: receivingAccounts.map((a) {
                            return DropdownMenuItem<String>(
                              value: a.id,
                              child: Text('${a.accountCode} - ${a.accountName}'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedTargetAccountId = val),
                          validator: (val) => val == null ? 'مطلوب اختيار الحساب المستلم' : null,
                        ),
                        const SizedBox(height: 16),

                        // Amount & Payment Method
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'المبلغ المستلم *',
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
                                  DropdownMenuItem(value: 'CASH', child: Text('نقداً')),
                                  DropdownMenuItem(value: 'CARD', child: Text('بطاقة/شبكة')),
                                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('تحويل بنكي')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _paymentMethod = val);
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
                            labelText: 'البيان / ملاحظات',
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
                              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
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
                              label: Text(_isSubmitting ? 'جاري الترحيل...' : 'حفظ وترحيل السند'),
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
