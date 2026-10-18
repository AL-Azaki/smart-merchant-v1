import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../kernel/storage/app_database.dart';
import '../../../../../catalog/presentation/views/widgets/catalog_formatters.dart';
import '../../../../application/services/stock_count_workflow.dart';
import '../../../providers/stock_counts_provider.dart';
import '../../../widgets/inventory_dialog_frame.dart';

class StockCountSettlementDialog extends ConsumerStatefulWidget {
  final StockCountDocument document;
  const StockCountSettlementDialog({required this.document, super.key});
  static Future<bool?> show(BuildContext context, StockCountDocument doc) =>
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => StockCountSettlementDialog(document: doc),
      );
  @override
  ConsumerState<StockCountSettlementDialog> createState() =>
      _StockCountSettlementDialogState();
}

class _StockCountSettlementDialogState
    extends ConsumerState<StockCountSettlementDialog> {
  String? _lossAccount, _gainAccount, _employee, _error;
  bool _onEmployee = false, _busy = false;
  Widget _select(
    String label,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final e in options.entries)
        DropdownMenuItem(
          value: e.key,
          child: Text(e.value, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );
  Future<void> _submit() async {
    final doc = widget.document;
    if (_busy) {
      return;
    }
    if (doc.shortage > 0 &&
            (_onEmployee ? _employee == null : _lossAccount == null) ||
        doc.surplus > 0 && _gainAccount == null) {
      setState(
        () => _error =
            'اختر جهة تحميل العجز وحساب الزيادة بحسب الفروقات الموجودة.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(stockCountWorkflowProvider)
          .settle(
            doc.count.id,
            lossAccountId: _onEmployee ? null : _lossAccount,
            gainAccountId: _gainAccount,
            employeeId: _onEmployee ? _employee : null,
          );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is InventoryWorkflowException
              ? e.message
              : 'تعذرت معالجة الفروقات. لم يتغير المخزون، حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final accountState = ref.watch(stockCountAccountsProvider);
    final accounts = accountState.valueOrNull ?? <ChartOfAccount>[];
    final employees = ref.watch(stockCountEmployeesProvider);
    return InventoryDialogFrame(
      title: 'معالجة فروقات الجرد',
      actionLabel: 'تأكيد المعالجة المالية',
      icon: Icons.account_balance_outlined,
      onClose: () => Navigator.pop(context),
      onAction: _submit,
      busy: _busy,
      error: _error,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'المخزون مصحّح بالفعل. هذه الخطوة تنقل الفروقات من الحساب المعلّق إلى الجهة التي تحددها، دون تغيير الكميات مرة أخرى.',
          ),
          const SizedBox(height: 24),
          if (accountState.isLoading) const LinearProgressIndicator(),
          if (accountState.hasError)
            TextButton.icon(
              onPressed: () => ref.invalidate(stockCountAccountsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة تحميل الحسابات'),
            ),
          if (doc.shortage > 0) ...[
            Text(
              'قيمة العجز: ${formatCatalogPrice(doc.shortage, doc.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.trending_down, size: 18),
                  label: const Text('الخسائر والمصروفات'),
                  selected: !_onEmployee,
                  onSelected: (_) => setState(() => _onEmployee = false),
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: const Text('تحميل على موظف'),
                  selected: _onEmployee,
                  onSelected: (_) => setState(() => _onEmployee = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_onEmployee)
              _select(
                'حساب تحميل العجز',
                _lossAccount,
                {
                  for (final a in accounts.where((a) => a.accountTypeId == 5))
                    a.id: catalogDisplayName(a.accountName),
                },
                (id) => setState(() => _lossAccount = id),
              )
            else ...[
              _select('الموظف المسؤول', _employee, {
                for (final e in employees.valueOrNull ?? <Employee>[])
                  e.id: '${e.firstName} ${e.lastName}',
              }, (id) => setState(() => _employee = id)),
              const SizedBox(height: 8),
              Text(
                employees.isLoading
                    ? 'جارٍ تحميل الموظفين…'
                    : employees.hasError
                    ? 'تعذر تحميل الموظفين.'
                    : (employees.valueOrNull?.isEmpty ?? true)
                    ? 'لا يوجد موظفون نشطون. أضف الموظف في قسم الموظفين أولاً.'
                    : 'تُنشأ ذمة مستقلة باسم الموظف، ولا تُخصم من راتبه تلقائياً.',
                style: const TextStyle(fontSize: 12),
              ),
              if (employees.hasError)
                TextButton(
                  onPressed: () => ref.invalidate(stockCountEmployeesProvider),
                  child: const Text('إعادة تحميل الموظفين'),
                ),
            ],
          ],
          if (doc.surplus > 0) ...[
            const SizedBox(height: 24),
            Text(
              'قيمة الزيادة: ${formatCatalogPrice(doc.surplus, doc.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _select(
              'حساب إثبات الزيادة',
              _gainAccount,
              {
                for (final a in accounts.where((a) => a.accountTypeId == 4))
                  a.id: catalogDisplayName(a.accountName),
              },
              (id) => setState(() => _gainAccount = id),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'راجع جهة التحميل قبل التأكيد. بعد تسجيل القيد لا يمكن تكرار المعالجة من الجرد نفسه.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
