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
import '../../../accounting/domain/repositories/accounting_repository.dart';
import '../../domain/repositories/treasury_repository.dart';

class InternalFundTransferCommand {
  final String fromAccountId; // Source Chart of Account
  final String toAccountId; // Destination Chart of Account
  final double amount;
  final String currencyId;
  final double exchangeRate;
  final String paymentMethodId;
  final String? notes;
  final String? fromCashRegisterId;
  final String? toCashRegisterId;
  final String? fromBankAccountId;
  final String? toBankAccountId;

  const InternalFundTransferCommand({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.currencyId,
    required this.paymentMethodId,
    this.exchangeRate = 1.0,
    this.notes,
    this.fromCashRegisterId,
    this.toCashRegisterId,
    this.fromBankAccountId,
    this.toBankAccountId,
  });
}

class InternalFundTransferUseCase
    implements UseCase<String, InternalFundTransferCommand> {
  final TreasuryRepository _treasuryRepository;
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  InternalFundTransferUseCase(
    this._treasuryRepository,
    this._accountingRepository,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(
    InternalFundTransferCommand params,
  ) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for internal fund transfer.'),
      );
    }
    if (params.amount <= 0) {
      return const Left(
        ValidationFailure('Transfer amount must be greater than zero.'),
      );
    }
    if (params.fromAccountId == params.toAccountId) {
      return const Left(
        ValidationFailure(
          'Source and destination accounts must be different.',
        ),
      );
    }

    // 1. Verify source and destination accounts allow posting
    final fromAccount = await _accountingRepository.getChartOfAccountById(
      params.fromAccountId,
      businessId,
    );
    if (fromAccount == null) {
      return const Left(ValidationFailure('Source cash/bank account not found.'));
    }
    if (!fromAccount.allowPosting) {
      return const Left(
        ValidationFailure('Source account does not allow direct transactions.'),
      );
    }

    final toAccount = await _accountingRepository.getChartOfAccountById(
      params.toAccountId,
      businessId,
    );
    if (toAccount == null) {
      return const Left(
        ValidationFailure('Destination cash/bank account not found.'),
      );
    }
    if (!toAccount.allowPosting) {
      return const Left(
        ValidationFailure(
          'Destination account does not allow direct transactions.',
        ),
      );
    }

    // 2. Fetch Open Fiscal Period
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

    final transferDate = DateTime.now();
    final paymentId = _uuid.v4();
    final voucherNumber = 'TRF-${transferDate.millisecondsSinceEpoch}';
    final roundedBaseAmount = PrecisionMath.roundMoney(
      params.amount * params.exchangeRate,
    );

    final resolvedPaymentMethodId = await _resolvePaymentMethodId(
      businessId: businessId,
      requestedMethodOrCode: params.paymentMethodId,
      chartOfAccountId: params.fromAccountId,
    );

    // 3. Prepare Transfer Payment Header
    final paymentCompanion = PaymentsCompanion.insert(
      id: paymentId,
      businessId: businessId,
      branchId: branchId,
      paymentNumber: voucherNumber,
      paymentDate: drift.Value(transferDate),
      paymentMethodId: resolvedPaymentMethodId,
      chartOfAccountId: params.fromAccountId,
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      amount: PrecisionMath.roundMoney(params.amount),
      baseAmount: roundedBaseAmount,
      paymentType: 'Transfer',
      contactType: const drift.Value('Other'),
      status: const drift.Value('Posted'),
      notes: drift.Value(params.notes ?? 'Internal Fund Transfer $voucherNumber'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(transferDate),
    );

    // 4. Build Journal Entry
    final journalId = _uuid.v4();
    final journalNumber = 'JE-${transferDate.millisecondsSinceEpoch}';

    final journalEntry = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: journalNumber,
      documentDate: transferDate,
      postingDate: drift.Value(transferDate),
      journalType: 'Payment',
      documentType: 'Payment',
      documentId: drift.Value(paymentId),
      documentNumber: drift.Value(voucherNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value('Internal Fund Transfer $voucherNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(transferDate),
    );

    final journalLines = [
      // Debit: Destination Account (Receiving Funds)
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: params.toAccountId,
        currencyId: params.currencyId,
        lineNumber: 1,
        type: 'Debit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: const drift.Value('Transfer In / Deposit'),
      ),
      // Credit: Source Account (Disbursing Funds)
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: params.fromAccountId,
        currencyId: params.currencyId,
        lineNumber: 2,
        type: 'Credit',
        foreignAmount: drift.Value(params.amount),
        baseAmount: drift.Value(roundedBaseAmount),
        description: const drift.Value('Transfer Out / Withdrawal'),
      ),
    ];

    if (!PrecisionMath.areBalanced(roundedBaseAmount, roundedBaseAmount)) {
      return const Left(
        ValidationFailure('Journal entry lines are not balanced.'),
      );
    }

    // 5. Atomic Execution
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record payment header
        await _treasuryRepository.insertPayment(paymentCompanion);

        // Adjust source balances and transactions
        if (params.fromCashRegisterId != null &&
            params.fromCashRegisterId!.isNotEmpty) {
          final reg = await _treasuryRepository.getCashRegisterById(
            params.fromCashRegisterId!,
            businessId,
          );
          if (reg != null) {
            await _treasuryRepository.insertCashTransaction(
              CashTransactionsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                cashRegisterId: params.fromCashRegisterId!,
                transactionType: 'TransferOut',
                amount: PrecisionMath.roundMoney(params.amount),
                documentType: const drift.Value('Payment'),
                documentId: drift.Value(paymentId),
                notes: drift.Value('Transfer to ${toAccount.accountName}'),
                createdBy: drift.Value(userId),
              ),
            );
            await _treasuryRepository.updateCashRegisterBalance(
              params.fromCashRegisterId!,
              businessId,
              reg.currentBalance - params.amount,
            );
          }
        }

        if (params.fromBankAccountId != null &&
            params.fromBankAccountId!.isNotEmpty) {
          final bank = await _treasuryRepository.getBankAccountById(
            params.fromBankAccountId!,
            businessId,
          );
          if (bank != null) {
            await _treasuryRepository.insertBankTransaction(
              BankTransactionsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                bankAccountId: params.fromBankAccountId!,
                transactionType: 'TransferOut',
                direction: 'Debit',
                amount: PrecisionMath.roundMoney(params.amount),
                documentType: const drift.Value('Payment'),
                documentId: drift.Value(paymentId),
                notes: drift.Value('Transfer to ${toAccount.accountName}'),
                createdBy: drift.Value(userId),
              ),
            );
            await _treasuryRepository.updateBankAccountBalance(
              params.fromBankAccountId!,
              businessId,
              bank.currentBalance - params.amount,
            );
          }
        }

        // Adjust destination balances and transactions
        if (params.toCashRegisterId != null &&
            params.toCashRegisterId!.isNotEmpty) {
          final reg = await _treasuryRepository.getCashRegisterById(
            params.toCashRegisterId!,
            businessId,
          );
          if (reg != null) {
            await _treasuryRepository.insertCashTransaction(
              CashTransactionsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                cashRegisterId: params.toCashRegisterId!,
                transactionType: 'TransferIn',
                amount: PrecisionMath.roundMoney(params.amount),
                documentType: const drift.Value('Payment'),
                documentId: drift.Value(paymentId),
                notes: drift.Value('Transfer from ${fromAccount.accountName}'),
                createdBy: drift.Value(userId),
              ),
            );
            await _treasuryRepository.updateCashRegisterBalance(
              params.toCashRegisterId!,
              businessId,
              reg.currentBalance + params.amount,
            );
          }
        }

        if (params.toBankAccountId != null &&
            params.toBankAccountId!.isNotEmpty) {
          final bank = await _treasuryRepository.getBankAccountById(
            params.toBankAccountId!,
            businessId,
          );
          if (bank != null) {
            await _treasuryRepository.insertBankTransaction(
              BankTransactionsCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                bankAccountId: params.toBankAccountId!,
                transactionType: 'TransferIn',
                direction: 'Credit',
                amount: PrecisionMath.roundMoney(params.amount),
                documentType: const drift.Value('Payment'),
                documentId: drift.Value(paymentId),
                notes: drift.Value('Transfer from ${fromAccount.accountName}'),
                createdBy: drift.Value(userId),
              ),
            );
            await _treasuryRepository.updateBankAccountBalance(
              params.toBankAccountId!,
              businessId,
              bank.currentBalance + params.amount,
            );
          }
        }

        // Post balanced Journal Entry
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

