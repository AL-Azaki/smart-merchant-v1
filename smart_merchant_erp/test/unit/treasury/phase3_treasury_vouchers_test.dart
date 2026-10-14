import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:smart_merchant_erp/database/daos/accounting_dao.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/database/daos/treasury_dao.dart';
import 'package:smart_merchant_erp/database/seeders/default_coa_seeder.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/kernel/core/transaction_runner.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/services/accounting_application_service.dart';
import 'package:smart_merchant_erp/modules/accounting/domain/repositories/accounting_repository.dart';
import 'package:smart_merchant_erp/modules/accounting/infrastructure/repositories/accounting_repository_impl.dart';
import 'package:smart_merchant_erp/modules/purchasing/domain/repositories/purchasing_repository.dart';
import 'package:smart_merchant_erp/modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';
import 'package:smart_merchant_erp/modules/treasury/application/services/party_statement_service.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/internal_fund_transfer_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/receive_payment_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/application/usecases/record_disbursement_usecase.dart';
import 'package:smart_merchant_erp/modules/treasury/domain/repositories/treasury_repository.dart';
import 'package:smart_merchant_erp/modules/treasury/infrastructure/repositories/treasury_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ApplicationTransactionRunner transactionRunner;
  late AccountingRepository accountingRepo;
  late SalesRepository salesRepo;
  late PurchasingRepository purchasingRepo;
  late TreasuryRepository treasuryRepo;
  late AccountingApplicationService accountingService;
  late DefaultChartOfAccountsSeeder coaSeeder;
  late ApplicationContext context;

  late ReceivePaymentUseCase receivePaymentUseCase;
  late RecordDisbursementUseCase recordDisbursementUseCase;
  late InternalFundTransferUseCase internalTransferUseCase;
  late PartyStatementService partyStatementService;

  const uuid = Uuid();
  late String businessId;
  late String branchId;
  late String userId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    transactionRunner = ApplicationTransactionRunnerImpl(db);
    accountingRepo = AccountingRepositoryImpl(AccountingDao(db));
    salesRepo = SalesRepositoryImpl(SalesDao(db));
    purchasingRepo = PurchasingRepositoryImpl(PurchasingDao(db));
    treasuryRepo = TreasuryRepositoryImpl(TreasuryDao(db));
    coaSeeder = DefaultChartOfAccountsSeeder(db);

    businessId = uuid.v4();
    branchId = uuid.v4();
    userId = uuid.v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    accountingService = AccountingApplicationService(accountingRepo, context);

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

    internalTransferUseCase = InternalFundTransferUseCase(
      treasuryRepo,
      accountingRepo,
      context,
      transactionRunner,
    );

    partyStatementService = PartyStatementService(
      salesRepo,
      purchasingRepo,
      treasuryRepo,
      context,
    );

    // Seed master business, branch, user
    await db.into(db.businesses).insert(
      BusinessesCompanion.insert(
        id: businessId,
        accountId: 'acc-treasury-test',
        businessName: 'Treasury Test Enterprise',
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
        email: 'treasury@test.com',
        passwordHash: 'dummy',
        firstName: 'Treasury',
        lastName: 'Manager',
        isActive: const drift.Value(true),
      ),
    );

    // Seed Open Fiscal Period
    final fiscalYearId = uuid.v4();
    await db.into(db.fiscalPeriods).insert(
      FiscalPeriodsCompanion.insert(
        id: uuid.v4(),
        businessId: businessId,
        fiscalYearId: fiscalYearId,
        periodNumber: 1,
        periodName: '2026-01',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        status: const drift.Value('Open'),
      ),
    );

    // Seed Standard Retail Chart of Accounts
    await coaSeeder.seedChartOfAccounts(businessId: businessId);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3: Treasury, Vouchers & Party Statements Suite', () {
    test('AC-3.1: Receipt Voucher lowers customer receivable and creates balanced journal', () async {
      // 1. Create Customer
      final customerId = uuid.v4();
      await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: customerId,
          businessId: businessId,
          customerName: 'شركة النور التجارية',
          phone: const drift.Value('770000001'),
          creditLimit: const drift.Value(50000.0),
          isActive: const drift.Value(true),
        ),
      );

      // 2. Create Open Receivable of 20,000 YER
      final receivableId = uuid.v4();
      final invoiceId = uuid.v4();
      await db.into(db.customerReceivables).insert(
        CustomerReceivablesCompanion.insert(
          id: receivableId,
          businessId: businessId,
          customerId: customerId,
          salesInvoiceId: invoiceId,
          currencyId: 'YER',
          originalAmount: 20000.0,
          baseOriginalAmount: 20000.0,
          paidAmount: const drift.Value(0.0),
          basePaidAmount: const drift.Value(0.0),
          remainingAmount: 20000.0,
          baseRemainingAmount: 20000.0,
          status: const drift.Value('Unpaid'),
        ),
      );

      // Resolve Cash Account (11101)
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;

      // 3. Receive 5,000 YER against the receivable
      final command = ReceivePaymentCommand(
        customerId: customerId,
        amount: 5000.0,
        currencyId: 'YER',
        paymentMethodId: 'CASH',
        chartOfAccountId: cashAccount.id,
        notes: 'دفعة نقدية تحت الحساب',
        allocations: [
          PaymentAllocationCommand(
            receivableId: receivableId,
            allocatedAmount: 5000.0,
          ),
        ],
      );

      final result = await receivePaymentUseCase(command);
      expect(result.isRight(), isTrue);

      final paymentId = result.getOrElse(() => '');
      expect(paymentId, isNotEmpty);

      // Verify Payment record
      final payment = await treasuryRepo.getPaymentById(paymentId, businessId);
      expect(payment, isNotNull);
      expect(payment!.paymentType, equals('Receipt'));
      expect(payment.amount, equals(5000.0));
      expect(payment.status, equals('Posted'));

      // Verify Receivable balance reduced to 15,000 YER
      final rec = await (db.select(db.customerReceivables)
            ..where((r) => r.id.equals(receivableId)))
          .getSingle();
      expect(rec.paidAmount, equals(5000.0));
      expect(rec.remainingAmount, equals(15000.0));
      expect(rec.status, equals('Partial'));

      // Verify Journal Entry is balanced
      final journals = await accountingRepo.listJournalEntries(
        JournalEntryFilter(businessId: businessId, documentId: paymentId),
      );
      expect(journals.length, equals(1));
      final journalWithLines = await accountingRepo.getJournalEntryWithLinesById(
        journals.first.id,
        businessId,
      );
      expect(journalWithLines, isNotNull);
      final lines = journalWithLines!.lines;
      expect(lines.length, equals(2));

      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');
      expect(debitLine.chartOfAccountId, equals(cashAccount.id));
      expect(debitLine.baseAmount, equals(5000.0));
      expect(creditLine.baseAmount, equals(5000.0));
    });

    test('AC-3.2: Direct Expense Disbursement posts balanced journal and records voucher', () async {
      // Resolve Cash Account (11101) and Rent Expense (52001)
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final rentAccount = (await accountingRepo.getChartOfAccountByCode('52001', businessId))!;

      final command = RecordDisbursementCommand(
        type: DisbursementType.expense,
        amount: 12000.0,
        currencyId: 'YER',
        paymentMethodId: 'CASH',
        chartOfAccountId: cashAccount.id,
        expenseAccountId: rentAccount.id,
        notes: 'سداد إيجار المحل لشهر أكتوبر',
      );

      final result = await recordDisbursementUseCase(command);
      expect(result.isRight(), isTrue);

      final paymentId = result.getOrElse(() => '');

      // Verify Payment record
      final payment = await treasuryRepo.getPaymentById(paymentId, businessId);
      expect(payment, isNotNull);
      expect(payment!.paymentType, equals('Payment'));
      expect(payment.amount, equals(12000.0));

      // Verify Journal Entry
      final journals = await accountingRepo.listJournalEntries(
        JournalEntryFilter(businessId: businessId, documentId: paymentId),
      );
      expect(journals.length, equals(1));
      final journalWithLines = await accountingRepo.getJournalEntryWithLinesById(
        journals.first.id,
        businessId,
      );
      final lines = journalWithLines!.lines;

      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');

      expect(debitLine.chartOfAccountId, equals(rentAccount.id)); // Rent Expense
      expect(debitLine.baseAmount, equals(12000.0));
      expect(creditLine.chartOfAccountId, equals(cashAccount.id)); // Cash
      expect(creditLine.baseAmount, equals(12000.0));
    });

    test('AC-3.3: Supplier Settlement lowers payable balance and generates balanced journal', () async {
      // 1. Create Supplier
      final supplierId = uuid.v4();
      await db.into(db.suppliers).insert(
        SuppliersCompanion.insert(
          id: supplierId,
          businessId: businessId,
          supplierName: 'مؤسسة البركة للاستيراد',
          creditLimit: const drift.Value(100000.0),
          isActive: const drift.Value(true),
        ),
      );

      // 2. Create Supplier Payable of 30,000 YER
      final payableId = uuid.v4();
      final invoiceId = uuid.v4();
      await db.into(db.supplierPayables).insert(
        SupplierPayablesCompanion.insert(
          id: payableId,
          businessId: businessId,
          supplierId: supplierId,
          purchaseInvoiceId: invoiceId,
          currencyId: 'YER',
          originalAmount: 30000.0,
          baseOriginalAmount: 30000.0,
          paidAmount: const drift.Value(0.0),
          basePaidAmount: const drift.Value(0.0),
          remainingAmount: 30000.0,
          baseRemainingAmount: 30000.0,
          status: const drift.Value('Unpaid'),
        ),
      );

      // Resolve Bank Account (11102)
      final bankAccount = (await accountingRepo.getChartOfAccountByCode('11102', businessId))!;

      // 3. Settle 10,000 YER
      final command = RecordDisbursementCommand(
        type: DisbursementType.supplierPayment,
        amount: 10000.0,
        currencyId: 'YER',
        paymentMethodId: 'BANK_TRANSFER',
        chartOfAccountId: bankAccount.id,
        supplierId: supplierId,
        notes: 'سداد دفعة من فاتورة المشتريات',
        allocations: [
          PayableAllocationCommand(
            payableId: payableId,
            allocatedAmount: 10000.0,
          ),
        ],
      );

      final result = await recordDisbursementUseCase(command);
      expect(result.isRight(), isTrue);

      final paymentId = result.getOrElse(() => '');

      // Verify Payable remaining reduced to 20,000 YER
      final pay = await (db.select(db.supplierPayables)
            ..where((p) => p.id.equals(payableId)))
          .getSingle();
      expect(pay.paidAmount, equals(10000.0));
      expect(pay.remainingAmount, equals(20000.0));
      expect(pay.status, equals('Partial'));

      // Verify Journal: Debit A/P (2111), Credit Bank (1112)
      final journals = await accountingRepo.listJournalEntries(
        JournalEntryFilter(businessId: businessId, documentId: paymentId),
      );
      final journalWithLines = await accountingRepo.getJournalEntryWithLinesById(
        journals.first.id,
        businessId,
      );
      final lines = journalWithLines!.lines;

      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');

      expect(debitLine.baseAmount, equals(10000.0));
      expect(creditLine.chartOfAccountId, equals(bankAccount.id));
      expect(creditLine.baseAmount, equals(10000.0));
    });

    test('AC-3.4: Internal Fund Transfer between Cash and Bank generates 2-line balanced journal', () async {
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final bankAccount = (await accountingRepo.getChartOfAccountByCode('11102', businessId))!;

      final command = InternalFundTransferCommand(
        fromAccountId: cashAccount.id,
        toAccountId: bankAccount.id,
        amount: 15000.0,
        currencyId: 'YER',
        paymentMethodId: 'INTERNAL_TRANSFER',
        notes: 'إيداع نقدي من الصندوق إلى الحساب البنكي',
      );

      final result = await internalTransferUseCase(command);
      expect(result.isRight(), isTrue);

      final paymentId = result.getOrElse(() => '');

      // Verify Payment record
      final payment = await treasuryRepo.getPaymentById(paymentId, businessId);
      expect(payment, isNotNull);
      expect(payment!.paymentType, equals('Transfer'));

      // Verify Journal: Debit Bank (1112), Credit Cash (1111)
      final journals = await accountingRepo.listJournalEntries(
        JournalEntryFilter(businessId: businessId, documentId: paymentId),
      );
      final journalWithLines = await accountingRepo.getJournalEntryWithLinesById(
        journals.first.id,
        businessId,
      );
      final lines = journalWithLines!.lines;

      final debitLine = lines.firstWhere((l) => l.type == 'Debit');
      final creditLine = lines.firstWhere((l) => l.type == 'Credit');

      expect(debitLine.chartOfAccountId, equals(bankAccount.id));
      expect(debitLine.baseAmount, equals(15000.0));
      expect(creditLine.chartOfAccountId, equals(cashAccount.id));
      expect(creditLine.baseAmount, equals(15000.0));
    });

    test('AC-3.5: PartyStatementService builds accurate chronological statement with running balance', () async {
      final customerId = uuid.v4();
      final now = DateTime.now();

      await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: customerId,
          businessId: businessId,
          customerName: 'مؤسسة الأمل',
          creditLimit: const drift.Value(50000.0),
          openingBalance: const drift.Value(1000.0),
          openingBalanceType: const drift.Value('debit'),
          openingBalanceDate: drift.Value(now.subtract(const Duration(days: 10))),
          isActive: const drift.Value(true),
        ),
      );

      // Sales Invoice of 5,000 YER
      final invoiceId = uuid.v4();
      await db.into(db.salesInvoices).insert(
        SalesInvoicesCompanion.insert(
          id: invoiceId,
          businessId: businessId,
          branchId: branchId,
          invoiceNumber: 'INV-1001',
          invoiceDate: drift.Value(now.subtract(const Duration(days: 5))),
          customerId: drift.Value(customerId),
          currencyId: 'YER',
          subTotal: const drift.Value(5000.0),
          grandTotal: const drift.Value(5000.0),
          baseSubTotal: const drift.Value(5000.0),
          baseGrandTotal: const drift.Value(5000.0),
          createdBy: userId,
        ),
      );

      // Receipt Payment of 2,000 YER
      final paymentId = uuid.v4();
      await db.into(db.payments).insert(
        PaymentsCompanion.insert(
          id: paymentId,
          businessId: businessId,
          branchId: branchId,
          paymentNumber: 'RCP-1001',
          paymentDate: drift.Value(now.subtract(const Duration(days: 2))),
          paymentMethodId: 'CASH',
          chartOfAccountId: 'acc_cash',
          currencyId: 'YER',
          amount: 2000.0,
          baseAmount: 2000.0,
          paymentType: 'Receipt',
          contactType: const drift.Value('Customer'),
          contactId: drift.Value(customerId),
          status: const drift.Value('Posted'),
          createdBy: userId,
        ),
      );

      final statement = await partyStatementService.getCustomerStatement(customerId);

      expect(statement.partyName, equals('مؤسسة الأمل'));
      expect(statement.lines.length, equals(3));
      // Line 1: Opening 1,000 -> Running: 1,000
      expect(statement.lines[0].documentType, equals('Opening'));
      expect(statement.lines[0].runningBalance, equals(1000.0));

      // Line 2: Invoice 5,000 -> Running: 6,000
      expect(statement.lines[1].documentType, equals('Invoice'));
      expect(statement.lines[1].runningBalance, equals(6000.0));

      // Line 3: Payment 2,000 -> Running: 4,000
      expect(statement.lines[2].documentType, equals('Payment'));
      expect(statement.lines[2].runningBalance, equals(4000.0));

      expect(statement.closingBalance, equals(4000.0));
    });

    test('AC-3.6: Safety & Danger Traps: Invalid amounts, same-account transfers, and parent accounts are rejected', () async {
      final cashAccount = (await accountingRepo.getChartOfAccountByCode('11101', businessId))!;
      final parentAccount = (await accountingRepo.getChartOfAccountByCode('11', businessId))!; // Parent Group (allowPosting = false)

      // Zero or Negative Amount rejected
      final zeroResult = await recordDisbursementUseCase(
        RecordDisbursementCommand(
          type: DisbursementType.expense,
          amount: 0.0,
          currencyId: 'YER',
          paymentMethodId: 'CASH',
          chartOfAccountId: cashAccount.id,
          expenseAccountId: 'some_id',
        ),
      );
      expect(zeroResult.isLeft(), isTrue);

      // Same Account Transfer rejected
      final sameResult = await internalTransferUseCase(
        InternalFundTransferCommand(
          fromAccountId: cashAccount.id,
          toAccountId: cashAccount.id,
          amount: 1000.0,
          currencyId: 'YER',
          paymentMethodId: 'CASH',
        ),
      );
      expect(sameResult.isLeft(), isTrue);

      // Posting to parent group rejected
      final parentDisbursementResult = await recordDisbursementUseCase(
        RecordDisbursementCommand(
          type: DisbursementType.expense,
          amount: 1000.0,
          currencyId: 'YER',
          paymentMethodId: 'CASH',
          chartOfAccountId: parentAccount.id, // Parent!
          expenseAccountId: 'some_id',
        ),
      );
      expect(parentDisbursementResult.isLeft(), isTrue);
    });
  });
}
