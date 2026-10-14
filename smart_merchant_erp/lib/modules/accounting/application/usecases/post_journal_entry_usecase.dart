import 'dart:math';
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
  final String? fiscalYearId;
  final String? fiscalPeriodId;
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
    this.fiscalYearId,
    this.fiscalPeriodId,
    required this.documentDate,
    this.journalType = 'Manual',
    this.documentType = 'Manual',
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

    if (params.lines.length < 2) {
      return const Left(
        ValidationFailure('يجب أن يحتوي القيد على سطرين على الأقل (مدين ودائن).'),
      );
    }

    // 1. Calculate totals and validate individual lines
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (final line in params.lines) {
      if (line.debit < 0 || line.credit < 0) {
        return const Left(
          ValidationFailure('لا يمكن أن تكون مبالغ المدين أو الدائن سالبة.'),
        );
      }
      if (line.debit > 0 && line.credit > 0) {
        return const Left(
          ValidationFailure(
            'لا يمكن للسطر الواحد أن يحتوي على مبلغ مدين ودائن في نفس الوقت.',
          ),
        );
      }
      if (line.debit == 0 && line.credit == 0) {
        return const Left(
          ValidationFailure('يجب تحديد مبلغ مدين أو دائن أكبر من الصفر لكل سطر.'),
        );
      }

      // Check allowPosting on each account (Reject postings to parent accounts)
      final account = await _accountingRepository.getChartOfAccountById(
        line.accountId,
        businessId,
      );
      if (account == null) {
        return Left(ValidationFailure('الحساب المحدد غير موجود: ${line.accountId}'));
      }
      if (!account.allowPosting) {
        return Left(
          ValidationFailure(
            'الحساب (${account.accountName}) حساب رئيسي ولا يقبل الترحيل المباشر.',
          ),
        );
      }

      totalDebit += line.debit;
      totalCredit += line.credit;
    }

    // 2. Double-entry balancing check
    if (!PrecisionMath.areBalanced(totalDebit, totalCredit)) {
      final diff = (totalDebit - totalCredit).abs().toStringAsFixed(2);
      return Left(
        ValidationFailure(
          'القيد غير متوازن! إجمالي المدين: ${totalDebit.toStringAsFixed(2)}، إجمالي الدائن: ${totalCredit.toStringAsFixed(2)}، الفارق: $diff',
        ),
      );
    }

    // 3. Verify date is not in a locked period (AC-4.4)
    final isLocked = await _accountingRepository.checkPeriodLocked(
      businessId,
      params.documentDate,
    );
    if (isLocked) {
      return const Left(
        ValidationFailure(
          'لا يمكن ترحيل القيد في فترة محاسبية مغلقة أو مقفولة.',
        ),
      );
    }

    // 4. Resolve active fiscal period
    String effectiveFiscalYearId;
    String effectiveFiscalPeriodId;

    if (params.fiscalPeriodId != null && params.fiscalYearId != null) {
      final period = await _accountingRepository.getFiscalPeriodById(
        params.fiscalPeriodId!,
        businessId,
      );
      if (period == null || period.status != 'Open') {
        return const Left(
          ValidationFailure(
            'الفترة المالية المحددة مغلقة أو غير صالحة لترحيل القيود.',
          ),
        );
      }
      effectiveFiscalYearId = params.fiscalYearId!;
      effectiveFiscalPeriodId = params.fiscalPeriodId!;
    } else {
      final periods = await _accountingRepository.listFiscalPeriods(
        FiscalPeriodFilter(businessId: businessId, status: 'Open'),
      );
      if (periods.isEmpty) {
        return const Left(
          ValidationFailure(
            'لا توجد فترة مالية مفتوحة في النظام لترحيل القيد.',
          ),
        );
      }
      final period = periods.first;
      effectiveFiscalYearId = period.fiscalYearId;
      effectiveFiscalPeriodId = period.id;
    }

    final journalId = _uuid.v4();
    final journalNumber = params.documentNumber ??
        'JE-${DateTime.now().millisecondsSinceEpoch}';

    final entryCompanion = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: effectiveFiscalYearId,
      fiscalPeriodId: effectiveFiscalPeriodId,
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
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(DateTime.now()),
      createdAt: drift.Value(DateTime.now()),
    );

    int sequence = 1;
    final linesCompanions = params.lines.map((line) {
      final amount = max(line.debit, line.credit);
      final baseAmount = PrecisionMath.toBaseAmount(
        foreignAmount: amount,
        exchangeRate: params.exchangeRate,
      );

      return JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: line.accountId,
        currencyId: params.currencyId,
        lineNumber: sequence++,
        type: line.debit > 0 ? 'Debit' : 'Credit',
        foreignAmount: drift.Value(amount),
        baseAmount: drift.Value(baseAmount),
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
