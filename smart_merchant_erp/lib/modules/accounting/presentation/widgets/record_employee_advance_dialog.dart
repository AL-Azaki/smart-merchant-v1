import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../hr/presentation/providers/hr_provider.dart';
import '../../../treasury/application/usecases/record_disbursement_usecase.dart';
import '../../../treasury/domain/repositories/treasury_repository.dart';
import '../providers/accounting_provider.dart';

class RecordEmployeeAdvanceDialog extends ConsumerStatefulWidget {
  final Employee? preselectedEmployee;
  final bool isAdvance; // true = سلفة, false = صرف وتصفية راتب
  final double currentRemainingSalary;

  const RecordEmployeeAdvanceDialog({
    super.key,
    this.preselectedEmployee,
    this.isAdvance = true,
    this.currentRemainingSalary = 0.0,
  });

  @override
  ConsumerState<RecordEmployeeAdvanceDialog> createState() =>
      _RecordEmployeeAdvanceDialogState();
}

class _RecordEmployeeAdvanceDialogState
    extends ConsumerState<RecordEmployeeAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedEmployeeId;
  String? _selectedSourceAccountId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedEmployee != null) {
      _selectedEmployeeId = widget.preselectedEmployee!.id;
    }
    if (!widget.isAdvance && widget.currentRemainingSalary > 0) {
      _amountController.text = widget.currentRemainingSalary.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amt) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    _amountController.text = (current + amt).toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedEmployeeId == null) {
      _showSnack('يرجى اختيار الموظف أولاً');
      return;
    }
    if (_selectedSourceAccountId == null) {
      _showSnack('يرجى اختيار الصندوق المصروف منه');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showSnack('يرجى إدخال مبلغ صحيح أكبر من الصفر');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final session = ref.read(sessionNotifierProvider);
      final treasuryRepo = getIt<TreasuryRepository>();
      final paymentMethods = await treasuryRepo.listPaymentMethods(
        session.businessId!,
        isActive: true,
      );
      final defaultMethod =
          paymentMethods.isNotEmpty ? paymentMethods.first.id : 'CASH';

      final accountsAsync = ref.read(chartOfAccountsNotifierProvider);
      final accounts = accountsAsync.asData?.value ?? [];

      // Find Salaries & Wages account (52003) or fallback to any 5xxx expense account
      final expenseAccount = accounts.firstWhere(
        (a) => a.accountCode == '52003' && a.allowPosting,
        orElse: () => accounts.firstWhere(
          (a) => a.accountTypeId == 5 && a.allowPosting,
          orElse: () => accounts.firstWhere((a) => a.allowPosting),
        ),
      );

      final employeesAsync = ref.read(employeesListProvider);
      final employees = employeesAsync.asData?.value ?? [];
      final selectedEmp = employees.firstWhere(
        (e) => e.id == _selectedEmployeeId,
        orElse: () => widget.preselectedEmployee!,
      );

      final defaultNote = widget.isAdvance
          ? 'سلفة على الراتب للموظف: ${selectedEmp.firstName} ${selectedEmp.lastName}'
          : 'صرف وتصفية راتب الموظف: ${selectedEmp.firstName} ${selectedEmp.lastName}';

      final noteText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : defaultNote;

      final useCase = getIt<RecordDisbursementUseCase>();
      final command = RecordDisbursementCommand(
        type: DisbursementType.expense,
        amount: amount,
        currencyId: 'YER',
        paymentMethodId: defaultMethod,
        chartOfAccountId: _selectedSourceAccountId!,
        expenseAccountId: expenseAccount.id,
        notes: noteText,
      );

      final result = await useCase(command);

      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);

      result.fold(
        (failure) => _showSnack('فشل الحفظ: ${failure.message}'),
        (paymentId) async {
          // Update the payment record to link with employee contactType/contactId
          try {
            final db = getIt<AppDatabase>();
            await (db.update(db.payments)..where((p) => p.id.equals(paymentId)))
                .write(
              PaymentsCompanion(
                contactType: const drift.Value('Employee'),
                contactId: drift.Value(selectedEmp.id),
              ),
            );
          } catch (_) {}

          if (mounted) {
            Navigator.of(context).pop(true);
            _showSnack(
              widget.isAdvance
                  ? 'تم تسجيل السلفة وخصمها من الصندوق بنجاح'
                  : 'تم صرف الراتب وترحيل القيد بنجاح',
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('حدث خطأ: $e');
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
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final employeesAsync = ref.watch(employeesListProvider);
    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);
    final tbAsync = ref.watch(trialBalanceReportProvider());

    final employees = employeesAsync.asData?.value ?? [];
    final availableAccounts = accountsAsync.asData?.value ?? [];

    // Postable cashboxes
    final sourceAccounts = availableAccounts
        .where((a) =>
            a.allowPosting &&
            (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .toList();

    if (_selectedSourceAccountId == null && sourceAccounts.isNotEmpty) {
      _selectedSourceAccountId = sourceAccounts.first.id;
    }

    final Map<String, double> balances = {};
    tbAsync.whenData((tb) {
      for (final item in tb.items) {
        balances[item.accountId] = item.netDebit - item.netCredit;
      }
    });

    final currentCash = _selectedSourceAccountId != null
        ? (balances[_selectedSourceAccountId] ?? 0.0)
        : 0.0;

    final inputAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isInsufficient =
        inputAmount > 0 && currentCash > 0 && inputAmount > currentCash;



    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isAdvance
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.isAdvance
                              ? Icons.payments_rounded
                              : Icons.price_check_rounded,
                          color: widget.isAdvance
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isAdvance
                                  ? 'تسجيل سلفة موظف'
                                  : 'صرف وتصفية راتب موظف',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              widget.isAdvance
                                  ? 'خصم مبلغ مقدماً من الراتب وصرفه من الصندوق'
                                  : 'صرف المتبقي من الراتب بعد خصم السلف',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 22),

                  // 1. اختيار الموظف
                  if (widget.preselectedEmployee != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 20, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الموظف: ${widget.preselectedEmployee!.firstName} ${widget.preselectedEmployee!.lastName}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            'الراتب: ${widget.preselectedEmployee!.salary.toStringAsFixed(0)} ر.ي',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: 'اختر الموظف *',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      items: employees.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                              '${e.firstName} ${e.lastName} (راتب: ${e.salary.toStringAsFixed(0)} ر.ي)'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedEmployeeId = val),
                      validator: (val) =>
                          val == null ? 'يرجى اختيار الموظف' : null,
                    ),

                  const SizedBox(height: 14),

                  // 2. اختيار الصندوق
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSourceAccountId,
                    decoration: InputDecoration(
                      labelText: 'الصندوق المصروف منه *',
                      prefixIcon:
                          const Icon(Icons.account_balance_wallet_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    items: sourceAccounts.map((a) {
                      final bal = balances[a.id] ?? 0.0;
                      return DropdownMenuItem<String>(
                        value: a.id,
                        child: Text(
                            '${a.accountName} (الرصيد: ${bal.toStringAsFixed(0)} ر.ي)'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSourceAccountId = val),
                    validator: (val) =>
                        val == null ? 'يرجى اختيار الصندوق' : null,
                  ),

                  // تنبيه الرصيد
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isInsufficient
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isInsufficient
                              ? 'تنبيه: المبلغ يتجاوز الرصيد بالصندوق!'
                              : 'الرصيد المتوفر بالصندوق حالياً:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isInsufficient
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          '${currentCash.toStringAsFixed(0)} ر.ي',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: isInsufficient
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. حقل المبلغ
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: widget.isAdvance
                          ? 'مبلغ السلفة (ر.ي) *'
                          : 'المبلغ المطلوب صرفه (ر.ي) *',
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      suffixText: 'ر.ي',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
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

                  // شرائح المبالغ السريعة
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5000.0, 10000.0, 20000.0, 50000.0].map((amt) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            onTap: () => _addQuickAmount(amt),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${amt.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4. البيان والتفاصيل
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'البيان والتفاصيل (اختياري)',
                      hintText: widget.isAdvance
                          ? 'مثال: سلفة نقدية مصاريف عائلية'
                          : 'مثال: تصفية باقي راتب شهر نوفمبر',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // زر التأكيد والصرف
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.isAdvance
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded,
                            size: 20),
                    label: Text(
                      _isSubmitting
                          ? 'جاري الصرف والترحيل...'
                          : (widget.isAdvance
                              ? 'تأكيد وصرف السلفة'
                              : 'تأكيد وصرف الراتب'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
