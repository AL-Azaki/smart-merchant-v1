import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/utils/precision_math.dart';
import '../../../catalog/application/services/product_unit_resolver.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../treasury/domain/repositories/treasury_repository.dart';
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
import '../../../../app/di/getit_instance.dart';
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
  final String? paymentMethodId;
  final String? supplierInvoiceNumber;
  final DateTime? dueDate;
  final double? paidAmount;
  final double? cashAmount;
  final double? bankAmount;

  const RecordPurchaseCommand({
    required this.supplierId,
    required this.currencyId,
    required this.items,
    this.exchangeRate = 1.0,
    this.notes,
    this.isCreditPurchase = true,
    this.paymentMethodId,
    this.supplierInvoiceNumber,
    this.dueDate,
    this.paidAmount,
    this.cashAmount,
    this.bankAmount,
  });
}

class RecordPurchaseUseCase implements UseCase<String, RecordPurchaseCommand> {
  final PurchasingRepository _purchasingRepository;
  final InventoryRepository _inventoryRepository;
  final AccountingRepository _accountingRepository;
  final AccountingApplicationService _accountingService;
  final TreasuryRepository _treasuryRepository;
  final ApplicationContext _context;
  final ApplicationTransactionRunner _transactionRunner;
  final ProductUnitResolver? _unitResolver;
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  RecordPurchaseUseCase(
    this._purchasingRepository,
    this._inventoryRepository,
    this._accountingRepository,
    this._accountingService,
    this._treasuryRepository,
    this._context,
    this._transactionRunner, {
    ProductUnitResolver? unitResolver,
    CatalogRepository? catalogRepository,
    AppDatabase? db,
  })  : _unitResolver = unitResolver ??
            (catalogRepository != null
                ? ProductUnitResolver(catalogRepository)
                : null),
        _db = db ?? getIt<AppDatabase>();

  @override
  Future<Either<Failure, String>> call(RecordPurchaseCommand params) async {
    final businessId = _context.currentBusinessId;
    final branchId = _context.currentBranchId;
    final userId = _context.currentUserId;

    print('--- RECORD PURCHASE COMMAND EXECUTING ---');
    print('Supplier ID: ${params.supplierId}');
    print('Is Credit: ${params.isCreditPurchase}');
    print('Payment Method ID: ${params.paymentMethodId}');
    print('Total Items: ${params.items.length}');
    print('Due Date: ${params.dueDate}');
    print('-----------------------------------------');

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

    // 0. Pre-Condition Guards: Guarantee DB integrity for Offline-First operations
    // Guard 1: Ensure User exists in usersTable (strictly prevents FOREIGN KEY constraint failed on created_by)
    final userCheck = await (_db.select(_db.usersTable)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (userCheck == null) {
      await _db.into(_db.usersTable).insertOnConflictUpdate(
        UsersTableCompanion.insert(
          id: drift.Value(userId),
          email: '$userId@smartmerchant.com',
          passwordHash: '',
          firstName: 'المدير',
          lastName: 'العام',
          isActive: const drift.Value(true),
        ),
      );
    }

    // Guard 2: Ensure Branch exists in branches table
    final branchCheck = await (_db.select(_db.branches)..where((t) => t.businessId.equals(businessId) & t.id.equals(branchId))).getSingleOrNull();
    if (branchCheck == null) {
      await _db.into(_db.branches).insertOnConflictUpdate(
        BranchesCompanion.insert(
          id: branchId,
          businessId: businessId,
          branchName: 'الفرع الرئيسي',
          branchCode: 'MAIN',
          isActive: const drift.Value(true),
        ),
      );
    }

    // Guard 3: Ensure Business exists in businesses table
    final businessCheck = await (_db.select(_db.businesses)..where((t) => t.id.equals(businessId))).getSingleOrNull();
    if (businessCheck == null) {
      final dummyAccountId = 'system-account-$userId';
      await _db.into(_db.accountsTable).insertOnConflictUpdate(
        AccountsTableCompanion.insert(
          id: drift.Value(dummyAccountId),
          ownerId: userId,
          businessName: 'المتجر الرئيسي',
          businessType: 'Retail',
          defaultCurrency: params.currencyId,
        ),
      );
      await _db.into(_db.businesses).insertOnConflictUpdate(
        BusinessesCompanion.insert(
          id: businessId,
          accountId: dummyAccountId,
          businessName: 'المتجر الرئيسي',
          businessType: const drift.Value('Retail'),
          status: const drift.Value('Active'),
        ),
      );
    }

    // Guard 4: Validate Supplier exists in suppliers table
    final supplierCheck = await (_db.select(_db.suppliers)..where((s) => s.businessId.equals(businessId) & s.id.equals(params.supplierId))).getSingleOrNull();
    if (supplierCheck == null) {
      return const Left(ValidationFailure('المورد المحدد غير مسجل في قاعدة البيانات المحلية.'));
    }

    // Guard 5: Validate Warehouse exists in warehouses table
    final whId = params.items.first.warehouseId;
    final warehouseCheck = await (_db.select(_db.warehouses)..where((w) => w.businessId.equals(businessId) & w.id.equals(whId))).getSingleOrNull();
    if (warehouseCheck == null) {
      return const Left(ValidationFailure('المخزن المحدد غير مسجل في قاعدة البيانات المحلية.'));
    }

    // 1. Resolve Accounting Mappings
    final apIdResult = await _accountingService.resolveAccountMapping(
      'accounts_payable',
    );
    if (apIdResult.isLeft()) {
      return Left(apIdResult.fold((l) => l, (r) => throw Exception()));
    }
    final accountsPayableId = apIdResult.getOrElse(() => '');

    // Resolve Cash Account & Payment Method
    String resolvedCashAccountId = '';
    PaymentMethod? resolvedCashPaymentMethod =
        await _treasuryRepository.getPaymentMethodByCode('CASH', businessId);
    if (resolvedCashPaymentMethod != null) {
      resolvedCashAccountId = resolvedCashPaymentMethod.chartOfAccountId;
    } else {
      final cashMainResult =
          await _accountingService.resolveAccountMapping('cash_main');
      if (cashMainResult.isRight()) {
        resolvedCashAccountId = cashMainResult.getOrElse(() => '');
      } else {
        resolvedCashAccountId = accountsPayableId;
      }
    }

    // Resolve Bank / Network / Wallet Account & Payment Method
    String resolvedBankAccountId = '';
    PaymentMethod? resolvedBankPaymentMethod =
        await _treasuryRepository.getPaymentMethodByCode('BANK', businessId) ??
        await _treasuryRepository.getPaymentMethodByCode('CARD', businessId);

    if (resolvedBankPaymentMethod == null) {
      final activeMethods = await _treasuryRepository.listPaymentMethods(businessId, isActive: true);
      resolvedBankPaymentMethod = activeMethods.where((m) =>
          m.paymentType == 'Bank' ||
          m.paymentType == 'DigitalWallet' ||
          m.paymentType == 'Card').firstOrNull;
    }

    if (resolvedBankPaymentMethod != null) {
      resolvedBankAccountId = resolvedBankPaymentMethod.chartOfAccountId;
    } else {
      final bankMainResult =
          await _accountingService.resolveAccountMapping('bank_main');
      if (bankMainResult.isRight()) {
        resolvedBankAccountId = bankMainResult.getOrElse(() => '');
      } else {
        resolvedBankAccountId = resolvedCashAccountId.isNotEmpty
            ? resolvedCashAccountId
            : accountsPayableId;
      }
    }

    // Custom payment method passed
    if (params.paymentMethodId != null &&
        params.paymentMethodId != 'CASH' &&
        params.paymentMethodId != 'BANK' &&
        params.paymentMethodId != 'CARD' &&
        params.paymentMethodId != 'SPLIT' &&
        params.paymentMethodId != 'CREDIT') {
      final customPm = await _treasuryRepository.getPaymentMethodById(
        params.paymentMethodId!,
        businessId,
      );
      if (customPm != null) {
        if (customPm.paymentType == 'Bank' || customPm.paymentType == 'Card') {
          resolvedBankPaymentMethod = customPm;
          resolvedBankAccountId = customPm.chartOfAccountId;
        } else if (customPm.paymentType == 'Cash') {
          resolvedCashPaymentMethod = customPm;
          resolvedCashAccountId = customPm.chartOfAccountId;
        }
      }
    }

    final inventoryAssetIdResult = await _accountingService
        .resolveAccountMapping('inventory_asset');
    if (inventoryAssetIdResult.isLeft()) {
      return Left(
        inventoryAssetIdResult.fold((l) => l, (r) => throw Exception()),
      );
    }
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

    // 3. Prepare Purchase Entities & Split/Partial Payment Calculations
    final invoiceId = _uuid.v4();
    final invoiceNumber = 'PINV-${DateTime.now().millisecondsSinceEpoch}';
    final invoiceDate = DateTime.now();

    // Ensure dueDate is not before invoiceDate to satisfy CHECK constraint (due_date >= purchase_date)
    final effectiveDueDate =
        (params.dueDate != null && params.dueDate!.isBefore(invoiceDate))
        ? invoiceDate
        : params.dueDate;

    // Calculate effective cash, bank, and remaining payables amounts
    double effectiveCash = 0.0;
    double effectiveBank = 0.0;

    if (params.cashAmount != null || params.bankAmount != null) {
      effectiveCash = (params.cashAmount ?? 0.0).clamp(0.0, grandTotal);
      final maxBank = (grandTotal - effectiveCash).clamp(0.0, grandTotal);
      effectiveBank = (params.bankAmount ?? 0.0).clamp(0.0, maxBank);
    } else if (params.paidAmount != null) {
      final p = params.paidAmount!.clamp(0.0, grandTotal);
      final methodUpper = (params.paymentMethodId ?? '').toUpperCase();
      if (methodUpper == 'BANK' || methodUpper == 'CARD' || methodUpper == 'NETWORK') {
        effectiveBank = p;
      } else {
        effectiveCash = p;
      }
    } else {
      if (!params.isCreditPurchase) {
        final methodUpper = (params.paymentMethodId ?? '').toUpperCase();
        if (methodUpper == 'BANK' || methodUpper == 'CARD' || methodUpper == 'NETWORK') {
          effectiveBank = grandTotal;
        } else {
          effectiveCash = grandTotal;
        }
      }
    }

    final effectiveTotalPaid = PrecisionMath.roundMoney(effectiveCash + effectiveBank);
    final remainingAmount = PrecisionMath.roundMoney(grandTotal - effectiveTotalPaid);

    final invoiceCompanion = PurchaseInvoicesCompanion.insert(
      id: invoiceId,
      businessId: businessId,
      branchId: branchId,
      warehouseId: params.items.first.warehouseId,
      supplierId: params.supplierId,
      invoiceNumber: invoiceNumber,
      purchaseDate: drift.Value(invoiceDate),
      dueDate: drift.Value(effectiveDueDate),
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
      paymentStatus: drift.Value(
        effectiveTotalPaid >= grandTotal - 0.001
            ? 'Paid'
            : (effectiveTotalPaid > 0.001 ? 'Partial' : 'Unpaid'),
      ),
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
    if (remainingAmount > 0.001 || params.isCreditPurchase) {
      payableCompanion = SupplierPayablesCompanion.insert(
        id: _uuid.v4(),
        businessId: businessId,
        supplierId: params.supplierId,
        currencyId: params.currencyId,
        purchaseInvoiceId: invoiceId,
        dueDate: drift.Value(effectiveDueDate),
        originalAmount: grandTotal,
        paidAmount: drift.Value(effectiveTotalPaid),
        remainingAmount: remainingAmount,
        baseOriginalAmount: grandTotal * params.exchangeRate,
        basePaidAmount: drift.Value(effectiveTotalPaid * params.exchangeRate),
        baseRemainingAmount: remainingAmount * params.exchangeRate,
        status: drift.Value(
          effectiveTotalPaid >= grandTotal - 0.001
              ? 'Paid'
              : (effectiveTotalPaid > 0.001 ? 'Partial' : 'Unpaid'),
        ),
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

    // Treasury Payment Vouchers
    final List<PaymentsCompanion> paymentsToRecord = [];
    if (effectiveCash > 0.001 && resolvedCashPaymentMethod != null) {
      paymentsToRecord.add(
        PaymentsCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          branchId: branchId,
          paymentNumber: 'PAY-CASH-${DateTime.now().millisecondsSinceEpoch}',
          paymentDate: drift.Value(invoiceDate),
          paymentMethodId: resolvedCashPaymentMethod.id,
          chartOfAccountId: resolvedCashAccountId,
          currencyId: params.currencyId,
          exchangeRate: drift.Value(params.exchangeRate),
          amount: effectiveCash,
          baseAmount: effectiveCash * params.exchangeRate,
          paymentType: 'Payment',
          contactType: const drift.Value('Supplier'),
          contactId: drift.Value(params.supplierId),
          status: const drift.Value('Posted'),
          notes: drift.Value(params.notes ?? 'سداد نقدي لفاتورة مشتريات $invoiceNumber'),
          createdBy: userId,
          postedBy: drift.Value(userId),
          postedAt: drift.Value(invoiceDate),
        ),
      );
    }
    if (effectiveBank > 0.001 && resolvedBankPaymentMethod != null) {
      paymentsToRecord.add(
        PaymentsCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          branchId: branchId,
          paymentNumber: 'PAY-BANK-${DateTime.now().millisecondsSinceEpoch}',
          paymentDate: drift.Value(invoiceDate),
          paymentMethodId: resolvedBankPaymentMethod.id,
          chartOfAccountId: resolvedBankAccountId,
          currencyId: params.currencyId,
          exchangeRate: drift.Value(params.exchangeRate),
          amount: effectiveBank,
          baseAmount: effectiveBank * params.exchangeRate,
          paymentType: 'Payment',
          contactType: const drift.Value('Supplier'),
          contactId: drift.Value(params.supplierId),
          status: const drift.Value('Posted'),
          notes: drift.Value(params.notes ?? 'سداد شبكة / بنك لفاتورة مشتريات $invoiceNumber'),
          createdBy: userId,
          postedBy: drift.Value(userId),
          postedAt: drift.Value(invoiceDate),
        ),
      );
    }

    // 5. Prepare Journal Entry
    var periods = await _accountingRepository.listFiscalPeriods(
      FiscalPeriodFilter(businessId: businessId, status: 'Open'),
    );
    if (periods.isEmpty) {
      final currentYear = DateTime.now().year;
      final fyId = _uuid.v4();
      await _db.into(_db.fiscalYears).insertOnConflictUpdate(
        FiscalYearsCompanion.insert(
          id: fyId,
          businessId: businessId,
          fiscalYearCode: 'FY-$currentYear',
          fiscalYearName: 'السنة المالية $currentYear',
          startDate: DateTime(currentYear, 1, 1),
          endDate: DateTime(currentYear, 12, 31),
          status: const drift.Value('Open'),
        ),
      );
      await _db.into(_db.fiscalPeriods).insert(
        FiscalPeriodsCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          fiscalYearId: fyId,
          periodNumber: 1,
          periodName: 'الفترة المالية $currentYear',
          startDate: DateTime(currentYear, 1, 1),
          endDate: DateTime(currentYear, 12, 31),
          status: const drift.Value('Open'),
        ),
      );
      periods = await _accountingRepository.listFiscalPeriods(
        FiscalPeriodFilter(businessId: businessId, status: 'Open'),
      );
    }
    if (periods.isEmpty) {
      return const Left(
        BusinessValidationFailure(
          'تعذر العثور على أو إنشاء فترة مالية نشطة لقيد المعاملة.',
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
      description: drift.Value('فاتورة مشتريات رقم $invoiceNumber'),
      status: const drift.Value('Posted'),
      createdBy: userId,
      postedBy: drift.Value(userId),
      postedAt: drift.Value(invoiceDate),
    );

    int lineSequence = 1;
    final baseGrandTotal = PrecisionMath.toBaseAmount(
      foreignAmount: grandTotal,
      exchangeRate: params.exchangeRate,
    );

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
        baseAmount: drift.Value(baseGrandTotal),
        description: const drift.Value('توريد مخزون مشتريات'),
      ),
    ];

    // Credit 1: Cash Payment (if effectiveCash > 0)
    if (effectiveCash > 0.001) {
      journalLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalId,
          chartOfAccountId: resolvedCashAccountId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Credit',
          foreignAmount: drift.Value(effectiveCash),
          baseAmount: drift.Value(effectiveCash * params.exchangeRate),
          description: const drift.Value('مدفوعات مشتريات نقدية'),
        ),
      );
    }

    // Credit 2: Bank / Card Payment (if effectiveBank > 0)
    if (effectiveBank > 0.001) {
      journalLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalId,
          chartOfAccountId: resolvedBankAccountId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Credit',
          foreignAmount: drift.Value(effectiveBank),
          baseAmount: drift.Value(effectiveBank * params.exchangeRate),
          description: const drift.Value('مدفوعات مشتريات شبكة وبنك'),
        ),
      );
    }

    // Credit 3: Accounts Payable (if remainingAmount > 0)
    if (remainingAmount > 0.001) {
      journalLines.add(
        JournalEntryLinesCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          journalEntryId: journalId,
          chartOfAccountId: accountsPayableId,
          currencyId: params.currencyId,
          lineNumber: lineSequence++,
          type: 'Credit',
          foreignAmount: drift.Value(remainingAmount),
          baseAmount: drift.Value(remainingAmount * params.exchangeRate),
          description: const drift.Value('ذمم موردين مشتريات آجلة'),
        ),
      );
    }

    // 6. Execute Transaction
    try {
      await _transactionRunner.runInTransaction(() async {
        // Record Purchase & Payable
        await _purchasingRepository.recordInvoiceWithItemsAndPayable(
          invoice: invoiceCompanion,
          items: invoiceItemsCompanions.cast<PurchaseInvoiceItemsCompanion>(),
          payable: payableCompanion,
        );

        // Add Inventory Transaction Logs
        await _inventoryRepository.recordTransactionWithLines(
          transaction: inventoryTxCompanion,
          lines: inventoryLineCompanions
              .cast<InventoryTransactionLinesCompanion>(),
        );

        // Update actual stock quantities and calculate new average cost in Base Currency
        for (final item in params.items) {
          ResolvedUnitInfo? unitInfo;
          if (_unitResolver != null) {
            try {
              unitInfo = await _unitResolver!.resolve(
                item.productUnitId,
                businessId,
              );
            } catch (_) {}
          }

          final targetUnitId = unitInfo?.baseUnit.id ?? item.productUnitId;
          final baseQuantity = unitInfo != null
              ? unitInfo.toBaseQuantity(item.quantity)
              : PrecisionMath.roundQty(item.quantity);
          final baseUnitCost = unitInfo != null
              ? unitInfo.toBaseUnitCost(
                  unitCost: item.unitCost,
                  exchangeRate: params.exchangeRate,
                )
              : PrecisionMath.toBaseAmount(
                  foreignAmount: item.unitCost,
                  exchangeRate: params.exchangeRate,
                  decimals: 4,
                );

          final inventory = await _inventoryRepository
              .getInventoryByUnitAndWarehouse(
                businessId,
                item.warehouseId,
                targetUnitId,
              );
          if (inventory != null) {
            final oldQty = inventory.quantity;
            final oldAvgCost = inventory.averageCost;
            final updatedQty = PrecisionMath.roundQty(oldQty + baseQuantity);
            final updatedAvgCost = PrecisionMath.calculateWac(
              oldQty: oldQty,
              oldAvgCost: oldAvgCost,
              newQty: baseQuantity,
              newUnitCostInBase: baseUnitCost,
            );

            await _inventoryRepository.updateInventory(
              inventory
                  .toCompanion(false)
                  .copyWith(
                    quantity: drift.Value(updatedQty),
                    averageCost: drift.Value(updatedAvgCost),
                  ),
            );
          } else {
            await _inventoryRepository.insertInventory(
              InventoriesCompanion.insert(
                id: _uuid.v4(),
                businessId: businessId,
                warehouseId: item.warehouseId,
                productUnitId: targetUnitId,
                quantity: drift.Value(baseQuantity),
                averageCost: drift.Value(baseUnitCost),
              ),
            );
          }
        }

        // Record Treasury Payments if applicable
        for (final payment in paymentsToRecord) {
          await _treasuryRepository.insertPayment(payment);
        }

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
