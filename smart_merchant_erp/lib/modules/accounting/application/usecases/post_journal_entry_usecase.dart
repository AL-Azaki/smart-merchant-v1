import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/core/usecase.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../core/domain/repositories/core_repository.dart';
import '../../domain/repositories/accounting_repository.dart';

class JournalEntryLineCommand {
  final String accountId;
  final double debit;
  final double credit;
  final String? description;

  const JournalEntryLineCommand({
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });
}

class PostJournalEntryCommand {
  final String fiscalYearId;
  final String fiscalPeriodId;
  final DateTime documentDate;
  final String journalType;
  final String documentType;
  final String? documentId;
  final String? documentNumber;
  final String currencyId;
  final double exchangeRate;
  final String? description;
  final List<JournalEntryLineCommand> lines;

  const PostJournalEntryCommand({
    required this.fiscalYearId,
    required this.fiscalPeriodId,
    required this.documentDate,
    required this.journalType,
    required this.documentType,
    this.documentId,
    this.documentNumber,
    required this.currencyId,
    this.exchangeRate = 1.0,
    this.description,
    required this.lines,
  });
}

class PostJournalEntryUseCase
    implements UseCase<String, PostJournalEntryCommand> {
  final AccountingRepository _accountingRepository;
  final CoreRepository _coreRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  PostJournalEntryUseCase(
    this._accountingRepository,
    this._coreRepository,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(PostJournalEntryCommand params) async {
    final businessId = _context.currentBusinessId;
    final userId = _context.currentUserId;

    if (params.lines.isEmpty) {
      return const Left(
        ValidationFailure('Journal entry must have at least one line.'),
      );
    }

    // Calculate totals
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in params.lines) {
      if (line.debit < 0 || line.credit < 0) {
        return const Left(
          ValidationFailure('Debit and credit amounts must be non-negative.'),
        );
      }
      if (line.debit > 0 && line.credit > 0) {
        return const Left(
          ValidationFailure(
            'A single journal line cannot have both debit and credit.',
          ),
        );
      }
      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    // Verify precision based on currency decimal places to avoid floating point issues
    final currency = await _coreRepository.getCurrencyById(params.currencyId);
    if (currency == null) {
      return const Left(ValidationFailure('Invalid currency ID.'));
    }

    final multiplier = pow(10, currency.decimalPlaces).toDouble();
    if ((totalDebit * multiplier).round() !=
        (totalCredit * multiplier).round()) {
      return const Left(
        ValidationFailure(
          'Journal entry must be balanced (Total Debit == Total Credit).',
        ),
      );
    }

    // Verify fiscal period locking
    try {
      final isLocked = await _accountingRepository.checkPeriodLocked(
        businessId,
        params.documentDate,
      );
      if (isLocked) {
        return const Left(
          BusinessValidationFailure('Cannot post to a closed fiscal period.'),
        );
      }
    } catch (e) {
      // if checkPeriodLocked doesn't exist, we fallback to checking manually
      final period = await _accountingRepository.getFiscalPeriodById(
        params.fiscalPeriodId,
        businessId,
      );
      if (period == null) {
        return const Left(ValidationFailure('Fiscal period not found.'));
      }
      if (period.status != 'Open') {
        return const Left(
          BusinessValidationFailure('Cannot post to a closed fiscal period.'),
        );
      }
    }

    final journalId = _uuid.v4();
    final journalNumber = 'JE-${DateTime.now().millisecondsSinceEpoch}';

    final entryCompanion = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: params.fiscalYearId,
      fiscalPeriodId: params.fiscalPeriodId,
      journalNumber: journalNumber,
      documentDate: params.documentDate,
      postingDate: drift.Value(DateTime.now()),
      journalType: params.journalType,
      documentType: params.documentType,
      documentId: drift.Value(params.documentId),
      documentNumber: drift.Value(params.documentNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value(params.description),
      status: drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(DateTime.now()),
      createdAt: drift.Value(DateTime.now()),
    );

    int sequence = 1;
    final linesCompanions = params.lines.map((line) {
      return JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: line.accountId,
        currencyId: params.currencyId,
        lineNumber: sequence++,
        type: line.debit > 0 ? 'Debit' : 'Credit',
        foreignAmount: drift.Value(max(line.debit, line.credit)),
        baseAmount: drift.Value(
          max(line.debit, line.credit) * params.exchangeRate,
        ),
        description: drift.Value(line.description ?? params.description),
      );
    }).toList();

    try {
      await _transactionRunner.runInTransaction(() async {
        await _accountingRepository.postJournalEntryWithLines(
          entry: entryCompanion,
          lines: linesCompanions.cast<JournalEntryLinesCompanion>(),
        );
      });
      return Right(journalId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class BusinessValidationFailure extends Failure {
  const BusinessValidationFailure(super.message, [super.code]);
}
