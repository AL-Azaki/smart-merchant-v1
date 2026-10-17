# الدليل الشامل وخريطة الجاهزية لنظام التاجر المحاسبي (ERP Master Readiness Tracker)
## وثيقة التسليم للمطورين ونماذج الذكاء الاصطناعي (AI Handover & Context File)

> [!IMPORTANT]
> **تنبيه لكل نموذج ذكاء اصطناعي (AI Agent) أو مطور يبدأ محادثة جديدة:**
> اقرأ هذا الملف أولاً قبل تنفيذ أي كود! يوضح هذا الدليل بالضبط أين يقف المشروع، ما تم إنجازه، وما هي النواقص الدقيقة الحقيقية لنصل إلى **منتج محاسبي وتجاري فعلي جاهز للتسليم لعميل حقيقي**.

---

## 1. جوهر المشروع والرؤية المعتمدة (Core Product Scope)
* **المشروع:** `Smart Merchant ERP` (نظام إدارة تجارة التجزئة، المخزون، ونقاط البيع مع محرك محاسبي مزدوج القيد Offline-First).
* **القاعدة الذهبية:** التركيز **حصراً بنسبة 100% على النواة الأساسية للتاجر** (المخزون، نقاط البيع، المشتريات، المبيعات، العملاء والموردين، الخزينة، وشجرة الحسابات).
* **المجالات المستبعدة تماماً حالياً (Frozen / Out of Scope):**
  * ❌ المتجر الإلكتروني (E-commerce / Online Store).
  * ❌ التزامن السحابي المتقدم (Cloud Sync Engines / Multi-device Cloud).
  * ❌ الأصول الثابتة المعقدة ونظام الرواتب وشؤون الموظفين (HR/Payroll).
* **ملاحظات تخص تجربة المستخدم بناءً على توجيه المستخدم:**
  * ⏸️ **اختصارات لوحة المفاتيح (Keyboard Shortcuts):** مؤجلة حالياً وليست أولوية في هذه المرحلة.
  * 🎯 **الأولوية القصوى الحالية:** **ربط الواجهات الحقيقية واستئصال البيانات الوهمية (Mock Data)، القضاء على الشاشات الشكلية (Placeholders)، ربط كشوفات الحسابات وتفاصيل الفواتير والسندات فعلياً بقاعدة البيانات.**

---

## 2. الوضع الحالي للمشروع: الحقيقة بين الكواليس والواجهات
المشروع يمتلك بنية تحتية ومعمارية قاعدة بيانات (Drift / SQLite) قوية ومختبرة بنسبة نجاح 100% في الحسابات الرياضية والقيد المزدوج، **ولكن الفجوة الحقيقية تكمن في طبقة الواجهات (Presentation Layer) والربط النهائي (End-to-End Wiring):**
1. **شاشات شكلية (Placeholders):** شاشات رئيسية تستدعي `FinanceSectionPlaceholderView` دون تنفيذ حقيقي (مثل الخزائن والبنوك، مراكز التكلفة).
2. **بيانات وهمية ثابتة (Hardcoded Mock Data):** وجود كائنات وهمية في صفحات العرض (مثل `_mockTransactions` في لوحة تحكم المالية).
3. **أدوات وودجات معزولة غير مربوطة (Orphan Widgets):** تم برمجة كود احترافي كامل مثل `PartyStatementDialog` (كشف حساب العميل والمورد) ولكن لم يتم ربطه بأي زر في قائمة العملاء أو الموردين!
4. **أزرار غير مربوطة (Dead Ends):** نوافذ منبثقة أو أزرار تحتوي على `onPressed: () {}` أو حقول لا تجلب الحسابات الحقيقية من شجرة الحسابات.

---

## 3. خريطة المراحل الخمس (Modular Readiness Phases)

| رقم المرحلة | الموديول المستهدف | ملف التفاصيل | نسبة الاكتمال الفعلي | الأولوية |
| :---: | :--- | :--- | :---: | :---: |
| **المرحلة 1** | **المالية والمحاسبة والخزينة** (Accounting & Treasury) | [PHASE_1_ACCOUNTING_AND_TREASURY.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/merchant_audit_and_readiness/PHASE_1_ACCOUNTING_AND_TREASURY.md) | 🟢 100% (مكتملة ومربوطة بالكامل) | **✅ منجزة بالكامل** |
| **المرحلة 2** | **الأصناف والمستودعات** (Catalog & Inventory) | [PHASE_2_INVENTORY_AND_CATALOG.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/merchant_audit_and_readiness/PHASE_2_INVENTORY_AND_CATALOG.md) | 🟢 100% (كارت الصنف، تحويلات المستودعات، التسويات والجرد) | **✅ منجزة بالكامل** |
| **المرحلة 3** | **المشتريات والموردين** (Purchasing & Suppliers) | [PHASE_3_PURCHASING_AND_SUPPLIERS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/merchant_audit_and_readiness/PHASE_3_PURCHASING_AND_SUPPLIERS.md) | 🟢 100% (أرصدة الموردين الحية، المردود وخصم المخزون، تفاصيل الفواتير، كشف الحساب) | **✅ منجزة بالكامل** |
| **المرحلة 4** | **المبيعات ونقاط البيع والعملاء** (Sales, POS & Customers) | [PHASE_4_SALES_POS_AND_CUSTOMERS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/merchant_audit_and_readiness/PHASE_4_SALES_POS_AND_CUSTOMERS.md) | 🟡 75% (تم ربط كشف الحساب وقبض دفعات العملاء) | **P1 (المرحلة الحالية النشطة)** |
| **المرحلة 5** | **الإعدادات وبنية النظام والطباعة** (Settings & Printing) | [PHASE_5_CORE_SETTINGS_AND_PRINTING.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/merchant_audit_and_readiness/PHASE_5_CORE_SETTINGS_AND_PRINTING.md) | 🟡 50% (إعدادات أساسية / قوالب طباعة الفواتير والسندات) | **P2** |

---

## 4. تعليمات بدء محادثة جديدة (Quick Start For Next Session)
إذا كنت ذكاءً اصطناعياً تبدأ جلسة جديدة:
1. اقرأ هذا الملف `00_MASTER_INDEX.md`.
2. حدد المرحلة الحالية التي يجري العمل عليها (مثلاً: **المرحلة 1**).
3. افتح ملف المرحلة الخاصة بها (مثال: `PHASE_1_ACCOUNTING_AND_TREASURY.md`).
4. ابدأ فوراً بتنفيذ قائمة المهام المحددة تحت بند `قائمة المهام التنفيذية (Action Items)`.
5. قم بتحديث علامات `[ ]` إلى `[x]` وتحديث نسبة الاكتمال فور إنجاز واختبار كل مهمة.
