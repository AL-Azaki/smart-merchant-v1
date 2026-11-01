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

    await _db.transaction(() async {
      // 0. Ensure currency exists
      await _db
          .into(_db.currencies)
          .insertOnConflictUpdate(
            CurrenciesCompanion.insert(
              id: currencyId,
              currencyCode: currencyId,
              currencyNameAr: currencyId == 'YER' ? 'ريال يمني' : currencyId,
              currencyNameEn: currencyId == 'YER' ? 'Yemeni Rial' : currencyId,
              currencySymbol: currencyId == 'YER' ? '﷼' : currencyId,
              isBaseCurrency: const Value(true),
              isActive: const Value(true),
            ),
          );

      // 0.1 Ensure user exists safely without UNIQUE constraint collision
      final existingQaUser = await (_db.select(_db.usersTable)
            ..where((u) => u.id.equals('qa-user-id')))
          .getSingleOrNull();

      if (existingQaUser == null) {
        final conflictingUsers = await (_db.select(_db.usersTable)
              ..where((u) => u.email.equals('admin@smartmerchant.com')))
            .get();
        for (final conflict in conflictingUsers) {
          await (_db.update(_db.usersTable)..where((u) => u.id.equals(conflict.id))).write(
            UsersTableCompanion(
              email: Value('old_${conflict.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}@smartmerchant.com'),
            ),
          );
        }

        await _db.into(_db.usersTable).insert(
          UsersTableCompanion.insert(
            id: const Value('qa-user-id'),
            email: 'admin@smartmerchant.com',
            passwordHash: '',
            firstName: 'المدير',
            lastName: 'العام',
            isActive: const Value(true),
          ),
        );
      }

      if (businessId != 'qa-business-id') {
        final tenantUserId = 'user-$businessId';
        final tenantCheck = await (_db.select(_db.usersTable)
              ..where((u) => u.id.equals(tenantUserId)))
            .getSingleOrNull();
        if (tenantCheck == null) {
          await _db.into(_db.usersTable).insert(
            UsersTableCompanion.insert(
              id: Value(tenantUserId),
              email: '$tenantUserId@smartmerchant.com',
              passwordHash: '',
              firstName: 'المدير',
              lastName: 'العام',
              isActive: const Value(true),
            ),
          );
        }
      }
      final effectiveUserId = businessId == 'qa-business-id' ? 'qa-user-id' : 'user-$businessId';

      // 0.2 Ensure accountsTable exists
      final dummyAccountId = 'system-account-$effectiveUserId';
      await _db
          .into(_db.accountsTable)
          .insertOnConflictUpdate(
            AccountsTableCompanion.insert(
              id: Value(dummyAccountId),
              ownerId: effectiveUserId,
              businessName: 'المتجر الرئيسي',
              businessType: 'Retail',
              defaultCurrency: currencyId,
            ),
          );

      // 0.3 Ensure business exists in businesses table
      await _db
          .into(_db.businesses)
          .insertOnConflictUpdate(
            BusinessesCompanion.insert(
              id: businessId,
              accountId: dummyAccountId,
              businessName: 'المتجر الرئيسي',
              businessType: const Value('Retail'),
              status: const Value('Active'),
            ),
          );

      // 0.4 Ensure branch exists in branches table
      if (businessId == 'qa-business-id') {
        await _db.into(_db.branches).insertOnConflictUpdate(
          BranchesCompanion.insert(
            id: 'qa-branch-id',
            businessId: businessId,
            branchName: 'الفرع الرئيسي',
            branchCode: 'MAIN',
            isActive: const Value(true),
          ),
        );
      }
      final defaultBranchId = 'branch-$businessId';
      await _db.into(_db.branches).insertOnConflictUpdate(
        BranchesCompanion.insert(
          id: defaultBranchId,
          businessId: businessId,
          branchName: 'الفرع الرئيسي',
          branchCode: 'MAIN-01',
          isActive: const Value(true),
        ),
      );
      final branchId = businessId == 'qa-business-id' ? 'qa-branch-id' : defaultBranchId;

      // Standard lookup data only; no sample balances, transactions or merchants.
      const types = [
        (1, 'Assets', 'الأصول', 'assets'),
        (2, 'Liabilities', 'الخصوم', 'liabilities'),
        (3, 'Equity', 'حقوق الملكية', 'equity'),
        (4, 'Revenue', 'الإيرادات', 'revenue'),
        (5, 'Expenses', 'المصروفات', 'expenses'),
      ];
      for (final type in types) {
        await _db
            .into(_db.accountTypes)
            .insert(
              AccountTypesCompanion.insert(
                id: Value(type.$1),
                nameEn: type.$2,
                nameAr: type.$3,
                slug: type.$4,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      // Check if COA is already initialized for this business
      final existingAccounts = await (_db.select(
        _db.chartOfAccounts,
      )..where((a) => a.businessId.equals(businessId))).get();

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
          final existing = existingAccounts.firstWhere(
            (a) => a.accountCode == code,
          );
          final legacyArabicName = existing.accountName
              .replaceAll(RegExp(r'\s*\([^)]*[A-Za-z][^)]*\)'), '')
              .trim();
          if (existing.isSystem &&
              legacyArabicName == nameAr &&
              existing.accountName != nameAr) {
            await (_db.update(_db.chartOfAccounts)..where(
                  (a) =>
                      a.id.equals(existing.id) &
                      a.businessId.equals(businessId),
                ))
                .write(
                  ChartOfAccountsCompanion(
                    accountName: Value(nameAr),
                    syncStatus: const Value('pending'),
                    version: Value(existing.version + 1),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
          }
          return codeToIdMap[code]!;
        }

        final id = _uuid.v4();
        final parentId = parentCode != null ? codeToIdMap[parentCode] : null;

        await _db
            .into(_db.chartOfAccounts)
            .insert(
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
        nameAr: 'الأصول',
        typeId: 1,
        normalBalance: 'Debit',
        level: 1,
        allowPosting: false,
      );
      await ensureAccount(
        code: '2',
        nameAr: 'الخصوم والالتزامات',
        typeId: 2,
        normalBalance: 'Credit',
        level: 1,
        allowPosting: false,
      );
      await ensureAccount(
        code: '3',
        nameAr: 'حقوق الملكية',
        typeId: 3,
        normalBalance: 'Credit',
        level: 1,
        allowPosting: false,
      );
      await ensureAccount(
        code: '4',
        nameAr: 'الإيرادات',
        typeId: 4,
        normalBalance: 'Credit',
        level: 1,
        allowPosting: false,
      );
      await ensureAccount(
        code: '5',
        nameAr: 'المصروفات',
        typeId: 5,
        normalBalance: 'Debit',
        level: 1,
        allowPosting: false,
      );

      // 2. Assets Sub-accounts
      await ensureAccount(
        code: '11',
        nameAr: 'الأصول المتداولة',
        typeId: 1,
        normalBalance: 'Debit',
        level: 2,
        allowPosting: false,
        parentCode: '1',
      );
      await ensureAccount(
        code: '111',
        nameAr: 'النقدية وما في حكمها',
        typeId: 1,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: false,
        parentCode: '11',
      );
      final cashMainId = await ensureAccount(
        code: '11101',
        nameAr: 'الصندوق الرئيسي',
        typeId: 1,
        normalBalance: 'Debit',
        level: 4,
        allowPosting: true,
        parentCode: '111',
        category: 'Cash',
      );
      final bankMainId = await ensureAccount(
        code: '11102',
        nameAr: 'الحساب البنكي الرئيسي',
        typeId: 1,
        normalBalance: 'Debit',
        level: 4,
        allowPosting: true,
        parentCode: '111',
        category: 'Bank',
      );
      final walletMainId = await ensureAccount(
        code: '11103',
        nameAr: 'المحافظ الإلكترونية',
        typeId: 1,
        normalBalance: 'Debit',
        level: 4,
        allowPosting: true,
        parentCode: '111',
        category: 'DigitalWallet',
      );
      await ensureAccount(
        code: '112',
        nameAr: 'المدينون وذمم العملاء',
        typeId: 1,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: false,
        parentCode: '11',
      );
      final arId = await ensureAccount(
        code: '11201',
        nameAr: 'ذمم العملاء',
        typeId: 1,
        normalBalance: 'Debit',
        level: 4,
        allowPosting: true,
        parentCode: '112',
        category: 'Receivable',
      );
      await ensureAccount(
        code: '113',
        nameAr: 'المخزون',
        typeId: 1,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: false,
        parentCode: '11',
      );
      final invId = await ensureAccount(
        code: '11301',
        nameAr: 'بضاعة المخزن الرئيسي',
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
        nameAr: 'الخصوم المتداولة',
        typeId: 2,
        normalBalance: 'Credit',
        level: 2,
        allowPosting: false,
        parentCode: '2',
      );
      await ensureAccount(
        code: '211',
        nameAr: 'الدائنون وذمم الموردين',
        typeId: 2,
        normalBalance: 'Credit',
        level: 3,
        allowPosting: false,
        parentCode: '21',
      );
      final apId = await ensureAccount(
        code: '21101',
        nameAr: 'ذمم الموردين',
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
        nameAr: 'رأس المال',
        typeId: 3,
        normalBalance: 'Credit',
        level: 2,
        allowPosting: true,
        parentCode: '3',
        category: 'Equity',
      );
      final retainedEarningsId = await ensureAccount(
        code: '32',
        nameAr: 'الأرباح المبقاة / المرحلة',
        typeId: 3,
        normalBalance: 'Credit',
        level: 2,
        allowPosting: true,
        parentCode: '3',
        category: 'Equity',
      );
      await ensureAccount(
        code: '33',
        nameAr: 'مسحوبات الشركاء',
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
        nameAr: 'إيرادات المبيعات',
        typeId: 4,
        normalBalance: 'Credit',
        level: 2,
        allowPosting: true,
        parentCode: '4',
        category: 'Revenue',
      );
      final discountReceivedId = await ensureAccount(
        code: '42',
        nameAr: 'إيرادات أخرى / خصم مكتسب',
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
        nameAr: 'تكلفة البضاعة المباعة',
        typeId: 5,
        normalBalance: 'Debit',
        level: 2,
        allowPosting: true,
        parentCode: '5',
        category: 'Expense',
      );
      await ensureAccount(
        code: '52',
        nameAr: 'مصروفات تشغيلية',
        typeId: 5,
        normalBalance: 'Debit',
        level: 2,
        allowPosting: false,
        parentCode: '5',
      );
      await ensureAccount(
        code: '52001',
        nameAr: 'إيجارات',
        typeId: 5,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: true,
        parentCode: '52',
      );
      await ensureAccount(
        code: '52002',
        nameAr: 'كهرباء ومياه',
        typeId: 5,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: true,
        parentCode: '52',
      );
      await ensureAccount(
        code: '52003',
        nameAr: 'رواتب وأجور',
        typeId: 5,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: true,
        parentCode: '52',
      );
      final stockLossId = await ensureAccount(
        code: '52004',
        nameAr: 'عجز وتلف المخزون',
        typeId: 5,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: true,
        parentCode: '52',
      );
      await ensureAccount(
        code: '52005',
        nameAr: 'مصاريف عمومية وإدارية',
        typeId: 5,
        normalBalance: 'Debit',
        level: 3,
        allowPosting: true,
        parentCode: '52',
      );
      final discountAllowedId = await ensureAccount(
        code: '53',
        nameAr: 'خصم مسموح به',
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
        {'key': 'accounts_receivable', 'name': 'ذمم العملاء', 'id': arId},
        {'key': 'inventory_asset', 'name': 'أصول المخزون', 'id': invId},
        {'key': 'accounts_payable', 'name': 'ذمم الموردين', 'id': apId},
        {'key': 'sales_revenue', 'name': 'إيرادات المبيعات', 'id': salesRevId},
        {
          'key': 'cost_of_goods_sold',
          'name': 'تكلفة البضاعة المباعة',
          'id': cogsId,
        },
        {'key': 'cogs', 'name': 'تكلفة البضاعة المباعة (مختصر)', 'id': cogsId},
        {
          'key': 'inventory_adjustment_loss',
          'name': 'خسائر وتلف المخزون',
          'id': stockLossId,
        },
        {'key': 'owner_equity', 'name': 'رأس المال', 'id': capitalId},
        {
          'key': 'retained_earnings',
          'name': 'الأرباح المرحلة',
          'id': retainedEarningsId,
        },
        {
          'key': 'wallet_main',
          'name': 'المحافظ الإلكترونية',
          'id': walletMainId,
        },
        {
          'key': 'discount_allowed',
          'name': 'خصم مسموح به',
          'id': discountAllowedId,
        },
        {
          'key': 'discount_received',
          'name': 'خصم مكتسب',
          'id': discountReceivedId,
        },
      ];

      for (final m in mappings) {
        final key = m['key']!;
        final existingMap =
            await (_db.select(_db.accountMappings)..where(
                  (map) =>
                      map.businessId.equals(businessId) &
                      map.mappingKey.equals(key),
                ))
                .getSingleOrNull();

        if (existingMap == null) {
          await _db
              .into(_db.accountMappings)
              .insert(
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

      // 8. Seed Default Payment Methods (Cash, Bank/POS, Wallet)
      final existingMethods = await (_db.select(_db.paymentMethods)
            ..where((pm) => pm.businessId.equals(businessId)))
          .get();
      if (existingMethods.isEmpty) {
        await _db.into(_db.paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            chartOfAccountId: cashMainId,
            methodCode: 'CASH',
            methodName: 'نقدي (الصندوق الرئيسي)',
            paymentType: 'Cash',
            isActive: const Value(true),
          ),
        );
        await _db.into(_db.paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            chartOfAccountId: bankMainId,
            methodCode: 'BANK',
            methodName: 'شبكة / مدى / بنك',
            paymentType: 'Bank',
            isActive: const Value(true),
          ),
        );
        await _db.into(_db.paymentMethods).insert(
          PaymentMethodsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            chartOfAccountId: walletMainId,
            methodCode: 'WALLET',
            methodName: 'محفظة إلكترونية',
            paymentType: 'DigitalWallet',
            isActive: const Value(true),
          ),
        );
      }

      // 9. Seed Default Bank Account & Cash Register
      // 9. Seed Default Bank Account, Electronic Wallet, & Cash Register
      final existingBanks = await (_db.select(_db.bankAccounts)
            ..where((b) => b.businessId.equals(businessId)))
          .get();
      if (existingBanks.isEmpty) {
        await _db.into(_db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            currencyId: currencyId,
            accountNumber: 'BANK-001',
            bankName: 'الحساب البنكي الرئيسي (شبكة)',
            displayName: const Value('حساب البنك / نقاط البيع'),
            description: const Value('BANK'),
            isDefault: const Value(true),
            status: const Value('Active'),
          ),
        );
        await _db.into(_db.bankAccounts).insert(
          BankAccountsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            currencyId: currencyId,
            accountNumber: '777000000',
            bankName: 'كريمي جوال',
            displayName: const Value('محفظة الكريمي مميز'),
            description: const Value('WALLET'),
            isDefault: const Value(false),
            status: const Value('Active'),
          ),
        );
      }

      final existingRegisters = await (_db.select(_db.cashRegisters)
            ..where((r) => r.businessId.equals(businessId)))
          .get();
      if (existingRegisters.isEmpty) {
        await _db.into(_db.cashRegisters).insert(
          CashRegistersCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            branchId: branchId,
            currencyId: currencyId,
            registerName: 'الصندوق الرئيسي (كاشير)',
            status: const Value('Open'),
          ),
        );
      }

      // 10. Seed Default Open Fiscal Year & Fiscal Period (100% Arabic)
      final existingFy = await (_db.select(_db.fiscalYears)
            ..where((t) => t.businessId.equals(businessId) & t.status.equals('Open')))
          .getSingleOrNull();
      String fyId;
      final currentYear = DateTime.now().year;
      if (existingFy == null) {
        fyId = _uuid.v4();
        await _db.into(_db.fiscalYears).insert(
          FiscalYearsCompanion.insert(
            id: fyId,
            businessId: businessId,
            fiscalYearCode: 'FY-$currentYear',
            fiscalYearName: 'السنة المالية $currentYear',
            startDate: DateTime(currentYear, 1, 1),
            endDate: DateTime(currentYear, 12, 31),
            status: const Value('Open'),
          ),
        );
      } else {
        fyId = existingFy.id;
      }

      final existingFp = await (_db.select(_db.fiscalPeriods)
            ..where((t) => t.businessId.equals(businessId) & t.status.equals('Open')))
          .getSingleOrNull();
      if (existingFp == null) {
        await _db.into(_db.fiscalPeriods).insert(
          FiscalPeriodsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            fiscalYearId: fyId,
            periodNumber: 1,
            periodName: 'الفترة المالية $currentYear',
            startDate: DateTime(currentYear, 1, 1),
            endDate: DateTime(currentYear, 12, 31),
            status: const Value('Open'),
          ),
        );
      }

      // 11. Seed Default Main Warehouse if none exists
      final existingWarehouses = await (_db.select(_db.warehouses)
            ..where((w) => w.businessId.equals(businessId)))
          .get();
      if (existingWarehouses.isEmpty) {
        await _db.into(_db.warehouses).insert(
          WarehousesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            branchId: branchId,
            warehouseName: 'المخزن الرئيسي',
            warehouseCode: 'WH-01',
            isDefault: const Value(true),
            isActive: const Value(true),
          ),
        );
      }

      // 12. Seed Default Standard Units if none exists
      final existingUnits = await (_db.select(_db.units)
            ..where((u) => u.businessId.equals(businessId)))
          .get();
      if (existingUnits.isEmpty) {
        final defaultUnits = [
          ('حبة', 'حبة', 'وحدة مفردة'),
          ('قطعة', 'قطعة', 'قطعة منفردة'),
          ('كرتون', 'كرتون', 'صندوق / كرتون'),
          ('كيلو', 'كجم', 'كيلوجرام بالوزن'),
          ('درزن', 'درزن', 'مجموعة 12 حبة'),
          ('لتر', 'لتر', 'لتر سوائل'),
        ];
        for (final u in defaultUnits) {
          await _db.into(_db.units).insert(
            UnitsCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              unitName: u.$1,
              unitSymbol: u.$2,
              unitDescription: Value(u.$3),
              isActive: const Value(true),
            ),
          );
        }
      }

      // 13. Seed Default Standard Categories if none exists
      final existingCategories = await (_db.select(_db.categories)
            ..where((c) => c.businessId.equals(businessId)))
          .get();
      if (existingCategories.isEmpty) {
        final defaultCategories = [
          ('عام', 'GEN', 'تصنيف عام للمنتجات المتنوعة'),
          ('مواد غذائية', 'FOOD', 'المواد التموينية والأغذية المعلبة'),
          ('مشروبات وعصائر', 'DRINKS', 'المياه والمشروبات الغازية والعصائر'),
          ('منظفات ومنزليات', 'CLEAN', 'أدوات التنظيف والمستلزمات المنزلية'),
          ('بقوليات وحبوب', 'GRAIN', 'الأرز والسكر والدقيق والحبوب'),
          ('خضار وفواكه', 'PRODUCE', 'الخضروات والفواكه الطازجة'),
        ];
        for (final cat in defaultCategories) {
          await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              categoryName: cat.$1,
              categoryCode: Value(cat.$2),
              description: Value(cat.$3),
              isActive: const Value(true),
            ),
          );
        }
      }
    });
  }
}
