# 📦 PHASE 3: دورة المبيعات ونقطة البيع والكاشير الميداني
## (Sales Engine, Real-Time POS, Atomic Checkout, Discounts & Returns)

---

## 1. أهداف المرحلة والمخرجات الفنية (Phase Objectives)
1. بناء جداول فواتير المبيعات ورؤوسها وأسطرها في Drift (`SalesInvoicesTable` و `SalesInvoiceItemsTable`).
2. ربط واجهة الـ POS الحالية ببيانات Drift الحقيقية واستبدال الموك نهائياً.
3. معمارية **المعاملة الذرية الخماسية للبيع (The 5-Step Atomic Checkout Transaction)**:
   * حفظ رأس الفاتورة.
   * حفظ تفاصيل الأسطر.
   * خصم كميات المخزون بوحدة الأساس وحساب تكلفة البضاعة المباعة (COGS).
   * توليد قيد اليومية المزدوج المتزن آلياً في الخلفية (صندوق/عميل + مبيعات + تكلفة + مخزون).
   * تحديث رصيد الصندوق أو دين العميل.
4. توزيع الخصم العام (Global Discount) نسبياً على الأسطر لمنع انحرافات الضرائب والتكلفة.
5. معالجة مرتجع المبيعات (Sales Return) المحاسبي والمخزني بالتكلفة التاريخية.
6. حزمة اختبارات Unit Testing ذرية للتحقق من تكامل البيع.

---

## 2. مخطط جداول Drift للمبيعات (`sales_tables.dart`)

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'financial_tables.dart';
import 'inventory_tables.dart';

// 1. جدول رؤوس فواتير المبيعات المعتمد
@DataClassName('SalesInvoiceData')
class SalesInvoicesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get invoiceNumber => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get invoiceDate => dateTime().withDefault(currentDateAndTime)();
  
  // العميل (nullable للبيع النقدي لعميل عابر)
  TextColumn get customerId => text().nullable().references(PartiesTable, #id)();
  TextColumn get warehouseId => text().references(WarehousesTable, #id)();
  
  TextColumn get currencyId => text().references(CurrenciesTable, #id)();
  RealColumn get exchangeRate => real().withDefault(const Constant(1.0))();

  // المجاميع بعملة الفاتورة
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0.0))();
  RealColumn get taxTotal => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  
  // المدفوع والمتبقي
  RealColumn get paidAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();

  // المجاميع المعادلة بعملة الأساس (Base Currency) للأستاذ العام
  RealColumn get baseGrandTotal => real().withDefault(const Constant(0.0))();
  RealColumn get totalCogs => real().withDefault(const Constant(0.0))(); // إجمالي تكلفة البضاعة المباعة

  // حالة الدفع: 'Paid', 'Partial', 'Unpaid'
  TextColumn get paymentStatus => text().withDefault(const Constant('Paid'))();
  
  // طريقة الدفع الأساسية: 'Cash', 'Credit', 'Split'
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get paymentMethodId => text().nullable().references(PaymentMethodsTable, #id)();

  // نوع الفاتورة: 'Standard' (فاتورة بيع)، 'Return' (مرتجع بيع)
  TextColumn get invoiceType => text().withDefault(const Constant('Standard'))();
  TextColumn get originalInvoiceId => text().nullable()(); // في حالة المرتجع

  // حالة الفاتورة: 'Posted', 'Voided'
  TextColumn get status => text().withDefault(const Constant('Posted'))();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. جدول أسطر وتفاصيل فواتير المبيعات (الذي كان مفقوداً في Drift!)
@DataClassName('SalesInvoiceItemData')
class SalesInvoiceItemsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get invoiceId => text().references(SalesInvoicesTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get lineNumber => integer()();
  
  TextColumn get productId => text().references(ProductsTable, #id)();
  TextColumn get productUnitId => text().references(ProductUnitsTable, #id)();
  
  RealColumn get quantity => real()(); // الكمية بالوحدة المختارة
  RealColumn get conversionFactor => real().withDefault(const Constant(1.0))(); // معامل التحويل لوحدة الأساس
  RealColumn get quantityBase => real()(); // الكمية بوحدة الأساس الصغرى (quantity * conversionFactor)

  RealColumn get unitPrice => real()(); // سعر بيع الوحدة المختارة
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))(); // حصة السطر من الخصم
  RealColumn get lineTotal => real()(); // صافي قيمة السطر بعد الخصم
  
  RealColumn get unitCost => real().withDefault(const Constant(0.0))(); // تكلفة وحدة الأساس وقت البيع
  RealColumn get lineCogs => real().withDefault(const Constant(0.0))(); // إجمالي تكلفة هذا السطر (quantityBase * unitCost)

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 3. محرك إتمام عملية البيع الذرية (Atomic Checkout Execution)

عندما يضغط الكاشير على زر "تأكيد وإصدار الفاتورة"، يتم تنفيذ هذا التدفق الصارم داخل **معاملة واحدة غير قابلة للتجزئة** في Drift:

```dart
class CheckoutCartItem {
  final String productId;
  final String productUnitId;
  final double quantity;
  final double conversionFactor;
  final double unitPrice;
  final double lineDiscount;

  CheckoutCartItem({
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    required this.conversionFactor,
    required this.unitPrice,
    this.lineDiscount = 0.0,
  });
}

class SalesCheckoutService {
  final AppDatabase db;
  final InventoryService inventoryService;
  final SilentAccountingEngine accountingEngine;

  SalesCheckoutService({
    required this.db,
    required this.inventoryService,
    required this.accountingEngine,
  });

  Future<String> executeCheckout({
    required String fiscalYearId,
    required String warehouseId,
    required String currencyId,
    required double exchangeRate,
    required String? customerId,
    required String paymentMethod, // 'Cash', 'Credit', 'Split'
    required String? paymentMethodAccountId, // حساب الصندوق أو البنك
    required double globalDiscount,
    required double paidAmount,
    required List<CheckoutCartItem> cartItems,
  }) async {
    return await db.transaction(() async {
      // 1. حساب مجاميع الفاتورة وتوزيع الخصم العام
      double rawSubtotal = 0.0;
      for (var item in cartItems) {
        rawSubtotal += PrecisionMath.roundMoney(item.quantity * item.unitPrice);
      }

      final totalDiscount = PrecisionMath.roundMoney(
        cartItems.fold(0.0, (sum, i) => sum + i.lineDiscount) + globalDiscount,
      );
      final grandTotal = PrecisionMath.roundMoney(rawSubtotal - totalDiscount);
      final remaining = PrecisionMath.roundMoney((grandTotal - paidAmount).clamp(0.0, double.infinity));
      final baseGrandTotal = PrecisionMath.roundMoney(grandTotal * exchangeRate);

      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // 2. إدراج رأس الفاتورة
      final invoiceId = await db.into(db.salesInvoicesTable).insert(
        SalesInvoicesTableCompanion.insert(
          invoiceNumber: invoiceNumber,
          warehouseId: warehouseId,
          customerId: Value(customerId),
          currencyId: currencyId,
          exchangeRate: Value(exchangeRate),
          subtotal: Value(rawSubtotal),
          discountTotal: Value(totalDiscount),
          grandTotal: Value(grandTotal),
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remaining),
          baseGrandTotal: Value(baseGrandTotal),
          paymentStatus: Value(remaining == 0 ? 'Paid' : (paidAmount > 0 ? 'Partial' : 'Unpaid')),
          paymentMethod: Value(paymentMethod),
        ),
      );

      // 3. معالجة الأسطر وخصم المخزون وحساب التكلفة
      double totalInvoiceCogs = 0.0;
      for (var i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final qtyBase = PrecisionMath.roundMoney(item.quantity * item.conversionFactor, decimals: 3);
        
        // توزيع الخصم العام نسبياً
        final lineGross = item.quantity * item.unitPrice;
        final lineGlobalDiscountShare = rawSubtotal > 0 ? (lineGross / rawSubtotal) * globalDiscount : 0.0;
        final finalLineDiscount = PrecisionMath.roundMoney(item.lineDiscount + lineGlobalDiscountShare);
        final lineNet = PrecisionMath.roundMoney(lineGross - finalLineDiscount);

        // خصم المخزون والحصول على التكلفة
        final lineCogs = await inventoryService.processStockOut(
          warehouseId: warehouseId,
          productId: item.productId,
          quantityInBaseUnit: qtyBase,
          referenceType: 'SalesInvoice',
          referenceId: invoiceId,
        );

        totalInvoiceCogs += lineCogs;
        final unitCost = qtyBase > 0 ? (lineCogs / qtyBase) : 0.0;

        await db.into(db.salesInvoiceItemsTable).insert(
          SalesInvoiceItemsTableCompanion.insert(
            invoiceId: invoiceId,
            lineNumber: i + 1,
            productId: item.productId,
            productUnitId: item.productUnitId,
            quantity: item.quantity,
            conversionFactor: Value(item.conversionFactor),
            quantityBase: qtyBase,
            unitPrice: item.unitPrice,
            discountAmount: Value(finalLineDiscount),
            lineTotal: lineNet,
            unitCost: Value(unitCost),
            lineCogs: Value(lineCogs),
          ),
        );
      }

      // تحديث إجمالي التكلفة في رأس الفاتورة
      await (db.update(db.salesInvoicesTable)..where((inv) => inv.id.equals(invoiceId))).write(
        SalesInvoicesTableCompanion(totalCogs: Value(totalInvoiceCogs)),
      );

      // 4. توليد قيد اليومية المزدوج آلياً (The Silent Journal Entry)
      // استخراج الحسابات النظامية
      final accounts = await db.select(db.chartOfAccountsTable).get();
      final salesRevAcc = accounts.firstWhere((a) => a.systemRole == 'SALES_REVENUE').id;
      final cogsAcc = accounts.firstWhere((a) => a.systemRole == 'COGS').id;
      final inventoryAcc = accounts.firstWhere((a) => a.systemRole == 'INVENTORY_ASSET').id;

      final journalLines = <JournalLineDraft>[];

      // طرف المبيعات (دائن بقيمة المبيعات)
      journalLines.add(JournalLineDraft(
        accountId: salesRevAcc,
        credit: grandTotal,
        description: 'إيراد مبيعات فاتورة $invoiceNumber',
      ));

      // طرف المدفوع نقداً (مدين للصندوق)
      if (paidAmount > 0) {
        journalLines.add(JournalLineDraft(
          accountId: paymentMethodAccountId!,
          debit: paidAmount,
          description: 'تحصيل نقدي فاتورة $invoiceNumber',
        ));
      }

      // طرف الآجل (مدين لحساب العميل)
      if (remaining > 0) {
        if (customerId == null) {
          throw Exception('لا يمكن البيع بالآجل لعميل نقدي غير مسجل!');
        }
        final customer = await (db.select(db.partiesTable)..where((p) => p.id.equals(customerId))).getSingle();
        journalLines.add(JournalLineDraft(
          accountId: customer.accountId,
          debit: remaining,
          description: 'متبقي آجل فاتورة $invoiceNumber',
        ));
      }

      // قيد تكلفة البضاعة المباعة والمخزون (COGS) إذا كان هناك تكلفة
      if (totalInvoiceCogs > 0) {
        // يتم تحويل التكلفة لقيمة بعملة الفاتورة لضمان توازن القيد
        final cogsInInvoiceCurrency = PrecisionMath.roundMoney(totalInvoiceCogs / exchangeRate);
        journalLines.add(JournalLineDraft(
          accountId: cogsAcc,
          debit: cogsInInvoiceCurrency,
          description: 'تكلفة بضاعة مباعة فاتورة $invoiceNumber',
        ));
        journalLines.add(JournalLineDraft(
          accountId: inventoryAcc,
          credit: cogsInInvoiceCurrency,
          description: 'خصم مخزون فاتورة $invoiceNumber',
        ));
      }

      // ترحيل القيد عبر المحرك الصامت
      await accountingEngine.createBalancedEntry(
        fiscalYearId: fiscalYearId,
        referenceType: 'SalesInvoice',
        referenceId: invoiceId,
        currencyId: currencyId,
        exchangeRate: exchangeRate,
        description: 'قيد مبيعات الفاتورة $invoiceNumber',
        lines: journalLines,
      );

      return invoiceId;
    });
  }
}
```

---

## 4. معالجة مرتجع المبيعات (Sales Return Policy)

عند إرجاع فاتورة بيع (كلية أو جزئية):
1. تُنشأ فاتورة برقم جديد وبنوع `invoiceType = 'Return'`.
2. تُعاد الكميات إلى المخزن وتزيد الكمية المتاحة.
3. التكلفة التي تعود بها البضاعة للمخزن هي **التكلفة الأصلية المسجلة في سطر الفاتورة المباعة حصراً** (`unitCost`).
4. يتولد قيد محاسبي عكسي آلي:
   * مدين: حـ/ مردودات المبيعات أو المبيعات.
   * دائن: حـ/ الصندوق (إذا أُعيد النقد) أو حـ/ العميل (إذا خُصم من دينه).
   * مدين: حـ/ المخزون.
   * دائن: حـ/ تكلفة البضاعة المباعة (COGS).

---

## 5. معايير القبول والرفض للمرحلة 3 (Acceptance & Rejection Criteria)

### معايير القبول (What MUST Pass):
* [ ] إصدار فاتورة نقدية يخصم المخزن فوراً، ويزيد رصيد الصندوق، وينشئ قيد يومية متزن بأطرافه الأربعة (صندوق + مبيعات + تكلفة + مخزون).
* [ ] إصدار فاتورة جزئية الدفع (مثلاً إجمالي 10,000، دفع 4,000 وبقي 6,000) يوجه الـ 4,000 للصندوق والـ 6,000 لحساب العميل تلقائياً.
* [ ] منع الدفع بالآجل منعاً باتاً إذا لم يتم تحديد عميل مسجل.
* [ ] إذا انقطع الاتصال أو أُغلق التطبيق في منتصف عملية الدفع، تلغى المعاملة كاملة دون ترك أي أثر جزئي مكسور (`All-or-Nothing Atomicity`).

### معايير الرفض والممنوعات (Prohibited Behaviors):
* ❌ **ممنوع منعاً باتاً:** السماح بتعديل بيانات الفاتورة أو أصنافها بعد طباعتها وإصدارها. (إذا أخطأ الكاشير، يُصدر مرتجعاً أو يلغي الفاتورة).
* ❌ **ممنوع منعاً باتاً:** بيع بالآجل لعميل تجاوز حده الائتماني (`creditLimit`) إلا بموافقة المدير.
* ❌ **ممنوع منعاً باتاً:** إدخال خصم يتجاوز إجمالي قيمة الفاتورة.

---

## 6. حزمة اختبارات الـ Unit Testing للمرحلة 3 (Runnable Dart Test Suite)

يتم وضع هذا الكود في `test/modules/sales/sales_checkout_atomic_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/accounting/application/silent_accounting_engine.dart';
import 'package:smart_merchant_erp/modules/inventory/application/inventory_service.dart';
import 'package:smart_merchant_erp/modules/sales/application/sales_checkout_service.dart';

void main() {
  late AppDatabase db;
  late InventoryService inventoryService;
  late SilentAccountingEngine accountingEngine;
  late SalesCheckoutService checkoutService;

  late String fiscalYearId;
  late String yerCurrencyId;
  late String warehouseId;
  late String cashAccountId;
  late String cashPaymentMethodId;
  late String productId;
  late String productUnitId;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    inventoryService = InventoryService(db);
    accountingEngine = SilentAccountingEngine(db);
    checkoutService = SalesCheckoutService(
      db: db,
      inventoryService: inventoryService,
      accountingEngine: accountingEngine,
    );

    // تجهيز البيانات الأساسية
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
      WarehousesTableCompanion.insert(name: 'المحل الرئيسي', code: 'MAIN'),
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
        accountCode: '411',
        accountName: 'المبيعات',
        accountType: 'Revenue',
        normalBalance: 'Credit',
        systemRole: const Value('SALES_REVENUE'),
      ),
    );

    await db.into(db.chartOfAccountsTable).insert(
      ChartOfAccountsTableCompanion.insert(
        accountCode: '511',
        accountName: 'تكلفة المبيعات',
        accountType: 'Expense',
        normalBalance: 'Debit',
        systemRole: const Value('COGS'),
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

    cashPaymentMethodId = await db.into(db.paymentMethodsTable).insert(
      PaymentMethodsTableCompanion.insert(
        name: 'كاش',
        type: 'Cash',
        accountId: cashAccountId,
        isDefault: const Value(true),
      ),
    );

    final unitId = await db.into(db.unitsTable).insert(
      UnitsTableCompanion.insert(nameAr: 'حبة', code: 'PCS'),
    );

    productId = await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(name: 'بيبسي علبة', baseUnitId: unitId),
    );

    productUnitId = await db.into(db.productUnitsTable).insert(
      ProductUnitsTableCompanion.insert(
        productId: productId,
        unitId: unitId,
        conversionFactor: const Value(1.0),
        salePrice: const Value(300.0),
      ),
    );

    // توريد 50 حبة بيبسي بتكلفة 200 ريال للحبة في المخزن
    await inventoryService.processStockIn(
      warehouseId: warehouseId,
      productId: productId,
      quantityInBaseUnit: 50.0,
      purchasePriceInBaseUnit: 200.0,
      referenceType: 'Initial',
      referenceId: 'INIT-01',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('اختبارات عملية البيع الذرية (Atomic Checkout)', () {
    test('عملية بيع نقدي ناجحة يجب أن تخصم المخزن وتنشئ الفاتورة وقيد اليومية المتزن', () async {
      final invoiceId = await checkoutService.executeCheckout(
        fiscalYearId: fiscalYearId,
        warehouseId: warehouseId,
        currencyId: yerCurrencyId,
        exchangeRate: 1.0,
        customerId: null,
        paymentMethod: 'Cash',
        paymentMethodAccountId: cashAccountId,
        globalDiscount: 0.0,
        paidAmount: 600.0,
        cartItems: [
          CheckoutCartItem(
            productId: productId,
            productUnitId: productUnitId,
            quantity: 2.0, // 2 حبات بـ 300 = 600 ريال
            conversionFactor: 1.0,
            unitPrice: 300.0,
          )
        ],
      );

      expect(invoiceId, isNotEmpty);

      // 1. التحقق من رأس الفاتورة
      final invoice = await (db.select(db.salesInvoicesTable)..where((i) => i.id.equals(invoiceId))).getSingle();
      expect(invoice.grandTotal, 600.0);
      expect(invoice.totalCogs, 400.0); // 2 حبات * 200 تكلفة = 400
      expect(invoice.paymentStatus, 'Paid');

      // 2. التحقق من المخزون (كان 50، تم بيع 2، المتبقي يجب أن يكون 48)
      final inv = await (db.select(db.inventoriesTable)
            ..where((i) => i.warehouseId.equals(warehouseId) & i.productId.equals(productId)))
          .getSingle();
      expect(inv.quantityOnHand, 48.0);

      // 3. التحقق من قيد اليومية المرتبط بالفاتورة
      final journalEntry = await (db.select(db.journalEntriesTable)
            ..where((j) => j.referenceId.equals(invoiceId)))
          .getSingle();
      expect(journalEntry.referenceType, 'SalesInvoice');

      final lines = await (db.select(db.journalEntryLinesTable)
            ..where((l) => l.journalEntryId.equals(journalEntry.id)))
          .get();

      // أطراف القيد: صـندوق مدين 600، مبيعات دائن 600، تكلفة مدين 400، مخزون دائن 400
      final totalBaseDebit = lines.fold(0.0, (sum, l) => sum + l.baseDebit);
      final totalBaseCredit = lines.fold(0.0, (sum, l) => sum + l.baseCredit);

      expect(totalBaseDebit, 1000.0);
      expect(totalBaseCredit, 1000.0);
      expect(totalBaseDebit, totalBaseCredit); // اتزان تام
    });
  });
}
```
