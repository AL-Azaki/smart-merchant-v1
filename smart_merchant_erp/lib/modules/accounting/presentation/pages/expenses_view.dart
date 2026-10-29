import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../providers/accounting_provider.dart';
import '../widgets/create_expense_dialog.dart';
import '../widgets/voucher_details_dialog.dart';
import 'expenses_analysis_view.dart';

class ExpensesView extends ConsumerStatefulWidget {
  const ExpensesView({super.key});

  @override
  ConsumerState<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends ConsumerState<ExpensesView> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _selectedFilterIndex = 0; // 0: الكل, 1: اليوم, 2: هذا الشهر, 3: مسحوبات شخصية

  Map<String, String> _accountNames = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final db = getIt<AppDatabase>();
      final coa = await db.select(db.chartOfAccounts).get();
      final map = <String, String>{};
      for (final a in coa) {
        map[a.id] = a.accountName;
      }
      if (mounted) {
        setState(() => _accountNames = map);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return val.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isExpenseOrDrawings(Payment p) {
    return p.contactType != 'Supplier' && (p.contactType == 'Other' || p.contactId == null);
  }

  bool _isDrawings(Payment p) {
    final note = p.notes?.toLowerCase() ?? '';
    final name = (_accountNames[p.chartOfAccountId] ?? '').toLowerCase();
    return note.contains('صرفة') ||
        note.contains('شخصية') ||
        note.contains('مسحوبات') ||
        name.contains('مسحوبات');
  }

  Future<void> _openCreateExpenseDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateExpenseDialog(),
    );
    if (created == true) {
      ref.invalidate(paymentVouchersStreamProvider);
      ref.invalidate(trialBalanceReportProvider());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final vouchersAsync = ref.watch(paymentVouchersStreamProvider);
    final tbAsync = ref.watch(trialBalanceReportProvider());
    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);
    final now = DateTime.now();

    // Calculate total available in cashboxes
    double totalCashAvailable = 0.0;
    final availableAccounts = accountsAsync.asData?.value ?? [];
    final cashAccounts = availableAccounts
        .where((a) => a.allowPosting && (a.accountCode.startsWith('111') || a.accountTypeId == 1))
        .map((a) => a.id)
        .toSet();

    tbAsync.whenData((tb) {
      for (final item in tb.items) {
        if (cashAccounts.contains(item.accountId)) {
          totalCashAvailable += (item.netDebit - item.netCredit);
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'تسجيل مصروف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _openCreateExpenseDialog,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          return CustomScrollView(
            slivers: [
              // ── 1. Header (Adaptive & Responsive) ──
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF97316).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    color: Color(0xFFF97316),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'إدارة المصروفات والصرفيات',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton.filledTonal(
                                  tooltip: 'المخطط الدائري والتحليلات',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                    foregroundColor: const Color(0xFF6366F1),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const ExpensesAnalysisView(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.pie_chart_rounded, size: 18),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payments_rounded,
                                color: Color(0xFFF97316),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إدارة المصروفات والصرفيات',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'تسجيل الصرف من الصناديق (كهرباء، إيجار، صرفة شخصية للمالك)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Analytics Pie Chart Button
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                foregroundColor: const Color(0xFF6366F1),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ExpensesAnalysisView(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.pie_chart_rounded, size: 18),
                              label: const Text('المخطط الدائري والتحليلات',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                ),
              ),

              // ── 2. KPI Cards Bar (Horizontally scrollable on small screens) ──
              SliverToBoxAdapter(
                child: vouchersAsync.maybeWhen(
                  data: (allVouchers) {
                    final expenseVouchers = allVouchers.where(_isExpenseOrDrawings).toList();

                    final todayTotal = expenseVouchers
                        .where((v) => _isSameDay(v.paymentDate, now))
                        .fold(0.0, (sum, v) => sum + v.amount);

                    final monthTotal = expenseVouchers
                        .where((v) => v.paymentDate.year == now.year && v.paymentDate.month == now.month)
                        .fold(0.0, (sum, v) => sum + v.amount);

                    final drawingsTotal = expenseVouchers
                        .where(_isDrawings)
                        .fold(0.0, (sum, v) => sum + v.amount);

                    final cards = [
                      _buildKpiCard(
                        title: 'مصروفات اليوم',
                        value: '${_formatAmount(todayTotal)} ر.ي',
                        icon: Icons.today_rounded,
                        color: const Color(0xFFEF4444),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildKpiCard(
                        title: 'مصروفات هذا الشهر',
                        value: '${_formatAmount(monthTotal)} ر.ي',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFFF97316),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildKpiCard(
                        title: 'صرفة شخصية للمالك (مسحوبات)',
                        value: '${_formatAmount(drawingsTotal)} ر.ي',
                        icon: Icons.person_rounded,
                        color: const Color(0xFFF59E0B),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      _buildKpiCard(
                        title: 'رصيد الصناديق المتوفر',
                        value: '${_formatAmount(totalCashAvailable)} ر.ي',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF10B981),
                        surface: surface,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ];

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151722) : const Color(0xFFF1F5F9),
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: cards.map((c) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: SizedBox(
                                width: isCompact ? 200 : 230,
                                child: c,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),

              // ── 3. Filters & Search Bar (Responsive) ──
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: surface,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'بحث بالرقم أو البيان أو الحساب...',
                                hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                suffixIcon: _search.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _search = '');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (val) => setState(() => _search = val.trim()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Filter Chips Horizontally Scrollable
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('الكل', 0),
                            const SizedBox(width: 6),
                            _buildFilterChip('اليوم', 1),
                            const SizedBox(width: 6),
                            _buildFilterChip('هذا الشهر', 2),
                            const SizedBox(width: 6),
                            _buildFilterChip('مسحوبات المالك 👤', 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1),
              ),

              // ── 4. Expenses List (SliverList for infinite smooth scrolling without overflow) ──
              vouchersAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('حدث خطأ أثناء تحميل المصروفات: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
                data: (allVouchers) {
                  // Filter only expenses & drawings
                  List<Payment> items = allVouchers.where(_isExpenseOrDrawings).toList();

                  // Apply quick filter
                  if (_selectedFilterIndex == 1) {
                    items = items.where((v) => _isSameDay(v.paymentDate, now)).toList();
                  } else if (_selectedFilterIndex == 2) {
                    items = items
                        .where((v) => v.paymentDate.year == now.year && v.paymentDate.month == now.month)
                        .toList();
                  } else if (_selectedFilterIndex == 3) {
                    items = items.where(_isDrawings).toList();
                  }

                  // Apply search
                  if (_search.isNotEmpty) {
                    items = items.where((v) {
                      final note = v.notes?.toLowerCase() ?? '';
                      final num = v.paymentNumber.toLowerCase();
                      final acc = (_accountNames[v.chartOfAccountId] ?? '').toLowerCase();
                      final q = _search.toLowerCase();
                      return note.contains(q) || num.contains(q) || acc.contains(q);
                    }).toList();
                  }

                  // Sort descending by date
                  items.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  size: 56, color: textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد مصروفات مسجلة في هذه الفترة',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold, color: textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'استخدم زر "تسجيل مصروف" بالأسفل للصرف من الصناديق',
                                style: TextStyle(
                                    fontSize: 11, color: textSecondary.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          final isDrawing = _isDrawings(item);
                          final sourceAccountName =
                              _accountNames[item.chartOfAccountId] ?? 'الصندوق الرئيسي';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDrawing
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDrawing ? Icons.person_rounded : Icons.payments_rounded,
                                  color: isDrawing
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    item.paymentNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDrawing
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                          : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      isDrawing ? 'صرفة شخصية' : 'مصروف',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDrawing
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today_rounded,
                                            size: 11, color: textSecondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${item.paymentDate.year}-${item.paymentDate.month.toString().padLeft(2, '0')}-${item.paymentDate.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.account_balance_wallet_rounded,
                                            size: 11, color: textSecondary),
                                        const SizedBox(width: 3),
                                        Text(
                                          'من: $sourceAccountName',
                                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                    if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                                      Text(
                                        'البيان: ${item.notes}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            color: textPrimary.withValues(alpha: 0.8)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_formatAmount(item.amount)} ر.ي',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      Text(
                                        item.paymentMethodId,
                                        style: TextStyle(fontSize: 9.5, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'تفاصيل السند والقيد',
                                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => VoucherDetailsDialog(
                                          voucher: item,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedFilterIndex = index);
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color surface,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
