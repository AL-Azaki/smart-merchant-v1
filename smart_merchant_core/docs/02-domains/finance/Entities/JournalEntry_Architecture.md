# JournalEntry Architecture

**Status:** APPROVED  
**Version:** 1.3  
**State:** FROZEN  

---

## Purpose
يمثل `JournalEntry` (رأس القيد المحاسبي) المكون الأساسي لتوثيق جميع العمليات المالية داخل النظام. 
- **مسؤوليته داخل Finance Domain:** يعتبر السجل الرسمي لأي حركة مالية تؤثر على الأرصدة.
- **Aggregate Root:** يعتبر الكيان الجذري (Aggregate Root) الذي يغلف ويحتوي على أطراف القيد (`JournalEntryLines`)، ولا يمكن التعامل مع الأطراف بشكل مستقل عنه.
- **علاقته بالـ General Ledger:** يمثل `JournalEntry` المُرحَّل (`Posted`) اللبنة الأساسية التي يُبنى منها الـ `General Ledger`. لا يوجد أي رصيد في النظام لا يستند إلى هذا الكيان.

---

## Responsibilities
- **يمثل رأس القيد المحاسبي:** يحتوي على البيانات الرئيسية للقيد مثل التاريخ، الوصف، المرجع، ورقم القيد.
- **يمتلك JournalEntryLine:** هو المسؤول الوحيد عن إدارة وحفظ أطراف القيد المرتبطة به.
- **لا يخزن الأرصدة:** الكيان نفسه لا يمتلك أي حقول لتخزين أرصدة الحسابات.
- **لا يحسب الأرصدة:** لا يقوم الكيان بحساب أرصدة الحسابات برمجياً. الأرصدة تُستخرج عبر تجميع الـ `JournalEntryLines` في الـ `General Ledger`.
- **الإنشاء الحصري:** لا ينشئ الكيان نفسه مباشرة عبر Controllers قياسية، وإنما يتم إنشاؤه فقط وبشكل حصري عبر محرك الترحيل (`Posting Engine`).
- **مستند رسمي:** يمثل مستنداً محاسبياً قانونياً ورسمياً بمجرد وصوله لحالة الترحيل (`Posted`).

---

## Entity Classification
- **Classification:** Transactional Data (بيانات حركية).
- **Ownership:** يتبع للـ `Business` (الشركة).
- **Tenant Scope:** Business Level.
- **Aggregate Root:** نعم (يغلف `JournalEntryLine`).
- **Lifecycle:** يمتلك دورة حياة صريحة (Draft → Posted → Reversed).
- **Mutability:** Mutable في حالة الـ Draft، و **Immutable** تماماً في حالة الـ Posted أو Reversed.
- **Deletion Strategy (No Soft Delete):** 
  - الكيان لا يستخدم `Soft Delete` إطلاقاً.
  - `Hard Delete` مسموح فقط في حالة الـ `Draft`.
  - يمنع حذف `Posted`.
  - يمنع حذف `Reversed`.

---

## Relationships
- **belongsTo:** `Business` (الشركة التي تملك القيد).
- **belongsTo:** `FiscalPeriod` (الفترة المالية التي يقع فيها القيد).
- **hasMany:** `JournalEntryLines` (أطراف القيد المدائنة والدائنة).

**علاقات تتبع المسؤولية (Audit Trail):**
- **belongsTo:** `User` (Created By)
- **belongsTo:** `User` (Posted By)
- **belongsTo:** `User` (Reversed By)
*(ملاحظة: هذه العلاقات مخصصة فقط لتتبع المسؤولية (Audit Trail)، ولا تؤثر على منطق القيد المحاسبي أو دورة حياته).*

*(لا يُسمح بإضافة أي علاقات أخرى غير معتمدة أو معقدة في الإصدار V1).*

---

## Lifecycle & Status Policy
دورة حياة القيد المحاسبي صارمة ومغلقة. الحالات الرسمية الوحيدة المسموحة هي:
- `Draft`
- `Posted`
- `Reversed`
ولا يسمح بأي حالة أخرى. ويجب أن تكون هذه القيم محمية أيضاً على مستوى قاعدة البيانات (Database Constraint).

- **Draft:** المسودة الأولية للقيد (قبل الترحيل النهائي).
- **Posted:** القيد مرحّل رسمياً وأثّر على الأرصدة المحاسبية.
- **Reversed:** القيد تم إلغاؤه (عكسه) بقيد عكسي آخر لتصفير أثره.

**الانتقالات المسموحة:**
- `Draft` → `Posted`
- `Posted` → `Reversed`

**الانتقالات الممنوعة قطعياً:**
- `Posted` → `Draft`
- `Reversed` → `Posted`
- `Reversed` → `Draft`

---

## Business Rules
تُطبق القواعد التالية بصرامة داخل الـ Posting Engine لضمان سلامة الكيان:
- **منع التعديل:** يُمنع تعديل أي تفاصيل مالية أو مرجعية بعد الوصول لحالة `Posted`.
- **منع الحذف:** يُمنع حذف القيد كلياً بعد الـ `Posting`.
- **الفترة المالية:** يُمنع إنشاء أو ترحيل قيد داخل فترة مالية مغلقة (`Closed`).
- **القيد المزدوج:** يُمنع الترحيل إذا كان القيد غير متوازن (المدين لا يساوي الدائن بالعملة الأساسية `base_amount`).
- **الأطراف الإلزامية:** يُمنع إنشاء `JournalEntry` بدون احتوائه على أطراف `JournalEntryLines` متوازنة.
- **المستند المصدري:** يُمنع وجود `JournalEntry` بدون مستند مصدري (`Source Document`)، ويستثنى من ذلك فقط القيد اليدوي (`Manual Journal`).
- **منع التكرار:** يُمنع تكرار ترحيل نفس المستند المصدري مرتين (Idempotency).
- **سياسة رقم القيد (Journal Number Policy):** رقم القيد (`Journal Number`) يجب أن يكون `Unique` داخل نفس الـ `Business`. القاعدة الرسمية هي: `Unique (business_id, journal_number)` ولا يجوز تكراره داخل نفس الشركة.
- **جمود النسخة (Snapshot):** بيانات العملة وأسعار الصرف ثابتة ولا يرجع فيها لجدول الصرف بعد الترحيل.
- **صلاحية الحسابات:** جميع الحسابات المستخدمة يجب أن تكون `Posting Accounts` ومفعلة (`Active`).
- **عزل الشركات:** جميع الحسابات والفترات يجب أن تنتمي لنفس الـ `Business` الخاص بالقيد.
- **صلاحية العملات:** جميع العملات المستخدمة يجب أن تكون صحيحة وموجودة بالنظام.
- **المرور الحتمي:** جميع البيانات وعمليات إنشاء القيد يجب أن تمر حصراً عبر الـ `Posting Engine`.

---

## Journal Type
يمتلك كل `JournalEntry` نوعاً (`Journal Type`).
الأنواع الرسمية في الإصدار الأول (V1) هي فقط:
- Manual
- Sales Invoice
- Purchase Invoice
- Payment
- Inventory Adjustment
- Reverse

**قواعد Journal Type:**
- يستخدم للتصنيف فقط.
- لا يؤثر على قواعد القيد المزدوج.
- لا يؤثر على الـ `Posting Engine`.
- يستخدم للتقارير والبحث والفلترة والتحليل فقط.

---

## Currency Policy
- يُسمح بأن يكون `JournalEntry` بعملة أجنبية.
- يحتفظ القيد بشكل دائم بالحقول التالية: `currency_id`, `exchange_rate`, `foreign_amount`, `base_amount`.
- يعتمد التوازن المحاسبي دائماً على `base_amount` فقط.
- يُستخدم `foreign_amount` فقط لحفظ قيمة العملية الأصلية.
- يُمنع قطعياً استخدام `foreign_amount` للتحقق من توازن القيود.

---

## Dates Policy (Document Date / Posting Date)
يوجد تاريخان مستقلان وإلزاميان، ولا يستخدم حقل `journal_date`:
- `document_date`: يمثل تاريخ المستند التشغيلي.
- `posting_date`: يمثل التاريخ الذي يؤثر فيه القيد على `General Ledger` وعلى الـ `Fiscal Period`.
  - يجب أن يقع `posting_date` داخل `FiscalPeriod` مفتوحة.
  - يمكن أن يختلف عن `document_date`.
  - بعد ترحيل القيد، يصبح `posting_date` غير قابل للتعديل نهائياً.

---

## Source Document Mapping & Document Type Policy
يعتمد القيد الحقول الرسمية التالية للربط بالمستند (ولا يعتمد `reference_type` أو `reference_id`):
- `journal_type`
- `document_type`
- `document_id`
- `document_number` (يمكن أن يكون Nullable فقط في `Manual Journal`)

القيم الرسمية الوحيدة المسموحة لـ `document_type` هي:
- `Manual`
- `SalesInvoice`
- `PurchaseInvoice`
- `Payment`
- `InventoryAdjustment`
- `Reverse`
ولا يسمح بإضافة أي قيمة أخرى خارج هذه القائمة في الإصدار الأول V1.

مصادر القيود المعتمدة:
- **Manual Journal:** القيد اليدوي (ينشئه المحاسب مباشرة عبر الـ Finance Domain).
- **SalesInvoice:** فاتورة المبيعات (تأتي كطلب ترحيل من Sales Domain).
- **PurchaseInvoice:** فاتورة المشتريات (تأتي كطلب ترحيل من Purchasing Domain).
- **Payment:** سندات الصرف والقبض (تأتي كطلب ترحيل من Finance Domain/Payments).
- **InventoryAdjustment:** التسويات الجردية (تأتي كطلب ترحيل من Inventory Domain).

*ملاحظة: المسؤول الوحيد عن الإنشاء الفعلي للقيد في جميع هذه الحالات هو الـ `Posting Engine` المتموضع داخل الـ Finance Domain.*

---

## Ownership Rules
- **الملكية الحصرية للترحيل:** محرك الترحيل (`Posting Engine`) داخل نطاق الـ Finance هو المالك الوحيد والشرعي لإنشاء `JournalEntry` وأطرافه.
- **المنع العابر للنطاقات:** لا يُسمح لأي Domain آخر (مثل المبيعات أو المشتريات) بإنشاء أو التعديل على جداول `JournalEntry` مباشرة في قاعدة البيانات بأي شكل من الأشكال.

**قيود الـ Aggregate Root:**
بما أن `JournalEntry` هو `Aggregate Root` فإنه:
- يُمنع إنشاء `JournalEntryLine` بشكل مستقل.
- يُمنع تعديل `JournalEntryLine` بشكل مستقل.
- يُمنع حذف `JournalEntryLine` بشكل مستقل.
- جميع العمليات على `JournalEntryLine` تتم حصراً من خلال `JournalEntry Aggregate Root`.

---

## Audit Trail
تتضمن الوثيقة بشكل صريح أن `JournalEntry` يحتوي على الحقول التالية لتكوين سجل المراجعة (Audit Trail) الرسمي:
- `created_by`
- `posted_by`
- `reversed_by`
- `created_at`
- `posted_at`
- `reversed_at`

وتعتبر هذه البيانات جزءاً لا يتجزأ من سجل المراجعة، ولا يجوز تعديلها أبداً بعد تسجيلها.

---

## Immutability Rules
بمجرد تحول حالة القيد إلى `Posted`، تصبح الحقول التالية **Immutable** (غير قابلة للتعديل أو الحذف نهائياً):
- `journal_number` (الرقم التسلسلي للقيد)
  - يبقى `Journal Number` ثابتاً حتى بعد تنفيذ `Reverse`.
  - لا يتم إعادة ترقيم القيود نهائياً.
  - لا يعاد استخدام أي `Journal Number` مهما كانت الظروف.
  - القيد العكسي (`Reverse Journal`) يحصل دائماً على `Journal Number` جديد ومستقل.
- `posting_date` (تاريخ الترحيل)
- `currency_id` ورمز العملة (Currency Snapshot)
- `exchange_rate` (Exchange Rate Snapshot اللحظي)
- `JournalEntryLines` (كافة الأطراف المرتبطة بالقيد)
- جميع الـ `Amounts` (المدين والدائن)
- `document_type`, `document_id`, `document_number` (بيانات المستند المصدري)

---

## Reverse Relationship & Rules
تعتمد الوثيقة مرجعاً واحداً فقط للعكس وهو: `original_journal_id` (ولا تعتمد `reversed_by_id`).
- القيد الأصلي لا يحتوي قيمة في هذا الحقل.
- القيد العكسي فقط يشير إلى `original_journal_id`.
- كل `Reverse Journal` يجب أن يرتبط بقيد أصلي واحد فقط.
- كل `JournalEntry` يمكن أن يمتلك `Reverse` واحداً فقط.
- يمنع إنشاء أكثر من `Reverse` لنفس القيد (`JournalEntry`).
- القيد الأصلي لا يتم تعديله عند تنفيذ `Reverse`.
- يتم إنشاء `JournalEntry` جديد بالكامل يعكس القيود الأصلية.

---

## Dependencies
الكيان `JournalEntry` يعتمد بشكل رسمي على:
- `Business` (Core Domain)
- `FiscalPeriod` (Finance Domain)
- `Posting Engine` (Finance Domain - كمدير لإنشائه)
- `JournalEntryLine` (Finance Domain - مكون داخلي للـ Aggregate)
- `ChartOfAccount` (Finance Domain)
- `ExchangeRate` (Finance Domain)

*(أي Dependency آخر يعتبر غير معتمد للإصدار V1).*

---

## Out Of Scope
الميزات التالية خارج إطار `JournalEntry` للإصدار الأول (V1):
- **Approval Workflow:** مسارات الاعتماد والموافقات المعقدة.
- **Recurring Journal:** القيود الدورية أو المكررة آلياً.
- **Auto Posting:** الترحيل التلقائي المجدول.
- **Async Posting:** الترحيل في الخلفية أو باستخدام الطوابير (Queues).
- **Closing Entries:** قيود إقفال السنة المالية المؤتمتة بشكل معقد.
- **Accrual Journals:** قيود الاستحقاق العكسية الآلية (Auto-Reversing Accruals).
- **Bank Reconciliation:** التسويات البنكية الآلية.
