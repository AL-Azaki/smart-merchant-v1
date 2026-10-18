import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design_system/tokens/colors.dart';
import '../providers/accounting_provider.dart';

/// تبويب دفتر الأستاذ العام (General Ledger / Account Statement)
/// يتيح للمحاسب اختيار أي حساب من دليل الحسابات واستعراض كشف حركاته ورصيده المتراكم بالتفصيل.
class GeneralLedgerTab extends ConsumerStatefulWidget {
  const GeneralLedgerTab({super.key});

  @override
  ConsumerState<GeneralLedgerTab> createState() => _GeneralLedgerTabState();
}

class _GeneralLedgerTabState extends ConsumerState<GeneralLedgerTab> {
  String? _selectedAccountId;
  DateTime? _startDate;
  DateTime? _endDate;
  final _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    final coaAsync = ref.watch(chartOfAccountsNotifierProvider);
    final accounts = coaAsync.value ?? [];

    // Auto-select first account if not set
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      final cashAccount = accounts.firstWhere(
        (a) => a.accountCode.startsWith('11101') || a.accountCode.startsWith('101'),
        orElse: () => accounts.first,
      );
      _selectedAccountId = cashAccount.id;
    }

    final statementAsync = _selectedAccountId != null
        ? ref.watch(accountStatementReportProvider(
            accountId: _selectedAccountId!,
            startDate: _startDate,
            endDate: _endDate,
          ))
        : const AsyncValue.data(null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Toolbar & Account Selector ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // Account Dropdown Selector
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'اختر الحساب المحاسبي',
                        labelStyle: TextStyle(fontSize: 13, color: textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Text(
                            '${acc.accountCode} - ${acc.accountName}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),
                  ),

                  // Date Range Selectors
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: borderColor),
                        ),
                        icon: const Icon(Icons.date_range_rounded, size: 16),
                        label: Text(
                          _startDate != null ? 'من: ${_dateFormat.format(_startDate!)}' : 'من البداية',
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: borderColor),
                        ),
                        icon: const Icon(Icons.event_available_rounded, size: 16),
                        label: Text(
                          _endDate != null ? 'إلى: ${_dateFormat.format(_endDate!)}' : 'إلى اليوم',
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'إلغاء تصفية التاريخ',
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() {
                            _startDate = null;
                            _endDate = null;
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Ledger Body ──
            Expanded(
              child: statementAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('خطأ في استخراج دفتر الأستاذ: $e')),
                data: (report) {
                  if (report == null) {
                    return Center(
                      child: Text('يرجى تحديد حساب لعرض كشف دفتر الأستاذ', style: TextStyle(color: textSecondary)),
                    );
                  }

                  return Column(
                    children: [
                      // KPI Summary Bar for the account
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('الرصيد الافتتاحي', report.openingBalance, textSecondary, textPrimary),
                            _buildStatItem('إجمالي المدين', report.totalDebit, const Color(0xFF3B82F6), const Color(0xFF3B82F6)),
                            _buildStatItem('إجمالي الدائن', report.totalCredit, const Color(0xFFEF4444), const Color(0xFFEF4444)),
                            _buildStatItem('الرصيد الختامي', report.closingBalance, const Color(0xFF10B981), const Color(0xFF10B981)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Transactions Table
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: report.lines.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history_rounded, size: 48, color: textSecondary.withValues(alpha: 0.3)),
                                      const SizedBox(height: 10),
                                      Text('لا توجد حركات مقيدة على هذا الحساب خلال الفترة المحددة', style: TextStyle(color: textSecondary)),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                    ),
                                    columnSpacing: 24,
                                    columns: const [
                                      DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('نوع السند', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('رقم المرجع', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('البيان / الوصف', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('مدين', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('دائن', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: report.lines.map((line) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(_dateFormat.format(line.date), style: const TextStyle(fontSize: 12))),
                                          DataCell(Text(line.documentType, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                          DataCell(Text(line.documentNumber, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                                          DataCell(
                                            SizedBox(
                                              width: 220,
                                              child: Text(
                                                line.description,
                                                style: const TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(
                                            line.debit > 0 ? _moneyFormat.format(line.debit) : '-',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: line.debit > 0 ? const Color(0xFF3B82F6) : textSecondary,
                                            ),
                                          )),
                                          DataCell(Text(
                                            line.credit > 0 ? _moneyFormat.format(line.credit) : '-',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: line.credit > 0 ? const Color(0xFFEF4444) : textSecondary,
                                            ),
                                          )),
                                          DataCell(Text(
                                            _moneyFormat.format(line.runningBalance),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF10B981),
                                            ),
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double val, Color labelColor, Color valColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '${_moneyFormat.format(val)} ر.ي',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valColor),
        ),
      ],
    );
  }
}
