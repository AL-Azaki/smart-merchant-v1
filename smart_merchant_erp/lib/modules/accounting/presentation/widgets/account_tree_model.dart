import 'package:flutter/material.dart';
import '../../../../kernel/storage/app_database.dart';

class AccountKind {
  final String label;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;
  const AccountKind(this.label, this.icon, this.lightColor, this.darkColor);

  Color color(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
  static const values = <int, AccountKind>{
    1: AccountKind(
      'الأصول',
      Icons.account_balance_wallet_outlined,
      Color(0xFF1D4ED8),
      Color(0xFF93C5FD),
    ),
    2: AccountKind(
      'الالتزامات',
      Icons.account_balance_outlined,
      Color(0xFFBE123C),
      Color(0xFFFDA4AF),
    ),
    3: AccountKind(
      'حقوق الملكية',
      Icons.diamond_outlined,
      Color(0xFF6D28D9),
      Color(0xFFC4B5FD),
    ),
    4: AccountKind(
      'الإيرادات',
      Icons.trending_up_rounded,
      Color(0xFF047857),
      Color(0xFF6EE7B7),
    ),
    5: AccountKind(
      'المصروفات',
      Icons.receipt_long_outlined,
      Color(0xFFB45309),
      Color(0xFFFCD34D),
    ),
  };
  static AccountKind of(int type) => values[type] ?? values[1]!;
}

String accountNameAr(ChartOfAccount account) {
  const legacyNames = {
    'Cash in Hand': 'النقدية بالصندوق',
    'Bank Account': 'الحساب البنكي',
    'Accounts Receivable': 'ذمم العملاء',
    'Inventory Asset': 'أصول المخزون',
    'Accounts Payable': 'ذمم الموردين',
    'Tax Payable': 'الضرائب المستحقة',
    'Sales Revenue': 'إيرادات المبيعات',
    'Inventory Gain': 'زيادة المخزون',
    'Cost of Goods Sold': 'تكلفة البضاعة المباعة',
    'Inventory Loss': 'عجز المخزون',
    'Assets': 'الأصول',
    'Liabilities': 'الالتزامات',
    'Equity': 'حقوق الملكية',
    'Revenue': 'الإيرادات',
    'Expenses': 'المصروفات',
  };
  final name = account.accountName.trim();
  if (legacyNames.containsKey(name)) return legacyNames[name]!;
  final arabic = name
      .replaceAll(RegExp(r'\s*\([^)]*[A-Za-z][^)]*\)'), '')
      .replaceAll(RegExp(r'[A-Za-z][A-Za-z0-9 &/_-]*'), '')
      .trim();
  return RegExp(r'[\u0600-\u06FF]').hasMatch(arabic)
      ? arabic
      : 'حساب باسم غير عربي';
}

bool isLegacySampleAccount(ChartOfAccount account) => const {
  'coa-cash',
  'coa-bank',
  'coa-ar',
  'coa-inv',
  'coa-ap',
  'coa-tax',
  'coa-sales',
  'coa-inv-gain',
  'coa-cogs',
  'coa-inv-loss',
}.contains(account.id);

class AccountTreeEntry {
  final ChartOfAccount account;
  final int depth;
  final bool hasChildren;
  const AccountTreeEntry(this.account, this.depth, this.hasChildren);
}

class AccountTreeModel {
  final Map<String, ChartOfAccount> byId;
  final Map<String?, List<ChartOfAccount>> children = {};
  late final List<ChartOfAccount> roots;

  AccountTreeModel(List<ChartOfAccount> accounts)
    : byId = {for (final a in accounts) a.id: a} {
    for (final account in accounts) {
      (children[account.parentAccountId] ??= []).add(account);
    }
    for (final siblings in children.values) {
      siblings.sort(_compare);
    }
    roots =
        accounts
            .where(
              (a) =>
                  a.parentAccountId == null ||
                  !byId.containsKey(a.parentAccountId),
            )
            .toList()
          ..sort(_compare);
  }

  static int _compare(ChartOfAccount a, ChartOfAccount b) {
    final left = BigInt.tryParse(a.accountCode);
    final right = BigInt.tryParse(b.accountCode);
    return left != null && right != null
        ? left.compareTo(right)
        : a.accountCode.compareTo(b.accountCode);
  }

  List<AccountTreeEntry> entries({
    Set<String>? expanded,
    String query = '',
    int? typeId,
  }) {
    final q = query.trim().toLowerCase();
    final filtering = q.isNotEmpty || typeId != null;
    final included = <String>{};
    if (filtering) {
      for (final account in byId.values) {
        if ((typeId == null || account.accountTypeId == typeId) &&
            (q.isEmpty ||
                accountNameAr(account).contains(q) ||
                account.accountName.toLowerCase().contains(q) ||
                account.accountCode.contains(q))) {
          ChartOfAccount? current = account;
          final path = <String>{};
          while (current != null && path.add(current.id)) {
            included.add(current.id);
            current = byId[current.parentAccountId];
          }
        }
      }
    }
    final result = <AccountTreeEntry>[];
    final visited = <String>{};
    void visit(ChartOfAccount account, int depth) {
      if ((filtering && !included.contains(account.id)) ||
          !visited.add(account.id)) {
        return;
      }
      final descendants = children[account.id] ?? [];
      result.add(AccountTreeEntry(account, depth, descendants.isNotEmpty));
      if (filtering || expanded == null || expanded.contains(account.id)) {
        for (final child in descendants) {
          visit(child, depth + 1);
        }
      }
    }

    for (final root in roots) {
      visit(root, 0);
    }
    // Invalid legacy cycles remain discoverable without recursing indefinitely.
    final reachable = <String>{};
    void mark(ChartOfAccount a) {
      if (!reachable.add(a.id)) return;
      for (final child in children[a.id] ?? <ChartOfAccount>[]) {
        mark(child);
      }
    }

    for (final root in roots) {
      mark(root);
    }
    for (final account
        in byId.values.where((a) => !reachable.contains(a.id)).toList()
          ..sort(_compare)) {
      visit(account, 0);
    }
    return result;
  }

  List<AccountTreeEntry> get parentOptions => entries()
      .where(
        (e) =>
            e.account.isActive &&
            !e.account.allowPosting &&
            !isLegacySampleAccount(e.account),
      )
      .toList();

  int get hierarchyIssueCount => byId.values.where((a) {
    if (a.parentAccountId != null && !byId.containsKey(a.parentAccountId)) {
      return true;
    }
    if (a.allowPosting && (children[a.id]?.isNotEmpty ?? false)) return true;
    final path = <String>{};
    ChartOfAccount? current = a;
    while (current != null) {
      if (!path.add(current.id)) return true;
      current = byId[current.parentAccountId];
    }
    return false;
  }).length;
}
