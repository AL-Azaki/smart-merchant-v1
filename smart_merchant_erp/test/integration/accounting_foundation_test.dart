import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/app/di/getit_instance.dart';
import 'package:smart_merchant_erp/app/di/injection.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/usecases/record_purchase_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/receive_payment_usecase.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';

class TestApplicationContext implements ApplicationContext {
  final String _bizId;
  TestApplicationContext(this._bizId);
  @override
  String get currentBusinessId => _bizId;
  @override
  String? get currentBranchId => 'test-branch';
  @override
  String get currentUserId => 'test-user';
}

void main() {
  late AppDatabase db;
  late CompleteSaleUseCase completeSaleUseCase;
  late RecordPurchaseUseCase recordPurchaseUseCase;
  late ReceivePaymentUseCase receivePaymentUseCase;
  late AccountingApplicationService accountingService;

  setUp(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.allowReassignment = true;
    
    db = AppDatabase(connection: NativeDatabase.memory());
    
    configureDependencies();
    
    getIt.registerSingleton<AppDatabase>(db);
    getIt.registerSingleton<ApplicationContext>(TestApplicationContext('test-biz'));

    final seeder = QaDataSeeder(db);
    await seeder.seedAll(
      businessId: 'test-biz',
      branchId: 'test-branch',
      userId: 'test-user',
      accountId: 'test-acc',
    );

    completeSaleUseCase = getIt<CompleteSaleUseCase>();
    recordPurchaseUseCase = getIt<RecordPurchaseUseCase>();
    receivePaymentUseCase = getIt<ReceivePaymentUseCase>();
    accountingService = getIt<AccountingApplicationService>();
  });

  tearDown(() async {
    await db.close();
    await GetIt.instance.reset();
  });

  test('1. Account Mapping Resolution - all required mappings exist', () async {
    final requiredMappings = [
      'accounts_receivable',
      'accounts_payable',
      'sales_revenue',
      'inventory_asset',
      'cost_of_goods_sold',
    ];

    for (var key in requiredMappings) {
      final result = await accountingService.resolveAccountMapping(key);
      expect(result.isRight(), true, reason: 'Mapping $key should resolve successfully.');
    }
  });

  test('2, 4. Credit Sale and Journal Balance', () async {
    final initialInv = await (db.select(db.inventories)..where((t) => t.productUnitId.equals('pu-prod-qa-01'))).getSingle();
    final costPrice = initialInv.averageCost ?? 0.0;
    
    final items = [
      CompleteSaleItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 2.0,
        unitPrice: 150.0,
        warehouseId: 'wh-qa-main',
        tax: 0.0,
        discount: 0.0,
      )
    ];

    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER',
      isCreditSale: true,
      items: items,
    );

    final result = await completeSaleUseCase(request);
    expect(result.isRight(), true);
    final invoiceId = result.getOrElse(() => '');

    // Check Journal Entries
    final journals = await (db.select(db.journalEntries)..where((t) => t.documentId.equals(invoiceId))).get();
    expect(journals.length, 1);
    final journal = journals.first;

    final lines = await (db.select(db.journalEntryLines)..where((t) => t.journalEntryId.equals(journal.id))).get();
    expect(lines.isNotEmpty, true);

    double totalDebit = 0;
    double totalCredit = 0;
    for (var line in lines) {
      if (line.type == 'Debit') totalDebit += line.baseAmount;
      if (line.type == 'Credit') totalCredit += line.baseAmount;
    }

    expect(totalDebit, closeTo(totalCredit, 0.001));
    // Amount should be grand total (300) + COGS (costPrice * 2)
    // 300 revenue, 300 AR, COGS debit, Inv credit
  });

  test('3. Cash Sale (if supported or Credit by default)', () async {
    // Currently complete_sale defaults to credit or unpaid, we'll verify it doesn't fail
    final items = [
      CompleteSaleItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 1.0,
        unitPrice: 150.0,
        warehouseId: 'wh-qa-main',
      )
    ];

    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER',
      isCreditSale: false,
      items: items,
    );

    final result = await completeSaleUseCase(request);
    expect(result.isRight(), true);
  });

  test('5. Cash Purchase', () async {
    final items = [
      PurchaseItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 5.0,
        unitCost: 100.0,
        warehouseId: 'wh-qa-main',
      )
    ];

    final request = RecordPurchaseCommand(
      supplierId: 'supplier-qa-01',
      currencyId: 'YER',
      isCreditPurchase: false,
      paymentMethodId: 'pm-cash',
      items: items,
    );

    // Create supplier first as it might not be in qa_data_seeder yet
    await db.into(db.suppliers).insertOnConflictUpdate(SuppliersCompanion.insert(
      id: 'supplier-qa-01',
      businessId: 'test-biz',
      supplierName: 'Test Supplier',
      isActive: const drift.Value(true),
    ));

    final result = await recordPurchaseUseCase(request);
    expect(result.isRight(), true);
  });

  test('6. Credit Purchase (Root cause fix)', () async {
    final items = [
      PurchaseItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 5.0,
        unitCost: 100.0,
        warehouseId: 'wh-qa-main',
      )
    ];

    await db.into(db.suppliers).insertOnConflictUpdate(SuppliersCompanion.insert(
      id: 'supplier-qa-01',
      businessId: 'test-biz',
      supplierName: 'Test Supplier',
      isActive: const drift.Value(true),
    ));

    final request = RecordPurchaseCommand(
      supplierId: 'supplier-qa-01',
      currencyId: 'YER',
      isCreditPurchase: true,
      items: items,
    );

    final result = await recordPurchaseUseCase(request);
    expect(result.isRight(), true, reason: 'Credit purchase should not fail with missing accounts_payable mapping.');

    final invoiceId = result.getOrElse(() => '');
    final journals = await (db.select(db.journalEntries)..where((t) => t.documentId.equals(invoiceId))).get();
    expect(journals.length, 1);
    
    final lines = await (db.select(db.journalEntryLines)..where((t) => t.journalEntryId.equals(journals.first.id))).get();
    double totalDebit = 0;
    double totalCredit = 0;
    for (var line in lines) {
      if (line.type == 'Debit') totalDebit += line.baseAmount;
      if (line.type == 'Credit') totalCredit += line.baseAmount;
    }
    expect(totalDebit, closeTo(totalCredit, 0.001));
  });

  test('7. Payment Allocation', () async {
    // 1. Create a credit sale
    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER',
      isCreditSale: true,
      items: [
        CompleteSaleItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 2.0,
          unitPrice: 150.0,
          warehouseId: 'wh-qa-main',
        )
      ],
    );

    final saleResult = await completeSaleUseCase(request);
    final invoiceId = saleResult.getOrElse(() => '');
    
    final receivables = await (db.select(db.customerReceivables)..where((t) => t.salesInvoiceId.equals(invoiceId))).get();
    final receivableId = receivables.first.id;

    // 2. Receive Payment
    final paymentReq = ReceivePaymentCommand(
      customerId: 'cust-qa-01',
      amount: 300.0,
      currencyId: 'YER',
      paymentMethodId: 'pm-cash',
      chartOfAccountId: 'coa-cash',
      allocations: [
        PaymentAllocationCommand(
          receivableId: receivableId,
          allocatedAmount: 300.0,
        )
      ]
    );

    final result = await receivePaymentUseCase(paymentReq);
    expect(result.isRight(), true);
  });

  test('8. Transaction Rollback', () async {
    // Intentionally pass an invalid currency to trigger failure in the repository level (foreign key failure).
    // Or we can rely on domain validation, but let's test a database-level transaction rollback.
    final items = [
      PurchaseItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 5.0,
        unitCost: 100.0,
        warehouseId: 'wh-qa-main',
      )
    ];

    await db.into(db.suppliers).insertOnConflictUpdate(SuppliersCompanion.insert(
      id: 'supplier-qa-01',
      businessId: 'test-biz',
      supplierName: 'Test Supplier',
      isActive: const drift.Value(true),
    ));

    final countBefore = (await db.select(db.purchaseInvoices).get()).length;

    final request = RecordPurchaseCommand(
      supplierId: 'supplier-qa-01',
      currencyId: 'INVALID_CURRENCY', 
      isCreditPurchase: true,
      items: items,
    );

    final result = await recordPurchaseUseCase(request);
    expect(result.isLeft(), true); // Should fail

    final countAfter = (await db.select(db.purchaseInvoices).get()).length;
    expect(countAfter, countBefore, reason: 'Transaction should rollback completely');
  });

  test('9. Tenant Isolation', () async {
    final getIt = GetIt.instance;
    // Switch context to a different tenant
    getIt.allowReassignment = true;
    getIt.registerSingleton<ApplicationContext>(TestApplicationContext('other-biz'));
    final otherAccountingService = AccountingApplicationService(getIt(), TestApplicationContext('other-biz'));

    final result = await otherAccountingService.resolveAccountMapping('accounts_receivable');
    expect(result.isLeft(), true, reason: 'Other tenant should not see test-biz mappings');
  });
}
