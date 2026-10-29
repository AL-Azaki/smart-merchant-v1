import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../treasury/application/usecases/record_disbursement_usecase.dart';
import '../../../treasury/domain/repositories/treasury_repository.dart';
import '../providers/accounting_provider.dart';

class QuickExpenseCategory {
  final String id;
  final String name;
  final String defaultCode; // Fallback account code in CoA
  final IconData icon;
  final Color color;
  final bool isOwnerDrawings;

  const QuickExpenseCategory({
    required this.id,
    required this.name,
    required this.defaultCode,
    required this.icon,
    required this.color,
    this.isOwnerDrawings = false,
  });
}

class CreateExpenseDialog extends ConsumerStatefulWidget {
  final String? preselectedCashboxId;
  final bool initialIsOwnerDrawings;

  const CreateExpenseDialog({
    super.key,
    this.preselectedCashboxId,
    this.initialIsOwnerDrawings = false,
  });

  @override
  ConsumerState<CreateExpenseDialog> createState() =>
      _CreateExpenseDialogState();
}

class _CreateExpenseDialogState extends ConsumerState<CreateExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  static const List<QuickExpenseCategory> _presetCategories = [
    QuickExpenseCategory(
      id: 'electricity',
      name: 'كهرباء ومياه',
      defaultCode: '52002',
      icon: Icons.bolt_rounded,
      color: Color(0xFFEF4444),
    ),
    QuickExpenseCategory(
      id: 'rent',
      name: 'إيجار المقر/المستودع',
      defaultCode: '52001',
      icon: Icons.storefront_rounded,
      color: Color(0xFF3B82F6),
    ),
    QuickExpenseCategory(
      id: 'owner_drawings',
      name: 'صرفة شخصية / مسحوبات',
      defaultCode: '33',
      icon: Icons.person_rounded,
      color: Color(0xFFF59E0B),
      isOwnerDrawings: true,
    ),
    QuickExpenseCategory(
      id: 'salaries',
      name: 'رواتب وأجور',
      defaultCode: '52003',
      icon: Icons.badge_rounded,
      color: Color(0xFF10B981),
    ),
    QuickExpenseCategory(
      id: 'telecom',
      name: 'اتصالات وإنترنت',
      defaultCode: '52005',
      icon: Icons.wifi_rounded,
      color: Color(0xFF8B5CF6),
    ),
    QuickExpenseCategory(
      id: 'hospitality',
      name: 'ضيافة ونثريات',
      defaultCode: '52005',
      icon: Icons.coffee_rounded,
      color: Color(0xFFEC4899),
    ),
    QuickExpenseCategory(
      id: 'maintenance',
      name: 'صيانة ومرافق',
      defaultCode: '52005',
      icon: Icons.build_rounded,
      color: Color(0xFF06B6D4),
    ),
  ];

  late QuickExpenseCategory _selectedCategory;
  String? _selectedSourceAccountId;
  String? _selectedExpenseAccountId;
  bool _useCustomCoaAccount = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialIsOwnerDrawings
        ? _presetCategories.firstWhere((c) => c.isOwnerDrawings)
        : _presetCategories.first;
    _selectedSourceAccountId = widget.preselectedCashboxId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amount) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final updated = current + amount;
    _amountController.text = updated.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedSourceAccountId == null) {
      _showSnack('يرجى اختيار الصندوق أو الحساب المصروف منه');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    final accountsAsync = ref.read(chartOfAccountsNotifierProvider);
    final accounts = accountsAsync.asData?.value ?? [];

    String? targetDebitAccountId = _selectedExpenseAccountId;

    if (!_useCustomCoaAccount || targetDebitAccountId == null) {
      // Auto-resolve by category code
      final targetAccount = accounts.firstWhere(
        (a) => a.accountCode == _selectedCategory.defaultCode && a.allowPosting,
        orElse: () => accounts.firstWhere(
          (a) => a.accountTypeId == (_selectedCategory.isOwnerDrawings ? 3 : 5) && a.allowPosting,
          orElse: () => accounts.firstWhere((a) => a.allowPosting),
        ),
      );
      targetDebitAccountId = targetAccount.id;
    }

    setState(() => _isSubmitting = true);

    try {
      final session = ref.read(sessionNotifierProvider);
      final treasuryRepo = getIt<TreasuryRepository>();
      final paymentMethods = await treasuryRepo.listPaymentMethods(
        session.businessId!,
        isActive: true,
      );
      final defaultMethod = paymentMethods.isNotEmpty
          ? paymentMethods.first.id
          : 'CASH';

      final useCase = getIt<RecordDisbursementUseCase>();
      final noteText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (_selectedCategory.isOwnerDrawings
              ? 'صرفة شخصية للمالك'
              : 'مصروف: ${_selectedCategory.name}');

      final command = RecordDisbursementCommand(
        type: DisbursementType.expense,
        amount: amount,
        currencyId: 'YER',
        paymentMethodId: defaultMethod,
        chartOfAccountId: _selectedSourceAccountId!,
        expenseAccountId: targetDebitAccountId,
        notes: noteText,
      );

      final result = await useCase(command);

      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);

      result.fold(
        (failure) => _showSnack('فشل الحفظ: ${failure.message}'),
        (paymentId) {
          Navigator.of(context).pop(true);
          _showSnack(
            _selectedCategory.isOwnerDrawings
                ? 'تم تسجيل وترحيل الصرفة الشخصية بنجاح'
                : 'تم تسجيل وترحيل المصروف والقيد المحاسبي بنجاح',
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('حدث خطأ أثناء حفظ المصروف: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);
    final tbAsync = ref.watch(trialBalanceReportProvider());
    final availableAccounts = accountsAsync.asData?.value ?? [];

    // 1. Postable cash & bank accounts (11101, 11102, 11103...)
    final sourceAccounts = availableAccounts
        .where((a) =>
            a.allowPosting && (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .toList();

    if (_selectedSourceAccountId == null && sourceAccounts.isNotEmpty) {
      _selectedSourceAccountId = sourceAccounts.first.id;
    }

    // 2. Real-time balance mapping per account
    final Map<String, double> balances = {};
    tbAsync.whenData((tb) {
      for (final item in tb.items) {
        final net = item.netDebit - item.netCredit;
        balances[item.accountId] = net;
      }
    });

    final currentSourceAccount = sourceAccounts.firstWhere(
      (a) => a.id == _selectedSourceAccountId,
      orElse: () => sourceAccounts.isNotEmpty ? sourceAccounts.first : availableAccounts.first,
    );
    final availableCash = balances[currentSourceAccount.id] ?? 0.0;

    // 3. Postable expense accounts (5...) and drawings (33...)
    final customAccounts = availableAccounts
        .where((a) => a.allowPosting && (a.accountTypeId == 5 || a.accountCode == '33'))
        .toList();

    final inputAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isInsufficient = inputAmount > 0 && availableCash > 0 && inputAmount > availableCash;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Dialog Header ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFFF97316),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory.isOwnerDrawings
                                  ? 'تسجيل صرفة شخصية للمالك'
                                  : 'تسجيل مصروف / نفقات جديدة',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'صرف نقدي مباشر من الصندوق مع توليد القيد المحاسبي تلقائياً',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),

                  // ── 1. Quick Categories Selector ──
                  Text(
                    'اختر تصنيف المصروف أو الصرفة *',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetCategories.map((cat) {
                      final isSelected = !_useCustomCoaAccount && _selectedCategory.id == cat.id;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _useCustomCoaAccount = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.18)
                                : (isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? cat.color : borderColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 16, color: cat.color),
                              const SizedBox(width: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? cat.color : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                      ..add(
                        InkWell(
                          onTap: () {
                            setState(() => _useCustomCoaAccount = true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _useCustomCoaAccount
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                                  : (isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _useCustomCoaAccount ? const Color(0xFF6366F1) : borderColor,
                                width: _useCustomCoaAccount ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF6366F1)),
                                const SizedBox(width: 6),
                                Text(
                                  'بند مخصص من الدليل',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _useCustomCoaAccount ? FontWeight.w900 : FontWeight.w600,
                                    color: _useCustomCoaAccount ? const Color(0xFF6366F1) : textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ),

                  // Custom Account Dropdown if selected
                  if (_useCustomCoaAccount) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExpenseAccountId,
                      decoration: const InputDecoration(
                        labelText: 'اختر الحساب المستهدف من الدليل *',
                        prefixIcon: Icon(Icons.account_tree_outlined),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: customAccounts.map((a) {
                        return DropdownMenuItem<String>(
                          value: a.id,
                          child: Text('${a.accountCode} - ${a.accountName}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedExpenseAccountId = val),
                      validator: (val) =>
                          _useCustomCoaAccount && val == null ? 'يرجى اختيار الحساب' : null,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── 2. Source Cashbox with Live Balance Display ──
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSourceAccountId,
                    decoration: InputDecoration(
                      labelText: 'الصندوق / الحساب المصروف منه *',
                      prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    items: sourceAccounts.map((a) {
                      final bal = balances[a.id] ?? 0.0;
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text('${a.accountName} (الرصيد: ${bal.toStringAsFixed(0)} ر.ي)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSourceAccountId = val),
                    validator: (val) => val == null ? 'يرجى اختيار الصندوق' : null,
                  ),

                  // Live Cash Balance Pill
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isInsufficient
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isInsufficient ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isInsufficient ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                              size: 16,
                              color: isInsufficient ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isInsufficient
                                  ? 'تنبيه: المبلغ يتجاوز الرصيد المتوفر بالصندوق!'
                                  : 'الرصيد المتوفر في هذا الصندوق حالياً:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isInsufficient ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${availableCash.toStringAsFixed(2)} ر.ي',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: isInsufficient ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 3. Amount Field & Quick Amount Chips ──
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'المبلغ المطلوب صرفه (ر.ي) *',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'ر.ي',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال المبلغ';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'المبلغ يجب أن يكون أكبر من الصفر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Quick Amounts
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [1000.0, 2000.0, 5000.0, 10000.0, 20000.0, 50000.0].map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => _addQuickAmount(amt),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                '+${amt.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 4. Notes / Description ──
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'البيان والتفاصيل (اختياري)',
                      hintText: _selectedCategory.isOwnerDrawings
                          ? 'مثال: صرفة غداء أو مشتريات شخصية للمالك'
                          : 'مثال: سداد فاتورة كهرباء شهر أكتوبر',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 5. Live Accounting Journal Entry Preview ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151722) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262A3C) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 16, color: Color(0xFF6366F1)),
                            SizedBox(width: 6),
                            Text(
                              'معاينة القيد المحاسبي المزدوج الآلي (متوازن 100%):',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'من حـ/ (مدين)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategory.isOwnerDrawings
                                    ? 'مسحوبات الشركاء / جاري المالك (33)'
                                    : '${_selectedCategory.name} (${_selectedCategory.defaultCode})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${inputAmount.toStringAsFixed(2)} ر.ي',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'إلى حـ/ (دائن)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentSourceAccount.accountName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${inputAmount.toStringAsFixed(2)} ر.ي',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Actions ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _selectedCategory.isOwnerDrawings
                              ? 'ترحيل الصرفة الشخصية'
                              : 'ترحيل المصروف فوراً',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
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
