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
import '../../domain/repositories/purchasing_repository.dart';
import '../../../../database/daos/purchasing_dao.dart';

class PurchaseReturnItemCommand {
  final String purchaseInvoiceItemId;
  final String productUnitId;
  final String warehouseId;
  final double quantity;
  final double unitPrice; // Amount to refund per unit

  const PurchaseReturnItemCommand({
    required this.purchaseInvoiceItemId,
    required this.productUnitId,
    required this.warehouseId,
    required this.quantity,
    required this.unitPrice,
  });
}

class RecordPurchaseReturnCommand {
  final String purchaseInvoiceId;
  final String supplierId;
  final String currencyId;
  final double exchangeRate;
  final List<PurchaseReturnItemCommand> items;
  final String? notes;

  const RecordPurchaseReturnCommand({
    required this.purchaseInvoiceId,
    required this.supplierId,
    required this.currencyId,
    required this.items,
    this.exchangeRate = 1.0,
    this.notes,
  });
}

@injectable
class RecordPurchaseReturnUseCase
    implements UseCase<String, RecordPurchaseReturnCommand> {
  final PurchasingRepository _purchasingRepository;
  final InventoryRepository _inventoryRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  RecordPurchaseReturnUseCase(
    this._purchasingRepository,
    this._inventoryRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(
    RecordPurchaseReturnCommand params,
  ) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for a purchase return.'),
      );
    }
    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Cannot record a return with no items.'),
      );
    }

    // 1. Resolve Accounting Mappings
    final apIdResult = await _accountingService.resolveAccountMapping(
      'accounts_payable',
    );
    if (apIdResult.isLeft()) {
      return Left(apIdResult.fold((l) => l, (r) => throw Exception()));
    }
    final creditAccountId = apIdResult.getOrElse(() => '');

    final inventoryAssetIdResult = await _accountingService
        .resolveAccountMapping('inventory_asset');
    if (inventoryAssetIdResult.isLeft()) {
      return Left(
        inventoryAssetIdResult.fold((l) => l, (r) => throw Exception()),
      );
    }
    final inventoryAssetId = inventoryAssetIdResult.getOrElse(() => '');

    // 2. Calculate Totals
    double totalAmount = 0.0;
    for (final item in params.items) {
      if (item.quantity <= 0) {
        return const Left(ValidationFailure('Quantity must be greater than 0.'));
      }
      if (item.unitPrice < 0) {
        return const Left(ValidationFailure('Unit price cannot be negative.'));
      }
      totalAmount += (item.quantity * item.unitPrice);
    }

    // 3. Prepare Purchase Return Entities
    final returnId = _uuid.v4();
    final returnNumber = 'PRET-${DateTime.now().millisecondsSinceEpoch}';
    final returnDate = DateTime.now();

    final returnHeader = PurchaseReturnsCompanion.insert(
      id: returnId,
      businessId: businessId,
      branchId: branchId,
      purchaseInvoiceId: params.purchaseInvoiceId,
      returnNumber: returnNumber,
      returnDate: drift.Value(returnDate),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      totalAmount: drift.Value(totalAmount),
      baseTotalAmount: drift.Value(totalAmount * params.exchangeRate),
      status: const drift.Value('Posted'),
      createdBy: userId,
      notes: drift.Value(params.notes),
    );

    final returnItemsCompanions = params.items.map((item) {
      final lineTotal = item.quantity * item.unitPrice;
      return PurchaseReturnItemsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        purchaseReturnId: returnId,
        purchaseInvoiceItemId: item.purchaseInvoiceItemId,
        warehouseId: item.warehouseId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        lineTotal: lineTotal,
        baseLineTotal: drift.Value(lineTotal * params.exchangeRate),
      );
    }).toList();

    // 4. Prepare Inventory Transaction (Outbound)
    final inventoryTransactionId = _uuid.v4();
    final inventoryTxCompanion = InventoryTransactionsCompanion.insert(
      id: inventoryTransactionId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.items.first.warehouseId,
      transactionDate: drift.Value(returnDate),
      transactionType: InventoryTransactionType.dispatch,
      movementDirection: InventoryMovementDirection.outbound,
      referenceType: const drift.Value(InventoryReferenceType.purchaseReturn),
      referenceId: drift.Value(returnId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final inventoryLineCompanions = params.items.map((item) {
      return InventoryTransactionLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        inventoryTransactionId: inventoryTransactionId,
        productUnitId: item.productUnitId,
        quantity: item.quantity,
        unitCost: drift.Value(item.unitPrice),
      );
    }).toList();

    // 5. Prepare Journal Entry
    final periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, status: 'Open'),
    );
    if (periods.isEmpty) {
      return const Left(ValidationFailure('No active fiscal period found.'));
    }
    final period = periods.first;

    final journalEntryId = _uuid.v4();
    final journalNum = 'JE-$returnNumber';
    final baseTotal = totalAmount * params.exchangeRate;

    final journalEntryCompanion = JournalEntriesCompanion.insert(
      id: journalEntryId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: journalNum,
      documentDate: returnDate,
      postingDate: drift.Value(returnDate),
      journalType: 'PurchaseInvoice', // Or PurchaseReturn if available
      documentType: 'PurchaseInvoice',
      documentId: drift.Value(returnId),
      documentNumber: drift.Value(returnNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value('Purchase Return: $returnNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(returnDate),
    );

    // Purchase return reduces Accounts Payable (Debit) and reduces Inventory Asset (Credit)
    int lineSequence = 1;
    final jeLines = [
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalEntryId,
        chartOfAccountId: creditAccountId, // Accounts Payable
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Debit',
        foreignAmount: drift.Value(totalAmount),
        baseAmount: drift.Value(baseTotal),
        description: drift.Value('Debit AP for Return $returnNumber'),
      ),
      JournalEntryLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        journalEntryId: journalEntryId,
        chartOfAccountId: inventoryAssetId,
        currencyId: params.currencyId,
        lineNumber: lineSequence++,
        type: 'Credit',
        foreignAmount: drift.Value(totalAmount),
        baseAmount: drift.Value(baseTotal),
        description: drift.Value('Credit Inventory for Return $returnNumber'),
      ),
    ];

    try {
      await _transactionRunner.runInTransaction(() async {
        // 1. Record Return & Items
        await _purchasingRepository.recordReturnWithItems(
          returnHeader: returnHeader,
          items: returnItemsCompanions.cast<PurchaseReturnItemsCompanion>(),
        );

        // 2. Adjust Payable with an Adjustment Entry
        // This simulates applying a credit note or a direct reduction to the supplier's payable
        // We find the outstanding payables for this invoice if any
        final payables = await _purchasingRepository.listPayables(
          SupplierPayableFilter(businessId: businessId, purchaseInvoiceId: params.purchaseInvoiceId)
        );
        
        if (payables.isNotEmpty) {
           final payable = payables.first;
           // We create a PayableEntry of type 'Adjustment'
           final adjustmentEntry = PayableEntriesCompanion.insert(
             id: _uuid.v4(),
             businessId: businessId,
             supplierPayableId: payable.id,
             amount: totalAmount,
             baseAmount: baseTotal,
             entryType: const drift.Value('Adjustment'),
             createdBy: userId,
           );
           await _purchasingRepository.recordPayableEntry(
             entry: adjustmentEntry,
             supplierPayableId: payable.id,
             businessId: businessId,
           );
        }

        // 3. Record Inventory Outbound Transaction & Update Stock
        await _inventoryRepository.recordTransactionWithLines(
          transaction: inventoryTxCompanion,
          lines: inventoryLineCompanions.cast<InventoryTransactionLinesCompanion>(),
        );

        // 4. Post Journal Entry
        await _accountingRepository.postJournalEntryWithLines(
          entry: journalEntryCompanion,
          lines: jeLines.cast<JournalEntryLinesCompanion>(),
        );
      });

      return Right(returnId);
    } catch (e, stacktrace) {
      print('Purchase Return Error: $e');
      print(stacktrace);
      if (e is Failure) return Left(e);
      return Left(DatabaseFailure('Failed to record purchase return: $e'));
    }
  }
}
