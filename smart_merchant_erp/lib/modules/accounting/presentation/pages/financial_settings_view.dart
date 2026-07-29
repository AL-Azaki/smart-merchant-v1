import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class FinancialSettingsView extends StatelessWidget {
  const FinancialSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'الإعدادات المالية والمحاسبية',
      subtitle: 'إعدادات الحسابات الافتراضية، التسلسل، وتفضيلات النظام المالي',
      icon: Icons.tune_rounded,
      themeColor: Color(0xFF64748B),
    );
  }
}
