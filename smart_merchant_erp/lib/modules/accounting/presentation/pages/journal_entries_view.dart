import 'package:flutter/material.dart';
import 'financial_dashboard_view.dart';

class JournalEntriesView extends StatelessWidget {
  const JournalEntriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: JournalEntriesTab()));
  }
}
