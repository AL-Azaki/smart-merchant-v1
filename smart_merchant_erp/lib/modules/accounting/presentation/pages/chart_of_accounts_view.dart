import 'package:flutter/material.dart';
import 'financial_dashboard_view.dart';

class ChartOfAccountsView extends StatelessWidget {
  const ChartOfAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: ChartOfAccountsTab()));
  }
}
