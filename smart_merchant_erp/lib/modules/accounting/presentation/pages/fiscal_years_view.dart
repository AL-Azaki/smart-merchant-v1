import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class FiscalYearsView extends StatelessWidget {
  const FiscalYearsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'السنوات المالية (Fiscal Years)',
      subtitle: 'إدارة وتحديد الفترات المالية والإقفال السنوي',
      icon: Icons.calendar_month_rounded,
      themeColor: Color(0xFF6366F1),
    );
  }
}
