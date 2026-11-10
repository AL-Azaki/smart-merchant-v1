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
import '../../../treasury/domain/repositories/treasury_repository.dart';
import 'voucher_account_search_picker.dart';

class PaymentVoucherDialog extends ConsumerStatefulWidget {
  final String? initialSupplierId;

  const PaymentVoucherDialog({super.key, this.initialSupplierId});

  @override
  ConsumerState<PaymentVoucherDialog> createState() =>
      _PaymentVoucherDialogState();
}

class _PaymentVoucherDialogState extends ConsumerState<PaymentVoucherDialog> {
  final _formKey = GlobalKey<FormState>();

  VoucherAccountItem? _selectedAccountItem;
  String? _selectedSourceAccountId; // Cash/Bank ChartOfAccount
  String _paymentMethod = 'CASH';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<Supplier> _suppliers = [];
  List<PaymentMethod> _paymentMethods = [];
  SupplierBalanceSummary? _supplierBalance;
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _accountSelectionError;

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
    if (!session.isActive || session.businessId == null) {
      return;
    }

    try {
      final purchasingRepo = getIt<PurchasingRepository>();
      final treasuryRepo = getIt<TreasuryRepository>();
      final suppliers = await purchasingRepo.listSuppliers(
        SupplierFilter(businessId: session.businessId!, isActive: true),
      );
      final paymentMethods = await treasuryRepo.listPaymentMethods(
        session.businessId!,
        isActive: true,
      );
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _paymentMethods = paymentMethods;
          if (paymentMethods.isNotEmpty) {
            _paymentMethod = paymentMethods.first.id;
          }
          _isLoadingData = false;
        });
        if (widget.initialSupplierId != null) {
          final matchedSupplier = _suppliers
              .where((s) => s.id == widget.initialSupplierId)
              .firstOrNull;
          if (matchedSupplier != null) {
            _selectSupplier(matchedSupplier);
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _selectSupplier(Supplier s) async {
    final item = VoucherAccountItem(
      id: s.id,
      title: s.supplierName,
      subtitle: s.phone != null && s.phone!.isNotEmpty ? 'مورد - ' : 'مورد',
      phone: s.phone,
      isSupplier: true,
    );
    setState(() {
      _selectedAccountItem = item;
      _accountSelectionError = null;
      _supplierBalance = null;
    });

    final session = ref.read(sessionNotifierProvider);
    if (session.businessId != null) {
      final purchasingRepo = getIt<PurchasingRepository>();
      final summary = await purchasingRepo.getSupplierBalanceSummary(
        s.id,
        session.businessId!,
      );
      if (mounted) {
        setState(() => _supplierBalance = summary);
      }
    }
  }

  void _onAccountSelected(VoucherAccountItem item) {
    if (item.isSupplier) {
      final supplier = _suppliers.where((s) => s.id == item.id).firstOrNull;
      if (supplier != null) {
        _selectSupplier(supplier);
        return;
      }
    }
    setState(() {
      _selectedAccountItem = item;
      _supplierBalance = null;
      _accountSelectionError = null;
    });
  }

  void _onClearAccount() {
    setState(() {
      _selectedAccountItem = null;
      _supplierBalance = null;
      _accountSelectionError = null;
    });
  }

  String _getAccountTypeName(int typeId) {
    switch (typeId) {
      case 1:
        return 'أصول';
      case 2:
        return 'خصوم';
      case 3:
        return 'حقوق ملكية';
      case 4:
        return 'إيرادات';
      case 5:
        return 'مصروفات';
      default:
        return 'حساب مالي';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedAccountItem == null) {
      setState(() {
        _accountSelectionError = 'يرجى اختيار الحساب أو المورد المصروف له';
      });
      _showSnack('يرجى اختيار الحساب أو المورد المصروف له');
      return;
    }
    if (_selectedSourceAccountId == null) {
      _showSnack('يرجى اختيار الصندوق أو الحساب البنكي المصروف منه');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    setState(() => _isSubmitting = true);

    final useCase = getIt<RecordDisbursementUseCase>();

    final isSupplier = _selectedAccountItem!.isSupplier;
    final command = RecordDisbursementCommand(
      type: isSupplier
          ? DisbursementType.supplierPayment
          : DisbursementType.expense,
      amount: amount,
      currencyId: 'YER',
      paymentMethodId: _paymentMethod,
      chartOfAccountId: _selectedSourceAccountId!,
      supplierId: isSupplier ? _selectedAccountItem!.id : null,
      expenseAccountId: !isSupplier ? _selectedAccountItem!.id : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final result = await useCase(command);

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => _showSnack('فشل الحفظ: '),
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
    // Parent account IDs to strictly exclude main/header accounts
    final Set<String> parentAccountIds = availableAccounts
        .map((a) => a.parentAccountId)
        .whereType<String>()
        .toSet();

    // Sub-accounts only (Leaf accounts that allow direct posting)
    final leafAccounts = availableAccounts
        .where((a) => a.allowPosting && !parentAccountIds.contains(a.id))
        .toList();

    // Filter strictly for Cash & Bank sub-accounts (صناديق وبنوك فرعية)
    final rawSourceAccounts = leafAccounts
        .where((a) =>
            a.accountCategory == 'Cash' ||
            a.accountCategory == 'Bank' ||
            a.accountCategory == 'DigitalWallet' ||
            a.accountCode.startsWith('1110') ||
            a.accountName.contains('صندوق') ||
            a.accountName.contains('خزينة') ||
            a.accountName.contains('كاشير') ||
            a.accountName.contains('بنك') ||
            a.accountName.contains('مصرف') ||
            a.accountName.contains('محفظة'))
        .toList();

    final sourceAccounts = rawSourceAccounts.isNotEmpty
        ? rawSourceAccounts
        : leafAccounts;
    final effectiveSourceAccountId = (_selectedSourceAccountId != null &&
            sourceAccounts.any((a) => a.id == _selectedSourceAccountId))
        ? _selectedSourceAccountId
        : (sourceAccounts.isNotEmpty ? sourceAccounts.first.id : null);
    if (_selectedSourceAccountId == null && effectiveSourceAccountId != null) {
      _selectedSourceAccountId = effectiveSourceAccountId;
    }

    final List<VoucherAccountItem> searchableItems = [
      ..._suppliers.map((s) => VoucherAccountItem(
            id: s.id,
            title: s.supplierName,
            subtitle: s.phone != null && s.phone!.isNotEmpty
                ? 'مورد - ${s.phone}'
                : 'مورد',
            phone: s.phone,
            isSupplier: true,
          )),
      ...leafAccounts.map((acc) =>
          VoucherAccountItem(
            id: acc.id,
            title: acc.accountName,
            code: acc.accountCode,
            subtitle: _getAccountTypeName(acc.accountTypeId),
          )),
    ];

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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.15),
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

                        VoucherAccountSelectField(
                          label: 'الحساب / الطرف المصروف له *',
                          selectedItem: _selectedAccountItem,
                          errorText: _accountSelectionError,
                          onTap: () async {
                            final picked =
                                await showVoucherAccountSearchPicker(
                              context: context,
                              title: 'اختيار الحساب أو المورد',
                              items: searchableItems,
                              selectedId: _selectedAccountItem?.id,
                            );
                            if (picked != null) {
                              _onAccountSelected(picked);
                            }
                          },
                          onClear: _onClearAccount,
                        ),
                        if (_supplierBalance != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'مستحقات المورد الحالية:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${_supplierBalance!.currentBalance.toStringAsFixed(2)} ر.ي',
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
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: effectiveSourceAccountId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'الصندوق / الحساب البنكي المصروف منه *',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                            border: OutlineInputBorder(),
                          ),
                          items: sourceAccounts.map((a) {
                            final isBank = a.accountCode.startsWith('112') || a.accountName.contains('بنك') || a.accountName.contains('مصرف');
                            return DropdownMenuItem<String>(
                              value: a.id,
                              child: Row(
                                children: [
                                  Icon(
                                    isBank ? Icons.account_balance_rounded : Icons.point_of_sale_rounded,
                                    size: 18,
                                    color: isBank ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${a.accountCode} - ${a.accountName}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSourceAccountId = val),
                          validator: (val) =>
                              val == null ? 'مطلوب اختيار حساب الصرف' : null,
                        ),
                        const SizedBox(height: 16),

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
                                value: _paymentMethods
                                        .any((m) => m.id == _paymentMethod)
                                    ? _paymentMethod
                                    : (_paymentMethods.isNotEmpty
                                        ? _paymentMethods.first.id
                                        : _paymentMethod),
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'طريقة الدفع',
                                  border: OutlineInputBorder(),
                                ),
                                items: _paymentMethods.isNotEmpty
                                    ? _paymentMethods.map((pm) {
                                        return DropdownMenuItem<String>(
                                          value: pm.id,
                                          child: Text(
                                            pm.methodName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList()
                                    : const [
                                        DropdownMenuItem(
                                            value: 'CASH',
                                            child: Text('نقداً')),
                                        DropdownMenuItem(
                                            value: 'CARD',
                                            child: Text('شبكة/مدى',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        DropdownMenuItem(
                                            value: 'BANK_TRANSFER',
                                            child: Text('تحويل بنكي',
                                                overflow:
                                                    TextOverflow.ellipsis)),
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
                                  : const Icon(
                                      Icons.check_circle_outline_rounded,
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
