# Finance Domain Planning

## 1. Executive Summary

يعتبر النطاق المالي (Finance Domain) القلب النابض لنظام `Smart Merchant ERP`. يتمثل الهدف الاستراتيجي لهذا النطاق في تسجيل، تتبع، وتدقيق كافة الآثار المالية الناتجة عن الأنشطة التشغيلية في النظام. يتحمل ה-Finance Domain المسؤولية الكاملة عن نزاهة البيانات المحاسبية، وتوفير صورة دقيقة ولحظية للمركز المالي للشركات (Tenants). وهو بمثابة النقطة المركزية التي تصب فيها جميع العمليات المكتملة من باقي الـ Domains لترجمتها إلى لغة محاسبية بحتة.

---

## 2. Scope

**يدخل ضمن نطاق ה-Finance Domain:**
- إدارة شجرة الحسابات (Chart of Accounts).
- تسجيل القيود اليومية (Journal Entries).
- إدارة الحركات المالية (مقبوضات ومدفوعات).
- إدارة الخزائن والحسابات البنكية.
- إدارة السنوات المالية والفترات المحاسبية.
- إدارة أسعار الصرف (Exchange Rates).
- إدارة الضرائب.

**يخرج عن نطاق ה-Finance Domain:**
- العمليات التشغيلية المباشرة (مثل بيع وشراء البضائع، إدارة المخزون، أو إدارة شؤون الموظفين) حيث تظل هذه العمليات ضمن نطاقاتها، ويقتصر دور ה-Finance على استلام الأثر المالي فقط.

---

## 3. Business Objectives

تم تصميم Finance Domain لتحقيق الأهداف التجارية التالية:
- **تسجيل القيود اليومية:** توثيق كل حركة مالية بأسلوب محاسبي دقيق.
- **إدارة الحسابات:** التحكم الشامل بشجرة الحسابات، الأرصدة، والحسابات الختامية.
- **إدارة الخزائن:** تتبع النقدية المتاحة في فروع الشركة المختلفة.
- **إدارة الحسابات البنكية:** تتبع الأرصدة البنكية وحركات التحويل والودائع.
- **إدارة السنوات المالية:** فتح وإغلاق الفترات المالية وترصيد الحسابات.
- **إدارة العملات:** تتبع أسعار الصرف المتغيرة للعملات الأجنبية.
- **الإقفال المالي (Financial Closing):** إغلاق الفترات المالية (شهري/سنوي) وترصيد الحسابات لمنع التعديل بأثر رجعي.
- **التقارير المالية:** توفير مخرجات دقيقة كالميزانية العمومية، قائمة الدخل، وميزان المراجعة.

---

## 4. Domain Boundaries

يتقاطع Finance Domain مع باقي النطاقات كالتالي:
- **Core Domain:** يعتمد ה-Finance على Core Domain للحصول على البيانات الأساسية مثل الحسابات (Tenants)، الشركات (Businesses)، الفروع (Branches)، والعملات (Currencies). اتجاه الاعتماد أحادي: Core → Finance. لا يعتمد Core Domain على Finance ولا يستهلك بياناته.
- **Sales Domain:** يستقبل ה-Finance الأثر المالي لفواتير المبيعات ومقبوضات العملاء ليترجمها إلى قيود يومية تلقائية. ويقدم للـ Sales أرصدة العملاء اللحظية (Customer Balances) وحدود الائتمان.
- **Purchasing Domain:** يستقبل الـ Finance الأثر المالي لفواتير المشتريات ومدفوعات الموردين. ويقدم للـ Purchasing أرصدة الموردين (Vendor Balances) وحالة الدفع.
- **Inventory Domain:** يستقبل الـ Finance الأثر المالي لحركات المخزون (مثل الجرد، الإتلاف، التحويل) لتقييم المخزون دفترياً. ويقدم للـ Inventory التقييم المالي للمخزون (Inventory Valuation).
- **HR Domain (مستقبلاً):** سيستقبل الأثر المالي لمسيرات الرواتب والسلف. ويقدم للـ HR تأكيدات الدفع والصرف.
- **Extended Domain:** يزود النطاقات المتقدمة بالبيانات المالية اللازمة لتحليل الأداء.

---

## 5. Candidate Entities

قائمة أولية غير مصنفة للكيانات المتوقع وجودها:
- AccountType
- ChartOfAccount
- JournalEntry
- JournalEntryLine
- FiscalYear
- FiscalPeriod
- CashRegister
- BankAccount
- ExchangeRate
- Tax
- PaymentTerm
- Payment

---

## 6. Business Capabilities

يقدم ה-Finance Domain القدرات الرئيسية التالية:
- **General Ledger (دفتر الأستاذ العام):** تتبع جميع الحسابات وأرصدتها اللحظية.
- **Payments:** معالجة المقبوضات والمدفوعات.
- **Cash Management:** إدارة حركة النقد في الخزائن الفرعية والرئيسية.
- **Bank Management:** إدارة الحسابات البنكية والتسويات.
- **Fiscal Management:** إدارة السنة المالية، الإقفال الشهري والسنوي.
- **Currency Management:** إدارة الفروقات في أسعار الصرف.
- **Tax Management:** تتبع الالتزامات الضريبية.
- **Financial Reporting:** توليد القوائم المالية الأساسية.

---

## 7. Accounting Principles

يجب أن يلتزم النطاق بالمبادئ المحاسبية المعيارية التالية:
- **Double Entry Accounting (القيد المزدوج):** يجب أن يتطابق إجمالي المدين مع إجمالي الدائن في أي قيد.
- **Immutable Posted Entries (عدم قابلية التعديل):** القيود المُرحّلة لا تُعدل ولا تُحذف. تصحيح الخطأ يتم عبر قيد عكسي أو تسوية.
- **Audit Trail (مسار التدقيق):** توثيق مصدر كل حركة مالية والمستخدم الذي قام بها.
- **Period Locking (إقفال الفترات):** منع تسجيل أي حركات في فترة مالية مغلقة.
- **Accrual Accounting (الاستحقاق المحاسبي):** تسجيل الإيرادات والمصروفات عند استحقاقها وليس عند تحصيلها نقدياً.
- **Financial Integrity (النزاهة المالية):** حماية الأرصدة من أي خلل أو فقدان للبيانات.
- **Source Document Traceability (تتبع المستند المصدري):** كل قيد محاسبي يجب أن يحتفظ بمرجع واضح وقطعي إلى المستند التشغيلي الذي أنشأه (مثل: Sales Invoice, Purchase Invoice, Payment, Inventory Adjustment, Manual Journal) لضمان الشفافية والمراجعة.
- **Journal Entry Lifecycle:** يمتلك Journal Entry دورة حياة (Lifecycle) رسمية سيتم تعريفها بالكامل في وثيقة Finance Domain Architecture، ولا يتم تحديد تفاصيلها في مرحلة التخطيط.

---

## 8. High-Level Workflow

دورة العمل العامة التي تحكم تفاعل النظام مع الـ Finance:

**مثال على دورة المبيعات:**
Sales Invoice Created 
↓ 
Generate Journal Entry (Receivables vs. Revenue) 
↓ 
Post To Ledger 
↓ 
Update Balances 
↓ 
Reflect in Financial Reports

**مثال على دورة التحصيل:**
Receive Payment 
↓ 
Generate Journal Entry (Cash/Bank vs. Receivables) 
↓ 
Post To Ledger 
↓ 
Update Balances

**Purchase Invoice**
↓
Generate Journal Entry
↓
Post To Ledger
↓
Update Balances

**Inventory Adjustment**
↓
Generate Journal Entry
↓
Post To Ledger
↓
Update Balances

**Manual Journal**
↓
Validation
↓
Post To Ledger
↓
Update Balances

**مثال على دورة الدفع اليدوي:**
Manual Payment
↓
Generate Journal Entry
↓
Post To Ledger
↓
Update Balances

---

## 9. Assumptions

يُبنى ה-Finance Domain على الافتراضات التالية:
- **Multi Currency:** دعم التعامل بعدة عملات مع تسجيل فروق الصرف.
- **Multi Branch:** القدرة على تتبع الإيرادات والمصروفات على مستوى كل فرع.
- **Multi Fiscal Year:** إمكانية فتح سنوات مالية جديدة مع تدوير الأرصدة.
- **Tenant Isolation:** عزل مطلق للبيانات المالية لكل حساب (Account) أو شركة (Business).
- **Posted Entries Immutable:** القيود المُرحّلة نهائية تماماً.
- **System Generated Journal Numbers:** توليد آلي ومتسلسل لأرقام القيود لمنع التلاعب.

---

## 10. Out of Scope

لن يتم بناء الميزات التالية في الإصدار الأول من الـ Finance Domain:
- Budgeting (الموازنات التقديرية).
- Asset Depreciation (إهلاك الأصول الثابتة آلياً).
- Manufacturing Costing (التكاليف الصناعية المعقدة).
- Advanced Consolidation (تجميع الميزانيات المتقدم للشركات القابضة).
- Payroll Accounting (محاسبة الرواتب المعقدة).
- Advanced Forecasting (التنبؤ المالي المتقدم).

---

## 11. Deliverables

بعد اعتماد هذه الوثيقة التخطيطية، سيتم إنتاج المخرجات التالية تباعاً:
- Finance Architecture (القرارات المعمارية وتصميم النطاق).
- Entity Classification (التصنيف الدقيق للكيانات المعتمدة).
- Dependency Diagram (مخطط التبعية والتواصل).
- Implementation Plan (خطة التنفيذ البرمجية).
- Development (البدء بكتابة الشفرة).

---

## 12. Finance Domain Success Criteria

يُعتبر ה-Finance Domain ناجحاً وجاهزاً للعمل إذا تحققت المعايير التالية:
- جميع القيود المحاسبية تحقق مبدأ القيد المزدوج (Double Entry) بتطابق المدين والدائن.
- يرفض النظام بشكل قاطع ترحيل أي قيد (Journal Entry) غير متوازن.
- القيود المُرحّلة (Posted) غير قابلة للتعديل أو الحذف نهائياً.
- كل عملية تشغيلية معتمدة (مثل فاتورة أو سند صرف) تولد أثراً محاسبياً آلياً صحيحاً وفي الوقت الفعلي.
- يمنع على أي عملية تشغيلية في النظام تعديل أرصدة الحسابات بشكل مباشر. جميع الأرصدة المالية يجب أن تُستخرج حصراً من القيود اليومية المُرحلة (Posted Journal Entries) عبر دفتر الأستاذ العام (General Ledger)، باعتباره المصدر الوحيد للحقيقة (Single Source of Truth).
- جميع التقارير المالية تعتمد حصرياً على بيانات دفتر الأستاذ (General Ledger) لضمان وحدة الحقيقة (Single Source of Truth).
- يمنع النظام تماماً تسجيل أو تعديل أي حركة مالية تقع داخل فترة مالية تم إغلاقها.

---

## 13. Approval

- **Status:** FINAL APPROVED
- **Version:** Finance Planning v1.0
