import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';
import '../widgets/user_card_widget.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock Users Data
  late List<UserCardModel> _allUsers;

  @override
  void initState() {
    super.initState();
    _allUsers = const [
      UserCardModel(
        id: '1',
        name: 'أحمد محمد العمري',
        role: 'مدير النظام (Admin)',
        branch: 'الفرع الرئيسي',
        initialLetter: 'أ',
        isActive: true,
        avatarColor: Color(0xFF6366F1),
      ),
      UserCardModel(
        id: '2',
        name: 'كاشير الصباح',
        role: 'كاشير مبيعات (Cashier)',
        branch: 'فرع المعلا',
        initialLetter: 'ك',
        isActive: true,
        avatarColor: Color(0xFF3B82F6),
      ),
      UserCardModel(
        id: '3',
        name: 'سارة علي',
        role: 'محاسب (Accountant)',
        branch: 'فرع المعلا',
        initialLetter: 'س',
        isActive: false,
        avatarColor: Color(0xFFEC4899),
      ),
      UserCardModel(
        id: '4',
        name: 'محمد خالد',
        role: 'مدير مخزون (Inventory Manager)',
        branch: 'المستودع الرئيسي',
        initialLetter: 'م',
        isActive: true,
        avatarColor: Color(0xFF10B981),
      ),
    ];

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserCardModel> get _filteredUsers {
    if (_searchQuery.trim().isEmpty) return _allUsers;
    final q = _searchQuery.trim().toLowerCase();
    return _allUsers.where((u) {
      return u.name.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q) ||
          u.branch.toLowerCase().contains(q);
    }).toList();
  }

  // 1. Modal: Add New User Modal (إضافة مستخدم جديد)
  void _showAddUserModal() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'مدير النظام (Admin)';
    String selectedBranch = 'الفرع الرئيسي';
    bool isActive = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight;
            final border = isDark
                ? AppColors.borderDark
                : AppColors.borderLight;

            return Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Icon & Title & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Text(
                              'إضافة مستخدم جديد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Full Name Field
                    SettingsFormFieldWidget(
                      label: 'الاسم الكامل',
                      hint: 'مثال: أحمد محمد',
                      isRequired: true,
                      controller: nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Username Field
                    SettingsFormFieldWidget(
                      label: 'اسم المستخدم (للدخول)',
                      hint: 'ahmed_m',
                      isRequired: true,
                      controller: usernameCtrl,
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone Number Field
                    SettingsFormFieldWidget(
                      label: 'رقم الهاتف',
                      hint: '05XXXXXXXX',
                      controller: phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password Field
                    SettingsFormFieldWidget(
                      label: 'كلمة المرور',
                      hint: '*****',
                      isRequired: true,
                      controller: passwordCtrl,
                      prefixIcon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.visiblePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dropdowns Row: Role & Branch
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'دور المستخدم (الصلاحيات) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(color: border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'مدير النظام (Admin)',
                                        child: Text('مدير النظام (Admin)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'كاشير مبيعات (Cashier)',
                                        child: Text('كاشير مبيعات (Cashier)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'أمين مخزن (Inventory Manager)',
                                        child: Text(
                                          'أمين مخزن (Inventory Manager)',
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null)
                                        setModalState(() => selectedRole = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفرع المتاح *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(color: border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBranch,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'الفرع الرئيسي',
                                        child: Text('الفرع الرئيسي'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'فرع المعلا',
                                        child: Text('فرع المعلا'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null)
                                        setModalState(
                                          () => selectedBranch = val,
                                        );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Active Status Checkbox Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => isActive = val);
                            },
                          ),
                          Text(
                            'حساب نشط',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Action Buttons Row: Cancel & Save
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'حفظ البيانات',
                            icon: Icons.check_rounded,
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'تم إضافة المستخدم بنجاح',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 2. Modal: Edit User Modal (تعديل المستخدم)
  void _showEditUserModal(UserCardModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final usernameCtrl = TextEditingController(text: 'admin_user');
    final phoneCtrl = TextEditingController(text: '771234567');
    final passwordCtrl = TextEditingController();
    String selectedRole = user.role.contains('Admin')
        ? 'مدير النظام (Admin)'
        : 'كاشير مبيعات (Cashier)';
    String selectedBranch = user.branch;
    bool isActive = user.isActive;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark
                ? AppColors.surfaceDark
                : AppColors.surfaceLight;
            final border = isDark
                ? AppColors.borderDark
                : AppColors.borderLight;

            return Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Icon & Title & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: const Icon(
                                Icons.manage_accounts_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Text(
                              'تعديل المستخدم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Full Name Field
                    SettingsFormFieldWidget(
                      label: 'الاسم الكامل',
                      isRequired: true,
                      controller: nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Username Field
                    SettingsFormFieldWidget(
                      label: 'اسم المستخدم (للدخول)',
                      isRequired: true,
                      controller: usernameCtrl,
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone Number Field
                    SettingsFormFieldWidget(
                      label: 'رقم الهاتف',
                      controller: phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password Field (Optional on edit)
                    SettingsFormFieldWidget(
                      label: 'كلمة المرور',
                      hint: 'اترك فارغاً لعدم التغيير',
                      controller: passwordCtrl,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dropdowns Row: Role & Branch
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'دور المستخدم (الصلاحيات) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(color: border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'مدير النظام (Admin)',
                                        child: Text('مدير النظام (Admin)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'كاشير مبيعات (Cashier)',
                                        child: Text('كاشير مبيعات (Cashier)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'أمين مخزن (Inventory Manager)',
                                        child: Text(
                                          'أمين مخزن (Inventory Manager)',
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null)
                                        setModalState(() => selectedRole = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفرع المتاح *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(color: border, width: 1.5),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedBranch,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'الفرع الرئيسي',
                                        child: Text('الفرع الرئيسي'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'فرع المعلا',
                                        child: Text('فرع المعلا'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null)
                                        setModalState(
                                          () => selectedBranch = val,
                                        );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Active Checkbox Tile
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              if (val != null)
                                setModalState(() => isActive = val);
                            },
                          ),
                          Text(
                            'حساب نشط',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Action Buttons Row: Save & Cancel
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'حفظ البيانات',
                            icon: Icons.check_rounded,
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم تحديث بيانات المستخدم (${user.name}) بنجاح',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusLg,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. Modal: Confirm Delete User Modal (تأكيد الحذف)
  void _showDeleteConfirmModal(UserCardModel user) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: BorderSide(color: border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Warning Icon Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Dialog Title
                Text(
                  'تأكيد الحذف',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Dialog Warning Message Body
                Text(
                  'هل أنت متأكد من أنك تريد حذف "${user.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons Row: Red Delete Button & Cancel Button
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _allUsers.removeWhere((u) => u.id == user.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم حذف المستخدم (${user.name})'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'حذف نهائي',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLg,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar
          SettingsHeaderWidget(
            title: 'إدارة المستخدمين',
            description: 'إدارة حسابات الموظفين وصلاحيات الوصول والربط بالفروع',
            onBackTap: () => Navigator.of(context).pop(),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Action Bar: Header Info + "+ إضافة مستخدم" Button
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 600;

                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.sm + 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.people_alt_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'إدارة المستخدمين',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          '${_allUsers.length} مستخدم',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                PrimaryButton(
                                  text: 'إضافة مستخدم',
                                  icon: Icons.add_rounded,
                                  onPressed: _showAddUserModal,
                                ),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.people_alt_rounded,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'إدارة المستخدمين',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        '${_allUsers.length} مستخدم',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 180,
                                child: PrimaryButton(
                                  text: 'إضافة مستخدم',
                                  icon: Icons.add_rounded,
                                  onPressed: _showAddUserModal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Search Input Field
                      SettingsFormFieldWidget(
                        label: '',
                        hint: 'ابحث بالإسم، الإيميل، أو اسم المستخدم...',
                        controller: _searchController,
                        prefixIcon: Icons.search_rounded,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // User Cards Grid or Empty Search View
                      if (filtered.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'لا توجد نتائج مطابقة للبحث',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth <= 700) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: AppSpacing.lg),
                                itemBuilder: (context, index) {
                                  final userItem = filtered[index];
                                  return UserCardWidget(
                                    user: userItem,
                                    onEdit: () => _showEditUserModal(userItem),
                                    onDelete: () =>
                                        _showDeleteConfirmModal(userItem),
                                  );
                                },
                              );
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: AppSpacing.lg,
                                    mainAxisSpacing: AppSpacing.lg,
                                    mainAxisExtent: 240,
                                  ),
                              itemBuilder: (context, index) {
                                final userItem = filtered[index];
                                return UserCardWidget(
                                  user: userItem,
                                  onEdit: () => _showEditUserModal(userItem),
                                  onDelete: () =>
                                      _showDeleteConfirmModal(userItem),
                                );
                              },
                            );
                          },
                        ),
                      ],
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
}
