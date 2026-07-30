import 'package:flutter/material.dart';
import 'financial_dashboard_view.dart';

class FinancialReportsView extends StatelessWidget {
  const FinancialReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: FinancialReportsTab()));
  }
}
