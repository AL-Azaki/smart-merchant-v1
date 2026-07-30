import 'package:flutter/material.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class FixedAssetFormSheet extends StatefulWidget {
  final Map<String, dynamic>? asset;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const FixedAssetFormSheet({
    required this.onClose,
    required this.onSave,
    super.key,
    this.asset,
  });

  @override
  State<FixedAssetFormSheet> createState() => _FixedAssetFormSheetState();
}

class _FixedAssetFormSheetState extends State<FixedAssetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _costController;
  late TextEditingController _dateController;

  String _category = 'أجهزة إلكترونية';
  String _location = 'المستودع الرئيسي';
  String _status = 'excellent';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?['name']?.toString() ?? '');
    _codeController = TextEditingController(text: widget.asset?['code']?.toString() ?? '');
    _costController = TextEditingController(text: (widget.asset?['cost'] ?? '').toString());
    _dateController = TextEditingController(text: widget.asset?['purchase_date']?.toString() ?? DateTime.now().toIso8601String().split('T').first);
    
    _category = widget.asset?['category']?.toString() ?? 'أجهزة إلكترونية';
    _location = widget.asset?['location']?.toString() ?? 'المستودع الرئيسي';
    _status = widget.asset?['status']?.toString() ?? 'excellent';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _costController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.asset?['id'],
        'name': _nameController.text,
        'code': _codeController.text,
        'category': _category,
        'cost': double.tryParse(_costController.text) ?? 0.0,
        'purchase_date': _dateController.text,
        'location': _location,
        'status': _status,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.asset != null;

    return AppModalSheet(
      title: isEdit ? 'تعديل بيانات الأصل' : 'تسجيل أصل ثابت جديد',
      icon: Icons.account_balance_outlined,
      iconColor: Colors.blue,
      onClose: widget.onClose,
      primaryLabel: 'حفظ الأصل',
      onPrimary: _submit,
      maxHeightFactor: 0.8,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم الأصل *',
              hint: 'طابعة، مكيف، سيارة...',
              controller: _nameController,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الأصل' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'الكود / الرقم التسلسلي *',
                    hint: 'AST-001',
                    controller: _codeController,
                    prefixIcon: const Icon(Icons.qr_code_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال كود الأصل' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'التصنيف',
                    initialValue: _category,
                    readOnly: true,
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (val) => setState(() => _category = val),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'أجهزة إلكترونية', child: Text('أجهزة إلكترونية')),
                        PopupMenuItem(value: 'أثاث ومعدات', child: Text('أثاث ومعدات')),
                        PopupMenuItem(value: 'مركبات ووسائل نقل', child: Text('مركبات ووسائل نقل')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppNumberField(
                    label: 'تكلفة الشراء (YER)',
                    hint: '0.00',
                    controller: _costController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'تاريخ الشراء',
                    controller: _dateController,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() => _dateController.text = d.toIso8601String().split('T').first);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'موقع الأصل / المستودع',
                    initialValue: _location,
                    readOnly: true,
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (val) => setState(() => _location = val),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'المستودع الرئيسي', child: Text('المستودع الرئيسي')),
                        PopupMenuItem(value: 'مستودع الفروع', child: Text('مستودع الفروع')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'حالة التشغيل',
                    initialValue: _status == 'excellent'
                        ? 'يعمل بممتاز'
                        : (_status == 'needs_maintenance' ? 'يحتاج صيانة' : 'خارج الخدمة / تالف'),
                    readOnly: true,
                    suffixIcon: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (val) => setState(() => _status = val),
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'excellent', child: Text('يعمل بممتاز')),
                        PopupMenuItem(value: 'needs_maintenance', child: Text('يحتاج صيانة')),
                        PopupMenuItem(value: 'broken', child: Text('خارج الخدمة / تالف')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
