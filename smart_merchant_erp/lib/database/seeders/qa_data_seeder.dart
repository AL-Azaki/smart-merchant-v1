import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../kernel/storage/app_database.dart';
import '../../database/enums/inventory_transaction_type.dart';
import '../../database/enums/inventory_movement_direction.dart';
import '../../database/enums/inventory_transaction_status.dart';

/// Idempotent QA Data Seeder for Smart Merchant ERP
class QaDataSeeder {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  QaDataSeeder(this._db);

  Future<void> seedAll({
    String accountId = 'qa-account-id',
    String businessId = 'qa-business-id',
    String branchId = 'qa-branch-id',
    String userId = 'qa-user-id',
  }) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      const currencyId = 'YER';

      // 1. Foundation & Auth
      final userCount = await (_db.select(_db.usersTable)..where((t) => t.id.equals(userId))).get();
      if (userCount.isEmpty) {
        await _db.into(_db.usersTable).insert(UsersTableCompanion.insert(
          id: Value(userId),
          email: 'admin@smartmerchant.com',
          passwordHash: 'hashed_password',
          firstName: 'QA',
          lastName: 'Admin',
          isActive: const Value(true),
        ));
      }

      final accountCount = await (_db.select(_db.accountsTable)..where((t) => t.id.equals(accountId))).get();
      if (accountCount.isEmpty) {
        await _db.into(_db.accountsTable).insert(AccountsTableCompanion.insert(
          id: Value(accountId),
          ownerId: userId,
          businessName: 'Smart Merchant QA Account',
          businessType: 'Retail',
          defaultCurrency: 'YER',
        ));
      }

      final currencyCount = await (_db.select(_db.currencies)..where((t) => t.id.equals(currencyId))).get();
      if (currencyCount.isEmpty) {
        await _db.into(_db.currencies).insert(CurrenciesCompanion.insert(
          id: currencyId,
          currencyCode: 'YER',
          currencyNameAr: 'ريال يمني',
          currencyNameEn: 'Yemeni Rial',
          currencySymbol: '﷼',
          isBaseCurrency: const Value(true),
          isActive: const Value(true),
        ));
        await _db.into(_db.currencies).insert(CurrenciesCompanion.insert(
          id: 'SAR',
          currencyCode: 'SAR',
          currencyNameAr: 'ريال سعودي',
          currencyNameEn: 'Saudi Riyal',
          currencySymbol: 'ر.س',
          isBaseCurrency: const Value(false),
          isActive: const Value(true),
        ));
        await _db.into(_db.currencies).insert(CurrenciesCompanion.insert(
          id: 'USD',
          currencyCode: 'USD',
          currencyNameAr: 'دولار أمريكي',
          currencyNameEn: 'US Dollar',
          currencySymbol: '\$',
          isBaseCurrency: const Value(false),
          isActive: const Value(true),
        ));
      }

      final businessCount = await (_db.select(_db.businesses)..where((t) => t.id.equals(businessId))).get();
      if (businessCount.isEmpty) {
        await _db.into(_db.businesses).insert(BusinessesCompanion.insert(
          id: businessId,
          accountId: accountId,
          businessName: 'Smart Merchant QA Business',
          status: const Value('Active'),
        ));
      }

      final branchCount = await (_db.select(_db.branches)..where((t) => t.id.equals(branchId))).get();
      if (branchCount.isEmpty) {
        await _db.into(_db.branches).insert(BranchesCompanion.insert(
          id: branchId,
          businessId: businessId,
          branchName: 'Main QA Branch',
          branchCode: 'MAIN-001',
          isActive: const Value(true),
        ));
      }

      // 2. Accounting Infrastructure
      final types = [
        {'id': 1, 'slug': 'assets', 'en': 'Assets', 'ar': 'الأصول'},
        {'id': 2, 'slug': 'liabilities', 'en': 'Liabilities', 'ar': 'الخصوم'},
        {'id': 3, 'slug': 'equity', 'en': 'Equity', 'ar': 'حقوق الملكية'},
        {'id': 4, 'slug': 'revenue', 'en': 'Revenue', 'ar': 'الإيرادات'},
        {'id': 5, 'slug': 'expenses', 'en': 'Expenses', 'ar': 'المصروفات'},
      ];

      for (var type in types) {
        final exists = await (_db.select(_db.accountTypes)..where((t) => t.id.equals(type['id'] as int))).getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.accountTypes).insert(AccountTypesCompanion.insert(
            id: Value(type['id'] as int),
            nameEn: type['en'] as String,
            nameAr: type['ar'] as String,
            slug: type['slug'] as String,
            isActive: const Value(true),
          ));
        }
      }

      final coa = [
        {'id': 'coa-cash', 'code': '1001', 'name': 'Cash in Hand', 'type': 1, 'balance': 'Debit'},
        {'id': 'coa-bank', 'code': '1002', 'name': 'Bank Account', 'type': 1, 'balance': 'Debit'},
        {'id': 'coa-ar', 'code': '1101', 'name': 'Accounts Receivable', 'type': 1, 'balance': 'Debit'},
        {'id': 'coa-inv', 'code': '1201', 'name': 'Inventory Asset', 'type': 1, 'balance': 'Debit'},
        {'id': 'coa-ap', 'code': '2001', 'name': 'Accounts Payable', 'type': 2, 'balance': 'Credit'},
        {'id': 'coa-tax', 'code': '2101', 'name': 'Tax Payable', 'type': 2, 'balance': 'Credit'},
        {'id': 'coa-sales', 'code': '4001', 'name': 'Sales Revenue', 'type': 4, 'balance': 'Credit'},
        {'id': 'coa-inv-gain', 'code': '4101', 'name': 'Inventory Gain', 'type': 4, 'balance': 'Credit'},
        {'id': 'coa-cogs', 'code': '5001', 'name': 'Cost of Goods Sold', 'type': 5, 'balance': 'Debit'},
        {'id': 'coa-inv-loss', 'code': '5101', 'name': 'Inventory Loss', 'type': 5, 'balance': 'Debit'},
      ];

      for (var account in coa) {
        final exists = await (_db.select(_db.chartOfAccounts)..where((t) => t.id.equals(account['id'] as String))).getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.chartOfAccounts).insert(ChartOfAccountsCompanion.insert(
            id: account['id'] as String,
            businessId: businessId,
            accountCode: account['code'] as String,
            accountName: account['name'] as String,
            accountTypeId: account['type'] as int,
            normalBalance: account['balance'] as String,
            allowPosting: const Value(true),
            isActive: const Value(true),
          ));
        }
      }

      final mappings = [
        {'key': 'accounts_receivable', 'acc_id': 'coa-ar', 'name': 'Accounts Receivable'},
        {'key': 'accounts_payable', 'acc_id': 'coa-ap', 'name': 'Accounts Payable'},
        {'key': 'sales_revenue', 'acc_id': 'coa-sales', 'name': 'Sales Revenue'},
        {'key': 'inventory_asset', 'acc_id': 'coa-inv', 'name': 'Inventory Asset'},
        {'key': 'inventory_adjustment_loss', 'acc_id': 'coa-inv-loss', 'name': 'Inventory Loss'},
        {'key': 'inventory_adjustment_gain', 'acc_id': 'coa-inv-gain', 'name': 'Inventory Gain'},
        {'key': 'cost_of_goods_sold', 'acc_id': 'coa-cogs', 'name': 'Cost of Goods Sold'},
        {'key': 'tax_payable', 'acc_id': 'coa-tax', 'name': 'Tax Payable'},
      ];

      for (var mapping in mappings) {
        final exists = await (_db.select(_db.accountMappings)..where((t) => t.mappingKey.equals(mapping['key'] as String))).getSingleOrNull();
        if (exists == null) {
          await _db.into(_db.accountMappings).insert(AccountMappingsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            mappingKey: mapping['key'] as String,
            mappingName: mapping['name'] as String,
            chartOfAccountId: mapping['acc_id'] as String,
          ));
        }
      }

      const fyId = 'fy-2026';
      final fyExists = await (_db.select(_db.fiscalYears)..where((t) => t.id.equals(fyId))).getSingleOrNull();
      if (fyExists == null) {
        await _db.into(_db.fiscalYears).insert(FiscalYearsCompanion.insert(
          id: fyId,
          businessId: businessId,
          fiscalYearCode: 'FY-2026',
          fiscalYearName: 'Fiscal Year 2026',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 12, 31),
          status: const Value('Open'),
        ));
      }

      const fpId = 'fp-2026-07';
      final fpExists = await (_db.select(_db.fiscalPeriods)..where((t) => t.id.equals(fpId))).getSingleOrNull();
      if (fpExists == null) {
        await _db.into(_db.fiscalPeriods).insert(FiscalPeriodsCompanion.insert(
          id: fpId,
          businessId: businessId,
          fiscalYearId: fyId,
          periodNumber: 7,
          periodName: 'July 2026',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
          status: const Value('Open'),
        ));
      }

      const pmCashId = 'pm-cash';
      final pmExists = await (_db.select(_db.paymentMethods)..where((t) => t.id.equals(pmCashId))).getSingleOrNull();
      if (pmExists == null) {
        await _db.into(_db.paymentMethods).insert(PaymentMethodsCompanion.insert(
          id: pmCashId,
          businessId: businessId,
          chartOfAccountId: 'coa-cash',
          methodCode: 'CASH',
          methodName: 'Cash',
          paymentType: 'Cash',
          isActive: const Value(true),
        ));
      }
      
      const pmBankId = 'pm-bank';
      final pmBankExists = await (_db.select(_db.paymentMethods)..where((t) => t.id.equals(pmBankId))).getSingleOrNull();
      if (pmBankExists == null) {
        await _db.into(_db.paymentMethods).insert(PaymentMethodsCompanion.insert(
          id: pmBankId,
          businessId: businessId,
          chartOfAccountId: 'coa-bank',
          methodCode: 'BANK',
          methodName: 'Bank Transfer',
          paymentType: 'Bank',
          isActive: const Value(true),
        ));
      }

      const whId = 'wh-qa-main';
      final whExists = await (_db.select(_db.warehouses)..where((t) => t.id.equals(whId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (whExists == null) {
        await _db.into(_db.warehouses).insert(WarehousesCompanion.insert(
          id: whId,
          businessId: businessId,
          branchId: branchId,
          warehouseName: 'Main QA Warehouse',
          warehouseCode: 'WH-QA-01',
          isDefault: const Value(true),
          isActive: const Value(true),
        ));
      }

      const catId = 'cat-groceries';
      final catExists = await (_db.select(_db.categories)..where((t) => t.id.equals(catId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (catExists == null) {
        await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: catId,
          businessId: businessId,
          categoryName: 'Groceries / المواد الغذائية',
          categoryCode: const Value('GROC'),
          isActive: const Value(true),
        ));
      }

      final units = [
        {'id': 'unit-pcs', 'name': 'Piece / حبة', 'symbol': 'PCS'},
        {'id': 'unit-kg', 'name': 'Kilogram / كجم', 'symbol': 'KG'},
        {'id': 'unit-ltr', 'name': 'Liter / لتر', 'symbol': 'LTR'},
      ];

      for (var u in units) {
        final uExists = await (_db.select(_db.units)..where((t) => t.id.equals(u['id']!) & t.businessId.equals(businessId))).getSingleOrNull();
        if (uExists == null) {
          await _db.into(_db.units).insert(UnitsCompanion.insert(
            id: u['id']!,
            businessId: businessId,
            unitName: u['name']!,
            unitSymbol: u['symbol']!,
            isActive: const Value(true),
          ));
        }
      }

      final qaProducts = [
        {'id': 'prod-qa-01', 'name': 'مياه معدنية 500 مل', 'unit': 'unit-pcs', 'price': 150.0, 'stock': 100.0, 'code': 'QA-WATER'},
        {'id': 'prod-qa-02', 'name': 'حليب كامل الدسم', 'unit': 'unit-pcs', 'price': 550.0, 'stock': 50.0, 'code': 'QA-MILK'},
        {'id': 'prod-qa-03', 'name': 'عصير برتقال', 'unit': 'unit-pcs', 'price': 400.0, 'stock': 40.0, 'code': 'QA-JUICE'},
        {'id': 'prod-qa-04', 'name': 'أرز 5 كجم', 'unit': 'unit-pcs', 'price': 3500.0, 'stock': 30.0, 'code': 'QA-RICE'},
        {'id': 'prod-qa-05', 'name': 'سكر 1 كجم', 'unit': 'unit-kg', 'price': 800.0, 'stock': 60.0, 'code': 'QA-SUGAR'},
        {'id': 'prod-qa-06', 'name': 'زيت طبخ 1 لتر', 'unit': 'unit-ltr', 'price': 1200.0, 'stock': 35.0, 'code': 'QA-OIL'},
        {'id': 'prod-qa-07', 'name': 'دقيق 1 كجم', 'unit': 'unit-kg', 'price': 750.0, 'stock': 45.0, 'code': 'QA-FLOUR'},
        {'id': 'prod-qa-08', 'name': 'شاي', 'unit': 'unit-pcs', 'price': 500.0, 'stock': 25.0, 'code': 'QA-TEA'},
        {'id': 'prod-qa-09', 'name': 'قهوة', 'unit': 'unit-pcs', 'price': 1500.0, 'stock': 20.0, 'code': 'QA-COFFEE'},
        {'id': 'prod-qa-10', 'name': 'بسكويت', 'unit': 'unit-pcs', 'price': 200.0, 'stock': 80.0, 'code': 'QA-BISCUIT'},
        {'id': 'prod-qa-11', 'name': 'صابون', 'unit': 'unit-pcs', 'price': 300.0, 'stock': 100.0, 'code': 'QA-SOAP'},
        {'id': 'prod-qa-12', 'name': 'مناديل ورقية', 'unit': 'unit-pcs', 'price': 150.0, 'stock': 100.0, 'code': 'QA-TISSUE'},
      ];

      for (var p in qaProducts) {
        final pId = p['id'] as String;
        final pName = p['name'] as String;
        final pCode = p['code'] as String;
        final pUnit = p['unit'] as String;
        final pPrice = p['price'] as double;
        final pStock = p['stock'] as double;

        final prodExists = await (_db.select(_db.products)..where((t) => t.id.equals(pId) & t.businessId.equals(businessId))).getSingleOrNull();
        if (prodExists == null) {
          await _db.into(_db.products).insert(ProductsCompanion.insert(
            id: pId,
            businessId: businessId,
            categoryId: Value(catId),
            productType: const Value('standard'),
            productName: pName,
            productCode: pCode,
            isActive: const Value(true),
          ));
        }

        final pUnitId = 'pu-$pId';
        final puExists = await (_db.select(_db.productUnits)..where((t) => t.id.equals(pUnitId) & t.businessId.equals(businessId))).getSingleOrNull();
        if (puExists == null) {
          await _db.into(_db.productUnits).insert(ProductUnitsCompanion.insert(
            id: pUnitId,
            businessId: businessId,
            productId: pId,
            unitId: pUnit,
            sku: Value('$pId-BASE'),
            barcode: Value('123456$pId'),
            conversionFactor: const Value(1.0),
            isBaseUnit: const Value(true),
            sellingPrice: Value(pPrice), 
            purchasePrice: Value(pPrice * 0.7), 
            isActive: const Value(true),
          ));
        }

        final invExists = await (_db.select(_db.inventories)..where((t) => t.productUnitId.equals(pUnitId) & t.businessId.equals(businessId))).getSingleOrNull();
        if (invExists == null) {
          final invId = 'inv-$pId';
          await _db.into(_db.inventories).insert(InventoriesCompanion.insert(
            id: invId,
            businessId: businessId,
            warehouseId: whId,
            productUnitId: pUnitId,
            quantity: Value(pStock),
            averageCost: Value(pPrice * 0.7),
          ));

          final txnId = _uuid.v4();
          await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
            id: txnId,
            businessId: businessId,
            branchId: branchId,
            transactionType: InventoryTransactionType.openingBalance,
            movementDirection: InventoryMovementDirection.inbound,
            transactionDate: Value(now),
            status: const Value(InventoryTransactionStatus.posted),
            warehouseId: whId,
            createdBy: userId,
          ));

          await _db.into(_db.inventoryTransactionLines).insert(InventoryTransactionLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            inventoryTransactionId: txnId,
            productUnitId: pUnitId,
            quantity: pStock,
            unitCost: Value(pPrice * 0.7),
          ));
        }
      }

      const seqId = 'seq-inv';
      final seqExists = await (_db.select(_db.sequences)..where((t) => t.id.equals(seqId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (seqExists == null) {
        await _db.into(_db.sequences).insert(SequencesCompanion.insert(
          id: seqId,
          businessId: businessId,
          branchId: Value(branchId),
          documentType: 'SalesInvoice',
          prefix: const Value('INV-2026-'),
          currentValue: const Value(0),
          step: const Value(1),
          padding: const Value(5),
        ));
      }
      
      const seqRecId = 'seq-rec';
      final seqRecExists = await (_db.select(_db.sequences)..where((t) => t.id.equals(seqRecId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (seqRecExists == null) {
        await _db.into(_db.sequences).insert(SequencesCompanion.insert(
          id: seqRecId,
          businessId: businessId,
          branchId: Value(branchId),
          documentType: 'CustomerReceivable',
          prefix: const Value('REC-'),
          currentValue: const Value(0),
          step: const Value(1),
          padding: const Value(5),
        ));
      }

      const custId = 'cust-qa-01';
      final custExists = await (_db.select(_db.customers)..where((t) => t.id.equals(custId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (custExists == null) {
        await _db.into(_db.customers).insert(CustomersCompanion.insert(
          id: custId,
          businessId: businessId,
          customerName: 'Customer QA',
          isActive: const Value(true),
        ));
      }

      const supId = 'supplier-qa-01';
      final supExists = await (_db.select(_db.suppliers)..where((t) => t.id.equals(supId) & t.businessId.equals(businessId))).getSingleOrNull();
      if (supExists == null) {
        await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
          id: supId,
          businessId: businessId,
          supplierName: 'Supplier QA',
          isActive: const Value(true),
        ));
      }

      final qaEmployees = [
        {'id': 'emp-qa-01', 'name': 'أحمد محمد', 'code': 'مدير مبيعات', 'phone': '770000001', 'salary': 150000.0, 'status': 'Active'},
        {'id': 'emp-qa-02', 'name': 'سعيد علي', 'code': 'كاشير', 'phone': '770000002', 'salary': 80000.0, 'status': 'Active'},
        {'id': 'emp-qa-03', 'name': 'فاطمة صالح', 'code': 'محاسبة', 'phone': '770000003', 'salary': 120000.0, 'status': 'OnLeave'},
      ];

      for (var e in qaEmployees) {
        final eId = e['id'] as String;
        final empExists = await (_db.select(_db.employees)..where((t) => t.id.equals(eId) & t.businessId.equals(businessId))).getSingleOrNull();
        if (empExists == null) {
          await _db.into(_db.employees).insert(EmployeesCompanion.insert(
            id: eId,
            businessId: businessId,
            employeeCode: e['code'] as String,
            firstName: e['name'] as String,
            lastName: '',
            hireDate: now,
            phone: Value(e['phone'] as String),
            salary: Value(e['salary'] as double),
            status: Value(e['status'] as String),
            currencyId: 'YER',
          ));
        }
      }
    });
  }
}
