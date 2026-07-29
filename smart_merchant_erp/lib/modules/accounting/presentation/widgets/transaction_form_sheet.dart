import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';

class TransactionFormSheet extends StatefulWidget {
  final String initialType; // 'income' | 'expense'
  final VoidCallback onClose;
  final Function(Map<String, dynamic> data, bool print) onSave;

  const TransactionFormSheet({
    super.key,
    this.initialType = 'income',
    required this.onClose,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    String initialType = 'income',
    required Function(Map<String, dynamic> data, bool print) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionFormSheet(
        initialType: initialType,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data, print) {
          Navigator.of(ctx).pop();
          onSave(data, print);
        },
      ),
    );
  }

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late String _currentType;
  late TextEditingController _amountController;
  late TextEditingController _entityNameController;
  late TextEditingController _referenceController;
  late TextEditingController _descriptionController;

  String _currency = 'YER';
  String _paymentMethod = 'cash';
  String _entityType = 'general';
  String _category = 'sales';
  bool _printAfterSave = true;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _category = _currentType == 'income' ? 'sales' : 'other_expense';
    _amountController = TextEditingController();
    _entityNameController = TextEditingController();
    _referenceController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _entityNameController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleType(String type) {
    setState(() {
      _currentType = type;
      _category = type == 'income' ? 'sales' : 'other_expense';
    });
  }

  void _submit() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال البيان / الوصف')),
      );
      return;
    }

    final data = {
      'type': _currentType,
      'amount': double.parse(amountText),
      'currency_id': _currency,
      'exchange_rate': 1.0,
      'base_amount': double.parse(amountText),
      'entity_type': _entityType,
      'entity_name': _entityNameController.text.trim(),
      'payment_method': _paymentMethod,
      'reference': _referenceController.text.trim(),
      'category': _category,
      'description': _descriptionController.text.trim(),
    };

    widget.onSave(data, _printAfterSave);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isIncome = _currentType == 'income';
    final primaryColor = isIncome ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.description_outlined, color: textPrimary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سند مالي جديد',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'حدد نوع السند (قبض / صرف) وأدخل التفاصيل',
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.close_rounded, color: textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Toggle switch (Receipt / Payment)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleType('income'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            decoration: BoxDecoration(
                              color: isIncome ? surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isIncome
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.north_east_rounded, size: 20, color: isIncome ? const Color(0xFF3B82F6) : textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'سند قبض (دخول)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isIncome ? FontWeight.w800 : FontWeight.w600,
                                    color: isIncome ? const Color(0xFF3B82F6) : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleType('expense'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            decoration: BoxDecoration(
                              color: !isIncome ? surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isIncome
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.south_west_rounded, size: 20, color: !isIncome ? const Color(0xFFEF4444) : textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  'سند صرف (خروج)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !isIncome ? FontWeight.w800 : FontWeight.w600,
                                    color: !isIncome ? const Color(0xFFEF4444) : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable Form Fields ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Card 1: Amount & Payment Details ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'تفاصيل المبلغ وطريقة الدفع',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('المبلغ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
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
                                  Text('العملة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _currency,
                                        isExpanded: true,
                                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                                        items: ['YER', 'USD', 'SAR'].map((c) {
                                          return DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)));
                                        }).toList(),
                                        onChanged: (v) => setState(() => _currency = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('طريقة الدفع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _paymentMethod,
                              isExpanded: true,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                              items: const [
                                DropdownMenuItem(value: 'cash', child: Text('نقداً (صندوق)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                                DropdownMenuItem(value: 'bank', child: Text('تحويل بنكي / شبكة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                              ],
                              onChanged: (v) => setState(() => _paymentMethod = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Card 2: Entity & Information Link ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_alt_outlined, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ارتباط الجهة والمعلومات',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('نوع الجهة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _entityType,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'general', child: Text('عام (بدون ربط)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'customer', child: Text('عميل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'supplier', child: Text('مورد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                          DropdownMenuItem(value: 'employee', child: Text('موظف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                        ],
                                        onChanged: (v) => setState(() => _entityType = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الجهة المختارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _entityNameController,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'اكتب الاسم هنا...',
                                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('رقم المرجع (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _referenceController,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'رقم السند/الفاتورة...',
                                      hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                                      prefixIcon: Icon(Icons.tag_rounded, color: textSecondary, size: 18),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('التصنيف المالي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _category,
                                        isExpanded: true,
                                        items: (isIncome
                                            ? const [
                                                DropdownMenuItem(value: 'sales', child: Text('إيرادات مبيعات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'services', child: Text('إيرادات خدمات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'investments', child: Text('عوائد استثمار', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'other_income', child: Text('إيرادات أخرى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                              ]
                                            : const [
                                                DropdownMenuItem(value: 'salaries', child: Text('رواتب وأجور', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'rent', child: Text('إيجارات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'utilities', child: Text('فواتير خدمات (كهرباء، ماء)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'marketing', child: Text('تسويق وإعلان', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'maintenance', child: Text('صيانة وإصلاح', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'office_supplies', child: Text('مستلزمات مكتبية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                                DropdownMenuItem(value: 'other_expense', child: Text('مصروفات أخرى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                              ]),
                                        onChanged: (v) => setState(() => _category = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('البيان / الوصف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'اكتب تفاصيل المعاملة هنا...',
                            hintStyle: TextStyle(color: textSecondary.withOpacity(0.5), fontSize: 13),
                            filled: true,
                            fillColor: bg,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──
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
                  children: [
                    Checkbox(
                      value: _printAfterSave,
                      activeColor: primaryColor,
                      onChanged: (v) => setState(() => _printAfterSave = v ?? true),
                    ),
                    Icon(Icons.print_outlined, color: textSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text('طباعة السند بعد الحفظ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 52,
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
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                          label: const Text('حفظ السند', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
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
