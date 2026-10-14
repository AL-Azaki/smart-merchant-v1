# مواصفات الاختبارات المحاسبية والقواعد الصارمة (Testing & Invariants)
## Phase 5 Specification: Accounting Invariants & Comprehensive Unit Testing Suite

**الهدف:** بناء شبكة أمان واختبارات آلية صارمة تضمن عدم انهيار دفاتر الحسابات أو حدوث أخطاء حسابية صامتة عند تشغيل التطبيق أو تعديله بواسطة الذكاء الاصطناعي والمطورين.

---

## 1. القواعد المحاسبية الصارمة التي لا تقبل المساومة (The 6 Invariants)

هذه القواعد يجب أن تظل صحيحة بنسبة 100% في جميع الأوقات وبعد أي عملية تجارية:

```
┌────────────────────────────────────────────────────────────────────────┐
│               القواعد المحاسبية الذهبية (The 6 Invariants)              │
├────────────────────────────────────────────────────────────────────────┤
│ 1. قاعدة التوازن المزدوج المطلق:                                        │
│    لكل قيد يومي: SUM(base_amount مدين) == SUM(base_amount دائن)         │
├────────────────────────────────────────────────────────────────────────┤
│ 2. قانون حفظ المخزون (Inventory Conservation):                         │
│    الرصيد الفعلي = رصيد أول المدة + المشتريات - المبيعات ± التسويات     │
├────────────────────────────────────────────────────────────────────────┤
│ 3. تطابق قيمة المخزون مع الأستاذ العام (Valuation Consistency):         │
│    رصيد حساب المخزون (11301) == SUM(كمية كل منتج × متوسط تكلفته)       │
├────────────────────────────────────────────────────────────────────────┤
│ 4. نزاهة أرصدة العملاء والموردين (Party Balance Integrity):           │
│    رصيد العميل = الفواتير الآجلة - سندات القبض + مرتجعات المبيعات       │
├────────────────────────────────────────────────────────────────────────┤
│ 5. تطابق رصيد الصندوق الحقيقي (Cash Conservation):                     │
│    رصيد الصندوق = رصيد البداية + المقبوضات النقدية - المدفوعات النقدية  │
├────────────────────────────────────────────────────────────────────────┤
│ 6. النزاهة الذرية عند الفشل (Atomic Rollback):                         │
│    إذا فشل القيد المحاسبي، يتراجع خصم المخزون وحفظ الفاتورة فوراً      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. هيكل مجلدات الاختبارات (Test Directory Structure)

```
test/
├── unit/
│   ├── accounting/
│   │   ├── wac_currency_calculation_test.dart       # اختبارات حساب متوسط التكلفة والعملات
│   │   ├── precision_math_test.dart                 # اختبارات تقريب الكسور والفوارق
│   │   └── chart_of_accounts_tree_test.dart         # اختبارات شجرة الحسابات والتسلسل
│   ├── inventory/
│   │   └── unit_conversion_stock_test.dart          # اختبارات تفكيك الكراتين والحبات
│   └── treasury/
│       └── voucher_balance_allocation_test.dart     # اختبارات تسديد فواتير العملاء FIFO
├── integration/
│   └── scenarios/
│       ├── full_purchase_to_sale_lifecycle_test.dart# دورة حياة الشراء والبيع الكاملة
│       ├── multi_currency_trading_test.dart         # دورة الشراء بدولار والبيع بمحلي
│       ├── sales_return_and_cogs_reversal_test.dart # المرتجعات وعكس تكلفة المبيعات
│       └── year_end_close_and_retained_equity_test.dart # الإقفال السنوي وترحيل الأرباح
└── invariants/
    └── ledger_invariants_validator_test.dart        # الفاحص الشامل لتوازن جميع القيود
```

---

## 3. نماذج الاختبارات العملية الجاهزة للتنفيذ (Ready-to-Run Test Specs)

### 3.1 اختبار متوسط التكلفة والشراء بعملة أجنبية (Multi-Currency WAC Test)
```dart
test('يجب تحديث متوسط التكلفة بالعملة الأساسية بدقة عند الشراء بعملة أجنبية', () async {
  // الحالة:
  // 1. لدينا 10 حبات في المخزن بتكلفة سابقة 1,000 ريال يمني للحبة (إجمالي = 10,000 ريال).
  // 2. اشترينا 10 حبات جديدة بسعر 2$ دولار أمريكي، وسعر الصرف وقت الشراء هو 530 ريال/دولار.
  // التكلفة الجديدة بالريال = 2 * 530 = 1,060 ريال يمني.
  // المتوقع: متوسط التكلفة الجديد = (10,000 + 10,600) / 20 = 20,600 / 20 = 1,030 ريال يمني بالضبط.

  final result = await recordPurchaseUseCase(RecordPurchaseCommand(
    supplierId: supplierId,
    currencyId: usdCurrencyId,
    exchangeRate: 530.0,
    items: [
      PurchaseItemCommand(
        productUnitId: pieceUnitId,
        warehouseId: mainWarehouseId,
        quantity: 10.0,
        unitCost: 2.0, // بالدولار
      ),
    ],
  ));

  expect(result.isRight(), true);

  final updatedInventory = await inventoryRepo.getInventory(mainWarehouseId, pieceUnitId);
  expect(updatedInventory.quantity, 20.0);
  expect(updatedInventory.averageCost, 1030.0); // فحص الدقة الصارمة
});
```

### 3.2 اختبار تحويل الوحدات: شراء بالكرتون والبيع بالحبة (Unit Conversion Test)
```dart
test('يجب أن تزيد كمية المخزن بالوحدة الأساسية عند الشراء بوحدة العبوة وتخصم عند البيع بالحبة', () async {
  // كرتون يحتوي على 24 حبة (معامل التحويل = 24.0)
  // رصيد البداية = 0

  // 1. شراء 2 كرتون بسعر 2,400 ريال للكرتون
  await recordPurchaseUseCase(RecordPurchaseCommand(
    supplierId: supplierId,
    currencyId: baseCurrencyId,
    items: [
      PurchaseItemCommand(
        productUnitId: cartonUnitId, // كرتون
        warehouseId: mainWarehouseId,
        quantity: 2.0,
        unitCost: 2400.0,
      ),
    ],
  ));

  // الرصيد يجب أن يكون 48 حبة، وتكلفة الحبة الواحدة = 2400 / 24 = 100 ريال
  var inv = await inventoryRepo.getInventory(mainWarehouseId, basePieceUnitId);
  expect(inv.quantity, 48.0);
  expect(inv.averageCost, 100.0);

  // 2. بيع 5 حبات في الكاشير
  await completeSaleUseCase(CompleteSaleCommand(
    warehouseId: mainWarehouseId,
    currencyId: baseCurrencyId,
    items: [
      SaleItemCommand(productUnitId: basePieceUnitId, quantity: 5.0, unitPrice: 150.0),
    ],
  ));

  inv = await inventoryRepo.getInventory(mainWarehouseId, basePieceUnitId);
  expect(inv.quantity, 43.0); // يتبقى 43 حبة دون أي خطأ نقص رصيد
});
```

### 3.3 اختبار توازن القيد اليومي ومنع الكسور (Balance Invariant Test)
```dart
test('كل فاتورة بيع يجب أن تولد قيوداً يومية متزنة تماماً (مدين == دائن)', () async {
  final saleResult = await completeSaleUseCase(CompleteSaleCommand(
    customerId: customerId,
    currencyId: baseCurrencyId,
    isCreditSale: true,
    items: [
      SaleItemCommand(productUnitId: pieceId, quantity: 3.0, unitPrice: 133.33),
    ],
  ));

  final invoiceId = saleResult.getOrElse(() => throw Exception());
  final journalEntry = await accountingRepo.getJournalEntryByReference(invoiceId);

  double totalDebit = 0.0;
  double totalCredit = 0.0;

  for (final line in journalEntry.lines) {
    if (line.type == 'Debit') totalDebit += line.baseAmount;
    if (line.type == 'Credit') totalCredit += line.baseAmount;
  }

  expect(PrecisionMath.areBalanced(totalDebit, totalCredit), true,
      reason: 'القيد غير متزن! إجمالي المدين: $totalDebit, إجمالي الدائن: $totalCredit');
});
```

### 3.4 اختبار التراجع الذري عند الفشل (Atomic Rollback Test)
```dart
test('في حال فشل تسجيل القيد اليومي، يجب التراجع فوراً عن خصم المخزون', () async {
  final initialQty = (await inventoryRepo.getInventory(warehouseId, productId)).quantity;

  // إرسال أمر بيع مع تعمد تمرير mapping حساب خاطئ لإفشال القيد
  final failResult = await completeSaleUseCaseWithFaultInjection(CompleteSaleCommand(...));

  expect(failResult.isLeft(), true);

  // التأكد من أن رصيد المخزون لم يتغير نهائياً وظل كما كان قبل العملية
  final currentQty = (await inventoryRepo.getInventory(warehouseId, productId)).quantity;
  expect(currentQty, initialQty);
});
```

---

## 4. الفاحص الآلي الشامل لدفتر الأستاذ (The Global Ledger Invariant Checker)

يتم تشغيل هذا الاختبار بعد نهاية كل دورة تطوير للتأكد من سلامة قاعدة البيانات ككل:

```dart
test('الفحص الذهبي الشامل: جميع قيود النظام متزنة ورصيد الميزانية صفر', () async {
  final allLines = await appDatabase.select(appDatabase.journalEntryLines).get();

  double grandDebit = 0.0;
  double grandCredit = 0.0;

  for (final line in allLines) {
    if (line.type == 'Debit') grandDebit += line.baseAmount;
    if (line.type == 'Credit') grandCredit += line.baseAmount;
  }

  grandDebit = PrecisionMath.roundMoney(grandDebit);
  grandCredit = PrecisionMath.roundMoney(grandCredit);

  expect(grandDebit, grandCredit,
      reason: 'تحذير كارثي: دفتر الأستاذ العام غير متزن! الفرق = ${grandDebit - grandCredit}');
});
```

---

## 5. تعليمات التنفيذ للمطور والذكاء الاصطناعي

1. استخدم دائماً قاعدة بيانات في الذاكرة (`NativeDatabase.memory()`) لتشغيل الاختبارات بسرعة فائقة ودون التأثير على ملف قاعدة البيانات الحقيقي.
2. لا تقم بعمل `git commit` لأي مرحلة قبل التأكد من تشغيل:
   ```bash
   flutter test test/unit/accounting/
   flutter test test/integration/scenarios/
   flutter test test/invariants/
   ```
   وظهور: **All tests passed!**
