import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

class DocumentFormSheet extends StatefulWidget {
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const DocumentFormSheet({
    super.key,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends State<DocumentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _refNumberController;
  late TextEditingController _issueDateController;
  late TextEditingController _expiryDateController;
  late TextEditingController _notesController;

  String _category = 'invoice';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _refNumberController = TextEditingController();
    _issueDateController = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    _expiryDateController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _refNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'title': _titleController.text,
        'category': _category,
        'ref_number': _refNumberController.text,
        'issue_date': _issueDateController.text,
        'expiry_date': _expiryDateController.text,
        'notes': _notesController.text,
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.description_outlined, color: Colors.purple),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'أرشفة مستند جديد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
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
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الوثيقة / المستند *',
                        border: OutlineInputBorder(),
                        hintText: 'مثال: رخصة مزاولة المهنة 2026',
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى كتابة اسم المستند' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'تصنيف المستند *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'invoice', child: Text('فاتورة مصورة')),
                              DropdownMenuItem(value: 'contract', child: Text('عقود واتفاقيات')),
                              DropdownMenuItem(value: 'license', child: Text('تراخيص وبطاقات')),
                              DropdownMenuItem(value: 'other', child: Text('أخرى')),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _refNumberController,
                            decoration: const InputDecoration(
                              labelText: 'رقم المرجع / الوثيقة',
                              border: OutlineInputBorder(),
                              hintText: 'REF-XXXX',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _issueDateController,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الإصدار',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _expiryDateController,
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الانتهاء (تنبيه)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Image upload mock
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 8),
                          Text('إرفاق صورة أو التقاطها', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات إضافية',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'أرشفة',
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
