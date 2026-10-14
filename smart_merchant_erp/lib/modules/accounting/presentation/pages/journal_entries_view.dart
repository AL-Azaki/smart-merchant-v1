import 'package:flutter/material.dart';
import '../widgets/journal_entries_tab.dart';

class JournalEntriesView extends StatelessWidget {
  const JournalEntriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: JournalEntriesTab()));
  }
}
