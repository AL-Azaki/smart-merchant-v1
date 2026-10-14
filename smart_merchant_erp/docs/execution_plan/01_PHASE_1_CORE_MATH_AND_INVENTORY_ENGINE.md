# مواصفات المرحلة الأولى: المحرك الحسابي وتوحيد المخزون والعملات
## Phase 1 Specification: Core Math Engine, Inventory & Currency Normalization

**الهدف:** تصحيح الأخطاء الحسابية القاتلة الحالية في الكود، وتوحيد منطق تقييم المخزون (WAC) بالعملة الأساسية، وتصحيح تفكيك وحدات القياس (كرتون/حبة)، وربط تسويات الجرد بالدفتر العام.

---

## 1. المشاكل الحالية والأدلة من الكود (Current Code Gaps)

### 1.1 خطأ متوسط التكلفة مع العملات الأجنبية (The Currency-Cost Bug)
* **الموقع:** [record_purchase_usecase.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/purchasing/application/usecases/record_purchase_usecase.dart#L400-L411)
* **الكود الحالي الخاطئ:**
  ```dart
  // السعر الجديد item.unitCost بعملة الفاتورة (مثلاً USD)، بينما oldAvgCost بالعملة الأساسية (YER)!
  final newCost = item.unitCost;
  updatedAvgCost = ((oldQty * oldAvgCost) + (newQty * newCost)) / updatedQty;
  ```
* **الأثر:** تدمير متوسط تكلفة المخزون عند الشراء بالدولار أو الريال السعودي.

### 1.2 فخ ربط المخزون بوحدة القياس (Unit Disconnection Trap)
* **الموقع:** [inventories_table.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/database/tables/inventory/inventories_table.dart#L33) و [complete_sale_usecase.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/sales/application/usecases/complete_sale_usecase.dart#L238-L248)
* **المشكلة:** يتم تخزين الرصيد برقم `product_unit_id`. عند شراء كرتون، يدخل الرصيد لسجل الكرتون. وعندما يبيع الكاشير بالحبة، يبحث النظام عن رصيد الحبة فيجده صفر، فيرفض البيع رغم وجود كراتين في المخزن!

### 1.3 خطأ مضاعفة سعر الصرف في تكلفة المبيعات (COGS Foreign Multiplier Bug)
* **الموقع:** [complete_sale_usecase.dart](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/lib/modules/sales/application/usecases/complete_sale_usecase.dart#L484-L503)
* **الكود الحالي:**
  ```dart
  foreignAmount: drift.Value(totalCost), // totalCost محسوبة أساساً بالعملة الأساسية من averageCost!
  baseAmount: drift.Value(totalCost * params.exchangeRate), // تم ضربها بسعر الصرف مرة أخرى بالخطأ!
  ```

---

## 2. الحلول الهندسية والمعادلات المعتمدة (Approved Solutions & Formulas)

### 2.1 كلاس الحسابات الدقيقة (PrecisionMath Utility)
للقضاء على أخطاء الفاصلة العائمة (`0.1 + 0.2 = 0.30000000000000004`)، يتم إنشاء وتعميم الكلاس التالي في `lib/core/utils/precision_math.dart`:

```dart
class PrecisionMath {
  /// تقريب مالي قياسي للعملات (افتراضياً رقمين عشريين، أو حسب إعدادات العملة)
  static double roundMoney(double value, [int decimals = 2]) {
    final mod = math.pow(10, decimals).toDouble();
    return ((value * mod).roundToDouble()) / mod;
  }

  /// تقريب كميات المخزون (3 خانات عشرية لدعم الكيلوجرام والجرام والأوزان)
  static double roundQty(double value, [int decimals = 3]) {
    final mod = math.pow(10, decimals).toDouble();
    return ((value * mod).roundToDouble()) / mod;
  }

  /// فحص توازن القيد مع معالجة الكسور المتناهية في الصغر
  static bool areBalanced(double debit, double credit, [double tolerance = 0.001]) {
    return (debit - credit).abs() <= tolerance;
  }
}
```

### 2.2 معادلة متوسط التكلفة المرجح الموحدة (Standard WAC Formula)
عند إدخال أي فاتورة شراء أو تسوية زيادة:
1. **تحويل سعر الشراء إلى العملة الأساسية فوراً:**
   $$\text{unitCostInBase} = \frac{\text{item.unitPrice} \times \text{exchangeRate}}{\text{conversionFactor}}$$
   *حيث `conversionFactor` هو معامل تحويل وحدة الشراء إلى الوحدة الأساسية.*
2. **تحويل كمية الشراء إلى الوحدة الأساسية الصغرى:**
   $$\text{qtyInBase} = \text{item.quantity} \times \text{conversionFactor}$$
3. **حساب متوسط التكلفة الجديد بالعملة الأساسية (Base WAC):**
   $$\text{New Average Cost} = \frac{(\text{Old Qty} \times \text{Old Avg Cost}) + (\text{Qty In Base} \times \text{Unit Cost In Base})}{\text{Old Qty} + \text{Qty In Base}}$$

### 2.3 معمارية توحيد المخزون (Single Stock Pool Per Product)
لمنع تشتت الكراتين والحبات:
* جدول `inventories` يعتبر الحقل `product_unit_id` ممثلاً **للوحدة الأساسية حصراً (Base Unit ID)** لكل منتج في كل مخزن.
* في شاشات المبيعات والمشتريات والمرتجعات والجرد:
  * يتم جلب `conversionFactor` الخاص بوحدة السطر المختارة.
  * كل العمليات على جدول `inventories` (زيادة، خصم، فحص رصيد) تُنفذ بعد تحويل الكمية إلى:
    $$\text{Effective Quantity} = \text{Input Quantity} \times \text{conversionFactor}$$
* **مثال عملي:**
  * المنتج: أرز الشعلان (الوحدة الأساسية: كيس 1 كجم، الوحدة الإضافية: كرتون 10 كجم ومعامله 10).
  * رصيد المخزن: 0.
  * اشترينا 5 كراتين -> يضاف للمخزن: $5 \times 10 = 50$ كيس.
  * بعنا في الكاشير 3 أكياس -> يخصم 3، يتبقى 47 كيس.
  * بعنا كرتون واحد -> يخصم $1 \times 10 = 10$، يتبقى 37 كيس.
  * النظام يعرض في شاشة الكاشير والمخزن: "المتوفر: 3 كرتون و 7 كيس" أو "37 كيس".

---

## 3. الخطوات التنفيذية التفصيلية (Implementation Steps)

### الخطوة 1.1: تعديل دالة `RecordPurchaseUseCase`
* مسار الملف: `lib/modules/purchasing/application/usecases/record_purchase_usecase.dart`
* **المطلوب:**
  1. جلب بيانات `ProductUnit` لكل عنصر لمعرفة `conversionFactor` والوحدة الأساسية.
  2. تحويل الكمية إلى الوحدة الأساسية: `baseQuantity = item.quantity * conversionFactor`.
  3. تحويل التكلفة للوحدة الأساسية بالعملة المحلية:
     `unitCostBase = (item.unitCost * params.exchangeRate) / conversionFactor`.
  4. تحديث `inventories.quantity` بالـ `baseQuantity`.
  5. تطبيق معادلة WAC بالعملة الأساسية وتخزين النتيجة في `inventories.averageCost`.
  6. في القيد اليومي:
     * سطر المخزون (مدين): المبلغ بعملة الفاتورة = إجمالي التكلفة، والمبلغ بالعملة الأساسية = `totalCost * exchangeRate`.
     * سطر المورد / النقدية (دائن): متطابق تماماً.

### الخطوة 1.2: تعديل دالة `CompleteSaleUseCase`
* مسار الملف: `lib/modules/sales/application/usecases/complete_sale_usecase.dart`
* **المطلوب:**
  1. حساب كمية البيع بالوحدة الأساسية: `soldBaseQty = item.quantity * unit.conversionFactor`.
  2. فحص توفر الرصيد: `if (inventory.quantity < soldBaseQty) return Left(InsufficientStockFailure())`.
  3. خصم `soldBaseQty` من المخزن.
  4. حساب تكلفة البضاعة المباعة (COGS) الحقيقية:
     `lineCogsBase = soldBaseQty * inventory.averageCost`.
  5. في قيود اليومية للـ COGS:
     * مدين: تكلفة المبيعات (COGS) -> `baseAmount = lineCogsBase`, `foreignAmount = lineCogsBase / params.exchangeRate`.
     * دائن: المخزون (Inventory Asset) -> `baseAmount = lineCogsBase`, `foreignAmount = lineCogsBase / params.exchangeRate`.
     *(هذا يحل خطأ مضاعفة سعر الصرف السابق نهائياً).*

### الخطوة 1.3: تصحيح تسويات الجرد المخزني `ProcessStockAdjustmentUseCase`
* مسار الملف: `lib/modules/inventory/application/usecases/process_stock_adjustment_usecase.dart`
* **المطلوب:**
  * عند وجود عجز جرد (الكمية الفعلية < الدفترية):
    1. خصم النقص من المخزون.
    2. توليد قيد آلي متزن:
       * مدين: خسائر وعجز الجرد المخزني (`inventory_adjustment_loss`).
       * دائن: أصل المخزون (`inventory_asset`).
       * القيمة = $\text{النقص بالوحدات الأساسية} \times \text{averageCost}$.
  * عند وجود فائض جرد (الكمية الفعلية > الدفترية):
    1. زيادة الفائض في المخزون.
    2. توليد قيد آلي متزن:
       * مدين: أصل المخزون (`inventory_asset`).
       * دائن: أرباح وفائض الجرد المخزني (`inventory_adjustment_gain`).

---

## 4. معايير القبول الصارمة (Acceptance Criteria)

- [ ] **AC-1.1:** شراء 10 حبات بسعر 100 ريال يمني، ثم شراء 10 حبات بسعر 1 دولار (سعر الصرف 530)، يجعل متوسط التكلفة الجديد = $\frac{(10 \times 100) + (10 \times 530)}{20} = \frac{1000 + 5300}{20} = 315$ ريال يمني بالضبط.
- [ ] **AC-1.2:** شراء 2 كرتون عصير (كل كرتون 24 علبة) يرفع رصيد العصير في المخزن إلى 48 علبة.
- [ ] **AC-1.3:** بيع 5 علب في الـ POS يخصم 5 من الـ 48 ويتبقى 43 علبة بنجاح تام ودون أخطاء.
- [ ] **AC-1.4:** قيد تكلفة البضاعة المباعة (COGS) في كل فاتورة بيع يساوي دائماً: $\text{الكميات المباعة} \times \text{متوسط التكلفة بالعملة الأساسية}$، ويكون القيد متزناً حتى الهللة.
- [ ] **AC-1.5:** تسوية عجز بمقدار 3 حبات تكلفة الواحدة 200 ريال تولد قيداً بـ 600 ريال من حساب عجز الجرد إلى حساب المخزون آلياً.

---

## 5. محاذير الخطر وقواعد الرفض (Danger Traps & Rejection Rules)

> [!CAUTION]
> **ممنوع قطعي (CRITICAL REJECTION):**
> 1. ممنوع تخزين `averageCost` بأي عملة غير العملة الأساسية للنظام.
> 2. ممنوع خصم المخزون دون ضرب الكمية في `conversionFactor`.
> 3. ممنوع السماح للـ `updatedQty` أن تصبح صفراً أو سالبة في معادلة القسمة لتفادي الـ `DivisionByZeroException` (إذا كان الرصيد الجديد صفر، يبقى متوسط التكلفة كما هو ولا يُقسم على صفر).
> 4. ممنوع تنفيذ أي تحديث للمخزون خارج `ApplicationTransactionRunner`.
