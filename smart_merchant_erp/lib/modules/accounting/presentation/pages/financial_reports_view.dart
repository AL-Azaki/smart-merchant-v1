import 'package:flutter/material.dart';
import '../widgets/financial_reports_tab.dart';

class FinancialReportsView extends StatelessWidget {
  const FinancialReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: FinancialReportsTab()));
  }
}
