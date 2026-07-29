import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class BanksAndCashView extends StatelessWidget {
  const BanksAndCashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'البنوك والحسابات النقدية',
      subtitle: 'إدارة حسابات الخزينة والصناديق والحسابات البنكية',
      icon: Icons.account_balance_rounded,
      themeColor: Color(0xFF06B6D4),
    );
  }
}
