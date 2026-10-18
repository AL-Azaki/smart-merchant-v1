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
import 'account_tree_model.dart';

class ChartOfAccountsTab extends ConsumerStatefulWidget {
  const ChartOfAccountsTab({super.key});
  @override
  ConsumerState<ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends ConsumerState<ChartOfAccountsTab> {
  final _searchController = TextEditingController();
  String _search = '';
  int? _typeFilter;
  final Set<String> _expanded = {};
  bool _initialized = false;
  bool _isSeeding = false;
  String? _loadedBusinessId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _message(String message) => RegExp(r'[A-Za-z]').hasMatch(message)
      ? 'تعذر إتمام العملية. حاول مرة أخرى.'
      : message;

  Future<void> _seedDefaultCoa() async {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isActive || _isSeeding) return;
    setState(() => _isSeeding = true);
    try {
      await DefaultChartOfAccountsSeeder(
        getIt<AppDatabase>(),
      ).seedChartOfAccounts(businessId: session.businessId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تجهيز دليل الحسابات بنجاح.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر تجهيز دليل الحسابات. حاول مرة أخرى.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _openCreate(List<ChartOfAccount> accounts, {String? parentId}) =>
      AccountFormSheet.show(
        context,
        parentAccounts: accounts,
        initialParentId: parentId,
        onSave: (data) async {
          final result = await getIt<AccountingApplicationService>()
              .createAccount(
                CreateAccountCommand(
                  accountName: data['name'] as String,
                  parentAccountId: data['parentId'] as String?,
                  allowPosting: data['allowPosting'] as bool,
                ),
              );
          result.fold(
            (failure) =>
                throw AccountFormSaveException(_message(failure.message)),
            (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الحساب بنجاح.')),
                );
              }
            },
          );
        },
      );

  Future<void> _delete(ChartOfAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: Text(
          'هل تريد حذف «${accountNameAr(account)}»؟ يُسمح بالحذف فقط إذا لم يرتبط بحركات أو حسابات أخرى.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await getIt<AccountingApplicationService>()
        .safeDeleteAccount(account.id);
    if (!mounted) return;
    final message = result.fold(
      (failure) => _message(failure.message),
      (_) => 'تم حذف الحساب.',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(
      sessionNotifierProvider.select((s) => s.businessId),
    );
    if (_loadedBusinessId != businessId) {
      _loadedBusinessId = businessId;
      _expanded.clear();
      _initialized = false;
      _search = '';
      _typeFilter = null;
      _searchController.clear();
    }
    return ref
        .watch(chartOfAccountsNotifierProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                const Text('تعذر تحميل شجرة الحسابات.'),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(chartOfAccountsNotifierProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
          data: (accounts) {
            if (accounts.isEmpty) {
              if (!_isSeeding) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isSeeding) {
                    _seedDefaultCoa();
                  }
                });
              }
              return _empty();
            }
            final tree = AccountTreeModel(accounts);
            if (!_initialized) {
              _expanded.addAll(tree.roots.map((a) => a.id));
              _initialized = true;
            }
            final entries = tree.entries(
              expanded: _expanded,
              query: _search,
              typeId: _typeFilter,
            );
            final groupCount = accounts.where((a) => !a.allowPosting).length;
            final legacyCount = accounts.where(isLegacySampleAccount).length;
            final issueCount = tree.hierarchyIssueCount;
            final theme = Theme.of(context);
            final border = theme.brightness == Brightness.dark
                ? AppColors.borderDark
                : AppColors.borderLight;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final title = Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_tree_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'شجرة الحسابات',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${accounts.length} حساب • $groupCount تجميعي • ${accounts.length - groupCount} للتسجيل',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                      final add = FilledButton.icon(
                        onPressed: () => _openCreate(accounts),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة حساب'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      );
                      if (constraints.maxWidth < 550) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [title, const SizedBox(height: 12), add],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: title),
                          const SizedBox(width: 16),
                          add,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _search = v.trim()),
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم الحساب أو رقمه',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'مسح البحث',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _search = '');
                                    },
                                  ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          side: BorderSide(color: border),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        tooltip: 'توسيع الكل',
                        icon: const Icon(Icons.unfold_more_rounded),
                        onPressed: () => setState(
                          () => _expanded.addAll(
                            tree.children.keys.whereType<String>(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          side: BorderSide(color: border),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        tooltip: 'طي الكل',
                        icon: const Icon(Icons.unfold_less_rounded),
                        onPressed: () => setState(() => _expanded.clear()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            showCheckmark: false,
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.colorScheme.primary.withValues(
                              alpha: 0.10,
                            ),
                            side: BorderSide(
                              color: _typeFilter == null
                                  ? theme.colorScheme.primary
                                  : border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            label: const Text('الكل'),
                            avatar: const Icon(
                              Icons.account_tree_outlined,
                              size: 18,
                            ),
                            selected: _typeFilter == null,
                            onSelected: (_) =>
                                setState(() => _typeFilter = null),
                          ),
                        ),
                        for (final kind in AccountKind.values.entries)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: FilterChip(
                              showCheckmark: false,
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: _typeFilter == kind.key
                                    ? kind.value.color(context)
                                    : border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              avatar: Icon(
                                kind.value.icon,
                                size: 18,
                                color: kind.value.color(context),
                              ),
                              label: Text(
                                '${kind.value.label} (${accounts.where((a) => a.accountTypeId == kind.key).length})',
                              ),
                              selected: _typeFilter == kind.key,
                              selectedColor: kind.value
                                  .color(context)
                                  .withValues(alpha: 0.12),
                              onSelected: (selected) => setState(
                                () => _typeFilter = selected ? kind.key : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (legacyCount > 0 || issueCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              legacyCount > 0
                                  ? 'توجد $legacyCount حسابات من بيانات تجريبية سابقة. راجع ارتباطاتها قبل حذفها.'
                                  : 'توجد $issueCount حسابات تحتاج إلى مراجعة ارتباطها داخل الشجرة.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: border),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: entries.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 40,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('لا توجد حسابات تطابق البحث'),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _search = '';
                                          _typeFilter = null;
                                        });
                                      },
                                      child: const Text('عرض كل الحسابات'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: entries.length,
                              itemBuilder: (_, index) =>
                                  _node(entries[index], tree, accounts),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _node(
    AccountTreeEntry entry,
    AccountTreeModel tree,
    List<ChartOfAccount> accounts,
  ) {
    final account = entry.account;
    final theme = Theme.of(context);
    final color = AccountKind.of(account.accountTypeId).color(context);
    final isRoot = entry.depth == 0;
    final expanded =
        _expanded.contains(account.id) ||
        _search.isNotEmpty ||
        _typeFilter != null;
    final group = !account.allowPosting;
    final childCount = tree.children[account.id]?.length ?? 0;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final indent = (entry.depth * 20.0)
        .clamp(0.0, compact ? 56.0 : 140.0)
        .toDouble();
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, top: isRoot ? 6 : 0),
      child: Material(
        color: isRoot ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: entry.hasChildren
              ? () => setState(() {
                  expanded
                      ? _expanded.remove(account.id)
                      : _expanded.add(account.id);
                })
              : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 4, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: entry.hasChildren
                      ? Icon(
                          expanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_left_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        )
                      : Icon(
                          entry.depth == 0
                              ? Icons.horizontal_rule_rounded
                              : Icons.subdirectory_arrow_left_rounded,
                          color: theme.colorScheme.outline,
                          size: 18,
                        ),
                ),
                Container(
                  width: isRoot ? 40 : 32,
                  height: isRoot ? 40 : 32,
                  decoration: isRoot
                      ? BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Icon(
                    isRoot
                        ? AccountKind.of(account.accountTypeId).icon
                        : group
                        ? (expanded
                              ? Icons.folder_open_outlined
                              : Icons.folder_outlined)
                        : Icons.description_outlined,
                    size: isRoot ? 22 : 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountNameAr(account),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: group ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (compact)
                            account.accountCode.replaceAll(
                              RegExp(r'[A-Za-z]'),
                              '',
                            ),
                          group
                              ? (childCount == 0
                                    ? 'حساب تجميعي'
                                    : 'الفروع: $childCount')
                              : 'يقبل التسجيل',
                          account.normalBalance == 'Debit' ? 'مدين' : 'دائن',
                          if (!account.isActive) 'غير نشط',
                          if (isLegacySampleAccount(account)) 'تجريبي سابق',
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Text(
                    account.accountCode.replaceAll(RegExp(r'[A-Za-z]'), ''),
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (group &&
                    account.isActive &&
                    !isLegacySampleAccount(account)) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'إضافة حساب تحت ${accountNameAr(account)}',
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 22,
                      color: color,
                    ),
                    onPressed: () =>
                        _openCreate(accounts, parentId: account.id),
                  ),
                ] else if (!account.isSystem && !entry.hasChildren)
                  PopupMenuButton<String>(
                    tooltip: 'خيارات الحساب',
                    onSelected: (_) => _delete(account),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 10),
                            Text('حذف الحساب'),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (account.isSystem && !group)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Tooltip(
                      message: 'حساب أساسي',
                      child: Icon(Icons.verified_user_outlined, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: AppColors.primary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ابدأ بشجرة حسابات منظّمة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'جهّز الحسابات الأساسية للمتجر، ثم أضف حساباتك الفرعية حسب احتياجك.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSeeding ? null : _seedDefaultCoa,
            icon: _isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: const Text('تجهيز دليل الحسابات'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
        ],
      ),
    ),
  );
}
