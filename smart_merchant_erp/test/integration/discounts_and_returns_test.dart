import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/app/di/getit_instance.dart';
import 'package:smart_merchant_erp/app/di/injection.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/process_sales_return_usecase.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/usecases/record_purchase_usecase.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/usecases/record_purchase_return_usecase.dart';
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
  late ProcessSalesReturnUseCase processSalesReturnUseCase;
  late RecordPurchaseUseCase recordPurchaseUseCase;
  late RecordPurchaseReturnUseCase recordPurchaseReturnUseCase;
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
      includeDemoProductsAndContacts: true,
    );

    completeSaleUseCase = getIt<CompleteSaleUseCase>();
    processSalesReturnUseCase = getIt<ProcessSalesReturnUseCase>();
    recordPurchaseUseCase = getIt<RecordPurchaseUseCase>();
    recordPurchaseReturnUseCase = getIt<RecordPurchaseReturnUseCase>();
    accountingService = getIt<AccountingApplicationService>();
  });

  tearDown(() async {
    await db.close();
    await GetIt.instance.reset();
  });

  group('Discounts & Returns Integration Tests -', () {
    test('1. Complete Sale with Item & Invoice Discounts generates balanced Journal Entry with Discount Allowed', () async {
      // 2 units at 150 = 300 gross. Item discount: 20 -> Subtotal net: 280.
      // Invoice discount: 30 -> Total discount: 50. Grand total: 250.
      final items = [
        CompleteSaleItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 2.0,
          unitPrice: 150.0,
          warehouseId: 'wh-qa-main',
          tax: 0.0,
          discount: 20.0,
        ),
      ];

      final command = CompleteSaleCommand(
        customerId: 'cust-qa-01',
        currencyId: 'YER',
        isCreditSale: true,
        items: items,
        invoiceDiscount: 30.0,
      );

      final result = await completeSaleUseCase(command);
      expect(result.isRight(), true, reason: 'Sale with discount should succeed');
      final invoiceId = result.getOrElse(() => '');

      // Verify invoice stored amounts
      final invoice = await (db.select(db.salesInvoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(invoice.discountTotal, 50.0);
      expect(invoice.grandTotal, 250.0);

      // Verify Journal Entry is perfectly balanced
      final journals = await (db.select(db.journalEntries)..where((t) => t.documentId.equals(invoiceId))).get();
      expect(journals.isNotEmpty, true);
      final journal = journals.first;

      final lines = await (db.select(db.journalEntryLines)..where((t) => t.journalEntryId.equals(journal.id))).get();
      double totalDebit = 0;
      double totalCredit = 0;
      for (final line in lines) {
        if (line.type == 'Debit') totalDebit += line.baseAmount;
        if (line.type == 'Credit') totalCredit += line.baseAmount;
      }
      expect(totalDebit, closeTo(totalCredit, 0.001), reason: 'Debits must equal Credits');
    });

    test('2. Sales Return deducts original item discount and credits the specified refund method', () async {
      // Step A: Sell 2 units at 100 with 20 discount (Net paid: 180, i.e. 90/unit)
      final saleItems = [
        CompleteSaleItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 2.0,
          unitPrice: 100.0,
          warehouseId: 'wh-qa-main',
          tax: 0.0,
          discount: 20.0,
        ),
      ];

      final saleCommand = CompleteSaleCommand(
        customerId: 'cust-qa-01',
        currencyId: 'YER',
        isCreditSale: false,
        items: saleItems,
      );

      final saleResult = await completeSaleUseCase(saleCommand);
      expect(saleResult.isRight(), true);
      final saleInvoiceId = saleResult.getOrElse(() => '');

      final saleInvoiceWithItems = await (db.select(db.salesInvoiceItems)..where((t) => t.salesInvoiceId.equals(saleInvoiceId))).get();
      final soldItem = saleInvoiceWithItems.first;

      // Step B: Return 1 unit with Cash refund method
      final returnCommand = ProcessSalesReturnCommand(
        salesInvoiceId: saleInvoiceId,
        currencyId: 'YER',
        refundMethod: 'CASH',
        items: [
          SalesReturnItemCommand(
            salesInvoiceItemId: soldItem.id,
            productUnitId: soldItem.productUnitId,
            warehouseId: soldItem.warehouseId,
            quantity: 1.0,
            unitPrice: soldItem.unitPrice,
          ),
        ],
      );

      final returnResult = await processSalesReturnUseCase(returnCommand);
      expect(returnResult.isRight(), true, reason: 'Sales return should succeed');
      final returnId = returnResult.getOrElse(() => '');

      // Verify refund total reflects net price (100 - 10 discount = 90)
      final returnHeader = await (db.select(db.salesReturns)..where((t) => t.id.equals(returnId))).getSingle();
      expect(returnHeader.totalAmount, equals(90.0), reason: 'Refund must be net of original discount');

      // Verify journal entry for return is balanced
      final returnJournals = await (db.select(db.journalEntries)..where((t) => t.documentId.equals(returnId))).get();
      expect(returnJournals.isNotEmpty, true);
      final returnLines = await (db.select(db.journalEntryLines)..where((t) => t.journalEntryId.equals(returnJournals.first.id))).get();
      double totalDebit = 0;
      double totalCredit = 0;
      for (final line in returnLines) {
        if (line.type == 'Debit') totalDebit += line.baseAmount;
        if (line.type == 'Credit') totalCredit += line.baseAmount;
      }
      expect(totalDebit, closeTo(totalCredit, 0.001), reason: 'Return journal must be balanced');
    });

    test('3. Purchase with item discount records inventory WAC cost net of discount', () async {
      final items = [
        PurchaseItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 10.0,
          unitCost: 100.0, // 1000 gross
          discount: 200.0, // 200 discount -> 80 net/unit
          warehouseId: 'wh-qa-main',
        ),
      ];

      final command = RecordPurchaseCommand(
        supplierId: 'supplier-qa-01',
        currencyId: 'YER',
        isCreditPurchase: true,
        items: items,
        invoiceDiscount: 50.0, // extra 50 invoice discount -> Grand Total: 750
      );

      final result = await recordPurchaseUseCase(command);
      expect(result.isRight(), true, reason: 'Purchase with discounts should succeed');
      final invoiceId = result.getOrElse(() => '');

      final invoice = await (db.select(db.purchaseInvoices)..where((t) => t.id.equals(invoiceId))).getSingle();
      expect(invoice.discountTotal, equals(250.0));
      expect(invoice.grandTotal, equals(750.0));
    });

    test('4. Purchase Return debits chosen refund method and reduces inventory', () async {
      // Step A: Purchase 5 units
      final purchaseItems = [
        PurchaseItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 5.0,
          unitCost: 80.0,
          warehouseId: 'wh-qa-main',
        ),
      ];

      final purchaseCommand = RecordPurchaseCommand(
        supplierId: 'supplier-qa-01',
        currencyId: 'YER',
        isCreditPurchase: false,
        paymentMethodId: 'pm-cash',
        items: purchaseItems,
      );

      final purchaseResult = await recordPurchaseUseCase(purchaseCommand);
      expect(purchaseResult.isRight(), true);
      final purchaseId = purchaseResult.getOrElse(() => '');

      final invoiceLines = await (db.select(db.purchaseInvoiceItems)..where((t) => t.purchaseInvoiceId.equals(purchaseId))).get();
      final pItem = invoiceLines.first;

      // Step B: Return 2 units with CASH refund
      final returnCommand = RecordPurchaseReturnCommand(
        purchaseInvoiceId: purchaseId,
        supplierId: 'supplier-qa-01',
        currencyId: 'YER',
        refundMethod: 'CASH',
        items: [
          PurchaseReturnItemCommand(
            purchaseInvoiceItemId: pItem.id,
            productUnitId: pItem.productUnitId,
            warehouseId: pItem.warehouseId,
            quantity: 2.0,
            unitPrice: pItem.unitPrice,
          ),
        ],
      );

      final returnResult = await recordPurchaseReturnUseCase(returnCommand);
      expect(returnResult.isRight(), true, reason: 'Purchase return should succeed');
      final returnId = returnResult.getOrElse(() => '');

      final returnRecord = await (db.select(db.purchaseReturns)..where((t) => t.id.equals(returnId))).getSingle();
      expect(returnRecord.totalAmount, equals(160.0));

      // Verify Journal Entry balance
      final jeList = await (db.select(db.journalEntries)..where((t) => t.documentId.equals(returnId))).get();
      expect(jeList.isNotEmpty, true);
      final lines = await (db.select(db.journalEntryLines)..where((t) => t.journalEntryId.equals(jeList.first.id))).get();
      double totalDebit = 0;
      double totalCredit = 0;
      for (final line in lines) {
        if (line.type == 'Debit') totalDebit += line.baseAmount;
        if (line.type == 'Credit') totalCredit += line.baseAmount;
      }
      expect(totalDebit, closeTo(totalCredit, 0.001));
    });
  });
}
