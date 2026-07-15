# System Domain Events Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الموحد للأحداث (Domain Events) التي يتم توليدها وتبادلها بين النطاقات (Domains) المختلفة في نظام Smart Merchant ERP. تهدف الوثيقة إلى توحيد المفاهيم الخاصة بالأحداث ووضع القواعد الصارمة لتعريفها، تسميتها، نشرها، واستهلاكها، لضمان استقرار النظام وعدم تداخل المسؤوليات.

---

## 2. Scope
يغطي هذا الدستور المعماري جميع الأحداث (Domain Events) التي تحدث داخل التطبيق وتستخدم للتواصل الداخلي بين Domains في النظام المتراص (Monolithic Architecture) للإصدار الأول (V1). ولا يمثل هذا الدستور نطاقاً (Domain) مستقلاً.

---

## 3. What is a Domain Event
**التعريف الرسمي:**
الـ Domain Event هو كائن يمثل حقيقة أو حدثاً ذا أهمية تشغيلية أو مالية وقع بالفعل في النظام بالماضي.
**متى يعتبر الحدث Domain Event:**
يعتبر الحدث Domain Event إذا كان يُشير إلى تغيير في حالة (State) لـ Aggregate Root مهم، وكان هذا التغيير يستدعي رد فعل (Reaction) من نطاق آخر داخل النظام دون أن يكون النطاق المصدر على علم بمن سيستقبل الحدث.

---

## 4. Event Principles
يخضع كل Domain Event للمبادئ التالية:
- **Fact of the Past:** يمثل شيئاً حدث بالفعل ولا يمكن تغييره (مثلاً: تم ترحيل الفاتورة).
- **Not a Command:** لا يمثل أمراً أو طلباً للقيام بشيء (مثلاً: لا يسمى `PostInvoice`)، بل يصف ما حدث (`InvoicePosted`).
- **Immutable:** الحدث غير قابل للتعديل (Immutable) بمجرد إنشائه.
- **Data Carrier:** يحمل بيانات الحدث فقط (Event Payload) التي تكفي لإعلام المستمعين بما حدث (غالباً Entity ID وبعض البيانات الأساسية).
- **No Business Logic:** لا يحتوي الحدث على أي منطق أعمال (Business Logic) أو استعلامات لقاعدة البيانات.

---

## 5. Naming Convention
تسمية الأحداث تخضع لقواعد صارمة تعبر عن الكيان والحالة بصيغة الماضي، ولا يسمح بأي صيغة أخرى.
*صيغة التسمية:* `[EntityName][Action in Past Tense]`
*أمثلة معتمدة:*
- `SalesInvoicePosted`
- `PurchaseInvoicePosted`
- `JournalEntryPosted`
- `InventoryTransactionPosted`
- `ReceiptVoucherPosted`
- `PaymentVoucherPosted`

---

## 6. Ownership Rules
- كل Event ينتمي لنطاق (Domain) واحد فقط وهو النطاق الذي وقع فيه الحدث (النطاق المصدر).
- لا يملك الحدث أكثر من Domain واحد.
- يتم تعريف الكائن الخاص بالحدث داخل طبقة النطاق المالك له.

---

## 7. Publishing Rules
في الإصدار الأول (V1) للنظام، تخضع عملية نشر الأحداث (Publishing) للقواعد التالية:
- تُنشر الأحداث بشكل متزامن (Synchronous).
- لا تُستخدم طوابير الانتظار (Queues).
- لا يُستخدم Event Bus خارجي.
- لا يُستخدم Message Broker للتبادل الداخلي للأحداث.

---

## 8. Consumption Rules
- أي Domain في النظام يستطيع الاستماع للحدث (Listen/Subscribe) إذا كان لديه مصلحة في التفاعل معه.
- المستمع (Consumer) يستطيع فقط قراءة بيانات الحدث.
- يُمنع إطلاقاً على المستمع محاولة تعديل بيانات الحدث أو حالته.

---

## 9. Transaction Rules
- يجب أن يتم توليد ونشر الحدث فقط **بعد نجاح العملية الأساسية** وحفظها في قاعدة البيانات (يفضل استخدامه بعد الـ Commit للـ Transaction، أو قبل الـ Commit بقليل بشرط ضمان التنفيذ).
- لا يجوز إطلاقاً نشر حدث لعملية فشلت أو تم التراجع عنها (Rollback).

---

## 10. Ordering Rules
- داخل نفس العملية (Transaction)، يجب أن تُنشر الأحداث بالترتيب المنطقي لحدوثها في النطاق المصدر.
- المستمع يجب ألا يعتمد بشكل صارم جداً على ترتيب أحداث من عمليات مختلفة إذا لم تكن مرتبطة، لكن في سياق الـ Synchronous Events الحالية، الترتيب يكون مضموناً بتسلسل الكود.

---

## 11. Idempotency Rules
- أي Event يجب أن يكون قابلاً لإعادة المعالجة (Idempotent) من قبل المستمعين (Listeners) دون أن يترك آثاراً جانبية ضارة (Side Effects) أو مضاعفة الأثر المحاسبي/المخزني.
- يجب على المستمع (Listener) التحقق مما إذا كان قد استجاب لهذا الحدث سابقاً وتجاهله إن تطلب الأمر.

---

## 12. Security Rules
يمنع منعاً باتاً احتواء الـ Domain Events على أي من البيانات التالية:
- كلمات المرور (Passwords).
- البيانات الشخصية الحساسة (PII) التي لا داعي لها.
- الأسرار والمفاتيح (Secrets & Keys).
- رموز الوصول (Tokens).

---

## 13. Dependencies
هذا الدستور يُشكل مرجعية للوثائق الخاصة بجميع النطاقات التالية التي قد تنشر أو تستمع للأحداث:
- `Finance_General_Ledger_Foundation_Architecture.md`
- `Sales_Foundation_Architecture.md`
- `Inventory_Foundation_Architecture.md`
- `Purchasing_Foundation_Architecture.md`
- `Financial_Documents_Foundation_Architecture.md`

---

## 14. Out Of Scope
العناصر التالية تعتبر **Out Of Scope** ولا يشملها هذا الدستور (V1):
- Event Bus الخارجي.
- رسائل الطوابير الموزعة (Kafka, RabbitMQ, SQS).
- المعالجة غير المتزامنة للأحداث (Async Processing).
- تصميم Event Sourcing (الذي يخزن الأحداث كحالة النظام).
- الفصل الكامل بنمط CQRS باستخدام الأحداث لنقل البيانات لقواعد القراءة.
- التراسل الموزع بين الخدمات المصغرة (Distributed Messaging).

---

## 15. Standard Domain Events
قائمة الأحداث الرسمية الحالية المعتمدة في النظام والتي تم تحديدها بناءً على النطاقات المكتملة:

**Finance Domain:**
- `JournalEntryPosted`
- `JournalEntryReversed`

**Sales Domain:**
- `SalesInvoicePosted`
- `SalesInvoiceReversed`

**Inventory Domain:**
- `InventoryTransactionPosted`
- `InventoryTransactionReversed`

**Purchasing Domain:**
- `PurchaseInvoicePosted`
- `PurchaseInvoiceReversed`

*(ملاحظة: لا يُسمح بإضافة أي أحداث أخرى غير مسجلة فعلياً في الوثائق المعمارية للـ Domains المذكورة).*
