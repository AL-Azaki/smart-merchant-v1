import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../kernel/security/permissions_provider.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/widgets/primary_button.dart';
import '../widgets/settings_form_field_widget.dart';
import '../widgets/user_card_widget.dart';

class UsersManagementView extends ConsumerStatefulWidget {
  const UsersManagementView({super.key});

  @override
  ConsumerState<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends ConsumerState<UsersManagementView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── 1. Quick Add User Modal (Name, Username, Password ONLY) ──
  void _showAddQuickUserModal() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isPasswordVisible = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark ? const Color(0xFF181B22) : Colors.white;
            final border = isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E8F0);
            final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
            final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إضافة مستخدم جديد',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'أنشئ حساب الدخول أولاً، وعيّن الصلاحيات لاحقاً بسهولة',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF252A38) : const Color(0xFFF1F5F9),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    SettingsFormFieldWidget(
                      label: 'الاسم الكامل',
                      hint: 'مثال: فيصل الكاشير',
                      isRequired: true,
                      controller: nameCtrl,
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),

                    // Username
                    SettingsFormFieldWidget(
                      label: 'اسم الدخول (Username)',
                      hint: 'faisal_cashier',
                      isRequired: true,
                      controller: usernameCtrl,
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 10),

                    // Phone (Optional)
                    SettingsFormFieldWidget(
                      label: 'رقم الهاتف (اختياري)',
                      hint: '77XXXXXXX',
                      controller: phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كلمة المرور *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'كلمة مرور الدخول للمستخدم',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E222D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Create User Button
                    PrimaryButton(
                      text: 'إنشاء المستخدم الآن',
                      icon: Icons.check_circle_rounded,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final username = usernameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final password = passwordCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);

                        if (name.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة الاسم الكامل للمستخدم')),
                          );
                          return;
                        }

                        if (username.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة اسم الدخول للمستخدم')),
                          );
                          return;
                        }

                        // Create user with default safe cashier preset
                        final newUser = AppUserModel(
                          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          username: username,
                          phone: phone.isNotEmpty ? phone : null,
                          password: password.isNotEmpty ? password : '123',
                          rolePreset: 'cashier',
                          branch: 'المركز الرئيسي',
                          isActive: true,
                          createdAt: DateTime.now(),
                          permissions: {
                            SystemModules.sales: const ModuleActionPermission.viewAndAdd(),
                            SystemModules.purchases: const ModuleActionPermission.none(),
                            SystemModules.inventory: const ModuleActionPermission.viewOnly(),
                            SystemModules.finance: const ModuleActionPermission.none(),
                            SystemModules.hr: const ModuleActionPermission.none(),
                            SystemModules.settings: const ModuleActionPermission.none(),
                          },
                        );

                        await ref.read(usersListProvider.notifier).saveUser(newUser);

                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('تم إنشاء حساب (${newUser.name}) بنجاح'),
                            action: SnackBarAction(
                              label: '🛡️ ضبط الصلاحيات الآن',
                              textColor: Colors.white,
                              onPressed: () => _showPermissionsModal(newUser),
                            ),
                          ),
                        );
                      },
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

  // ── 2. Dedicated Permissions Modal (Presets + 4 Actions Matrix) ──
  void _showPermissionsModal(AppUserModel user) {
    String selectedPreset = user.rolePreset;

    // Clone current permissions
    final Map<String, ModuleActionPermission> perms = {};
    for (final mod in SystemModules.all) {
      if (user.permissions.containsKey(mod.id)) {
        perms[mod.id] = user.permissions[mod.id]!;
      } else {
        perms[mod.id] = const ModuleActionPermission.none();
      }
    }

    void applyPreset(String preset, void Function(void Function()) setModalState) {
      setModalState(() {
        selectedPreset = preset;
        switch (preset) {
          case 'admin':
            for (final m in SystemModules.all) {
              perms[m.id] = const ModuleActionPermission.all();
            }
            break;
          case 'cashier':
            for (final m in SystemModules.all) {
              if (m.id == SystemModules.sales) {
                perms[m.id] = const ModuleActionPermission.viewAndAdd();
              } else if (m.id == SystemModules.inventory) {
                perms[m.id] = const ModuleActionPermission.viewOnly();
              } else {
                perms[m.id] = const ModuleActionPermission.none();
              }
            }
            break;
          case 'purchaser':
            for (final m in SystemModules.all) {
              if (m.id == SystemModules.purchases) {
                perms[m.id] = const ModuleActionPermission.viewAddEdit();
              } else if (m.id == SystemModules.inventory) {
                perms[m.id] = const ModuleActionPermission.viewOnly();
              } else {
                perms[m.id] = const ModuleActionPermission.none();
              }
            }
            break;
          case 'inventory_keeper':
            for (final m in SystemModules.all) {
              if (m.id == SystemModules.inventory) {
                perms[m.id] = const ModuleActionPermission.viewAddEdit();
              } else if (m.id == SystemModules.sales || m.id == SystemModules.purchases) {
                perms[m.id] = const ModuleActionPermission.viewOnly();
              } else {
                perms[m.id] = const ModuleActionPermission.none();
              }
            }
            break;
          case 'accountant':
            for (final m in SystemModules.all) {
              if (m.id == SystemModules.finance) {
                perms[m.id] = const ModuleActionPermission.viewAddEdit();
              } else if (m.id == SystemModules.sales || m.id == SystemModules.purchases || m.id == SystemModules.inventory) {
                perms[m.id] = const ModuleActionPermission.viewOnly();
              } else {
                perms[m.id] = const ModuleActionPermission.none();
              }
            }
            break;
        }
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark ? const Color(0xFF181B22) : Colors.white;
            final border = isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E8F0);
            final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
            final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF6366F1),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'صلاحيات: ${user.name}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'حدد العمليات المصرح بها (عرض، إضافة، تعديل، حذف)',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF252A38) : const Color(0xFFF1F5F9),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // One-click Presets Bar
                  Text(
                    'قوالب الصلاحيات السريعة (بنقرة واحدة):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                  ),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPresetChip('👑 مدير كامل', 'admin', selectedPreset, () => applyPreset('admin', setModalState)),
                        const SizedBox(width: 6),
                        _buildPresetChip('🛒 كاشير مبيعات', 'cashier', selectedPreset, () => applyPreset('cashier', setModalState)),
                        const SizedBox(width: 6),
                        _buildPresetChip('📦 مسؤول مشتريات', 'purchaser', selectedPreset, () => applyPreset('purchaser', setModalState)),
                        const SizedBox(width: 6),
                        _buildPresetChip('🏬 أمين مخزن', 'inventory_keeper', selectedPreset, () => applyPreset('inventory_keeper', setModalState)),
                        const SizedBox(width: 6),
                        _buildPresetChip('💰 محاسب مالي', 'accountant', selectedPreset, () => applyPreset('accountant', setModalState)),
                        const SizedBox(width: 6),
                        _buildPresetChip('⚙️ مخصص', 'custom', selectedPreset, () => setModalState(() => selectedPreset = 'custom')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 10),

                  // Scrollable Permissions Matrix Cards
                  Expanded(
                    child: ListView(
                      children: SystemModules.all.map((mod) {
                        final currentPerm = perms[mod.id] ?? const ModuleActionPermission.none();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentPerm.canView ? mod.color.withValues(alpha: 0.4) : border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Module Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: mod.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(mod.icon, size: 16, color: mod.color),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mod.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          mod.subtitle,
                                          style: TextStyle(fontSize: 10, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quick Toggle All
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        selectedPreset = 'custom';
                                        if (currentPerm.isFull) {
                                          perms[mod.id] = const ModuleActionPermission.none();
                                        } else {
                                          perms[mod.id] = const ModuleActionPermission.all();
                                        }
                                      });
                                    },
                                    child: Text(
                                      currentPerm.isFull ? 'إلغاء الكل' : 'تحديد الكل',
                                      style: TextStyle(fontSize: 11, color: mod.color, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Row of 4 Checkbox Action Chips
                              Row(
                                children: [
                                  // 1. عرض (View)
                                  Expanded(
                                    child: _buildActionChip(
                                      title: 'عرض',
                                      icon: Icons.visibility_outlined,
                                      isSelected: currentPerm.canView,
                                      color: const Color(0xFF3B82F6),
                                      isDark: isDark,
                                      onTap: () {
                                        setModalState(() {
                                          selectedPreset = 'custom';
                                          final nextView = !currentPerm.canView;
                                          if (!nextView) {
                                            perms[mod.id] = const ModuleActionPermission.none();
                                          } else {
                                            perms[mod.id] = currentPerm.copyWith(canView: true);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 2. إضافة (Add)
                                  Expanded(
                                    child: _buildActionChip(
                                      title: 'إضافة',
                                      icon: Icons.add_circle_outline_rounded,
                                      isSelected: currentPerm.canAdd,
                                      color: const Color(0xFF10B981),
                                      isDark: isDark,
                                      isEnabled: currentPerm.canView,
                                      onTap: () {
                                        setModalState(() {
                                          selectedPreset = 'custom';
                                          final nextAdd = !currentPerm.canAdd;
                                          perms[mod.id] = currentPerm.copyWith(
                                            canView: true,
                                            canAdd: nextAdd,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 3. تعديل (Edit)
                                  Expanded(
                                    child: _buildActionChip(
                                      title: 'تعديل',
                                      icon: Icons.edit_note_rounded,
                                      isSelected: currentPerm.canEdit,
                                      color: const Color(0xFFF59E0B),
                                      isDark: isDark,
                                      isEnabled: currentPerm.canView,
                                      onTap: () {
                                        setModalState(() {
                                          selectedPreset = 'custom';
                                          final nextEdit = !currentPerm.canEdit;
                                          perms[mod.id] = currentPerm.copyWith(
                                            canView: true,
                                            canEdit: nextEdit,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 4. حذف (Delete)
                                  Expanded(
                                    child: _buildActionChip(
                                      title: 'حذف',
                                      icon: Icons.delete_outline_rounded,
                                      isSelected: currentPerm.canDelete,
                                      color: const Color(0xFFEF4444),
                                      isDark: isDark,
                                      isEnabled: currentPerm.canView,
                                      onTap: () {
                                        setModalState(() {
                                          selectedPreset = 'custom';
                                          final nextDelete = !currentPerm.canDelete;
                                          perms[mod.id] = currentPerm.copyWith(
                                            canView: true,
                                            canDelete: nextDelete,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Save Permissions Button
                  PrimaryButton(
                    text: 'حفظ واعتماد الصلاحيات في قاعدة البيانات',
                    icon: Icons.save_rounded,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);

                      await ref.read(usersListProvider.notifier).updatePermissions(
                        userId: user.id,
                        rolePreset: selectedPreset,
                        permissions: perms,
                      );

                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('تم تحديث صلاحيات (${user.name}) وحفظها بنجاح'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 3. Edit User Basic Info Modal (Name, Phone, Password) ──
  void _showEditUserBasicInfoModal(AppUserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final usernameCtrl = TextEditingController(text: user.username);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final passwordCtrl = TextEditingController(text: user.password);
    bool isPasswordVisible = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final surface = isDark ? const Color(0xFF181B22) : Colors.white;
            final border = isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E8F0);
            final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تعديل بيانات الحساب: ${user.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SettingsFormFieldWidget(
                      label: 'الاسم الكامل',
                      isRequired: true,
                      controller: nameCtrl,
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),

                    SettingsFormFieldWidget(
                      label: 'اسم الدخول',
                      isRequired: true,
                      controller: usernameCtrl,
                      prefixIcon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 10),

                    SettingsFormFieldWidget(
                      label: 'رقم الهاتف',
                      controller: phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كلمة المرور',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordCtrl,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 18,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E222D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    PrimaryButton(
                      text: 'حفظ التعديلات',
                      icon: Icons.check_circle_rounded,
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final username = usernameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final password = passwordCtrl.text.trim();
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);

                        if (name.isEmpty || username.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('الاسم واسم الدخول مطلوبان')),
                          );
                          return;
                        }

                        final updated = user.copyWith(
                          name: name,
                          username: username,
                          phone: phone.isNotEmpty ? phone : null,
                          password: password.isNotEmpty ? password : user.password,
                        );

                        await ref.read(usersListProvider.notifier).saveUser(updated);

                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('تم تحديث بيانات (${updated.name}) بنجاح'),
                          ),
                        );
                      },
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

  Widget _buildPresetChip(String title, String presetKey, String selectedPreset, VoidCallback onTap) {
    final isSelected = selectedPreset == presetKey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6366F1),
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final effectiveColor = isEnabled ? color : Colors.grey;
    final effectiveSelected = isEnabled && isSelected;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: effectiveSelected
              ? effectiveColor.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? const Color(0xFF141720) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: effectiveSelected ? effectiveColor : (isDark ? const Color(0xFF2B3040) : const Color(0xFFE2E8F0)),
            width: effectiveSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              effectiveSelected ? Icons.check_circle_rounded : icon,
              size: 13,
              color: effectiveSelected ? effectiveColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: effectiveSelected ? FontWeight.bold : FontWeight.normal,
                color: effectiveSelected
                    ? effectiveColor
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final users = ref.watch(usersListProvider);
    final currentActiveUser = ref.watch(activeUserProvider);

    // Filter users
    final filteredUsers = users.where((u) {
      if (_selectedRoleFilter != 'الكل') {
        if (_selectedRoleFilter == 'المدراء' && u.rolePreset != 'admin') {
          return false;
        }
        if (_selectedRoleFilter == 'الكاشير' && u.rolePreset != 'cashier') {
          return false;
        }
        if (_selectedRoleFilter == 'المخزن' && u.rolePreset != 'inventory_keeper') {
          return false;
        }
        if (_selectedRoleFilter == 'نشط' && !u.isActive) {
          return false;
        }
        if (_selectedRoleFilter == 'معطل' && u.isActive) {
          return false;
        }
      }

      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) {
        return true;
      }
      return u.name.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          (u.phone?.contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1117) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'المستخدمون والصلاحيات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(usersListProvider.notifier).load(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Current Active User Banner ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2433) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'الحساب الفعّال حالياً: ',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currentActiveUser.name,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          'الدور: ${currentActiveUser.roleTitle} (@${currentActiveUser.username})',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Search & Filter Controls ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث باسم المستخدم أو رمزه أو هاتفه...',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('الكل', isDark),
                  const SizedBox(width: 6),
                  _buildFilterTab('المدراء', isDark),
                  const SizedBox(width: 6),
                  _buildFilterTab('الكاشير', isDark),
                  const SizedBox(width: 6),
                  _buildFilterTab('المخزن', isDark),
                  const SizedBox(width: 6),
                  _buildFilterTab('نشط', isDark),
                  const SizedBox(width: 6),
                  _buildFilterTab('معطل', isDark),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Add New User Button ──
            PrimaryButton(
              text: 'إضافة مستخدم جديد (سريع)',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => _showAddQuickUserModal(),
            ),
            const SizedBox(height: 16),

            // ── Users List ──
            if (filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        users.isEmpty ? 'لا يوجد مستخدمون مسجلون بعد' : 'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                itemBuilder: (ctx, index) {
                  final user = filteredUsers[index];
                  final isCurrent = user.id == currentActiveUser.id;

                  return UserCardWidget(
                    user: user,
                    isCurrentActive: isCurrent,
                    onManagePermissions: () => _showPermissionsModal(user),
                    onEditBasic: () => _showEditUserBasicInfoModal(user),
                    onToggleActive: (val) => ref.read(usersListProvider.notifier).toggleStatus(user.id),
                    onSwitchToUser: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(activeUserProvider.notifier).switchUser(user.id);
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF6366F1),
                          content: Text('تم تفعيل حساب (${user.name}) كمستخدم حالي للنظام'),
                        ),
                      );
                      if (!user.can(SystemModules.settings, 'view') && context.mounted) {
                        context.go('/');
                      }
                    },
                    onDelete: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف المستخدم'),
                            ],
                          ),
                          content: Text('هل أنت متأكد من حذف حساب (${user.name}) نهائياً؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx, false),
                              child: const Text('إلغاء'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(dCtx, true),
                              child: const Text('تأكيد الحذف'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await ref.read(usersListProvider.notifier).deleteUser(user.id);
                        messenger.showSnackBar(
                          SnackBar(content: Text('تم حذف حساب (${user.name}) بنجاح')),
                        );
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isDark) {
    final isSelected = _selectedRoleFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? const Color(0xFF1E222D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
