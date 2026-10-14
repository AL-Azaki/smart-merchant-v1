import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../kernel/core/usecase.dart';
import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/repositories/accounting_repository.dart';
import '../services/accounting_application_service.dart';

/// Command DTO to trigger a Year-End Closing process.
class YearEndClosingCommand {
  final String fiscalYearId;
  final DateTime closingDate;
  final String? notes;

  const YearEndClosingCommand({
    required this.fiscalYearId,
    required this.closingDate,
    this.notes,
  });
}

/// Executes official Year-End Closing: zeroes out Revenue & Expense accounts,
/// transfers net profit/loss to Retained Earnings, closes fiscal periods, and posts closing journal.
class YearEndClosingUseCase implements UseCase<String, YearEndClosingCommand> {
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  YearEndClosingUseCase(
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(YearEndClosingCommand params) async {
    final businessId = _context.currentBusinessId;
    final userId = _context.currentUserId;

    // 1. Verify Fiscal Year
    final fiscalYear = await _accountingRepository.getFiscalYearById(
      params.fiscalYearId,
      businessId,
    );
    if (fiscalYear == null) {
      return const Left(ValidationFailure('السنة المالية المحددة غير موجودة.'));
    }
    if (fiscalYear.status == 'Closed') {
      return const Left(ValidationFailure('السنة المالية مقفلة مسبقاً.'));
    }

    // 2. Critical Rejection Rule: Disallow closing if Draft journal entries exist
    final draftJournals = await _accountingRepository.listJournalEntries(
      JournalEntryFilter(
        businessId: businessId,
        fiscalYearId: params.fiscalYearId,
        status: 'Draft',
      ),
    );
    if (draftJournals.isNotEmpty) {
      return const Left(
        ValidationFailure(
          'لا يمكن تنفيذ الإقفال السنوي لوجود قيود يومية معلقة بحالة مسودة. يرجى ترحيلها أو حذفها أولاً.',
        ),
      );
    }

    // 3. Resolve Retained Earnings mapping
    final retainedMappingResult = await _accountingService.resolveAccountMapping(
      'retained_earnings',
    );
    String retainedEarningsAccountId;
    if (retainedMappingResult.isRight()) {
      retainedEarningsAccountId = retainedMappingResult.getOrElse(() => '');
    } else {
      // Fallback: search for account code '32'
      final fallbackAccount = await _accountingRepository.getChartOfAccountByCode(
        '32',
        businessId,
      );
      if (fallbackAccount == null) {
        return const Left(
          ValidationFailure('لم يتم العثور على حساب الأرباح المحتجزة / المرحلة (32).'),
        );
      }
      retainedEarningsAccountId = fallbackAccount.id;
    }

    // 4. Fetch all accounts and posted lines up to closingDate
    final accounts = await _accountingRepository.listChartOfAccounts(
      ChartOfAccountFilter(businessId: businessId, isActive: true),
    );

    final linesWithEntries = await _accountingRepository.getJournalLinesForReporting(
      businessId: businessId,
      endDate: params.closingDate,
      status: 'Posted',
    );

    // Filter lines belonging to this fiscal year
    final yearLines = linesWithEntries.where((item) {
      return item.entry.fiscalYearId == params.fiscalYearId;
    }).toList();

    // 5. Aggregate net balances of Revenue (4) and Expense (5) accounts
    final Map<String, double> debitsMap = {};
    final Map<String, double> creditsMap = {};

    for (final item in yearLines) {
      final accId = item.line.chartOfAccountId;
      final amt = item.line.baseAmount;
      if (item.line.type == 'Debit') {
        debitsMap[accId] = (debitsMap[accId] ?? 0.0) + amt;
      } else if (item.line.type == 'Credit') {
        creditsMap[accId] = (creditsMap[accId] ?? 0.0) + amt;
      }
    }

    final List<JournalEntryLinesCompanion> closingLines = [];
    int lineNumber = 1;
    double totalRevenueClosed = 0.0;
    double totalExpenseClosed = 0.0;

    for (final acc in accounts) {
      if (!acc.allowPosting) continue;

      final deb = debitsMap[acc.id] ?? 0.0;
      final cred = creditsMap[acc.id] ?? 0.0;

      // Revenue: Credit balance -> Debit to zero out
      if (acc.accountTypeId == 4) {
        final netCredit = PrecisionMath.roundMoney(cred - deb);
        if (netCredit > 0) {
          totalRevenueClosed += netCredit;
          closingLines.add(
            JournalEntryLinesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              journalEntryId: '', // Assigned below
              lineNumber: lineNumber++,
              chartOfAccountId: acc.id,
              currencyId: 'YER',
              type: 'Debit',
              baseAmount: drift.Value(netCredit),
              description: drift.Value('إقفال إيرادات: ${acc.accountName}'),
            ),
          );
        }
      }

      // Expense: Debit balance -> Credit to zero out
      if (acc.accountTypeId == 5) {
        final netDebit = PrecisionMath.roundMoney(deb - cred);
        if (netDebit > 0) {
          totalExpenseClosed += netDebit;
          closingLines.add(
            JournalEntryLinesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              journalEntryId: '', // Assigned below
              lineNumber: lineNumber++,
              chartOfAccountId: acc.id,
              currencyId: 'YER',
              type: 'Credit',
              baseAmount: drift.Value(netDebit),
              description: drift.Value('إقفال مصروفات: ${acc.accountName}'),
            ),
          );
        }
      }
    }

    if (closingLines.isEmpty) {
      return const Left(
        ValidationFailure('لا توجد إيرادات أو مصروفات لإقفالها في هذه السنة.'),
      );
    }

    // 6. Transfer net difference to Retained Earnings
    final netIncome = PrecisionMath.roundMoney(totalRevenueClosed - totalExpenseClosed);

    if (netIncome > 0) {
      // Net Profit: Credit Retained Earnings
      closingLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: '',
          lineNumber: lineNumber++,
          chartOfAccountId: retainedEarningsAccountId,
          currencyId: 'YER',
          type: 'Credit',
          baseAmount: drift.Value(netIncome),
          description: const drift.Value('ترحيل صافي ربح السنة إلى الأرباح المرحلة'),
        ),
      );
    } else if (netIncome < 0) {
      // Net Loss: Debit Retained Earnings
      closingLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: '',
          lineNumber: lineNumber++,
          chartOfAccountId: retainedEarningsAccountId,
          currencyId: 'YER',
          type: 'Debit',
          baseAmount: drift.Value(netIncome.abs()),
          description: const drift.Value('ترحيل صافي خسارة السنة إلى الأرباح المرحلة'),
        ),
      );
    }

    // 7. Verify balanced closing entry
    double totalDebits = 0.0;
    double totalCredits = 0.0;
    for (final l in closingLines) {
      if (l.type.value == 'Debit') totalDebits += l.baseAmount.value;
      if (l.type.value == 'Credit') totalCredits += l.baseAmount.value;
    }

    if (!PrecisionMath.areBalanced(totalDebits, totalCredits)) {
      return Left(
        ValidationFailure('قيد الإقفال غير متوازن محاسبياً! الفارق: ${(totalDebits - totalCredits).abs()}'),
      );
    }

    // 8. Find last fiscal period in year for entry header
    final periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, fiscalYearId: params.fiscalYearId),
    );
    final closingPeriodId = periods.isNotEmpty ? periods.last.id : _uuid.v4();

    final closingJournalId = _uuid.v4();
    final closingEntry = JournalEntriesCompanion.insert(
      id: closingJournalId,
      businessId: businessId,
      fiscalYearId: params.fiscalYearId,
      fiscalPeriodId: closingPeriodId,
      journalNumber: 'YE-CLOSE-${DateTime.now().year}',
      documentDate: params.closingDate,
      postingDate: drift.Value(params.closingDate),
      journalType: 'Manual',
      documentType: 'Manual',
      currencyId: 'YER',
      status: const drift.Value('Posted'),
      createdBy: userId,
      description: drift.Value(params.notes ?? 'قيد إقفال السنة المالية ${fiscalYear.fiscalYearName}'),
    );

    // Attach journal ID to lines
    final finalizedLines = closingLines.map((l) {
      return l.copyWith(journalEntryId: drift.Value(closingJournalId));
    }).toList();

    // 9. Atomic Execution
    try {
      await _transactionRunner.runInTransaction(() async {
        await _accountingRepository.postJournalEntryWithLines(
          entry: closingEntry,
          lines: finalizedLines,
        );

        // Close all periods
        for (final p in periods) {
          await _accountingRepository.updateFiscalPeriod(
            FiscalPeriodsCompanion(
              id: drift.Value(p.id),
              businessId: drift.Value(businessId),
              status: const drift.Value('Closed'),
            ),
          );
        }

        // Close fiscal year
        await _accountingRepository.updateFiscalYear(
          FiscalYearsCompanion(
            id: drift.Value(fiscalYear.id),
            businessId: drift.Value(businessId),
            status: const drift.Value('Closed'),
          ),
        );
      });

      return Right(closingJournalId);
    } catch (e) {
      return Left(DatabaseFailure('فشل تنفيذ الإقفال السنوي: $e'));
    }
  }
}
