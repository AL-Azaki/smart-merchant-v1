import 'package:flutter/material.dart';
import '../widgets/chart_of_accounts_tab.dart';

class ChartOfAccountsView extends StatelessWidget {
  const ChartOfAccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: ChartOfAccountsTab()));
  }
}
