import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../kernel/storage/app_database.dart';

/// Seeds a standard retail Chart of Accounts and vital account mappings for a business.
/// Fully idempotent: checks if accounts already exist before inserting.
class DefaultChartOfAccountsSeeder {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  DefaultChartOfAccountsSeeder(this._db);

  Future<void> seedChartOfAccounts({
    required String businessId,
    String currencyId = 'YER',
  }) async {
    if (businessId.trim().isEmpty) return;

    // Check if COA is already initialized for this business
    final existingAccounts = await (_db.select(_db.chartOfAccounts)
          ..where((a) => a.businessId.equals(businessId)))
        .get();

    final Map<String, String> codeToIdMap = {
      for (final a in existingAccounts) a.accountCode: a.id,
    };

    Future<String> ensureAccount({
      required String code,
      required String nameAr,
      required int typeId,
      required String normalBalance,
      required int level,
      required bool allowPosting,
      String? parentCode,
      String? category,
    }) async {
      if (codeToIdMap.containsKey(code)) {
        return codeToIdMap[code]!;
      }

      final id = _uuid.v4();
      final parentId = parentCode != null ? codeToIdMap[parentCode] : null;

      await _db.into(_db.chartOfAccounts).insert(
            ChartOfAccountsCompanion.insert(
              id: id,
              businessId: businessId,
              accountCode: code,
              accountName: nameAr,
              accountTypeId: typeId,
              normalBalance: normalBalance,
              parentAccountId: Value(parentId),
              currencyId: Value(currencyId),
              accountLevel: Value(level),
              allowPosting: Value(allowPosting),
              isSystem: const Value(true),
              isActive: const Value(true),
              accountCategory: Value(category),
            ),
          );

      codeToIdMap[code] = id;
      return id;
    }

    // 1. Root Categories (Level 1)
    await ensureAccount(
      code: '1',
      nameAr: 'الأصول (Assets)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 1,
      allowPosting: false,
    );
    await ensureAccount(
      code: '2',
      nameAr: 'الخصوم والالتزامات (Liabilities)',
      typeId: 2,
      normalBalance: 'Credit',
      level: 1,
      allowPosting: false,
    );
    await ensureAccount(
      code: '3',
      nameAr: 'حقوق الملكية (Equity)',
      typeId: 3,
      normalBalance: 'Credit',
      level: 1,
      allowPosting: false,
    );
    await ensureAccount(
      code: '4',
      nameAr: 'الإيرادات (Revenue)',
      typeId: 4,
      normalBalance: 'Credit',
      level: 1,
      allowPosting: false,
    );
    await ensureAccount(
      code: '5',
      nameAr: 'المصروفات (Expenses)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 1,
      allowPosting: false,
    );

    // 2. Assets Sub-accounts
    await ensureAccount(
      code: '11',
      nameAr: 'الأصول المتداولة (Current Assets)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 2,
      allowPosting: false,
      parentCode: '1',
    );
    await ensureAccount(
      code: '111',
      nameAr: 'النقدية وما في حكمها (Cash & Banks)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: false,
      parentCode: '11',
    );
    final cashMainId = await ensureAccount(
      code: '11101',
      nameAr: 'الصندوق الرئيسي (Main Cashbox)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 4,
      allowPosting: true,
      parentCode: '111',
      category: 'Cash',
    );
    final bankMainId = await ensureAccount(
      code: '11102',
      nameAr: 'الحساب البنكي الرئيسي (Main Bank)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 4,
      allowPosting: true,
      parentCode: '111',
      category: 'Bank',
    );
    await ensureAccount(
      code: '112',
      nameAr: 'المدينون وذمم العملاء (Accounts Receivable)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: false,
      parentCode: '11',
    );
    final arId = await ensureAccount(
      code: '11201',
      nameAr: 'ذمم العملاء (Customer Receivables)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 4,
      allowPosting: true,
      parentCode: '112',
      category: 'Receivable',
    );
    await ensureAccount(
      code: '113',
      nameAr: 'المخزون (Inventory)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: false,
      parentCode: '11',
    );
    final invId = await ensureAccount(
      code: '11301',
      nameAr: 'بضاعة المخزن الرئيسي (Main Stock)',
      typeId: 1,
      normalBalance: 'Debit',
      level: 4,
      allowPosting: true,
      parentCode: '113',
      category: 'Inventory',
    );

    // 3. Liabilities Sub-accounts
    await ensureAccount(
      code: '21',
      nameAr: 'الخصوم المتداولة (Current Liabilities)',
      typeId: 2,
      normalBalance: 'Credit',
      level: 2,
      allowPosting: false,
      parentCode: '2',
    );
    await ensureAccount(
      code: '211',
      nameAr: 'الدائنون وذمم الموردين (Accounts Payable)',
      typeId: 2,
      normalBalance: 'Credit',
      level: 3,
      allowPosting: false,
      parentCode: '21',
    );
    final apId = await ensureAccount(
      code: '21101',
      nameAr: 'ذمم الموردين (Supplier Payables)',
      typeId: 2,
      normalBalance: 'Credit',
      level: 4,
      allowPosting: true,
      parentCode: '211',
      category: 'Payable',
    );

    // 4. Equity Sub-accounts
    final capitalId = await ensureAccount(
      code: '31',
      nameAr: 'رأس المال (Capital)',
      typeId: 3,
      normalBalance: 'Credit',
      level: 2,
      allowPosting: true,
      parentCode: '3',
      category: 'Equity',
    );
    final retainedEarningsId = await ensureAccount(
      code: '32',
      nameAr: 'الأرباح المبقاة / المرحلة (Retained Earnings)',
      typeId: 3,
      normalBalance: 'Credit',
      level: 2,
      allowPosting: true,
      parentCode: '3',
      category: 'Equity',
    );
    await ensureAccount(
      code: '33',
      nameAr: 'مسحوبات الشركاء (Owner Drawings)',
      typeId: 3,
      normalBalance: 'Debit',
      level: 2,
      allowPosting: true,
      parentCode: '3',
      category: 'Equity',
    );

    // 5. Revenue Sub-accounts
    final salesRevId = await ensureAccount(
      code: '41',
      nameAr: 'إيرادات المبيعات (Sales Revenue)',
      typeId: 4,
      normalBalance: 'Credit',
      level: 2,
      allowPosting: true,
      parentCode: '4',
      category: 'Revenue',
    );
    await ensureAccount(
      code: '42',
      nameAr: 'إيرادات أخرى / خصم مكتسب (Other Revenue)',
      typeId: 4,
      normalBalance: 'Credit',
      level: 2,
      allowPosting: true,
      parentCode: '4',
      category: 'Revenue',
    );

    // 6. Expenses Sub-accounts
    final cogsId = await ensureAccount(
      code: '51',
      nameAr: 'تكلفة البضاعة المباعة (COGS)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 2,
      allowPosting: true,
      parentCode: '5',
      category: 'Expense',
    );
    await ensureAccount(
      code: '52',
      nameAr: 'مصروفات تشغيلية (Operating Expenses)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 2,
      allowPosting: false,
      parentCode: '5',
    );
    await ensureAccount(
      code: '52001',
      nameAr: 'إيجارات (Rent)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: true,
      parentCode: '52',
    );
    await ensureAccount(
      code: '52002',
      nameAr: 'كهرباء ومياه (Utilities)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: true,
      parentCode: '52',
    );
    await ensureAccount(
      code: '52003',
      nameAr: 'رواتب وأجور (Salaries)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: true,
      parentCode: '52',
    );
    final stockLossId = await ensureAccount(
      code: '52004',
      nameAr: 'عجز وتلف المخزون (Stock Loss)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: true,
      parentCode: '52',
    );
    await ensureAccount(
      code: '52005',
      nameAr: 'مصاريف عمومية وإدارية (General Expenses)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 3,
      allowPosting: true,
      parentCode: '52',
    );
    await ensureAccount(
      code: '53',
      nameAr: 'خصم مسموح به (Discounts Allowed)',
      typeId: 5,
      normalBalance: 'Debit',
      level: 2,
      allowPosting: true,
      parentCode: '5',
    );

    // 7. Seed Mandatory Account Mappings
    final mappings = [
      {'key': 'cash_main', 'name': 'الصندوق الرئيسي', 'id': cashMainId},
      {'key': 'bank_main', 'name': 'الحساب البنكي الرئيسي', 'id': bankMainId},
      {'key': 'accounts_receivable', 'name': 'ذمم العملاء (AR)', 'id': arId},
      {'key': 'inventory_asset', 'name': 'أصول المخزون', 'id': invId},
      {'key': 'accounts_payable', 'name': 'ذمم الموردين (AP)', 'id': apId},
      {'key': 'sales_revenue', 'name': 'إيرادات المبيعات', 'id': salesRevId},
      {'key': 'cost_of_goods_sold', 'name': 'تكلفة البضاعة المباعة', 'id': cogsId},
      {'key': 'cogs', 'name': 'تكلفة البضاعة المباعة (مختصر)', 'id': cogsId},
      {'key': 'inventory_adjustment_loss', 'name': 'خسائر وتلف المخزون', 'id': stockLossId},
      {'key': 'owner_equity', 'name': 'رأس المال', 'id': capitalId},
      {'key': 'retained_earnings', 'name': 'الأرباح المرحلة', 'id': retainedEarningsId},
    ];

    for (final m in mappings) {
      final key = m['key']!;
      final existingMap = await (_db.select(_db.accountMappings)
            ..where((map) =>
                map.businessId.equals(businessId) & map.mappingKey.equals(key)))
          .getSingleOrNull();

      if (existingMap == null) {
        await _db.into(_db.accountMappings).insert(
              AccountMappingsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                mappingKey: key,
                mappingName: m['name']!,
                chartOfAccountId: m['id']!,
              ),
            );
      }
    }
  }
}
