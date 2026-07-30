import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_status_badge.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';

class JournalEntryLineModel {
  String id;
  String accountId;
  String accountCode;
  String accountName;
  String description;
  double debit;
  double credit;

  JournalEntryLineModel({
    required this.id,
    this.accountId = '',
    this.accountCode = '',
    this.accountName = '',
    this.description = '',
    this.debit = 0.0,
    this.credit = 0.0,
  });
}

class JournalEntryFormSheet extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> entry, List<JournalEntryLineModel> lines) onSave;

  const JournalEntryFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> entry, List<JournalEntryLineModel> lines) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JournalEntryFormSheet(
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (entry, lines) {
          Navigator.of(ctx).pop();
          onSave(entry, lines);
        },
      ),
    );
  }

  @override
  State<JournalEntryFormSheet> createState() => _JournalEntryFormSheetState();
}

class _JournalEntryFormSheetState extends State<JournalEntryFormSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _referenceController;
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _mockAccounts = const [
    {'id': '1101', 'code': '1101', 'name': 'الصندوق (النقدية)'},
    {'id': '1102', 'code': '1102', 'name': 'بنك التضامن'},
    {'id': '1103', 'code': '1103', 'name': 'المدينون (العملاء)'},
    {'id': '2101', 'code': '2101', 'name': 'الموردون (الدائنون)'},
    {'id': '3100', 'code': '3100', 'name': 'رأس المال'},
    {'id': '4100', 'code': '4100', 'name': 'إيرادات المبيعات'},
    {'id': '5100', 'code': '5100', 'name': 'تكلفة المبيعات'},
    {'id': '5200', 'code': '5200', 'name': 'مصروفات تشغيلية'},
    {'id': '5300', 'code': '5300', 'name': 'أرباح/خسائر فروق الصرف'},
  ];

  late List<JournalEntryLineModel> _lines;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _referenceController = TextEditingController();
    _lines = [
      JournalEntryLineModel(id: '1'),
      JournalEntryLineModel(id: '2'),
    ];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0.0, (sum, line) => sum + line.debit);
  double get _totalCredit => _lines.fold(0.0, (sum, line) => sum + line.credit);
  bool get _isBalanced => _totalDebit == _totalCredit && _totalDebit > 0;
  double get _difference => (_totalDebit - _totalCredit).abs();

  void _addLine() {
    setState(() {
      _lines.add(JournalEntryLineModel(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  void _removeLine(int index) {
    if (_lines.length > 2) {
      setState(() {
        _lines.removeAt(index);
      });
    }
  }

  void _submit() {
    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('القيد غير متوازن! يجب أن يتساوى إجمالي المدين مع الدائن')),
      );
      return;
    }

    if (_lines.any((l) => l.accountId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد حساب لكل سطر في القيد')),
      );
      return;
    }

    final entry = {
      'description': _descriptionController.text.trim(),
      'date': _selectedDate.toIso8601String(),
      'reference': _referenceController.text.trim(),
      'totalDebit': _totalDebit,
      'totalCredit': _totalCredit,
      'status': 'Posted',
    };

    widget.onSave(entry, _lines);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return AppModalSheet(
      title: 'إضافة قيد يومية',
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFF10B981),
      onClose: widget.onClose,
      primaryLabel: 'حفظ وترحيل القيد',
      onPrimary: _isBalanced ? _submit : null,
      maxHeightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'البيان / الوصف *',
                  hint: 'مثال: إثبات فاتورة مشتريات',
                  controller: _descriptionController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppTextField(
                  label: 'التاريخ',
                  initialValue: '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppTextField(
                  label: 'رقم المرجع',
                  hint: 'INV-001',
                  controller: _referenceController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('البيان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(width: 8),
                Expanded(flex: 1, child: Center(child: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)))),
                SizedBox(width: 8),
                Expanded(flex: 1, child: Center(child: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)))),
                SizedBox(width: 36),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lines List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lines.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final line = _lines[index];
              final selectedAcc = _mockAccounts.cast<Map<String, String>?>().firstWhere(
                (a) => a!['id'] == line.accountId,
                orElse: () => null,
              );

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: '',
                      initialValue: selectedAcc != null ? '${selectedAcc['code']} - ${selectedAcc['name']}' : 'اختر الحساب...',
                      readOnly: true,
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (val) {
                          final acc = _mockAccounts.firstWhere((a) => a['id'] == val);
                          setState(() {
                            line.accountId = acc['id']!;
                            line.accountCode = acc['code']!;
                            line.accountName = acc['name']!;
                          });
                        },
                        itemBuilder: (ctx) => _mockAccounts
                            .map((acc) => PopupMenuItem(
                                  value: acc['id'],
                                  child: Text('${acc['code']} - ${acc['name']}'),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: '',
                      hint: 'شرح السطر...',
                      initialValue: line.description,
                      onChanged: (val) => line.description = val,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: AppNumberField(
                      label: '',
                      hint: '0',
                      initialValue: line.debit > 0 ? line.debit.toString() : '',
                      onChanged: (val) {
                        setState(() {
                          line.debit = double.tryParse(val) ?? 0.0;
                          if (line.debit > 0) {
                            line.credit = 0.0;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: AppNumberField(
                      label: '',
                      hint: '0',
                      initialValue: line.credit > 0 ? line.credit.toString() : '',
                      onChanged: (val) {
                        setState(() {
                          line.credit = double.tryParse(val) ?? 0.0;
                          if (line.credit > 0) {
                            line.debit = 0.0;
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: IconButton(
                      onPressed: _lines.length > 2 ? () => _removeLine(index) : null,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: _lines.length > 2 ? Colors.red : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 20),
            label: const Text(
              'إضافة سطر جديد للقيد',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor),
          const SizedBox(height: 12),

          // Summary & Balance Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إجمالي المدين', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        _totalDebit.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إجمالي الدائن', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        _totalCredit.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
              AppStatusBadge(
                label: _isBalanced ? 'القيد متوازن' : 'غير متوازن (${_difference.toStringAsFixed(0)})',
                variant: _isBalanced ? AppStatusBadgeVariant.success : AppStatusBadgeVariant.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
