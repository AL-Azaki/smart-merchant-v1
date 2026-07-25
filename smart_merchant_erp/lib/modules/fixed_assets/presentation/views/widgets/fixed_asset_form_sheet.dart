import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

class FixedAssetFormSheet extends StatefulWidget {
  final Map<String, dynamic>? asset;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const FixedAssetFormSheet({
    super.key,
    this.asset,
    required this.onClose,
    required this.onSave,
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
    _nameController = TextEditingController(text: widget.asset?['name'] ?? '');
    _codeController = TextEditingController(text: widget.asset?['code'] ?? '');
    _costController = TextEditingController(text: (widget.asset?['cost'] ?? '').toString());
    _dateController = TextEditingController(text: widget.asset?['purchase_date'] ?? DateTime.now().toIso8601String().split('T').first);
    
    _category = widget.asset?['category'] ?? 'أجهزة إلكترونية';
    _location = widget.asset?['location'] ?? 'المستودع الرئيسي';
    _status = widget.asset?['status'] ?? 'excellent';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 500,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.asset == null ? 'تسجيل أصل ثابت جديد' : 'تعديل بيانات الأصل',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          
          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الأصل *',
                        border: OutlineInputBorder(),
                        hintText: 'طابعة، مكيف، سيارة...',
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال اسم الأصل' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: 'الكود / الرقم التسلسلي *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'يرجى إدخال كود الأصل' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'التصنيف',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'أجهزة إلكترونية', child: Text('أجهزة إلكترونية')),
                              DropdownMenuItem(value: 'أثاث ومعدات', child: Text('أثاث ومعدات')),
                              DropdownMenuItem(value: 'مركبات ووسائل نقل', child: Text('مركبات ووسائل نقل')),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'تكلفة الشراء (YER)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الشراء',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _location,
                            decoration: const InputDecoration(
                              labelText: 'موقع الأصل / المستودع',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'المستودع الرئيسي', child: Text('المستودع الرئيسي')),
                              DropdownMenuItem(value: 'مستودع الفروع', child: Text('مستودع الفروع')),
                            ],
                            onChanged: (v) => setState(() => _location = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'حالة التشغيل',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'excellent', child: Text('يعمل بممتاز')),
                              DropdownMenuItem(value: 'needs_maintenance', child: Text('يحتاج صيانة')),
                              DropdownMenuItem(value: 'broken', child: Text('خارج الخدمة / تالف')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'حفظ',
                            onPressed: _submit,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('إلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
