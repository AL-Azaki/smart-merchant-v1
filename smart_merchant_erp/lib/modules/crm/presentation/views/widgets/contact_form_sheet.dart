import 'package:flutter/material.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/widgets/primary_button.dart';

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
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.contact?['phone'] ?? '');
    _emailController = TextEditingController(text: widget.contact?['email'] ?? '');
    _addressController = TextEditingController(text: widget.contact?['address'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'id': widget.contact?['id'],
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Container(
      width: 600,
      height: MediaQuery.of(context).size.height * 0.8,
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          color: widget.isCustomer ? AppColors.primary.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isCustomer ? Icons.person_outline : Icons.storefront_outlined,
                          color: widget.isCustomer ? AppColors.primary : AppColors.warning,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contact == null
                              ? (widget.isCustomer ? 'إضافة عميل جديد' : 'إضافة مورد جديد')
                              : (widget.isCustomer ? 'تعديل بيانات العميل' : 'تعديل بيانات المورد'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.red),
                  style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: widget.isCustomer ? 'اسم العميل *' : 'اسم المورد / الشركة *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان التفصيلي',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 16),
                PrimaryButton(
                  text: 'حفظ البيانات',
                  icon: Icons.check,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
