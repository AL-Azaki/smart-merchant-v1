import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class CurrenciesManagementView extends StatelessWidget {
  const CurrenciesManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'إدارة العملات وسعر الصرف',
      subtitle: 'تحديد العملات الأساسية والفرعية وتحديث أسعار الصرف التبادلية',
      icon: Icons.currency_exchange_rounded,
      themeColor: Color(0xFF10B981),
    );
  }
}
