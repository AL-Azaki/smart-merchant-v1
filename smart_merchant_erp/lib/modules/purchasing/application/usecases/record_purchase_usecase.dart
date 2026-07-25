import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../kernel/core/transaction_runner.dart';
import '../../../../kernel/core/usecase.dart';
import '../../../../kernel/error/failures.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
import '../../../accounting/application/services/accounting_application_service.dart';
import '../../../accounting/domain/repositories/accounting_repository.dart';
import '../../../../database/daos/accounting_dao.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../core/domain/repositories/core_repository.dart';
import '../../domain/repositories/purchasing_repository.dart';

class PurchaseItemCommand {
  final String productUnitId;
  final String warehouseId;
  final double quantity;
  final double unitCost;
  final double discount;
  final double tax;
  final String? taxId;

  const PurchaseItemCommand({
    required this.productUnitId,
    required this.warehouseId,
    required this.quantity,
    required this.unitCost,
    this.discount = 0.0,
    this.tax = 0.0,
    this.taxId,
  });
}

class RecordPurchaseCommand {
  final String supplierId;
  final String currencyId;
  final double exchangeRate;
  final List<PurchaseItemCommand> items;
  final String? notes;
  final bool isCreditPurchase;
  final String? supplierInvoiceNumber;
  final DateTime? dueDate;

  const RecordPurchaseCommand({
    required this.supplierId,
    required this.currencyId,
    required this.items,
    this.exchangeRate = 1.0,
    this.notes,
    this.isCreditPurchase = true,
    this.supplierInvoiceNumber,
    this.dueDate,
  });
}

@injectable
class RecordPurchaseUseCase implements UseCase<String, RecordPurchaseCommand> {
  final PurchasingRepository _purchasingRepository;
  final InventoryRepository _inventoryRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  RecordPurchaseUseCase(
    this._purchasingRepository,
    this._inventoryRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(RecordPurchaseCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for a purchase.'),
      );
    }
    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Cannot record a purchase with no items.'),
      );
    }

    // 1. Resolve Accounting Mappings
    final apIdResult = await _accountingService.resolveAccountMapping(
      'accounts_payable',
    );
    if (apIdResult.isLeft())
      return Left(apIdResult.fold((l) => l, (r) => throw Exception()));
    final accountsPayableId = apIdResult.getOrElse(() => '');

    final inventoryAssetIdResult = await _accountingService
        .resolveAccountMapping('inventory_asset');
    if (inventoryAssetIdResult.isLeft())
      return Left(
        inventoryAssetIdResult.fold((l) => l, (r) => throw Exception()),
      );
    final inventoryAssetId = inventoryAssetIdResult.getOrElse(() => '');

    // 2. Calculate Totals
    double subTotal = 0.0;
    double discountTotal = 0.0;
    double taxTotal = 0.0;
    double totalCost = 0.0;

    for (final item in params.items) {
      if (item.quantity <= 0)
        return const Left(
          ValidationFailure('Quantity must be greater than 0.'),
        );
      if (item.unitCost < 0)
        return const Left(ValidationFailure('Unit cost cannot be negative.'));

      subTotal += (item.quantity * item.unitCost);
      discountTotal += item.discount;
      taxTotal += item.tax;
      totalCost += ((item.quantity * item.unitCost) - item.discount + item.tax);
    }
    final grandTotal = totalCost;

    // 3. Prepare Purchase Entities
    final invoiceId = _uuid.v4();
    final invoiceNumber = 'PINV-${DateTime.now().millisecondsSinceEpoch}';
    final invoiceDate = DateTime.now();

    final invoiceCompanion = PurchaseInvoicesCompanion.insert(
      id: invoiceId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.items.first.warehouseId,
      supplierId: params.supplierId,
      invoiceNumber: invoiceNumber,
      purchaseDate: drift.Value(invoiceDate),
      dueDate: drift.Value(params.dueDate),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      subTotal: drift.Value(subTotal),
      discountTotal: drift.Value(discountTotal),
      taxTotal: drift.Value(taxTotal),
      grandTotal: drift.Value(grandTotal),
      baseSubTotal: drift.Value(subTotal * params.exchangeRate),
      baseDiscountTotal: drift.Value(discountTotal * params.exchangeRate),
      baseTaxTotal: drift.Value(taxTotal * params.exchangeRate),
      baseGrandTotal: drift.Value(grandTotal * params.exchangeRate),
      status: const drift.Value('Posted'),
      paymentStatus: drift.Value(params.isCreditPurchase ? 'Unpaid' : 'Paid'),
      createdBy: userId,
      notes: drift.Value(params.notes),
    );

    final invoiceItemsCompanions = params.items.map((item) {
      final lineTotal =
          (item.quantity * item.unitCost) - item.discount + item.tax;
      return PurchaseInvoiceItemsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        purchaseInvoiceId: invoiceId,
        productUnitId: item.productUnitId,
        warehouseId: item.warehouseId,
        quantity: item.quantity,
        unitPrice: item.unitCost,
        discount: drift.Value(item.discount),
        tax: drift.Value(item.tax),
        taxId: drift.Value(item.taxId),
        lineTotal: lineTotal,
        baseLineTotal: drift.Value(lineTotal * params.exchangeRate),
      );
    }).toList();

    SupplierPayablesCompanion? payableCompanion;
    if (params.isCreditPurchase) {
      payableCompanion = SupplierPayablesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        supplierId: params.supplierId,
        currencyId: params.currencyId,
        purchaseInvoiceId: invoiceId,
        originalAmount: grandTotal,
        paidAmount: const drift.Value(0.0),
        remainingAmount: grandTotal,
        baseOriginalAmount: grandTotal * params.exchangeRate,
        basePaidAmount: const drift.Value(0.0),
        baseRemainingAmount: grandTotal * params.exchangeRate,
        status: const drift.Value('Active'),
      );
    }

    // 4. Prepare Inventory Transaction (Inbound)
    final inventoryTransactionId = _uuid.v4();
    final inventoryTxCompanion = InventoryTransactionsCompanion.insert(
      id: inventoryTransactionId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.items.first.warehouseId,
      transactionDate: drift.Value(invoiceDate),
      transactionType: InventoryTransactionType.receipt,
      movementDirection: InventoryMovementDirection.inbound,
      referenceType: const drift.Value(InventoryReferenceType.purchaseInvoice),
      referenceId: drift.Value(invoiceId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final inventoryLineCompanions = params.items.map((item) {
      final totalLineCost =
          (item.quantity * item.unitCost) - item.discount + item.tax;
      final actualUnitCost = item.quantity > 0
          ? (totalLineCost / item.quantity)
          : 0.0;

      return InventoryTransactionLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        inventoryTransactionId: inventoryTransactionId,
        productUnitId: item.productUnitId,
        quantity: item.quantity,
        unitCost: drift.Value(actualUnitCost),
      );
    }).toList();

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
    final journalNum = 'JE-${DateTime.now().millisecondsSinceEpoch}';

    final entryCompanion = JournalEntriesCompanion.insert(
      id: journalId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: journalNum,
      documentDate: invoiceDate,
      postingDate: drift.Value(invoiceDate),
      journalType: 'PurchaseInvoice',
      documentType: 'PurchaseInvoice',
      documentId: drift.Value(invoiceId),
      documentNumber: drift.Value(invoiceNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value('Purchase Invoice $invoiceNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(invoiceDate),
    );

    int lineSequence = 1;
    final List<JournalEntryLinesCompanion> journalLines = [
      // Debit: Inventory Asset
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: inventoryAssetId,
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Debit',
        foreignAmount: drift.Value(grandTotal),
        baseAmount: drift.Value(grandTotal * params.exchangeRate),
        description: const drift.Value('Inventory Addition'),
      ),
      // Credit: Accounts Payable (or Cash)
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalId,
        chartOfAccountId: accountsPayableId,
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Credit',
        foreignAmount: drift.Value(grandTotal),
        baseAmount: drift.Value(grandTotal * params.exchangeRate),
        description: const drift.Value('Purchase Liability'),
      ),
    ];

    // 6. Execute Transaction
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Purchase & Payable
        await _purchasingRepository.recordInvoiceWithItemsAndPayable(
          invoice: invoiceCompanion,
          items: invoiceItemsCompanions.cast<PurchaseInvoiceItemsCompanion>(),
          payable: payableCompanion,
        );

        // Add Inventory
        await _inventoryRepository.recordTransactionWithLines(
          transaction: inventoryTxCompanion,
          lines: inventoryLineCompanions
              .cast<InventoryTransactionLinesCompanion>(),
        );

        // Post Accounting Journal
        await _accountingRepository.postJournalEntryWithLines(
          entry: entryCompanion,
          lines: journalLines,
        );
      });

      return Right(invoiceId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class BusinessValidationFailure extends Failure {
  const BusinessValidationFailure(super.message, [super.code]);
}
