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
import '../../domain/repositories/sales_repository.dart';
import '../../../../database/daos/sales_dao.dart';

class SalesReturnItemCommand {
  final String salesInvoiceItemId;
  final String productUnitId;
  final String warehouseId;
  final double quantity;
  final double unitPrice;

  const SalesReturnItemCommand({
    required this.salesInvoiceItemId,
    required this.productUnitId,
    required this.warehouseId,
    required this.quantity,
    required this.unitPrice,
  });
}

class ProcessSalesReturnCommand {
  final String salesInvoiceId;
  final String currencyId;
  final double exchangeRate;
  final List<SalesReturnItemCommand> items;
  final String? notes;

  const ProcessSalesReturnCommand({
    required this.salesInvoiceId,
    required this.currencyId,
    required this.items,
    this.exchangeRate = 1.0,
    this.notes,
  });
}

class ProcessSalesReturnUseCase
    implements UseCase<String, ProcessSalesReturnCommand> {
  final SalesRepository _salesRepository;
  final InventoryRepository _inventoryRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final Uuid _uuid = const Uuid();

  ProcessSalesReturnUseCase(
    this._salesRepository,
    this._inventoryRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
  );

  @override
  Future<Either<Failure, String>> call(ProcessSalesReturnCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(
        ValidationFailure('Branch ID is required for sales return.'),
      );
    }
    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Cannot process return with no items.'),
      );
    }

    // 1. Fetch original invoice
    final originalInvoice = await _salesRepository.getInvoiceWithItemsById(
      params.salesInvoiceId,
      businessId,
    );
    if (originalInvoice == null) {
      return const Left(ValidationFailure('Original sales invoice not found.'));
    }

    // 2. Validate return quantities against originally sold AND previously returned
    final existingReturns = await _salesRepository.listReturns(
      SalesReturnFilter(
        businessId: businessId,
        salesInvoiceId: params.salesInvoiceId,
      ),
    );
    final returnedQuantities = <String, double>{};
    for (final ret in existingReturns) {
      final retWithItems = await _salesRepository.getReturnWithItemsById(
        ret.id,
        businessId,
      );
      if (retWithItems != null) {
        for (final item in retWithItems.items) {
          returnedQuantities[item.salesInvoiceItemId] =
              (returnedQuantities[item.salesInvoiceItemId] ?? 0.0) +
              item.quantity;
        }
      }
    }

    double totalAmount = 0.0;
    double totalCost = 0.0;
    final itemsWithCost = <Map<String, dynamic>>[];

    for (final cmdItem in params.items) {
      if (cmdItem.quantity <= 0) {
        return const Left(
          ValidationFailure('Return quantity must be greater than zero.'),
        );
      }

      final originalItem = originalInvoice.items
          .where((i) => i.id == cmdItem.salesInvoiceItemId)
          .firstOrNull;
      if (originalItem == null) {
        return const Left(
          ValidationFailure('Original invoice item not found.'),
        );
      }

      final previouslyReturned =
          returnedQuantities[cmdItem.salesInvoiceItemId] ?? 0.0;
      final maxReturnable = originalItem.quantity - previouslyReturned;

      if (cmdItem.quantity > maxReturnable) {
        return Left(
          ValidationFailure(
            'Cannot return more than originally sold. Max returnable for ${cmdItem.productUnitId} is $maxReturnable.',
          ),
        );
      }

      final costPrice = originalItem.costPrice ?? 0.0;

      totalAmount += (cmdItem.quantity * cmdItem.unitPrice);
      totalCost += (cmdItem.quantity * costPrice);

      itemsWithCost.add({'command': cmdItem, 'costPrice': costPrice});
    }

    // 3. Resolve Accounting Mappings
    final arIdResult = await _accountingService.resolveAccountMapping(
      'accounts_receivable',
    );
    final accountsReceivableId = arIdResult.getOrElse(() => '');

    final salesRevenueIdResult = await _accountingService.resolveAccountMapping(
      'sales_revenue',
    );
    final salesRevenueId = salesRevenueIdResult.getOrElse(() => '');

    final cogsIdResult = await _accountingService.resolveAccountMapping(
      'cost_of_goods_sold',
    );
    final cogsId = cogsIdResult.getOrElse(() => '');

    final inventoryAssetIdResult = await _accountingService
        .resolveAccountMapping('inventory_asset');
    final inventoryAssetId = inventoryAssetIdResult.getOrElse(() => '');

    // 4. Prepare Entities
    final returnId = _uuid.v4();
    final returnNumber = 'SRET-${DateTime.now().millisecondsSinceEpoch}';
    final returnDate = DateTime.now();

    final returnHeader = SalesReturnsCompanion.insert(
      id: returnId,
      businessId: businessId,
      branchId: branchId,
      salesInvoiceId: params.salesInvoiceId,
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

    final returnItemsCompanions = itemsWithCost.map((map) {
      final item = map['command'] as SalesReturnItemCommand;
      final costPrice = map['costPrice'] as double;
      final lineTotal = item.quantity * item.unitPrice;
      return SalesReturnItemsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        salesReturnId: returnId,
        salesInvoiceItemId: item.salesInvoiceItemId,
        warehouseId: item.warehouseId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costPrice: drift.Value(costPrice),
        totalPrice: lineTotal,
        costTotal: drift.Value(item.quantity * costPrice),
        baseTotalPrice: drift.Value(lineTotal * params.exchangeRate),
      );
    }).toList();

    // 5. Inventory Transaction (Inbound)
    final inventoryTransactionId = _uuid.v4();
    final inventoryTxCompanion = InventoryTransactionsCompanion.insert(
      id: inventoryTransactionId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.items.first.warehouseId,
      transactionDate: drift.Value(returnDate),
      transactionType: InventoryTransactionType.receipt,
      movementDirection: InventoryMovementDirection.inbound,
      referenceType: const drift.Value(InventoryReferenceType.salesReturn),
      referenceId: drift.Value(returnId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final inventoryLineCompanions = itemsWithCost.map((map) {
      final item = map['command'] as SalesReturnItemCommand;
      final costPrice = map['costPrice'] as double;
      return InventoryTransactionLinesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        inventoryTransactionId: inventoryTransactionId,
        productUnitId: item.productUnitId,
        quantity: item.quantity,
        unitCost: drift.Value(costPrice),
      );
    }).toList();

    // 6. Journal Entry
    final periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, status: 'Open'),
    );
    if (periods.isEmpty) {
      return const Left(ValidationFailure('No active fiscal period found.'));
    }
    final period = periods.first;

    final journalEntryId = _uuid.v4();
    final journalEntryCompanion = JournalEntriesCompanion.insert(
      id: journalEntryId,
      businessId: businessId,
      fiscalYearId: period.fiscalYearId,
      fiscalPeriodId: period.id,
      journalNumber: 'JE-$returnNumber',
      documentDate: returnDate,
      postingDate: drift.Value(returnDate),
      journalType: 'SalesReturn',
      documentType: 'SalesReturn',
      documentId: drift.Value(returnId),
      documentNumber: drift.Value(returnNumber),
      currencyId: params.currencyId,
      exchangeRate: drift.Value(params.exchangeRate),
      description: drift.Value('Sales Return: $returnNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(returnDate),
    );

    int lineSequence = 1;
    final List<JournalEntryLinesCompanion> jeLines = [];

    if (salesRevenueId.isNotEmpty) {
      jeLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalEntryId,
          chartOfAccountId: salesRevenueId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Debit',
          foreignAmount: drift.Value(totalAmount),
          baseAmount: drift.Value(totalAmount * params.exchangeRate),
          description: const drift.Value('Sales Revenue Reversal'),
        ),
      );
    }

    if (accountsReceivableId.isNotEmpty) {
      jeLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalEntryId,
          chartOfAccountId: accountsReceivableId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Credit',
          foreignAmount: drift.Value(totalAmount),
          baseAmount: drift.Value(totalAmount * params.exchangeRate),
          description: const drift.Value('Receivable Reversal'),
        ),
      );
    }

    if (inventoryAssetId.isNotEmpty) {
      jeLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalEntryId,
          chartOfAccountId: inventoryAssetId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Debit',
          foreignAmount: drift.Value(totalCost),
          baseAmount: drift.Value(totalCost * params.exchangeRate),
          description: const drift.Value('Inventory Asset Restoration'),
        ),
      );
    }

    if (cogsId.isNotEmpty) {
      jeLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalEntryId,
          chartOfAccountId: cogsId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Credit',
          foreignAmount: drift.Value(totalCost),
          baseAmount: drift.Value(totalCost * params.exchangeRate),
          description: const drift.Value('COGS Reversal'),
        ),
      );
    }

    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Return
        await _salesRepository.recordReturnWithItems(
          salesReturn: returnHeader,
          items: returnItemsCompanions,
        );

        // Adjust Receivable
        final receivables = await _salesRepository.listReceivables(
          CustomerReceivableFilter(
            businessId: businessId,
            salesInvoiceId: params.salesInvoiceId,
          ),
        );
        if (receivables.isNotEmpty) {
          final receivable = receivables.first;
          final entryCompanion = ReceivableEntriesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            customerReceivableId: receivable.id,
            entryType: const drift.Value('Return'),
            amount: totalAmount,
            baseAmount: totalAmount * params.exchangeRate,
            createdBy: userId,
          );

          final newPaidAmount = receivable.paidAmount;
          final newRemainingAmount = receivable.remainingAmount - totalAmount;
          final newStatus = newRemainingAmount <= 0.001
              ? 'Paid'
              : (newPaidAmount > 0 ? 'Partial' : 'Unpaid');

          await _salesRepository.recordReceivableEntry(
            entryCompanion,
            customerReceivableId: receivable.id,
            businessId: businessId,
            newPaidAmount: newPaidAmount,
            newRemainingAmount: newRemainingAmount,
            newBasePaidAmount: newPaidAmount * params.exchangeRate,
            newBaseRemainingAmount: newRemainingAmount * params.exchangeRate,
            newStatus: newStatus,
          );
        }

        // Record Inventory Transaction
        await _inventoryRepository.recordTransactionWithLines(
          transaction: inventoryTxCompanion,
          lines: inventoryLineCompanions,
        );

        // Restock Inventory Quantities
        for (final item in params.items) {
          final inventory = await _inventoryRepository
              .getInventoryByUnitAndWarehouse(
                businessId,
                item.warehouseId,
                item.productUnitId,
              );
          if (inventory != null) {
            final newQuantity = inventory.quantity + item.quantity;
            await _inventoryRepository.updateInventory(
              inventory
                  .toCompanion(false)
                  .copyWith(quantity: drift.Value(newQuantity)),
            );
          } else {
            await _inventoryRepository.insertInventory(
              InventoriesCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                warehouseId: item.warehouseId,
                productUnitId: item.productUnitId,
                quantity: drift.Value(item.quantity),
              ),
            );
          }
        }

        // Post Journal Entry
        if (jeLines.isNotEmpty) {
          await _accountingRepository.postJournalEntryWithLines(
            entry: journalEntryCompanion,
            lines: jeLines,
          );
        }
      });

      return Right(returnId);
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}
