import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _acceptTerms = true;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) return;

    setState(() => _isLoading = true);

    final fullName = _nameController.text.trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : firstName;

    final result = await ref
        .read(authNotifierProvider.notifier)
        .register(
          firstName: firstName,
          lastName: lastName,
          name: fullName,
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      final isServerIssue = (result.errorMessage ?? '').contains('الخادم') ||
          (result.errorMessage ?? '').contains('السيرفر') ||
          (result.errorMessage ?? '').contains('اتصال');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'حدث خطأ أثناء التسجيل'),
          backgroundColor: isServerIssue ? const Color(0xFF334155) : AppColors.error,
          duration: const Duration(seconds: 4),
          action: isServerIssue
              ? SnackBarAction(
                  label: 'المتابعة محلياً',
                  textColor: const Color(0xFF38BDF8),
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).enterOfflineMode(
                      storeName: fullName.isNotEmpty ? fullName : null,
                    );
                  },
                )
              : null,
        ),
      );
    }
    // If success, GoRouter will automatically redirect based on auth status change!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D4ED8), // Fallback for gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header Area
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Step Indicators
                        Row(
                          children: [
                            _buildStepDot(true),
                            const SizedBox(width: 6),
                            _buildStepDot(false),
                            const SizedBox(width: 6),
                            _buildStepDot(false),
                          ],
                        ),
                        const SizedBox(width: 40), // Balance the row
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل بياناتك الأساسية للبدء في استخدام النظام',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Form Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'الاسم الكامل أو اسم المتجر *',
                          controller: _nameController,
                          hint: 'مثال: متجر الأناقة أو محمد علي',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'رقم الهاتف *',
                          controller: _phoneController,
                          hint: '771234567 أو +967...',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'كلمة المرور *',
                          controller: _passwordController,
                          hint: '••••••••',
                          obscureText: !_showPassword,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'كلمة المرور مطلوبة';
                            if (v.length < 6) return 'يجب أن لا تقل عن 6 أحرف';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Terms Checkbox
                        InkWell(
                          onTap: () =>
                              setState(() => _acceptTerms = !_acceptTerms),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _acceptTerms
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _acceptTerms
                                        ? AppColors.primary
                                        : AppColors.borderLight,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: _acceptTerms
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'أوافق على الشروط والأحكام وسياسة الخصوصية',
                                style: TextStyle(
                                  color: AppColors.textSecondaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _acceptTerms && !_isLoading
                              ? _submit
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.borderLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'إنشاء الحساب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  final fullName = _nameController.text.trim();
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .enterOfflineMode(
                                        storeName: fullName.isNotEmpty ? fullName : null,
                                      );
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            side: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.offline_pin_rounded,
                            color: Color(0xFF10B981),
                          ),
                          label: const Text(
                            'المتابعة في وضع عدم الاتصال (بدون خادم)',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/login'),
                            child: const Text(
                              'لديك حساب بالفعل؟ تسجيل الدخول',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(bool isActive) {
    return Container(
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
