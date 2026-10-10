# 📌 تقرير حالة المشروع والتسليم المرحلي (Current Progress & Handover Report)
**التاريخ:** 10 أكتوبر 2026  
**الفرع:** `feat/erp-core-foundation-v1` (فرع جديد مخصص للنواة والـ ERP Core)  
**حالة الاختبارات الحالية:** 33 اختباراً آلياً ناجحاً بنسبة 100% (33 Passed / 0 Failed)

---

## 1. ما تم إنجازه واختباره وتأكيده بالكامل (Completed & Verified)

### أولاً: المرحلة 1 - النواة والمحرك المالي الصامت (Phase 1: Core Financial Engine) 🟢
1. **جداول النواة والمالية في Drift:**
   * `currency_tables.dart` (العملات، عملة الأساس، أسعار الصرف).
   * `fiscal_tables.dart` (السنوات والفترات المالية والإقفال).
   * `accounting_tables.dart` (شجرة الحسابات، قيود اليومية، أسطر القيود).
   * `party_tables.dart` (العملاء والموردين وحساباتهم المالية).
   * `payment_method_tables.dart` (الصناديق والبنوك وطرق الدفع).
2. **محرك الدقة الحسابية (`PrecisionMath`):**
   * حماية العمليات المالية والمخزنية من خطأ IEEE 754 للفواصل العشرية.
   * التوزيع النسبي للخصومات دون ضياع فلس واحد.
3. **شجرة الحسابات الافتراضية والزراعة التلقائية (`StandardCoaSeeder`):**
   * زراعة 24 حساباً معيارياً مقفلاً لحماية التاجر من التخريب.
   * زراعة عملة الأساس YER والعملات الأجنبية SAR و USD.
   * زراعة الصندوق الافتراضي وبنك الشبكة والسنة المالية الحالية.
   * اجتياز اختبار منع تكرار البيانات (Idempotency).
4. **محرك المحاسبة الصامت (`SilentAccountingEngine`):**
   * توليد القيود المزدوجة المتزنة تلقائياً (`baseDebit == baseCredit`).
   * التحويل لعملة الأساس اللحظية.
   * منع القيد في الفترات المقفلة (`FiscalPeriodClosedException`).
   * إلغاء القيود عبر القيد العكسي المعياري (`reverseEntry`).

---

### ثانياً: المرحلة 2 - الكتالوج، المخزون، والوحدات ومتوسط التكلفة (Phase 2: Inventory Engine) 🟢
1. **جداول الكتالوج والمخزون في Drift:**
   * `inventory_tables.dart` يشمل: `UnitsTable`, `ProductsTable`, `ProductUnitsTable`, `WarehousesTable`, `InventoriesTable`, `InventoryTransactionsTable`.
2. **محرك تحويل الوحدات (`UnitConverter`):**
   * تحويل الكراتين والدرزن إلى وحدة الأساس الصغرى (حبة) والعكس.
   * تحويل أسعار الشراء وتكاليف الوحدات بدقة.
3. **خوارزمية المتوسط المرجح المتحرك (`InventoryService`):**
   * حساب المتوسط المرجح المتحرك التراكمي عند الشراء المتتالي:
     $$\text{NewAvgCost} = \frac{(\text{CurrentQty} \times \text{CurrentCost}) + (\text{NewQty} \times \text{NewPurchasePrice})}{\text{CurrentQty} + \text{NewQty}}$$
   * حل فخ "البيع بالسالب": عند الشراء اللاحق تستقر التكلفة عند سعر الشراء الجديد فوراً دون انهيار المعادلة.
   * ثبات متوسط التكلفة عند البيع واستخراج تكلفة البضاعة المباعة (COGS).
   * تسويات الجرد الفعلي (Stocktake Reconciliation) وتوثيق التالف.

---

## 2. أين توقفنا بالضبط الآن؟ (Where We Stopped)
* **نحن الآن في بداية المرحلة 3 (Phase 3: Sales Engine & Live POS):**
  1. قمنا بتحديث جدول فواتير المبيعات [sales_tables.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/kernel/storage/tables/sales_tables.dart) وإضافة جدول تفاصيل وأسطر الفاتورة الجديد المفقود سابقاً (`SalesInvoiceItemsTable`).
  2. النقطة التالية مباشرة هي تشغيل `build_runner` لتوليد كود الـ Drift لجدول `SalesInvoiceItemsTable`، ثم بناء خدمة إتمام البيع الذرية `SalesCheckoutService`.

---

## 3. ما هو المتبقي بالترتيب للمراحل القادمة؟ (Remaining Roadmap)

### المتبقي في المرحلة 3 (المبيعات ونقطة البيع والكاشير):
* [ ] تشغيل `build_runner` لتوليد `SalesInvoiceItemsTable`.
* [ ] بناء فئة `SalesCheckoutService` لتنفيذ **المعاملة الذرية الخماسية للبيع**:
  1. حفظ رأس الفاتورة.
  2. حفظ أسطر الفاتورة مع التوزيع النسبي للخصم العام.
  3. خصم المخزون عبر `inventoryService.processStockOut` واستخراج التكلفة.
  4. إنشاء قيد اليومية الآلي المزدوج (صندوق/عميل + مبيعات + تكلفة + مخزون).
  5. ربط معايير التحقق (منع البيع الآجل لعميل غير مسجل أو متجاوز للحد الائتماني).
* [ ] كتابة وتشغيل اختبارات `sales_checkout_service_test.dart`.
* [ ] ربط واجهة نقطة البيع [pos_view.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/sales/presentation/views/pos_view.dart) و [pos_provider.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/sales/presentation/providers/pos_provider.dart) بقاعدة بيانات Drift واستبدال الـ Mock.
* [ ] كتابة تقرير التدقيق `PHASE_3_AUDIT_REPORT.md`.

### المراحل اللاحقة (الموثقة بالكامل في مجلد docs/blueprint/):
* **المرحلة 4 (المشتريات والموردين):**
  * فواتير المشتريات، تحديث التكلفة، مصاريف الشحن الإضافية، ودفتر الموردين (راجع `PHASE_4_PURCHASING_AND_SUPPLIERS.md`).
* **المرحلة 5 (الخزينة والصناديق والسندات):**
  * سندات القبض والصرف، التحويل بين الصناديق، معالجة فروق أسعار الصرف (FX Gain/Loss)، وإقفال الكاشير اليومي (راجع `PHASE_5_TREASURY_AND_VOUCHERS.md`).
* **المرحلة 6 (الإقفالات المالية والتقارير والأرباح):**
  * كشف حساب العميل التراكمي، قائمة الدخل (P&L)، بطاقة حركة الصنف، والإقفال السنوي (راجع `PHASE_6_CLOSINGS_AND_FINANCIAL_REPORTS.md`).
* **المرحلة 7 (المزامنة الأوفلاين وجسر المتجر):**
  * نمط صندوق الصادر (Outbox Pattern)، فض النزاعات، ومزامنة طلبات المتجر وتحويلها لفواتير كاشير (راجع `PHASE_7_OFFLINE_SYNC_AND_STORE_BRIDGE.md`).

---

## 4. إرشادات للفريق أو لأي مطور يكمل بعدنا:
1. **جميع الاختبارات تعمل محلياً بنسبة 100%** عبر الأمر: `flutter --no-version-check test`.
2. **اتبع الوثائق:** كل مرحلة لها ملف تفصيلي في `docs/blueprint/` يشمل الجداول، والمنطق، ومعايير القبول والممنوعات، واختبارات الـ Unit Tests.
3. **لا تكسر مبدأ الذرية (Atomicity):** أي عملية بيع أو شراء أو سند يجب أن تتم داخل كتلة `db.transaction()`.
