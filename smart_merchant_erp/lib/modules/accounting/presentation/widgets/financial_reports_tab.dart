import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import 'balance_sheet_tab.dart';
import 'cash_flow_tab.dart';
import 'general_ledger_tab.dart';
import 'profit_loss_tab.dart';
import 'trial_balance_tab.dart';
import 'year_end_closing_dialog.dart';

/// Central Financial Reports Hub providing access to live Trial Balance,
/// Balance Sheet (ميزان العمومية), Cash Flow Statement (التدفق المالي),
/// Income Statement (Profit & Loss), General Ledger, and Year-End Closing.
class FinancialReportsTab extends ConsumerStatefulWidget {
  const FinancialReportsTab({super.key});

  @override
  ConsumerState<FinancialReportsTab> createState() => _FinancialReportsTabState();
}

class _FinancialReportsTabState extends ConsumerState<FinancialReportsTab> with SingleTickerProviderStateMixin {
  late TabController _reportsController;

  @override
  void initState() {
    super.initState();
    _reportsController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _reportsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Column(
      children: [
        // Top Action & Sub-Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              // Sub Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _reportsController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: textPrimary,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('ميزان المراجعة', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('الميزانية العمومية', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.waves_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('قائمة التدفق المالي', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('قائمة الدخل والأرباح', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.auto_stories_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('دفتر الأستاذ العام', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Year-End Closing Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.lock_clock_rounded, size: 18),
                label: const Text('الإقفال السنوي', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const YearEndClosingDialog(),
                  );
                },
              ),
            ],
          ),
        ),

        // Sub Tab Views
        Expanded(
          child: TabBarView(
            controller: _reportsController,
            children: const [
              TrialBalanceTab(),
              BalanceSheetTab(),
              CashFlowTab(),
              ProfitLossTab(),
              GeneralLedgerTab(),
            ],
          ),
        ),
      ],
    );
  }
}
