import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/getit_instance.dart';
import '../../../../database/seeders/default_coa_seeder.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../authentication/presentation/providers/session_provider.dart';
import '../../application/services/accounting_application_service.dart';
import '../providers/accounting_provider.dart';
import 'account_form_sheet.dart';

class ChartOfAccountsTab extends ConsumerStatefulWidget {
  const ChartOfAccountsTab({super.key});

  @override
  ConsumerState<ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends ConsumerState<ChartOfAccountsTab> {
  String _search = '';
  String _selectedTypeFilter = 'all';
  final Set<String> _expanded = {};
  bool _isSeeding = false;

  Color _typeColor(int typeId) {
    switch (typeId) {
      case 1:
        return const Color(0xFF3B82F6); // Assets (Blue)
      case 2:
        return const Color(0xFFEF4444); // Liabilities (Red)
      case 3:
        return const Color(0xFF8B5CF6); // Equity (Purple)
      case 4:
        return const Color(0xFF10B981); // Revenue (Emerald)
      case 5:
        return const Color(0xFFF59E0B); // Expenses (Amber)
      default:
        return Colors.grey;
    }
  }

  String _typeLabelAr(int typeId) {
    switch (typeId) {
      case 1:
        return 'أصول';
      case 2:
        return 'خصوم';
      case 3:
        return 'حقوق ملكية';
      case 4:
        return 'إيرادات';
      case 5:
        return 'مصروفات';
      default:
        return 'حساب';
    }
  }

  Future<void> _seedDefaultCoa() async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || session.businessId == null) return;

    setState(() => _isSeeding = true);
    try {
      final db = getIt<AppDatabase>();
      final seeder = DefaultChartOfAccountsSeeder(db);
      await seeder.seedChartOfAccounts(businessId: session.businessId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بذر دليل الحسابات القياسي بنجاح.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل بذر دليل الحسابات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _handleCreateAccount(
    List<ChartOfAccount> allAccounts,
    Map<String, dynamic> data,
  ) async {
    final service = getIt<AccountingApplicationService>();

    int typeId = 1;
    final typeStr = data['type']?.toString() ?? 'Asset';
    if (typeStr == 'Liability') typeId = 2;
    if (typeStr == 'Equity') typeId = 3;
    if (typeStr == 'Revenue') typeId = 4;
    if (typeStr == 'Expense') typeId = 5;

    final cmd = CreateAccountCommand(
      accountCode: (data['code'] as String?) ?? '',
      accountName: (data['name'] as String?) ?? '',
      accountTypeId: typeId,
      normalBalance: (data['normalBalance'] as String?) ?? (typeId == 1 || typeId == 5 ? 'Debit' : 'Credit'),
      parentAccountId: data['parentId'] as String?,
      allowPosting: (data['allowPosting'] as bool?) ?? true,
    );

    final result = await service.createAccount(cmd);
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (accountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة الحساب بنجاح: ${cmd.accountName}'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(ChartOfAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الحساب "${account.accountName}" (${account.accountCode})؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final service = getIt<AccountingApplicationService>();
    final result = await service.safeDeleteAccount(account.id);
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
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الحساب بنجاح: ${account.accountName}'),
            backgroundColor: const Color(0xFF10B981),
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

    final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('حدث خطأ أثناء تحميل دليل الحسابات: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (allAccounts) {
        if (allAccounts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: Color(0xFF3B82F6), size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'دليل الحسابات فارغ حالياً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك بذر دليل الحسابات القياسي المعتمد بضغطة زر واحدة لبدء العمليات المحاسبية فوراً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _seedDefaultCoa,
                    icon: _isSeeding
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
                    label: const Text('بذر دليل الحسابات القياسي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalAccounts = allAccounts.length;
        final parentCount = allAccounts.where((a) => !a.allowPosting).length;
        final postingCount = allAccounts.where((a) => a.allowPosting).length;

        // Auto-expand root accounts on first load
        if (_expanded.isEmpty) {
          _expanded.addAll(allAccounts.where((a) => a.parentAccountId == null).map((a) => a.id));
        }

        final filteredAccounts = allAccounts.where((a) {
          final matchesSearch = _search.isEmpty ||
              a.accountName.contains(_search) ||
              a.accountCode.contains(_search);
          final matchesType = _selectedTypeFilter == 'all' ||
              a.accountTypeId.toString() == _selectedTypeFilter;
          return matchesSearch && matchesType;
        }).toList();

        List<ChartOfAccount> getChildren(String? parentId) {
          return filteredAccounts.where((a) => a.parentAccountId == parentId).toList()
            ..sort((a, b) => a.accountCode.compareTo(b.accountCode));
        }

        final roots = _search.isEmpty && _selectedTypeFilter == 'all'
            ? getChildren(null)
            : filteredAccounts;

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
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_tree_rounded, color: Color(0xFF3B82F6), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دليل الحسابات الفعلي',
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
                          '$totalAccounts حساب ($parentCount رئيسي • $postingCount فرعي)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                        ),
                      ),
                      const Spacer(),
                      // Add Account Button
                      ElevatedButton.icon(
                        onPressed: () {
                          AccountFormSheet.show(
                            context,
                            parentAccounts: allAccounts
                                .where((a) => !a.allowPosting)
                                .map((a) => {'id': a.id, 'code': a.accountCode, 'name': a.accountName})
                                .toList(),
                            onSave: (data) => _handleCreateAccount(allAccounts, data),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('إضافة حساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Search & Filter
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'بحث برمز أو اسم الحساب...',
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
                        value: _selectedTypeFilter,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('كافة الأنواع', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '1', child: Text('الأصول', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '2', child: Text('الخصوم', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '3', child: Text('حقوق الملكية', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '4', child: Text('الإيرادات', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: '5', child: Text('المصروفات', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedTypeFilter = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Accounts Tree List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: roots.length,
                itemBuilder: (context, index) {
                  return _buildAccountNode(
                    roots[index],
                    allAccounts,
                    getChildren,
                    isDark,
                    surface,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountNode(
    ChartOfAccount account,
    List<ChartOfAccount> allAccounts,
    List<ChartOfAccount> Function(String?) getChildren,
    bool isDark,
    Color surface,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final children = getChildren(account.id);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded.contains(account.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasChildren
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expanded.remove(account.id);
                      } else {
                        _expanded.add(account.id);
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (hasChildren)
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_left_rounded,
                      size: 20,
                      color: textSecondary,
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeColor(account.accountTypeId).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      account.accountCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: _typeColor(account.accountTypeId),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.accountName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: account.allowPosting ? FontWeight.normal : FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  // Postable badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: account.allowPosting ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      account.allowPosting ? 'فرعي' : 'رئيسي',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: account.allowPosting ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button for custom leaf accounts
                  if (!account.isSystem && account.allowPosting)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      onPressed: () => _handleDeleteAccount(account),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          if (hasChildren && isExpanded)
            Padding(
              padding: const EdgeInsets.only(right: 20, left: 8, bottom: 8),
              child: Column(
                children: children
                    .map((child) => _buildAccountNode(
                          child,
                          allAccounts,
                          getChildren,
                          isDark,
                          surface,
                          borderColor,
                          textPrimary,
                          textSecondary,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
