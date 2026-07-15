# Finance General Ledger Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## Purpose
هذه الوثيقة تمثل المرجع المعماري الرسمي لمحرك دفتر الأستاذ العام (General Ledger) داخل `Finance Domain` في نظام Smart Merchant ERP للإصدار الأول (V1). قبل البدء في تنفيذ أي كيانات متعلقة بالقيود المحاسبية مثل `JournalEntry` أو `JournalEntryLine` أو `Payment`، تعتبر هذه الوثيقة المرجع النهائي والحصري لجميع عمليات إنشاء وترحيل القيود المحاسبية داخل النظام.

---

## Scope
تشمل هذه الوثيقة تصميم الجوانب المعمارية التالية:
- General Ledger Responsibilities
- Posting Engine
- Posting Workflow
- Validation Pipeline
- Atomic Transaction Strategy
- Journal Number Strategy
- Source Document Mapping
- Posting Ownership
- Error Handling Strategy
- Reverse Strategy
- Performance Strategy
- Integration Strategy
- Security Rules

لا تشمل الوثيقة أي تنفيذ برمجي للكيانات (No Code Implementation).

---

## 1. General Ledger Responsibilities
يمثل دفتر الأستاذ العام (General Ledger) القلب النابض للنظام المالي والمستودع المركزي لجميع الحركات المحاسبية.

- **Single Source of Truth:** هو المصدر الأوحد والوحيد لجميع الأرصدة. لا يوجد أي كيان آخر داخل النظام (مثل الخزائن أو البنوك أو العملاء أو الموردين) يقوم بتخزين الأرصدة كقيمة ثابتة.
- **Balance Calculation:** جميع أرصدة الحسابات تُحسب ديناميكياً حصراً من الحركات المحلّلة داخل الـ General Ledger بناءً على القيود المُرحلة (`Posted Journal Entries`).
- **Financial Integrity:** يضمن توازن النظام المالي من خلال تطبيق قاعدة القيد المزدوج (Double Entry) حيث يتساوى مجموع الجانب المدين مع مجموع الجانب الدائن بشكل دائم في جميع الحركات.
- **Reporting Foundation:** يعتبر حجر الأساس الذي تُبنى عليه كافة القوائم المالية (ميزان المراجعة، الأرباح والخسائر، الميزانية العمومية).
- **سياسة الدقة الحسابية:**
  - يُمنع قطعياً استخدام `float` أو `double`.
  - جميع القيم المالية يجب أن تستخدم نوع `DECIMAL` حصراً.
  - جميع عمليات التحقق من التوازن تعتمد على `DECIMAL`.
  - يُمنع استخدام العمليات الحسابية ذات الفاصلة العائمة داخل الـ Posting Engine.

---

## 2. Posting Engine
محرك الترحيل (Posting Engine) هو المكون البرمجي المعني بترجمة العمليات التشغيلية إلى قيود محاسبية فعلية.

- **مسؤوليته:** تحويل البيانات القادمة من مستندات المصدر إلى قيود محاسبية متوازنة، وتطبيق جميع قواعد التحقق قبل اعتمادها في قاعدة البيانات.
- **من يملك حق استدعائه:** يُستدعى فقط بواسطة الـ Use Cases المرخصة داخل الـ Finance Domain، أو عبر Integration Services قادمة من الـ Domains الأخرى التي تم تكوين قواعد الترحيل لها.
- **من يُمنع من استدعائه:** يُمنع استدعاؤه بشكل مباشر من طبقات الـ UI Controllers أو من أي Domain آخر.
- **Single Entry Point:** يعتبر المحرك البوابة الوحيدة لإنشاء القيود. لا يُسمح بأي إدخال مباشر في جداول قواعد البيانات للقيود.
- **سياسة الـ Idempotency:**
  - يجب أن يكون الـ Posting Engine `Idempotent`.
  - أي مستند تشغيلي لا يمكن أن ينتج أكثر من `Journal Entry` مرحل واحد.
  - إذا تمت إعادة استدعاء عملية الترحيل لنفس المستند: لا يتم إنشاء قيد جديد، لا يتم إنشاء Journal Lines جديدة، ولا يتكرر الأثر المحاسبي.

---

## 3. Posting Workflow
دورة الترحيل تتميز بالتسلسل الصارم للعمليات لضمان عدم إنشاء أي قيد به خلل.

### 3.1. دورة حياة القيود (Journal Status)
الحالات الرسمية لـ `Journal Entry` تقتصر على:
- `Draft`
- `Posted`
- `Reversed`

**الانتقالات المسموح بها:**
- `Draft` → `Posted`
- `Posted` → `Reversed`

**الانتقالات الممنوعة:**
- `Posted` → `Draft`
- `Reversed` → `Posted`
- `Reversed` → `Draft`

*(يُمنع إضافة حالات أخرى مثل Pending, Approved, Cancelled).*

### 3.2. الفصل بين التواريخ
كلا التاريخين إلزاميان ويجب التفريق بينهما:
- **Document Date:** تاريخ المستند التشغيلي الفعلي.
- **Posting Date:** تاريخ ترحيل القيد المحاسبي للتأثير على الأرصدة.

### 3.3. خطوات الترحيل (Workflow Steps)
1. **Create Draft:** استقبال تفاصيل الحركة وتكوين مسودة أولية في الذاكرة.
2. **Validate:** فحص البيانات الأساسية للحركة.
3. **Check Fiscal Period:** التأكد من أن `Posting Date` يقع ضمن فترة مالية مفتوحة تابعة لـ Business.
4. **Check Accounts:** التأكد من أن الحسابات موجودة، مفعلة، ومصنفة كـ Posting Accounts.
5. **Check Balance:** فحص قاعدة القيد المزدوج لضمان التوازن بـ `base_amount`.
6. **Create Journal Entry:** إدخال بيانات الترويسة الرئيسية.
7. **Create Journal Entry Lines:** إدخال أطراف القيد المزدوج وربطها بالترويسة.
8. **Post:** تغيير حالة القيد إلى `Posted`.
9. **Commit:** إغلاق عملية قاعدة البيانات (DB Transaction) لاعتماد البيانات نهائياً.

---

## 4. Validation Pipeline
لضمان الدقة المطلقة، تمر كل مسودة قيد بسلسلة من التحققات الإلزامية:
- **Fiscal Year & Period:** يجب أن يكون التاريخ المالي صالحاً وداخل فترة مفتوحة.
- **Accounts Validity:** لا يقبل الترحيل على حساب رئيسي (Header Account)، ويجب أن تكون الحسابات مفعلة (Active).
- **Tenant Scope Isolation:** جميع الحسابات والفترات والعملات يجب أن تنتمي لنفس الـ `business_id`.
- **Exchange Rate & Currency:** التحقق من وجود العملات وصلاحية التحويل إلى العملة الأساسية للشركة.
- **Document Reference Integrity:** المستند المصدر يجب ألا يكون قد رُحِّل له قيد سابق (Idempotency).
- **Double Entry Rule:** الرفض القطعي لأي قيد فيه فرق بين إجمالي المدين والدائن في حقل الـ `base_amount`.

---

## 5. Atomic Transaction Strategy
تطبق معمارية الـ General Ledger سياسة الترابط الكامل باستخدام (Atomic DB Transactions):

- **All or Nothing:** إما أن تنجح كافة الخطوات وتُحفظ (Commit) أو يتم إجهاض العملية كلياً وإلغاء التغييرات (Rollback).

**ترتيب الأقفال (Locking Order) لتقليل الـ Deadlocks:**
يجب اتباع الترتيب المنطقي التالي داخل الـ Transaction:
1. التحقق من Fiscal Period.
2. قفل Fiscal Period.
3. قفل مولد أرقام القيود.
4. توليد Journal Number.
5. إنشاء Journal Header.
6. إنشاء Journal Lines.
7. تغيير الحالة إلى `Posted`.
8. Commit.

---

## 6. Journal Number Strategy
- **متى يولد الرقم:** يُولد أثناء عملية الـ `Posting` اللحظة الأخيرة قبل حفظ القيد لمنع الفجوات.
- **النوع:** يجب أن يكون متسلسلاً (Sequential Numbering).
- **عدم التعديل:** الرقم غير قابل للتعديل بمجرد الحفظ.
- **منع إعادة الاستخدام:** لا يُعاد استخدام أي رقم قيد إطلاقاً.

---

## 7. Source Document Mapping
يربط كل قيد بالعملية التشغيلية التي أنتجته باستخدام حقول المرجعية (`document_type`, `document_id`, `document_number`).

**ملكية مصدر القيد:**
- يجب أن يرتبط كل `Journal Entry` بمصدر واحد فقط (مثال: Sales Invoice, Purchase Invoice, Payment, Inventory Adjustment).
- يُمنع منعاً باتاً وجود `Journal Entry` بدون مصدر.
- **الاستثناء الوحيد:** هو القيد اليدوي (`Manual Journal`).

---

## 8. Posting Ownership
- **الملكية الحصرية:** الـ Finance Domain (وتحديداً Posting Engine) هو المالك الوحيد لإنشاء `JournalEntry` و `JournalEntryLine`.
- **المنع العابر للنطاقات:** يُمنع على النطاقات الأخرى محاولة إدخال بيانات مباشرة في الجداول المحاسبية.

**سياسة Manual Journal:**
- الـ Manual Journal يستخدم نفس `Posting Engine` بالكامل.
- لا يمتلك أي مسار خاص أو استثنائي.
- يخضع لنفس خطوط التحقق (Validation Pipeline, Fiscal Period, Double Entry, إلخ).
- لا يُسمح له بأي تجاوز للقواعد.

---

## 9. Error Handling Strategy
- **متى يتم رفض العملية:** يُرفض الترحيل فوراً عند إخفاق أي نقطة في مسار التحقق.
- **التعامل مع الأخطاء:** إطلاق استثناء واضح (`ValidationException`) وتطبيق `DB::rollBack()` للحماية.
- **فشل طرف القيد:** إذا فشل إدخال أي `JournalEntryLine`، يفشل القيد بكامله بناءً على قواعد Atomic Transaction.

---

## 10. Reverse Strategy
- **الجمود بعد الترحيل (Immutability):** يُمنع تماماً التعديل أو الحذف الفعلي لأي قيد أخذ حالة `Posted`.
- **استراتيجية الإلغاء (Reverse Journal):** يعالج القيد الخاطئ بإنشاء قيد محاسبي جديد كلياً يعاكس القيد الأصلي في الأطراف لتصفير الأثر المالي، مع ربط القيد العكسي برقم القيد الأصلي.
- **سياسة Snapshot للعملات:**
  - كل قيد مرحّل يجب أن يحتفظ بشكل دائم بالحقول: `currency_id`, `exchange_rate`, `foreign_amount`, `base_amount`.
  - بعد الترحيل تصبح هذه القيم `Immutable`.
  - لا يتم الرجوع إلى جدول أسعار الصرف مرة أخرى لهذا القيد.
  - أي تعديل مستقبلي على أسعار الصرف لا يؤثر نهائياً على القيود السابقة.

---

## 11. Performance Strategy
الإصدار الأول (V1) مُصمم للموثوقية المطلقة للأرصدة:
- **لا أرصدة مخبأة (No Cached Balances):** يتم استخراج الأرصدة بالاستعلام المباشر اللحظي من `journal_entry_lines`.
- **التنفيذ المتزامن (No Async Posting):** عملية الترحيل تتم بشكل لحظي ومتزامن في نفس دورة الـ HTTP Request.

---

## 12. Integration Strategy
يعمل محرك الترحيل كمزود خدمة (Service Provider) للكيانات التشغيلية:
- **Sales & Purchasing & Inventory:** تقوم النطاقات بجمع الأطراف المحددة وإرسال DTO إلى الـ Finance Domain لترحيل القيد.
- **Payments:** تمر بشكل طبيعي عبر הـ Posting Engine لترحيل الدفعة.

---

## 13. Security Rules
- منع تجاوز الـ Posting Engine و الـ Business Rules لإنشاء أي قيود.
- منع تعديل أو حذف أي `Posted Journal`.
- جميع العمليات تمر عبر قواعد الترحيل الصارمة لحماية القيود المزدوجة.

---

## 14. Out Of Scope
الميزات التالية تعتبر خارج نطاق الإصدار الأول (V1) ولا يجوز إضافتها:
- Async Posting
- Queue
- Event Bus
- Workflow Approval
- Distributed Transactions
- Recurring Journals
- Bank Reconciliation
- Closing Engine
- Accrual Engine
- Background Workers
- Auto Posting Scheduler