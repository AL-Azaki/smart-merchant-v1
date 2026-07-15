# JournalEntryLine Architecture

**Status:** APPROVED  
**Version:** 1.1  
**State:** FROZEN  

---

## Purpose
يمثل `JournalEntryLine` (طرف القيد المحاسبي) الوحدة الذرية التي تحمل الأثر المالي المباشر على الحسابات في النظام.
- **ما هو JournalEntryLine:** هو السطر المحاسبي الذي يسجل الحركة المالية المدائنة أو الدائنة لحساب محدد.
- **لماذا يعتبر Child Entity:** لأنه مجرد جزء مكمّل لا يمكنه التعبير عن حركة مالية متوازنة بمفرده، ولا يحمل معنى محاسبي مكتمل إلا كجزء من قيد مزدوج.
- **لماذا لا يعتبر Aggregate Root:** لأنه يعتمد بالكامل في وجوده وإدارته على الكيان الجذري `JournalEntry`.
- **علاقته بـ JournalEntry:** علاقة تبعية مطلقة (Composition)؛ لا يمكن لسطر القيد أن يُوجد، أو يُعدل، أو يُحذف بمعزل عن ترويسة القيد الخاصة به.
- **علاقته بالـ General Ledger:** يعتبر `JournalEntryLine` المُرحّل هو المصدر الأساسي والوحيد لحساب الأرصدة (Balances) في دفتر الأستاذ العام.

---

## Responsibilities
- يمثل طرفاً واحداً (سطراً واحداً) من أطراف القيد المحاسبي.
- يمثل حساباً محاسبياً واحداً فقط (`ChartOfAccount`) في كل سطر.
- يحتوي مبلغاً مالياً واحداً.
- يمثل توجيهاً محاسبياً إما مديناً (`Debit`) أو دائناً (`Credit`).
- لا يستطيع الوجود إطلاقاً بدون قيد أم (`JournalEntry`).
- لا ينشئ نفسه ولا يمتلك آلية ذاتية للحفظ.
- لا يدير دورة حياته بنفسه بل يخضع لدورة حياة القيد الرئيسي.

---

## Entity Classification
- **Classification:** Transactional Data (Child Entity).
- **Ownership:** يتبع حصراً لـ `JournalEntry` (Aggregate Root).
- **Aggregate:** No (مملوك بالكامل لـ JournalEntry).
- **Lifecycle:** توريث كامل من `JournalEntry`.
- **Mutability:** Mutable فقط عندما يكون القيد الأم في حالة `Draft`. يصبح **Immutable** تماماً عند الترحيل.
- **Deletion Strategy:** 
  - `Hard Delete` مسموح فقط أثناء حالة `Draft`.
  - يُمنع الحذف قطعياً (Anti-Delete) بعد الترحيل (`Posted`).
- **Tenant Scope:** يتبع للشركة (`Business Level`) عبر الوراثة من القيد الأم.

---

## Relationships
يقتصر الكيان على العلاقات الرسمية التالية للحفاظ على صلابة الهيكلة:
- **belongsTo:** `JournalEntry` (القيد الأم الذي يملك السطر).
- **belongsTo:** `ChartOfAccount` (الحساب المحاسبي الذي يتأثر بالعملية).

*(لا تُضاف أي علاقة غير معتمدة أو خارج نطاق V1).*

---

## Lifecycle
- **الوراثة المطلقة:** يرث `JournalEntryLine` دورة حياته بشكل كامل من `JournalEntry`.
- **لا دورة حياة مستقلة:** لا يمتلك الكيان أي Lifecycle مستقلة بأي شكل من الأشكال.
- **حالات الترحيل والعكس:** يُعتبر السطر مرحّلاً (`Posted`) بمجرد ترحيل القيد الأم، ويُعتبر منعكساً (`Reversed`) بمجرد عكس القيد الأم.

---

## Business Rules
تُطبق القواعد المعمارية التالية بصرامة:
- كل `Line` يتبع `JournalEntry` واحد فقط.
- كل `Line` يشير إلى `ChartOfAccount` واحد فقط.
- يُمنع قطعياً استخدام الحسابات الرئيسية (`Header Account`) في أي سطر.
- يجب أن يكون الحساب المستخدم مفعلاً (`Active`).
- يجب أن يكون الحساب مصنفاً كحساب ترحيل (`Posting Account`).
- كل `Line` يمثل إما `Debit` أو `Credit` فقط.
- لا يجوز أن تكون قيمتي الـ `Debit` والـ `Credit` أكبر من صفر معاً في نفس السطر.
- يجب أن تكون إحدى القيمتين فقط (إما المدين أو الدائن) أكبر من الصفر.
- يُمنع استخدام القيم السالبة إطلاقاً في تسجيل المبالغ.
- جميع المبالغ يجب أن تستخدم نوع البيانات `DECIMAL` حصراً.
- يحتفظ السطر بنسخة ثابتة (Snapshot) للعملة وسعر الصرف لضمان الاستقلالية التاريخية.
- لا يمكن تعديل أي `Line` بعد تحول القيد الأم إلى `Posted`.
- لا يمكن حذف أي `Line` بعد تحول القيد الأم إلى `Posted`.
- يُمنع إنشاء `Line` بدون ربطه بقيد أساسي `JournalEntry`.

---

## Line Number Policy
- يمتلك كل `JournalEntryLine` رقماً ترتيبياً (`line_number`).
- يبدأ الترقيم من الرقم 1 داخل كل `JournalEntry`.
- يجب أن يكون `line_number` فريداً داخل نفس `JournalEntry`.
- يستخدم فقط للعرض والطباعة وتتبع السطور والمراجعة.
- لا يدخل في أي Business Logic.
- لا يؤثر على أي قاعدة محاسبية.
- يصبح Immutable بعد ترحيل القيد.

---

## Currency Policy
تُدار المبالغ والعملات في السطر المحاسبي عبر الحقول التالية:
- `currency_id`: العملة التي نُفذت بها الحركة في هذا السطر.
- `exchange_rate`: سعر الصرف اللحظي المستخدم للتحويل.
- `foreign_amount`: المبلغ بعملة الحركة الأصلية.
- `base_amount`: المبلغ مُقيّماً بالعملة الأساسية للشركة.

**قاعدة التوازن:**
التوازن المحاسبي للقيد (Double Entry Rule) يعتمد بشكل كلي وحصري على حقل الـ `base_amount`. يُستخدم الـ `foreign_amount` لأغراض التوثيق وعرض قيمة العملية الأصلية ولا يُعتد به للتحقق من توازن القيد.

---

## Currency Consistency Rule
- جميع `JournalEntryLines` التابعة لنفس `JournalEntry` يجب أن تستخدم نفس `currency_id`.
- جميع `JournalEntryLines` التابعة لنفس `JournalEntry` يجب أن تستخدم نفس `exchange_rate`.
- لا يسمح في الإصدار الأول V1 بوجود أكثر من عملة داخل نفس `JournalEntry`.
- تتم جميع عمليات تحويل العملات قبل إنشاء `JournalEntry` بواسطة Posting Engine.
- جميع `JournalEntryLines` ترث بيانات Currency Snapshot الخاصة بالقيد.

---

## Description Policy
- `description` حقل اختياري.
- يمكن لكل سطر أن يمتلك وصفاً مستقلاً.
- إذا لم يتم توفير وصف للسطر يمكن استخدام وصف `JournalEntry`.
- لا يستخدم `description` في أي Business Logic.
- يستخدم فقط للعرض والطباعة والتقارير والمراجعة.

---

## Ownership Rules
- **الكيان الجذري:** يُعتبر `JournalEntry` هو الـ `Aggregate Root`.
- **حصرية العمليات:** جميع العمليات الأساسية (Create, Update, Delete) على أطراف القيد تمر حصراً عبر الـ `JournalEntry`.
- **لا واجهات مستقلة:** لا توجد، ولن تُبنى، أي واجهات برمجة تطبيقات مستقلة (`Standalone API`) لإدارة أو تعديل `JournalEntryLine` بمعزل عن القيد الأم.

---

## Audit Trail
- **وراثة سجل المراجعة:** بما أن الكيان لا يدير نفسه، فإنه يرث سجل المراجعة (Audit Trail) بالكامل من الـ `JournalEntry`.
- **لا دورة منفصلة:** لا يحتاج `JournalEntryLine` إلى حقول لتتبع من قام بالإنشاء أو الترحيل (Created By / Posted By) بشكل مستقل، حيث أن القيد بأكمله يُعتمد كوحدة واحدة.

---

## Immutability Rules
بمجرد تحول حالة القيد الأم إلى `Posted`، تصبح الحقول التالية للسطر المحاسبي ثابتة للأبد (Immutable):
- `journal_entry_id` (مرجعية القيد)
- `chart_of_account_id` (الحساب المتأثر)
- `debit` / `credit` (نوع التوجيه)
- `foreign_amount` (المبلغ الأجنبي)
- `base_amount` (المبلغ الأساسي)
- `currency_id` (العملة)
- `exchange_rate` (سعر الصرف)
- `description` (البيان الخاص بالسطر)

---

## Reverse Policy
- لا يتم تعديل أي `JournalEntryLine` موجود عند تنفيذ Reverse.
- يتم إنشاء `JournalEntry` جديد بالكامل.
- يتم إنشاء `JournalEntryLines` جديدة بالكامل.
- يتم نسخ الحساب المحاسبي كما هو.
- يتم عكس المدين والدائن.
- يتم الاحتفاظ بنفس Currency Snapshot.
- يتم الاحتفاظ بنفس Exchange Rate Snapshot.
- يتم الاحتفاظ بنفس Foreign Amount و Base Amount.
- تبقى جميع `JournalEntryLines` الأصلية كما هي دون أي تعديل.
- تصبح `JournalEntryLines` الجديدة جزءاً من Audit Trail.

---

## Dependencies
يعتمد الكيان المعماري لـ `JournalEntryLine` رسمياً وحصرياً على:
- `JournalEntry` (الكيان المالك والجذري).
- `ChartOfAccount` (الدليل المحاسبي).
- `ExchangeRate` (أسعار الصرف المستخدمة لحساب المبالغ).

---

## Out Of Scope
الميزات التالية تعتبر متقدمة ومستبعدة تماماً من `JournalEntryLine` في الإصدار الأول (V1):
- **Split Allocation:** توزيع السطر الواحد على حسابات متعددة.
- **Cost Centers:** مراكز التكلفة.
- **Dimensions:** الأبعاد المحاسبية والتحليلية.
- **Projects:** ربط الأطراف بمشاريع.
- **Budgets:** ربط السطور بالموازنات التقديرية.
- **Analytical Accounting:** المحاسبة التحليلية المتقدمة.
- **Recurring Lines:** السطور المكررة برمجياً.
- **Auto Generated Lines:** السطور المولدة آلياً خارج نطاق Posting Engine.
- أي ميزة أو مكون تشغيلي خارج إطار الإصدار V1.
