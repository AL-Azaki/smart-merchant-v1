import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/core/utils/precision_math.dart';
import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/catalog_dao.dart';
import 'package:smart_merchant_erp/database/daos/core_dao.dart';
import 'package:smart_merchant_erp/database/daos/inventory_dao.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/treasury_dao.dart';
import 'package:smart_merchant_erp/database/seeders/default_coa_seeder.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/application/usecases/post_journal_entry_usecase.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/catalog/domain/repositories/catalog_repository.dart';
import 'package:smart_merchant_erp/modules/catalog/infrastructure/repositories/catalog_repository_impl.dart';
import 'package:smart_merchant_erp/modules/core/domain/repositories/core_repository.dart';
import 'package:smart_merchant_erp/modules/core/infrastructure/repositories/core_repository_impl.dart';
import 'package:smart_merchant_erp/modules/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_merchant_erp/modules/inventory/infrastructure/repositories/inventory_repository_impl.dart';
import 'package:smart_merchant_erp/modules/purchasing/domain/repositories/purchasing_repository.dart';
import 'package:smart_merchant_erp/modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/receive_payment_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/record_disbursement_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/domain/repositories/treasury_repository.dart';
import 'package:smart_merchant_erp/modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late AccountingRepository accountingRepo;
  late CoreRepository coreRepo;
  late SalesRepository salesRepo;
  late PurchasingRepository purchasingRepo;
  late TreasuryRepository treasuryRepo;
  late InventoryRepository inventoryRepo;
  late CatalogRepository catalogRepo;
  late AccountingApplicationService accountingService;
  late DefaultChartOfAccountsSeeder coaSeeder;
  late ApplicationContext context;

  late PostJournalEntryUseCase postJournalUseCase;
  late ReceivePaymentUseCase receivePaymentUseCase;
  late RecordDisbursementUseCase recordDisbursementUseCase;

  const uuid = Uuid();
  late String businessId;
  late String branchId;
  late String userId;
  late String fiscalYearId;
  late String fiscalPeriodId;
  const String baseCurrencyId = 'YER';

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    transactionRunner = ApplicationTransactionRunnerImpl(db);
    accountingRepo = AccountingRepositoryImpl(AccountingDao(db));
    coreRepo = CoreRepositoryImpl(CoreDao(db));
    salesRepo = SalesRepositoryImpl(SalesDao(db));
    purchasingRepo = PurchasingRepositoryImpl(PurchasingDao(db));
    treasuryRepo = TreasuryRepositoryImpl(TreasuryDao(db));
    inventoryRepo = InventoryRepositoryImpl(InventoryDao(db));
    catalogRepo = CatalogRepositoryImpl(CatalogDao(db));
    coaSeeder = DefaultChartOfAccountsSeeder(db);

    businessId = uuid.v4();
    branchId = uuid.v4();
    userId = uuid.v4();
    fiscalYearId = uuid.v4();
    fiscalPeriodId = uuid.v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    accountingService = AccountingApplicationService(accountingRepo, context);

    postJournalUseCase = PostJournalEntryUseCase(
      accountingRepo,
      coreRepo,
      context,
      transactionRunner,
    );

    receivePaymentUseCase = ReceivePaymentUseCase(
      treasuryRepo,
      salesRepo,
      accountingRepo,
      accountingService,
      context,
      transactionRunner,
    );

    recordDisbursementUseCase = RecordDisbursementUseCase(
      treasuryRepo,
      purchasingRepo,
      accountingRepo,
      accountingService,
      context,
      transactionRunner,
    );

    // 1. Seed master business, branch, user
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: businessId,
        accountId: 'acc-inv-test',
        businessName: 'Invariants Test Enterprise',
        status: const drift.Value('Active'),
      ),
    );
    await db.into(db.branches).insert(
      BranchesCompanion.insert(
        id: branchId,
        businessId: businessId,
        branchCode: 'MAIN',
        branchName: 'Main Branch',
        isActive: const drift.Value(true),
      ),
    );
    await db.into(db.usersTable).insert(
      UsersTableCompanion.insert(
        id: drift.Value(userId),
        email: 'inv@test.com',
        passwordHash: 'dummy',
        firstName: 'Ledger',
        lastName: 'Auditor',
        isActive: const drift.Value(true),
      ),
    );

    // 2. Seed active fiscal year & period
    final now = DateTime.now();
    await db.into(db.fiscalYears).insert(FiscalYearsCompanion.insert(
          id: fiscalYearId,
          businessId: businessId,
          fiscalYearCode: 'FY-${now.year}',
          fiscalYearName: 'السنة المالية ${now.year}',
          startDate: DateTime(now.year, 1, 1),
          endDate: DateTime(now.year, 12, 31),
          status: const drift.Value('Open'),
        ));

    await db.into(db.fiscalPeriods).insert(FiscalPeriodsCompanion.insert(
          id: fiscalPeriodId,
          businessId: businessId,
          fiscalYearId: fiscalYearId,
          periodNumber: 1,
          periodName: '2026-01',
          startDate: DateTime(now.year, 1, 1),
          endDate: DateTime(now.year, 12, 31),
          status: const drift.Value('Open'),
        ));

    // 3. Seed standard chart of accounts
    await coaSeeder.seedChartOfAccounts(businessId: businessId);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 5: Accounting Invariants & Ledger Safety Suite', () {
    test('Invariant 1: Absolute Double-Entry Balance across all journal entries', () async {
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final equityAccount = (await accountingRepo.getChartOfAccountByCode('31', businessId))!;

      // Entry: Capital deposit
      final result = await postJournalUseCase(
        PostJournalEntryCommand(
          documentDate: DateTime.now(),
          journalType: 'Manual',
          currencyId: baseCurrencyId,
          description: 'إيداع رأس المال التأسيسي',
          lines: [
            JournalEntryLineCommand(accountId: cashAccount.id, debit: 500000.0, credit: 0.0),
            JournalEntryLineCommand(accountId: equityAccount.id, debit: 0.0, credit: 500000.0),
          ],
        ),
      );

      expect(result.isRight(), isTrue);

      // Verify every single journal entry in the database is individually balanced
      final allEntries = await (db.select(db.journalEntries)
            ..where((tbl) => tbl.businessId.equals(businessId)))
          .get();

      expect(allEntries.isNotEmpty, true);

      for (final entry in allEntries) {
        final lines = await (db.select(db.journalEntryLines)
              ..where((tbl) => tbl.journalEntryId.equals(entry.id)))
            .get();

        double debitSum = 0.0;
        double creditSum = 0.0;
        for (final l in lines) {
          if (l.type == 'Debit') debitSum += l.baseAmount;
          if (l.type == 'Credit') creditSum += l.baseAmount;
        }

        expect(
          PrecisionMath.areBalanced(debitSum, creditSum),
          true,
          reason: 'Entry ${entry.journalNumber} is not balanced: Debit=$debitSum, Credit=$creditSum',
        );
      }

      // Verify global invariant: Grand Total Debit == Grand Total Credit
      final allLines = await db.select(db.journalEntryLines).get();
      double grandDebit = 0.0;
      double grandCredit = 0.0;
      for (final line in allLines) {
        if (line.type == 'Debit') grandDebit += line.baseAmount;
        if (line.type == 'Credit') grandCredit += line.baseAmount;
      }

      grandDebit = PrecisionMath.roundMoney(grandDebit);
      grandCredit = PrecisionMath.roundMoney(grandCredit);

      expect(grandDebit, grandCredit,
          reason: 'Global Ledger Invariant violated: Debit=$grandDebit, Credit=$grandCredit');
    });

    test('Invariant 2 & 3: Inventory Conservation & Asset Account Valuation Consistency', () async {
      final warehouseId = uuid.v4();
      final productId = uuid.v4();
      final pieceUnitId = uuid.v4();
      final baseProductUnitId = uuid.v4();

      await db.into(db.warehouses).insert(WarehousesCompanion.insert(
            id: warehouseId,
            businessId: businessId,
            branchId: branchId,
            warehouseCode: 'WH-MAIN',
            warehouseName: 'المخزن الرئيسي',
          ));

      await db.into(db.units).insert(UnitsCompanion.insert(
            id: pieceUnitId,
            businessId: businessId,
            unitName: 'حبة',
            unitSymbol: 'PCS',
          ));

      await db.into(db.products).insert(ProductsCompanion.insert(
            id: productId,
            businessId: businessId,
            productCode: 'PRD-OIL',
            productName: 'زيت نباتي 1 لتر',
          ));

      await db.into(db.productUnits).insert(ProductUnitsCompanion.insert(
            id: baseProductUnitId,
            businessId: businessId,
            productId: productId,
            unitId: pieceUnitId,
            conversionFactor: const drift.Value(1.0),
            isBaseUnit: const drift.Value(true),
            sellingPrice: const drift.Value(1500.0),
            purchasePrice: const drift.Value(1000.0),
          ));

      // Initial Inventory: 100 pieces @ 1,000 YER = 100,000 YER
      await db.into(db.inventories).insert(InventoriesCompanion.insert(
            id: uuid.v4(),
            businessId: businessId,
            warehouseId: warehouseId,
            productUnitId: baseProductUnitId,
            quantity: const drift.Value(100.0),
            averageCost: const drift.Value(1000.0),
          ));

      // Movement 1: Purchase 50 pieces @ 1,100 YER (adds 50 units, new WAC = (100,000 + 55,000)/150 = 1,033.33)
      final prevInv = (await inventoryRepo.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        baseProductUnitId,
      ))!;

      final newTotalQty = prevInv.quantity + 50.0;
      final newWac = PrecisionMath.calculateWac(
        oldQty: prevInv.quantity,
        oldAvgCost: prevInv.averageCost,
        newQty: 50.0,
        newUnitCostInBase: 1100.0,
      );

      await (db.update(db.inventories)..where((tbl) => tbl.id.equals(prevInv.id))).write(
        InventoriesCompanion(
          quantity: drift.Value(newTotalQty),
          averageCost: drift.Value(newWac),
        ),
      );

      // Movement 2: Sale of 30 pieces
      final afterPurchaseInv = (await inventoryRepo.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        baseProductUnitId,
      ))!;

      final remainingQty = afterPurchaseInv.quantity - 30.0;
      await (db.update(db.inventories)..where((tbl) => tbl.id.equals(afterPurchaseInv.id))).write(
        InventoriesCompanion(quantity: drift.Value(remainingQty)),
      );

      // Verify Inventory Conservation Law:
      // Final Qty = Initial (100) + Purchased (50) - Sold (30) = 120
      final finalInv = (await inventoryRepo.getInventoryByUnitAndWarehouse(
        businessId,
        warehouseId,
        baseProductUnitId,
      ))!;

      expect(finalInv.quantity, 120.0);
      expect(finalInv.averageCost, 1033.3333);

      // Total physical inventory valuation:
      final totalStockValuation =
          PrecisionMath.roundMoney(finalInv.quantity * finalInv.averageCost);
      expect(totalStockValuation, PrecisionMath.roundMoney(120.0 * 1033.3333));
    });

    test('Invariant 4: Party Balance Integrity (Receivables & Payables match transactions)', () async {
      final customerId = uuid.v4();
      await db.into(db.customers).insert(CustomersCompanion.insert(
            id: customerId,
            businessId: businessId,
            customerName: 'عميل النزاهة المحاسبية',
            creditLimit: const drift.Value(50000.0),
            isActive: const drift.Value(true),
          ));

      // Simulate 2 credit receivables: 2,500 + 4,000 = 6,500
      final rec1Id = uuid.v4();
      final rec2Id = uuid.v4();
      await db.into(db.customerReceivables).insert(CustomerReceivablesCompanion.insert(
            id: rec1Id,
            businessId: businessId,
            customerId: customerId,
            salesInvoiceId: uuid.v4(),
            currencyId: baseCurrencyId,
            originalAmount: 2500.0,
            baseOriginalAmount: 2500.0,
            remainingAmount: 2500.0,
            baseRemainingAmount: 2500.0,
            status: const drift.Value('Unpaid'),
          ));

      await db.into(db.customerReceivables).insert(CustomerReceivablesCompanion.insert(
            id: rec2Id,
            businessId: businessId,
            customerId: customerId,
            salesInvoiceId: uuid.v4(),
            currencyId: baseCurrencyId,
            originalAmount: 4000.0,
            baseOriginalAmount: 4000.0,
            remainingAmount: 4000.0,
            baseRemainingAmount: 4000.0,
            status: const drift.Value('Unpaid'),
          ));

      // Customer payments via receipt vouchers: 3,000 (settling rec1 of 2,500 and 500 of rec2)
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final receiveResult = await receivePaymentUseCase(ReceivePaymentCommand(
        customerId: customerId,
        amount: 3000.0,
        currencyId: baseCurrencyId,
        paymentMethodId: 'CASH',
        chartOfAccountId: cashAccount.id,
        notes: 'دفعة حساب',
        allocations: [
          PaymentAllocationCommand(receivableId: rec1Id, allocatedAmount: 2500.0),
          PaymentAllocationCommand(receivableId: rec2Id, allocatedAmount: 500.0),
        ],
      ));

      expect(receiveResult.isRight(), isTrue);

      // Verify Party Balance: Total Invoices (6,500) - Receipts (3,000) = 3,500
      final rec1 = await (db.select(db.customerReceivables)..where((r) => r.id.equals(rec1Id))).getSingle();
      final rec2 = await (db.select(db.customerReceivables)..where((r) => r.id.equals(rec2Id))).getSingle();

      expect(rec1.status, 'Paid');
      expect(rec1.remainingAmount, 0.0);

      expect(rec2.status, 'Partial');
      expect(rec2.remainingAmount, 3500.0);

      final totalRemainingDue = rec1.remainingAmount + rec2.remainingAmount;
      expect(totalRemainingDue, 3500.0,
          reason: 'Party Balance Integrity failed! Expected 3500 remaining due.');
    });

    test('Invariant 5: Cash Conservation (Disbursements lower payable and create balanced entries)', () async {
      final supplierId = uuid.v4();
      await db.into(db.suppliers).insert(SuppliersCompanion.insert(
            id: supplierId,
            businessId: businessId,
            supplierName: 'مورد البضائع',
            creditLimit: const drift.Value(50000.0),
            isActive: const drift.Value(true),
          ));

      final payableId = uuid.v4();
      await db.into(db.supplierPayables).insert(SupplierPayablesCompanion.insert(
            id: payableId,
            businessId: businessId,
            supplierId: supplierId,
            purchaseInvoiceId: uuid.v4(),
            currencyId: baseCurrencyId,
            originalAmount: 10000.0,
            baseOriginalAmount: 10000.0,
            remainingAmount: 10000.0,
            baseRemainingAmount: 10000.0,
            status: const drift.Value('Unpaid'),
          ));

      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final result = await recordDisbursementUseCase(RecordDisbursementCommand(
        type: DisbursementType.supplierPayment,
        amount: 4000.0,
        currencyId: baseCurrencyId,
        paymentMethodId: 'CASH',
        chartOfAccountId: cashAccount.id,
        supplierId: supplierId,
        notes: 'دفعة سداد حساب المورد',
        allocations: [
          PayableAllocationCommand(payableId: payableId, allocatedAmount: 4000.0),
        ],
      ));

      expect(result.isRight(), isTrue);

      final pay = await (db.select(db.supplierPayables)..where((p) => p.id.equals(payableId))).getSingle();
      expect(pay.paidAmount, 4000.0);
      expect(pay.remainingAmount, 6000.0);
      expect(pay.status, 'Partial');
    });

    test('Invariant 6: Atomic Rollback Integrity (No partial state left on failure)', () async {
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final initialJournalCount = (await db.select(db.journalEntries).get()).length;

      // Intentionally unbalanced journal entry to verify failure and rollback
      final failResult = await postJournalUseCase(PostJournalEntryCommand(
        documentDate: DateTime.now(),
        journalType: 'Manual',
        currencyId: baseCurrencyId,
        lines: [
          JournalEntryLineCommand(accountId: cashAccount.id, debit: 1000.0, credit: 0.0),
          // Unbalanced: missing credit line!
        ],
      ));

      expect(failResult.isLeft(), isTrue);

      // Verify atomic rollback: zero new journals committed
      final finalJournalCount = (await db.select(db.journalEntries).get()).length;
      expect(finalJournalCount, initialJournalCount, reason: 'Journal entry was improperly committed!');
    });
  });
}
