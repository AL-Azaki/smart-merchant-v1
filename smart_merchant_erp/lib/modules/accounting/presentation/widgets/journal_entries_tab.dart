import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../../treasury/presentation/providers/treasury_provider.dart';
import '../../application/usecases/post_journal_entry_usecase.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../providers/accounting_provider.dart';
import 'journal_entry_details_sheet.dart';
import 'journal_entry_form_sheet.dart';

class JournalEntriesTab extends ConsumerStatefulWidget {
  const JournalEntriesTab({super.key});

  @override
  ConsumerState<JournalEntriesTab> createState() => _JournalEntriesTabState();
}

class _JournalEntriesTabState extends ConsumerState<JournalEntriesTab> {
  String _search = '';
  String _selectedStatus = 'all';
  String _selectedDateFilter = 'all'; // all, today, week, month
  String _selectedTypeFilter = 'all'; // all, Manual, SalesInvoice, PurchaseInvoice, Payment, Returns

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return const Color(0xFF10B981);
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'reversed':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _statusLabelAr(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return 'مرحل';
      case 'draft':
        return 'مسودة';
      case 'reversed':
        return 'معكوس';
      default:
        return status;
    }
  }

  String _journalTypeLabelAr(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('salesinvoice') || lower == 'sales') return 'فاتورة مبيعات';
    if (lower.contains('purchaseinvoice') || lower == 'purchase') return 'فاتورة مشتريات';
    if (lower.contains('salesreturn')) return 'مردود مبيعات';
    if (lower.contains('purchasereturn')) return 'مردود مشتريات';
    if (lower.contains('payment') || lower.contains('receipt')) return 'سند قبض';
    if (lower.contains('disbursement')) return 'سند صرف';
    if (lower.contains('transfer')) return 'تحويل مالي';
    if (lower.contains('closing')) return 'إقفال سنوي';
    if (lower.contains('manual')) return 'قيد يدوي';
    return type;
  }

  Color _journalTypeColor(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('sales')) return const Color(0xFF10B981);
    if (lower.contains('purchase')) return const Color(0xFF3B82F6);
    if (lower.contains('return')) return const Color(0xFFF59E0B);
    if (lower.contains('payment') || lower.contains('receipt')) return const Color(0xFF06B6D4);
    if (lower.contains('disbursement')) return const Color(0xFF8B5CF6);
    return const Color(0xFF64748B);
  }

  Future<void> _handleCreateJournalEntry(
    Map<String, dynamic> entryData,
    List<JournalEntryLineModel> lines,
  ) async {
    final useCase = getIt<PostJournalEntryUseCase>();
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    final lineCommands = lines
        .map((l) => JournalEntryLineCommand(
              accountId: l.accountId,
              debit: l.debit,
              credit: l.credit,
              description: l.description.isNotEmpty ? l.description : null,
            ))
        .toList();

    final cmd = PostJournalEntryCommand(
      documentDate: DateTime.tryParse(entryData['date']?.toString() ?? '') ?? DateTime.now(),
      journalType: 'Manual',
      documentType: 'Manual',
      currencyId: 'YER',
      exchangeRate: 1.0,
      description: entryData['description']?.toString(),
      lines: lineCommands,
    );

    final result = await useCase(cmd);
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      },
      (journalId) {
        // Refresh accounting, cash registers, and trial balance
        ref.invalidate(journalEntriesNotifierProvider);
        ref.invalidate(trialBalanceReportProvider());
        ref.invalidate(cashRegistersStreamProvider);
        ref.invalidate(bankAccountsStreamProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ترحيل وحفظ القيد اليومي بنجاح.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      },
    );
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case 'today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo);
      case 'month':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  bool _matchesTypeFilter(String type) {
    if (_selectedTypeFilter == 'all') return true;
    final lower = type.toLowerCase();
    switch (_selectedTypeFilter) {
      case 'Manual':
        return lower.contains('manual');
      case 'SalesInvoice':
        return lower.contains('sales') && !lower.contains('return');
      case 'PurchaseInvoice':
        return lower.contains('purchase') && !lower.contains('return');
      case 'Payment':
        return lower.contains('payment') || lower.contains('receipt') || lower.contains('disbursement');
      case 'Returns':
        return lower.contains('return');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgLight = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);

    final entriesAsync = ref.watch(journalEntriesNotifierProvider);
    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);

    final List<Map<String, String>> availableAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where((a) => a.allowPosting)
          .map((a) => {'id': a.id, 'code': a.accountCode, 'name': a.accountName})
          .toList(),
      orElse: () => [],
    );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('حدث خطأ أثناء تحميل القيود اليومية: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (entries) {
        final filteredEntries = entries.where((e) {
          final matchesSearch = _search.isEmpty ||
              e.journalNumber.contains(_search) ||
              (e.description?.contains(_search) ?? false);
          final matchesStatus = _selectedStatus == 'all' ||
              e.status.toLowerCase() == _selectedStatus.toLowerCase();
          final matchesDate = _matchesDateFilter(e.documentDate);
          final matchesType = _matchesTypeFilter(e.journalType);
          return matchesSearch && matchesStatus && matchesDate && matchesType;
        }).toList();

        return Column(
          children: [
            // ── Toolbar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'سجل القيود اليومية (اليومية العامة)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          '${filteredEntries.length} من أصل ${entries.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'تحديث القيود',
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: () {
                          ref.invalidate(journalEntriesNotifierProvider);
                          ref.invalidate(trialBalanceReportProvider());
                        },
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () {
                          JournalEntryFormSheet.show(
                            context,
                            availableAccounts: availableAccounts,
                            onSave: _handleCreateJournalEntry,
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        label: const Text('إنشاء قيد يدوي', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filters Row (بحث + فرز بالنوع + فرز بالتاريخ + فرز بالحالة)
                  Row(
                    children: [
                      // 1. Search Box
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'بحث برقم القيد أو البيان العام...',
                              hintStyle: TextStyle(fontSize: 11, color: textSecondary),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              filled: true,
                              fillColor: bgLight,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Date Filter
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDateFilter,
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('كافة التواريخ')),
                              DropdownMenuItem(value: 'today', child: Text('قيود اليوم')),
                              DropdownMenuItem(value: 'week', child: Text('هذا الأسبوع')),
                              DropdownMenuItem(value: 'month', child: Text('هذا الشهر')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedDateFilter = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Type Filter
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTypeFilter,
                            icon: const Icon(Icons.filter_alt_outlined, size: 16),
                            style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('كافة أنواع العمليات')),
                              DropdownMenuItem(value: 'Manual', child: Text('قيود يدوية')),
                              DropdownMenuItem(value: 'SalesInvoice', child: Text('فواتير مبيعات')),
                              DropdownMenuItem(value: 'PurchaseInvoice', child: Text('فواتير مشتريات')),
                              DropdownMenuItem(value: 'Payment', child: Text('سندات قبض وصرف')),
                              DropdownMenuItem(value: 'Returns', child: Text('مردودات مبيعات/مشتريات')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedTypeFilter = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 4. Status Filter
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('كافة الحالات')),
                              DropdownMenuItem(value: 'Posted', child: Text('مرحل')),
                              DropdownMenuItem(value: 'Draft', child: Text('مسودة')),
                              DropdownMenuItem(value: 'Reversed', child: Text('معكوس')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedStatus = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Entries List ──
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, color: textSecondary.withValues(alpha: 0.4), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد قيود يومية مسجلة مطابقة للبحث أو الفلتر المحدد',
                              style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final dateStr = '${entry.documentDate.year}/${entry.documentDate.month.toString().padLeft(2, '0')}/${entry.documentDate.day.toString().padLeft(2, '0')}';
                        final typeColor = _journalTypeColor(entry.journalType);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final session = ref.read(sessionNotifierProvider);
                              if (session.isActive && session.businessId != null) {
                                final repo = getIt<AccountingRepository>();
                                final details = await repo.getJournalEntryWithLinesById(entry.id, session.businessId!);
                                if (details != null && context.mounted) {
                                  final coaAccounts = accountsAsync.value ?? [];
                                  final coaMap = {for (var a in coaAccounts) a.id: a};

                                  final mappedLines = details.lines.map((l) {
                                    final acc = coaMap[l.chartOfAccountId];
                                    return <String, dynamic>{
                                      'account_code': acc?.accountCode ?? l.chartOfAccountId,
                                      'account_name': acc?.accountName ?? 'حساب محاسبي',
                                      'debit': l.type.toLowerCase() == 'debit' ? l.baseAmount : 0.0,
                                      'credit': l.type.toLowerCase() == 'credit' ? l.baseAmount : 0.0,
                                      'description': l.description ?? '',
                                    };
                                  }).toList();

                                  JournalEntryDetailsSheet.show(
                                    context,
                                    entry: {
                                      'id': details.entry.id,
                                      'number': details.entry.journalNumber,
                                      'date': dateStr,
                                      'status': details.entry.status,
                                      'description': details.entry.description,
                                      'refType': details.entry.journalType,
                                      'documentType': details.entry.documentType,
                                      'documentId': details.entry.documentId,
                                      'documentNumber': details.entry.documentNumber,
                                    },
                                    lines: mappedLines,
                                  );
                                  return;
                                }
                              }

                              if (context.mounted) {
                                JournalEntryDetailsSheet.show(
                                  context,
                                  entryId: entry.id,
                                  entry: {
                                    'id': entry.id,
                                    'number': entry.journalNumber,
                                    'date': dateStr,
                                    'status': entry.status,
                                    'description': entry.description,
                                    'refType': entry.journalType,
                                    'documentType': entry.documentType,
                                    'documentId': entry.documentId,
                                    'documentNumber': entry.documentNumber,
                                  },
                                  lines: const [],
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _statusColor(entry.status).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.receipt_rounded, color: _statusColor(entry.status), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              entry.journalNumber,
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Status Badge (Arabic)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _statusColor(entry.status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _statusLabelAr(entry.status),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _statusColor(entry.status),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Operation Type Badge (Arabic)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: typeColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _journalTypeLabelAr(entry.journalType),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: typeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.description ?? 'بدون بيان',
                                          style: TextStyle(fontSize: 12, color: textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
