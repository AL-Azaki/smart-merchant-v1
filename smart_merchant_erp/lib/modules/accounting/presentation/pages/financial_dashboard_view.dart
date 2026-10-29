import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../../application/usecases/post_journal_entry_usecase.dart';
import '../providers/accounting_provider.dart';
import '../widgets/chart_of_accounts_tab.dart';
import '../widgets/financial_reports_tab.dart';
import '../widgets/journal_entries_tab.dart';
import '../widgets/create_expense_dialog.dart';
import '../widgets/journal_entry_form_sheet.dart';
import '../widgets/payment_voucher_dialog.dart';
import '../widgets/receipt_voucher_dialog.dart';
import 'banks_and_cash_view.dart';
import 'expenses_view.dart';
import 'financial_analytics_view.dart';
import 'payment_vouchers_view.dart';
import 'receipt_vouchers_view.dart';

// ─── Main FinancialDashboardView ───────────────────────────────────────────────

class FinancialDashboardView extends ConsumerStatefulWidget {
  const FinancialDashboardView({super.key});

  @override
  ConsumerState<FinancialDashboardView> createState() => _FinancialDashboardViewState();
}

class _FinancialDashboardViewState extends ConsumerState<FinancialDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  final tabs = const [
    _TabItem(id: 'dashboard', label: 'لوحة التحكم', icon: Icons.dashboard_rounded, color: Color(0xFF10B981)),
    _TabItem(id: 'analytics', label: 'التحليلات', icon: Icons.insights_rounded, color: Color(0xFF6366F1)),
    _TabItem(id: 'expenses', label: 'المصروفات', icon: Icons.payments_rounded, color: Color(0xFFF97316)),
    _TabItem(id: 'receipts', label: 'سندات القبض', icon: Icons.call_received_rounded, color: Color(0xFF059669)),
    _TabItem(id: 'payments', label: 'سندات الصرف', icon: Icons.call_made_rounded, color: Color(0xFFEF4444)),
    _TabItem(id: 'banks', label: 'الخزينة والبنوك', icon: Icons.account_balance_rounded, color: Color(0xFF06B6D4)),
    _TabItem(id: 'coa', label: 'دليل الحسابات', icon: Icons.account_tree_rounded, color: Color(0xFF3B82F6)),
    _TabItem(id: 'journal', label: 'القيود اليومية', icon: Icons.receipt_long_rounded, color: Color(0xFF8B5CF6)),
    _TabItem(id: 'reports', label: 'التقارير المالية', icon: Icons.pie_chart_rounded, color: Color(0xFFEC4899)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    _tabController.animateTo(index);
    setState(() => _activeTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Module Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              color: surface,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المالية والمحاسبة والخزينة',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'إدارة الحسابات، السندات، الخزينة والتقارير المالية العامة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ──
            Container(
              color: surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                onTap: (i) => setState(() => _activeTab = i),
                indicatorColor: tabs[_activeTab].color,
                indicatorWeight: 3,
                dividerColor: borderColor,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: tabs.map((tab) {
                  final isActive = tabs.indexOf(tab) == _activeTab;
                  final tabColor = isActive
                      ? tab.color
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
                  return Tab(
                    height: 52,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 18, color: tabColor),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            color: tabColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _DashboardTab(
                    key: const ValueKey('dashboard'),
                    onSelectTab: _switchTab,
                  ),
                  const FinancialAnalyticsView(key: ValueKey('analytics')),
                  const ExpensesView(key: ValueKey('expenses')),
                  const ReceiptVouchersView(key: ValueKey('receipts')),
                  const PaymentVouchersView(key: ValueKey('payments')),
                  const BanksAndCashView(key: ValueKey('banks')),
                  const ChartOfAccountsTab(key: ValueKey('coa')),
                  const JournalEntriesTab(key: ValueKey('journal')),
                  const FinancialReportsTab(key: ValueKey('reports')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _TabItem({required this.id, required this.label, required this.icon, required this.color});
}

// ─── Tab 1: Real-time Live Dashboard ──────────────────────────────────────────

class _DashboardTab extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSelectTab;
  const _DashboardTab({super.key, this.onSelectTab});

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  String _search = '';

  String _formatNum(double n) {
    return '${n.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ر.ي';
  }

  Future<void> _openCreateReceiptDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const ReceiptVoucherDialog(),
    );
    if (res == true && mounted) {
      ref.invalidate(receiptVouchersStreamProvider);
      ref.invalidate(chartOfAccountsNotifierProvider);
      ref.invalidate(trialBalanceReportProvider());
    }
  }

  Future<void> _openCreatePaymentDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const PaymentVoucherDialog(),
    );
    if (res == true && mounted) {
      ref.invalidate(paymentVouchersStreamProvider);
      ref.invalidate(chartOfAccountsNotifierProvider);
      ref.invalidate(trialBalanceReportProvider());
    }
  }

  Future<void> _openCreateExpenseDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateExpenseDialog(),
    );
    if (res == true && mounted) {
      ref.invalidate(paymentVouchersStreamProvider);
      ref.invalidate(chartOfAccountsNotifierProvider);
      ref.invalidate(trialBalanceReportProvider());
    }
  }

  void _openCreateJournalEntry() {
    final coaAccounts = ref.read(chartOfAccountsNotifierProvider).value ?? [];
    final available = coaAccounts
        .map((a) => {'id': a.id, 'code': a.accountCode, 'name': a.accountName})
        .toList();

    JournalEntryFormSheet.show(
      context,
      availableAccounts: available,
      onSave: (entry, lines) async {
        final useCase = getIt<PostJournalEntryUseCase>();
        final session = ref.read(sessionNotifierProvider);
        if (!session.isActive || session.businessId == null) {
          return;
        }

        final lineCommands = lines
            .map((l) => JournalEntryLineCommand(
                  accountId: l.accountId,
                  debit: l.debit,
                  credit: l.credit,
                  description: l.description.isNotEmpty ? l.description : null,
                ))
            .toList();

        final cmd = PostJournalEntryCommand(
          documentDate: DateTime.now(),
          currencyId: 'YER',
          documentNumber: 'JE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          description: (entry['notes'] as String?) ?? (entry['description'] as String?) ?? 'قيد يدوي',
          lines: lineCommands,
        );

        final result = await useCase(cmd);
        if (mounted) {
          result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل ترحيل القيد: ${failure.message}'), backgroundColor: Colors.red),
            ),
            (id) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم ترحيل القيد بنجاح'), backgroundColor: Colors.green),
              );
              ref.invalidate(journalEntriesNotifierProvider);
              ref.invalidate(chartOfAccountsNotifierProvider);
              ref.invalidate(trialBalanceReportProvider());
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final receiptsAsync = ref.watch(receiptVouchersStreamProvider);
    final paymentsAsync = ref.watch(paymentVouchersStreamProvider);
    final journalAsync = ref.watch(journalEntriesNotifierProvider);
    final tbAsync = ref.watch(trialBalanceReportProvider());

    // Calculate real figures
    double totalReceipts = 0.0;
    receiptsAsync.whenData((receipts) {
      for (final r in receipts) {
        totalReceipts += r.amount;
      }
    });

    double totalPayments = 0.0;
    paymentsAsync.whenData((payments) {
      for (final p in payments) {
        totalPayments += p.amount;
      }
    });

    double cashBalance = 0.0;
    double bankBalance = 0.0;
    tbAsync.whenData((tb) {
      for (final item in tb.items) {
        final bal = item.netDebit - item.netCredit;
        if (item.accountCode.startsWith('11101') || item.accountName.contains('صندوق') || item.accountName.contains('خزينة')) {
          cashBalance += bal;
        } else if (item.accountCode.startsWith('11102') || item.accountName.contains('بنك') || item.accountName.contains('مصرف')) {
          bankBalance += bal;
        }
      }
    });

    final netCashFlow = totalReceipts - totalPayments;
    final totalVouchersCount = (receiptsAsync.value?.length ?? 0) + (paymentsAsync.value?.length ?? 0);
    final totalJournalCount = journalAsync.value?.length ?? 0;

    // Build real recent transactions from receipts & payments
    final receiptsList = receiptsAsync.value ?? [];
    final paymentsList = paymentsAsync.value ?? [];
    final allVouchers = <Payment>[...receiptsList, ...paymentsList]
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final filtered = allVouchers.where((v) {
      if (_search.isEmpty) {
        return true;
      }
      final q = _search.toLowerCase();
      return (v.notes?.toLowerCase().contains(q) ?? false) ||
          v.id.toLowerCase().contains(q) ||
          v.paymentMethodId.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Quick Action Chips ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _QuickActionChip(
                label: 'سند قبض جديد',
                icon: Icons.north_east_rounded,
                color: const Color(0xFF10B981),
                onTap: _openCreateReceiptDialog,
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'سند صرف جديد',
                icon: Icons.south_west_rounded,
                color: const Color(0xFFEF4444),
                onTap: _openCreatePaymentDialog,
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'تسجيل مصروف / صرفية',
                icon: Icons.payments_rounded,
                color: const Color(0xFFF97316),
                onTap: _openCreateExpenseDialog,
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'قيد يومي يدوي',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: _openCreateJournalEntry,
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'المصروفات',
                icon: Icons.payments_rounded,
                color: const Color(0xFFF97316),
                onTap: () => widget.onSelectTab?.call(2),
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'التحليلات المالية',
                icon: Icons.insights_rounded,
                color: const Color(0xFF6366F1),
                onTap: () => widget.onSelectTab?.call(1),
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'الخزينة والبنوك',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF06B6D4),
                onTap: () => widget.onSelectTab?.call(5),
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'دليل الحسابات',
                icon: Icons.account_tree_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => widget.onSelectTab?.call(6),
              ),
              const SizedBox(width: 14),
              _QuickActionChip(
                label: 'التقارير المالية',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => widget.onSelectTab?.call(8),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Real KPI Cards Grid ──
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final crossCount = isWide ? 3 : 2;
          final aspect = isWide ? 1.6 : 1.25;

          return GridView.count(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspect,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // رصيد الصندوق
              _SolidKpiCard(
                title: 'رصيد الصندوق النقدي',
                value: _formatNum(cashBalance),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF10B981),
              ),
              // رصيد البنك
              _SolidKpiCard(
                title: 'رصيد الحسابات البنكية',
                value: _formatNum(bankBalance),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF3B82F6),
              ),
              // إجمالي المقبوضات
              _BorderKpiCard(
                title: 'إجمالي المقبوضات',
                value: _formatNum(totalReceipts),
                icon: Icons.north_east_rounded,
                iconColor: const Color(0xFF10B981),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // إجمالي المدفوعات
              _BorderKpiCard(
                title: 'إجمالي المدفوعات',
                value: _formatNum(totalPayments),
                icon: Icons.south_west_rounded,
                iconColor: const Color(0xFFEF4444),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // صافي حركة النقدية
              _BorderKpiCard(
                title: 'صافي حركة النقدية',
                value: _formatNum(netCashFlow),
                valueColor: netCashFlow >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // عدد القيود والسندات
              _BorderKpiCard(
                title: 'القيود / السندات المسجلة',
                value: '$totalJournalCount قيد / $totalVouchersCount سند',
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          );
        }),

        const SizedBox(height: 28),

        // ── Toolbar ──
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'ابحث في السندات والعمليات المسجلة...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: '+ إضافة سند',
              color: const Color(0xFF3B82F6),
              textColor: Colors.white,
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.north_east_rounded, color: Color(0xFF10B981)),
                            ),
                            title: const Text('سند قبض جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('استلام دفعة من عميل أو إيراد نقدي / بنكي'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openCreateReceiptDialog();
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.south_west_rounded, color: Color(0xFFEF4444)),
                            ),
                            title: const Text('سند صرف جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('صرف دفعة لمورد أو مصروف تشغيلي'),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openCreatePaymentDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Real Recent Operations ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'آخر العمليات والسندات المسجلة فعلياً',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            Text(
              '${filtered.length} عملية',
              style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.hardEdge,
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد سندات أو عمليات مالية مسجلة بعد',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.take(15).length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isReceipt = item.paymentType == 'Receipt';
                    final color = isReceipt ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isReceipt ? Icons.north_east_rounded : Icons.south_west_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${isReceipt ? 'سند قبض' : 'سند صرف'} #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                      ),
                      subtitle: Text(
                        '${item.paymentMethodId} • ${item.notes ?? 'بدون ملاحظات'} • ${item.createdAt == null ? 'بدون تاريخ' : DateFormat('yyyy/MM/dd HH:mm', 'ar').format(item.createdAt!)}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${isReceipt ? '+' : '-'}${_formatNum(item.amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 60),
      ],
    );
  }
}

// ─── Shared Visual Components ──────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final LinearGradient gradient;
  final Color shadowColor;

  const _SolidKpiCard({
    required this.title,
    required this.value,
    required this.gradient,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shadowColor.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
          ),
        ],
      ),
    );
  }
}

class _BorderKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final Color surface;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const _BorderKpiCard({
    required this.title,
    required this.value,
    required this.surface,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.icon,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 15, color: iconColor),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ] else
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: valueColor ?? textPrimary, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
          ),
        ),
      ),
    );
  }
}
