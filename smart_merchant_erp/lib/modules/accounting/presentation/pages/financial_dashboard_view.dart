import 'package:flutter/material.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/journal_entry_form_sheet.dart';
import '../widgets/account_form_sheet.dart';
import '../widgets/transaction_details_sheet.dart';
import '../widgets/journal_entry_details_sheet.dart';
import '../widgets/chart_of_accounts_tab.dart';
import '../widgets/journal_entries_tab.dart';
import '../widgets/financial_reports_tab.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_search_filter_bar.dart';

// ─── Mock Data ─────────────────────────────────────────────────────────────────

class _MockTransaction {
  final String id;
  final String type; // income | expense
  final int amount;
  final String category;
  final String description;
  final DateTime date;
  final String? ref;

  const _MockTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.ref,
  });
}

final _mockTransactions = <_MockTransaction>[
  _MockTransaction(id: 'tx_1', type: 'income', amount: 150000, category: 'sales', description: 'مبيعات الكاشير الوردية الصباحية', date: DateTime.now()),
  _MockTransaction(id: 'tx_2', type: 'expense', amount: 12000, category: 'utilities', description: 'فاتورة كهرباء', date: DateTime.now().subtract(const Duration(days: 1))),
  _MockTransaction(id: 'tx_3', type: 'expense', amount: 5000, category: 'other_expense', description: 'ضيافة للعملاء', date: DateTime.now().subtract(const Duration(days: 2))),
];

// ─── Main FinancialDashboardView ───────────────────────────────────────────────

class FinancialDashboardView extends StatefulWidget {
  const FinancialDashboardView({super.key});

  @override
  State<FinancialDashboardView> createState() => _FinancialDashboardViewState();
}

class _FinancialDashboardViewState extends State<FinancialDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final tabs = [
      _TabItem(id: 'dashboard', label: 'لوحة التحكم', icon: Icons.account_balance_wallet_rounded, color: const Color(0xFF10B981)),
      _TabItem(id: 'coa', label: 'دليل الحسابات', icon: Icons.account_tree_rounded, color: const Color(0xFF3B82F6)),
      _TabItem(id: 'journal', label: 'القيود اليومية', icon: Icons.receipt_long_rounded, color: const Color(0xFF8B5CF6)),
      _TabItem(id: 'reports', label: 'التقارير', icon: Icons.pie_chart_rounded, color: const Color(0xFFEC4899)),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Module Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              color: surface,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المالية والمحاسبة',
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'إدارة الشؤون المالية والحسابات',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar (native Flutter TabBar, RTL-safe, non-scrollable) ──
            Container(
              color: surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                onTap: (i) => setState(() => _activeTab = i),
                indicatorColor: tabs[_activeTab].color,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: borderColor,
                labelPadding: EdgeInsets.zero,
                tabs: tabs.map((tab) {
                  final isActive = tabs.indexOf(tab) == _activeTab;
                  final tabColor = isActive ? tab.color
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
                  return Tab(
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.icon, size: 20, color: tabColor),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: tabColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    onSelectTab: (index) {
                      _tabController.animateTo(index);
                      setState(() => _activeTab = index);
                    },
                  ),
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

// ─── Tab 1: Dashboard ──────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;
  const _DashboardTab({super.key, this.onSelectTab});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  String _search = '';

  String _getCategoryName(String key) {
    const map = {
      'sales': 'إيرادات مبيعات',
      'services': 'إيرادات خدمات',
      'investments': 'عوائد استثمار',
      'other_income': 'إيرادات أخرى',
      'salaries': 'رواتب وأجور',
      'rent': 'إيجارات',
      'utilities': 'فواتير خدمات (كهرباء، ماء)',
      'marketing': 'تسويق وإعلان',
      'maintenance': 'صيانة وإصلاح',
      'office_supplies': 'مستلزمات مكتبية',
      'other_expense': 'مصروفات أخرى',
    };
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgSurface = isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9);

    final totalIncome = _mockTransactions.where((t) => t.type == 'income').fold(0, (a, t) => a + t.amount);
    final totalExpense = _mockTransactions.where((t) => t.type == 'expense').fold(0, (a, t) => a + t.amount);
    final balance = totalIncome - totalExpense;

    final filtered = _mockTransactions.where((t) {
      if (_search.isEmpty) return true;
      return t.description.contains(_search) || t.category.contains(_search);
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
                label: 'سند قبض',
                icon: Icons.north_east_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  TransactionFormSheet.show(
                    context,
                    initialType: 'income',
                    onSave: (data, print) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حفظ سند القبض بمبلغ ${data['amount']} ${data['currency_id']}')),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              _QuickActionChip(
                label: 'سند صرف',
                icon: Icons.south_west_rounded,
                color: const Color(0xFFEF4444),
                onTap: () {
                  TransactionFormSheet.show(
                    context,
                    initialType: 'expense',
                    onSave: (data, print) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حفظ سند الصرف بمبلغ ${data['amount']} ${data['currency_id']}')),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              _QuickActionChip(
                label: 'قيد يومي',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  JournalEntryFormSheet.show(
                    context,
                    onSave: (entry, lines) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم حفظ وترحيل القيد اليومي بمبلغ ${entry['totalDebit']} ر.ي')),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              _QuickActionChip(
                label: 'دليل الحسابات',
                icon: Icons.account_tree_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () {
                  widget.onSelectTab?.call(1);
                },
              ),
              const SizedBox(width: 16),
              _QuickActionChip(
                label: 'التقارير',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFEC4899),
                onTap: () {
                  widget.onSelectTab?.call(3);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── KPI Cards Grid ──
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossCount = isWide ? 3 : 2;
          final aspect = isWide ? 1.6 : 1.2;
          return GridView.count(

            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspect,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // رصيد الصندوق - solid green
              _SolidKpiCard(
                title: 'رصيد الصندوق',
                value: '${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ر.ي',
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF10B981),
              ),
              // رصيد البنك - solid blue
              _SolidKpiCard(
                title: 'رصيد البنك',
                value: '1,450,000 ر.ي',
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shadowColor: const Color(0xFF3B82F6),
              ),
              // إجمالي الإيرادات
              _BorderKpiCard(
                title: 'إجمالي الإيرادات',
                value: _formatNum(totalIncome),
                icon: Icons.north_east_rounded,
                iconColor: const Color(0xFF3B82F6),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // إجمالي المصروفات
              _BorderKpiCard(
                title: 'إجمالي المصروفات',
                value: _formatNum(totalExpense),
                icon: Icons.south_west_rounded,
                iconColor: const Color(0xFFEF4444),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // صافي الربح
              _BorderKpiCard(
                title: 'صافي الربح',
                value: _formatNum(balance),
                valueColor: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // عدد القيود اليوم
              _BorderKpiCard(
                title: 'عدد القيود اليوم',
                value: '0',
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              // عدد السندات
              _BorderKpiCard(
                title: 'عدد السندات',
                value: '${_mockTransactions.length}',
                surface: surface,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          );
        }),

        const SizedBox(height: 32),

        // ── Toolbar ──
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'ابحث في العمليات المالية...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
                TransactionFormSheet.show(
                  context,
                  initialType: 'income',
                  onSave: (data, print) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حفظ السند بمبلغ ${data['amount']} ${data['currency_id']}')),
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'تصدير',
              icon: Icons.download_rounded,
              color: bgSurface,
              textColor: textPrimary,
              borderColor: borderColor,
              onTap: () => _showSnack(context, 'جاري التصدير...'),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── آخر العمليات ──
        Text(
          'آخر العمليات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              ...filtered.asMap().entries.map((entry) {
                final i = entry.key;
                final trx = entry.value;
                final isLast = i == filtered.length - 1;
                final isIncome = trx.type == 'income';
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        TransactionDetailsSheet.show(
                          context,
                          transaction: {
                            'id': trx.id,
                            'type': trx.type,
                            'amount': trx.amount,
                            'currency': 'ر.ي',
                            'date': '${trx.date.year}-${trx.date.month.toString().padLeft(2, '0')}-${trx.date.day.toString().padLeft(2, '0')}',
                            'category': trx.category,
                            'description': trx.description,
                            'ref': trx.ref,
                            'entityType': 'عام',
                            'entityName': 'جهة عملية',
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? const Color(0xFF3B82F6).withOpacity(0.1)
                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isIncome ? Icons.north_east_rounded : Icons.south_west_rounded,
                                color: isIncome ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trx.description,
                                    style: TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.description_outlined, size: 16, color: textSecondary),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _getCategoryName(trx.category),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.calendar_today_rounded, size: 16, color: textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${trx.date.day}/${trx.date.month}/${trx.date.year}',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${_formatNum(trx.amount)}',
                              style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900,
                                color: isIncome ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast) Divider(height: 1, color: borderColor),
                  ],
                );
              }),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'لا توجد عمليات مالية',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatNum(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: shadowColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
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
            child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ] else
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor ?? textPrimary, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: borderColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor!, width: 1.5),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

