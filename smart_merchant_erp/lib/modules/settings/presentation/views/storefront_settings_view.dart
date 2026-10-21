import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_status_badge.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../../domain/entities/storefront_settings.dart';
import '../providers/storefront_settings_provider.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';

class StorefrontSettingsView extends ConsumerStatefulWidget {
  const StorefrontSettingsView({super.key});

  @override
  ConsumerState<StorefrontSettingsView> createState() =>
      _StorefrontSettingsViewState();
}

class _StorefrontSettingsViewState
    extends ConsumerState<StorefrontSettingsView> {
  final _displayNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isActive = false;
  bool _hasInitializedValues = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _slugController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _populateFromSettings(StorefrontSettings settings) {
    _isActive = settings.storefrontActive;
    _displayNameController.text = settings.storefrontDisplayName ?? '';
    _slugController.text = settings.storefrontSlug ?? '';
    _whatsappController.text = settings.storefrontWhatsapp ?? '';
    _phoneController.text = settings.storefrontPhone ?? '';
    _addressController.text = settings.storefrontAddressText ?? '';
    _latController.text =
        settings.storefrontLat != null ? settings.storefrontLat.toString() : '';
    _lngController.text =
        settings.storefrontLng != null ? settings.storefrontLng.toString() : '';
    _hasInitializedValues = true;
  }

  StorefrontSettings _buildCurrentSettings() {
    final currentSettings = ref.read(storefrontSettingsProvider).settings;

    return StorefrontSettings(
      storefrontActive: _isActive,
      storefrontDisplayName: _displayNameController.text.trim().isNotEmpty
          ? _displayNameController.text.trim()
          : null,
      effectiveDisplayName: currentSettings?.effectiveDisplayName,
      storefrontSlug: _slugController.text.trim().isNotEmpty
          ? StorefrontSettingsNotifier.normalizeSlug(
              _slugController.text.trim(),
            )
          : null,
      storeUrl: currentSettings?.storeUrl,
      storefrontWhatsapp: _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : null,
      storefrontPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      effectivePhone: currentSettings?.effectivePhone,
      storefrontAddressText: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      storefrontLat: double.tryParse(_latController.text.trim()),
      storefrontLng: double.tryParse(_lngController.text.trim()),
      storefrontThemeSettings: currentSettings?.storefrontThemeSettings,
    );
  }

  Future<void> _copyUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.md),
            Text(
              'تم نسخ رابط المتجر إلى الحافظة بنجاح',
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

  Future<void> _openStore(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الرابط في المتصفح حالياً.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareStore(String? url, String? storeName) async {
    if (url == null || url.isEmpty) {
      return;
    }

    final name = (storeName != null && storeName.isNotEmpty)
        ? storeName
        : 'متجرنا الإلكتروني';
    await SharePlus.instance.share(
      ShareParams(
        text: 'تسوق الآن من $name عبر الرابط:\n$url',
        subject: 'رابط $name',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storefrontSettingsProvider);
    final notifier = ref.read(storefrontSettingsProvider.notifier);

    // Populate controllers when settings first load
    if (state.settings != null && !_hasInitializedValues) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasInitializedValues && state.settings != null) {
          setState(() {
            _populateFromSettings(state.settings!);
          });
        }
      });
    }

    // Listen for save success to show toast
    ref.listen<StorefrontSettingsState>(storefrontSettingsProvider,
        (previous, next) {
      if (next.isSuccess && (previous == null || !previous.isSuccess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Text(
                  next.settings?.storefrontActive == true
                      ? 'تم تفعيل وحفظ إعدادات المتجر الإلكتروني بنجاح!'
                      : 'تم حفظ مسودة إعدادات المتجر بنجاح',
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUrl = state.settings?.storeUrl;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar
          SettingsHeaderWidget(
            title: 'إعدادات المتجر الإلكتروني',
            description:
                'إدارة المتجر العام، رابط الوصول للعملاء، وبيانات التواصل',
            onBackTap: () => Navigator.of(context).pop(),
          ),

          // Main Body
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : state.errorMessage != null && state.settings == null
                    ? _buildErrorView(state.errorMessage!, notifier)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 850;

                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Main Column (Form Fields)
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            _buildActivationCard(),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            _buildIdentityCard(
                                                state, notifier),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            _buildContactCard(state),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            _buildLocationCard(state),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xl),

                                      // Side Column (Preview & Actions)
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            _buildPreviewCard(
                                              currentUrl,
                                              _displayNameController.text,
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.lg),
                                            _buildActionsCard(
                                              state,
                                              notifier,
                                              currentUrl,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // Mobile / Single-Column View
                                return Column(
                                  children: [
                                    _buildActivationCard(),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildIdentityCard(state, notifier),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildContactCard(state),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildLocationCard(state),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildPreviewCard(
                                      currentUrl,
                                      _displayNameController.text,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildActionsCard(
                                      state,
                                      notifier,
                                      currentUrl,
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

  // --- Widgets Breakdown ---

  Widget _buildActivationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      title: 'حالة المتجر الإلكتروني',
      icon: Icons.power_settings_new_rounded,
      iconColor: _isActive ? AppColors.success : AppColors.textSecondaryLight,
      trailing: AppStatusBadge(
        label: _isActive ? 'مفعل' : 'مسودة',
        variant: _isActive
            ? AppStatusBadgeVariant.success
            : AppStatusBadgeVariant.neutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تفعيل المتجر للعملاء',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'عند التفعيل، يمكن للعملاء تصفح منتجاتك وإرسال طلبات الشراء أونلاين.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: AppColors.success,
                activeTrackColor: AppColors.success.withValues(alpha: 0.3),
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'ملاحظة: يمكنك إدارة المنتجات ومزامنتها أثناء تعطيل المتجر دون التأثير على عمليات ERP ونقاط البيع، لكنها لن تظهر للعملاء ولن تُقبل طلبات جديدة حتى تفعيل المتجر.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(
    StorefrontSettingsState state,
    StorefrontSettingsNotifier notifier,
  ) {
    return AppCard(
      title: 'هوية المتجر والرابط العام',
      icon: Icons.storefront_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormFieldWidget(
            label: 'اسم المتجر المعروض للعملاء',
            hint: (state.settings?.effectiveDisplayName != null &&
                    state.settings!.effectiveDisplayName!.isNotEmpty)
                ? 'الاسم الافتراضي: ${state.settings!.effectiveDisplayName}'
                : 'مثال: متجر الأمل التجاري',
            helperText: 'اتركه فارغاً لاستخدام الاسم التجاري للمنشأة كاسم افتراضي',
            controller: _displayNameController,
            errorText: state.validationErrors['storefront_display_name']?.first,
            onChanged: (val) {
              setState(() {});
            },
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsFormFieldWidget(
            label: 'رابط المتجر الخاص (Slug)',
            hint: 'alamal-market',
            controller: _slugController,
            prefixText: 'store/',
            errorText: state.validationErrors['storefront_slug']?.first ??
                (state.slugStatus == SlugCheckStatus.invalid
                    ? state.slugMessage
                    : null),
            helperText: state.slugStatus == SlugCheckStatus.available
                ? (state.slugMessage ?? 'الرابط متاح')
                : (state.slugStatus == SlugCheckStatus.checking
                    ? 'جاري التحقق من التوفر...'
                    : 'يتكون من أحرف إنجليزية وأرقام وشرطات (3 إلى 60 حرفاً)'),
            suffix: _buildSlugStatusIcon(state.slugStatus),
            onChanged: (val) {
              notifier.onSlugChanged(val);
              // Normalize visually if valid latin characters are typed
              final normalized = StorefrontSettingsNotifier.normalizeSlug(val);
              if (!RegExp(r'[\u0600-\u06FF]').hasMatch(val) &&
                  !RegExp(r'[^a-zA-Z0-9\s_-]').hasMatch(val) &&
                  normalized.isNotEmpty &&
                  _slugController.text != normalized &&
                  !val.endsWith(' ') &&
                  !val.endsWith('-')) {
                _slugController.value = TextEditingValue(
                  text: normalized,
                  selection: TextSelection.collapsed(offset: normalized.length),
                );
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget? _buildSlugStatusIcon(SlugCheckStatus status) {
    switch (status) {
      case SlugCheckStatus.checking:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        );
      case SlugCheckStatus.available:
        return const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        );
      case SlugCheckStatus.unavailable:
      case SlugCheckStatus.invalid:
        return const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 20,
        );
      case SlugCheckStatus.initial:
        return null;
    }
  }

  Widget _buildContactCard(StorefrontSettingsState state) {
    return AppCard(
      title: 'بيانات التواصل والعنوان',
      icon: Icons.contact_phone_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormFieldWidget(
            label: 'رقم الواتساب لاستقبال الطلبات',
            hint: 'مثال: 967770000000',
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android_rounded,
            errorText: state.validationErrors['storefront_whatsapp']?.first,
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsFormFieldWidget(
            label: 'هاتف المتجر',
            hint: (state.settings?.effectivePhone != null &&
                    state.settings!.effectivePhone!.isNotEmpty)
                ? 'الرقم الافتراضي: ${state.settings!.effectivePhone}'
                : 'مثال: 9671000000',
            helperText: 'اتركه فارغاً لاستخدام رقم الهاتف الأساسي للمنشأة',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.call_outlined,
            errorText: state.validationErrors['storefront_phone']?.first,
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsFormFieldWidget(
            label: 'عنوان المعرض أو المركز الرئيسي',
            hint: 'صنعاء، شارع الزبيري...',
            controller: _addressController,
            maxLines: 2,
            prefixIcon: Icons.location_on_outlined,
            errorText: state.validationErrors['storefront_address_text']?.first,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(StorefrontSettingsState state) {
    return AppCard(
      title: 'الإحداثيات الجغرافية (اختياري)',
      icon: Icons.map_outlined,
      subtitle: 'تساعد في تحديد موقع متجرك على الخريطة للعملاء',
      child: Row(
        children: [
          Expanded(
            child: SettingsFormFieldWidget(
              label: 'خط العرض (Latitude)',
              hint: '15.354000',
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              errorText: state.validationErrors['storefront_lat']?.first,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SettingsFormFieldWidget(
              label: 'خط الطول (Longitude)',
              hint: '44.205000',
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              errorText: state.validationErrors['storefront_lng']?.first,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(String? currentUrl, String displayName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (ref.watch(storefrontSettingsProvider).settings?.effectiveDisplayName ??
            'اسم المتجر المعروض');

    return AppCard(
      title: 'معاينة رابط المتجر',
      icon: Icons.preview_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppStatusBadge(
                      label: _isActive ? 'مفعل' : 'مسودة',
                      variant: _isActive
                          ? AppStatusBadgeVariant.success
                          : AppStatusBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'رابط الوصول:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  currentUrl ?? 'لم يتم تعيين رابط بعد',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: currentUrl != null
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: currentUrl != null ? () => _copyUrl(currentUrl) : null,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('نسخ الرابط'),
              ),
              OutlinedButton.icon(
                onPressed: currentUrl != null
                    ? () => _openStore(currentUrl)
                    : null,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('فتح المتجر'),
              ),
              IconButton.outlined(
                onPressed: currentUrl != null
                    ? () => _shareStore(currentUrl, name)
                    : null,
                icon: const Icon(Icons.share_rounded, size: 18),
                tooltip: 'مشاركة الرابط',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    StorefrontSettingsState state,
    StorefrontSettingsNotifier notifier,
    String? currentUrl,
  ) {
    return AppCard(
      title: 'إجراءات الحفظ',
      icon: Icons.save_outlined,
      child: Column(
        children: [
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          PrimaryButton(
            text: _isActive ? 'تفعيل وحفظ الإعدادات' : 'تفعيل المتجر الآن',
            icon: Icons.check_circle_outline_rounded,
            isLoading: state.isSaving && _isActive,
            onPressed: () async {
              setState(() => _isActive = true);
              final settings = _buildCurrentSettings();
              await notifier.activateStore(settings);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save_as_outlined, size: 18),
              label: state.isSaving && !_isActive
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ كمسودة (بدون تفعيل)'),
              onPressed: state.isSaving
                  ? null
                  : () async {
                      setState(() => _isActive = false);
                      final settings = _buildCurrentSettings();
                      await notifier.saveDraft(settings);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    String message,
    StorefrontSettingsNotifier notifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'تعذر جلب إعدادات المتجر',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => notifier.loadSettings(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
