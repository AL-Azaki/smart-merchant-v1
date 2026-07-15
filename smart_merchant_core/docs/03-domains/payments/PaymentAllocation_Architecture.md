# PaymentAllocation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري لكيان الـ `PaymentAllocation` بصفته كياناً تابعاً (Child Entity) داخل نطاق المدفوعات (Payments Domain). الغرض منها هو ترسيخ مبدأ فصل عملية استلام الأموال الإجمالية عن تفاصيل تسويتها الدقيقة، مما يمنح النظام مرونة فائقة لربط وتوزيع الدفعة الواحدة على أي نوع من المستندات المالية في الحاضر والمستقبل.

---

## 2. Responsibilities
يتحمل كيان `PaymentAllocation` المسؤوليات الحصرية التالية:
- **تمثيل توزيع جزء أو كامل مبلغ الدفع:** يعبر هذا الكيان عن مقدار الأموال المقتطعة من الدفعة الأصلية.
- **ربط الدفع بمستند مالي:** يمثل حلقة الوصل الوحيدة (Link) بين الدفعة (Payment) والمستند المالي المستحق.
- **دعم الدفع الجزئي:** توثيق تسديد جزء محدد من قيمة المستند المالي فقط.
- **دعم توزيع دفعة واحدة على عدة مستندات:** يسمح للدفعة بامتلاك عدة Allocations، كل منها يسدد مستنداً مستقلاً.

---

## 3. Entity Classification
- **Classification:** Child Entity.
- هذا الكيان ليس (Aggregate Root)، وبالتالي لا يُستعلم عنه ولا يُعدل بمعزل عن الـ `Payment` المالك له.

---

## 4. Relationships
الارتباط المنطقي للكيان:
**Payment** (المالك الحصري - Aggregate Root)
↓
**PaymentAllocation** (الكيان التابع)
↓
**Financial Document** (المستند المالي المستهدف)

يرتبط هذا الكيان במستند مالي بطريقة مجردة وعامة (Reference ID & Document Type)، دون الالتزام بنوع محدد כجدول مبيعات أو مشتريات.

---

## 5. Lifecycle
- دورة حياة الـ `PaymentAllocation` تتبع حرفياً وفيزيائياً دورة حياة الـ `Payment` المالك له.
- لا يمكن أن يعيش مستقلاً، ولا توجد له حالة (Status) منفصلة عن حالة الدفعة الأصلية.
- يُنشأ كـ `Draft` عند إنشاء הדفعة، ويصبح معتمداً عندما تُرحّل הדفعة (`Posted`)، ويُلغى أثره إذا انعكست הדفعة (`Reversed`).

---

## 6. Business Rules
- لا يمكن إنشاء `Allocation` بدون `Payment` مالك.
- يجب ألا يتجاوز مجموع مبالغ كافة الـ `Allocations` التابعة לنفس הـ `Payment` إجمالي مبلغ الدفعة الأساسي (إمكانية وجود Unallocated Balance مسموحة).
- لا يمكن تعديل بيانات الـ `Allocation` (كالمبلغ أو المستند المستهدف) إطلاقاً بعد تحول الـ `Payment` إلى `Posted`.
- لا يمكن إضافة أي `Allocation` جديد بعد أن يصبح ה-`Payment` في حالة `Reversed`.
- لا يمكن حذف `Allocation` منفرداً بعد الترحيل، المعالجة الوحيدة هي عكس הדفعة بالكامل.

---

## 7. Allocation Policy
المبادئ الأساسية للتسوية تشمل:
- **Partial Allocation:** تخصيص مبلغ أقل من المستحق في المستند، مما يبقيه مفتوحاً (Partially Paid).
- **Full Allocation:** تخصيص مبلغ يطابق تماماً رصيد المستند لجعله مسدداً (Fully Paid).
- **Multiple Allocation:** إنشاء عدة `PaymentAllocations` تحت `Payment` واحد لتسديد مجموعة مستندات.
- **Remaining Balance:** المتبقي من ה-Payment الذي لم يُغطِ به أي `Allocation` يُعتبر رصيداً غير موزع (Unallocated).

---

## 8. Financial Document Policy
- **المبدأ العام:** يرتبط ה-`PaymentAllocation` بمفهوم ה-`Financial Document` كمفهوم معماري مجرد (Abstract Reference).
- لا يرتبط بجدول الفواتير (SalesInvoice أو PurchaseInvoice) ارتباطاً صلباً.
- هذه المرونة تمكّن المنصة مستقبلاً من استقبال وتخصيص المدفوعات على مستندات أخرى مثل:
  - فواتير المبيعات (Sales Invoices).
  - فواتير المشتريات (Purchase Invoices).
  - مطالبات الذمم المدينة (Receivables).
  - تسويات الذمم الدائنة (Payables).
  - أي مستند مالي قد يُستحدث في النطاقات التجارية.

---

## 9. Currency Policy
- **العملة تتبع Payment:** العملة المسجلة في ה-`PaymentAllocation` هي نفسها عملة ה-`Payment` الأصلية.
- **لا يتم التحويل داخل Allocation:** الـ Allocation لا ينفذ عمليات تحويل أسعار الصرف. إذا كان المستند المالي بعملة أخرى، تتم المطابقة أو حساب فروق العملة عبر أدوات ה-Finance لاحقاً، ولا يتحمل الـ Allocation هذا العبء.

---

## 10. Ownership Rules
- **المالك الوحيد:** `Payment` هو المالك الوحيد والقاطع לـ `PaymentAllocation`.
- لا يمكن نقل ملكية `Allocation` من دفعة إلى دفعة أخرى أبداً.

---

## 11. Audit Trail
الـ `PaymentAllocation` يرث التدقيق من ה-`Payment` ولكن يجب تسجيل تفاصيله بدقة:
- المبلغ المخصص.
- رقم ونوع المستند المالي المستهدف (Financial Document Reference).
- وقت إجراء التخصيص.
- إذا أُلغي التخصيص عبر عكس الدفعة (Reversal)، يُسجل الحدث لتسوية المستند المتأثر.

---

## 12. Immutability Rules
- ה-`PaymentAllocation` يصبح غير قابل للتعديل (Immutable) برمجياً بمجرد तرحيل الـ `Payment` إلى `Posted`.
- أي محاولة لتغيير قيمة التوزيع أو المستند بعد الترحيل تعتبر مخالفة معمارية خطيرة وتهدد سلامة القيود المحاسبية.

---

## 13. Dependencies
يعتمد هذا الكيان معمارياً ويتأثر بـ:
- `Payment_Architecture.md`
- `Payments_Foundation_Architecture.md`
- `Financial_Documents_Foundation_Architecture.md`
- `Platform_Architecture.md`

---

## 14. Out Of Scope
يخرج عن نطاق ومسؤولية `PaymentAllocation` العمليات التالية:
- واجهات أو بوابات الدفع الإلكتروني (Payment Gateway).
- إدارة وتوزيع الأقساط (Installments).
- سير عمل المرتجعات المالية (Refund Workflow).
- التسويات البنكية (Bank Settlement).
- تحويل العملات وحساب فروق العملة (Currency Conversion).
- إنشاء قيود اليومية (Accounting Posting - مسؤولية ה-Finance).
