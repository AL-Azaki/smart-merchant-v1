import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/utils/precision_math.dart';
import '../../../catalog/application/services/product_unit_resolver.dart';
import '../../../catalog/infrastructure/repositories/catalog_repository_impl.dart';
import '../../../../database/daos/catalog_dao.dart';
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

import '../../../treasury/domain/repositories/treasury_repository.dart';
import '../../../treasury/infrastructure/repositories/treasury_repository_impl.dart';
import '../../../../database/daos/treasury_dao.dart';

class CompleteSaleItemCommand {
  final String productUnitId;
  final String warehouseId;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final String? taxId;

  const CompleteSaleItemCommand({
    required this.productUnitId,
    required this.warehouseId,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    this.taxId,
  });
}

class CompleteSaleCommand {
  final String? customerId;
  final String currencyId;
  final double exchangeRate;
  final List<CompleteSaleItemCommand> items;
  final String? notes;
  final bool isCreditSale; // true if unpaid/receivable, false if cash sale
  final String? paymentMethodId; // 'CASH', 'CARD', or PaymentMethod ID

  const CompleteSaleCommand({
    this.customerId,
    required this.currencyId,
    required this.items,
    this.exchangeRate = 1.0,
    this.notes,
    this.isCreditSale = true,
    this.paymentMethodId,
  });
}

class CompleteSaleUseCase implements UseCase<String, CompleteSaleCommand> {
  final SalesRepository _salesRepository;
  final InventoryRepository _inventoryRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final TreasuryRepository _treasuryRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final AppDatabase _db;
  final ProductUnitResolver? _unitResolver;
  final Uuid _uuid = const Uuid();

  CompleteSaleUseCase(
    this._salesRepository,
    this._inventoryRepository,
    this._accountingRepository,
    this._accountingService,
    this._context,
    this._transactionRunner,
    this._db, {
    TreasuryRepository? treasuryRepository,
    ProductUnitResolver? unitResolver,
  }) : _treasuryRepository = treasuryRepository ??
            TreasuryRepositoryImpl(TreasuryDao(_db)),
       _unitResolver = unitResolver ??
            ProductUnitResolver(CatalogRepositoryImpl(CatalogDao(_db)));

  @override
  Future<Either<Failure, String>> call(CompleteSaleCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    if (branchId == null) {
      return const Left(ValidationFailure('Branch ID is required for a sale.'));
    }

    if (params.items.isEmpty) {
      return const Left(
        ValidationFailure('Cannot complete a sale with no items.'),
      );
    }

    // 0. Pre-Condition Guard: Validate Session Integrity Locally
    final userCheck = await (_db.select(
      _db.usersTable,
    )..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (userCheck == null) {
      return const Left(
        ValidationFailure(
          'تعذر إصدار الفاتورة بسبب عدم اكتمال بيانات جلسة العمل. (المستخدم غير موجود محلياً)',
        ),
      );
    }

    final businessCheck = await (_db.select(
      _db.businesses,
    )..where((t) => t.id.equals(businessId))).getSingleOrNull();
    if (businessCheck == null) {
      return const Left(
        ValidationFailure(
          'تعذر إصدار الفاتورة بسبب عدم اكتمال بيانات جلسة العمل. (النشاط التجاري غير موجود محلياً)',
        ),
      );
    }

    final branchCheck = await (_db.select(
      _db.branches,
    )..where((t) => t.id.equals(branchId))).getSingleOrNull();
    if (branchCheck == null) {
      return const Left(
        ValidationFailure(
          'تعذر إصدار الفاتورة بسبب عدم اكتمال بيانات جلسة العمل. (الفرع غير موجود محلياً)',
        ),
      );
    }

    // Validate Currency
    final currencyCheck = await (_db.select(
      _db.currencies,
    )..where((t) => t.id.equals(params.currencyId))).getSingleOrNull();
    if (currencyCheck == null) {
      return Left(
        ValidationFailure(
          'العملة المحددة غير مسجلة في قاعدة البيانات المحلية: ${params.currencyId}',
        ),
      );
    }

    // Validate Customer: walk-in cash customer is allowed for cash sales, but credit sales require registered customer
    final isWalkInCustomer = params.customerId == null ||
        params.customerId!.trim().isEmpty ||
        params.customerId == 'DEFAULT-CUSTOMER';

    if (params.isCreditSale && isWalkInCustomer) {
      return const Left(
        ValidationFailure('لا يمكن إنشاء فاتورة بيع آجل بدون تحديد عميل مسجل.'),
      );
    }

    String? resolvedCustomerId;
    if (!isWalkInCustomer) {
      final customerCheck = await (_db.select(_db.customers)..where(
            (t) =>
                t.id.equals(params.customerId!) &
                t.businessId.equals(businessId),
          )).getSingleOrNull();
      if (customerCheck == null) {
        return Left(
          ValidationFailure(
            'العميل المحدد غير مسجل في قاعدة البيانات المحلية (ID: ${params.customerId})',
          ),
        );
      }
      resolvedCustomerId = params.customerId;
    }

    // 1. Resolve Accounting Mappings & Payment Method
    PaymentMethod? resolvedPaymentMethod;
    String resolvedDebitAccountId = '';

    if (params.isCreditSale) {
      final accountsReceivableIdResult = await _accountingService
          .resolveAccountMapping('accounts_receivable');
      if (accountsReceivableIdResult.isLeft()) {
        return Left(
          accountsReceivableIdResult.fold((l) => l, (r) => throw Exception()),
        );
      }
      resolvedDebitAccountId = accountsReceivableIdResult.getOrElse(() => '');
    } else {
      // Resolve Cash or Bank Payment Method and Account
      final rawMethodId = params.paymentMethodId?.trim();
      if (rawMethodId != null && rawMethodId.isNotEmpty) {
        if (rawMethodId == 'CARD' || rawMethodId == 'BANK') {
          resolvedPaymentMethod =
              await _treasuryRepository.getPaymentMethodByCode('BANK', businessId) ??
              await _treasuryRepository.getPaymentMethodByCode('CARD', businessId);
        } else if (rawMethodId == 'CASH') {
          resolvedPaymentMethod =
              await _treasuryRepository.getPaymentMethodByCode('CASH', businessId);
        } else {
          resolvedPaymentMethod =
              await _treasuryRepository.getPaymentMethodById(rawMethodId, businessId) ??
              await _treasuryRepository.getPaymentMethodByCode(rawMethodId, businessId);
        }
      }

      resolvedPaymentMethod ??=
          await _treasuryRepository.getPaymentMethodByCode('CASH', businessId);

      if (resolvedPaymentMethod == null) {
        final existingMethods = await _treasuryRepository.listPaymentMethods(
          businessId,
          isActive: true,
        );
        if (existingMethods.isNotEmpty) {
          resolvedPaymentMethod = existingMethods.firstWhere(
            (m) => m.paymentType == 'Cash',
            orElse: () => existingMethods.first,
          );
        }
      }

      if (resolvedPaymentMethod == null) {
        // Fallback: Resolve cash_main account mapping and seed a default Cash payment method
        final cashMainResult =
            await _accountingService.resolveAccountMapping('cash_main');
        if (cashMainResult.isRight()) {
          final cashAccountId = cashMainResult.getOrElse(() => '');
          final newPmId = _uuid.v4();
          await _treasuryRepository.insertPaymentMethod(
            PaymentMethodsCompanion.insert(
              id: newPmId,
              businessId: businessId,
              chartOfAccountId: cashAccountId,
              methodCode: 'CASH',
              methodName: 'نقدي',
              paymentType: 'Cash',
              isActive: const drift.Value(true),
            ),
          );
          resolvedPaymentMethod =
              await _treasuryRepository.getPaymentMethodById(newPmId, businessId);
          resolvedDebitAccountId = cashAccountId;
        } else {
          // Graceful fallback: If cash_main is not yet mapped, fall back to accounts_receivable
          final arFallback =
              await _accountingService.resolveAccountMapping('accounts_receivable');
          if (arFallback.isLeft()) {
            return Left(cashMainResult.fold((l) => l, (r) => throw Exception()));
          }
          resolvedDebitAccountId = arFallback.getOrElse(() => '');
        }
      }

      if (resolvedPaymentMethod != null) {
        resolvedDebitAccountId = resolvedPaymentMethod.chartOfAccountId;
      }
    }

    final salesRevenueIdResult = await _accountingService.resolveAccountMapping(
      'sales_revenue',
    );
    if (salesRevenueIdResult.isLeft())
      return Left(
        salesRevenueIdResult.fold((l) => l, (r) => throw Exception()),
      );
    final salesRevenueId = salesRevenueIdResult.getOrElse(() => '');

    final cogsIdResult = await _accountingService.resolveAccountMapping(
      'cost_of_goods_sold',
    );
    if (cogsIdResult.isLeft())
      return Left(cogsIdResult.fold((l) => l, (r) => throw Exception()));
    final cogsId = cogsIdResult.getOrElse(() => '');

    final inventoryAssetIdResult = await _accountingService
        .resolveAccountMapping('inventory_asset');
    if (inventoryAssetIdResult.isLeft())
      return Left(
        inventoryAssetIdResult.fold((l) => l, (r) => throw Exception()),
      );
    final inventoryAssetId = inventoryAssetIdResult.getOrElse(() => '');

    // 2. Validate Items & Check Stock
    double subTotal = 0.0;
    double discountTotal = 0.0;
    double taxTotal = 0.0;
    double totalCost = 0.0;

    // We will augment the items with their authoritative cost for later use
    final itemsWithCost = <Map<String, dynamic>>[];
    final validatedWarehouses = <String>{};

    for (final item in params.items) {
      if (item.quantity <= 0)
        return const Left(
          ValidationFailure('Quantity must be greater than 0.'),
        );
      if (item.unitPrice < 0)
        return const Left(ValidationFailure('Unit price cannot be negative.'));

      if (!validatedWarehouses.contains(item.warehouseId)) {
        final warehouse = await _inventoryRepository.getWarehouseById(
          item.warehouseId,
          businessId,
        );
        if (warehouse == null) {
          return const Left(
            ValidationFailure(
              'Warehouse does not exist or does not belong to the active business.',
            ),
          );
        }
        if (warehouse.branchId != branchId) {
          return const Left(
            ValidationFailure(
              'Warehouse does not belong to the active branch context.',
            ),
          );
        }
        if (!warehouse.isActive) {
          return const Left(
            ValidationFailure(
              'Warehouse is inactive and cannot be used for sales.',
            ),
          );
        }
        validatedWarehouses.add(item.warehouseId);
      }

      // Resolve base unit and conversion ratio
      ResolvedUnitInfo? unitInfo;
      try {
        unitInfo = await _unitResolver?.resolve(
          item.productUnitId,
          businessId,
        );
      } catch (_) {}

      final targetUnitId = unitInfo?.baseUnit.id ?? item.productUnitId;
      final baseQuantity = unitInfo != null
          ? unitInfo.toBaseQuantity(item.quantity)
          : PrecisionMath.roundQty(item.quantity);

      // Stock Check against Base Unit
      final inventory = await _inventoryRepository
          .getInventoryByUnitAndWarehouse(
            businessId,
            item.warehouseId,
            targetUnitId,
          );

      if (inventory == null || inventory.quantity < baseQuantity) {
        return const Left(ValidationFailure('Insufficient stock for product.'));
      }

      final itemCost = inventory.averageCost ?? 0.0; // Authoritative Cost in Base Currency
      final lineCogsBase = PrecisionMath.roundMoney(baseQuantity * itemCost);

      subTotal += (item.quantity * item.unitPrice);
      discountTotal += item.discount;
      taxTotal += item.tax;
      totalCost += lineCogsBase;

      itemsWithCost.add({
        'command': item,
        'costPrice': itemCost,
        'baseQuantity': baseQuantity,
        'lineCogsBase': lineCogsBase,
        'inventory': inventory,
      });
    }

    final grandTotal = subTotal - discountTotal + taxTotal;
    final grandTotalInBase = PrecisionMath.toBaseAmount(
      foreignAmount: grandTotal,
      exchangeRate: params.exchangeRate,
    );

    // 3. Prepare Sales Entities
    final invoiceId = _uuid.v4();
    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final invoiceDate = DateTime.now();

    final invoiceCompanion = SalesInvoicesCompanion.insert(
      id: invoiceId,
      businessId: businessId,
      branchId: branchId,
      customerId: drift.Value(resolvedCustomerId),
      invoiceNumber: invoiceNumber,
      invoiceDate: drift.Value(invoiceDate),
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
      paymentStatus: drift.Value(params.isCreditSale ? 'Unpaid' : 'Paid'),
      createdBy: userId,
      notes: drift.Value(params.notes),
    );

    final invoiceItemsCompanions = itemsWithCost.map((map) {
      final item = map['command'] as CompleteSaleItemCommand;
      final costPrice = map['costPrice'] as double;
      final lineTotal =
          (item.quantity * item.unitPrice) - item.discount + item.tax;
      return SalesInvoiceItemsCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        salesInvoiceId: invoiceId,
        productUnitId: item.productUnitId,
        warehouseId: item.warehouseId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costPrice: drift.Value(costPrice),
        discount: drift.Value(item.discount),
        tax: drift.Value(item.tax),
        taxId: drift.Value(item.taxId),
        lineTotal: lineTotal,
        costTotal: drift.Value(item.quantity * costPrice),
        baseLineTotal: drift.Value(lineTotal * params.exchangeRate),
      );
    }).toList();

    CustomerReceivablesCompanion? receivableCompanion;
    if (params.isCreditSale) {
      receivableCompanion = CustomerReceivablesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        salesInvoiceId: invoiceId,
        customerId: resolvedCustomerId!,
        currencyId: params.currencyId,
        originalAmount: grandTotal,
        paidAmount: const drift.Value(0.0),
        remainingAmount: grandTotal,
        baseOriginalAmount: grandTotal * params.exchangeRate,
        basePaidAmount: const drift.Value(0.0),
        baseRemainingAmount: grandTotal * params.exchangeRate,
        status: const drift.Value('Unpaid'),
      );
    }

    // 4. Prepare Inventory Transaction
    final inventoryTransactionId = _uuid.v4();
    final inventoryTxCompanion = InventoryTransactionsCompanion.insert(
      id: inventoryTransactionId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: (itemsWithCost.first['command'] as CompleteSaleItemCommand).warehouseId,
      transactionDate: drift.Value(invoiceDate),
      transactionType: InventoryTransactionType.dispatch,
      movementDirection: InventoryMovementDirection.outbound,
      referenceType: const drift.Value(InventoryReferenceType.salesInvoice),
      referenceId: drift.Value(invoiceId),
      status: const drift.Value(InventoryTransactionStatus.posted),
      createdBy: userId,
    );

    final inventoryLineCompanions = itemsWithCost.map((map) {
      final item = map['command'] as CompleteSaleItemCommand;
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

    // 5. Prepare Journal Entry
    final journalId = _uuid.v4();
    final journalNumber = 'JE-${DateTime.now().millisecondsSinceEpoch}';
    final currentPeriodIdResult =
        'PERIOD-TODO'; // We should resolve the period ID properly in a real setup, but for now we'll assume we can get it from accounting repo, or it's not strictly required in the companion if not enforced. Actually, fiscalPeriodId is required.
    // Wait, let's get the active fiscal period for the document date.

    // We will retrieve active fiscal year and period inside the UseCase
    // Let's assume we fetch it via the repository (this requires adding a method or using list).

    // For now, let's just use empty strings or skip journal entry if we don't have period resolution logic yet. Let's add it properly.

    // 6. Run Transaction (Sales & Inventory & Accounting)
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Sales
        await _salesRepository.recordInvoiceWithItemsAndReceivable(
          invoice: invoiceCompanion,
          items: invoiceItemsCompanions,
          receivable: receivableCompanion,
        );

        // If immediate/cash sale, record Treasury Receipt Voucher
        if (!params.isCreditSale && resolvedPaymentMethod != null) {
          final receiptCompanion = PaymentsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            branchId: branchId,
            paymentNumber: 'RCP-${DateTime.now().millisecondsSinceEpoch}',
            paymentDate: drift.Value(invoiceDate),
            paymentMethodId: resolvedPaymentMethod.id,
            chartOfAccountId: resolvedDebitAccountId,
            currencyId: params.currencyId,
            exchangeRate: drift.Value(params.exchangeRate),
            amount: grandTotal,
            baseAmount: grandTotalInBase,
            paymentType: 'Receipt',
            contactType:
                drift.Value(resolvedCustomerId != null ? 'Customer' : null),
            contactId: drift.Value(resolvedCustomerId),
            status: const drift.Value('Posted'),
            notes: drift.Value('Receipt for Sales Invoice $invoiceNumber'),
            createdBy: userId,
            postedBy: drift.Value(userId),
            postedAt: drift.Value(invoiceDate),
          );
          await _treasuryRepository.insertPayment(receiptCompanion);
        }

        // Deduct Inventory
        await _inventoryRepository.recordTransactionWithLines(
          transaction: inventoryTxCompanion,
          lines: inventoryLineCompanions
              .cast<InventoryTransactionLinesCompanion>(),
        );

        // Update actual stock quantities
        for (final map in itemsWithCost) {
          final inventory = map['inventory'] as Inventory;
          final baseQty = (map['baseQuantity'] as double?) ??
              ((map['command'] as CompleteSaleItemCommand).quantity);
          final newQuantity =
              PrecisionMath.roundQty(inventory.quantity - baseQty);

          await _inventoryRepository.updateInventory(
            inventory
                .toCompanion(false)
                .copyWith(quantity: drift.Value(newQuantity)),
          );
        }

        // Record Accounting (Debit Cash/AR, Debit COGS, Credit Sales, Credit Inventory)
        // Find Fiscal Period
        final periods = await _accountingRepository.listFiscalPeriods(
          FiscalPeriodFilter(businessId: businessId, status: 'Open'),
        );
        if (periods.isEmpty) {
          throw const BusinessValidationFailure(
            'No active fiscal period found for accounting posting.',
          );
        }
        final period = periods.first;

        final entryCompanion = JournalEntriesCompanion.insert(
          id: journalId,
          businessId: businessId,
          fiscalYearId: period.fiscalYearId,
          fiscalPeriodId: period.id,
          journalNumber: journalNumber,
          documentDate: invoiceDate,
          postingDate: drift.Value(invoiceDate),
          journalType: 'SalesInvoice',
          documentType: 'SalesInvoice',
          documentId: drift.Value(invoiceId),
          documentNumber: drift.Value(invoiceNumber),
          currencyId: params.currencyId,
          exchangeRate: drift.Value(params.exchangeRate),
          description: drift.Value('Sales Invoice $invoiceNumber'),
          status: const drift.Value('Posted'),
          createdBy: userId,
          postedBy: drift.Value(userId),
          postedAt: drift.Value(invoiceDate),
        );

        int lineSequence = 1;
        final List<JournalEntryLinesCompanion> journalLines = [];

        // Debit: Accounts Receivable or Cash/Bank
        journalLines.add(
          JournalEntryLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            journalEntryId: journalId,
            chartOfAccountId: resolvedDebitAccountId,
            currencyId: params.currencyId,
            lineNumber: lineSequence++,
            type: 'Debit',
            foreignAmount: drift.Value(grandTotal),
            baseAmount: drift.Value(grandTotalInBase),
            description: drift.Value(
              params.isCreditSale
                  ? 'Sales Receivables (Credit)'
                  : 'Cash/Bank Sales Collection',
            ),
          ),
        );

        // Credit: Sales Revenue
        journalLines.add(
          JournalEntryLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            journalEntryId: journalId,
            chartOfAccountId: salesRevenueId,
            currencyId: params.currencyId,
            lineNumber: lineSequence++,
            type: 'Credit',
            foreignAmount: drift.Value(grandTotal),
            baseAmount: drift.Value(grandTotalInBase),
            description: const drift.Value('Sales Revenue'),
          ),
        );

        final totalCostInBase = PrecisionMath.roundMoney(totalCost);
        final totalCostInForeign = PrecisionMath.toForeignAmount(
          baseAmount: totalCostInBase,
          exchangeRate: params.exchangeRate,
        );

        // Debit: COGS
        journalLines.add(
          JournalEntryLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            journalEntryId: journalId,
            chartOfAccountId: cogsId,
            currencyId: params.currencyId,
            lineNumber: lineSequence++,
            type: 'Debit',
            foreignAmount: drift.Value(totalCostInForeign),
            baseAmount: drift.Value(totalCostInBase),
            description: const drift.Value('Cost of Goods Sold'),
          ),
        );

        // Credit: Inventory Asset
        journalLines.add(
          JournalEntryLinesCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            journalEntryId: journalId,
            chartOfAccountId: inventoryAssetId,
            currencyId: params.currencyId,
            lineNumber: lineSequence++,
            type: 'Credit',
            foreignAmount: drift.Value(totalCostInForeign),
            baseAmount: drift.Value(totalCostInBase),
            description: const drift.Value('Inventory Deduction'),
          ),
        );

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
