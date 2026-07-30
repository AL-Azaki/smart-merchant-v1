import 'package:flutter/material.dart';
import '../widgets/transaction_form_sheet.dart';
import '../widgets/journal_entry_form_sheet.dart';
import '../widgets/account_form_sheet.dart';
import '../widgets/transaction_details_sheet.dart';
import '../widgets/journal_entry_details_sheet.dart';
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

class _MockAccount {
  final String id;
  final String code;
  final String name;
  final String type; // Asset, Liability, Equity, Revenue, Expense
  final String? parentId;
  final bool allowPosting;

  const _MockAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.allowPosting = true,
  });
}

class _MockJournalEntry {
  final String id;
  final String number;
  final String refType;
  final String description;
  final DateTime date;
  final String status;
  final int totalDebit;
  final int totalCredit;
  final int linesCount;

  const _MockJournalEntry({
    required this.id,
    required this.number,
    required this.refType,
    required this.description,
    required this.date,
    required this.status,
    required this.totalDebit,
    required this.totalCredit,
    required this.linesCount,
  });

  bool get isBalanced => (totalDebit - totalCredit).abs() < 1;
}

final _mockTransactions = <_MockTransaction>[
  _MockTransaction(id: 'tx_1', type: 'income', amount: 150000, category: 'sales', description: 'مبيعات الكاشير الوردية الصباحية', date: DateTime.now()),
  _MockTransaction(id: 'tx_2', type: 'expense', amount: 12000, category: 'utilities', description: 'فاتورة كهرباء', date: DateTime.now().subtract(const Duration(days: 1))),
  _MockTransaction(id: 'tx_3', type: 'expense', amount: 5000, category: 'other_expense', description: 'ضيافة للعملاء', date: DateTime.now().subtract(const Duration(days: 2))),
];

final _mockAccounts = <_MockAccount>[
  const _MockAccount(id: 'acc_1', code: '1000', name: 'الأصول', type: 'Asset', parentId: null, allowPosting: false),
  const _MockAccount(id: 'acc_2', code: '1100', name: 'الأصول المتداولة', type: 'Asset', parentId: 'acc_1', allowPosting: false),
  const _MockAccount(id: 'acc_3', code: '1110', name: 'الصندوق', type: 'Asset', parentId: 'acc_2', allowPosting: true),
  const _MockAccount(id: 'acc_4', code: '1120', name: 'البنك', type: 'Asset', parentId: 'acc_2', allowPosting: true),
  const _MockAccount(id: 'acc_5', code: '2000', name: 'الخصوم', type: 'Liability', parentId: null, allowPosting: false),
  const _MockAccount(id: 'acc_6', code: '2100', name: 'الخصوم المتداولة', type: 'Liability', parentId: 'acc_5', allowPosting: false),
  const _MockAccount(id: 'acc_7', code: '3000', name: 'حقوق الملكية', type: 'Equity', parentId: null, allowPosting: false),
  const _MockAccount(id: 'acc_8', code: '3100', name: 'رأس المال', type: 'Equity', parentId: 'acc_7', allowPosting: true),
  const _MockAccount(id: 'acc_9', code: '4000', name: 'الإيرادات', type: 'Revenue', parentId: null, allowPosting: false),
  const _MockAccount(id: 'acc_10', code: '4100', name: 'إيرادات المبيعات', type: 'Revenue', parentId: 'acc_9', allowPosting: true),
  const _MockAccount(id: 'acc_11', code: '5000', name: 'المصروفات', type: 'Expense', parentId: null, allowPosting: false),
  const _MockAccount(id: 'acc_12', code: '5100', name: 'تكلفة المبيعات', type: 'Expense', parentId: 'acc_11', allowPosting: true),
  const _MockAccount(id: 'acc_13', code: '5200', name: 'مصروفات تشغيلية', type: 'Expense', parentId: 'acc_11', allowPosting: false),
  const _MockAccount(id: 'acc_14', code: '5210', name: 'فواتير خدمات', type: 'Expense', parentId: 'acc_13', allowPosting: true),
  const _MockAccount(id: 'acc_15', code: '5220', name: 'رواتب وأجور', type: 'Expense', parentId: 'acc_13', allowPosting: true),
];

final _mockJournalEntries = <_MockJournalEntry>[
  _MockJournalEntry(
    id: 'je_1', number: 'JE-2024-001', refType: 'SalesInvoice',
    description: 'إثبات مبيعات يومية - فاتورة ر...',
    date: DateTime(2024, 6, 25), status: 'Posted',
    totalDebit: 8700, totalCredit: 8700, linesCount: 2,
  ),
  _MockJournalEntry(
    id: 'je_2', number: 'JE-2024-002', refType: 'Expense',
    description: 'سداد مصروف نثريات وضيافة',
    date: DateTime(2024, 6, 25), status: 'Posted',
    totalDebit: 8000, totalCredit: 8000, linesCount: 2,
  ),
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
                value: '${_mockJournalEntries.length}',
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

// ─── Tab 2: Chart of Accounts ──────────────────────────────────────────────────

class ChartOfAccountsTab extends StatefulWidget {
  const ChartOfAccountsTab({super.key});

  @override
  State<ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends State<ChartOfAccountsTab> {
  String _search = '';
  String _selectedTypeFilter = 'all';
  final Set<String> _expanded = {'acc_1', 'acc_5', 'acc_7', 'acc_9', 'acc_11'};

  Color _typeColor(String type) {
    switch (type) {
      case 'Asset':
        return const Color(0xFF3B82F6);
      case 'Liability':
        return const Color(0xFFEF4444);
      case 'Equity':
        return const Color(0xFF8B5CF6);
      case 'Revenue':
        return const Color(0xFF10B981);
      case 'Expense':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _typeLabelAr(String type) {
    switch (type) {
      case 'Asset':
        return 'أصول';
      case 'Liability':
        return 'خصوم';
      case 'Equity':
        return 'حقوق ملكية';
      case 'Revenue':
        return 'إيرادات';
      case 'Expense':
        return 'مصروفات';
      default:
        return type;
    }
  }

  List<_MockAccount> _children(String? parentId) {
    return _mockAccounts.where((a) => a.parentId == parentId).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  bool _hasChildren(String id) => _mockAccounts.any((a) => a.parentId == id);

  void _expandAll() {
    setState(() {
      _expanded.addAll(_mockAccounts.where((a) => _hasChildren(a.id)).map((a) => a.id));
    });
  }

  void _collapseAll() {
    setState(() {
      _expanded.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgLight = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);

    final totalAccounts = _mockAccounts.length;
    final parentCount = _mockAccounts.where((a) => !a.allowPosting).length;
    final postingCount = _mockAccounts.where((a) => a.allowPosting).length;

    final filteredAccounts = _mockAccounts.where((a) {
      final matchesSearch = _search.isEmpty ||
          a.name.contains(_search) ||
          a.code.contains(_search);
      final matchesType = _selectedTypeFilter == 'all' || a.type == _selectedTypeFilter;
      return matchesSearch && matchesType;
    }).toList();

    final roots = _search.isEmpty && _selectedTypeFilter == 'all'
        ? _children(null)
        : filteredAccounts;

    return Column(
      children: [
        // ── Ultra-Compact Combined Header & Toolbar Banner ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              // Row 1: Title + Micro Stat Chip + Expand/Collapse + Add Account Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.account_tree_outlined,
                      color: Color(0xFF6366F1),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'دليل الحسابات',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Micro Stats Chip
                  Tooltip(
                    message: '$totalAccounts حساب ($parentCount رئيسي • $postingCount فرعي)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '$totalAccounts حساب',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Expand & Collapse Icon Buttons
                  InkWell(
                    onTap: _expandAll,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Icons.unfold_more_rounded, size: 14, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _collapseAll,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(Icons.unfold_less_rounded, size: 14, color: textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Add Account Button
                  ElevatedButton.icon(
                    onPressed: () {
                      AccountFormSheet.show(
                        context,
                        parentAccounts: _mockAccounts
                            .where((a) => !a.allowPosting)
                            .map((a) => {'id': a.id, 'code': a.code, 'name': a.name})
                            .toList(),
                        onSave: (data) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم إضافة الحساب: ${data['name']}')),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 13, color: Colors.white),
                    label: const Text('إضافة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Compact Search Bar & Type Filter Chips
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: TextStyle(fontSize: 11, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'بحث بالأسم أو الرمز...',
                          hintStyle: TextStyle(color: textSecondary, fontSize: 10),
                          prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 14),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 12),
                                  onPressed: () => setState(() => _search = ''),
                                  padding: EdgeInsets.zero,
                                )
                              : null,
                          filled: true,
                          fillColor: bgLight,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'الكل', Colors.indigo, isDark),
                          _buildFilterChip('Asset', 'أصول', const Color(0xFF3B82F6), isDark),
                          _buildFilterChip('Liability', 'خصوم', const Color(0xFFEF4444), isDark),
                          _buildFilterChip('Equity', 'ملكية', const Color(0xFF8B5CF6), isDark),
                          _buildFilterChip('Revenue', 'إيرادات', const Color(0xFF10B981), isDark),
                          _buildFilterChip('Expense', 'مصروفات', const Color(0xFFF59E0B), isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Optimized Column Headers Bar (Matching Data Columns) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bgLight,
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 32),
              SizedBox(
                width: 50,
                child: Text(
                  'الرمز',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  'اسم الحساب (Account Title)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  'النوع',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 40,
                child: Text(
                  'الحالة',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 34,
                child: Text(
                  'إجراء',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // ── Main Accounts Tree List Area (Fills 90%+ of Vertical Space) ──
        Expanded(
          child: Container(
            color: bgLight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                children: [
                  ...(_search.isEmpty && _selectedTypeFilter == 'all'
                          ? roots
                          : filteredAccounts)
                      .map((acc) => (_search.isEmpty && _selectedTypeFilter == 'all')
                          ? _buildAccountNode(context, acc, 0, borderColor, textPrimary, textSecondary, surface, bgLight)
                          : _buildAccountRow(context, acc, 0, borderColor, textPrimary, textSecondary, surface, bgLight)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, Color color, bool isDark) {
    final isSelected = _selectedTypeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedTypeFilter = key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? color : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountNode(
    BuildContext context,
    _MockAccount account,
    int depth,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color surface,
    Color bgLight,
  ) {
    final hasKids = _hasChildren(account.id);
    final isExpanded = _expanded.contains(account.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountRow(context, account, depth, borderColor, textPrimary, textSecondary, surface, bgLight),
        if (hasKids && isExpanded)
          ..._children(account.id).map(
            (child) => _buildAccountNode(
              context,
              child,
              depth + 1,
              borderColor,
              textPrimary,
              textSecondary,
              surface,
              bgLight,
            ),
          ),
      ],
    );
  }

  Widget _buildAccountRow(
    BuildContext context,
    _MockAccount account,
    int depth,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    Color surface,
    Color bgLight,
  ) {
    final hasKids = _hasChildren(account.id);
    final isExpanded = _expanded.contains(account.id);
    final color = _typeColor(account.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: hasKids
            ? () => setState(() {
                  if (_expanded.contains(account.id)) {
                    _expanded.remove(account.id);
                  } else {
                    _expanded.add(account.id);
                  }
                })
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: depth == 0 ? color.withValues(alpha: 0.3) : borderColor,
              width: depth == 0 ? 1.2 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            children: [
              // Tree Indentation & Connector Lines
              SizedBox(
                width: 32.0 + (depth * 8.0),
                child: Row(
                  children: [
                    if (depth > 0)
                      Container(
                        width: 1.5,
                        height: 14,
                        margin: const EdgeInsets.only(right: 2, left: 2),
                        color: color.withValues(alpha: 0.4),
                      ),
                    if (hasKids)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_left_rounded,
                        size: 15,
                        color: color,
                      )
                    else
                      const SizedBox(width: 15),
                    Icon(
                      account.allowPosting
                          ? Icons.description_outlined
                          : Icons.folder_rounded,
                      size: 14,
                      color: color,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Account Code Chip
              SizedBox(
                width: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    account.code,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Account Title (EXPANDED TO MAXIMUM WIDTH!)
              Expanded(
                child: Text(
                  account.name,
                  style: TextStyle(
                    fontWeight: account.allowPosting
                        ? FontWeight.w600
                        : FontWeight.w900,
                    fontSize: 12,
                    color: textPrimary,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 4),

              // Account Type Badge (Ultra-Compact Column)
              SizedBox(
                width: 42,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _typeLabelAr(account.type),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Account Posting Type Badge (رئيسي vs فرعي - Ultra Compact)
              SizedBox(
                width: 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  decoration: BoxDecoration(
                    color: account.allowPosting
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    account.allowPosting ? 'فرعي' : 'رئيسي',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: account.allowPosting ? const Color(0xFF047857) : Colors.indigo.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Actions (Shield, Edit - Ultra Compact)
              SizedBox(
                width: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'حساب محمي',
                      child: Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        AccountFormSheet.show(
                          context,
                          parentAccounts: _mockAccounts
                              .where((a) => !a.allowPosting)
                              .map((a) => {'id': a.id, 'code': a.code, 'name': a.name})
                              .toList(),
                          account: {
                            'id': account.id,
                            'code': account.code,
                            'name': account.name,
                            'type': account.type,
                            'parentId': account.parentId,
                            'allowPosting': account.allowPosting,
                          },
                          onSave: (data) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم تعديل الحساب: ${data['name']}')),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Icon(Icons.edit_outlined, size: 13, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 3: Journal Entries ────────────────────────────────────────────────────

class JournalEntriesTab extends StatefulWidget {
  const JournalEntriesTab({super.key});

  @override
  State<JournalEntriesTab> createState() => _JournalEntriesTabState();
}

class _JournalEntriesTabState extends State<JournalEntriesTab> {
  String _search = '';
  String _filterType = 'all';

  static const _filterTabs = [
    _FilterTab(key: 'all', label: 'الكل'),
    _FilterTab(key: 'SalesInvoice', label: 'مبيعات'),
    _FilterTab(key: 'PurchaseInvoice', label: 'مشتريات'),
    _FilterTab(key: 'Payment', label: 'سندات'),
    _FilterTab(key: 'Manual', label: 'يدوي'),
  ];

  static const _refConfig = {
    'SalesInvoice':    _RefConfig(icon: Icons.shopping_cart_outlined, color: Color(0xFF3B82F6), label: 'فاتورة مبيعات'),
    'SalesReturn':     _RefConfig(icon: Icons.undo_rounded, color: Color(0xFFF59E0B), label: 'مرتجع مبيعات'),
    'PurchaseInvoice': _RefConfig(icon: Icons.inventory_2_outlined, color: Color(0xFF8B5CF6), label: 'فاتورة مشتريات'),
    'PurchaseReturn':  _RefConfig(icon: Icons.undo_rounded, color: Color(0xFFEF4444), label: 'مرتجع مشتريات'),
    'Payment':         _RefConfig(icon: Icons.north_east_rounded, color: Color(0xFF10B981), label: 'سند مالي'),
    'Expense':         _RefConfig(icon: Icons.south_west_rounded, color: Color(0xFFEF4444), label: 'مصروف'),
    'Manual':          _RefConfig(icon: Icons.description_outlined, color: Color(0xFF64748B), label: 'قيد يدوي'),
    'Income':          _RefConfig(icon: Icons.north_east_rounded, color: Color(0xFF10B981), label: 'إيراد'),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgSurface = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    final totalPosted = _mockJournalEntries.where((e) => e.status == 'Posted').length;
    final totalUnbalanced = _mockJournalEntries.where((e) => !e.isBalanced).length;
    final grandDebit = _mockJournalEntries.fold(0, (a, e) => a + e.totalDebit);

    final filtered = _mockJournalEntries.where((e) {
      final matchType = _filterType == 'all' || e.refType == _filterType;
      final matchSearch = _search.isEmpty ||
          e.number.toLowerCase().contains(_search.toLowerCase()) ||
          e.description.toLowerCase().contains(_search.toLowerCase());
      return matchType && matchSearch;
    }).toList();

    return Column(
      children: [
        // ── Header ──
        Container(
          color: surface,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // KPI row (scrollable horizontally)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _JournalKpi(label: 'إجمالي القيود', value: '${_mockJournalEntries.length}', unit: 'قيد', color: const Color(0xFF3B82F6), icon: Icons.description_outlined),
                    const SizedBox(width: 10),
                    _JournalKpi(label: 'مُرحَّل', value: '$totalPosted', unit: 'قيد', color: const Color(0xFF10B981), icon: Icons.check_circle_outline_rounded),
                    const SizedBox(width: 10),
                    _JournalKpi(label: 'المدين الكلي', value: _formatNum(grandDebit), unit: 'ر.ي', color: const Color(0xFF8B5CF6), icon: Icons.balance_rounded),
                    const SizedBox(width: 10),
                    _JournalKpi(
                      label: 'غير متوازن',
                      value: '$totalUnbalanced',
                      unit: 'قيد',
                      color: totalUnbalanced > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              AppSearchFilterBar(
                searchHint: 'ابحث برقم القيد أو البيان...',
                padding: EdgeInsets.zero,
                onSearchChanged: (v) => setState(() => _search = v),
                selectedFilterValue: _filterType,
                onFilterSelected: (v) => setState(() => _filterType = v),
                filterChips: _filterTabs
                    .map((ft) => AppFilterChipData(label: ft.label, value: ft.key))
                    .toList(),
                trailingAction: _ActionButton(
                  label: '+ قيد يدوي',
                  color: const Color(0xFF10B981),
                  textColor: Colors.white,
                  onTap: () {
                    JournalEntryFormSheet.show(
                      context,
                      onSave: (entry, lines) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إضافة القيد اليومي بنجاح')),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // ── Entry Card List (Mobile adapted) ──
        Expanded(
          child: Container(
            color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد قيود مطابقة',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      final conf = _refConfig[entry.refType] ?? _refConfig['Manual']!;
                      return InkWell(
                        onTap: () {
                          JournalEntryDetailsSheet.show(
                            context,
                            entry: {
                              'id': entry.id,
                              'number': entry.number,
                              'date': '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
                              'notes': entry.description,
                              'status': entry.status,
                            },
                            lines: [
                              {
                                'account_name': '1101 - الصندوق الرئيسي',
                                'description': entry.description,
                                'debit': entry.totalDebit.toDouble(),
                                'credit': 0,
                              },
                              {
                                'account_name': '4100 - إيرادات المبيعات',
                                'description': entry.description,
                                'debit': 0,
                                'credit': entry.totalDebit.toDouble(),
                              },
                            ],
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: conf.color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(conf.icon, size: 14, color: conf.color),
                                            const SizedBox(width: 4),
                                            Text(
                                              conf.label,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: conf.color),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          entry.number,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        entry.status == 'Posted' ? 'مُرحَّل' : 'مسودة',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              entry.description,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'التاريخ: ${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'الأسطر: 2',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_formatNum(entry.totalDebit)} ر.ي',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  static String _formatNum(int n) {
    return n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _FilterTab {
  final String key;
  final String label;
  const _FilterTab({required this.key, required this.label});
}

class _RefConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _RefConfig({required this.icon, required this.color, required this.label});
}

// ─── Tab 4: Reports ────────────────────────────────────────────────────────────

class FinancialReportsTab extends StatefulWidget {
  const FinancialReportsTab({super.key});

  @override
  State<FinancialReportsTab> createState() => _FinancialReportsTabState();
}

class _FinancialReportsTabState extends State<FinancialReportsTab> {
  String? _selectedCategoryId;
  String _selectedSubReportId = 'sales_summary';

  final List<Map<String, dynamic>> _categories = const [
    {
      'id': 'sales',
      'title': 'تقارير المبيعات',
      'countText': '3 تقارير فرعية',
      'description': 'تحليل المبيعات اليومية، والمنتجات الأكثر مبيعاً.',
      'icon': Icons.show_chart_rounded,
      'color': Color(0xFF3B82F6),
      'subReports': [
        {'id': 'sales_summary', 'label': 'ملخص المبيعات'},
        {'id': 'top_products', 'label': 'المنتجات الأكثر مبيعاً'},
        {'id': 'sales_by_branch', 'label': 'المبيعات حسب الفرع'},
      ],
    },
    {
      'id': 'inventory',
      'title': 'تقارير المخزون',
      'countText': '4 تقارير فرعية',
      'description': 'حركة المخزون، تقييم البضاعة، والنواقص.',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFFF59E0B),
      'subReports': [
        {'id': 'stock_balance', 'label': 'أرصدة المخزون'},
        {'id': 'inventory_valuation', 'label': 'تقييم المخزون'},
        {'id': 'stock_movement', 'label': 'حركة المخزون'},
        {'id': 'stock_adjustments', 'label': 'فروقات الجرد'},
      ],
    },
    {
      'id': 'finance',
      'title': 'التقارير المالية',
      'countText': '3 تقارير فرعية',
      'description': 'حركة الخزينة، الأرباح والخسائر، وكشف حساب.',
      'icon': Icons.attach_money_rounded,
      'color': Color(0xFF10B981),
      'subReports': [
        {'id': 'cash_flow', 'label': 'حركة الخزينة'},
        {'id': 'profit_loss', 'label': 'الأرباح والخسائر'},
        {'id': 'expense_summary', 'label': 'ملخص المصروفات'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final bgLight = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);

    if (_selectedCategoryId == null) {
      // ─── Overview Categories View ───────────────────────────────────────────────
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF8B5CF6), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('التقارير والتحليلات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('نظرة شاملة على أداء أعمالك', style: TextStyle(fontSize: 14, color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _categories.map((cat) {
                  final Color catColor = cat['color'] as Color;
                  return SizedBox(
                    width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = cat['id'] as String?;
                          _selectedSubReportId = ((cat['subReports'] as List)[0] as Map)['id'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(cat['icon'] as IconData?, color: catColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cat['title'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(cat['countText'] as String, style: TextStyle(fontSize: 13, color: textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              cat['description'] as String,
                              style: TextStyle(fontSize: 14, height: 1.4, color: textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('عرض التقارير', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: catColor)),
                                Icon(Icons.arrow_back_ios_rounded, color: catColor, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      );
    }

    // ─── Detailed Report Screen View ─────────────────────────────────────────────
    final currentCat = _categories.firstWhere((c) => c['id'] == _selectedCategoryId);
    final List<dynamic> subReports = currentCat['subReports'] as List<dynamic>;

    return Column(
      children: [
        // Category Header with Back Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: surface,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedCategoryId = null),
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: (currentCat['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(currentCat['icon'] as IconData?, color: currentCat['color'] as Color?, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentCat['title'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('نظرة شاملة على أداء أعمالك', style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),

        // Sub Reports Selector Pills
        Container(
          color: surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: subReports.map((sr) {
                final isSelected = sr['id'] == _selectedSubReportId;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(sr['label'] as String),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: bgLight,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : borderColor),
                    onSelected: (_) => setState(() => _selectedSubReportId = sr['id'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Divider(height: 1, color: borderColor),

        // Main Report Content Area
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMainReportBody(context, currentCat),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainReportBody(BuildContext context, Map<String, dynamic> currentCat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final catId = currentCat['id'];

    if (catId == 'inventory') {
      // ─── Inventory Report View (Screenshot 1) ──────────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تقرير تقييم وحركة المخزون', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('تحليل شامل لقيمة البضاعة والنواقص', style: TextStyle(fontSize: 14, color: textSecondary)),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFF59E0B), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterBar(context, borderColor),
          const SizedBox(height: 20),
          // KPI Grid for Inventory
          Row(
            children: [
              Expanded(child: _buildReportKpi(context, 'قيمة المخزون', '1,250,000', 'ر.ي', textPrimary)),
              const SizedBox(width: 10),
              Expanded(child: _buildReportKpi(context, 'عدد المنتجات', '8,500', '', textPrimary)),
              const SizedBox(width: 10),
              Expanded(child: _buildReportKpi(context, 'منخفض المخزون', '12', '', const Color(0xFFF59E0B))),
              const SizedBox(width: 10),
              Expanded(child: _buildReportKpi(context, 'غير متوفر', '3', '', const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory Charts & Alerts
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inventory Valuation by Category
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقييم المخزون حسب الفئة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                          const SizedBox(height: 20),
                          _buildCategoryProgress('إلكترونيات', '800,000 (64%)', 0.64, const Color(0xFFF59E0B), textPrimary, textSecondary),
                          const SizedBox(height: 16),
                          _buildCategoryProgress('إكسسوارات', '200,000 (16%)', 0.16, const Color(0xFFF59E0B), textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                  // Stock Shortage Alerts Table
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تنبيهات النواقص', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('المنتج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                              Row(
                                children: [
                                  Text('الرصيد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                  const SizedBox(width: 40),
                                  Text('الأدنى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('شاشة آيفون 13', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                                  ),
                                  const SizedBox(width: 40),
                                  Text('10', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    if (catId == 'finance') {
      // ─── Financial Report View (Screenshot 2) ──────────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تقرير الأرباح والخسائر وحركة الخزينة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('تحليل مالي متكامل وتدفقات نقدية', style: TextStyle(fontSize: 14, color: textSecondary)),
                ],
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_money_rounded, color: Color(0xFF10B981), size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterBar(context, borderColor),
          const SizedBox(height: 20),

          // Profit Bar Chart + Expense Breakdown Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profit Bar Chart (Green Gradient)
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الرسم البياني للأرباح', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildGreenBar('11-04', 120),
                                _buildGreenBar('11-03', 95),
                                _buildGreenBar('11-02', 65),
                                _buildGreenBar('11-01', 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isWide) const SizedBox(width: 16) else const SizedBox(height: 16),

                  // Expense Analysis (Red Progress Bars)
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تحليل المصروفات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                          const SizedBox(height: 16),
                          _buildCategoryProgress('رواتب', '40,000 (47%)', 0.47, const Color(0xFFEF4444), textPrimary, textSecondary),
                          const SizedBox(height: 12),
                          _buildCategoryProgress('إيجارات', '20,000 (24%)', 0.24, const Color(0xFFEF4444), textPrimary, textSecondary),
                          const SizedBox(height: 12),
                          _buildCategoryProgress('مرافق وخدمات', '15,000 (18%)', 0.18, const Color(0xFFEF4444), textPrimary, textSecondary),
                          const SizedBox(height: 12),
                          _buildCategoryProgress('نثريات', '10,000 (12%)', 0.12, const Color(0xFFEF4444), textPrimary, textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    // ─── Sales Report View (Default / Screenshot Sales) ─────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تقرير المبيعات الشامل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
                const SizedBox(height: 4),
                Text('تحليل مبيعات الفروع والمنتجات', style: TextStyle(fontSize: 14, color: textSecondary)),
              ],
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.show_chart_rounded, color: Color(0xFF3B82F6), size: 22),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFilterBar(context, borderColor),
        const SizedBox(height: 20),

        // KPI Cards
        Row(
          children: [
            Expanded(child: _buildReportKpi(context, 'إجمالي المبيعات', '45,000', 'ر.ي', const Color(0xFF2563EB))),
            const SizedBox(width: 10),
            Expanded(child: _buildReportKpi(context, 'عدد الفواتير', '120', '', textPrimary)),
            const SizedBox(width: 10),
            Expanded(child: _buildReportKpi(context, 'متوسط الفاتورة', '375', 'ر.ي', textPrimary)),
          ],
        ),
        const SizedBox(height: 16),

        // Highlights Row (Best Customer / Best Product)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أفضل عميل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'أحمد عبدالله',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أفضل منتج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لابتوب ديل XPS',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Visual Analytics Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تريند المبيعات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [40, 80, 60, 100, 75, 90, 110].map((h) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          height: h.toDouble(),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 20),
              Text('المبيعات حسب الفئة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
              const SizedBox(height: 16),
              _buildCategoryProgress('إلكترونيات', '25,000 (55%)', 0.55, const Color(0xFF2563EB), textPrimary, textSecondary),
              const SizedBox(height: 12),
              _buildCategoryProgress('إكسسوارات', '12,000 (27%)', 0.27, const Color(0xFF3B82F6), textPrimary, textSecondary),
              const SizedBox(height: 12),
              _buildCategoryProgress('قطع غيار', '8,000 (18%)', 0.18, const Color(0xFF60A5FA), textPrimary, textSecondary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreenBar(String label, double height) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF10B981), Color(0xFFA7F3D0)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterDropdown(context, 'اليوم', ['اليوم', 'أمس', 'هذا الأسبوع', 'هذا الشهر'])),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown(context, 'كل الفروع', ['كل الفروع', 'الفرع الرئيسي', 'فرع صنعاء'])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildFilterDropdown(context, 'كل المستودعات', ['كل المستودعات', 'المستودع الرئيسي'])),
              const SizedBox(width: 10),
              Expanded(child: _buildFilterDropdown(context, 'كل الموظفين', ['كل الموظفين', 'أحمد العمري'])),
            ],
          ),
          const SizedBox(height: 10),
          _buildFilterDropdown(context, 'كل الطرق', ['كل الطرق', 'نقداً', 'شبكة / آجل']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('تحديث', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                  label: const Text('تصدير', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, String value, List<String> options) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildReportKpi(BuildContext context, String title, String value, String unit, Color valColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textSecondary)),
          const SizedBox(height: 8),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valColor)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress(String name, String detail, double progress, Color color, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
            Text(detail, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}


// ─── Reusable Small Widgets ────────────────────────────────────────────────────

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label, required this.icon, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 140),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0), width: 1.5),
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
                fontSize: 15, fontWeight: FontWeight.w800,
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
    required this.title, required this.value, required this.gradient, required this.shadowColor,
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
                  width: 28, height: 28,
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
    required this.label, required this.color, required this.textColor, required this.onTap,
    this.icon, this.borderColor,
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

class _JournalKpi extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _JournalKpi({
    required this.label, required this.value, required this.unit,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minWidth: 125),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(unit,
                      style: TextStyle(
                          fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
