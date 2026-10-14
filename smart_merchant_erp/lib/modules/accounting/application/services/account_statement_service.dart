import '../../../../core/utils/precision_math.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../../kernel/core/application_context.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Single chronological movement line in an Account Statement / General Ledger.
class AccountStatementLine {
  final DateTime date;
  final String documentType;
  final String documentNumber;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;

  const AccountStatementLine({
    required this.date,
    required this.documentType,
    required this.documentNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

/// Comprehensive Account Statement / General Ledger report.
class AccountStatementReport {
  final String accountId;
  final String accountCode;
  final String accountName;
  final String normalBalance;
  final double openingBalance;
  final List<AccountStatementLine> lines;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;

  const AccountStatementReport({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.normalBalance,
    required this.openingBalance,
    required this.lines,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
  });
}

/// Domain engine compiling chronological general ledger account statements with running balances.
class AccountStatementService {
  final AccountingRepository _accountingRepository;
  final ApplicationContext _context;

  AccountStatementService(this._accountingRepository, this._context);

  Future<AccountStatementReport?> generateStatement({
    required String accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;

    // 1. Fetch account
    final account = await _accountingRepository.getChartOfAccountById(
      accountId,
      businessId,
    );
    if (account == null) return null;

    final isNormalDebit = account.normalBalance.toLowerCase() == 'debit';

    // 2. Compute opening balance prior to startDate
    double openingBalance = 0.0;
    if (startDate != null) {
      final priorLines = await _accountingRepository.getJournalLinesForReporting(
        businessId: businessId,
        chartOfAccountId: accountId,
        endDate: startDate.subtract(const Duration(milliseconds: 1)),
        status: 'Posted',
      );

      for (final item in priorLines) {
        final amt = item.line.baseAmount;
        if (item.line.type == 'Debit') {
          openingBalance += isNormalDebit ? amt : -amt;
        } else if (item.line.type == 'Credit') {
          openingBalance += isNormalDebit ? -amt : amt;
        }
      }
    }
    openingBalance = PrecisionMath.roundMoney(openingBalance);

    // 3. Fetch period lines
    final periodLines = await _accountingRepository.getJournalLinesForReporting(
      businessId: businessId,
      chartOfAccountId: accountId,
      startDate: startDate,
      endDate: endDate,
      status: 'Posted',
    );

    // 4. Construct running balance lines
    final List<AccountStatementLine> lines = [];
    double currentBalance = openingBalance;
    double periodTotalDebit = 0.0;
    double periodTotalCredit = 0.0;

    for (final item in periodLines) {
      final isDebit = item.line.type == 'Debit';
      final deb = isDebit ? item.line.baseAmount : 0.0;
      final cred = !isDebit ? item.line.baseAmount : 0.0;

      periodTotalDebit += deb;
      periodTotalCredit += cred;

      if (isNormalDebit) {
        currentBalance += (deb - cred);
      } else {
        currentBalance += (cred - deb);
      }
      currentBalance = PrecisionMath.roundMoney(currentBalance);

      lines.add(
        AccountStatementLine(
          date: item.entry.documentDate,
          documentType: item.entry.journalType,
          documentNumber: item.entry.journalNumber,
          description: item.line.description ?? item.entry.documentNumber ?? '',
          debit: PrecisionMath.roundMoney(deb),
          credit: PrecisionMath.roundMoney(cred),
          runningBalance: currentBalance,
        ),
      );
    }

    return AccountStatementReport(
      accountId: account.id,
      accountCode: account.accountCode,
      accountName: account.accountName,
      normalBalance: account.normalBalance,
      openingBalance: openingBalance,
      lines: lines,
      totalDebit: PrecisionMath.roundMoney(periodTotalDebit),
      totalCredit: PrecisionMath.roundMoney(periodTotalCredit),
      closingBalance: currentBalance,
    );
  }
}
