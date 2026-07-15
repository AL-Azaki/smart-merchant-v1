# Payments Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الموحد لنطاق المدفوعات (Payments Domain) في نظام Smart Merchant ERP. الغرض منها هو تحديد القواعد والمبادئ الصارمة للتعامل مع حركات الدفع والقبض، وتسوية الالتزامات المالية، وضمان عزل هذا النطاق عن النطاقات الأخرى مثل المبيعات والمشتريات لتمكينه من التوسع والمرونة.

---

## 2. Scope
يغطي هذا الدستور المعماري كافة الأنشطة المتعلقة بالمدفوعات داخل المنصة، وتشمل:
- Customer Payments (مقبوضات العملاء).
- Supplier Payments (مدفوعات الموردين).
- Internal Payments (المدفوعات والمقبوضات الداخلية، مثل المصروفات التشغيلية).
- Refunds (Future) (المستردات).
- Online Payments (Future) (التسويات الآتية من بوابات الدفع الإلكتروني).

---

## 3. Domain Responsibilities
تنحصر مسؤوليات نطاق Payments في الآتي:
- تسجيل عمليات الدفع والقبض (سندات القبض والصرف).
- تسوية الالتزامات المالية للعملاء والموردين.
- توزيع مبالغ المدفوعات (Allocation) على المستندات المالية المستحقة (كالفواتير).
- إنشاء وبث أحداث المجال (Domain Events) الخاصة بالدفع لتعلم بها باقي النطاقات.

---

## 4. Domain Boundaries
لضمان الفصل المعماري السليم، يُمنع على نطاق Payments القيام بالآتي:
- لا يصدر فواتير مبيعات أو مشتريات.
- لا يحسب الضرائب أو يتدخل في نسبها.
- لا يدير المخزون ولا يؤثر عليه.
- لا ينشئ القيود المحاسبية مباشرة في قاعدة البيانات.
- لا يدير بيانات العملاء أو الموردين الأساسية (تدار في ה-Core/Finance).

---

## 5. Domain Principles
- **Payment Independent:** المدفوعات كيانات مستقلة بذاتها وليست تابعة لجدول الفاتورة.
- **Immutable Payment History:** بمجرد اعتماد الدفعة، تصبح سجلاتها غير قابلة للتعديل أو الحذف، ويتم التراجع عنها عبر القيود العكسية (Reversals).
- **Settlement Oriented:** الهدف الأساسي للمدفوعات هو تسوية الالتزامات وتصفير الأرصدة المعلقة.
- **Tenant Aware:** جميع المدفوعات مقيدة بسياق الـ Tenant والـ Business.
- **Auditable:** مسار تدقيق كامل لكل حركة دفع وتسوية.
- **Event Driven:** يتواصل النطاق مع النطاقات الأخرى عبر الأحداث حصراً لضمان فك الارتباط (Decoupling).

---

## 6. Aggregate Roots
يحتوي نطاق المدفوعات على الـ Aggregate Roots المتوقعة التالية:
- **Payment:** الكيان الرئيسي الذي يمثل الحركة المالية (القبض أو الدفع) والمبلغ الإجمالي وطريقة الدفع.
- **Payment Allocation:** الكيان المسؤول عن توزيع مبلغ الـ Payment على مستند مالي محدد.

---

## 7. Entity Ownership
تسلسل الملكية والارتباط المنطقي للكيانات:
Payment (يمثل أصل الحركة المالية الإجمالية)
↓
Payment Allocation (يمثل تفاصيل توزيع هذا المبلغ الإجمالي على مستند أو عدة مستندات)
*(الـ Payment يملك الـ Allocations التابعة له بالكامل).*

---

## 8. Lifecycle Principles
دورة حياة الدفعة (Payment) مقيدة بالمسار التالي:
**Draft** (مسودة - قيد الإنشاء أو لم تعتمد بعد) ➔ **Posted** (مُرحلة - تم اعتمادها وإرسالها للمحاسبة) ➔ **Reversed** (معكوسة - تم التراجع عنها محاسبياً وإلغاء تأثيرها).
*(لا يُسمح بالانتقال من Reversed إلى Posted، بل يجب إنشاء Payment جديد).*

---

## 9. Allocation Principles
- **Allocation Responsibility:** `Payment Allocation` هو المسؤول الوحيد والأساسي عن ربط المدفوعات بالمستندات المالية (سواء كانت فاتورة مبيعات، فاتورة مشتريات، أو مستندات مستقبلية مثل الذمم). هذا المبدأ يجعل كيان `Payment` عاماً ومستقلاً تماماً، ويحصر تفاصيل التسوية في الـ Allocation، مما يضمن مرونة وقابلية عالية للتوسع مستقبلاً.
- **Invoice Allocation:** القدرة على سداد فاتورة بالكامل.
- **Partial Allocation:** سداد جزء من الفاتورة.
- **Multiple Allocation:** توزيع دفعة واحدة كبيرة على عدة فواتير في نفس الوقت.
- **Unallocated Balance:** القدرة على تسجيل دفعة تفوق قيمة المستندات المفتوحة، وترك الباقي كرصيد غير موزع (يُستخدم لاحقاً أو يُعتبر دفعة مقدمة).

---

## 10. Currency Principles
- العلاقة مع Finance تضمن توافق المدفوعات مع العملات.
- يدعم النطاق تعدد العملات (دفع فاتورة بعملة وربما التسوية بعملة أخرى بناءً على سعر الصرف).
- نطاق Payments لا ينفذ عمليات تحويل العملات بنفسه، بل يعتمد على `Shared Value Objects` وخدمات ה-Finance للحصول على القيم المكافئة.

---

## 11. Accounting Relationship
العلاقة مع Finance Domain:
- نطاق Payments لا يحتوي على محرك محاسبي (No Accounting Engine).
- يعتمد بالكامل وبشكل حصري على واجهة ה-Posting Engine (عبر ה-Contracts) التابع لـ Finance لترجمة الدفعة (Posted Payment) إلى قيود يومية مزدوجة.

---

## 12. Sales Relationship
العلاقة مع Sales Domain:
- المبيعات تستمع لأحداث ה-Payments (مثل `PaymentAllocatedToInvoice`) لتحديث حالة الدفع للفاتورة (Paid, Partially Paid).
- نطاق Payments يقرأ بيانات הפاتورة من ה-Read Models للتحقق من الرصيد المتبقي قبل قبول الـ Allocation.

---

## 13. Purchasing Relationship
العلاقة مع Purchasing Domain:
- المشتريات تستمع لأحداث ה-Payments لتحديث حالة الدفع لفواتير الموردين.
- نطاق Payments يقرأ قيمة الفاتورة المستحقة للتحقق قبل عملية الدفع (Payment Allocation).

---

## 14. Receivables Relationship (Future)
- يتكامل نطاق Payments في المستقبل مع إدارة الذمم المدينة (Accounts Receivable) لتسوية أرصدة العملاء التراكمية، ومتابعة أعمار الديون بناءً على ה-Allocations.

---

## 15. Payables Relationship (Future)
- يتكامل نطاق Payments مع إدارة الذمم الدائنة (Accounts Payable) لتسوية مطالبات الموردين، وإدارة التوزيعات المعقدة للمدفوعات الآجلة.

---

## 16. Notification Relationship
العلاقة مع Notification Platform:
- يطلق نطاق Payments الأحداث التي تلتقطها منصة الإشعارات لإرسال سندات القبض أو تأكيدات الدفع للعملاء عبر البريد الإلكتروني أو ה-SMS.

---

## 17. Background Processing Relationship
العلاقة مع Background Processing Platform:
- العمليات الثقيلة المرتبطة بالمدفوعات (مثل استيراد دفعات جماعية من كشف بنكي) تُنفذ كمهام خلفية لضمان عدم حجب ה-API.
- عمليات إعادة المحاولة (Retries) للمزامنة مع بوابات الدفع تدار هنا.

---

## 18. Reporting Relationship
العلاقة مع Reporting Platform:
- يوفر نطاق Payments هيكل بيانات مبسط للـ Read Models ليُمكّن منصة التقارير من توليد كشوف المقبوضات والمدفوعات اليومية بدقة عالية.

---

## 19. API Relationship
العلاقة مع Platform API:
- يخضع نطاق Payments بالكامل لمعايير ה-API Contract لتوحيد أشكال الردود والأخطاء، وتمرير ה-Correlation IDs.

---

## 20. Offline Relationship
العلاقة مع Offline First:
- يمكن لأجهزة ה-POS إنشاء `Draft Payments` وحفظها محلياً في حال انقطاع الشبكة.
- تُنقل للـ Server عند المزامنة حيث يطبق عليها الـ Posting Engine لترحيلها بشكل رسمي.

---

## 21. Synchronization Relationship
العلاقة مع Data Synchronization:
- تخضع حركات الدفع لإستراتيجية التحديث التفاضلي (Incremental Sync) لضمان دقة أرصدة العملاء في الأجهزة المحلية فور نجاح الدفع المركزي.

---

## 22. Security Principles
- **Authorization:** التأكد من صلاحية الموظف (الكاشير، المحاسب) لإنشاء سند قبض أو دفع.
- **Ownership Validation:** التحقق من أن الدفعة تنتمي إلى العميل والمستند الخاصين بنفس ה-Tenant والـ Business.
- **Duplicate Prevention:** تطبيق آلية حماية صارمة لمنع تسجيل نفس عملية الدفع مرتين متتاليتين (Idempotency).

---

## 23. Audit Principles
المساءلة القصوى لأي حركة نقدية، يجب أن تكون العمليات التالية قابلة للتتبع الكامل:
- Create Payment
- Post Payment
- Reverse Payment
- Allocate Payment
- Unallocate Payment

---

## 24. Platform Responsibilities
- **Client (Mobile/Web):** جمع بيانات الدفع ورفع الطلب بأمان للـ API.
- **API:** التحقق من هيكل الطلب وصلاحياته وتوجيهه للـ Domain.
- **Payments Domain:** تطبيق قواعد التسوية، وإنشاء الدفعة، وإطلاق الأحداث.
- **Finance Domain:** الاستماع لطلب الترحيل (Posting) وبناء القيود المحاسبية.

---

## 25. Dependencies
يعتمد الدستور المعماري للمدفوعات على:
- `Platform_Architecture.md`
- `System_Domain_Events_Foundation_Architecture.md`
- `Financial_Documents_Foundation_Architecture.md`
- `Shared_Value_Objects_Foundation_Architecture.md`
- `Finance Domain Architecture`
- `Sales Domain Architecture`
- `Purchasing Domain Architecture`

---

## 26. Out Of Scope
يخرج عن إطار هذه الوثيقة التفاصيل التنفيذية التالية:
- بوابات الدفع الإلكتروني (Payment Gateway).
- التكامل التقني مع (Stripe, PayPal, Mada, Apple Pay, Google Pay).
- الربط البنكي المباشر (Bank Integration).
- نظام الدفع بالاشتراكات (Subscription Billing).
- المحافظ الإلكترونية (Wallet).
- أنظمة الولاء والنقاط (Loyalty).
- عمليات البيع بالتقسيط (Installments).
- تفاصيل سير عمل المستردات (Refund Workflow Details).
