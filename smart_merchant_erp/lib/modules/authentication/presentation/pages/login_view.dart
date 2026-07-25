import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      );
      return;
    }

    setState(() => _errorMessage = null);

    final result = await ref
        .read(authNotifierProvider.notifier)
        .loginWithLaravel(email: email, password: password);

    if (!result.isSuccess) {
      if (mounted) {
        setState(
          () => _errorMessage =
              result.errorMessage ?? 'حدث خطأ أثناء تسجيل الدخول',
        );
      }
    }
    // Success is handled by the router redirecting automatically based on auth state
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: const Color(0xFF1D4ED8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                      ],
                    ),
                    const SizedBox(height: 48),
                    // App Logo or Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بعودتك إلى التاجر الذكي',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'البريد الإلكتروني',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'admin@smartmerchant.com',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password
                      const Text(
                        'كلمة المرور',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textSecondaryLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textSecondaryLight,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                      ),

                      const SizedBox(height: 16),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment
                            .centerLeft, // Left because Arabic puts it visually at the end of the line
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          child: const Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'دخول النظام',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.login_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push('/register'),
                          child: const Text(
                            'ليس لديك حساب؟ إنشاء حساب جديد',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
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
          ],
        ),
      ),
    );
  }
}
