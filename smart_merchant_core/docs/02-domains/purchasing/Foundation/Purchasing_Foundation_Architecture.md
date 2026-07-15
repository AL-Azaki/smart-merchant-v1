# Purchasing Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري والمرجع الأساسي لنطاق المشتريات (Purchasing Domain) في نظام Smart Merchant ERP. الهدف من هذه الوثيقة هو إرساء القواعد الحاكمة لإدارة عمليات الشراء والتوريد، وتوضيح مسؤوليات النطاق، وحدوده الصارمة لضمان عدم تداخله مع النطاقات الأخرى (مثل المخزون والمالية) وفقاً لمبادئ التصميم النظيف (Clean Architecture).

---

## 2. Scope
**ما تغطيه الوثيقة:**
- المبادئ المعمارية الحاكمة لنطاق المشتريات.
- تعريف الكيانات الجذرية (Aggregate Roots) والكيانات التابعة (Child Entities).
- قواعد الملكية (Ownership) والفصل التام عن النطاقات الأخرى.
- سياسات الأمان والعزل (Tenant Isolation).
- قواعد التخاطب والتكامل (Integration) مع المخزون والقيود المحاسبية.

---

## 3. Responsibilities
- المالك الحصري والوحيد لإدارة عمليات المشتريات (Purchase Invoices).
- توثيق بيانات الموردين المرتبطة بالفواتير، المنتجات المشتراة، الكميات، والتكاليف.
- حساب الضرائب، الخصومات، وإجماليات الشراء داخل الفاتورة.
- إدارة دورة حياة الفاتورة الشرائية (Lifecycle).
- إرسال طلبات التفويض للأنظمة الأخرى (Inventory و Posting Engine) لتطبيق التأثيرات المالية والمخزنية.

---

## 4. Domain Principles
- **Separation of Concerns:** نطاق المشتريات مسؤول عن الشراء فقط. ولا يمتلك أي معرفة بآلية تخزين البضاعة أو كيفية بناء القيود المزدوجة.
- **Single Source of Truth:** `PurchaseInvoice` هو المصدر الوحيد الموثوق لجميع بيانات عملية الشراء ضمن النظام.
- **Strict Boundaries:** يُمنع تماماً أي وصول مباشر لجداول أو نماذج خارج Purchasing Domain.

---

## 5. Ownership Rules
- **التشغيل:** نطاق المشتريات يمتلك بالكامل بيانات فواتير المشتريات وأسطرها.
- **المخزون:** المشتريات لا تعدل المخزون أو ترصده مباشرة.
- **المحاسبة:** المشتريات لا تنشئ قيوداً محاسبية أو تؤثر على الحسابات المالية (General Ledger) بنفسها.
- **التكامل:** كل تأثير خارج نطاق المشتريات يتم حصرياً عبر توجيه طلبات (Requests/DTOs) للخدمات المخصصة في النطاقات المعنية.

---

## 6. Aggregate Rules
- **PurchaseInvoice:** يعتبر `PurchaseInvoice` الكيان الجذري الوحيد (Aggregate Root) في عمليات الشراء الأساسية (V1).
- **PurchaseInvoiceItem:** يعتبر `PurchaseInvoiceItem` كياناً فرعياً (Child Entity) مملوكاً بالكامل لـ `PurchaseInvoice`.
- لا يجوز إنشاء، أو تعديل، أو حذف، أو الاستعلام عن `PurchaseInvoiceItem` بشكل مستقل عن الفاتورة الأم.
- أي عملية استرجاع أو تحديث يجب أن تتم عبر الـ Aggregate Root حصراً.

---

## 7. Tenant Isolation
- **Business Isolation:** جميع عمليات الشراء وفواتيرها تخص شركة واحدة فقط (`business_id`). يُمنع إطلاقاً خلط الفواتير بين الشركات، ويجب أن تتضمن جميع العمليات والاستعلامات تصفية صارمة برقم الشركة.
- **Branch Isolation:** تخضع الفاتورة لفرع محدد وتُربط به لضمان توزيع الصلاحيات والتقارير بشكل صحيح.

---

## 8. Integration Rules
- **Inventory Integration:** 
  - Purchasing يرسل طلباً (عبر Builder/Integration Service) إلى Inventory Domain لتسجيل حركة دخول بضاعة (Receipt).
  - يُمنع تماماً الوصول المباشر لجداول `inventory_transactions` أو `inventories`.
- **Finance Integration:**
  - Purchasing يرسل طلباً عبر Integration Service إلى Posting Engine لإنشاء القيد المحاسبي.
  - يُمنع تماماً الوصول المباشر لجداول `journal_entries` أو غيرها في Finance Domain.
- **Contracts Only:** جميع عمليات التكامل يجب أن تتم عبر الواجهات (Interfaces) والخدمات (Services) المعتمدة.

---

## 9. Security Rules
- جميع العمليات (إنشاء، تعديل، قراءة، حذف) يجب أن تمر عبر طبقة الـ Policy الخاصة بـ `PurchaseInvoice` للتأكد من هوية المستخدم وامتلاكه للصلاحية والـ `business_id` الصحيح.
- لا يُسمح بتعديل الفواتير بعد ترحيلها واعتمادها (Posted)، وتخضع لقيود Immutability صارمة.

---

## 10. Dependencies
تتكامل وتتوافق هذه الوثيقة مع الدساتير المعمارية المجمدة التالية:
- `Finance_General_Ledger_Foundation_Architecture.md`
- `Sales_Foundation_Architecture.md`
- `Inventory_Foundation_Architecture.md`

---

## 11. Out Of Scope
- إدارة عروض الأسعار الشرائية (Purchase Quotations) أو طلبات الشراء (Purchase Orders) في الإصدار الأول (V1).
- إدارة خطط السداد وتتبع دفعات الموردين المعقدة (يُدار جزء الدفعات عبر نطاق المالية/المدفوعات).
- إدارة الشحنات وتكاليف الاستيراد المتقدمة (Landed Cost/LC) في الإصدار الأساسي الأول.
