import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../models/settings_card_item_model.dart';
import '../widgets/settings_group_section_widget.dart';
import '../widgets/settings_header_widget.dart';

import 'activity_log_view.dart';
import 'appearance_and_language_view.dart';
import 'backup_and_restore_view.dart';
import 'business_profile_view.dart';
import 'currencies_view.dart';
import 'print_settings_view.dart';
import 'product_categories_view.dart';
import 'roles_permissions_view.dart';
import 'taxes_and_fees_view.dart';
import 'units_of_measure_view.dart';
import 'users_management_view.dart';
import 'warehouses_and_branches_view.dart';

class SettingsControlCenterView extends StatelessWidget {
  const SettingsControlCenterView({super.key});

  List<SettingsGroupModel> _getSettingsGroups() {
    return const [
      SettingsGroupModel(
        title: 'الإدارة والمستخدمين',
        cards: [
          SettingsCardItemModel(
            id: 'business',
            title: 'معلومات المنشأة',
            description: 'إدارة بيانات النشاط التجاري والسجل التجاري والشعار',
            icon: Icons.business_rounded,
            color: Color(0xFF3B82F6),
            stats: ['المركز الرئيسي', 'الرقم الضريبي مسجل'],
            destinationView: BusinessProfileView(),
          ),
          SettingsCardItemModel(
            id: 'users',
            title: 'المستخدمون',
            description: 'إدارة الحسابات وصلاحيات الوصول والفروع',
            icon: Icons.people_alt_rounded,
            color: Color(0xFF8B5CF6),
            stats: ['12 مستخدم', '2 متصل حالياً'],
            destinationView: UsersManagementView(),
          ),
          SettingsCardItemModel(
            id: 'roles',
            title: 'الأدوار والصلاحيات',
            description: 'تحديد مستويات الوصول والتكليفات لكل دور',
            icon: Icons.shield_rounded,
            color: Color(0xFF14B8A6),
            stats: ['4 أدوار نشطة', '120 صلاحية'],
            destinationView: RolesPermissionsView(),
          ),
        ],
      ),
      SettingsGroupModel(
        title: 'المالية والمخزون',
        cards: [
          SettingsCardItemModel(
            id: 'currencies',
            title: 'العملات والصرف',
            description: 'إدارة العملات المحلية والأجنبية وأسعار الصرف',
            icon: Icons.attach_money_rounded,
            color: Color(0xFF10B981),
            stats: ['3 عملات', 'الأساسية: YER'],
            destinationView: CurrenciesView(),
          ),
          SettingsCardItemModel(
            id: 'categories',
            title: 'فئات المنتجات',
            description: 'تصنيف وتنظيم الأصناف والفئات الرئيسية والفرعية',
            icon: Icons.sell_rounded,
            color: Color(0xFFF59E0B),
            stats: ['18 فئة', '420 منتج'],
            destinationView: ProductCategoriesView(),
          ),
          SettingsCardItemModel(
            id: 'units',
            title: 'وحدات القياس',
            description: 'تعريف وحدات البيع والشراء ومعاملات التحويل',
            icon: Icons.straighten_rounded,
            color: Color(0xFFEC4899),
            stats: ['12 وحدة', 'الافتراضية: قطعة'],
            destinationView: UnitsOfMeasureView(),
          ),
          SettingsCardItemModel(
            id: 'taxes',
            title: 'الضرائب والرسوم',
            description: 'إعدادات ضريبة القيمة المضافة وتطبيقها على الأسعار',
            icon: Icons.percent_rounded,
            color: Color(0xFFEF4444),
            stats: ['القيمة المضافة 15%', 'مفعل'],
            destinationView: TaxesAndFeesView(),
          ),
          SettingsCardItemModel(
            id: 'warehouses',
            title: 'المستودعات والفروع',
            description: 'إدارة الفروع وتخصيص نقاط البيع والمستودعات',
            icon: Icons.store_rounded,
            color: Color(0xFF6366F1),
            stats: ['3 فروع', '2 مستودع'],
            destinationView: WarehousesAndBranchesView(),
          ),
        ],
      ),
      SettingsGroupModel(
        title: 'النظام والتفضيلات',
        cards: [
          SettingsCardItemModel(
            id: 'print',
            title: 'إعدادات الطباعة',
            description: 'طابعات الفواتير الحرارية والباركود والـ QR Code',
            icon: Icons.print_rounded,
            color: Color(0xFF06B6D4),
            stats: ['طابعة حرارية 80mm', 'QR مفعل'],
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
            title: 'النسخ الاحتياطي',
            description: 'أخذ نسخة احتياطية من البيانات واستعادتها عند الحاجة',
            icon: Icons.cloud_sync_rounded,
            color: Color(0xFF10B981),
            stats: ['تلقائي يومياً', 'آخر نسخة: اليوم'],
            destinationView: BackupAndRestoreView(),
          ),
          SettingsCardItemModel(
            id: 'activity',
            title: 'سجل النشاط',
            description: 'مراقبة حركات النظام والتغييرات والعمليات المنفذة',
            icon: Icons.auto_graph_rounded,
            color: Color(0xFFF59E0B),
            stats: ['1,240 عملية اليوم'],
            destinationView: ActivityLogView(),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _getSettingsGroups();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header Bar
          const SettingsHeaderWidget(
            title: 'مركز الإعدادات (Control Center)',
            description: 'إدارة تفضيلات النظام، الفروع، والمستخدمين',
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
                          onCardTap: (cardItem) {
                            Navigator.of(context).push(
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
