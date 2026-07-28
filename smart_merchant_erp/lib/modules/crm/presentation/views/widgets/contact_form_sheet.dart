import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../../shared/forms/app_field_config.dart';
import '../../../../../shared/forms/app_input_formatters.dart';

class ContactFormSheet extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final bool isCustomer;
  final VoidCallback onClose;
  final Function(Map<String, dynamic>) onSave;

  const ContactFormSheet({
    super.key,
    this.contact,
    required this.isCustomer,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _creditLimitController;
  late TextEditingController _openingBalanceController;
  late TextEditingController _openingBalanceNotesController;

  String _openingBalanceType = 'debit';
  DateTime _openingBalanceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?['name'] ?? '');
    _contactPersonController = TextEditingController(text: widget.contact?['contact_person'] ?? '');
    _phoneController = TextEditingController(text: widget.contact?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.contact?['email'] ?? '');
    _addressController = TextEditingController(text: widget.contact?['address'] ?? '');
    _creditLimitController = TextEditingController(text: widget.contact?['credit_limit']?.toString() ?? '');
    _openingBalanceController = TextEditingController(text: widget.contact?['opening_balance']?.toString() ?? '');
    _openingBalanceNotesController = TextEditingController(text: widget.contact?['opening_balance_notes'] ?? '');
    _openingBalanceType = widget.contact?['opening_balance_type'] ?? 'debit';
    if (widget.contact?['opening_balance_date'] != null) {
      _openingBalanceDate = DateTime.tryParse(widget.contact!['opening_balance_date']) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _openingBalanceNotesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.contact?['id'],
        'name': _nameController.text,
        'contact_person': _contactPersonController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'credit_limit': _creditLimitController.text,
        'opening_balance': _openingBalanceController.text,
        'opening_balance_type': _openingBalanceType,
        'opening_balance_date': _openingBalanceDate.toIso8601String(),
        'opening_balance_notes': _openingBalanceNotesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? borderColor : Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 48,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.contact == null
                            ? (widget.isCustomer ? 'إضافة عميل جديد' : 'إضافة مورد جديد')
                            : (widget.isCustomer ? 'تعديل بيانات العميل' : 'تعديل بيانات المورد'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isCustomer ? 'أدخل تفاصيل العميل بدقة' : 'أدخل تفاصيل المورد بدقة',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Basic Info Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 18, color: Colors.deepPurple[400]),
                                const SizedBox(width: 8),
                                const Text('المعلومات الأساسية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: widget.isCustomer ? 'اسم العميل *' : 'اسم المورد / الشركة *',
                              controller: _nameController,
                              fieldType: AppFieldType.generalText,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            if (!widget.isCustomer) ...[
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'الشخص المسؤول (اختياري)',
                                controller: _contactPersonController,
                                fieldType: AppFieldType.generalText,
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                            ],
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                Widget phoneField = CustomTextField(
                                  label: 'رقم الهاتف',
                                  controller: _phoneController,
                                  fieldType: AppFieldType.phone,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                );
                                Widget addressField = CustomTextField(
                                  label: 'العنوان',
                                  controller: _addressController,
                                  fieldType: AppFieldType.generalText,
                                  prefixIcon: const Icon(Icons.location_on_outlined),
                                );

                                if (isMobile) {
                                  return Column(
                                    children: [
                                      phoneField,
                                      const SizedBox(height: 16),
                                      addressField,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: phoneField),
                                    const SizedBox(width: 16),
                                    Expanded(child: addressField),
                                  ],
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Financial Info Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.credit_card_outlined, size: 18, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text('المعلومات المالية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: 'الحد الائتماني',
                              controller: _creditLimitController,
                              fieldType: AppFieldType.decimal,
                              prefixIcon: const Icon(Icons.credit_card_outlined),
                            ),
                            
                            const SizedBox(height: 16),
                            Divider(color: isDark ? borderColor : Colors.grey[100]),
                            const SizedBox(height: 16),
                            
                            const Text('الرصيد الافتتاحي (أول المدة)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 600;
                                Widget balanceField = CustomTextField(
                                  label: 'مبلغ الرصيد الافتتاحي',
                                  controller: _openingBalanceController,
                                  fieldType: AppFieldType.decimal,
                                );
                                Widget typeField = DropdownButtonFormField<String>(
                                  value: _openingBalanceType,
                                  decoration: InputDecoration(
                                    labelText: 'نوع الرصيد',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'debit', child: Text(widget.isCustomer ? 'مدين (لنا)' : 'مدين (مستحق لنا)')),
                                    DropdownMenuItem(value: 'credit', child: Text(widget.isCustomer ? 'دائن (علينا)' : 'دائن (علينا)')),
                                  ],
                                  onChanged: (v) => setState(() => _openingBalanceType = v ?? 'debit'),
                                );
                                
                                if (isMobile) {
                                  return Column(
                                    children: [
                                      balanceField,
                                      const SizedBox(height: 16),
                                      typeField,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: balanceField),
                                    const SizedBox(width: 16),
                                    Expanded(child: typeField),
                                  ],
                                );
                              }
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: _openingBalanceDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) {
                                  setState(() => _openingBalanceDate = d);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'تاريخ إدخال الرصيد الافتتاحي',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                child: Text("${_openingBalanceDate.year}-${_openingBalanceDate.month.toString().padLeft(2, '0')}-${_openingBalanceDate.day.toString().padLeft(2, '0')}"),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'البيان / تفاصيل الرصيد (اختياري)',
                              controller: _openingBalanceNotesController,
                              fieldType: AppFieldType.generalText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 60,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: widget.onClose,
                        child: const Text('إلغاء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _submit,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 24),
                            SizedBox(width: 10),
                            Text('حفظ البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}
