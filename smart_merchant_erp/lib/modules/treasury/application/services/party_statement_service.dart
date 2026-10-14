import '../../../../core/utils/precision_math.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../database/daos/purchasing_dao.dart';
import '../../../../database/daos/sales_dao.dart';
import '../../../../database/daos/treasury_dao.dart';
import '../../../purchasing/domain/repositories/purchasing_repository.dart';
import '../../../sales/domain/repositories/sales_repository.dart';
import '../../domain/repositories/treasury_repository.dart';

class StatementLine {
  final DateTime date;
  final String documentType; // 'Invoice', 'Payment', 'Return', 'Opening'
  final String documentNumber;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;

  const StatementLine({
    required this.date,
    required this.documentType,
    required this.documentNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

class PartyStatementReport {
  final String partyId;
  final String partyName;
  final String partyType; // 'Customer' | 'Supplier'
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double closingBalance;
  final List<StatementLine> lines;

  const PartyStatementReport({
    required this.partyId,
    required this.partyName,
    required this.partyType,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingBalance,
    required this.lines,
  });
}

class PartyStatementService {
  final SalesRepository _salesRepository;
  final PurchasingRepository _purchasingRepository;
  final TreasuryRepository _treasuryRepository;
  final ApplicationContext _context;

  PartyStatementService(
    this._salesRepository,
    this._purchasingRepository,
    this._treasuryRepository,
    this._context,
  );

  /// Generates chronological Customer Statement of Account
  Future<PartyStatementReport> getCustomerStatement(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;
    final customer = await _salesRepository.getCustomerById(customerId, businessId);
    final customerName = customer?.customerName ?? 'عميل غير معروف';

    // 1. Fetch Invoices
    final invoices = await _salesRepository.listInvoices(
      SalesInvoiceFilter(
        businessId: businessId,
        customerId: customerId,
        limit: 1000,
      ),
    );

    // 2. Fetch Payments (Receipts)
    final payments = await _treasuryRepository.listPayments(
      PaymentFilter(
        businessId: businessId,
        contactType: 'Customer',
        contactId: customerId,
        limit: 1000,
      ),
    );

    // 3. Compile raw entries
    final rawEntries = <_RawEntry>[];

    // Initial Opening balance
    final initOpening = customer?.openingBalance ?? 0.0;
    if (initOpening > 0 && customer?.openingBalanceDate != null) {
      final isDebit = (customer?.openingBalanceType ?? 'debit').toLowerCase() == 'debit';
      rawEntries.add(_RawEntry(
        date: customer!.openingBalanceDate!,
        documentType: 'Opening',
        documentNumber: 'OPN-001',
        description: 'رصيد افتتاحي سابق',
        debit: isDebit ? initOpening : 0.0,
        credit: isDebit ? 0.0 : initOpening,
      ));
    }

    for (final inv in invoices) {
      if (inv.status != 'Cancelled') {
        rawEntries.add(_RawEntry(
          date: inv.invoiceDate,
          documentType: 'Invoice',
          documentNumber: inv.invoiceNumber,
          description: 'فاتورة مبيعات ${inv.invoiceNumber}',
          debit: inv.grandTotal,
          credit: 0.0,
        ));
      }
    }

    for (final p in payments) {
      if (p.status == 'Posted') {
        rawEntries.add(_RawEntry(
          date: p.paymentDate,
          documentType: 'Payment',
          documentNumber: p.paymentNumber,
          description: p.notes ?? 'سند قبض ${p.paymentNumber}',
          debit: 0.0,
          credit: p.amount,
        ));
      }
    }

    // Sort chronologically
    rawEntries.sort((a, b) => a.date.compareTo(b.date));

    // Calculate opening balance before startDate and filter period lines
    double periodOpening = 0.0;
    final periodLines = <StatementLine>[];
    double running = 0.0;

    for (final e in rawEntries) {
      if (startDate != null && e.date.isBefore(startDate)) {
        periodOpening += (e.debit - e.credit);
      } else if (endDate == null || !e.date.isAfter(endDate)) {
        if (periodLines.isEmpty) {
          running = periodOpening;
        }
        running = PrecisionMath.roundMoney(running + e.debit - e.credit);
        periodLines.add(StatementLine(
          date: e.date,
          documentType: e.documentType,
          documentNumber: e.documentNumber,
          description: e.description,
          debit: PrecisionMath.roundMoney(e.debit),
          credit: PrecisionMath.roundMoney(e.credit),
          runningBalance: running,
        ));
      }
    }

    if (periodLines.isEmpty) {
      running = periodOpening;
    }

    final totalDebit = periodLines.fold(0.0, (sum, l) => sum + l.debit);
    final totalCredit = periodLines.fold(0.0, (sum, l) => sum + l.credit);

    return PartyStatementReport(
      partyId: customerId,
      partyName: customerName,
      partyType: 'Customer',
      openingBalance: PrecisionMath.roundMoney(periodOpening),
      totalDebit: PrecisionMath.roundMoney(totalDebit),
      totalCredit: PrecisionMath.roundMoney(totalCredit),
      closingBalance: PrecisionMath.roundMoney(running),
      lines: periodLines,
    );
  }

  /// Generates chronological Supplier Statement of Account
  Future<PartyStatementReport> getSupplierStatement(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final businessId = _context.currentBusinessId;
    final supplier = await _purchasingRepository.getSupplierById(supplierId, businessId);
    final supplierName = supplier?.supplierName ?? 'مورد غير معروف';

    // 1. Fetch Purchase Invoices
    final invoices = await _purchasingRepository.listInvoices(
      PurchaseInvoiceFilter(
        businessId: businessId,
        supplierId: supplierId,
        limit: 1000,
      ),
    );

    // 2. Fetch Payments (Disbursements)
    final payments = await _treasuryRepository.listPayments(
      PaymentFilter(
        businessId: businessId,
        contactType: 'Supplier',
        contactId: supplierId,
        limit: 1000,
      ),
    );

    final rawEntries = <_RawEntry>[];

    // Initial Opening Balance
    final initOpening = supplier?.openingBalance ?? 0.0;
    if (initOpening > 0 && supplier?.openingBalanceDate != null) {
      final isCredit = (supplier?.openingBalanceType ?? 'credit').toLowerCase() == 'credit';
      rawEntries.add(_RawEntry(
        date: supplier!.openingBalanceDate!,
        documentType: 'Opening',
        documentNumber: 'OPN-001',
        description: 'رصيد افتتاحي سابق',
        debit: isCredit ? 0.0 : initOpening,
        credit: isCredit ? initOpening : 0.0,
      ));
    }

    for (final inv in invoices) {
      if (inv.status != 'Cancelled') {
        rawEntries.add(_RawEntry(
          date: inv.purchaseDate,
          documentType: 'Invoice',
          documentNumber: inv.invoiceNumber,
          description: 'فاتورة مشتريات ${inv.invoiceNumber}',
          debit: 0.0,
          credit: inv.grandTotal, // Purchase increases supplier credit
        ));
      }
    }

    for (final p in payments) {
      if (p.status == 'Posted') {
        rawEntries.add(_RawEntry(
          date: p.paymentDate,
          documentType: 'Payment',
          documentNumber: p.paymentNumber,
          description: p.notes ?? 'سند صرف ${p.paymentNumber}',
          debit: p.amount, // Payment decreases supplier credit (Debit)
          credit: 0.0,
        ));
      }
    }

    rawEntries.sort((a, b) => a.date.compareTo(b.date));

    double periodOpening = 0.0;
    final periodLines = <StatementLine>[];
    double running = 0.0;

    for (final e in rawEntries) {
      if (startDate != null && e.date.isBefore(startDate)) {
        periodOpening += (e.credit - e.debit);
      } else if (endDate == null || !e.date.isAfter(endDate)) {
        if (periodLines.isEmpty) {
          running = periodOpening;
        }
        running = PrecisionMath.roundMoney(running + e.credit - e.debit);
        periodLines.add(StatementLine(
          date: e.date,
          documentType: e.documentType,
          documentNumber: e.documentNumber,
          description: e.description,
          debit: PrecisionMath.roundMoney(e.debit),
          credit: PrecisionMath.roundMoney(e.credit),
          runningBalance: running,
        ));
      }
    }

    if (periodLines.isEmpty) {
      running = periodOpening;
    }

    final totalDebit = periodLines.fold(0.0, (sum, l) => sum + l.debit);
    final totalCredit = periodLines.fold(0.0, (sum, l) => sum + l.credit);

    return PartyStatementReport(
      partyId: supplierId,
      partyName: supplierName,
      partyType: 'Supplier',
      openingBalance: PrecisionMath.roundMoney(periodOpening),
      totalDebit: PrecisionMath.roundMoney(totalDebit),
      totalCredit: PrecisionMath.roundMoney(totalCredit),
      closingBalance: PrecisionMath.roundMoney(running),
      lines: periodLines,
    );
  }
}

class _RawEntry {
  final DateTime date;
  final String documentType;
  final String documentNumber;
  final String description;
  final double debit;
  final double credit;

  const _RawEntry({
    required this.date,
    required this.documentType,
    required this.documentNumber,
    required this.description,
    required this.debit,
    required this.credit,
  });
}
