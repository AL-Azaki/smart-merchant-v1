import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class PaymentVouchersView extends StatelessWidget {
  const PaymentVouchersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'سندات الصرف (Payment Vouchers)',
      subtitle: 'إدارة وتوثيق المدفوعات والمصروفات النقدية والبنكية',
      icon: Icons.south_west_rounded,
      themeColor: Color(0xFFEF4444),
    );
  }
}
