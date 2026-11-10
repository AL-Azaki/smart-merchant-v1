import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_card.dart';
import '../../../../shared/design_system/widgets/app_status_badge.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../../../../shared/design_system/widgets/yemen_map_picker_dialog.dart';
import '../../domain/entities/storefront_settings.dart';
import '../providers/storefront_settings_provider.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';

class StorefrontSettingsView extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onOpenLiveSimulator;

  const StorefrontSettingsView({
    super.key,
    this.isEmbedded = false,
    this.onOpenLiveSimulator,
  });

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
  final _customCategoryController = TextEditingController();

  bool _isActive = false;
  bool _hasInitializedValues = false;

  List<String> _selectedCategories = [];
  static const List<String> _suggestedCategories = [
    'سوبرماركت',
    'مواد غذائية',
    'ملابس وأزياء',
    'هواتف وإلكترونيات',
    'عطور وتجميل',
    'مطاعم ومقاهي',
    'صيدلية ومستلزمات',
    'أدوات منزلية',
    'بضائع منوعة',
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _slugController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _customCategoryController.dispose();
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
    _selectedCategories = settings.storefrontCategories != null
        ? List<String>.from(settings.storefrontCategories!)
        : ['سوبرماركت', 'بضائع منوعة'];
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
      storefrontCategories:
          _selectedCategories.isNotEmpty ? _selectedCategories : null,
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
          if (!widget.isEmbedded)
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
                                            _buildCategoriesCard(),
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

                                      // Side Column (Actions)
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
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
                                    _buildCategoriesCard(),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildContactCard(state),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildLocationCard(state),
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

  Future<void> _pickLocationFromMap() async {
    final currentLat = double.tryParse(_latController.text.trim());
    final currentLng = double.tryParse(_lngController.text.trim());

    final result = await YemenMapPickerDialog.show(
      context,
      initialLatitude: currentLat,
      initialLongitude: currentLng,
    );

    if (result != null && mounted) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'تم تثبيت الموقع: ${result.cityName ?? "اليمن"} (${result.formattedCoordinates})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLocationCard(StorefrontSettingsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final hasCoordinates = lat != null && lng != null;

    return AppCard(
      title: 'موقع المتجر الجغرافي على الخريطة',
      icon: Icons.map_rounded,
      subtitle: 'تحديد موقع المعرض أو المتجر على خريطة اليمن لتسهيل وصول العملاء والطلبات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Map Picker Banner / Status
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: hasCoordinates
                    ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981))
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: hasCoordinates ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (hasCoordinates ? const Color(0xFF10B981) : AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasCoordinates
                            ? Icons.location_on_rounded
                            : Icons.add_location_alt_rounded,
                        color: hasCoordinates ? const Color(0xFF10B981) : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasCoordinates
                                ? 'تم تحديد موقع المتجر على الخريطة'
                                : 'لم يتم تحديد موقع المتجر على الخريطة بعد',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasCoordinates
                                ? 'الإحداثيات: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
                                : 'اضغط لاختيار وتثبيت الموقع عبر خريطة تفاعلية لمدن اليمن',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: hasCoordinates ? 'محدد' : 'غير محدد',
                      variant: hasCoordinates
                          ? AppStatusBadgeVariant.success
                          : AppStatusBadgeVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Action Buttons
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: _pickLocationFromMap,
                      icon: Icon(
                        hasCoordinates ? Icons.edit_location_rounded : Icons.map_rounded,
                        size: 16,
                      ),
                      label: Text(
                        hasCoordinates
                            ? 'تعديل الموقع من الخريطة'
                            : 'تحديد الموقع من خريطة اليمن',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasCoordinates
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    if (hasCoordinates) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final url =
                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('معاينة بخرائط Google'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _latController.clear();
                            _lngController.clear();
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                        label: const Text('مسح', style: TextStyle(color: AppColors.error)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Manual coordinate inputs for review/editing
          Row(
            children: [
              Expanded(
                child: SettingsFormFieldWidget(
                  label: 'خط العرض (Latitude)',
                  hint: '15.369400',
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
                  hint: '44.191000',
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
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      title: 'تصنيفات المتجر الإلكتروني',
      icon: Icons.category_outlined,
      subtitle: 'اختر أو أضف الأقسام التي تظهر كشريط تصنيفات رئيسي للعملاء في المتجر',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedCategories.isNotEmpty) ...[
            Text(
              'التصنيفات المختارة للواجهة (${_selectedCategories.length}):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _selectedCategories.map((cat) {
                return Chip(
                  label: Text(
                    cat,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  deleteIconColor: AppColors.primary,
                  onDeleted: () {
                    setState(() {
                      _selectedCategories.remove(cat);
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'تصنيفات مقترحة سريعة:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs,
            children: _suggestedCategories.map((cat) {
              final isSelected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(cat);
                    } else {
                      _selectedCategories.remove(cat);
                    }
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    hintText: 'إضافة تصنيف مخصص آخر...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onSubmitted: (val) {
                    final trimmed = val.trim();
                    if (trimmed.isNotEmpty && !_selectedCategories.contains(trimmed)) {
                      setState(() {
                        _selectedCategories.add(trimmed);
                        _customCategoryController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () {
                  final trimmed = _customCategoryController.text.trim();
                  if (trimmed.isNotEmpty && !_selectedCategories.contains(trimmed)) {
                    setState(() {
                      _selectedCategories.add(trimmed);
                      _customCategoryController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                ),
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
