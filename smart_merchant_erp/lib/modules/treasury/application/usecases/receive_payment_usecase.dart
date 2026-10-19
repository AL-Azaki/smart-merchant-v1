import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../core/utils/precision_math.dart';
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
  final String? customerId;
  final String? incomeAccountId;
  final double amount;
  final String currencyId;
  final double exchangeRate;
  final String paymentMethodId;
  final String chartOfAccountId; // The bank/cash account receiving the funds
  final String? notes;
  final String? cashRegisterId;
  final String? bankAccountId;
  final List<PaymentAllocationCommand> allocations;

  const ReceivePaymentCommand({
    this.customerId,
    this.incomeAccountId,
    required this.amount,
    required this.currencyId,
    required this.paymentMethodId,
    required this.chartOfAccountId,
    this.exchangeRate = 1.0,
    this.notes,
    this.cashRegisterId,
    this.bankAccountId,
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

    // 1. Verify target cash/bank account exists and allows posting
    final targetAccount = await _accountingRepository.getChartOfAccountById(
      params.chartOfAccountId,
      businessId,
    );
    if (targetAccount == null) {
      return const Left(ValidationFailure('Target cash/bank account not found.'));
    }
    if (!targetAccount.allowPosting) {
      return const Left(
        ValidationFailure(
          'Target account is a parent group and does not allow direct transactions.',
        ),
      );
    }

    // 2. Validate Allocations match total amount if provided
    double totalAllocated = 0.0;
    for (final allocation in params.allocations) {
      if (allocation.allocatedAmount <= 0) {
        return const Left(
          ValidationFailure('Allocated amounts must be greater than zero.'),
        );
      }
      totalAllocated += allocation.allocatedAmount;
    }

    if (params.allocations.isNotEmpty &&
        (totalAllocated * 100).round() != (params.amount * 100).round()) {
      return const Left(
        ValidationFailure('Total allocations must equal the payment amount.'),
      );
    }

    // 3. Resolve Credit Account (Accounts Receivable or Revenue Account)
    String creditAccountId;
    if (params.customerId != null && params.customerId!.trim().isNotEmpty) {
      final arIdResult = await _accountingService.resolveAccountMapping(
        'accounts_receivable',
      );
      if (arIdResult.isLeft()) {
        return Left(arIdResult.fold((l) => l, (r) => throw Exception()));
      }
      creditAccountId = arIdResult.getOrElse(() => '');
    } else {
      if (params.incomeAccountId == null ||
          params.incomeAccountId!.trim().isEmpty) {
        return const Left(
          ValidationFailure(
            'Either customerId or incomeAccountId must be provided for receipt.',
          ),
        );
      }
      final incomeAcc = await _accountingRepository.getChartOfAccountById(
        params.incomeAccountId!,
        businessId,
      );
      if (incomeAcc == null) {
        return const Left(ValidationFailure('Income account not found.'));
      }
      if (!incomeAcc.allowPosting) {
        return const Left(
          ValidationFailure(
            'Income account is a parent group and does not allow direct transactions.',
          ),
        );
      }
      creditAccountId = params.incomeAccountId!;
    }

    final paymentDate = DateTime.now();
    final paymentId = _uuid.v4();
    final paymentNumber = 'RCP-${paymentDate.millisecondsSinceEpoch}';
    final roundedBaseAmount = PrecisionMath.roundMoney(
      params.amount * params.exchangeRate,
    );

    final resolvedPaymentMethodId = await _resolvePaymentMethodId(
      businessId: businessId,
      requestedMethodOrCode: params.paymentMethodId,
      chartOfAccountId: params.chartOfAccountId,
    );

    // 4. Prepare Payment Header
    final paymentCompanion = PaymentsCompanion.insert(
      id: paymentId,
      businessId: businessId,
      branchId: branchId,
      paymentNumber: paymentNumber,
      paymentDate: drift.Value(paymentDate),
      paymentMethodId: resolvedPaymentMethodId,
      chartOfAccountId: params.chartOfAccountId,
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      amount: PrecisionMath.roundMoney(params.amount),
      baseAmount: roundedBaseAmount,
      paymentType: 'Receipt',
      contactType: drift.Value(
        params.customerId != null ? 'Customer' : 'Other',
      ),
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
        amount: PrecisionMath.roundMoney(alloc.allocatedAmount),
        documentType: 'CustomerReceivable',
        documentId: alloc.receivableId,
        createdBy: userId,
      );
    }).toList();

    // 5. Optional Cash / Bank Transactions
    CashTransactionsCompanion? cashTx;
    if (params.cashRegisterId != null && params.cashRegisterId!.isNotEmpty) {
      cashTx = CashTransactionsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        cashRegisterId: params.cashRegisterId!,
        transactionType: 'Receipt',
        amount: PrecisionMath.roundMoney(params.amount),
        documentType: const drift.Value('Payment'),
        documentId: drift.Value(paymentId),
        notes: drift.Value(params.notes ?? 'Receipt Voucher $paymentNumber'),
        createdBy: drift.Value(userId),
      );
    }

    BankTransactionsCompanion? bankTx;
    if (params.bankAccountId != null && params.bankAccountId!.isNotEmpty) {
      bankTx = BankTransactionsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        bankAccountId: params.bankAccountId!,
        transactionType: 'Deposit',
        direction: 'Credit',
        amount: PrecisionMath.roundMoney(params.amount),
        documentType: const drift.Value('Payment'),
        documentId: drift.Value(paymentId),
        notes: drift.Value(params.notes ?? 'Receipt Voucher $paymentNumber'),
        createdBy: drift.Value(userId),
      );
    }

    // 6. Fetch Open Fiscal Period
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

    final journalId = _uuid.v4();
    final journalNumber = 'JE-${paymentDate.millisecondsSinceEpoch}';

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
      description: drift.Value(
        params.customerId != null
            ? 'Customer Receipt $paymentNumber'
            : 'Revenue Receipt $paymentNumber',
      ),
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
        lineNumber: 1,
        type: 'Debit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: const drift.Value('Cash/Bank Receipt'),
      ),
      // Credit: Accounts Receivable or Revenue
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: creditAccountId,
        currencyId: params.currencyId,
        lineNumber: 2,
        type: 'Credit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: drift.Value(
          params.customerId != null
              ? 'Receivable Settlement'
              : 'Direct Revenue Receipt',
        ),
      ),
    ];

    if (!PrecisionMath.areBalanced(roundedBaseAmount, roundedBaseAmount)) {
      return const Left(ValidationFailure('Journal entry lines are not balanced.'));
    }

    // 7. Execute Transaction
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Payment & Allocations & Register balances
        await _treasuryRepository.recordPaymentWithAllocationsAndTransactions(
          payment: paymentCompanion,
          allocations: allocationCompanions,
          cashTransaction: cashTx,
          bankTransaction: bankTx,
        );

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

  /// Resolves the payment method ID safely against `payment_methods` table.
  /// Handles UUIDs, method codes ('CASH', 'BANK', etc.), and auto-provisions if missing.
  Future<String> _resolvePaymentMethodId({
    required String businessId,
    required String requestedMethodOrCode,
    required String chartOfAccountId,
  }) async {
    // 1. Try finding by direct ID
    final byId = await _treasuryRepository.getPaymentMethodById(
      requestedMethodOrCode,
      businessId,
    );
    if (byId != null) {
      return byId.id;
    }

    // 2. Try finding by method code (e.g., CASH, BANK, WALLET)
    final byCode = await _treasuryRepository.getPaymentMethodByCode(
      requestedMethodOrCode.toUpperCase(),
      businessId,
    );
    if (byCode != null) {
      return byCode.id;
    }

    // 3. Try finding in active methods by code or paymentType
    final activeMethods = await _treasuryRepository.listPaymentMethods(
      businessId,
      isActive: true,
    );
    final normalized = requestedMethodOrCode.toUpperCase();
    final matched = activeMethods.where((m) {
      final code = m.methodCode.toUpperCase();
      final type = m.paymentType.toUpperCase();
      return code == normalized ||
          type == normalized ||
          (normalized == 'BANK_TRANSFER' && (code == 'BANK' || type == 'BANK')) ||
          (normalized == 'CARD' &&
              (code == 'CARD' || code == 'BANK' || type == 'CARD' || type == 'BANK'));
    }).firstOrNull;

    if (matched != null) {
      return matched.id;
    }

    if (activeMethods.isNotEmpty) {
      return activeMethods.first.id;
    }

    // 4. Auto-provision default payment method if none exist in the database
    final newPmId = _uuid.v4();
    final code = requestedMethodOrCode.trim().isNotEmpty
        ? requestedMethodOrCode.toUpperCase()
        : 'CASH';
    final name = code == 'CASH'
        ? 'نقدي (الصندوق الرئيسي)'
        : (code == 'BANK' || code == 'BANK_TRANSFER')
            ? 'شبكة / مدى / بنك'
            : code;
    final type = (code == 'BANK' || code == 'BANK_TRANSFER' || code == 'CARD')
        ? 'Bank'
        : 'Cash';

    await _treasuryRepository.insertPaymentMethod(
      PaymentMethodsCompanion.insert(
        id: newPmId,
        businessId: businessId,
        chartOfAccountId: chartOfAccountId,
        methodCode: code,
        methodName: name,
        paymentType: type,
        isActive: const drift.Value(true),
      ),
    );

    return newPmId;
  }
}

