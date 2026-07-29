import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class CostCentersView extends StatelessWidget {
  const CostCentersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'مراكز التكلفة (Cost Centers)',
      subtitle: 'تخصيص وتتبع الإيرادات والمصروفات حسب المشاريع والفروع',
      icon: Icons.pie_chart_rounded,
      themeColor: Color(0xFFF59E0B),
    );
  }
}
