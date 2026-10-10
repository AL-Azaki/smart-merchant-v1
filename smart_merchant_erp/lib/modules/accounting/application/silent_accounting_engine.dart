import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/precision_math.dart';
import '../../../../kernel/storage/app_database.dart';

/// A draft representing an individual line in a journal entry before database insertion.
class JournalLineDraft {
  final String accountId;
  final double debit;
  final double credit;
  final String? description;

  JournalLineDraft({
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });
}

/// SilentAccountingEngine is the central financial engine of Smart Merchant ERP.
/// 
/// It accepts business transaction events (Sales, Purchases, Vouchers, Adjustments)
/// and silently transforms them into balanced, legally compliant double-entry journal entries.
class SilentAccountingEngine {
  final AppDatabase db;

  SilentAccountingEngine(this.db);

  /// Creates and posts an atomic, strictly balanced journal entry.
  /// 
  /// Throws [AccountingBalanceException] if total base debit does not equal total base credit.
  /// Throws [FiscalPeriodClosedException] if the targeted fiscal year is closed.
  Future<String> createBalancedEntry({
    required String fiscalYearId,
    required String referenceType,
    required String? referenceId,
    required String currencyId,
    required double exchangeRate,
    required String description,
    required List<JournalLineDraft> lines,
    DateTime? entryDate,
  }) async {
    // 1. Verify Fiscal Year status
    final fiscalYear = await (db.select(db.fiscalYearsTable)
          ..where((fy) => fy.id.equals(fiscalYearId)))
        .getSingleOrNull();

    if (fiscalYear == null) {
      throw FiscalPeriodNotFoundException('السنة المالية المحددة غير موجودة: $fiscalYearId');
    }

    if (fiscalYear.isClosed) {
      throw FiscalPeriodClosedException('لا يمكن إنشاء قيود في سنة مالية مقفلة (${fiscalYear.yearName})');
    }

    // 2. Validate and convert lines to Base Currency
    double totalBaseDebit = 0.0;
    double totalBaseCredit = 0.0;
    final processedRows = <Map<String, dynamic>>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineDebit = PrecisionMath.roundMoney(line.debit);
      final lineCredit = PrecisionMath.roundMoney(line.credit);

      final baseDebit = PrecisionMath.roundMoney(lineDebit * exchangeRate);
      final baseCredit = PrecisionMath.roundMoney(lineCredit * exchangeRate);

      totalBaseDebit += baseDebit;
      totalBaseCredit += baseCredit;

      processedRows.add({
        'lineNumber': i + 1,
        'accountId': line.accountId,
        'description': line.description,
        'debit': lineDebit,
        'credit': lineCredit,
        'baseDebit': baseDebit,
        'baseCredit': baseCredit,
      });
    }

    totalBaseDebit = PrecisionMath.roundMoney(totalBaseDebit);
    totalBaseCredit = PrecisionMath.roundMoney(totalBaseCredit);

    // 3. Strict Double-Entry Balance Check
    if (!PrecisionMath.areBalanced(totalBaseDebit, totalBaseCredit)) {
      final variance = PrecisionMath.roundMoney(totalBaseDebit - totalBaseCredit);
      throw AccountingBalanceException(
        'القيد المحاسبي غير متزن! إجمالي المدين: $totalBaseDebit، إجمالي الدائن: $totalBaseCredit، الفارق: $variance',
      );
    }

    // 4. Generate unique sequential entry number and UUID
    final entryId = const Uuid().v4();
    final entryNumber = 'JV-${DateTime.now().millisecondsSinceEpoch}';

    // 5. Insert Journal Entry Header
    await db.into(db.journalEntriesTable).insert(
      JournalEntriesTableCompanion.insert(
        id: Value(entryId),
        fiscalYearId: fiscalYearId,
        entryNumber: entryNumber,
        referenceType: referenceType,
        referenceId: Value(referenceId),
        currencyId: currencyId,
        exchangeRate: Value(exchangeRate),
        description: Value(description),
        entryDate: Value(entryDate ?? DateTime.now()),
        status: const Value('Posted'),
      ),
    );

    // 6. Insert Journal Entry Lines
    for (var row in processedRows) {
      await db.into(db.journalEntryLinesTable).insert(
        JournalEntryLinesTableCompanion.insert(
          journalEntryId: entryId,
          lineNumber: row['lineNumber'] as int,
          accountId: row['accountId'] as String,
          description: Value(row['description'] as String?),
          debit: Value(row['debit'] as double),
          credit: Value(row['credit'] as double),
          baseDebit: Value(row['baseDebit'] as double),
          baseCredit: Value(row['baseCredit'] as double),
        ),
      );
    }

    return entryId;
  }

  /// Reverses an existing posted entry (Void/Reversal) following accounting immutability rules.
  /// 
  /// Reverses debits into credits and credits into debits, creating a new cancellation entry.
  Future<String> reverseEntry({
    required String originalEntryId,
    required String cancellationReason,
  }) async {
    final original = await (db.select(db.journalEntriesTable)
          ..where((e) => e.id.equals(originalEntryId)))
        .getSingle();

    final originalLines = await (db.select(db.journalEntryLinesTable)
          ..where((l) => l.journalEntryId.equals(originalEntryId)))
        .get();

    // Invert the lines
    final reversedLines = originalLines.map((line) {
      return JournalLineDraft(
        accountId: line.accountId,
        debit: line.credit, // Debit becomes Credit
        credit: line.debit, // Credit becomes Debit
        description: 'إلغاء قيد ${original.entryNumber}: $cancellationReason',
      );
    }).toList();

    // Create the reversal entry
    final reversalEntryId = await createBalancedEntry(
      fiscalYearId: original.fiscalYearId,
      referenceType: 'VoidReversal',
      referenceId: originalEntryId,
      currencyId: original.currencyId,
      exchangeRate: original.exchangeRate,
      description: 'عكس قيد ${original.entryNumber} - $cancellationReason',
      lines: reversedLines,
    );

    // Mark original as voided
    await (db.update(db.journalEntriesTable)..where((e) => e.id.equals(originalEntryId))).write(
      const JournalEntriesTableCompanion(status: Value('Voided')),
    );

    return reversalEntryId;
  }

  /// Helper to fetch a designated system account by role (e.g. 'SALES_REVENUE', 'COGS')
  Future<AccountData> getAccountByRole(String systemRole) async {
    final accounts = await (db.select(db.chartOfAccountsTable)
          ..where((a) => a.systemRole.equals(systemRole)))
        .get();

    if (accounts.isEmpty) {
      throw SystemAccountNotFoundException('الحساب النظامي المطلوب غير موجود: $systemRole');
    }

    return accounts.first;
  }
}

class AccountingBalanceException implements Exception {
  final String message;
  AccountingBalanceException(this.message);
  @override
  String toString() => 'AccountingBalanceException: $message';
}

class FiscalPeriodClosedException implements Exception {
  final String message;
  FiscalPeriodClosedException(this.message);
  @override
  String toString() => 'FiscalPeriodClosedException: $message';
}

class FiscalPeriodNotFoundException implements Exception {
  final String message;
  FiscalPeriodNotFoundException(this.message);
  @override
  String toString() => 'FiscalPeriodNotFoundException: $message';
}

class SystemAccountNotFoundException implements Exception {
  final String message;
  SystemAccountNotFoundException(this.message);
  @override
  String toString() => 'SystemAccountNotFoundException: $message';
}
