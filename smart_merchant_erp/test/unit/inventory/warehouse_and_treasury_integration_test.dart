import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/seeders/default_coa_seeder.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();
  const testBusinessId = 'biz-warehouse-test';

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Warehouse & Treasury Yemeni Localization Suite', () {
    test('Warehouse seeding creates default warehouse accessible without branch restriction', () async {
      final seeder = DefaultChartOfAccountsSeeder(db);
      await seeder.seedChartOfAccounts(businessId: testBusinessId);

      // Verify branches table has a valid branch
      final branches = await (db.select(db.branches)
            ..where((b) => b.businessId.equals(testBusinessId)))
          .get();
      expect(branches, isNotEmpty);

      // Verify default warehouse was created
      final warehouses = await (db.select(db.warehouses)
            ..where((w) => w.businessId.equals(testBusinessId)))
          .get();
      expect(warehouses, isNotEmpty);
      expect(warehouses.first.isDefault, isTrue);
      expect(warehouses.first.warehouseName, 'المخزن الرئيسي');

      // Test InventoryDao.listWarehouses with WarehouseFilter without branchId
      final dao = InventoryDao(db);
      final allWarehouses = await dao.listWarehouses(
        const WarehouseFilter(businessId: testBusinessId, isActive: true),
      );
      expect(allWarehouses, isNotEmpty);
      expect(allWarehouses.first.warehouseCode, 'WH-01');
    });

    test('Creating a new warehouse and changing default warehouse unsets previous default', () async {
      final seeder = DefaultChartOfAccountsSeeder(db);
      await seeder.seedChartOfAccounts(businessId: testBusinessId);

      final branch = (await (db.select(db.branches)
            ..where((b) => b.businessId.equals(testBusinessId)))
          .get()).first;

      // Create a second warehouse
      final whId2 = uuid.v4();
      await db.into(db.warehouses).insert(
        WarehousesCompanion.insert(
          id: whId2,
          businessId: testBusinessId,
          branchId: branch.id,
          warehouseName: 'مستودع فرع التحرير',
          warehouseCode: 'WH-02',
          isDefault: const drift.Value(true),
          isActive: const drift.Value(true),
        ),
      );

      // Unset previous default
      await (db.update(db.warehouses)
            ..where((w) => w.businessId.equals(testBusinessId) & w.id.equals(whId2).not()))
          .write(const WarehousesCompanion(isDefault: drift.Value(false)));

      final allWarehouses = await (db.select(db.warehouses)
            ..where((w) => w.businessId.equals(testBusinessId)))
          .get();
      expect(allWarehouses.length, 2);

      final defaultWh = allWarehouses.firstWhere((w) => w.isDefault);
      expect(defaultWh.id, whId2);
      expect(defaultWh.warehouseName, 'مستودع فرع التحرير');
    });

    test('Cash Register creation satisfies branches foreign key constraint with zero failures', () async {
      final seeder = DefaultChartOfAccountsSeeder(db);
      await seeder.seedChartOfAccounts(businessId: testBusinessId);

      final branches = await (db.select(db.branches)
            ..where((b) => b.businessId.equals(testBusinessId)))
          .get();
      expect(branches, isNotEmpty);

      // Insert a new Cash Register
      final regId = uuid.v4();
      final insertResult = await db.into(db.cashRegisters).insert(
        CashRegistersCompanion.insert(
          id: regId,
          businessId: testBusinessId,
          branchId: branches.first.id,
          currencyId: 'YER',
          registerName: 'صندوق كاشير الصباح',
          status: const drift.Value('Open'),
        ),
      );
      expect(insertResult, isPositive);

      final saved = await (db.select(db.cashRegisters)..where((r) => r.id.equals(regId))).getSingle();
      expect(saved.registerName, 'صندوق كاشير الصباح');
      expect(saved.branchId, branches.first.id);
    });

    test('Electronic Wallets (كريمي جوال) are seeded and created with WALLET description & 11103 COA code', () async {
      final seeder = DefaultChartOfAccountsSeeder(db);
      await seeder.seedChartOfAccounts(businessId: testBusinessId);

      // Verify Chart of Account 11103 exists for Electronic Wallets
      final walletCoa = await (db.select(db.chartOfAccounts)
            ..where((a) => a.businessId.equals(testBusinessId) & a.accountCode.equals('11103')))
          .getSingleOrNull();
      expect(walletCoa, isNotNull);
      expect(walletCoa!.accountCategory, 'DigitalWallet');

      // Verify seeded BankAccounts contains a WALLET entry (Kuraimi Jawwal)
      final allBankAccounts = await (db.select(db.bankAccounts)
            ..where((b) => b.businessId.equals(testBusinessId)))
          .get();
      expect(allBankAccounts, isNotEmpty);

      final kuraimiWallet = allBankAccounts.firstWhere((b) => b.description == 'WALLET');
      expect(kuraimiWallet.bankName, 'كريمي جوال');
      expect(kuraimiWallet.displayName, 'محفظة الكريمي مميز');
      expect(kuraimiWallet.accountNumber, '777000000');

      // Add a custom Yemeni wallet (e.g., CAC Bank Cash Wallet)
      final customWalletId = uuid.v4();
      await db.into(db.bankAccounts).insert(
        BankAccountsCompanion.insert(
          id: customWalletId,
          businessId: testBusinessId,
          currencyId: 'YER',
          accountNumber: '771234567',
          bankName: 'محفظة كاش',
          displayName: const drift.Value('محفظة كاش - كاك بنك'),
          description: const drift.Value('WALLET'),
          status: const drift.Value('Active'),
        ),
      );

      final walletsList = (await (db.select(db.bankAccounts)
            ..where((b) => b.businessId.equals(testBusinessId)))
          .get())
          .where((b) => b.description == 'WALLET')
          .toList();
      expect(walletsList.length, 2);
    });
  });
}
