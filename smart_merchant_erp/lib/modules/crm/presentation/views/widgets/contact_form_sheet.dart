import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../../shared/design_system/widgets/app_text_field.dart';

class ContactFormSheet extends StatefulWidget {
  final Map<String, dynamic>? contact;
  final bool isCustomer;
  final VoidCallback onClose;
  final void Function(Map<String, dynamic> data) onSave;

  const ContactFormSheet({
    required this.isCustomer,
    required this.onClose,
    required this.onSave,
    super.key,
    this.contact,
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
    _nameController = TextEditingController(text: widget.contact?['name']?.toString() ?? '');
    _contactPersonController = TextEditingController(text: widget.contact?['contact_person']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.contact?['phone']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.contact?['email']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.contact?['address']?.toString() ?? '');
    _creditLimitController = TextEditingController(text: widget.contact?['credit_limit']?.toString() ?? '');
    _openingBalanceController = TextEditingController(text: widget.contact?['opening_balance']?.toString() ?? '');
    _openingBalanceNotesController = TextEditingController(text: widget.contact?['opening_balance_notes']?.toString() ?? '');
    _openingBalanceType = widget.contact?['opening_balance_type']?.toString() ?? 'debit';
    if (widget.contact?['opening_balance_date'] != null) {
      _openingBalanceDate = DateTime.tryParse(widget.contact!['opening_balance_date'].toString()) ?? DateTime.now();
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
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isEdit = widget.contact != null;
    final titleText = isEdit
        ? (widget.isCustomer ? 'تعديل بيانات العميل' : 'تعديل بيانات المورد')
        : (widget.isCustomer ? 'إضافة عميل جديد' : 'إضافة مورد جديد');

    return AppModalSheet(
      title: titleText,
      icon: widget.isCustomer ? Icons.person_outline : Icons.business_outlined,
      iconColor: Colors.deepPurple,
      onClose: widget.onClose,
      primaryLabel: 'حفظ البيانات',
      onPrimary: _submit,
      maxHeightFactor: 0.9,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // قسم المعلومات الأساسية
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Text('المعلومات الأساسية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: widget.isCustomer ? 'اسم العميل *' : 'اسم المورد / الشركة *',
                    hint: 'أدخل الاسم الثلاثي أو اسم الشركة',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
                  ),
                  if (!widget.isCustomer) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'الشخص المسؤول (اختياري)',
                      hint: 'اسم الشخص المسؤول في الشركة',
                      controller: _contactPersonController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ],
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final phoneField = AppTextField(
                        label: 'رقم الهاتف',
                        hint: '05xxxxxxxx',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      );
                      final addressField = AppTextField(
                        label: 'العنوان',
                        hint: 'المدينة، الشارع',
                        controller: _addressController,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            phoneField,
                            const SizedBox(height: 14),
                            addressField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: phoneField),
                          const SizedBox(width: 12),
                          Expanded(child: addressField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // قسم المعلومات المالية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.credit_card_outlined, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('المعلومات المالية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppNumberField(
                    label: 'الحد الائتماني',
                    hint: '0.00',
                    controller: _creditLimitController,
                    suffixIcon: const Icon(Icons.credit_card_outlined),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor),
                  const SizedBox(height: 12),
                  const Text('الرصيد الافتتاحي (أول المدة)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final balanceField = AppNumberField(
                        label: 'مبلغ الرصيد الافتتاحي',
                        hint: '0.00',
                        controller: _openingBalanceController,
                      );
                      final typeField = AppTextField(
                        label: 'نوع الرصيد',
                        initialValue: _openingBalanceType == 'debit'
                            ? (widget.isCustomer ? 'مدين (لنا)' : 'مدين (مستحق لنا)')
                            : (widget.isCustomer ? 'دائن (علينا)' : 'دائن (علينا)'),
                        readOnly: true,
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => setState(() => _openingBalanceType = val),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'debit',
                              child: Text(widget.isCustomer ? 'مدين (لنا)' : 'مدين (مستحق لنا)'),
                            ),
                            PopupMenuItem(
                              value: 'credit',
                              child: Text(widget.isCustomer ? 'دائن (علينا)' : 'دائن (علينا)'),
                            ),
                          ],
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            balanceField,
                            const SizedBox(height: 14),
                            typeField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: balanceField),
                          const SizedBox(width: 12),
                          Expanded(child: typeField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'تاريخ إدخال الرصيد الافتتاحي',
                    initialValue:
                        "${_openingBalanceDate.year}-${_openingBalanceDate.month.toString().padLeft(2, '0')}-${_openingBalanceDate.day.toString().padLeft(2, '0')}",
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
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
                  ),
                  const SizedBox(height: 14),
                  AppMultilineField(
                    label: 'البيان / تفاصيل الرصيد (اختياري)',
                    hint: 'أدخل أي ملاحظات إضافية بخصوص الرصيد',
                    controller: _openingBalanceNotesController,
                    lines: 2,
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
