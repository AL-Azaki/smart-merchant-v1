import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/daos/treasury_dao.dart';
import 'package:smart_merchant_erp/database/daos/dao_exceptions.dart';

void main() {
  late AppDatabase database;
  late TreasuryDao treasuryDao;

  setUp(() async {
    database = AppDatabase(connection: NativeDatabase.memory());
    treasuryDao = TreasuryDao(database);

    // Seed required parent User, Account, Businesses, Branches, Currencies, AccountTypes, Chart of Accounts, and Customers
    await database
        .into(database.usersTable)
        .insert(
          UsersTableCompanion.insert(
            id: const drift.Value('u-owner'),
            email: 'owner@treasury.com',
            passwordHash: 'hash',
            firstName: 'Treasury',
            lastName: 'Owner',
          ),
        );
    await database
        .into(database.accountsTable)
        .insert(
          AccountsTableCompanion.insert(
            id: const drift.Value('acc-treasury-01'),
            ownerId: 'u-owner',
            businessName: 'Treasury Enterprise',
            businessType: 'Enterprise',
            defaultCurrency: 'SAR',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_A',
            accountId: 'acc-treasury-01',
            businessName: 'Business Alpha',
          ),
        );
    await database
        .into(database.businesses)
        .insert(
          BusinessesCompanion.insert(
            id: 'BUS_B',
            accountId: 'acc-treasury-01',
            businessName: 'Business Beta',
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_1',
            businessId: 'BUS_A',
            branchName: 'Main Branch Alpha',
            branchCode: 'BR-A1',
            isDefault: const drift.Value(true),
          ),
        );
    await database
        .into(database.branches)
        .insert(
          BranchesCompanion.insert(
            id: 'BRANCH_2',
            businessId: 'BUS_A',
            branchName: 'Sub Branch Alpha',
            branchCode: 'BR-A2',
            isDefault: const drift.Value(false),
          ),
        );
    await database
        .into(database.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: 'curr-sar',
            currencyCode: 'SAR',
            currencyNameAr: 'ريال سعودي',
            currencyNameEn: 'Saudi Riyal',
            currencySymbol: 'SAR',
            decimalPlaces: const drift.Value(2),
            exchangeRate: const drift.Value(1.0),
            isBaseCurrency: const drift.Value(true),
          ),
        );

    // Seed AccountTypes
    await database
        .into(database.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: const drift.Value(1),
            nameEn: 'Assets',
            nameAr: 'الأصول',
            slug: 'assets',
          ),
        );

    // Seed Chart of Accounts for Bank, Cash, and Payment Methods
    await database
        .into(database.chartOfAccounts)
        .insert(
          ChartOfAccountsCompanion.insert(
            id: 'coa-bank',
            businessId: 'BUS_A',
            accountCode: '1101',
            accountName: 'Riyad Bank Account',
            accountTypeId: 1,
            normalBalance: 'Debit',
          ),
        );
    await database
        .into(database.chartOfAccounts)
        .insert(
          ChartOfAccountsCompanion.insert(
            id: 'coa-cash',
            businessId: 'BUS_A',
            accountCode: '1102',
            accountName: 'Main Cash Register',
            accountTypeId: 1,
            normalBalance: 'Debit',
          ),
        );

    // Seed Customer and Sales Invoice for payment allocation testing
    await database
        .into(database.customers)
        .insert(
          CustomersCompanion.insert(
            id: 'cust-1',
            businessId: 'BUS_A',
            customerName: 'Customer One',
          ),
        );
    await database
        .into(database.salesInvoices)
        .insert(
          SalesInvoicesCompanion.insert(
            id: 'inv-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            customerId: const drift.Value('cust-1'),
            invoiceNumber: 'INV-1001',
            currencyId: 'curr-sar',
            subTotal: const drift.Value(1000.0),
            grandTotal: const drift.Value(1000.0),
            baseSubTotal: const drift.Value(1000.0),
            baseGrandTotal: const drift.Value(1000.0),
            createdBy: 'u-owner',
          ),
        );
    await database
        .into(database.customerReceivables)
        .insert(
          CustomerReceivablesCompanion.insert(
            id: 'rec-1',
            businessId: 'BUS_A',
            customerId: 'cust-1',
            salesInvoiceId: 'inv-1',
            currencyId: 'curr-sar',
            originalAmount: 1000.0,
            baseOriginalAmount: 1000.0,
            paidAmount: const drift.Value(0.0),
            basePaidAmount: const drift.Value(0.0),
            remainingAmount: 1000.0,
            baseRemainingAmount: 1000.0,
            status: const drift.Value('Unpaid'),
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('TreasuryDao Phase 07 Test Suite -', () {
    test(
      '1. Core CRUD: BankAccounts, CashRegisters, PaymentMethods, Payments, Reconciliations',
      () async {
        // 1. BankAccounts CRUD
        await treasuryDao.insertBankAccount(
          BankAccountsCompanion.insert(
            id: 'acc-bank-1',
            businessId: 'BUS_A',
            branchId: const drift.Value('BRANCH_1'),
            currencyId: 'curr-sar',
            bankName: 'Riyad Bank',
            accountNumber: 'SA100010001000',
            currentBalance: const drift.Value(50000.0),
            status: const drift.Value('Active'),
            isDefault: const drift.Value(true),
          ),
        );

        final bankAcc = await treasuryDao.getBankAccountById(
          'acc-bank-1',
          'BUS_A',
        );
        expect(bankAcc, isNotNull);
        expect(bankAcc!.bankName, equals('Riyad Bank'));
        expect(bankAcc.currentBalance, equals(50000.0));

        await treasuryDao.updateBankAccountBalance(
          'acc-bank-1',
          'BUS_A',
          55000.0,
        );
        final updatedBankAcc = await treasuryDao.getBankAccountById(
          'acc-bank-1',
          'BUS_A',
        );
        expect(updatedBankAcc!.currentBalance, equals(55000.0));

        // 2. CashRegisters CRUD
        await treasuryDao.insertCashRegister(
          CashRegistersCompanion.insert(
            id: 'reg-cash-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            currencyId: 'curr-sar',
            registerName: 'Counter 1 Register',
            currentBalance: const drift.Value(2000.0),
            status: const drift.Value('Open'),
          ),
        );

        final register = await treasuryDao.getCashRegisterById(
          'reg-cash-1',
          'BUS_A',
        );
        expect(register, isNotNull);
        expect(register!.registerName, equals('Counter 1 Register'));

        await treasuryDao.updateCashRegisterStatus(
          'reg-cash-1',
          'BUS_A',
          'Closed',
        );
        final closedRegister = await treasuryDao.getCashRegisterById(
          'reg-cash-1',
          'BUS_A',
        );
        expect(closedRegister!.status, equals('Closed'));

        // 3. PaymentMethods CRUD
        await treasuryDao.insertPaymentMethod(
          PaymentMethodsCompanion.insert(
            id: 'pm-cash',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-cash',
            methodCode: 'CASH',
            methodName: 'Cash Payment',
            paymentType: 'Cash',
            isActive: const drift.Value(true),
          ),
        );

        final pm = await treasuryDao.getPaymentMethodByCode('CASH', 'BUS_A');
        expect(pm, isNotNull);
        expect(pm!.methodName, equals('Cash Payment'));

        // 4. Payments CRUD & Soft Delete
        await treasuryDao.insertPayment(
          PaymentsCompanion.insert(
            id: 'pay-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            paymentNumber: 'RCP-2026-0001',
            paymentMethodId: 'pm-cash',
            chartOfAccountId: 'coa-cash',
            currencyId: 'curr-sar',
            amount: 500.0,
            baseAmount: 500.0,
            paymentType: 'Receipt',
            contactType: const drift.Value('Customer'),
            contactId: const drift.Value('cust-1'),
            status: const drift.Value('Posted'),
            createdBy: 'u-owner',
          ),
        );

        final payment = await treasuryDao.getPaymentById('pay-1', 'BUS_A');
        expect(payment, isNotNull);
        expect(payment!.amount, equals(500.0));

        // Soft delete check
        await treasuryDao.softDeletePayment('pay-1', 'BUS_A');
        final deletedPayment = await treasuryDao.getPaymentById(
          'pay-1',
          'BUS_A',
        );
        expect(deletedPayment, isNull);
        final deletedPaymentIncluding = await treasuryDao.getPaymentById(
          'pay-1',
          'BUS_A',
          includeDeleted: true,
        );
        expect(deletedPaymentIncluding, isNotNull);
        expect(deletedPaymentIncluding!.deletedAt, isNotNull);

        // Restore
        await treasuryDao.restorePayment('pay-1', 'BUS_A');
        final restoredPayment = await treasuryDao.getPaymentById(
          'pay-1',
          'BUS_A',
        );
        expect(restoredPayment, isNotNull);
        expect(restoredPayment!.deletedAt, isNull);

        // 5. BankReconciliation CRUD
        await treasuryDao.recordBankReconciliationWithLines(
          reconciliation: BankReconciliationsCompanion.insert(
            id: 'recon-1',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-bank',
            statementDate: DateTime(2026, 7, 31),
            statementBalance: 55000.0,
            systemBalance: 55000.0,
            difference: 0.0,
            status: const drift.Value('Draft'),
            createdBy: 'u-owner',
          ),
          lines: [
            BankReconciliationLinesCompanion.insert(
              id: 'recon-line-1',
              businessId: 'BUS_A',
              bankReconciliationId: 'recon-1',
              paymentId: 'pay-1',
              isCleared: const drift.Value(false),
            ),
          ],
        );

        final reconWithLines = await treasuryDao
            .getBankReconciliationWithLinesById('recon-1', 'BUS_A');
        expect(reconWithLines, isNotNull);
        expect(reconWithLines!.lines.length, equals(1));
        expect(reconWithLines.lines.first.paymentId, equals('pay-1'));

        await treasuryDao.updateBankReconciliationLineCleared(
          'recon-line-1',
          'BUS_A',
          true,
        );
        final updatedReconWithLines = await treasuryDao
            .getBankReconciliationWithLinesById('recon-1', 'BUS_A');
        expect(updatedReconWithLines!.lines.first.isCleared, isTrue);
      },
    );

    test(
      '2. Tenant Isolation: BUS_A queries never return BUS_B records and throwing on empty businessId',
      () async {
        await treasuryDao.insertBankAccount(
          BankAccountsCompanion.insert(
            id: 'bank-bus-a',
            businessId: 'BUS_A',
            currencyId: 'curr-sar',
            bankName: 'Bank Alpha',
            accountNumber: '1111111111',
          ),
        );
        await treasuryDao.insertBankAccount(
          BankAccountsCompanion.insert(
            id: 'bank-bus-b',
            businessId: 'BUS_B',
            currencyId: 'curr-sar',
            bankName: 'Bank Beta',
            accountNumber: '2222222222',
          ),
        );

        final listA = await treasuryDao.listBankAccounts(
          const BankAccountFilter(businessId: 'BUS_A'),
        );
        expect(listA.any((a) => a.id == 'bank-bus-b'), isFalse);
        expect(listA.any((a) => a.id == 'bank-bus-a'), isTrue);

        final listB = await treasuryDao.listBankAccounts(
          const BankAccountFilter(businessId: 'BUS_B'),
        );
        expect(listB.any((a) => a.id == 'bank-bus-a'), isFalse);
        expect(listB.any((a) => a.id == 'bank-bus-b'), isTrue);

        expect(
          () => treasuryDao.getBankAccountById('bank-bus-a', ''),
          throwsA(isA<TenantScopingException>()),
        );
        expect(
          () => treasuryDao.listBankAccounts(
            const BankAccountFilter(businessId: ''),
          ),
          throwsA(isA<TenantScopingException>()),
        );
      },
    );

    test(
      '3. Branch Scoping: filtering by branchId returns exact or global records',
      () async {
        await treasuryDao.insertCashRegister(
          CashRegistersCompanion.insert(
            id: 'reg-b1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            currencyId: 'curr-sar',
            registerName: 'Branch 1 Reg',
          ),
        );
        await treasuryDao.insertCashRegister(
          CashRegistersCompanion.insert(
            id: 'reg-b2',
            businessId: 'BUS_A',
            branchId: 'BRANCH_2',
            currencyId: 'curr-sar',
            registerName: 'Branch 2 Reg',
          ),
        );

        final regsBranch1 = await treasuryDao.listCashRegisters(
          const CashRegisterFilter(businessId: 'BUS_A', branchId: 'BRANCH_1'),
        );
        expect(regsBranch1.length, equals(1));
        expect(regsBranch1.first.id, equals('reg-b1'));

        final regsBranch2 = await treasuryDao.listCashRegisters(
          const CashRegisterFilter(businessId: 'BUS_A', branchId: 'BRANCH_2'),
        );
        expect(regsBranch2.length, equals(1));
        expect(regsBranch2.first.id, equals('reg-b2'));
      },
    );

    test(
      '4. Atomic Transactional Integrity & Multi-Table Allocation & Balance Adjustments',
      () async {
        await treasuryDao.insertBankAccount(
          BankAccountsCompanion.insert(
            id: 'acc-atomic-bank',
            businessId: 'BUS_A',
            currencyId: 'curr-sar',
            bankName: 'Atomic Bank',
            accountNumber: 'SA99999999',
            currentBalance: const drift.Value(10000.0),
          ),
        );
        await treasuryDao.insertPaymentMethod(
          PaymentMethodsCompanion.insert(
            id: 'pm-bank',
            businessId: 'BUS_A',
            chartOfAccountId: 'coa-bank',
            methodCode: 'BANK',
            methodName: 'Bank Transfer',
            paymentType: 'Bank',
          ),
        );

        // Record atomic receipt voucher allocating 400.0 against customer receivable + bank transaction
        await treasuryDao.recordPaymentWithAllocationsAndTransactions(
          payment: PaymentsCompanion.insert(
            id: 'pay-atomic-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            paymentNumber: 'RCP-2026-0099',
            paymentMethodId: 'pm-bank',
            chartOfAccountId: 'coa-bank',
            currencyId: 'curr-sar',
            amount: 400.0,
            baseAmount: 400.0,
            paymentType: 'Receipt',
            contactType: const drift.Value('Customer'),
            contactId: const drift.Value('cust-1'),
            status: const drift.Value('Posted'),
            createdBy: 'u-owner',
          ),
          allocations: [
            PaymentAllocationsCompanion.insert(
              id: 'alloc-1',
              businessId: 'BUS_A',
              paymentId: 'pay-atomic-1',
              documentType: 'CustomerReceivable',
              documentId: 'rec-1',
              amount: 400.0,
              createdBy: 'u-owner',
            ),
          ],
          bankTransaction: BankTransactionsCompanion.insert(
            id: 'bank-trans-1',
            businessId: 'BUS_A',
            bankAccountId: 'acc-atomic-bank',
            documentType: const drift.Value('Payment'),
            documentId: const drift.Value('pay-atomic-1'),
            transactionType: 'Deposit',
            direction: 'Credit',
            amount: 400.0,
            reconciliationStatus: const drift.Value('Unreconciled'),
            createdBy: const drift.Value('u-owner'),
          ),
        );

        // Verify payment and allocations inserted
        final payWithAlloc = await treasuryDao.getPaymentWithAllocationsById(
          'pay-atomic-1',
          'BUS_A',
        );
        expect(payWithAlloc, isNotNull);
        expect(payWithAlloc!.allocations.length, equals(1));

        // Verify CustomerReceivable paid amount updated from 0 to 400, remaining from 1000 to 600, status Partial
        final rec = await (database.select(
          database.customerReceivables,
        )..where((r) => r.id.equals('rec-1'))).getSingle();
        expect(rec.paidAmount, equals(400.0));
        expect(rec.remainingAmount, equals(600.0));
        expect(rec.status, equals('Partial'));

        // Verify ReceivableEntry created automatically
        final recEntries = await (database.select(
          database.receivableEntries,
        )..where((e) => e.customerReceivableId.equals('rec-1'))).get();
        expect(recEntries.length, equals(1));
        expect(recEntries.first.amount, equals(400.0));

        // Verify BankAccount balance automatically increased by 400 deposit (10000 -> 10400)
        final bankAcc = await treasuryDao.getBankAccountById(
          'acc-atomic-bank',
          'BUS_A',
        );
        expect(bankAcc!.currentBalance, equals(10400.0));

        // Test Rollback on failure (mismatched businessId in allocation)
        expect(
          () => treasuryDao.recordPaymentWithAllocationsAndTransactions(
            payment: PaymentsCompanion.insert(
              id: 'pay-atomic-fail',
              businessId: 'BUS_A',
              branchId: 'BRANCH_1',
              paymentNumber: 'RCP-2026-0100',
              paymentMethodId: 'pm-bank',
              chartOfAccountId: 'coa-bank',
              currencyId: 'curr-sar',
              amount: 200.0,
              baseAmount: 200.0,
              paymentType: 'Receipt',
              createdBy: 'u-owner',
            ),
            allocations: [
              PaymentAllocationsCompanion.insert(
                id: 'alloc-fail',
                businessId:
                    'BUS_B', // Mismatched businessId triggers TenantScopingException inside transaction
                paymentId: 'pay-atomic-fail',
                documentType: 'CustomerReceivable',
                documentId: 'rec-1',
                amount: 200.0,
                createdBy: 'u-owner',
              ),
            ],
          ),
          throwsA(isA<TenantScopingException>()),
        );

        // Verify rollback: no new payment inserted, rec balance remains 400/600
        final failedPay = await treasuryDao.getPaymentById(
          'pay-atomic-fail',
          'BUS_A',
        );
        expect(failedPay, isNull);
        final recAfterFail = await (database.select(
          database.customerReceivables,
        )..where((r) => r.id.equals('rec-1'))).getSingle();
        expect(recAfterFail.paidAmount, equals(400.0));
      },
    );

    test('5. Offline-First Sync Flag Management', () async {
      await treasuryDao.insertBankAccount(
        BankAccountsCompanion.insert(
          id: 'acc-sync-1',
          businessId: 'BUS_A',
          currencyId: 'curr-sar',
          bankName: 'Sync Bank',
          accountNumber: 'SA88888888',
        ),
      );

      final pendingBanks = await treasuryDao.getPendingSyncBankAccounts(
        'BUS_A',
      );
      expect(pendingBanks.any((a) => a.id == 'acc-sync-1'), isTrue);

      await treasuryDao.markBankAccountsAsSynced(['acc-sync-1'], 'BUS_A');
      final afterSyncBanks = await treasuryDao.getPendingSyncBankAccounts(
        'BUS_A',
      );
      expect(afterSyncBanks.any((a) => a.id == 'acc-sync-1'), isFalse);
    });

    test(
      '6. Reactive Stream Emittance: watchBankAccountById and watchCashRegisterById emit updates',
      () async {
        await treasuryDao.insertCashRegister(
          CashRegistersCompanion.insert(
            id: 'reg-stream-1',
            businessId: 'BUS_A',
            branchId: 'BRANCH_1',
            currencyId: 'curr-sar',
            registerName: 'Stream Reg',
            currentBalance: const drift.Value(100.0),
          ),
        );

        final stream = treasuryDao.watchCashRegisterById(
          'reg-stream-1',
          'BUS_A',
        );
        final expectation = expectLater(
          stream.map((c) => c?.currentBalance),
          emitsInOrder([100.0, 250.0]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await treasuryDao.updateCashRegisterBalance(
          'reg-stream-1',
          'BUS_A',
          250.0,
        );

        await expectation;
      },
    );
  });
}
