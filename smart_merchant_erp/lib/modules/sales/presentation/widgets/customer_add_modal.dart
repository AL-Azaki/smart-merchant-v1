import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/injection.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_modal_sheet.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppModalSheet(
      title: 'إضافة عميل جديد',
      icon: Icons.person_add_outlined,
      iconColor: AppColors.primary,
      onClose: () => Navigator.pop(context),
      primaryLabel: 'حفظ واختيار العميل',
      onPrimary: _isLoading ? null : _saveCustomer,
      isLoading: _isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'اسم العميل / الشركة *',
              hint: 'أدخل الاسم الكامل للعميل أو المنشأة',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم العميل' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'رقم الهاتف (اختياري)',
              hint: '05xxxxxxxx أو 77xxxxxxx',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'البريد الإلكتروني (اختياري)',
              hint: 'example@domain.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'العنوان (اختياري)',
              hint: 'المدينة، الشارع، المبنى',
              controller: _addressController,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ],
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
