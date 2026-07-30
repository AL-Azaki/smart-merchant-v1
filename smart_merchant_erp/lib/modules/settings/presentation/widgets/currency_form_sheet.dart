import 'package:flutter/material.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';

class CurrencyFormSheet extends StatefulWidget {
  final Map<String, dynamic>? currency;
  final void Function(Map<String, dynamic> data) onSave;

  const CurrencyFormSheet({
    required this.onSave,
    super.key,
    this.currency,
  });

  static void show(
    BuildContext context, {
    required void Function(Map<String, dynamic> data) onSave,
    Map<String, dynamic>? currency,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CurrencyFormSheet(
        currency: currency,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CurrencyFormSheet> createState() => _CurrencyFormSheetState();
}

class _CurrencyFormSheetState extends State<CurrencyFormSheet> {
  late TextEditingController _codeController;
  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _symbolController;
  late TextEditingController _rateController;
  bool _isBase = false;

  @override
  void initState() {
    super.initState();
    final c = widget.currency;
    _codeController = TextEditingController(text: (c?['currency_code'] as String?) ?? '');
    _nameArController = TextEditingController(text: (c?['currency_name_ar'] as String?) ?? '');
    _nameEnController = TextEditingController(text: (c?['currency_name_en'] as String?) ?? '');
    _symbolController = TextEditingController(text: (c?['currency_symbol'] as String?) ?? '');
    _rateController = TextEditingController(
      text: c?['exchange_rate'] != null ? c!['exchange_rate'].toString() : '1',
    );
    _isBase = (c?['is_base_currency'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _symbolController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_codeController.text.trim().isEmpty) {
      return;
    }

    final data = <String, dynamic>{
      'id': widget.currency?['id'] ?? 'cur_${DateTime.now().millisecondsSinceEpoch}',
      'currency_code': _codeController.text.trim().toUpperCase(),
      'currency_name_ar': _nameArController.text.trim(),
      'currency_name_en': _nameEnController.text.trim(),
      'currency_symbol': _symbolController.text.trim(),
      'exchange_rate': double.tryParse(_rateController.text.trim()) ?? 1.0,
      'is_base_currency': _isBase,
      'is_active': widget.currency?['is_active'] ?? true,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.currency != null;

    return AppModalSheet(
      title: isEditing ? 'تعديل العملة' : 'إضافة عملة جديدة',
      icon: Icons.monetization_on_outlined,
      iconColor: Colors.teal,
      onClose: () => Navigator.of(context).pop(),
      primaryLabel: 'حفظ العملة',
      onPrimary: _handleSave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'رمز العملة (مثل USD) *',
            hint: 'YER / USD / SAR',
            controller: _codeController,
            prefixIcon: const Icon(Icons.code_outlined),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'الاسم (عربي) *',
                  hint: 'ريال يمني',
                  controller: _nameArController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'الاسم (إنجليزي)',
                  hint: 'Yemeni Rial',
                  controller: _nameEnController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'الرمز (مثل \$)',
                  hint: 'ر.ي',
                  controller: _symbolController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppNumberField(
                  label: 'سعر الصرف للأساسية',
                  hint: '1',
                  controller: _rateController,
                  enabled: !_isBase,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
