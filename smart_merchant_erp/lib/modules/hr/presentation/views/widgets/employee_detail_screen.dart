import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/design_system/tokens/colors.dart';
import '../../../../../shared/design_system/tokens/spacing.dart';
import '../../../../../kernel/storage/app_database.dart';
import '../../providers/hr_provider.dart';
import 'employee_form_sheet.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final Employee employee;
  final VoidCallback onBack;

  const EmployeeDetailScreen({
    super.key,
    required this.employee,
    required this.onBack,
  });

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  int _activeTabIndex = 0;

  final _tabs = [
    'نظرة عامة',
    'المعلومات الشخصية',
    'المعلومات الوظيفية',
    'السجل المالي',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.info]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.employee.firstName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(widget.employee.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.employee.employeeCode} • الفرع الرئيسي',
                        style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          width: double.infinity,
          color: surfaceColor,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isActive = _activeTabIndex == index;
                return InkWell(
                  onTap: () => setState(() => _activeTabIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: isActive ? AppColors.primary : textSecondary,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildTabContent(surfaceColor, borderColor, textPrimary, textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab(surfaceColor, borderColor, textPrimary, textSecondary);
      case 1:
        return _buildPersonalInfoTab(surfaceColor, borderColor, textPrimary, textSecondary);
      case 2:
        return _buildJobInfoTab(surfaceColor, borderColor, textPrimary, textSecondary);
      case 3:
        return _buildFinancialTab(surfaceColor, borderColor, textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isMobile ? 3 : 2.5,
              children: [
                _buildOverviewCard(surfaceColor, borderColor, Icons.calendar_today, AppColors.info, 'تاريخ التوظيف', widget.employee.hireDate.toString().split(' ')[0], textPrimary, textSecondary),
                _buildOverviewCard(surfaceColor, borderColor, Icons.badge_outlined, AppColors.success, 'رمز الموظف', widget.employee.employeeCode, textPrimary, textSecondary),
                _buildOverviewCard(surfaceColor, borderColor, Icons.account_circle, AppColors.warning, 'الحالة الوظيفية', widget.employee.status == 'Active' ? 'نشط' : 'غير نشط', textPrimary, textSecondary),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('معلومات إدارية', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('الراتب الأساسي', '${widget.employee.salary} YER', textPrimary, textSecondary),
                  ),
                  Expanded(
                    child: _buildInfoItem('الفرع', 'الفرع الرئيسي', textPrimary, textSecondary),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOverviewCard(Color surfaceColor, Color borderColor, IconData icon, Color iconColor, String title, String value, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المعلومات الشخصية', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(width: 250, child: _buildInfoItem('الاسم الكامل', widget.employee.firstName, textPrimary, textSecondary)),
              SizedBox(width: 250, child: _buildInfoItem('رقم الهاتف', widget.employee.phone ?? '---', textPrimary, textSecondary)),
              SizedBox(width: 250, child: _buildInfoItem('البريد الإلكتروني', widget.employee.email ?? '---', textPrimary, textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المعلومات الوظيفية', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              SizedBox(width: 250, child: _buildInfoItem('رمز الموظف', widget.employee.employeeCode, textPrimary, textSecondary)),
              SizedBox(width: 250, child: _buildInfoItem('الراتب الأساسي', '${widget.employee.salary} YER', textPrimary, textSecondary)),
              SizedBox(width: 250, child: _buildInfoItem('الفرع', 'الفرع الرئيسي', textPrimary, textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab(Color surfaceColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.info),
          const SizedBox(height: 16),
          Text('السجل المالي للموظف', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('السجل المالي وإصدار الرواتب والسلف سيتم تفعيله من خلال ربط دليل الحسابات.', style: TextStyle(color: textSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 8),
                Text('CAPABILITY GAP: Employee Financial Documents not yet supported by backend', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Active';
    final isOnLeave = status == 'OnLeave';
    final badgeColor = isActive ? AppColors.success : (isOnLeave ? AppColors.warning : AppColors.error);
    final badgeText = isActive ? 'نشط' : (isOnLeave ? 'في إجازة' : 'موقوف');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
