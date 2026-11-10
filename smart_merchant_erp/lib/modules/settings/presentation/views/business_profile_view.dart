import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../../../authentication/infrastructure/api/auth_remote_api_client.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../widgets/logo_upload_card_widget.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';

/// Provider to watch current business profile reactively across Settings & Headers.
final currentBusinessEntityProvider =
    StreamProvider.autoDispose<BusinessEntity?>((ref) {
      final session = ref.watch(sessionNotifierProvider);
      final db = getIt<AppDatabase>();
      final businessId = session.businessId;
      if (businessId != null && businessId.isNotEmpty) {
        return (db.select(
          db.businesses,
        )..where((t) => t.id.equals(businessId))).watchSingleOrNull();
      }
      return (db.select(db.businesses)..limit(1)).watchSingleOrNull();
    });

class BusinessProfileView extends ConsumerStatefulWidget {
  const BusinessProfileView({super.key});

  @override
  ConsumerState<BusinessProfileView> createState() =>
      _BusinessProfileViewState();
}

class _BusinessProfileViewState extends ConsumerState<BusinessProfileView> {
  final _businessNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedBusinessType = 'retail';
  String _selectedCity = 'صنعاء';
  String? _logoPath;
  String _baseCurrencyLabel = 'ريال يمني (YER - ﷼)';
  String _businessStatus = 'Active';
  DateTime? _createdAt;

  String? _loadedBusinessId;
  String? _loadedBranchId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _nameError;

  static const List<Map<String, dynamic>> _businessTypes = [
    {
      'id': 'grocery',
      'label': 'بقالة وتموينات',
      'icon': Icons.shopping_basket_rounded,
    },
    {
      'id': 'retail',
      'label': 'تجزئة ومبيعات عامة',
      'icon': Icons.storefront_rounded,
    },
    {
      'id': 'wholesale',
      'label': 'جملة ومستودعات',
      'icon': Icons.inventory_2_rounded,
    },
    {
      'id': 'electronics',
      'label': 'هواتف وإلكترونيات',
      'icon': Icons.devices_rounded,
    },
    {
      'id': 'fashion',
      'label': 'أزياء وملابس',
      'icon': Icons.checkroom_rounded,
    },
    {
      'id': 'pharmacy',
      'label': 'صيدلية وعناية',
      'icon': Icons.medication_rounded,
    },
    {
      'id': 'restaurant',
      'label': 'مطاعم وكافيهات',
      'icon': Icons.restaurant_rounded,
    },
    {
      'id': 'other',
      'label': 'نشاط تجاري آخر',
      'icon': Icons.business_center_rounded,
    },
  ];

  static const List<String> _yemenCities = [
    'صنعاء',
    'عدن',
    'تعز',
    'إب',
    'حضرموت',
    'الحديدة',
    'مأرب',
    'ذمار',
    'عمران',
    'البيضاء',
    'حجة',
    'لحج',
    'شبوة',
    'المهرة',
    'أبين',
    'صعدة',
    'المحويت',
    'ريمة',
    'الضالع',
    'الجوف',
    'سقطرى',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController.addListener(_onFieldChanged);
    _branchNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _loadBusinessData();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {
        if (_nameError != null &&
            _businessNameController.text.trim().isNotEmpty) {
          _nameError = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _businessNameController.removeListener(_onFieldChanged);
    _branchNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _businessNameController.dispose();
    _branchNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _normalizeBusinessType(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'retail';
    final lower = raw.trim().toLowerCase();
    for (final item in _businessTypes) {
      if (item['id'] == lower || item['label'] == raw.trim()) {
        return item['id'] as String;
      }
    }
    return 'retail';
  }

  String _businessTypeLabel(String typeId) {
    for (final item in _businessTypes) {
      if (item['id'] == typeId) {
        return item['label'] as String;
      }
    }
    return 'تجزئة ومبيعات عامة';
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(sessionNotifierProvider);
      final db = getIt<AppDatabase>();
      final prefs = getIt<SharedPreferences>();

      BusinessEntity? business;
      if (session.businessId != null && session.businessId!.isNotEmpty) {
        business = await (db.select(
          db.businesses,
        )..where((t) => t.id.equals(session.businessId!))).getSingleOrNull();
      }
      business ??= await (db.select(db.businesses)..limit(1)).getSingleOrNull();

      BranchEntity? branch;
      if (business != null) {
        if (session.branchId != null && session.branchId!.isNotEmpty) {
          branch = await (db.select(db.branches)
                ..where(
                  (t) =>
                      t.id.equals(session.branchId!) &
                      t.businessId.equals(business!.id),
                ))
              .getSingleOrNull();
        }
        branch ??= await (db.select(db.branches)
              ..where((t) => t.businessId.equals(business!.id))
              ..limit(1))
            .getSingleOrNull();
      }

      final baseCurrency = await (db.select(
        db.currencies,
      )..where((t) => t.isBaseCurrency.equals(true))).getSingleOrNull();

      if (business != null) {
        _loadedBusinessId = business.id;
        _loadedBranchId = branch?.id;
        _businessNameController.text = business.businessName;
        _selectedBusinessType = _normalizeBusinessType(business.businessType);
        _phoneController.text =
            business.primaryPhone ?? branch?.phone ?? '';
        _emailController.text =
            business.primaryEmail ?? branch?.email ?? '';
        _logoPath = business.logoPath ??
            prefs.getString('business_logo_${business.id}');
        _businessStatus = business.status;
        _createdAt = business.createdAt;

        _branchNameController.text =
            (branch?.branchName != null && branch!.branchName.trim().isNotEmpty)
                ? branch.branchName
                : 'المركز الرئيسي';

        // Parse city and detailed address
        final savedCity = prefs.getString('business_city_${business.id}');
        final rawAddress = branch?.address ??
            prefs.getString('business_address_${business.id}') ??
            '';

        if (savedCity != null && _yemenCities.contains(savedCity)) {
          _selectedCity = savedCity;
          if (rawAddress.startsWith('$savedCity - ')) {
            _addressController.text =
                rawAddress.substring('$savedCity - '.length).trim();
          } else {
            _addressController.text = rawAddress;
          }
        } else if (rawAddress.contains(' - ')) {
          final parts = rawAddress.split(' - ');
          final candidateCity = parts.first.trim();
          if (_yemenCities.contains(candidateCity)) {
            _selectedCity = candidateCity;
            _addressController.text = parts.sublist(1).join(' - ').trim();
          } else {
            _addressController.text = rawAddress;
          }
        } else {
          _addressController.text = rawAddress;
        }
      }

      if (baseCurrency != null) {
        _baseCurrencyLabel =
            '${baseCurrency.currencyNameAr} (${baseCurrency.currencyCode} - ${baseCurrency.currencySymbol})';
      }
    } catch (e) {
      debugPrint('Error loading business profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );
      if (picked != null && mounted) {
        setState(() {
          _logoPath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر اختيار الصورة: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeLogo() {
    setState(() {
      _logoPath = null;
    });
  }

  Future<void> _handleSave() async {
    final name = _businessNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'يرجى إدخال اسم المنشأة التجاري';
      });
      return;
    }

    final branchName = _branchNameController.text.trim().isNotEmpty
        ? _branchNameController.text.trim()
        : 'المركز الرئيسي';
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final detailAddress = _addressController.text.trim();
    final fullAddress = detailAddress.isNotEmpty
        ? '$_selectedCity - $detailAddress'
        : _selectedCity;

    setState(() => _isSaving = true);

    try {
      final db = getIt<AppDatabase>();
      final prefs = getIt<SharedPreferences>();
      final businessId = _loadedBusinessId;

      if (businessId != null && businessId.isNotEmpty) {
        final existingBiz = await (db.select(
          db.businesses,
        )..where((t) => t.id.equals(businessId))).getSingleOrNull();

        if (existingBiz != null) {
          await (db.update(
            db.businesses,
          )..where((t) => t.id.equals(businessId))).write(
            BusinessesCompanion(
              businessName: drift.Value(name),
              businessType: drift.Value(_selectedBusinessType),
              primaryPhone: drift.Value(phone.isNotEmpty ? phone : null),
              primaryEmail: drift.Value(email.isNotEmpty ? email : null),
              logoPath: drift.Value(_logoPath),
              syncStatus: const drift.Value('pending'),
              version: drift.Value(existingBiz.version + 1),
              updatedAt: drift.Value(DateTime.now()),
            ),
          );

          // Keep account record in sync
          await (db.update(
            db.accountsTable,
          )..where((t) => t.id.equals(existingBiz.accountId))).write(
            AccountsTableCompanion(
              businessName: drift.Value(name),
              businessType: drift.Value(_selectedBusinessType),
            ),
          );
        }

        // Update active/main branch
        if (_loadedBranchId != null && _loadedBranchId!.isNotEmpty) {
          final existingBranch = await (db.select(
            db.branches,
          )..where((t) => t.id.equals(_loadedBranchId!))).getSingleOrNull();

          if (existingBranch != null) {
            await (db.update(
              db.branches,
            )..where((t) => t.id.equals(_loadedBranchId!))).write(
              BranchesCompanion(
                branchName: drift.Value(branchName),
                phone: drift.Value(phone.isNotEmpty ? phone : null),
                email: drift.Value(email.isNotEmpty ? email : null),
                address: drift.Value(fullAddress),
                syncStatus: const drift.Value('pending'),
                version: drift.Value(existingBranch.version + 1),
                updatedAt: drift.Value(DateTime.now()),
              ),
            );
          }
        }

        // Persist city & address preferences
        await prefs.setString('business_city_$businessId', _selectedCity);
        await prefs.setString('business_address_$businessId', detailAddress);
        if (_logoPath != null && _logoPath!.isNotEmpty) {
          await prefs.setString('business_logo_$businessId', _logoPath!);
        } else {
          await prefs.remove('business_logo_$businessId');
        }
      }

      // Sync to remote server if reachable (non-blocking for offline mode)
      try {
        final authApi = getIt<AuthRemoteApiClient>();
        await authApi.setupBusiness({
          'business_name': name,
          'business_type': _selectedBusinessType,
          'branch_name': branchName,
          'primary_phone': phone.isNotEmpty ? phone : null,
          'primary_email': email.isNotEmpty ? email : null,
          'city': _selectedCity,
          'address': detailAddress,
        });
      } catch (_) {
        // Offline or server unavailable: local database already updated and marked pending.
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'تم حفظ بيانات المنشأة بنجاح وتحديث ترويسة الفواتير والنظام',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ البيانات: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          SettingsHeaderWidget(
            title: 'معلومات المنشأة',
            description:
                'إدارة الهوية التجارية وبيانات التواصل والعنوان الظاهر في الفواتير والتقارير',
            onBackTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLiveIdentityBanner(isDark, surface, border),
                            const SizedBox(height: AppSpacing.lg),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 820;

                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                      SizedBox(
                                        width: 340,
                                        child: Column(
                                          children: [
                                            LogoUploadCardWidget(
                                              logoPath: _logoPath,
                                              businessName:
                                                  _businessNameController.text,
                                              onUploadTap: _pickLogo,
                                              onRemoveTap: _removeLogo,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _buildInvoiceHeaderPreviewCard(
                                              isDark,
                                              surface,
                                              border,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.lg,
                                            ),
                                            _buildSystemConstantsCard(
                                              isDark,
                                              surface,
                                              border,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    LogoUploadCardWidget(
                                      logoPath: _logoPath,
                                      businessName:
                                          _businessNameController.text,
                                      onUploadTap: _pickLogo,
                                      onRemoveTap: _removeLogo,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildFormCard(
                                      context,
                                      isDark,
                                      surface,
                                      border,
                                      isWide: false,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildInvoiceHeaderPreviewCard(
                                      isDark,
                                      surface,
                                      border,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildSystemConstantsCard(
                                      isDark,
                                      surface,
                                      border,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIdentityBanner(bool isDark, Color surface, Color border) {
    final displayName = _businessNameController.text.trim().isNotEmpty
        ? _businessNameController.text.trim()
        : 'اسم المنشأة';
    final displayBranch = _branchNameController.text.trim().isNotEmpty
        ? _branchNameController.text.trim()
        : 'المركز الرئيسي';
    final isActive = _businessStatus == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.14)
                              : AppColors.warning.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'منشأة نشطة' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_businessTypeLabel(_selectedBusinessType)} • $displayBranch • $_selectedCity',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _loadBusinessData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('استعادة البيانات المحفوظة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              side: BorderSide(color: border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البيانات الأساسية والتواصل',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الحقول التالية حقيقية وتنعكس مباشرة في فواتير المبيعات والمشتريات والتقارير',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. Business Name & Branch Name
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'اسم المنشأة التجاري',
                    hint: 'مثال: مؤسسة النور للتجارة',
                    isRequired: true,
                    controller: _businessNameController,
                    prefixIcon: Icons.storefront_rounded,
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'اسم الفرع الرئيسي',
                    hint: 'مثال: المركز الرئيسي',
                    controller: _branchNameController,
                    prefixIcon: Icons.account_tree_outlined,
                  ),
                ),
              ],
            )
          else ...[
            SettingsFormFieldWidget(
              label: 'اسم المنشأة التجاري',
              hint: 'مثال: مؤسسة النور للتجارة',
              isRequired: true,
              controller: _businessNameController,
              prefixIcon: Icons.storefront_rounded,
              errorText: _nameError,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'اسم الفرع الرئيسي',
              hint: 'مثال: المركز الرئيسي',
              controller: _branchNameController,
              prefixIcon: Icons.account_tree_outlined,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // 2. Business Type Selector (Interactive Chips)
          Text(
            'نوع النشاط التجاري',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _businessTypes.map((type) {
              final id = type['id'] as String;
              final label = type['label'] as String;
              final icon = type['icon'] as IconData;
              final isSelected = _selectedBusinessType == id;

              return InkWell(
                onTap: () => setState(() => _selectedBusinessType = id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : (isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.8 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 17,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Phone & Optional Email
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'رقم الهاتف الأساسي (للفواتير والتواصل)',
                    hint: '77xxxxxxx',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_in_talk_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: SettingsFormFieldWidget(
                    label: 'البريد الإلكتروني (اختياري)',
                    hint: 'info@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                ),
              ],
            )
          else ...[
            SettingsFormFieldWidget(
              label: 'رقم الهاتف الأساسي (للفواتير والتواصل)',
              hint: '77xxxxxxx',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_in_talk_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsFormFieldWidget(
              label: 'البريد الإلكتروني (اختياري)',
              hint: 'info@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // 4. City Dropdown + Detailed Address
          _buildCitySelector(isDark),
          const SizedBox(height: AppSpacing.md),
          SettingsFormFieldWidget(
            label: 'العنوان التفصيلي للمنشأة',
            hint: 'مثال: شارع الزبيري - جوار جولة عصر',
            controller: _addressController,
            maxLines: 2,
            prefixIcon: Icons.location_on_outlined,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Save Button
          Row(
            children: [
              SizedBox(
                width: isWide ? 240 : double.infinity,
                child: PrimaryButton(
                  text: 'حفظ بيانات المنشأة',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector(bool isDark) {
    final surface = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المدينة / المحافظة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedCity),
          initialValue: _yemenCities.contains(_selectedCity) ? _selectedCity : 'صنعاء',
          items: _yemenCities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(
                    city,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCity = val);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: surface,
            prefixIcon: Icon(
              Icons.location_city_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHeaderPreviewCard(
    bool isDark,
    Color surface,
    Color border,
  ) {
    final name = _businessNameController.text.trim().isNotEmpty
        ? _businessNameController.text.trim()
        : 'اسم المنشأة التجاري';
    final branch = _branchNameController.text.trim().isNotEmpty
        ? _branchNameController.text.trim()
        : 'المركز الرئيسي';
    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : 'لم يتم تحديد رقم الهاتف';
    final detailAddress = _addressController.text.trim();
    final addressText = detailAddress.isNotEmpty
        ? '$_selectedCity - $detailAddress'
        : _selectedCity;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'معاينة ترويسة الفاتورة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  branch,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        phone,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        addressText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemConstantsCard(bool isDark, Color surface, Color border) {
    final createdDateText = _createdAt != null
        ? '${_createdAt!.year}/${_createdAt!.month.toString().padLeft(2, '0')}/${_createdAt!.day.toString().padLeft(2, '0')}'
        : 'مسجل في النظام';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'ثوابت النظام المحاسبية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReadOnlyRow(
            label: 'العملة الأساسية للدفاتر',
            value: _baseCurrencyLabel,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildReadOnlyRow(
            label: 'تاريخ تسجيل المنشأة',
            value: createdDateText,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'ملاحظة: العملة الأساسية مرتبطة بالقيود المحاسبية ولا يمكن تغييرها بعد التأسيس، ويمكنك إدارة العملات الإضافية وأسعار الصرف من قسم العملات.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
