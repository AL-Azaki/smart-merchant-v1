import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../widgets/logo_upload_card_widget.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';

class BusinessProfileView extends StatefulWidget {
  const BusinessProfileView({super.key});

  @override
  State<BusinessProfileView> createState() => _BusinessProfileViewState();
}

class _BusinessProfileViewState extends State<BusinessProfileView> {
  // Pre-filled Mock Controllers for Demo UI
  final _arabicNameController = TextEditingController(
    text: 'مؤسسة التقنية المتقدمة',
  );
  final _englishNameController = TextEditingController(
    text: 'Advanced Tech Est.',
  );
  final _crNumberController = TextEditingController(text: '1010123456');
  final _vatNumberController = TextEditingController(text: '300123456789003');
  final _phoneController = TextEditingController(text: '+966 50 123 4567');
  final _emailController = TextEditingController(text: 'info@adv-tech.com');
  final _websiteController = TextEditingController(text: 'www.adv-tech.com');
  final _timezoneController = TextEditingController(text: 'Riyadh (GMT+03:00)');
  final _countryCityController = TextEditingController(
    text: 'المملكة العربية السعودية، الرياض',
  );
  final _currencyController = TextEditingController(text: 'YER - ريال يمني');
  final _addressController = TextEditingController(
    text: 'الرياض، شارع العليا العام، مبنى رقم 12',
  );

  bool _isSaving = false;

  @override
  void dispose() {
    _arabicNameController.dispose();
    _englishNameController.dispose();
    _crNumberController.dispose();
    _vatNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _timezoneController.dispose();
    _countryCityController.dispose();
    _currencyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.md),
            Text(
              'تم حفظ معلومات المنشأة بنجاح',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar with Back Button
          SettingsHeaderWidget(
            title: 'معلومات المنشأة',
            description: 'إعدادات السجل التجاري والبيانات الأساسية',
            onBackTap: () => Navigator.of(context).pop(),
          ),

          // Main Form Content Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;

                      if (isWide) {
                        // 2-Column Wide Layout (Tablet / Desktop)
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left/Right Main Form Card
                            Expanded(
                              flex: 3,
                              child: _buildFormCard(
                                context,
                                isDark,
                                surface,
                                border,
                                isWide: true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            // Logo Upload Card Side Panel
                            SizedBox(
                              width: 320,
                              child: LogoUploadCardWidget(onUploadTap: () {}),
                            ),
                          ],
                        );
                      }

                      // 1-Column Stacked Mobile Layout
                      return Column(
                        children: [
                          // Logo Upload Card (Top on Mobile)
                          LogoUploadCardWidget(onUploadTap: () {}),
                          const SizedBox(height: AppSpacing.lg),
                          // Form Card
                          _buildFormCard(
                            context,
                            isDark,
                            surface,
                            border,
                            isWide: false,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    bool isDark,
    Color surface,
    Color border, {
    required bool isWide,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Inside Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'البيانات الأساسية للمنشأة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Responsive Form Field Grid
          if (isWide) ...[
            Row(
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'اسم المنشأة بالعربية',
                    isRequired: true,
                    controller: _arabicNameController,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'اسم المنشأة بالإنجليزي',
                    controller: _englishNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'رقم السجل التجاري',
                    controller: _crNumberController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'الرقم الضريبي (VAT)',
                    controller: _vatNumberController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'رقم الهاتف',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'البريد الإلكتروني',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'الموقع الإلكتروني',
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'المنطقة الزمنية',
                    controller: _timezoneController,
                    suffixIcon: Icons.access_time_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'الدولة والمدينة',
                    controller: _countryCityController,
                    suffixIcon: Icons.public_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'العملة الافتراضية',
                    controller: _currencyController,
                    suffixIcon: Icons.attach_money_rounded,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile Stacked Fields
            SettingsFormFieldWidget(
              label: 'اسم المنشأة بالعربية',
              isRequired: true,
              controller: _arabicNameController,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'اسم المنشأة بالإنجليزي',
              controller: _englishNameController,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'رقم السجل التجاري',
              controller: _crNumberController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'الرقم الضريبي (VAT)',
              controller: _vatNumberController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'رقم الهاتف',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'البريد الإلكتروني',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'الموقع الإلكتروني',
              controller: _websiteController,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'المنطقة الزمنية',
              controller: _timezoneController,
              suffixIcon: Icons.access_time_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'الدولة والمدينة',
              controller: _countryCityController,
              suffixIcon: Icons.public_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'العملة الافتراضية',
              controller: _currencyController,
              suffixIcon: Icons.attach_money_rounded,
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          // Detailed Address (Full Width on Mobile & Tablet)
          SettingsFormFieldWidget(
            label: 'العنوان بالتفصيل',
            controller: _addressController,
            maxLines: 3,
            suffixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Save Button
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: isWide ? 220 : double.infinity,
              child: PrimaryButton(
                text: 'حفظ التغييرات',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
