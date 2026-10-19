import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../widgets/receipt_voucher_dialog.dart';
import '../widgets/voucher_details_dialog.dart';
import '../widgets/voucher_print_service.dart';

class ReceiptVouchersView extends ConsumerStatefulWidget {
  const ReceiptVouchersView({super.key});

  @override
  ConsumerState<ReceiptVouchersView> createState() => _ReceiptVouchersViewState();
}

class _ReceiptVouchersViewState extends ConsumerState<ReceiptVouchersView> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  int _selectedFilterIndex = 0; // 0: تلقائي, 1: اليوم, 2: هذا الأسبوع, 3: هذا الشهر, 4: تاريخ مخصص
  DateTimeRange? _customDateRange;

  String _sortField = 'number'; // 'number' (رقم السند) أو 'date' (التاريخ)
  bool _isAscending = false; // false = تنازلي, true = تصاعدي

  Map<String, String> _contactNames = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final db = getIt<AppDatabase>();
      final customers = await db.select(db.customers).get();
      final suppliers = await db.select(db.suppliers).get();
      final coa = await db.select(db.chartOfAccounts).get();

      final map = <String, String>{};
      for (final c in customers) {
        map[c.id] = c.customerName;
      }
      for (final s in suppliers) {
        map[s.id] = s.supplierName;
      }
      for (final a in coa) {
        map[a.id] = a.accountName;
      }

      if (mounted) {
        setState(() {
          _contactNames = map;
        });
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
      return val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesPeriod(DateTime date, DateTime now) {
    switch (_selectedFilterIndex) {
      case 1: // اليوم
        return _isSameDay(date, now);
      case 2: // هذا الأسبوع (آخر 7 أيام)
        final weekAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        return date.isAfter(weekAgo.subtract(const Duration(milliseconds: 1)));
      case 3: // هذا الشهر
        return date.year == now.year && date.month == now.month;
      case 4: // تاريخ مخصص
        if (_customDateRange == null) {
          return true;
        }
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            date.isBefore(end.add(const Duration(milliseconds: 1)));
      case 0: // تلقائي
      default:
        return true;
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'اختر الفترة الزمنية للبحث',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
      saveText: 'تطبيق',
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
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final vouchersAsync = ref.watch(receiptVouchersStreamProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'سندات القبض (Receipt Vouchers)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: textPrimary,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(receiptVouchersStreamProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('سند قبض جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const ReceiptVoucherDialog(),
          );
          if (created == true) {
            ref.invalidate(receiptVouchersStreamProvider);
          }
        },
      ),
      body: Column(
        children: [
          // 1. شريط الإحصائيات السريع (KPI Summary Ribbon)
          vouchersAsync.maybeWhen(
            data: (vouchers) {
              final double totalAll = vouchers.fold(0.0, (sum, v) => sum + v.amount);
              final double todayTotal =
                  vouchers.where((v) => _isSameDay(v.paymentDate, now)).fold(0.0, (sum, v) => sum + v.amount);

              return Container(
                color: surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryKpiCard(
                        title: 'إجمالي المقبوضات',
                        value: '${_formatAmount(totalAll)} ر.ي',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryKpiCard(
                        title: 'مقبوضات اليوم',
                        value: '${_formatAmount(todayTotal)} ر.ي',
                        icon: Icons.today_rounded,
                        color: const Color(0xFF059669),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryKpiCard(
                        title: 'عدد السندات',
                        value: '${vouchers.length} سند',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // 2. شريط البحث والفرز والفلاتر المتقدمة (مطابق للتصميم المطلوب)
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // السطر 1: مربع البحث بالاسم/الرقم/المرجع + قائمة فرز الحقل + قائمة اتجاه الفرز
                Row(
                  children: [
                    // مربع البحث
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم، رقم السند، أو المرجع...',
                          hintStyle: TextStyle(fontSize: 12.5, color: textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _search = val.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // قائمة فرز الحقل (رقم السند / التاريخ) مع إطار بارز
                    _buildSortFieldDropdown(isDark, surface),
                    const SizedBox(width: 8),

                    // قائمة اتجاه الفرز (تنازلي / تصاعدي)
                    _buildSortDirectionDropdown(isDark, surface),
                  ],
                ),
                const SizedBox(height: 12),

                // السطر 2: عنوان الفترة الزمنية + فلاتر الفترات
                Row(
                  children: [
                    Text(
                      'الفترة الزمنية',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPeriodChip(0, 'تلقائي', isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip(1, 'اليوم', isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip(2, 'هذا الأسبوع', isDark),
                            const SizedBox(width: 6),
                            _buildPeriodChip(3, 'هذا الشهر', isDark),
                            const SizedBox(width: 6),
                            _buildCustomDateChip(isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. قائمة السندات المطورة مع الفرز والتصفية المباشرة
          Expanded(
            child: vouchersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('خطأ في تحميل السندات: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (vouchers) {
                final filtered = vouchers.where((v) {
                  // 1. تصفية بالبحث (بالاسم، برقم السند، أو بالمرجع في الملاحظات)
                  if (_search.isNotEmpty) {
                    final q = _search.toLowerCase();
                    final matchNumber = v.paymentNumber.toLowerCase().contains(q);
                    final matchNotes = (v.notes ?? '').toLowerCase().contains(q);
                    final contact = (v.contactId != null ? _contactNames[v.contactId!] : null) ?? '';
                    final account = _contactNames[v.chartOfAccountId] ?? '';
                    final matchContact = contact.toLowerCase().contains(q);
                    final matchAccount = account.toLowerCase().contains(q);
                    final matchAmount = v.amount.toString().contains(q);

                    if (!matchNumber && !matchNotes && !matchContact && !matchAccount && !matchAmount) {
                      return false;
                    }
                  }
                  // 2. تصفية بالفترة الزمنية
                  return _matchesPeriod(v.paymentDate, now);
                }).toList();

                // 3. الفرز الديناميكي (حسب رقم السند أو التاريخ - تنازلي أو تصاعدي)
                filtered.sort((a, b) {
                  int cmp;
                  if (_sortField == 'number') {
                    cmp = a.paymentNumber.compareTo(b.paymentNumber);
                  } else {
                    cmp = a.paymentDate.compareTo(b.paymentDate);
                  }
                  return _isAscending ? cmp : -cmp;
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد سندات قبض مطابقة',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط على "سند قبض جديد" لتقييد دفعة من عميل أو إيراد نقدي',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final contactName = item.contactId != null ? _contactNames[item.contactId!] : null;
                    return _ReceiptVoucherCard(
                      item: item,
                      contactName: contactName,
                      surface: surface,
                      borderColor: borderColor,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) => VoucherDetailsDialog(voucher: item),
                        );
                      },
                      onPrint: () {
                        VoucherPrintService.printVoucher(
                          context: context,
                          voucher: item,
                        );
                      },
                      onShare: () {
                        VoucherPrintService.shareVoucher(
                          context: context,
                          voucher: item,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(int index, String label, bool isDark) {
    final isSelected = _selectedFilterIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
                : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDateChip(bool isDark) {
    final isSelected = _selectedFilterIndex == 4;
    String label = 'تاريخ مخصص';
    if (isSelected && _customDateRange != null) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      label = '${s.month}/${s.day} - ${e.month}/${e.day}';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _selectCustomDateRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: isSelected
                  ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
                  : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857))
                    : (isDark ? Colors.grey[300] : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortFieldDropdown(bool isDark, Color surface) {
    return PopupMenuButton<String>(
      tooltip: 'فرز حسب',
      onSelected: (val) {
        setState(() => _sortField = val);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'number',
          child: Row(
            children: [
              Icon(
                Icons.tag_rounded,
                size: 16,
                color: _sortField == 'number' ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Text(
                'رقم السند',
                style: TextStyle(
                  fontWeight: _sortField == 'number' ? FontWeight.bold : FontWeight.normal,
                  color: _sortField == 'number' ? const Color(0xFF10B981) : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date',
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: _sortField == 'date' ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Text(
                'التاريخ',
                style: TextStyle(
                  fontWeight: _sortField == 'date' ? FontWeight.bold : FontWeight.normal,
                  color: _sortField == 'date' ? const Color(0xFF10B981) : null,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sortField == 'number' ? 'رقم السند' : 'التاريخ',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDirectionDropdown(bool isDark, Color surface) {
    return PopupMenuButton<bool>(
      tooltip: 'اتجاه الفرز',
      onSelected: (val) {
        setState(() => _isAscending = val);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: false,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                size: 16,
                color: !_isAscending ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Text(
                'تنازلي',
                style: TextStyle(
                  fontWeight: !_isAscending ? FontWeight.bold : FontWeight.normal,
                  color: !_isAscending ? const Color(0xFF10B981) : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: _isAscending ? const Color(0xFF10B981) : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              Text(
                'تصاعدي',
                style: TextStyle(
                  fontWeight: _isAscending ? FontWeight.bold : FontWeight.normal,
                  color: _isAscending ? const Color(0xFF10B981) : null,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isAscending ? 'تصاعدي' : 'تنازلي',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReceiptVoucherCard extends StatelessWidget {
  final Payment item;
  final String? contactName;
  final Color surface;
  final Color borderColor;
  final VoidCallback onTap;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  const _ReceiptVoucherCard({
    required this.item,
    required this.surface,
    required this.borderColor,
    required this.onTap,
    required this.onPrint,
    required this.onShare,
    this.contactName,
  });

  String _formatAmount(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    }
    return val.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final dateStr =
        '${item.paymentDate.year}/${item.paymentDate.month.toString().padLeft(2, '0')}/${item.paymentDate.day.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 1. أيقونة السند
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.north_east_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),

              // 2. تفاصيل السند (الرقم، البيان، التاريخ)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.paymentNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.contactType == 'Customer' ? 'قبض من عميل' : 'إيراد نقدي',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                        if (contactName != null && contactName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              contactName!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.notes?.isNotEmpty == true ? item.notes! : 'سند قبض مقيد ومرحل',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. المبلغ وأزرار الإجراءات السريعة (المعاينة، الطباعة، المشاركة)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatAmount(item.amount)} ${item.currencyId}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر المعاينة
                      InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.visibility_outlined, size: 16, color: isDark ? Colors.grey[300] : const Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // زر الطباعة
                      InkWell(
                        onTap: onPrint,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // زر المشاركة
                      InkWell(
                        onTap: onShare,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.share_outlined, size: 16, color: isDark ? Colors.grey[300] : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
