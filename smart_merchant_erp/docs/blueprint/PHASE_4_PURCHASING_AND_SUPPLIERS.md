# 📦 PHASE 4: دورة المبيعات والمشتريات والموردين وإدارة الديون
## (Purchasing Engine, Moving Cost Realignment, Supplier Ledgers & Payables)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء جداول المشتريات وأسطرها في Drift (`PurchaseInvoicesTable` و `PurchaseInvoiceItemsTable`).
2. ربط دورة الشراء بالمخزون: زيادة الكميات فوراً، وتحديث **متوسط التكلفة المرجح المتحرك**.
3. معالجة الشراء النقدي والشراء الآجل على حساب المورد مع ضبط ديون الموردين.
4. توزيع المصاريف الإضافية للشراء (النقل والشحن) على تكلفة الأصناف بطريقة مبسطة وذكية.
5. معالجة مرتجع المشتريات (Purchase Return) وأثره على المخزون ورصيد المورد.
6. حزمة اختبارات Unit Testing للتحقق من تحديث التكلفة ودقة قيود المشتريات.

---

## 2. مخطط جداول Drift للمشتريات (`purchasing_tables.dart`)

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'financial_tables.dart';
import 'inventory_tables.dart';

// 1. جدول رؤوس فواتير المشتريات
@DataClassName('PurchaseInvoiceData')
class PurchaseInvoicesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 50).unique()();
  TextColumn get supplierInvoiceNumber => text().nullable().withLength(max: 100)(); // رقم فاتورة المورد الورقية
  DateTimeColumn get invoiceDate => dateTime().withDefault(currentDateAndTime)();
  
  TextColumn get supplierId => text().references(PartiesTable, #id)();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  // المجاميع
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0.0))();
  RealColumn get additionalExpenses => real().withDefault(const Constant(0.0))(); // مصاريف نقل وشحن إضافية
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();
  RealColumn get baseGrandTotal => real().withDefault(const Constant(0.0))();

  // حالة الدفع: 'Paid', 'Partial', 'Unpaid'
  TextColumn get paymentStatus => text().withDefault(const Constant('Unpaid'))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Credit'))(); // 'Cash', 'Credit', 'Split'
  TextColumn get paymentMethodId => text().nullable().references(PaymentMethodsTable, #id)();

  // نوع الفاتورة: 'Standard', 'Return'
  TextColumn get invoiceType => text().withDefault(const Constant('Standard'))();
  TextColumn get originalInvoiceId => text().nullable()();

  TextColumn get status => text().withDefault(const Constant('Posted'))();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. جدول تفاصيل وأسطر فواتير المشتريات
@DataClassName('PurchaseInvoiceItemData')
class PurchaseInvoiceItemsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get invoiceId => text().references(PurchaseInvoicesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  
  TextColumn get productId => text().references(ProductsTable, #id)();
  TextColumn get productUnitId => text().references(ProductUnitsTable, #id)();
  
  RealColumn get quantity => real()();
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))();
  RealColumn get quantityBase => real()(); // الكمية بوحدة الأساس
  
  RealColumn get unitPurchasePrice => real()(); // سعر الشراء للوحدة المختارة
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()(); // صافي سطر الشراء
  
  // التكلفة الفعلية المحسوبة لوحدة الأساس شاملة حصة السطر من مصاريف النقل
  RealColumn get effectiveBaseUnitCost => real()(); 

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. محرك تنفيذ فاتورة المشتريات (Purchase Invoice Execution Engine)

```dart
class PurchaseItemDraft {
  final String productId;
  final String productUnitId;
  final double quantity;
  final double conversionFactor;
  final double unitPurchasePrice;
  final double lineDiscount;

  PurchaseItemDraft({
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    required this.conversionFactor,
    required this.unitPurchasePrice,
    this.lineDiscount = 0.0,
  });
}

class PurchasingService {
  final AppDatabase db;
  final InventoryService inventoryService;
  final SilentAccountingEngine accountingEngine;

  PurchasingService({
    required this.db,
    required this.inventoryService,
    required this.accountingEngine,
  });

  Future<String> executePurchaseInvoice({
    required String fiscalYearId,
    required String warehouseId,
    required String supplierId,
    required String currencyId,
    required double exchangeRate,
    required String? supplierInvoiceNumber,
    required String paymentMethod, // 'Cash', 'Credit', 'Split'
    required String? paymentMethodAccountId,
    required double globalDiscount,
    required double additionalExpenses, // مصاريف نقل تُضاف للتكلفة
    required double paidAmount,
    required List<PurchaseItemDraft> items,
  }) async {
    return await db.transaction(() async {
      // 1. حساب مجاميع المشتريات
      double rawSubtotal = 0.0;
      for (var item in items) {
        rawSubtotal += PrecisionMath.roundMoney(item.quantity * item.unitPurchasePrice);
      }

      final totalDiscount = PrecisionMath.roundMoney(
        items.fold(0.0, (sum, i) => sum + i.lineDiscount) + globalDiscount,
      );

      final netGoodsTotal = PrecisionMath.roundMoney(rawSubtotal - totalDiscount);
      // إجمالي الفاتورة المطلوب سداده = صافي البضاعة + مصاريف الشحن إذا كانت على المورد
      final grandTotal = PrecisionMath.roundMoney(netGoodsTotal + additionalExpenses);
      final remaining = PrecisionMath.roundMoney((grandTotal - paidAmount).clamp(0.0, double.infinity));
      final baseGrandTotal = PrecisionMath.roundMoney(grandTotal * exchangeRate);

      final invoiceNumber = 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      // 2. إدراج رأس فاتورة الشراء
      final invoiceId = await db.into(db.purchaseInvoicesTable).insert(
        PurchaseInvoicesTableCompanion.insert(
          invoiceNumber: invoiceNumber,
          supplierInvoiceNumber: Value(supplierInvoiceNumber),
          supplierId: supplierId,
          warehouseId: warehouseId,
          currencyId: currencyId,
          exchangeRate: Value(exchangeRate),
          subtotal: Value(rawSubtotal),
          discountTotal: Value(totalDiscount),
          additionalExpenses: Value(additionalExpenses),
          grandTotal: Value(grandTotal),
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remaining),
          baseGrandTotal: Value(baseGrandTotal),
          paymentStatus: Value(remaining == 0 ? 'Paid' : (paidAmount > 0 ? 'Partial' : 'Unpaid')),
          paymentMethod: Value(paymentMethod),
        ),
      );

      // 3. معالجة الأسطر وتوريد المخزون وتحديث متوسط التكلفة
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final qtyBase = PrecisionMath.roundMoney(item.quantity * item.conversionFactor, decimals: 3);
        
        final lineGross = item.quantity * item.unitPurchasePrice;
        final lineGlobalDiscountShare = rawSubtotal > 0 ? (lineGross / rawSubtotal) * globalDiscount : 0.0;
        final lineExpensesShare = rawSubtotal > 0 ? (lineGross / rawSubtotal) * additionalExpenses : 0.0;

        final finalLineDiscount = PrecisionMath.roundMoney(item.lineDiscount + lineGlobalDiscountShare);
        final lineNet = PrecisionMath.roundMoney(lineGross - finalLineDiscount);
        
        // التكلفة الفعلية المحملة للسطر (صافي الشراء + نصيب السطر من مصاريف النقل)
        final effectiveLineTotal = lineNet + lineExpensesShare;
        final effectiveBaseUnitCost = qtyBase > 0 
            ? PrecisionMath.roundMoney((effectiveLineTotal / qtyBase) * exchangeRate, decimals: 2) 
            : 0.0;

        // توريد للمخزن وتحديث متوسط التكلفة المرجح المتحرك
        await inventoryService.processStockIn(
          warehouseId: warehouseId,
          productId: item.productId,
          quantityInBaseUnit: qtyBase,
          purchasePriceInBaseUnit: effectiveBaseUnitCost,
          referenceType: 'PurchaseInvoice',
          referenceId: invoiceId,
        );

        await db.into(db.purchaseInvoiceItemsTable).insert(
          PurchaseInvoiceItemsTableCompanion.insert(
            invoiceId: invoiceId,
            lineNumber: i + 1,
            productId: item.productId,
            productUnitId: item.productUnitId,
            quantity: item.quantity,
            conversionFactor: Value(item.conversionFactor),
            quantityBase: qtyBase,
            unitPurchasePrice: item.unitPurchasePrice,
            discountAmount: Value(finalLineDiscount),
            lineTotal: lineNet,
            effectiveBaseUnitCost: effectiveBaseUnitCost,
          ),
        );
      }

      // 4. توليد قيد اليومية الآلي (The Silent Journal Entry)
      final accounts = await db.select(db.chartOfAccountsTable).get();
      final inventoryAcc = accounts.firstWhere((a) => a.systemRole == 'INVENTORY_ASSET').id;
      final supplier = await (db.select(db.partiesTable)..where((p) => p.id.equals(supplierId))).getSingle();

      final journalLines = <JournalLineDraft>[];

      // الطرف المدين: زيادة المخزون بكامل القيمة
      journalLines.add(JournalLineDraft(
        accountId: inventoryAcc,
        debit: grandTotal,
        description: 'إثبات مشتريات بضاعة فاتورة $invoiceNumber',
      ));

      // الطرف الدائن: الصندوق إذا سدد نقداً
      if (paidAmount > 0) {
        journalLines.add(JournalLineDraft(
          accountId: paymentMethodAccountId!,
          credit: paidAmount,
          description: 'سداد نقدي مشتريات فاتورة $invoiceNumber',
        ));
      }

      // الطرف الدائن: حساب المورد بالدين المتبقي
      if (remaining > 0) {
        journalLines.add(JournalLineDraft(
          accountId: supplier.accountId,
          credit: remaining,
          description: 'متبقي آجل للمورد فاتورة $invoiceNumber',
        ));
      }

      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'PurchaseInvoice',
        referenceId: invoiceId,
        currencyId: currencyId,
        exchangeRate: exchangeRate,
        description: 'قيد مشتريات الفاتورة $invoiceNumber',
        lines: journalLines,
      );

      return invoiceId;
    });
  }
}
```

---

## 4. معايير القبول والرفض للمرحلة 4 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] تسجيل فاتورة مشتريات يزيد كمية المخزون في المستودع المحدد فوراً.
* [ ] إعادة احتساب متوسط التكلفة بدقة تامة: إذا كان في المخزن 10 حبات بتكلفة 100، واشترينا 10 حبات بـ 200، يصبح متوسط التكلفة 150 ريال فوراً في جدول `inventories`.
* [ ] توزيع مصاريف النقل الإضافية يزيد من تكلفة الأصناف المخزنية ولا يضيع في الهواء.
* [ ] القيد المحاسبي يرفع أصل المخزون (مدين) ويسجل التزام المورد أو خصم الصندوق (دائن) بتطابق كامل.

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** إنشاء فاتورة مشتريات بدون تحديد مورد مسجل في النظام.
* ❌ **ممنوع منعاً باتاً:** تعديل فاتورة الشراء بعد ترحيلها وتوزيع بضاعتها للبيع. (يتم التعديل حصراً عبر إشعار خصم/إضافة أو مرتجع مشتريات).
* ❌ **ممنوع منعاً باتاً:** إدخال كمية شراء سالبة أو صفرية في أسطر الفاتورة.

---

## 5. حزمة اختبارات الـ Unit Testing للمرحلة 4 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/modules/purchasing/purchasing_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/modules/inventory/application/inventory_service.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/purchasing_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService inventoryService;
  late SilentAccountingEngine accountingEngine;
  late PurchasingService purchasingService;

  late String fiscalYearId;
  late String yerCurrencyId;
  late String warehouseId;
  late String cashAccountId;
  late String supplierPartyId;
  late String supplierAccountId;
  late String productId;
  late String productUnitId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    inventoryService = InventoryService(db);
    accountingEngine = SilentAccountingEngine(db);
    purchasingService = PurchasingService(
      db: db,
      inventoryService: inventoryService,
      accountingEngine: accountingEngine,
    );

    yerCurrencyId = await db.into(db.currenciesTable).insert(
      CurrenciesTableCompanion.insert(
        code: 'YER',
        nameAr: 'ريال يمني',
        symbol: 'ر.ي',
        isBaseCurrency: const Value(true),
      ),
    );

    fiscalYearId = await db.into(db.fiscalYearsTable).insert(
      FiscalYearsTableCompanion.insert(
        yearName: '2026',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );

    warehouseId = await db.into(db.warehousesTable).insert(
      WarehousesTableCompanion.insert(name: 'مخزن الوارد', code: 'WH-IN'),
    );

    // زراعة الحسابات النظامية
    cashAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '111',
        accountName: 'الصندوق',
        accountType: 'Asset',
        normalBalance: 'Debit',
        systemRole: const Value('CASH_DRAWER_DEFAULT'),
      ),
    );

    await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '114',
        accountName: 'المخزون',
        accountType: 'Asset',
        normalBalance: 'Debit',
        systemRole: const Value('INVENTORY_ASSET'),
      ),
    );

    // إنشاء حساب ومورد تجريبي
    supplierAccountId = await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '2111',
        accountName: 'شركة الأمل للتجارة',
        accountType: 'Liability',
        normalBalance: 'Credit',
      ),
    );

    supplierPartyId = await db.into(db.partiesTable).insert(
      PartiesTableCompanion.insert(
        name: 'شركة الأمل للتجارة',
        partyType: 'Supplier',
        accountId: supplierAccountId,
      ),
    );

    final unitId = await db.into(db.unitsTable).insert(
      UnitsTableCompanion.insert(nameAr: 'حبة', code: 'PCS'),
    );

    productId = await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(name: 'سكر برازيلي 10 كجم', baseUnitId: unitId),
    );

    productUnitId = await db.into(db.productUnitsTable).insert(
      ProductUnitsTableCompanion.insert(
        productId: productId,
        unitId: unitId,
        conversionFactor: const Value(1.0),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات دورة المشتريات والقيود المحاسبية', () {
    test('شراء آجل بالكامل يرفع المخزون ويسجل التزام المورد وقيد متزن', () async {
      final invoiceId = await purchasingService.executePurchaseInvoice(
        fiscalYearId: fiscalYearId,
        warehouseId: warehouseId,
        supplierId: supplierPartyId,
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        supplierInvoiceNumber: 'SUP-9988',
        paymentMethod: 'Credit',
        paymentMethodAccountId: null,
        globalDiscount: 0.0,
        additionalExpenses: 0.0,
        paidAmount: 0.0,
        items: [
          PurchaseItemDraft(
            productId: productId,
            productUnitId: productUnitId,
            quantity: 100.0,
            conversionFactor: 1.0,
            unitPurchasePrice: 5000.0, // 100 * 5000 = 500,000 ريال
          ),
        ],
      );

      expect(invoiceId, isNotEmpty);

      // 1. التحقق من رأس الفاتورة
      final invoice = await (db.select(db.purchaseInvoicesTable)..where((i) => i.id.equals(invoiceId))).getSingle();
      expect(invoice.grandTotal, 500000.0);
      expect(invoice.remainingAmount, 500000.0);
      expect(invoice.paymentStatus, 'Unpaid');

      // 2. التحقق من المخزون وتكلفة الصنف
      final inv = await (db.select(db.inventoriesTable)
            ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
          .getSingle();
      expect(inv.quantityOnHand, 100.0);
      expect(inv.averageCost, 5000.0);

      // 3. التحقق من القيد المحاسبي
      final entry = await (db.select(db.journalEntriesTable)
            ..where((j) => j.referenceId.equals(invoiceId)))
          .getSingle();
      
      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(entry.id)))
          .get();

      // مدين مخزون 500,000 ودائن مورد 500,000
      expect(lines.first.baseDebit, 500000.0);
      expect(lines.last.baseCredit, 500000.0);
    });
  });
}
```
