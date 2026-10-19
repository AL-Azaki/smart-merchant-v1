import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
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
  final List<Map<String, String>>? availableAccounts;

  const JournalEntryFormSheet({
    required this.onClose,
    required this.onSave,
    this.availableAccounts,
    super.key,
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> entry, List<JournalEntryLineModel> lines) onSave,
    List<Map<String, String>>? availableAccounts,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
          child: JournalEntryFormSheet(
            availableAccounts: availableAccounts,
            onClose: () => Navigator.of(ctx).pop(),
            onSave: (entry, lines) {
              Navigator.of(ctx).pop();
              onSave(entry, lines);
            },
          ),
        ),
      ),
    );
  }

  @override
  State<JournalEntryFormSheet> createState() => _JournalEntryFormSheetState();
}

class _JournalEntryFormSheetState extends State<JournalEntryFormSheet> {
  late TextEditingController _descriptionController;
  late TextEditingController _referenceController;
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _mockAccounts = const [
    {'id': '1101', 'code': '11101', 'name': 'الصندوق الرئيسي (النقدية)'},
    {'id': '1102', 'code': '11102', 'name': 'بنك التضامن'},
    {'id': '1103', 'code': '11201', 'name': 'المدينون (العملاء)'},
    {'id': '2101', 'code': '21101', 'name': 'الموردون (الدائنون)'},
    {'id': '3100', 'code': '31101', 'name': 'رأس المال'},
    {'id': '4100', 'code': '41101', 'name': 'إيرادات المبيعات'},
    {'id': '5100', 'code': '51101', 'name': 'تكلفة المبيعات'},
    {'id': '5200', 'code': '52101', 'name': 'مصروفات تشغيلية'},
    {'id': '5300', 'code': '53101', 'name': 'أرباح/خسائر فروق الصرف'},
  ];

  late List<JournalEntryLineModel> _lines;

  List<Map<String, String>> get _effectiveAccounts =>
      (widget.availableAccounts != null && widget.availableAccounts!.isNotEmpty)
          ? widget.availableAccounts!
          : _mockAccounts;

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
    _scrollController.dispose();
    super.dispose();
  }

  double get _totalDebit => _lines.fold(0.0, (sum, line) => sum + line.debit);
  double get _totalCredit => _lines.fold(0.0, (sum, line) => sum + line.credit);
  bool get _isBalanced => (_totalDebit - _totalCredit).abs() < 0.005 && _totalDebit > 0;
  double get _difference => (_totalDebit - _totalCredit).abs();

  void _addLine() {
    setState(() {
      _lines.add(JournalEntryLineModel(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _autoBalance() {
    if (_lines.isEmpty) return;
    final diff = _totalDebit - _totalCredit;
    if (diff.abs() < 0.005) return;

    final lastLine = _lines.last;
    setState(() {
      if (diff > 0) {
        lastLine.credit += diff;
        lastLine.debit = 0.0;
      } else {
        lastLine.debit += diff.abs();
        lastLine.credit = 0.0;
      }
    });
  }

  void _removeLine(int index) {
    if (_lines.length > 2) {
      setState(() {
        _lines.removeAt(index);
      });
    }
  }

  void _openAccountPickerDialog(JournalEntryLineModel line) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _effectiveAccounts.where((a) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              final code = a['code']?.toLowerCase() ?? '';
              final name = a['name']?.toLowerCase() ?? '';
              return code.contains(q) || name.contains(q);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'اختر الحساب المحاسبي',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'ابحث برمز أو اسم الحساب...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        setModalState(() => query = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'لا يوجد حساب مطابق للبحث',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final acc = filtered[index];
                                final isSelected = acc['id'] == line.accountId;
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
                                  title: Text(
                                    acc['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected ? AppColors.primary : null,
                                    ),
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      acc['code'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      line.accountId = acc['id']!;
                                      line.accountCode = acc['code']!;
                                      line.accountName = acc['name']!;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      color: bg,
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'إنشاء قيد يومية يدوي',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
          ),

          // 2. Fixed Top Inputs (البيان، التاريخ، المرجع)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    label: 'البيان / الوصف العام للقيد *',
                    hint: 'مثال: إثبات مصاريف تشغيلية، تسوية حسابات...',
                    controller: _descriptionController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: 'تاريخ القيد',
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
                  flex: 2,
                  child: AppTextField(
                    label: 'رقم المرجع / المستند (اختياري)',
                    hint: 'REF-001',
                    controller: _referenceController,
                  ),
                ),
              ],
            ),
          ),

          // 3. Lines Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : const Color(0xFFEDF2F7),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('الحساب المحاسبي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 10),
                Expanded(flex: 3, child: Text('البيان الخاص بالسطر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 10),
                Expanded(flex: 2, child: Center(child: Text('مدين (ر.ي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))))),
                SizedBox(width: 10),
                Expanded(flex: 2, child: Center(child: Text('دائن (ر.ي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFDC2626))))),
                SizedBox(width: 36),
              ],
            ),
          ),

          // 4. Scrollable Lines List
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _lines.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  final bool hasAccount = line.accountId.isNotEmpty;

                  return Row(
                    children: [
                      // A. Clickable Account Picker Box
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () => _openAccountPickerDialog(line),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: hasAccount ? AppColors.primary.withValues(alpha: 0.5) : borderColor,
                                width: hasAccount ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 16,
                                  color: hasAccount ? AppColors.primary : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasAccount
                                        ? '${line.accountCode} - ${line.accountName}'
                                        : 'اختر الحساب المحاسبي...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: hasAccount ? FontWeight.bold : FontWeight.normal,
                                      color: hasAccount ? textPrimary : Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // B. Line Description
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 46,
                          child: TextFormField(
                            initialValue: line.description,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'شرح اختياري...',
                              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
                            onChanged: (val) => line.description = val,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // C. Debit
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: TextFormField(
                            initialValue: line.debit > 0 ? line.debit.toStringAsFixed(0) : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
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
                      ),
                      const SizedBox(width: 10),

                      // D. Credit
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 46,
                          child: TextFormField(
                            initialValue: line.credit > 0 ? line.credit.toStringAsFixed(0) : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              filled: true,
                              fillColor: surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: borderColor),
                              ),
                            ),
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
                      ),

                      // E. Delete Button
                      SizedBox(
                        width: 36,
                        child: IconButton(
                          onPressed: _lines.length > 2 ? () => _removeLine(index) : null,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: _lines.length > 2 ? const Color(0xFFDC2626) : Colors.grey.shade400,
                            size: 20,
                          ),
                          tooltip: 'حذف السطر',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 5. Add Line & Auto Balance Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addLine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                    foregroundColor: const Color(0xFF047857),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'إضافة سطر جديد للقيد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '(${_lines.length} أسطر)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                if (!_isBalanced && _difference > 0)
                  OutlinedButton.icon(
                    onPressed: _autoBalance,
                    icon: const Icon(Icons.balance_rounded, size: 16, color: Color(0xFF2563EB)),
                    label: Text(
                      'موازنة تلقائية (${_difference.toStringAsFixed(2)} ر.ي)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // 6. Bottom Totals and Actions Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي المدين', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            '${_totalDebit.toStringAsFixed(2)} ر.ي',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي الدائن', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(
                            '${_totalCredit.toStringAsFixed(2)} ر.ي',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppStatusBadge(
                      label: _isBalanced
                          ? 'القيد متوازن ✓'
                          : 'غير متوازن (الفرق: ${_difference.toStringAsFixed(2)})',
                      variant: _isBalanced ? AppStatusBadgeVariant.success : AppStatusBadgeVariant.error,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: widget.onClose,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isBalanced ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text(
                        'حفظ وترحيل القيد',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
