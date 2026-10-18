import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/core/application_context.dart';
import '../../../../core/utils/precision_math.dart';
import '../../../../database/enums/stock_count_status.dart';
import '../../../../database/enums/inventory_transaction_type.dart';
import '../../../../database/enums/inventory_transaction_status.dart';
import '../../../../database/enums/inventory_movement_direction.dart';
import '../../../../database/enums/inventory_reference_type.dart';
import '../../../accounting/application/services/accounting_application_service.dart';
import '../../../accounting/application/usecases/post_journal_entry_usecase.dart';
import '../../domain/models/stock_count_commands.dart';

class InventoryWorkflowException implements Exception {
  final String message;
  const InventoryWorkflowException(this.message);
  @override
  String toString() => message;
}

class InventoryRecordLine {
  final String name, unit;
  final double quantity;
  const InventoryRecordLine(this.name, this.unit, this.quantity);
}

class InventoryRecordData {
  final String reference, location;
  final String? notes;
  final DateTime date;
  final List<InventoryRecordLine> lines;
  const InventoryRecordData({
    required this.reference,
    required this.location,
    required this.date,
    required this.lines,
    this.notes,
  });
}

class StockCountCandidate {
  final Product product;
  final ProductUnit unit;
  final String unitName;
  final double quantity, unitCost;
  const StockCountCandidate({
    required this.product,
    required this.unit,
    required this.unitName,
    required this.quantity,
    required this.unitCost,
  });
}

class StockCountDocument {
  final StockCount count;
  final List<StockCountItem> items;
  final Map<String, String> names, unitNames;
  final String warehouseName, currency;
  const StockCountDocument({
    required this.count,
    required this.items,
    required this.names,
    required this.unitNames,
    required this.warehouseName,
    required this.currency,
  });
  double get shortage => PrecisionMath.roundMoney(
    items
        .where((i) => i.differenceQuantity < 0)
        .fold(0.0, (v, i) => v - i.differenceQuantity * i.unitCost),
  );
  double get surplus => PrecisionMath.roundMoney(
    items
        .where((i) => i.differenceQuantity > 0)
        .fold(0.0, (v, i) => v + i.differenceQuantity * i.unitCost),
  );
}

/// Quantities, valuation snapshots, movements and journals commit atomically.
class StockCountWorkflow {
  final AppDatabase db;
  final ApplicationContext context;
  final AccountingApplicationService accounts;
  final PostJournalEntryUseCase postJournal;
  static const _uuid = Uuid();
  StockCountWorkflow(this.db, this.context, this.accounts, this.postJournal);
  String get businessId => context.currentBusinessId;

  Stream<List<InventoryTransaction>> watchAdjustments() =>
      (db.select(db.inventoryTransactions)
            ..where(
              (t) =>
                  t.businessId.equals(businessId) &
                  t.branchId.equals(context.currentBranchId ?? '') &
                  t.referenceType.equalsValue(
                    InventoryReferenceType.adjustment,
                  ),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Stream<List<InventoryTransfer>> watchTransfers() {
    final from = db.alias(db.warehouses, 'transfer_source');
    final to = db.alias(db.warehouses, 'transfer_target');
    final transfers = db.inventoryTransfers;
    return (db.select(transfers).join([
            innerJoin(from, from.id.equalsExp(transfers.fromWarehouseId)),
            innerJoin(to, to.id.equalsExp(transfers.toWarehouseId)),
          ])
          ..where(
            transfers.businessId.equals(businessId) &
                (from.branchId.equals(context.currentBranchId ?? '') |
                    to.branchId.equals(context.currentBranchId ?? '')),
          )
          ..orderBy([OrderingTerm.desc(transfers.transferDate)]))
        .watch()
        .map((rows) => rows.map((r) => r.readTable(transfers)).toList());
  }

  Never _fail(String message) => throw InventoryWorkflowException(message);

  Future<List<InventoryRecordLine>> _recordLines(
    List<(String, double)> quantities,
  ) async {
    final units = db.productUnits, products = db.products, labels = db.units;
    final rows =
        await (db.select(units).join([
              innerJoin(
                products,
                products.id.equalsExp(units.productId) &
                    products.businessId.equals(businessId),
              ),
              innerJoin(
                labels,
                labels.id.equalsExp(units.unitId) &
                    labels.businessId.equals(businessId),
              ),
            ])..where(
              units.businessId.equals(businessId) &
                  units.id.isIn(quantities.map((q) => q.$1)),
            ))
            .get();
    final names = {
      for (final row in rows)
        row.readTable(units).id: (
          row.readTable(products).productName,
          row.readTable(labels).unitName,
        ),
    };
    return [
      for (final q in quantities)
        InventoryRecordLine(
          names[q.$1]?.$1 ?? 'منتج غير متاح',
          names[q.$1]?.$2 ?? 'وحدة',
          q.$2,
        ),
    ];
  }

  Future<InventoryRecordData> loadTransfer(String id) async {
    final transfer =
        await (db.select(db.inventoryTransfers)
              ..where((t) => t.businessId.equals(businessId) & t.id.equals(id)))
            .getSingleOrNull();
    if (transfer == null) {
      _fail('التحويل غير موجود.');
    }
    final warehouses =
        await (db.select(db.warehouses)..where(
              (w) =>
                  w.businessId.equals(businessId) &
                  w.id.isIn([transfer.fromWarehouseId, transfer.toWarehouseId]),
            ))
            .get();
    if (!warehouses.any((w) => w.branchId == context.currentBranchId)) {
      _fail('التحويل لا يخص الفرع الحالي.');
    }
    final names = {for (final w in warehouses) w.id: w.warehouseName};
    final items =
        await (db.select(db.inventoryTransferItems)..where(
              (i) => i.businessId.equals(businessId) & i.transferId.equals(id),
            ))
            .get();
    return InventoryRecordData(
      reference: transfer.transferNumber,
      location:
          '${names[transfer.fromWarehouseId] ?? 'مستودع المصدر'} ← ${names[transfer.toWarehouseId] ?? 'مستودع المستلم'}',
      notes: transfer.notes,
      date: transfer.transferDate,
      lines: await _recordLines([
        for (final i in items) (i.productUnitId, i.quantity),
      ]),
    );
  }

  Future<InventoryRecordData> loadAdjustment(String id) async {
    final tx =
        await (db.select(db.inventoryTransactions)..where(
              (t) =>
                  t.id.equals(id) &
                  t.businessId.equals(businessId) &
                  t.branchId.equals(context.currentBranchId ?? ''),
            ))
            .getSingleOrNull();
    if (tx == null) {
      _fail('الحركة غير موجودة في الفرع الحالي.');
    }
    final warehouse =
        await (db.select(db.warehouses)..where(
              (w) =>
                  w.businessId.equals(businessId) & w.id.equals(tx.warehouseId),
            ))
            .getSingleOrNull();
    final items =
        await (db.select(db.inventoryTransactionLines)..where(
              (i) =>
                  i.businessId.equals(businessId) &
                  i.inventoryTransactionId.equals(id),
            ))
            .get();
    return InventoryRecordData(
      reference: tx.transactionType == InventoryTransactionType.adjustmentIn
          ? 'زيادة مخزون'
          : 'نقص مخزون',
      location: warehouse?.warehouseName ?? 'مستودع',
      date: tx.transactionDate,
      lines: await _recordLines([
        for (final i in items) (i.productUnitId, i.quantity),
      ]),
    );
  }

  Future<Warehouse> _warehouse(String id) async {
    final warehouse =
        await (db.select(db.warehouses)..where(
              (w) =>
                  w.id.equals(id) &
                  w.businessId.equals(businessId) &
                  w.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (warehouse == null ||
        !warehouse.isActive ||
        warehouse.branchId != context.currentBranchId) {
      _fail('اختر مستودعاً نشطاً من الفرع الحالي.');
    }
    return warehouse;
  }

  Future<StockCount> _count(String id) async {
    final count =
        await (db.select(db.stockCounts)..where(
              (c) =>
                  c.id.equals(id) &
                  c.businessId.equals(businessId) &
                  c.branchId.equals(context.currentBranchId ?? ''),
            ))
            .getSingleOrNull();
    if (count == null) {
      _fail('الجرد غير موجود في الفرع الحالي.');
    }
    return count;
  }

  Stream<List<StockCount>> watchCounts() =>
      (db.select(db.stockCounts)
            ..where(
              (c) =>
                  c.businessId.equals(businessId) &
                  c.branchId.equals(context.currentBranchId ?? ''),
            )
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  Future<List<StockCountCandidate>> candidates(String warehouseId) async {
    await _warehouse(warehouseId);
    final p = db.products,
        u = db.productUnits,
        stock = db.inventories,
        unit = db.units;
    final rows =
        await (db.select(p).join([
                innerJoin(
                  u,
                  u.productId.equalsExp(p.id) &
                      u.businessId.equals(businessId) &
                      u.isBaseUnit.equals(true) &
                      u.isActive.equals(true) &
                      u.deletedAt.isNull(),
                ),
                leftOuterJoin(
                  stock,
                  stock.productUnitId.equalsExp(u.id) &
                      stock.businessId.equals(businessId) &
                      stock.warehouseId.equals(warehouseId) &
                      stock.deletedAt.isNull(),
                ),
                innerJoin(
                  unit,
                  unit.id.equalsExp(u.unitId) &
                      unit.businessId.equals(businessId),
                ),
              ])
              ..where(
                p.businessId.equals(businessId) &
                    p.isActive.equals(true) &
                    p.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm.asc(p.productName)]))
            .get();
    final currencies = await db.select(db.currencies).get();
    return rows.map((r) {
      final product = r.readTable(p), productUnit = r.readTable(u);
      final inventory = r.readTableOrNull(stock);
      final currency = currencies
          .where((c) => c.id == product.currencyId)
          .firstOrNull;
      return StockCountCandidate(
        product: product,
        unit: productUnit,
        unitName: r.readTable(unit).unitName,
        quantity: inventory?.quantity ?? 0,
        unitCost:
            inventory?.averageCost ??
            (productUnit.purchasePrice == 0
                ? 0
                : product.currencyId == null
                ? productUnit.purchasePrice
                : currency != null &&
                      currency.exchangeRate.isFinite &&
                      currency.exchangeRate > 0
                ? productUnit.purchasePrice * currency.exchangeRate
                : double.nan),
      );
    }).toList();
  }

  Future<StockCountDocument> load(String id) async {
    final count = await _count(id);
    final items =
        await (db.select(db.stockCountItems)..where(
              (i) =>
                  i.businessId.equals(businessId) & i.stockCountId.equals(id),
            ))
            .get();
    final products =
        await (db.select(db.products)..where(
              (p) =>
                  p.businessId.equals(businessId) &
                  p.id.isIn(items.map((i) => i.productId)),
            ))
            .get();
    final units =
        await (db.select(db.productUnits).join([
              innerJoin(
                db.units,
                db.units.id.equalsExp(db.productUnits.unitId),
              ),
            ])..where(
              db.productUnits.businessId.equals(businessId) &
                  db.productUnits.id.isIn(items.map((i) => i.productUnitId)),
            ))
            .get();
    final warehouse =
        await (db.select(db.warehouses)..where(
              (w) =>
                  w.id.equals(count.warehouseId) &
                  w.businessId.equals(businessId),
            ))
            .getSingleOrNull();
    final currency = await (db.select(
      db.currencies,
    )..where((c) => c.isBaseCurrency.equals(true))).getSingleOrNull();
    return StockCountDocument(
      count: count,
      items: items,
      names: {for (final p in products) p.id: p.productName},
      unitNames: {
        for (final r in units)
          r.readTable(db.productUnits).id: r.readTable(db.units).unitName,
      },
      warehouseName: warehouse?.warehouseName ?? 'مستودع',
      currency: currency?.currencySymbol ?? '',
    );
  }

  Future<String> save(
    SaveStockCountCommand command,
  ) => db.transaction(() async {
    final warehouse = await _warehouse(command.warehouseId);
    final existing = command.id == null ? null : await _count(command.id!);
    if (existing != null &&
        (existing.status != StockCountStatus.draft ||
            existing.warehouseId != warehouse.id)) {
      _fail('يمكن تعديل مسودة الجرد فقط مع إبقاء المستودع نفسه.');
    }
    if (command.items.isEmpty) {
      _fail('أدخل الكمية الفعلية لمنتج واحد على الأقل.');
    }
    final candidatesById = {
      for (final c in await candidates(warehouse.id)) c.unit.id: c,
    };
    final seen = <String>{};
    final id = existing?.id ?? _uuid.v4(), now = DateTime.now();
    final lines = <StockCountItemsCompanion>[];
    for (final item in command.items) {
      final candidate = candidatesById[item.productUnitId];
      if (candidate == null ||
          candidate.product.id != item.productId ||
          !seen.add(item.productUnitId)) {
        _fail('راجع المنتجات؛ يوجد صنف مكرر أو غير متاح للجرد.');
      }
      if (!item.countedQuantity.isFinite ||
          !item.expectedQuantity.isFinite ||
          item.countedQuantity < 0 ||
          item.expectedQuantity < 0) {
        _fail('الكميات يجب أن تكون أرقاماً صحيحة أو عشرية غير سالبة.');
      }
      if (!candidate.unitCost.isFinite || candidate.unitCost < 0) {
        _fail(
          'تعذر تحديد تكلفة المنتج بالعملة الأساسية. راجع عملة المنتج وتكلفته أولاً.',
        );
      }
      final physical = PrecisionMath.roundQty(item.countedQuantity),
          expected = PrecisionMath.roundQty(item.expectedQuantity);
      lines.add(
        StockCountItemsCompanion.insert(
          id: _uuid.v4(),
          businessId: businessId,
          stockCountId: id,
          productId: item.productId,
          productUnitId: item.productUnitId,
          expectedQuantity: expected,
          countedQuantity: physical,
          differenceQuantity: PrecisionMath.roundQty(physical - expected),
          unitCost: Value(candidate.unitCost),
          createdAt: Value(now),
        ),
      );
    }
    if (existing == null) {
      await db
          .into(db.stockCounts)
          .insert(
            StockCountsCompanion.insert(
              id: id,
              businessId: businessId,
              branchId: warehouse.branchId,
              warehouseId: warehouse.id,
              countNumber: 'SC-${now.microsecondsSinceEpoch}',
              createdBy: context.currentUserId,
              notes: Value(command.notes),
              createdAt: Value(now),
              financialStatus: const Value('Pending'),
            ),
          );
    } else {
      await (db.update(
        db.stockCounts,
      )..where((c) => c.id.equals(id) & c.businessId.equals(businessId))).write(
        StockCountsCompanion(
          notes: Value(command.notes),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
          version: Value(existing.version + 1),
        ),
      );
      await (db.delete(db.stockCountItems)..where(
            (i) => i.stockCountId.equals(id) & i.businessId.equals(businessId),
          ))
          .go();
    }
    await db.batch((b) => b.insertAll(db.stockCountItems, lines));
    return id;
  });

  Future<String> _mappedAccount(String key) async {
    final result = await accounts.resolveAccountMapping(key);
    final id = result.fold(
      (f) => _fail('يلزم ضبط حسابات المخزون في المالية قبل الاعتماد.'),
      (id) => id,
    );
    final account =
        await (db.select(db.chartOfAccounts)
              ..where((a) => a.id.equals(id) & a.businessId.equals(businessId)))
            .getSingle();
    final base = await (db.select(
      db.currencies,
    )..where((c) => c.isBaseCurrency.equals(true))).getSingleOrNull();
    if (account.accountTypeId != 1 ||
        (account.currencyId != null && account.currencyId != base?.id)) {
      _fail('حساب المخزون يجب أن يكون من الأصول وبالعملة الأساسية.');
    }
    return id;
  }

  Future<void> cancelDraft(String id) => db.transaction(() async {
    final count = await _count(id);
    if (count.status != StockCountStatus.draft) {
      _fail('يمكن إلغاء المسودة فقط؛ الجرد المعتمد له أثر مخزني ومالي.');
    }
    await (db.update(
      db.stockCounts,
    )..where((c) => c.id.equals(id) & c.businessId.equals(businessId))).write(
      StockCountsCompanion(
        status: const Value(StockCountStatus.cancelled),
        financialStatus: const Value('NotRequired'),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
        version: Value(count.version + 1),
      ),
    );
  });

  Future<String> _auxiliaryAccount(
    String key,
    String name,
    String parentId, {
    bool allowPosting = true,
  }) async {
    final mapping =
        await (db.select(db.accountMappings)..where(
              (m) => m.businessId.equals(businessId) & m.mappingKey.equals(key),
            ))
            .getSingleOrNull();
    if (mapping != null) {
      final account =
          await (db.select(db.chartOfAccounts)..where(
                (a) =>
                    a.businessId.equals(businessId) &
                    a.id.equals(mapping.chartOfAccountId),
              ))
              .getSingleOrNull();
      if (!mapping.isActive ||
          account == null ||
          !account.isActive ||
          account.allowPosting != allowPosting ||
          account.accountTypeId != 1) {
        _fail('حساب الفروقات المعلق أو حساب الموظف غير نشط أو لا يقبل القيود.');
      }
      return account.id;
    }
    final result = await accounts.createAccount(
      CreateAccountCommand(
        accountName: name,
        parentAccountId: parentId,
        allowPosting: allowPosting,
      ),
    );
    final id = result.fold((f) => _fail(f.message), (id) => id);
    await db
        .into(db.accountMappings)
        .insert(
          AccountMappingsCompanion.insert(
            id: _uuid.v4(),
            businessId: businessId,
            mappingKey: key,
            mappingName: name,
            chartOfAccountId: id,
          ),
        );
    return id;
  }

  Future<String> _assetParent() async {
    final root =
        await (db.select(db.chartOfAccounts)
              ..where(
                (a) =>
                    a.businessId.equals(businessId) &
                    a.accountTypeId.equals(1) &
                    a.isActive.equals(true) &
                    a.allowPosting.equals(false) &
                    a.parentAccountId.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (root == null) {
      _fail('أضف حساباً تجميعياً للأصول قبل اعتماد الجرد.');
    }
    return root.id;
  }

  Future<String?> _journal(
    StockCountDocument doc,
    List<JournalEntryLineCommand> lines,
    String suffix,
    String description,
  ) async {
    if (lines.isEmpty) {
      return null;
    }
    final currency = await (db.select(
      db.currencies,
    )..where((c) => c.isBaseCurrency.equals(true))).getSingleOrNull();
    if (currency == null) {
      _fail('حدّد العملة الأساسية قبل اعتماد الجرد.');
    }
    final date = DateTime.now();
    final periods =
        await (db.select(db.fiscalPeriods)..where(
              (p) =>
                  p.businessId.equals(businessId) &
                  p.status.equals('Open') &
                  p.startDate.isSmallerOrEqualValue(date) &
                  p.endDate.isBiggerOrEqualValue(
                    DateTime(date.year, date.month, date.day),
                  ),
            ))
            .get();
    if (periods.isEmpty) {
      _fail(
        'لا توجد فترة مالية مفتوحة لتاريخ اليوم. افتح الفترة المناسبة ثم أعد المحاولة.',
      );
    }
    final period = periods.first;
    final year =
        await (db.select(db.fiscalYears)..where(
              (y) =>
                  y.businessId.equals(businessId) &
                  y.id.equals(period.fiscalYearId) &
                  y.status.equals('Open'),
            ))
            .getSingleOrNull();
    if (year == null) {
      _fail('السنة المالية مغلقة. افتح السنة المناسبة قبل اعتماد القيد.');
    }
    final result = await postJournal(
      PostJournalEntryCommand(
        fiscalYearId: period.fiscalYearId,
        fiscalPeriodId: period.id,
        documentDate: date,
        journalType: 'InventoryAdjustment',
        documentType: 'InventoryAdjustment',
        documentId: doc.count.id,
        documentNumber: '${doc.count.countNumber}-$suffix',
        currencyId: currency.id,
        description: description,
        lines: lines,
      ),
    );
    return result.fold((f) => _fail(f.message), (id) => id);
  }

  Future<void> correct(String id) => db.transaction(() async {
    var doc = await load(id);
    if (doc.count.status != StockCountStatus.draft) {
      _fail('تم تصحيح هذا الجرد بالفعل؛ لا يمكن اعتماده مرة أخرى.');
    }
    await _warehouse(doc.count.warehouseId);
    if (doc.items.isEmpty) {
      _fail('لا يمكن اعتماد جرد فارغ.');
    }
    final candidatesById = {
      for (final c in await candidates(doc.count.warehouseId)) c.unit.id: c,
    };
    final now = DateTime.now(), seen = <String>{};
    for (final item in doc.items) {
      final candidate = candidatesById[item.productUnitId];
      if (candidate == null ||
          candidate.product.id != item.productId ||
          !seen.add(item.productUnitId)) {
        _fail('يوجد منتج غير متاح أو مكرر. أعد فتح المسودة وراجع المنتجات.');
      }
      if ((candidate.quantity - item.expectedQuantity).abs() > 0.0005) {
        _fail(
          'تغيّر رصيد «${candidate.product.productName}» منذ بدء الجرد. افتح المسودة واضغط تحديث رصيد النظام ثم راجع الكمية الفعلية.',
        );
      }
      if (!item.countedQuantity.isFinite ||
          item.countedQuantity < 0 ||
          !candidate.unitCost.isFinite ||
          candidate.unitCost < 0) {
        _fail('راجع الكميات والتكلفة قبل الاعتماد.');
      }
      final diff = PrecisionMath.roundQty(
        item.countedQuantity - candidate.quantity,
      );
      await (db.update(db.stockCountItems)..where(
            (i) => i.id.equals(item.id) & i.businessId.equals(businessId),
          ))
          .write(
            StockCountItemsCompanion(
              differenceQuantity: Value(diff),
              unitCost: Value(candidate.unitCost),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
              version: Value(item.version + 1),
            ),
          );
    }
    doc = await load(id);
    final hasDifferences = doc.items.any((i) => i.differenceQuantity != 0);
    String? journalId;
    if (doc.shortage > 0 || doc.surplus > 0) {
      final inventoryAccount = await _mappedAccount('inventory_asset');
      final clearing = await _auxiliaryAccount(
        'stock_count_clearing',
        'فروقات جرد معلّقة',
        await _assetParent(),
      );
      journalId = await _journal(
        doc,
        [
          if (doc.shortage > 0) ...[
            JournalEntryLineCommand(
              accountId: clearing,
              debit: doc.shortage,
              description: 'عجز جرد قيد المراجعة',
            ),
            JournalEntryLineCommand(
              accountId: inventoryAccount,
              credit: doc.shortage,
            ),
          ],
          if (doc.surplus > 0) ...[
            JournalEntryLineCommand(
              accountId: inventoryAccount,
              debit: doc.surplus,
            ),
            JournalEntryLineCommand(
              accountId: clearing,
              credit: doc.surplus,
              description: 'زيادة جرد قيد المراجعة',
            ),
          ],
        ],
        'COR',
        'تصحيح مخزون ${doc.count.countNumber}؛ تحديد المسؤولية لاحقاً',
      );
    }
    for (final inbound in [true, false]) {
      final lines = doc.items
          .where(
            (i) =>
                inbound ? i.differenceQuantity > 0 : i.differenceQuantity < 0,
          )
          .toList();
      if (lines.isEmpty) {
        continue;
      }
      final txId = _uuid.v4();
      await db
          .into(db.inventoryTransactions)
          .insert(
            InventoryTransactionsCompanion.insert(
              id: txId,
              businessId: businessId,
              branchId: doc.count.branchId,
              warehouseId: doc.count.warehouseId,
              transactionDate: Value(now),
              transactionType: inbound
                  ? InventoryTransactionType.adjustmentIn
                  : InventoryTransactionType.adjustmentOut,
              movementDirection: inbound
                  ? InventoryMovementDirection.inbound
                  : InventoryMovementDirection.outbound,
              referenceType: const Value(InventoryReferenceType.adjustment),
              referenceId: Value(id),
              status: const Value(InventoryTransactionStatus.posted),
              createdBy: context.currentUserId,
              postedBy: Value(context.currentUserId),
              postedAt: Value(now),
            ),
          );
      await db.batch(
        (b) => b.insertAll(db.inventoryTransactionLines, [
          for (final i in lines)
            InventoryTransactionLinesCompanion.insert(
              id: _uuid.v4(),
              businessId: businessId,
              inventoryTransactionId: txId,
              productUnitId: i.productUnitId,
              quantity: i.differenceQuantity.abs(),
              unitCost: Value(i.unitCost),
            ),
        ]),
      );
      for (final i in lines) {
        final existing =
            await (db.select(db.inventories)..where(
                  (s) =>
                      s.businessId.equals(businessId) &
                      s.warehouseId.equals(doc.count.warehouseId) &
                      s.productUnitId.equals(i.productUnitId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          await db
              .into(db.inventories)
              .insert(
                InventoriesCompanion.insert(
                  id: _uuid.v4(),
                  businessId: businessId,
                  warehouseId: doc.count.warehouseId,
                  productUnitId: i.productUnitId,
                  quantity: Value(i.countedQuantity),
                  averageCost: Value(i.unitCost),
                  createdAt: Value(now),
                ),
              );
        } else {
          await (db.update(db.inventories)..where(
                (s) =>
                    s.id.equals(existing.id) & s.businessId.equals(businessId),
              ))
              .write(
                InventoriesCompanion(
                  quantity: Value(i.countedQuantity),
                  averageCost: Value(i.unitCost),
                  deletedAt: const Value(null),
                  updatedAt: Value(now),
                  syncStatus: const Value('pending'),
                  version: Value(existing.version + 1),
                ),
              );
        }
      }
    }
    await (db.update(db.stockCounts)..where(
          (c) =>
              c.id.equals(id) &
              c.businessId.equals(businessId) &
              c.status.equalsValue(StockCountStatus.draft),
        ))
        .write(
          StockCountsCompanion(
            status: const Value(StockCountStatus.posted),
            financialStatus: Value(
              hasDifferences && journalId != null ? 'Pending' : 'NotRequired',
            ),
            financialJournalId: Value(journalId),
            postedBy: Value(context.currentUserId),
            postedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value('pending'),
            version: Value(doc.count.version + 1),
          ),
        );
  });

  Future<void> settle(
    String id, {
    String? lossAccountId,
    String? gainAccountId,
    String? employeeId,
  }) => db.transaction(() async {
    final doc = await load(id);
    if (doc.count.status != StockCountStatus.posted ||
        doc.count.financialStatus != 'Pending' ||
        doc.count.financialJournalId == null) {
      _fail('هذا الجرد ليس بانتظار معالجة الفروقات أو تمت معالجته بالفعل.');
    }
    final inventoryAccount = await _mappedAccount('inventory_asset');
    final originalJournal =
        await (db.select(db.journalEntries)..where(
              (j) =>
                  j.id.equals(doc.count.financialJournalId!) &
                  j.businessId.equals(businessId),
            ))
            .getSingleOrNull();
    if (originalJournal == null ||
        originalJournal.status != 'Posted' ||
        originalJournal.documentId != id) {
      _fail('قيد تصحيح هذا الجرد يحتاج مراجعة في المالية قبل معالجة الفروقات.');
    }
    final clearing = await _auxiliaryAccount(
      'stock_count_clearing',
      'فروقات جرد معلّقة',
      await _assetParent(),
    );
    String? debitAccount = lossAccountId;
    String description = 'معالجة فروقات ${doc.count.countNumber}';
    if (employeeId != null && doc.shortage > 0) {
      final employee =
          await (db.select(db.employees)..where(
                (e) =>
                    e.id.equals(employeeId) &
                    e.businessId.equals(businessId) &
                    e.deletedAt.isNull() &
                    e.status.equals('Active'),
              ))
              .getSingleOrNull();
      if (employee == null) {
        _fail('اختر موظفاً نشطاً من هذه المنشأة.');
      }
      final name = '${employee.firstName} ${employee.lastName}'.trim();
      debitAccount = await _auxiliaryAccount(
        'stock_count_employee_$employeeId',
        'ذمة جرد — $name',
        await _auxiliaryAccount(
          'stock_count_employee_receivables',
          'ذمم الموظفين عن فروقات الجرد',
          await _assetParent(),
          allowPosting: false,
        ),
      );
      description = '$description؛ تحميل العجز على $name';
    }
    Future<void> validateAccount(String? accountId, List<int> types) async {
      if (accountId == null ||
          accountId == clearing ||
          accountId == inventoryAccount) {
        _fail('اختر حساب المعالجة المناسب للفروقات.');
      }
      final account =
          await (db.select(db.chartOfAccounts)..where(
                (a) => a.id.equals(accountId) & a.businessId.equals(businessId),
              ))
              .getSingleOrNull();
      if (account == null ||
          !account.isActive ||
          !account.allowPosting ||
          !types.contains(account.accountTypeId)) {
        _fail('حساب المعالجة غير صالح أو لا يقبل القيود.');
      }
      final currency = await (db.select(
        db.currencies,
      )..where((c) => c.isBaseCurrency.equals(true))).getSingleOrNull();
      if (account.currencyId != null && account.currencyId != currency?.id) {
        _fail('اختر حساب معالجة بالعملة الأساسية.');
      }
    }

    if (doc.shortage > 0) {
      await validateAccount(debitAccount, [1, 5]);
    }
    if (doc.surplus > 0) {
      await validateAccount(gainAccountId, [4]);
    }
    final journal = await _journal(
      doc,
      [
        if (doc.shortage > 0) ...[
          JournalEntryLineCommand(
            accountId: debitAccount!,
            debit: doc.shortage,
          ),
          JournalEntryLineCommand(accountId: clearing, credit: doc.shortage),
        ],
        if (doc.surplus > 0) ...[
          JournalEntryLineCommand(accountId: clearing, debit: doc.surplus),
          JournalEntryLineCommand(
            accountId: gainAccountId!,
            credit: doc.surplus,
          ),
        ],
      ],
      'SET',
      description,
    );
    await (db.update(
      db.stockCounts,
    )..where((c) => c.id.equals(id) & c.businessId.equals(businessId))).write(
      StockCountsCompanion(
        financialStatus: const Value('Settled'),
        settlementJournalId: Value(journal),
        financialSettledAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
        version: Value(doc.count.version + 1),
      ),
    );
  });
}
