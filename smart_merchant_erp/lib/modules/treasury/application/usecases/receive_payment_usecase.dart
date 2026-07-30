import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/core/usecase.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../accounting/application/services/accounting_application_service.dart';
import '../../../accounting/domain/repositories/accounting_repository.dart';
import '../../../sales/domain/repositories/sales_repository.dart';
import '../../domain/repositories/treasury_repository.dart';

class PaymentAllocationCommand {
  final String receivableId;
  final double allocatedAmount;

  const PaymentAllocationCommand({
    required this.receivableId,
    required this.allocatedAmount,
  });
}

class ReceivePaymentCommand {
  final String customerId;
  final double amount;
  final String currencyId;
  final double exchangeRate;
  final String paymentMethodId;
  final String chartOfAccountId; // The bank/cash account receiving the funds
  final String? notes;
  final List<PaymentAllocationCommand> allocations;

  const ReceivePaymentCommand({
    required this.customerId,
    required this.amount,
    required this.currencyId,
    required this.paymentMethodId,
    required this.chartOfAccountId,
    this.exchangeRate = 1.0,
    this.notes,
    this.allocations = const [],
  });
}

class ReceivePaymentUseCase implements UseCase<String, ReceivePaymentCommand> {
  final TreasuryRepository _treasuryRepository;
  final SalesRepository _salesRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  ReceivePaymentUseCase(
    this._treasuryRepository,
    this._salesRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(ReceivePaymentCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for receiving payment.'),
      );
    }
    if (params.amount <= 0) {
      return const Left(
        ValidationFailure('Payment amount must be greater than zero.'),
      );
    }

    // 1. Validate Allocations match total amount
    double totalAllocated = 0.0;
    for (final allocation in params.allocations) {
      if (allocation.allocatedAmount <= 0) {
        return const Left(
          ValidationFailure('Allocated amounts must be greater than zero.'),
        );
      }
      totalAllocated += allocation.allocatedAmount;
    }

    // Using rounding to avoid floating point precision issues
    if (params.allocations.isNotEmpty &&
        (totalAllocated * 100).round() != (params.amount * 100).round()) {
      return const Left(
        ValidationFailure('Total allocations must equal the payment amount.'),
      );
    }

    // 2. Fetch Accounts Receivable Mapping for Journal
    final arIdResult = await _accountingService.resolveAccountMapping(
      'accounts_receivable',
    );
    if (arIdResult.isLeft())
      return Left(arIdResult.fold((l) => l, (r) => throw Exception()));
    final accountsReceivableId = arIdResult.getOrElse(() => '');

    final paymentDate = DateTime.now();
    final paymentId = _uuid.v4();
    final paymentNumber = 'RCP-${paymentDate.millisecondsSinceEpoch}';

    // 3. Prepare Payment Entities
    final paymentCompanion = PaymentsCompanion.insert(
      id: paymentId,
      businessId: businessId,
      branchId: branchId,
      paymentNumber: paymentNumber,
      paymentDate: drift.Value(paymentDate),
      paymentMethodId: params.paymentMethodId,
      chartOfAccountId: params.chartOfAccountId,
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      amount: params.amount,
      baseAmount: params.amount * params.exchangeRate,
      paymentType: 'Receipt',
      contactType: const drift.Value('Customer'),
      contactId: drift.Value(params.customerId),
      status: const drift.Value('Posted'),
      notes: drift.Value(params.notes),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(paymentDate),
    );

    final allocationCompanions = params.allocations.map((alloc) {
      return PaymentAllocationsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        paymentId: paymentId,
        amount: alloc.allocatedAmount,
        documentType: 'CustomerReceivable',
        documentId: alloc.receivableId,
        createdBy: userId,
      );
    }).toList();

    // 4. Validate and Prepare Receivable Updates
    final List<Map<String, dynamic>> receivableUpdates = [];
    for (final alloc in params.allocations) {
      final receivable = await _salesRepository.getReceivableById(
        alloc.receivableId,
        businessId,
      );
      if (receivable == null) {
        return Left(
          ValidationFailure('Receivable not found: ${alloc.receivableId}'),
        );
      }
      if (params.amount > receivable.remainingAmount) {
        return Left(
          ValidationFailure(
            'Allocation exceeds remaining amount for receivable ${receivable.salesInvoiceId}',
          ),
        );
      }

      final newPaidAmount = receivable.paidAmount + alloc.allocatedAmount;
      final newRemainingAmount =
          receivable.remainingAmount - alloc.allocatedAmount;

      final newStatus = newRemainingAmount <= 0.001
          ? 'Paid'
          : (newPaidAmount > 0 ? 'Partial' : 'Unpaid');

      final entryCompanion = ReceivableEntriesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        customerReceivableId: receivable.id,
        entryType: const drift.Value('Payment'),
        paymentId: drift.Value(paymentId),
        amount: alloc.allocatedAmount,
        baseAmount: alloc.allocatedAmount * params.exchangeRate,
        createdBy: userId,
      );

      receivableUpdates.add({
        'receivableId': alloc.receivableId,
        'entryCompanion': entryCompanion,
        'newPaidAmount': newPaidAmount,
        'newRemainingAmount': newRemainingAmount,
        'newBasePaidAmount': newPaidAmount * params.exchangeRate,
        'newBaseRemainingAmount': newRemainingAmount * params.exchangeRate,
        'newStatus': newStatus,
        'id': receivable.id,
        'salesInvoiceId': receivable.salesInvoiceId,
        'referenceId': receivable.salesInvoiceId,
      });
    }

    // 5. Prepare Journal Entry
    final periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, status: 'Open'),
    );
    if (periods.isEmpty) {
      return const Left(
        BusinessValidationFailure(
          'No active fiscal period found for accounting posting.',
        ),
      );
    }
    final period = periods.first;

    final journalId = _uuid.v4();
    final journalNumber = 'JE-${paymentDate.millisecondsSinceEpoch}';
    int lineSequence = 1;

    final entryCompanion = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: journalNumber,
      documentDate: paymentDate,
      postingDate: drift.Value(paymentDate),
      journalType: 'Payment',
      documentType: 'Payment',
      documentId: drift.Value(paymentId),
      documentNumber: drift.Value(paymentNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value('Payment Receipt $paymentNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(paymentDate),
    );

    final List<JournalEntryLinesCompanion> journalLines = [
      // Debit: Bank/Cash Account
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: params.chartOfAccountId,
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Debit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(params.amount * params.exchangeRate),
        description: const drift.Value('Payment Received'),
      ),
      // Credit: Accounts Receivable
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: accountsReceivableId,
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Credit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(params.amount * params.exchangeRate),
        description: const drift.Value('Receivable Settlement'),
      ),
    ];

    // 6. Execute Transaction
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Payment & Allocations
        await _treasuryRepository.recordPaymentWithAllocationsAndTransactions(
          payment: paymentCompanion,
          allocations: allocationCompanions,
        );

        // Update Receivables & Invoices
        for (final update in receivableUpdates) {
          await _salesRepository.recordReceivableEntry(
            update['entryCompanion'] as ReceivableEntriesCompanion,
            customerReceivableId: update['receivableId'] as String,
            businessId: businessId,
            newPaidAmount: update['newPaidAmount'] as double,
            newRemainingAmount: update['newRemainingAmount'] as double,
            newBasePaidAmount: update['newBasePaidAmount'] as double,
            newBaseRemainingAmount: update['newBaseRemainingAmount'] as double,
            newStatus: update['newStatus'] as String,
          );

          // Update Invoice Payment Status if applicable
          if (update['referenceId'] != null) {
            final invoiceId = update['referenceId'] as String;
            final invoice = await _salesRepository.getInvoiceById(
              invoiceId,
              businessId,
            );
            if (invoice != null) {
              final newPaymentStatus = (update['newStatus'] as String) == 'Paid'
                  ? 'Paid'
                  : 'Partial';
              await _salesRepository.updateInvoicePaymentStatus(
                invoiceId,
                businessId,
                newPaymentStatus,
              );
            }
          }
        }

        // Post Accounting Journal
        await _accountingRepository.postJournalEntryWithLines(
          entry: entryCompanion,
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

class BusinessValidationFailure extends Failure {
  const BusinessValidationFailure(super.message, [super.code]);
}
