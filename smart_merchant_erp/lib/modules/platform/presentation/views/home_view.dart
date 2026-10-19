import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../kernel/storage/app_database.dart' show SalesInvoice;
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../accounting/presentation/widgets/payment_voucher_dialog.dart';
import '../../../accounting/presentation/widgets/receipt_voucher_dialog.dart';
import '../../../purchasing/presentation/providers/purchasing_provider.dart';
import '../../../purchasing/presentation/widgets/purchase_invoice_modal.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _selectedFilterIndex = 0; // 0: اليوم, 1: أسبوع, 2: الشهر, 3: السنة, 4: تاريخ محدد
  DateTimeRange? _customDateRange;

  final List<String> _filterTabs = ['اليوم', 'أسبوع', 'الشهر', 'السنة', 'تاريخ محدد'];

  static const List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _getArabicDate() {
    final now = DateTime.now();
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final dayName = days[now.weekday - 1];
    final monthName = _arabicMonths[now.month - 1];
    return '$dayName، ${now.day} $monthName ${now.year}';
  }

  DateTimeRange _getCurrentDateRange() {
    final now = DateTime.now();
    switch (_selectedFilterIndex) {
      case 0: // اليوم
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case 1: // أسبوع (آخر 7 أيام)
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case 2: // الشهر
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case 3: // السنة
        final start = DateTime(now.year);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      case 4: // تاريخ محدد
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return DateTimeRange(
            start: DateTime(s.year, s.month, s.day),
            end: DateTime(e.year, e.month, e.day, 23, 59, 59, 999),
          );
        }
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      default:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
    }
  }

  String _getFilterSubtitle(DateTimeRange range) {
    final now = DateTime.now();
    switch (_selectedFilterIndex) {
      case 0:
        return _getArabicDate();
      case 1:
        return 'آخر 7 أيام (${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month})';
      case 2:
        return 'شهر ${_arabicMonths[now.month - 1]} ${now.year}';
      case 3:
        return 'سنة ${now.year}';
      case 4:
        return 'من ${range.start.day}/${range.start.month}/${range.start.year} إلى ${range.end.day}/${range.end.month}/${range.end.year}';
      default:
        return _getArabicDate();
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context, bool isDark) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilterIndex = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Active Date Filter Range
    final activeRange = _getCurrentDateRange();
    final filterSubtitle = _getFilterSubtitle(activeRange);

    // 1. Sales Invoices
    final salesInvoicesAsync = ref.watch(salesInvoicesNotifierProvider);
    final allSales = salesInvoicesAsync.value ?? [];

    // Filter sales within the active period
    final periodSales = allSales.where((inv) {
      return inv.status != 'Cancelled' &&
          !inv.invoiceDate.isBefore(activeRange.start) &&
          !inv.invoiceDate.isAfter(activeRange.end);
    }).toList();

    final double salesValue = periodSales.fold(0.0, (sum, inv) => sum + inv.grandTotal);

    // 2. Expenses (Payment Vouchers within the active period)
    final payments = ref.watch(paymentVouchersStreamProvider).value ?? [];
    final periodPayments = payments.where((p) {
      return !p.paymentDate.isBefore(activeRange.start) &&
          !p.paymentDate.isAfter(activeRange.end);
    }).toList();
    final double expensesValue = periodPayments.fold(0.0, (sum, p) => sum + p.amount);

    // 3. Profits (Sales - Expenses)
    final double profitValue = (salesValue - expensesValue) > 0 ? (salesValue - expensesValue) : 0.0;

    // 4. Supplier Dues (Real Unpaid / Partial Active Purchase Invoices)
    final purchaseInvoicesAsync = ref.watch(purchaseInvoicesNotifierProvider);
    final allPurchases = purchaseInvoicesAsync.value ?? [];
    final double suppliersValue = allPurchases
        .where((p) => p.status != 'Cancelled' && p.paymentStatus.toLowerCase() != 'paid')
        .fold(0.0, (sum, p) => sum + p.grandTotal);

    // 5. Customer Debts (Real Unpaid / Partial Active Sales Invoices)
    final double customersDebtValue = allSales
        .where((inv) => inv.status != 'Cancelled' && inv.paymentStatus.toLowerCase() != 'paid')
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);

    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Time Filter Tabs Bar (اليوم - أسبوع - الشهر - السنة - تاريخ محدد)
            _buildTimeFilterBar(isDark),
            const SizedBox(height: 16),

            // 2. Performance Overview Header ("نظرة عامة على الأداء")
            _buildSectionHeader(
              title: 'نظرة عامة على الأداء',
              subtitle: filterSubtitle,
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF6366F1),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // 3. KPI Cards (المبيعات، المصروفات، الأرباح، مستحقات الموردين)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'المبيعات',
                    value: '${_formatAmount(salesValue)} ر.ي',
                    icon: Icons.shopping_cart_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                    borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
                    isIncrease: salesValue > 0 ? true : null,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'المصروفات',
                    value: '${_formatAmount(expensesValue)} ر.ي',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFFEF4444),
                    bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
                    borderColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
                    isIncrease: expensesValue > 0 ? false : null,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'الأرباح',
                    value: '${_formatAmount(profitValue)} ر.ي',
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                    borderColor: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
                    isIncrease: profitValue > 0 ? true : null,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'مستحقات الموردين',
                    value: '${_formatAmount(suppliersValue)} ر.ي',
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB),
                    borderColor: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                    isIncrease: null,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Customer Debts Full Width Banner ("ديون العملاء")
            _buildCustomerDebtBanner(
              debtAmount: '${_formatAmount(customersDebtValue)} ر.ي',
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // 5. Sales Chart ("المبيعات خلال الأيام الماضية")
            _buildSalesChartCard(allSales, isDark, cardBg, textColor),
            const SizedBox(height: 20),

            // 6. Quick Actions Section ("العمليات السريعة")
            _buildSectionHeader(
              title: 'العمليات السريعة',
              subtitle: null,
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFF6366F1),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // 4 Action Buttons in a Single Row
            _buildQuickActionButtons(context, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // 1. شريط فلاتر الفترة الزمنية
  Widget _buildTimeFilterBar(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filterTabs.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          final title = _filterTabs[index];
          final isCustomDate = index == 4;

          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (isCustomDate) {
                  _pickCustomDateRange(context, isDark);
                } else {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustomDate) ...[
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // عناوين الأقسام
  Widget _buildSectionHeader({
    required String title,
    required String? subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // بطاقة KPI
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required bool? isIncrease,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isIncrease != null)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isIncrease
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncrease ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                    size: 14,
                    color: isIncrease ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                )
              else
                const SizedBox(width: 22),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بانر ديون العملاء
  Widget _buildCustomerDebtBanner({
    required String debtAmount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ديون العملاء',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
              ),
              const SizedBox(height: 2),
              Text(
                debtAmount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  // 5. بطاقة الرسم البياني للمبيعات الحقيقية
  Widget _buildSalesChartCard(List<SalesInvoice> allSales, bool isDark, Color cardBg, Color textColor) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> barsData = [];
    double maxVal = 0.0;

    for (int i = 5; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayLabel = '${day.day}/${day.month}';
      final daySales = allSales.where((inv) {
        return inv.status != 'Cancelled' &&
            inv.invoiceDate.year == day.year &&
            inv.invoiceDate.month == day.month &&
            inv.invoiceDate.day == day.day;
      }).fold(0.0, (sum, inv) => sum + inv.grandTotal);

      if (daySales > maxVal) {
        maxVal = daySales;
      }

      barsData.add({
        'date': dayLabel,
        'val': daySales,
        'isToday': i == 0,
      });
    }

    final double effectiveMax = maxVal > 0 ? maxVal : 10000.0;
    final String yLabelTop = _formatAmount(effectiveMax);
    final String yLabelMid2 = _formatAmount(effectiveMax * 0.66);
    final String yLabelMid1 = _formatAmount(effectiveMax * 0.33);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'المبيعات خلال الأيام الماضية',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              if (maxVal > 0)
                Text(
                  'الأعلى: ${_formatAmount(maxVal)} ر.ي',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // الرسم البياني بالأعمدة
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // مقياس المحور الرأسي Y
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(yLabelTop, style: TextStyle(fontSize: 8.5, color: Colors.grey[500])),
                    Text(yLabelMid2, style: TextStyle(fontSize: 8.5, color: Colors.grey[500])),
                    Text(yLabelMid1, style: TextStyle(fontSize: 8.5, color: Colors.grey[500])),
                    Text('0', style: TextStyle(fontSize: 8.5, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(width: 8),

                // الأعمدة
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: barsData.map((data) {
                      final val = data['val'] as double;
                      final isHighest = maxVal > 0 && val == maxVal;
                      final ratio = (val / effectiveMax).clamp(0.0, 1.0);
                      final barHeight = (120 * ratio).clamp(val > 0 ? 8.0 : 4.0, 120.0);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isHighest)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4338CA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_formatAmount(val)} ر.ي',
                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const SizedBox(height: 18),
                          Container(
                            width: 24,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: val > 0 ? const Color(0xFF6366F1) : (isDark ? Colors.grey[800] : const Color(0xFFE2E8F0)),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['date'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: data['isToday'] == true ? const Color(0xFF6366F1) : Colors.grey[500],
                              fontWeight: data['isToday'] == true ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. صف أزرار العمليات السريعة الأربعة
  Widget _buildQuickActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        // فاتورة مبيعات
        Expanded(
          child: _buildActionTile(
            title: 'فاتورة مبيعات',
            icon: Icons.shopping_cart_rounded,
            iconColor: const Color(0xFF3B82F6),
            bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
            borderColor: isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE),
            onTap: () => context.go('/sales'),
          ),
        ),
        const SizedBox(width: 8),

        // فاتورة مشتريات
        Expanded(
          child: _buildActionTile(
            title: 'فاتورة مشتريات',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: isDark ? const Color(0xFF5B21B6).withValues(alpha: 0.3) : const Color(0xFFF3E8FF),
            borderColor: isDark ? const Color(0xFF6D28D9) : const Color(0xFFDDD6FE),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const PurchaseInvoiceModal(),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // سند صرف
        Expanded(
          child: _buildActionTile(
            title: 'سند صرف',
            icon: Icons.indeterminate_check_box_rounded,
            iconColor: const Color(0xFFEF4444),
            bgColor: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
            borderColor: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const PaymentVoucherDialog(),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // سند قبض
        Expanded(
          child: _buildActionTile(
            title: 'سند قبض',
            icon: Icons.add_box_rounded,
            iconColor: const Color(0xFF10B981),
            bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
            borderColor: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const ReceiptVoucherDialog(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
