# PurchaseInvoice Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الرسمي لكيان فاتورة المشتريات (`PurchaseInvoice`) ضمن نطاق المشتريات (Purchasing Domain). يُعد هذا الكيان المرجع التشغيلي الرسمي والوحيد لإثبات عمليات الشراء من الموردين في الإصدار الأول (V1)، وهو المسؤول عن تجميع وتغليف جميع تفاصيل المشتريات وتوجيه طلبات التأثيرات المالية والمخزنية إلى النطاقات المختصة.

---

## 2. Responsibilities
- تسجيل تواريخ ومرجعيات فواتير الشراء المستلمة من الموردين (مثل رقم فاتورة المورد، وتاريخ الاستحقاق).
- حساب وحفظ الإجماليات (Sub-total, Taxes, Discounts, Grand Total) بناءً على أسطر الفاتورة.
- إدارة العملة المحلية والأجنبية وتخزين سعر الصرف وقت تنفيذ العملية.
- توثيق بيانات المورد المستهدف لعملية الشراء.
- تنظيم وقيادة دورة حياة العملية من الإنشاء إلى الاعتماد المالي والمخزني.

---

## 3. Entity Classification
- **Aggregate Root:** يُعتبر `PurchaseInvoice` الكيان الجذري (Aggregate Root) الأساسي والأوحد لإدارة عمليات الشراء.
- **Child Entity:** `PurchaseInvoiceItem` هو كيان فرعي (Child Entity) مملوك بالكامل للـ Aggregate Root، ولا يمكن وجوده أو التعامل معه بشكل مستقل إطلاقاً.

---

## 4. Relationships
- **PurchaseInvoiceItem:** علاقة (1-To-Many) تمثل الأسطر الخاصة بالمنتجات المشتراة، وجميعها يجب أن تنتمي لنفس الـ Business.
- **Supplier:** علاقة (Many-To-1) لتحديد المورد الذي تم الشراء منه.
- **Branch/Warehouse:** علاقة (Many-To-1) لتحديد وجهة الفاتورة الأساسية.
- **Currency:** علاقة (Many-To-1) للربط مع العملة المستخدمة في الفاتورة.
- **Business:** علاقة (Many-To-1) صارمة لضمان عزل البيانات (Tenant Isolation).

---

## 5. Lifecycle
تمر فاتورة المشتريات بدورة حياة صارمة مكونة من ثلاث حالات:
1. **Draft (مسودة):** 
   - الحالة الافتراضية عند الإنشاء. 
   - الفاتورة وأسطرها قابلة للتعديل أو الحذف (Hard Delete).
   - ليس لها أي تأثير مالي أو مخزني.
2. **Posted (مُرحلة):** 
   - الحالة المعتمدة والنهائية.
   - الفاتورة مُقفلة كلياً وغير قابلة لأي تعديل أو حذف (Immutable).
   - تم إرسال طلب إلى Inventory Domain لتوليد حركة دخول المخزون.
   - تم إرسال طلب إلى Posting Engine لتوليد القيد المحاسبي.
3. **Reversed (مُلغاة/معكوسة):** 
   - تُعكس الفاتورة لغرض التصحيح أو الإلغاء.
   - الفاتورة تظل موجودة، ولكن يتم إرسال طلبات إلغاء/حركات عكسية للمخزون (Reverse Stock Movement) والمالية (Reverse Journal Entry).

---

## 6. Business Rules
- يُمنع إدخال فاتورة مشتريات بدون سطر تفصيلي واحد (`PurchaseInvoiceItem`) على الأقل قبل عملية الترحيل (Posting).
- لا يجوز لفاتورة واحدة أن تحتوي على منتجات لشركات مختلفة (Strict Tenant Isolation).
- يجب حساب جميع إجماليات الفاتورة محلياً ومركزياً داخل `PurchaseInvoice` بناءً على الأسطر التابعة.
- لا يجوز تجاوز تاريخ الاستحقاق لتاريخ الفاتورة (Due Date >= Invoice Date).
- النظام يمتنع عن توجيه أي أوامر محاسبية أو مخزنية إذا لم تكن الفاتورة متوازنة.

---

## 7. Invoice Number Policy
- يتم إنشاء رقم فاتورة داخلي (Internal Invoice Number) تسلسلي فريد لكل `business_id` (وعادة يتم تفريعه حسب الـ Branch إذا تطلب العمل).
- يمكن للفاتورة أن تحتفظ أيضاً برقم المرجع الخاص بالمورد (Supplier Reference Number) لأغراض المطابقة.

---

## 8. Currency Policy
- تُسجل الفاتورة بعملة المعاملة (`currency_id`) مع حفظ سعر الصرف (`exchange_rate`) في نفس اللحظة.
- تُحسب الإجماليات (Totals) بعملة الفاتورة.
- تُحسب القيم الأساسية (Base Totals) بالعملة الرئيسية للنظام عن طريق ضرب القيم الأصلية في سعر الصرف، لاستخدامها في إعداد القيود المحاسبية عبر Posting Engine.

---

## 9. Inventory Policy
- **No Direct Inventory Modification:** يُمنع إطلاقاً تعديل أي رصيد مخزني من داخل `PurchaseInvoice`.
- إنشاء حركة المخزون لا يتم داخل هذا النطاق، بل يتم إرسال طلب تكامل (Integration Request) إلى Inventory Domain (InventoryStockService) لإنشاء حركة مخزنية رسمية وشرعية.

---

## 10. Posting Policy
- **No Direct Posting Logic:** يُمنع تماماً إنشاء قيود محاسبية أو كتابة أي منطق محاسبي (Business Logic for Accounting) داخل `PurchaseInvoice` أو خدمات المشتريات.
- إنشاء القيد المحاسبي يتم حصرياً عبر توجيه DTO إلى Posting Engine (أو Finance Domain). المشتريات تُعلم المحرك بحدوث حدث مالي ليقوم هو بالتوجيه والترحيل السليمين.

---

## 11. Ownership Rules
- المشتريات تملك الفاتورة والأسطر.
- المالية تملك القيود (Journal Entries).
- المخزون يملك الحركات (Inventory Transactions).
- جميع عمليات التكامل مع الأنظمة الأخرى تتم حصرياً عبر الواجهات والخدمات (Services and Contracts).

---

## 12. Audit Trail
- يجب تسجيل معرّف المستخدم الذي أنشأ الفاتورة (`created_by`).
- يجب تسجيل من قام بترحيل الفاتورة (`posted_by`) وتاريخ الترحيل (`posted_at`).
- في حال عكس الفاتورة، يجب توثيق من قام بالعكس (`reversed_by`) وتاريخه (`reversed_at`).
- تُطبّق الأختام الزمنية العادية (`created_at`, `updated_at`).

---

## 13. Immutability Rules
- بعد الترحيل (`Posted`)، يُمنع إطلاقاً إجراء أي تعديل (Update) على بيانات الفاتورة أو الأسطر الخاصة بها.
- لا يُسمح باستخدام الـ Soft Delete. يتم حذف الفاتورة فعلياً (Hard Delete) فقط وفقط إذا كانت في حالة `Draft`. بمجرد الترحيل، يُلغى الحذف ويُعتمد العكس (`Reversed`) كخيار وحيد للتصحيح.

---

## 14. Dependencies
تتكامل هذه الوثيقة المعمارية مع:
- `Purchasing_Foundation_Architecture.md`
- `Finance_General_Ledger_Foundation_Architecture.md`
- `Posting_Engine_Architecture.md`
- `Inventory_Foundation_Architecture.md`

---

## 15. Out Of Scope
- المدفوعات النقدية والبنكية للموردين (يُدار عبر Finance Domain / Payment Vouchers).
- إدارة ومتابعة الطلبيات المسبقة (Purchase Orders) في V1.
- تقييم أداء الموردين الإحصائي المتقدم (Supplier Analytics).
