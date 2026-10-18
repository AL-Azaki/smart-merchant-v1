import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../treasury/presentation/dialogs/add_bank_or_cash_dialog.dart';
import '../../../treasury/presentation/dialogs/fund_transfer_dialog.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../providers/accounting_provider.dart';

/// شاشة إدارة الخزائن والصناديق والمحافظ والبنوك
/// تعرض الصناديق النقدية، المحافظ الإلكترونية اليمنية، الحسابات البنكية، والأرصدة الحية،
/// مع إمكانية التحويل المالي وإضافة حسابات جديدة مرتبطة آلياً بالدليل المحاسبي.
class BanksAndCashView extends ConsumerStatefulWidget {
  const BanksAndCashView({super.key});

  @override
  ConsumerState<BanksAndCashView> createState() => _BanksAndCashViewState();
}

class _BanksAndCashViewState extends ConsumerState<BanksAndCashView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatNum(double val) {
    return '${val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ر.ي';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgSurface = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);

    final cashRegistersAsync = ref.watch(cashRegistersStreamProvider);
    final bankAccountsAsync = ref.watch(bankAccountsStreamProvider);
    final coaAsync = ref.watch(chartOfAccountsNotifierProvider);
    final receiptsAsync = ref.watch(receiptVouchersStreamProvider);
    final paymentsAsync = ref.watch(paymentVouchersStreamProvider);
    final tbAsync = ref.watch(trialBalanceReportProvider());

    // Calculate real cash, wallet, and bank balances from Trial Balance under Code 111%
    double cashBalance = 0.0;
    double walletBalance = 0.0;
    double bankBalance = 0.0;
    final Map<String, double> accountBalances = {};

    tbAsync.whenData((tb) {
      for (final item in tb.items) {
        final net = item.netDebit - item.netCredit;
        accountBalances[item.accountId] = net;
        if (item.accountCode.startsWith('11101') ||
            item.accountName.contains('صندوق') ||
            item.accountName.contains('خزينة')) {
          cashBalance += net;
        } else if (item.accountCode.startsWith('11103') ||
            item.accountName.contains('محفظة') ||
            item.accountName.contains('جوال') ||
            item.accountName.contains('كاش')) {
          walletBalance += net;
        } else if (item.accountCode.startsWith('11102') ||
            item.accountName.contains('بنك') ||
            item.accountName.contains('مصرف')) {
          bankBalance += net;
        } else if (item.accountCode.startsWith('111')) {
          cashBalance += net;
        }
      }
    });

    final totalLiquidity = cashBalance + walletBalance + bankBalance;

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: const Text(
          'الخزينة والصناديق والمحافظ والبنوك',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'إضافة صندوق / محفظة / بنك',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddBankOrCashDialog(
                initialType: _tabController.index == 0
                    ? TreasuryItemType.cash
                    : (_tabController.index == 1
                        ? TreasuryItemType.wallet
                        : TreasuryItemType.bank),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text(
              'تحويل بين الصناديق',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const FundTransferDialog(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(cashRegistersStreamProvider);
              ref.invalidate(bankAccountsStreamProvider);
              ref.invalidate(chartOfAccountsNotifierProvider);
              ref.invalidate(receiptVouchersStreamProvider);
              ref.invalidate(paymentVouchersStreamProvider);
              ref.invalidate(trialBalanceReportProvider());
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── KPI Summary Cards ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isMedium = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : (isMedium ? 2 : 1),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 2.1 : (isMedium ? 2.4 : 2.8),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // إجمالي السيولة
                    _buildKpiCard(
                      title: 'إجمالي السيولة النقدية',
                      value: _formatNum(totalLiquidity),
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF10B981),
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    // رصيد الصناديق
                    _buildKpiCard(
                      title: 'رصيد الصناديق والخزائن',
                      value: _formatNum(cashBalance),
                      icon: Icons.point_of_sale_rounded,
                      color: const Color(0xFF06B6D4),
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    // رصيد المحافظ
                    _buildKpiCard(
                      title: 'رصيد المحافظ الإلكترونية',
                      value: _formatNum(walletBalance),
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF8B5CF6),
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    // رصيد البنوك
                    _buildKpiCard(
                      title: 'رصيد الحسابات البنكية',
                      value: _formatNum(bankBalance),
                      icon: Icons.account_balance_rounded,
                      color: const Color(0xFF3B82F6),
                      surface: surface,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Tab Bar (الصناديق vs المحافظ vs البنوك) ──
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 3,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: textSecondary,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.point_of_sale_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('الصناديق النقدية', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('المحافظ الإلكترونية', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('الحسابات البنكية', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab View Content ──
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Cash Registers
                  _buildCashRegistersList(
                    cashRegistersAsync,
                    coaAsync,
                    accountBalances,
                    isDark,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                  // Tab 2: Mobile Wallets
                  _buildWalletsList(
                    bankAccountsAsync,
                    coaAsync,
                    accountBalances,
                    isDark,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                  // Tab 3: Bank Accounts
                  _buildBankAccountsList(
                    bankAccountsAsync,
                    coaAsync,
                    accountBalances,
                    isDark,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── آخر حركات السندات النقدية ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر السندات المالية المقيدة بالخزينة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRecentVouchersList(
              receiptsAsync,
              paymentsAsync,
              surface,
              borderColor,
              textPrimary,
              textSecondary,
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashRegistersList(
    AsyncValue<List<CashRegister>> cashAsync,
    AsyncValue<List<ChartOfAccount>> coaAsync,
    Map<String, double> accountBalances,
    bool isDark,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return cashAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في جلب الصناديق: $e')),
      data: (registers) {
        if (registers.isEmpty) {
          final coaAccounts = coaAsync.value ?? [];
          final cashAccounts = coaAccounts
              .where((a) =>
                  a.accountCode.startsWith('11101') ||
                  a.accountName.contains('صندوق') ||
                  a.accountName.contains('خزينة'))
              .toList();

          if (cashAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale_rounded, size: 48, color: textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('لا توجد صناديق نقدية مسجلة حالياً', style: TextStyle(color: textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: cashAccounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final acc = cashAccounts[index];
              final bal = accountBalances[acc.id] ?? 0.0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF06B6D4), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc.accountName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                          Text('كود الحساب: ${acc.accountCode}', style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _formatNum(bal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.separated(
          itemCount: registers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final reg = registers[index];
            final bal = reg.currentBalance != 0.0 ? reg.currentBalance : (accountBalances[reg.id] ?? 0.0);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF06B6D4), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reg.registerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                        Text('صندوق نقدي - ${reg.currencyId}', style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _formatNum(bal),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (reg.status == 'Open' ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      reg.status == 'Open' ? 'مفتوح (نشط)' : 'مغلق',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: reg.status == 'Open' ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletsList(
    AsyncValue<List<BankAccount>> bankAsync,
    AsyncValue<List<ChartOfAccount>> coaAsync,
    Map<String, double> accountBalances,
    bool isDark,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return bankAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في جلب المحافظ الإلكترونية: $e')),
      data: (allBanks) {
        final wallets = allBanks.where((b) {
          if (b.description == 'WALLET') return true;
          final n = b.bankName.toLowerCase();
          final d = (b.displayName ?? '').toLowerCase();
          return n.contains('محفظة') ||
              n.contains('كريمي') ||
              n.contains('جيب') ||
              n.contains('كاش') ||
              n.contains('ون كاش') ||
              n.contains('فلوسك') ||
              d.contains('محفظة');
        }).toList();

        if (wallets.isEmpty) {
          final coaAccounts = coaAsync.value ?? [];
          final coaWallets = coaAccounts
              .where((a) =>
                  a.accountCode.startsWith('11103') ||
                  a.accountName.contains('محفظة') ||
                  a.accountName.contains('جوال'))
              .toList();

          if (coaWallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 48, color: textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('لا توجد محافظ إلكترونية مسجلة حالياً', style: TextStyle(color: textSecondary)),
                  const SizedBox(height: 8),
                  Text('يمكنك إضافة محفظة كريمي، كاش، جيب، ون كاش، فلوسك...', style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: coaWallets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final acc = coaWallets[index];
              final bal = accountBalances[acc.id] ?? 0.0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8B5CF6), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc.accountName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                          Text('كود الحساب: ${acc.accountCode}', style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _formatNum(bal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.separated(
          itemCount: wallets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final w = wallets[index];
            final bal = w.currentBalance != 0.0 ? w.currentBalance : (accountBalances[w.id] ?? 0.0);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.displayName ?? w.bankName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                        ),
                        Text(
                          '${w.bankName} • رقم الهاتف / الحساب: ${w.accountNumber} (${w.currencyId})',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatNum(bal),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (w.status == 'Active' ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w.status == 'Active' ? 'نشط' : 'معطل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: w.status == 'Active' ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBankAccountsList(
    AsyncValue<List<BankAccount>> bankAsync,
    AsyncValue<List<ChartOfAccount>> coaAsync,
    Map<String, double> accountBalances,
    bool isDark,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return bankAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ في جلب الحسابات البنكية: $e')),
      data: (allBanks) {
        final banks = allBanks.where((b) {
          if (b.description == 'WALLET') return false;
          final n = b.bankName.toLowerCase();
          final d = (b.displayName ?? '').toLowerCase();
          if (n.contains('محفظة') || d.contains('محفظة')) return false;
          return true;
        }).toList();

        if (banks.isEmpty) {
          final coaAccounts = coaAsync.value ?? [];
          final bankAccounts = coaAccounts
              .where((a) =>
                  a.accountCode.startsWith('11102') ||
                  a.accountName.contains('بنك') ||
                  a.accountName.contains('مصرف'))
              .toList();

          if (bankAccounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_rounded, size: 48, color: textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('لا توجد حسابات بنكية مسجلة حالياً', style: TextStyle(color: textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: bankAccounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final acc = bankAccounts[index];
              final bal = accountBalances[acc.id] ?? 0.0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3B82F6), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(acc.accountName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                          Text('كود الحساب: ${acc.accountCode}', style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _formatNum(bal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF3B82F6)),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.separated(
          itemCount: banks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final b = banks[index];
            final bal = b.currentBalance != 0.0 ? b.currentBalance : (accountBalances[b.id] ?? 0.0);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.bankName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                        Text('رقم الحساب: ${b.accountNumber} (${b.currencyId})', style: TextStyle(fontSize: 12, color: textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    _formatNum(bal),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (b.status == 'Active' ? const Color(0xFF10B981) : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      b.status == 'Active' ? 'نشط' : 'معطل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: b.status == 'Active' ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentVouchersList(
    AsyncValue<List<Payment>> receiptsAsync,
    AsyncValue<List<Payment>> paymentsAsync,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final receipts = receiptsAsync.value ?? [];
    final payments = paymentsAsync.value ?? [];

    final combined = <Payment>[...receipts, ...payments]
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final recent = combined.take(5).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text('لا توجد سندات مقيدة في الخزينة بعد.', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
        itemBuilder: (context, index) {
          final p = recent[index];
          final isReceipt = p.paymentType == 'Receipt';
          final color = isReceipt ? const Color(0xFF10B981) : const Color(0xFFEF4444);

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isReceipt ? Icons.north_east_rounded : Icons.south_west_rounded,
                color: color,
                size: 18,
              ),
            ),
            title: Text(
              isReceipt ? 'سند قبض #${p.id.substring(0, 8)}' : 'سند صرف #${p.id.substring(0, 8)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
            ),
            subtitle: Text(
              '${p.paymentMethodId} • ${(p.createdAt ?? p.paymentDate).toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            trailing: Text(
              '${isReceipt ? '+' : '-'}${p.amount.toStringAsFixed(2)} ${p.currencyId}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color),
            ),
          );
        },
      ),
    );
  }
}
