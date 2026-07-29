import 'package:flutter/material.dart';
import 'finance_section_placeholder_view.dart';

class ReceiptVouchersView extends StatelessWidget {
  const ReceiptVouchersView({super.key});

  @override
  Widget build(BuildContext context) {
    return const FinanceSectionPlaceholderView(
      title: 'سندات القبض (Receipt Vouchers)',
      subtitle: 'إدارة وتوثيق مقبوضات النقدية والتحويلات البنكية',
      icon: Icons.north_east_rounded,
      themeColor: Color(0xFF10B981),
    );
  }
}
