import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  bool _acceptTerms = false;
  bool _showPassword = false;

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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
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
                    const Text('إنشاء حساب جديد', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('أدخل بياناتك الأساسية للبدء في استخدام النظام', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('الاسم الأول', 'أحمد')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('اسم العائلة', 'محمد')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('اسم المستخدم', '@username', textDirection: TextDirection.ltr),
                      const SizedBox(height: 16),
                      _buildTextField('البريد الإلكتروني', 'email@example.com', textDirection: TextDirection.ltr, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField('رقم الهاتف', '+967 77...', textDirection: TextDirection.ltr, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      
                      // Password
                      Text('كلمة المرور', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textSecondaryLight),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Terms Checkbox
                      InkWell(
                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                        child: Row(
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _acceptTerms ? AppColors.primary : Colors.transparent,
                                border: Border.all(color: _acceptTerms ? AppColors.primary : AppColors.borderLight, width: 2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _acceptTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            const Text('أوافق على الشروط والأحكام وسياسة الخصوصية', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      ElevatedButton(
                        onPressed: _acceptTerms ? () {
                          // Trigger Setup Required State
                          ref.read(authNotifierProvider.notifier).register();
                          // Router will automatically redirect to /setup-business
                        } : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.borderLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('إنشاء الحساب', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('لديك حساب بالفعل؟ تسجيل الدخول', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
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

  Widget _buildTextField(String label, String hint, {TextDirection? textDirection, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          textDirection: textDirection,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
          ),
        ),
      ],
    );
  }
}
