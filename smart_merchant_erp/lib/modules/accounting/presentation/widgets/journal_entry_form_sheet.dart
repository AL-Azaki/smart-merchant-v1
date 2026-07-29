import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

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
  final Function(Map<String, dynamic> entry, List<JournalEntryLineModel> lines) onSave;

  const JournalEntryFormSheet({
    super.key,
    required this.onClose,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    required Function(Map<String, dynamic> entry, List<JournalEntryLineModel> lines) onSave,
  }) {
    showModalBottomSheet(
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
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.description_outlined, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'إضافة قيد يومية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close_rounded, color: textPrimary, size: 22),
                ),
              ],
            ),
          ),

          // ── Scrollable Form Area (Top Fields + Lines Table) ──
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Fields (Description, Date, Ref)
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: surface,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('البيان / الوصف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _descriptionController,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'مثال: إثبات فاتورة مشتريات',
                                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('التاريخ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  GestureDetector(
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
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                                          ),
                                          Icon(Icons.calendar_today_rounded, size: 16, color: textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم المرجع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _referenceController,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'INV-001',
                                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Table Column Headers ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: Border.symmetric(horizontal: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('الحساب', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: Text('البيان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary))),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: Text('مدين', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary))),
                        const SizedBox(width: 8),
                        Expanded(flex: 1, child: Text('دائن', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary))),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),

                  // ── Lines List ──
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      return Row(
                        children: [
                          // Account dropdown
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: line.accountId.isEmpty ? null : line.accountId,
                                  hint: Text('اختر الحساب...', style: TextStyle(fontSize: 12, color: textSecondary)),
                                  isExpanded: true,
                                  items: _mockAccounts.map((acc) {
                                    return DropdownMenuItem(
                                      value: acc['id'],
                                      child: Text(
                                        '${acc['code']} - ${acc['name']}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    final acc = _mockAccounts.firstWhere((a) => a['id'] == val);
                                    setState(() {
                                      line.accountId = acc['id']!;
                                      line.accountCode = acc['code']!;
                                      line.accountName = acc['name']!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Line description
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                onChanged: (val) => line.description = val,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'شرح السطر...',
                                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 12),
                                  filled: true,
                                  fillColor: surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Debit
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: line.debit > 0 ? const Color(0xFF3B82F6) : textPrimary,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    line.debit = double.tryParse(val) ?? 0.0;
                                    if (line.debit > 0) line.credit = 0.0;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: '0',
                                  filled: true,
                                  fillColor: surface,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Credit
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: line.credit > 0 ? const Color(0xFFEF4444) : textPrimary,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    line.credit = double.tryParse(val) ?? 0.0;
                                    if (line.credit > 0) line.debit = 0.0;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: '0',
                                  filled: true,
                                  fillColor: surface,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Delete button
                          IconButton(
                            onPressed: _lines.length > 2 ? () => _removeLine(index) : null,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: _lines.length > 2 ? const Color(0xFFEF4444) : textSecondary.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF10B981), size: 20),
                      label: const Text(
                        'إضافة سطر',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),

          // ── Bottom Summary & Actions ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إجمالي المدين', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              _totalDebit.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إجمالي الدائن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              _totalCredit.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isBalanced
                            ? const Color(0xFF10B981).withOpacity(0.12)
                            : const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isBalanced ? Icons.check_rounded : Icons.close_rounded,
                            size: 16,
                            color: _isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isBalanced ? 'متوازن' : 'غير متوازن (${_difference.toStringAsFixed(0)})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _isBalanced ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('إلغاء', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textSecondary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isBalanced ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isBalanced ? const Color(0xFF10B981) : borderColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          label: const Text('حفظ وترحيل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
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
