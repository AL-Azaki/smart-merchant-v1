import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../widgets/role_card_widget.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/settings_header_widget.dart';

class PermissionItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String group;

  const PermissionItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.group,
  });
}

class RolesPermissionsView extends StatefulWidget {
  const RolesPermissionsView({super.key});

  @override
  State<RolesPermissionsView> createState() => _RolesPermissionsViewState();
}

class _RolesPermissionsViewState extends State<RolesPermissionsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // All 5 Permission Groups matching the reference screenshots exactly
  final List<PermissionItemModel> _allPermissions = const [
    // 1. المبيعات
    PermissionItemModel(
      id: 'sales_view',
      title: 'عرض المبيعات',
      subtitle: 'عرض فواتير المبيعات والطلبات',
      group: 'المبيعات',
    ),
    PermissionItemModel(
      id: 'sales_create',
      title: 'إنشاء فواتير المبيعات',
      subtitle: 'إمكانية بيع وإنشاء فواتير جديدة',
      group: 'المبيعات',
    ),

    // 2. المشتريات والموردين
    PermissionItemModel(
      id: 'purchases_view',
      title: 'عرض المشتريات',
      subtitle: 'عرض فواتير المشتريات والموردين',
      group: 'المشتريات والموردين',
    ),
    PermissionItemModel(
      id: 'purchases_manage',
      title: 'إدارة المشتريات',
      subtitle: 'إنشاء فواتير شراء بضاعة مرتجعاتها',
      group: 'المشتريات والموردين',
    ),

    // 3. المخزون والمنتجات
    PermissionItemModel(
      id: 'inventory_view',
      title: 'عرض المخزون',
      subtitle: 'تصفح قائمة المنتجات والمستودعات',
      group: 'المخزون والمنتجات',
    ),
    PermissionItemModel(
      id: 'inventory_manage',
      title: 'تعديل المخزون والمنتجات',
      subtitle: 'إضافة وتعديل المنتجات والأصول وجرد المخزون',
      group: 'المخزون والمنتجات',
    ),

    // 4. المالية والحسابات
    PermissionItemModel(
      id: 'finance_view',
      title: 'عرض المالية',
      subtitle: 'عرض الخزينة والحسابات المالية',
      group: 'المالية والحسابات',
    ),
    PermissionItemModel(
      id: 'finance_manage',
      title: 'إدارة المالية والمصاريف',
      subtitle: 'سندات الصرف والقبض وإدخال المصاريف',
      group: 'المالية والحسابات',
    ),

    // 5. المستخدمين والصلاحيات
    PermissionItemModel(
      id: 'users_manage',
      title: 'إدارة المستخدمين والصلاحيات',
      subtitle: 'إضافة مستخدمين وتعديل أدوارهم وصلاحياتهم',
      group: 'المستخدمين والصلاحيات',
    ),
  ];

  // Mock Roles Data
  late List<RoleCardModel> _allRoles;

  @override
  void initState() {
    super.initState();
    _allRoles = const [
      RoleCardModel(
        id: '1',
        title: 'مدير النظام (Admin)',
        description: 'كامل صلاحيات الوصول والإدارة لكل موديونات النظام والفروع',
        permissionsCount: 9,
        isSystemRole: true,
        isActive: true,
      ),
      RoleCardModel(
        id: '2',
        title: 'كاشير مبيعات (Cashier)',
        description: 'صلاحيات تصفح المبيعات وإنشاء الفواتير فقط',
        permissionsCount: 2,
        isSystemRole: false,
        isActive: true,
      ),
      RoleCardModel(
        id: '3',
        title: 'أمين مخزن (Inventory Manager)',
        description:
            'صلاحية إدارة المنتجات، الأصول الثابتة، المستودعات وجرد المخزون',
        permissionsCount: 3,
        isSystemRole: false,
        isActive: true,
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

  List<RoleCardModel> get _filteredRoles {
    if (_searchQuery.trim().isEmpty) return _allRoles;
    final q = _searchQuery.trim().toLowerCase();
    return _allRoles.where((r) {
      return r.title.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
  }

  // Show Add/Edit Role Modal with exact Permission Groups and Checkboxes
  void _showRoleModal({RoleCardModel? existingRole}) {
    final titleCtrl = TextEditingController(text: existingRole?.title ?? '');
    final descCtrl = TextEditingController(
      text: existingRole?.description ?? '',
    );
    bool isActive = existingRole?.isActive ?? true;

    // Selected permission IDs
    final Set<String> selectedPermissions = existingRole != null
        ? {'purchases_view', 'inventory_view', 'inventory_manage'}
        : {};

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
            const amberColor = Color(0xFFF59E0B);

            // Group permissions by category
            final Map<String, List<PermissionItemModel>> grouped = {};
            for (final p in _allPermissions) {
              grouped.putIfAbsent(p.group, () => []).add(p);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
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
              child: Column(
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: amberColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: amberColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          Text(
                            existingRole != null
                                ? 'تعديل الدور'
                                : 'إضافة دور جديد',
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

                  const SizedBox(height: AppSpacing.md),
                  Divider(color: border, height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Scrollable Content (Role Name, Description, Permissions Checklist)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role Title & Description Fields
                          Row(
                            children: [
                              Expanded(
                                child: SettingsFormFieldWidget(
                                  label: 'اسم الدور',
                                  hint: 'مثال: محاسب',
                                  isRequired: true,
                                  controller: titleCtrl,
                                  prefixIcon: Icons.shield_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: SettingsFormFieldWidget(
                                  label: 'الوصف',
                                  hint: 'وصف الصلاحيات...',
                                  controller: descCtrl,
                                  prefixIcon: Icons.notes_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Checklist Section Title
                          Text(
                            'صلاحيات الوصول (Permissions Checklist)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Permission Groups Checklist Cards
                          for (final entry in grouped.entries) ...[
                            Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                border: Border.all(color: border, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Title
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  // Items Row / List
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: entry.value.map((perm) {
                                      final isChecked = selectedPermissions
                                          .contains(perm.id);

                                      return Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isChecked
                                                ? (isDark
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFFEEF2FF))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              setModalState(() {
                                                if (isChecked) {
                                                  selectedPermissions.remove(
                                                    perm.id,
                                                  );
                                                } else {
                                                  selectedPermissions.add(
                                                    perm.id,
                                                  );
                                                }
                                              });
                                            },
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Checkbox(
                                                  value: isChecked,
                                                  activeColor: const Color(
                                                    0xFF6366F1,
                                                  ),
                                                  onChanged: (val) {
                                                    setModalState(() {
                                                      if (val == true) {
                                                        selectedPermissions.add(
                                                          perm.id,
                                                        );
                                                      } else {
                                                        selectedPermissions
                                                            .remove(perm.id);
                                                      }
                                                    });
                                                  },
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        perm.title,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textPrimaryDark
                                                              : AppColors
                                                                    .textPrimaryLight,
                                                        ),
                                                      ),
                                                      Text(
                                                        perm.subtitle,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark
                                                              ? AppColors
                                                                    .textSecondaryDark
                                                              : AppColors
                                                                    .textSecondaryLight,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Active Role Checkbox Tile
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
                                  activeColor: amberColor,
                                  onChanged: (val) {
                                    if (val != null)
                                      setModalState(() => isActive = val);
                                  },
                                ),
                                Text(
                                  'دور نشط',
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

                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Bottom Action Buttons: Save & Cancel
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: amberColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existingRole != null
                                        ? 'تم تحديث الدور بنجاح'
                                        : 'تم إضافة الدور بنجاح',
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
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'حفظ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            );
          },
        );
      },
    );
  }

  // Delete Confirm Modal for Roles
  void _showDeleteRoleModal(RoleCardModel role) {
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
                Text(
                  'هل أنت متأكد من أنك تريد حذف الدور "${role.title}"؟ لا يمكن التراجع عن هذا الإجراء.',
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
                            if (role.isSystemRole) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'لا يمكن حذف أدوار النظام الأساسية',
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                _allRoles.removeWhere((r) => r.id == role.id);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم حذف الدور (${role.title})'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                ),
                              );
                            }
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
    final filtered = _filteredRoles;
    const amberColor = Color(0xFFF59E0B);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar
          SettingsHeaderWidget(
            title: 'الأدوار والصلاحيات',
            description:
                'تحديد مستويات الوصول وتوزيع الصلاحيات الخاصة بكافة الموظفين',
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
                      // Top Action Bar: Header Info + "+ إضافة دور" Amber Button
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
                                        color: amberColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.shield_outlined,
                                        color: amberColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'الأدوار والصلاحيات',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          '${_allRoles.length} دور',
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
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: amberColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusLg,
                                        ),
                                      ),
                                    ),
                                    onPressed: () => _showRoleModal(),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'إضافة دور',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
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
                                      color: amberColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: amberColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الأدوار والصلاحيات',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      Text(
                                        '${_allRoles.length} دور',
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
                                width: 160,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: amberColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusLg,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _showRoleModal(),
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: const Text(
                                    'إضافة دور',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
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
                        hint: 'ابحث باسم الدور...',
                        controller: _searchController,
                        prefixIcon: Icons.search_rounded,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Roles List / Grid
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
                                'لا توجد أدوار مطابقة للبحث',
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
                                  final roleItem = filtered[index];
                                  return RoleCardWidget(
                                    role: roleItem,
                                    onEdit: () =>
                                        _showRoleModal(existingRole: roleItem),
                                    onDelete: () =>
                                        _showDeleteRoleModal(roleItem),
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
                                    mainAxisExtent: 250,
                                  ),
                              itemBuilder: (context, index) {
                                final roleItem = filtered[index];
                                return RoleCardWidget(
                                  role: roleItem,
                                  onEdit: () =>
                                      _showRoleModal(existingRole: roleItem),
                                  onDelete: () =>
                                      _showDeleteRoleModal(roleItem),
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
