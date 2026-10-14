import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ترحيل القيد اليومي بنجاح.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
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
          return matchesSearch && matchesStatus;
        }).toList();

        return Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF8B5CF6), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دفتر اليومية العامة',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
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
                          '${entries.length} قيد',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          JournalEntryFormSheet.show(
                            context,
                            availableAccounts: availableAccounts,
                            onSave: _handleCreateJournalEntry,
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('قيد يدوي جديد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'بحث برقم القيد أو البيان...',
                              hintStyle: TextStyle(fontSize: 12, color: textSecondary),
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
                      DropdownButton<String>(
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('كافة الحالات', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Posted', child: Text('مرحل', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Draft', child: Text('مسودة', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Reversed', child: Text('معكوس', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedStatus = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Entries List
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, color: textSecondary.withOpacity(0.5), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد قيود يومية مسجلة مطابقة للبحث',
                              style: TextStyle(fontSize: 14, color: textSecondary),
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final session = ref.read(sessionNotifierProvider);
                              if (session.isActive && session.businessId != null) {
                                final repo = getIt<AccountingRepository>();
                                final details = await repo.getJournalEntryWithLinesById(entry.id, session.businessId!);
                                if (details != null && context.mounted) {
                                  JournalEntryDetailsSheet.show(
                                    context,
                                    entry: {
                                      'id': details.entry.id,
                                      'number': details.entry.journalNumber,
                                      'date': '${details.entry.documentDate.year}/${details.entry.documentDate.month.toString().padLeft(2, '0')}/${details.entry.documentDate.day.toString().padLeft(2, '0')}',
                                      'status': details.entry.status,
                                      'description': details.entry.description,
                                      'refType': details.entry.journalType,
                                    },
                                    lines: details.lines.map((l) => <String, dynamic>{
                                      'account_code': l.chartOfAccountId,
                                      'debit': l.type.toLowerCase() == 'debit' ? l.baseAmount : 0.0,
                                      'credit': l.type.toLowerCase() == 'credit' ? l.baseAmount : 0.0,
                                      'description': l.description,
                                    }).toList(),
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
                                  },
                                  lines: const [],
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _statusColor(entry.status).withOpacity(0.1),
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
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _statusColor(entry.status).withOpacity(0.12),
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
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                entry.journalType,
                                                style: const TextStyle(fontSize: 10, color: Colors.blue),
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
                                        style: TextStyle(fontSize: 11, color: textSecondary),
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
