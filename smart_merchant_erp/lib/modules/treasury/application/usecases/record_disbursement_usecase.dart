import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/core/usecase.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../accounting/application/services/accounting_application_service.dart';
import '../../../accounting/domain/repositories/accounting_repository.dart';
import '../../../purchasing/domain/repositories/purchasing_repository.dart';
import '../../domain/repositories/treasury_repository.dart';

enum DisbursementType {
  supplierPayment,
  expense,
}

class PayableAllocationCommand {
  final String payableId;
  final double allocatedAmount;

  const PayableAllocationCommand({
    required this.payableId,
    required this.allocatedAmount,
  });
}

class RecordDisbursementCommand {
  final DisbursementType type;
  final double amount;
  final String currencyId;
  final double exchangeRate;
  final String paymentMethodId;
  final String chartOfAccountId; // Source cash/bank account
  final String? supplierId;
  final String? expenseAccountId;
  final String? notes;
  final String? cashRegisterId;
  final String? bankAccountId;
  final List<PayableAllocationCommand> allocations;

  const RecordDisbursementCommand({
    required this.type,
    required this.amount,
    required this.currencyId,
    required this.paymentMethodId,
    required this.chartOfAccountId,
    this.supplierId,
    this.expenseAccountId,
    this.exchangeRate = 1.0,
    this.notes,
    this.cashRegisterId,
    this.bankAccountId,
    this.allocations = const [],
  });
}

class RecordDisbursementUseCase
    implements UseCase<String, RecordDisbursementCommand> {
  final TreasuryRepository _treasuryRepository;
  final PurchasingRepository _purchasingRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  RecordDisbursementUseCase(
    this._treasuryRepository,
    this._purchasingRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(RecordDisbursementCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for recording disbursement.'),
      );
    }
    if (params.amount <= 0) {
      return const Left(
        ValidationFailure('Disbursement amount must be greater than zero.'),
      );
    }

    // 1. Verify source account allows posting
    final sourceAccount = await _accountingRepository.getChartOfAccountById(
      params.chartOfAccountId,
      businessId,
    );
    if (sourceAccount == null) {
      return const Left(ValidationFailure('Source cash/bank account not found.'));
    }
    if (!sourceAccount.allowPosting) {
      return const Left(
        ValidationFailure(
          'Source account is a parent group and does not allow direct transactions.',
        ),
      );
    }

    // 2. Resolve target debit account
    String targetDebitAccountId;
    if (params.type == DisbursementType.supplierPayment) {
      if (params.supplierId == null || params.supplierId!.trim().isEmpty) {
        return const Left(
          ValidationFailure('Supplier ID is required for supplier payments.'),
        );
      }
      final apResult = await _accountingService.resolveAccountMapping(
        'accounts_payable',
      );
      if (apResult.isLeft()) {
        return Left(apResult.fold((l) => l, (r) => throw Exception()));
      }
      targetDebitAccountId = apResult.getOrElse(() => '');
    } else {
      if (params.expenseAccountId == null ||
          params.expenseAccountId!.trim().isEmpty) {
        return const Left(
          ValidationFailure('Expense account is required for expense disbursements.'),
        );
      }
      final expenseAccount = await _accountingRepository.getChartOfAccountById(
        params.expenseAccountId!,
        businessId,
      );
      if (expenseAccount == null) {
        return const Left(ValidationFailure('Target expense account not found.'));
      }
      if (!expenseAccount.allowPosting) {
        return const Left(
          ValidationFailure(
            'Target expense account is a parent group and does not allow direct transactions.',
          ),
        );
      }
      targetDebitAccountId = params.expenseAccountId!;
    }

    // 3. Validate Allocations if provided
    double totalAllocated = 0.0;
    for (final alloc in params.allocations) {
      if (alloc.allocatedAmount <= 0) {
        return const Left(
          ValidationFailure('Allocated amounts must be greater than zero.'),
        );
      }
      totalAllocated += alloc.allocatedAmount;
    }
    if (params.allocations.isNotEmpty &&
        (totalAllocated * 100).round() != (params.amount * 100).round()) {
      return const Left(
        ValidationFailure('Total allocations must equal the disbursement amount.'),
      );
    }

    // 4. Fetch open fiscal period
    final periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, status: 'Open'),
    );
    if (periods.isEmpty) {
      return const Left(
        ValidationFailure(
          'No active fiscal period found for accounting posting.',
        ),
      );
    }
    final period = periods.first;

    final voucherDate = DateTime.now();
    final paymentId = _uuid.v4();
    final voucherNumber = 'PAY-${voucherDate.millisecondsSinceEpoch}';
    final roundedBaseAmount = PrecisionMath.roundMoney(
      params.amount * params.exchangeRate,
    );

    // 5. Build Payment Companion
    final paymentCompanion = PaymentsCompanion.insert(
      id: paymentId,
      businessId: businessId,
      branchId: branchId,
      paymentNumber: voucherNumber,
      paymentDate: drift.Value(voucherDate),
      paymentMethodId: params.paymentMethodId,
      chartOfAccountId: params.chartOfAccountId,
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      amount: PrecisionMath.roundMoney(params.amount),
      baseAmount: roundedBaseAmount,
      paymentType: 'Payment',
      contactType: drift.Value(
        params.type == DisbursementType.supplierPayment ? 'Supplier' : 'Other',
      ),
      contactId: drift.Value(params.supplierId),
      status: const drift.Value('Posted'),
      notes: drift.Value(params.notes),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(voucherDate),
    );

    // 6. Build Allocations Companion
    final allocationCompanions = params.allocations.map((alloc) {
      return PaymentAllocationsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        paymentId: paymentId,
        amount: PrecisionMath.roundMoney(alloc.allocatedAmount),
        documentType: 'SupplierPayable',
        documentId: alloc.payableId,
        createdBy: userId,
      );
    }).toList();

    // 7. Optional Cash / Bank Transaction Companions
    CashTransactionsCompanion? cashTx;
    if (params.cashRegisterId != null && params.cashRegisterId!.isNotEmpty) {
      cashTx = CashTransactionsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        cashRegisterId: params.cashRegisterId!,
        transactionType: 'Disbursement',
        amount: PrecisionMath.roundMoney(params.amount),
        documentType: const drift.Value('Payment'),
        documentId: drift.Value(paymentId),
        notes: drift.Value(params.notes ?? 'Payment Voucher $voucherNumber'),
        createdBy: drift.Value(userId),
      );
    }

    BankTransactionsCompanion? bankTx;
    if (params.bankAccountId != null && params.bankAccountId!.isNotEmpty) {
      bankTx = BankTransactionsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        bankAccountId: params.bankAccountId!,
        transactionType: 'Withdrawal',
        direction: 'Debit',
        amount: PrecisionMath.roundMoney(params.amount),
        documentType: const drift.Value('Payment'),
        documentId: drift.Value(paymentId),
        notes: drift.Value(params.notes ?? 'Payment Voucher $voucherNumber'),
        createdBy: drift.Value(userId),
      );
    }

    // 8. Build Journal Entry
    final journalId = _uuid.v4();
    final journalNumber = 'JE-${voucherDate.millisecondsSinceEpoch}';

    final journalEntry = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: journalNumber,
      documentDate: voucherDate,
      postingDate: drift.Value(voucherDate),
      journalType: 'Payment',
      documentType: 'Payment',
      documentId: drift.Value(paymentId),
      documentNumber: drift.Value(voucherNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value(
        params.type == DisbursementType.supplierPayment
            ? 'Supplier Settlement $voucherNumber'
            : 'Expense Disbursement $voucherNumber',
      ),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(voucherDate),
    );

    final journalLines = [
      // Debit: Supplier A/P or Expense Account
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: targetDebitAccountId,
        currencyId: params.currencyId,
        lineNumber: 1,
        type: 'Debit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: drift.Value(
          params.type == DisbursementType.supplierPayment
              ? 'Supplier Payable Settlement'
              : 'Direct Expense Payment',
        ),
      ),
      // Credit: Cash / Bank Account
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: params.chartOfAccountId,
        currencyId: params.currencyId,
        lineNumber: 2,
        type: 'Credit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: const drift.Value('Cash/Bank Disbursement'),
      ),
    ];

    if (!PrecisionMath.areBalanced(roundedBaseAmount, roundedBaseAmount)) {
      return const Left(ValidationFailure('Journal entry lines are not balanced.'));
    }

    // 9. Atomic Transaction Execution
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record payment, allocations, and update cash/bank registers & balances
        await _treasuryRepository.recordPaymentWithAllocationsAndTransactions(
          payment: paymentCompanion,
          allocations: allocationCompanions,
          cashTransaction: cashTx,
          bankTransaction: bankTx,
        );

        // Post balanced General Ledger Journal Entry
        await _accountingRepository.postJournalEntryWithLines(
          entry: journalEntry,
          lines: journalLines,
        );
      });

      return Right(paymentId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
