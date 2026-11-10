import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../kernel/security/permissions_provider.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../models/settings_card_item_model.dart';
import '../widgets/settings_group_section_widget.dart';
import '../widgets/settings_header_widget.dart';

import 'activity_log_view.dart';
import 'appearance_and_language_view.dart';
import 'backup_and_restore_view.dart';
import 'business_profile_view.dart';
import 'currencies_view.dart';
import 'demo_data_management_view.dart';
import 'print_settings_view.dart';
import 'product_categories_view.dart';
import 'roles_permissions_view.dart';
import 'storefront_settings_view.dart';
import 'units_of_measure_view.dart';
import 'users_management_view.dart';
import 'warehouses_and_branches_view.dart';

class SettingsControlCenterView extends ConsumerWidget {
  const SettingsControlCenterView({super.key});

  List<SettingsGroupModel> _getSettingsGroups({
    required String businessName,
    required String? businessPhone,
  }) {
    final businessStats = <String>[
      businessName.isNotEmpty ? businessName : 'المركز الرئيسي',
      if (businessPhone != null && businessPhone.trim().isNotEmpty)
        businessPhone.trim()
      else
        'الهوية والتواصل',
    ];

    return [
      SettingsGroupModel(
        title: 'الإدارة والمستخدمين',
        cards: [
          SettingsCardItemModel(
            id: 'business',
            title: 'معلومات المنشأة',
            description:
                'إدارة الاسم التجاري، النشاط، رقم التواصل، العنوان والشعار',
            icon: Icons.business_rounded,
            color: const Color(0xFF3B82F6),
            stats: businessStats,
            destinationView: const BusinessProfileView(),
          ),
          const SettingsCardItemModel(
            id: 'users',
            title: 'المستخدمون',
            description: 'إدارة الحسابات وصلاحيات الوصول والفروع',
            icon: Icons.people_alt_rounded,
            color: Color(0xFF8B5CF6),
            stats: ['حسابات الموظفين', 'تبديل سريع'],
            destinationView: UsersManagementView(),
          ),
          const SettingsCardItemModel(
            id: 'roles',
            title: 'الأدوار والصلاحيات',
            description: 'تحديد مستويات الوصول والتكليفات لكل دور',
            icon: Icons.shield_rounded,
            color: Color(0xFF14B8A6),
            stats: ['4 أدوار نشطة', 'صلاحيات مخصصة'],
            destinationView: RolesPermissionsView(),
          ),
          const SettingsCardItemModel(
            id: 'storefront',
            title: 'إعدادات المتجر الإلكتروني',
            description: 'الرابط العام للمتجر، تفعيل استقبال الطلبات، وبيانات التواصل',
            icon: Icons.storefront_rounded,
            color: Color(0xFF0EA5E9),
            stats: ['الرابط المباشر', 'مُدار مركزياً'],
            destinationView: StorefrontSettingsView(),
          ),
        ],
      ),
      const SettingsGroupModel(
        title: 'المالية والمخزون',
        cards: [
          SettingsCardItemModel(
            id: 'currencies',
            title: 'العملات والصرف',
            description: 'إدارة العملات المحلية والأجنبية وأسعار الصرف',
            icon: Icons.attach_money_rounded,
            color: Color(0xFF10B981),
            stats: ['الأساسية: YER', 'أسعار الصرف'],
            destinationView: CurrenciesView(),
          ),
          SettingsCardItemModel(
            id: 'categories',
            title: 'فئات المنتجات',
            description: 'تصنيف وتنظيم الأصناف والفئات الرئيسية والفرعية',
            icon: Icons.sell_rounded,
            color: Color(0xFFF59E0B),
            stats: ['الأقسام الرئيسية', 'التصنيفات'],
            destinationView: ProductCategoriesView(),
          ),
          SettingsCardItemModel(
            id: 'units',
            title: 'وحدات القياس',
            description: 'تعريف وحدات البيع والشراء ومعاملات التحويل',
            icon: Icons.straighten_rounded,
            color: Color(0xFFEC4899),
            stats: ['الافتراضية: قطعة', 'عبوات التحويل'],
            destinationView: UnitsOfMeasureView(),
          ),
          SettingsCardItemModel(
            id: 'warehouses',
            title: 'المستودعات والفروع',
            description: 'إدارة الفروع وتخصيص نقاط البيع والمستودعات',
            icon: Icons.store_rounded,
            color: Color(0xFF6366F1),
            stats: ['الفروع النشطة', 'المخازن'],
            destinationView: WarehousesAndBranchesView(),
          ),
        ],
      ),
      const SettingsGroupModel(
        title: 'النظام والتفضيلات',
        cards: [
          SettingsCardItemModel(
            id: 'print',
            title: 'إعدادات الطباعة',
            description: 'طابعات الفواتير الحرارية والباركود والـ QR Code',
            icon: Icons.print_rounded,
            color: Color(0xFF06B6D4),
            stats: ['طابعة حرارية 80mm', 'ترويسة الفواتير'],
            destinationView: PrintSettingsView(),
          ),
          SettingsCardItemModel(
            id: 'appearance',
            title: 'المظهر واللغة',
            description: 'تخصيص نمط الواجهة والوضع المظلم/الفاتح واللغات',
            icon: Icons.palette_rounded,
            color: Color(0xFF8B5CF6),
            stats: ['الوضع المظلم متوفر', 'العربية'],
            destinationView: AppearanceAndLanguageView(),
          ),
          SettingsCardItemModel(
            id: 'backup',
            title: 'النسخ الاحتياطي والاستعادة',
            description: 'أخذ نسخة احتياطية من البيانات واستعادتها عند الحاجة',
            icon: Icons.cloud_sync_rounded,
            color: Color(0xFF10B981),
            stats: ['محلي مشفر', 'Argon2id + AES'],
            destinationView: BackupAndRestoreView(),
          ),
          SettingsCardItemModel(
            id: 'activity',
            title: 'سجل النشاط',
            description: 'مراقبة حركات النظام والتغييرات والعمليات المنفذة',
            icon: Icons.auto_graph_rounded,
            color: Color(0xFFF59E0B),
            stats: ['رقابة العمليات', 'سجل الحركات'],
            destinationView: ActivityLogView(),
          ),
          SettingsCardItemModel(
            id: 'demo_data',
            title: 'البيانات التجريبية والتصفير',
            description:
                'توليد منتجات وعملاء وموردين بأسماء واقعية أو تصفيرهم للاختبار',
            icon: Icons.auto_awesome_rounded,
            color: Color(0xFF6366F1),
            stats: ['منتجات تجريبية', 'تصفير آمن'],
            destinationView: DemoDataManagementView(),
          ),
          SettingsCardItemModel(
            id: 'logout',
            title: 'تسجيل الخروج',
            description: 'إنهاء الجلسة الحالية وتسجيل الدخول بحساب آخر',
            icon: Icons.logout_rounded,
            color: Color(0xFFEF4444),
            stats: ['تبديل الحساب'],
            destinationView: SizedBox.shrink(),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUser = ref.watch(activeUserProvider);
    final canViewSettings = activeUser.can(SystemModules.settings, 'view');
    if (!canViewSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBusiness = ref.watch(currentBusinessEntityProvider).valueOrNull;
    final groups = _getSettingsGroups(
      businessName: currentBusiness?.businessName ?? '',
      businessPhone: currentBusiness?.primaryPhone,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar
          const SettingsHeaderWidget(
            title: 'مركز الإعدادات (Control Center)',
            description: 'إدارة بيانات المنشأة، الفروع، والمستخدمين وتفضيلات النظام',
          ),

          // Scrollable Settings Cards Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    children: [
                      for (int i = 0; i < groups.length; i++) ...[
                        SettingsGroupSectionWidget(
                          group: groups[i],
                          mainAxisExtent: groups[i].cards.any((c) => c.stats.isNotEmpty)
                              ? 210
                              : 185,
                          onCardTap: (cardItem) async {
                            if (cardItem.id == 'logout') {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تسجيل الخروج'),
                                  content: const Text(
                                    'هل أنت متأكد من رغبتك في تسجيل الخروج والعودة لشاشة الدخول؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('إلغاء'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text(
                                        'تأكيد الخروج',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldLogout == true) {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                              }
                              return;
                            }
                            if (!context.mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => cardItem.destinationView,
                              ),
                            );
                          },
                        ),
                        if (i < groups.length - 1)
                          const SizedBox(height: AppSpacing.xxl),
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
