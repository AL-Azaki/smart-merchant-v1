import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';

class TransactionFormSheet extends StatefulWidget {
  final String initialType; // 'income' | 'expense'
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data, bool print) onSave;

  const TransactionFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.initialType = 'income',
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> data, bool print) onSave,
    String initialType = 'income',
  }) {
    showModalBottomSheet<void>(
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
    final isIncome = _currentType == 'income';
    final primaryColor = isIncome ? Colors.blue : Colors.red;

    return AppModalSheet(
      title: 'سند مالي جديد',
      icon: Icons.receipt_long_outlined,
      iconColor: primaryColor,
      onClose: widget.onClose,
      primaryLabel: 'حفظ السند المالي',
      onPrimary: _submit,
      maxHeightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle switch (Receipt / Payment)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleType('income'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isIncome ? (isDark ? AppColors.surfaceDark : Colors.white) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, size: 18, color: isIncome ? Colors.blue : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'سند قبض (دخول)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isIncome ? FontWeight.bold : FontWeight.w600,
                              color: isIncome ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleType('expense'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isIncome ? (isDark ? AppColors.surfaceDark : Colors.white) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_upward, size: 18, color: !isIncome ? Colors.red : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'سند صرف (خروج)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !isIncome ? FontWeight.bold : FontWeight.w600,
                              color: !isIncome ? Colors.red : Colors.grey,
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
          const SizedBox(height: 16),

          // Card 1: Amount & Currency & Payment Method
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'تفاصيل المبلغ وطريقة الدفع',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppNumberField(
                        label: 'المبلغ *',
                        hint: '0.00',
                        controller: _amountController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: AppTextField(
                        label: 'العملة',
                        initialValue: _currency,
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _currency = val),
                          itemBuilder: (ctx) => ['YER', 'USD', 'SAR']
                              .map((c) => PopupMenuItem(value: c, child: Text(c)))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'طريقة الدفع',
                  initialValue: _paymentMethod == 'cash' ? 'نقداً (صندوق)' : 'تحويل بنكي / شبكة',
                  readOnly: true,
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (val) => setState(() => _paymentMethod = val),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'cash', child: Text('نقداً (صندوق)')),
                      PopupMenuItem(value: 'bank', child: Text('تحويل بنكي / شبكة')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Entity & Information
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'ارتباط الجهة والمعلومات',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'نوع الجهة',
                        initialValue: _entityType == 'general'
                            ? 'عام (بدون ربط)'
                            : (_entityType == 'customer' ? 'عميل' : (_entityType == 'supplier' ? 'مورد' : 'موظف')),
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _entityType = val),
                          itemBuilder: (ctx) => const [
                            PopupMenuItem(value: 'general', child: Text('عام (بدون ربط)')),
                            PopupMenuItem(value: 'customer', child: Text('عميل')),
                            PopupMenuItem(value: 'supplier', child: Text('مورد')),
                            PopupMenuItem(value: 'employee', child: Text('موظف')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'الجهة المختارة',
                        hint: 'اكتب اسم الجهة...',
                        controller: _entityNameController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'رقم المرجع (اختياري)',
                        hint: 'رقم الفاتورة أو المستند',
                        controller: _referenceController,
                        prefixIcon: const Icon(Icons.tag_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'التصنيف المالي',
                        initialValue: _getCategoryName(_category),
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _category = val),
                          itemBuilder: (ctx) => (isIncome
                              ? const [
                                  PopupMenuItem(value: 'sales', child: Text('إيرادات مبيعات')),
                                  PopupMenuItem(value: 'services', child: Text('إيرادات خدمات')),
                                  PopupMenuItem(value: 'investments', child: Text('عوائد استثمار')),
                                  PopupMenuItem(value: 'other_income', child: Text('إيرادات أخرى')),
                                ]
                              : const [
                                  PopupMenuItem(value: 'salaries', child: Text('رواتب وأجور')),
                                  PopupMenuItem(value: 'rent', child: Text('إيجارات')),
                                  PopupMenuItem(value: 'utilities', child: Text('فواتير خدمات')),
                                  PopupMenuItem(value: 'marketing', child: Text('تسويق وإعلان')),
                                  PopupMenuItem(value: 'maintenance', child: Text('صيانة وإصلاح')),
                                  PopupMenuItem(value: 'office_supplies', child: Text('مستلزمات مكتبية')),
                                  PopupMenuItem(value: 'other_expense', child: Text('مصروفات أخرى')),
                                ]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppMultilineField(
                  label: 'البيان / الوصف *',
                  hint: 'اكتب تفاصيل المعاملة المالية هنا...',
                  controller: _descriptionController,
                  lines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          CheckboxListTile(
            title: const Text('طباعة السند بعد الحفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            value: _printAfterSave,
            onChanged: (v) => setState(() => _printAfterSave = v ?? true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String cat) {
    switch (cat) {
      case 'sales':
        return 'إيرادات مبيعات';
      case 'services':
        return 'إيرادات خدمات';
      case 'investments':
        return 'عوائد استثمار';
      case 'other_income':
        return 'إيرادات أخرى';
      case 'salaries':
        return 'رواتب وأجور';
      case 'rent':
        return 'إيجارات';
      case 'utilities':
        return 'فواتير خدمات';
      case 'marketing':
        return 'تسويق وإعلان';
      case 'maintenance':
        return 'صيانة وإصلاح';
      case 'office_supplies':
        return 'مستلزمات مكتبية';
      default:
        return 'مصروفات أخرى';
    }
  }
}
