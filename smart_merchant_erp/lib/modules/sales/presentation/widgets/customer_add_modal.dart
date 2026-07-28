import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/getit_providers.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/custom_text_field.dart';
import '../../../../shared/forms/app_field_config.dart';
import '../../application/services/customer_application_service.dart';
import '../providers/pos_provider.dart';

class CustomerAddModal extends ConsumerStatefulWidget {
  const CustomerAddModal({super.key});

  @override
  ConsumerState<CustomerAddModal> createState() => _CustomerAddModalState();
}

class _CustomerAddModalState extends ConsumerState<CustomerAddModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final value = _nameController.value;
      print('ARABIC TEST [addListener] text: "${value.text}"');
      print('ARABIC TEST [addListener] runes: ${value.text.runes.toList()}');
      print('ARABIC TEST [addListener] selection: ${value.selection}');
      print('ARABIC TEST [addListener] composing: ${value.composing}');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person_add_rounded, color: AppColors.primary),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'إضافة عميل جديد',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'اسم العميل / الشركة *',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline),
                fieldType: AppFieldType.humanName,
                isRequired: true,
                style: const TextStyle(
                  fontFamily: null,
                  color: Colors.black,
                  fontSize: 16,
                  height: 1.5,
                ),
                onChanged: (val) {
                  print('ARABIC TEST [onChanged] val: "$val"');
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'رقم الهاتف (اختياري)',
                controller: _phoneController,
                prefixIcon: const Icon(Icons.phone_outlined),
                fieldType: AppFieldType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'البريد الإلكتروني (اختياري)',
                controller: _emailController,
                prefixIcon: const Icon(Icons.email_outlined),
                fieldType: AppFieldType.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'العنوان (اختياري)',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on_outlined),
                fieldType: AppFieldType.generalText,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'حفظ واختيار العميل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final service = getIt<CustomerApplicationService>();
    final result = await service.saveCustomer(
      CustomerCommand(
        name: name,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      ),
    );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        }
      },
      (customerId) {
        if (mounted) {
          ref.read(posNotifierProvider.notifier).setCustomer(customerId, name);
          Navigator.pop(context);
        }
      },
    );
  }
}
