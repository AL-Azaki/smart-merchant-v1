# مواصفات المرحلة الثانية: شجرة الحسابات الحقيقية ودفتر الأستاذ العام
## Phase 2 Specification: Real Chart of Accounts & General Ledger Engine

**الهدف:** استئصال الـ Mock UI بالكامل من شاشة الإدارة المالية (`financial_dashboard_view.dart`)، وبذر شجرة حسابات قياسية تجارية، وبناء شاشات إدارة الحسابات والقيود اليومية المتقدمة المتصلة بقاعدة البيانات الحقيقية.

---

## 1. المشاكل الحالية والأدلة من الكود (Current Code Gaps)

1. **الواجهات الوهمية المعزولة:**
   * في `financial_dashboard_view.dart`:
     * السطور 33-50 و 700-1200: تستخدم كلاس `_MockAccount` ومصفوفة محلية `_mockAccounts`.
     * السطور 1325-1500: تستخدم مصفوفة `_mockJournalEntries` لعرض القيود اليومية.
     * أي تعديل أو إضافة حساب يضيع فور إغلاق التطبيق لأنه لا يصل لقاعدة البيانات!
2. **غياب دوال إدارة الحسابات في طبقة التطبيق:**
   * في `accounting_application_service.dart`: يحتوي الملف على دالة واحدة فقط هي `resolveAccountMapping`، بينما دوال الإضافة والتعديل والحذف والفحص غير موجودة إطلاقاً على عكس ما ورد في التقارير السابقة.
3. **غياب شجرة الحسابات الافتراضية للتاجر:**
   * عند تسجيل مستخدم جديد أو إنشاء متجر، لا توجد دالة بذر تلقائي (Auto-Seed) لشجرة حسابات جاهزة، مما يجعل النظام غير قابل للعمل دون إدخال عشرات الحسابات يدوياً.

---

## 2. الهيكلية القياسية لشجرة الحسابات للتاجر (Standard Retail COA)

يتم بذر هذه الشجرة تلقائياً في قاعدة البيانات عند إنشاء المنشأة (`businesses`):

```
1. الأصول (Assets) - رئيسي
   ├── 11. الأصول المتداولة (Current Assets) - رئيسي
   │    ├── 111. النقدية وما في حكمها (Cash & Banks) - رئيسي
   │    │    ├── 11101. الصندوق الرئيسي (Main Cashbox) - فرعي (يقبل حركات)
   │    │    └── 11102. الحساب البنكي الرئيسي (Main Bank) - فرعي (يقبل حركات)
   │    ├── 112. المدينون وذمم العملاء (Accounts Receivable) - رئيسي
   │    │    └── 11201. ذمم العملاء (Customer Receivables) - فرعي (يقبل حركات)
   │    └── 113. المخزون (Inventory) - رئيسي
   │         └── 11301. بضاعة المخزن الرئيسي (Main Stock) - فرعي (يقبل حركات)
2. الخصوم والالتزامات (Liabilities) - رئيسي
   └── 21. الخصوم المتداولة (Current Liabilities) - رئيسي
        └── 211. الدائنون وذمم الموردين (Accounts Payable) - رئيسي
             └── 21101. ذمم الموردين (Supplier Payables) - فرعي (يقبل حركات)
3. حقوق الملكية (Equity) - رئيسي
   ├── 31. رأس المال (Capital) - فرعي (يقبل حركات)
   ├── 32. الأرباح المحتجزة / المرحلة (Retained Earnings) - فرعي (يقبل حركات)
   └── 33. مسحوبات الشركاء (Owner Drawings) - فرعي (يقبل حركات)
4. الإيرادات (Revenue) - رئيسي
   ├── 41. إيرادات المبيعات (Sales Revenue) - فرعي (يقبل حركات)
   └── 42. إيرادات أخرى / خصم مكتسب (Other Revenue) - فرعي (يقبل حركات)
5. المصروفات (Expenses) - رئيسي
   ├── 51. تكلفة البضاعة المباعة (COGS) - فرعي (يقبل حركات)
   ├── 52. مصروفات تشغيلية (Operating Expenses) - رئيسي
   │    ├── 52001. إيجارات (Rent) - فرعي
   │    ├── 52002. كهرباء ومياه (Utilities) - فرعي
   │    ├── 52003. رواتب وأجور (Salaries) - فرعي
   │    ├── 52004. عجز وتلف المخزون (Stock Loss) - فرعي
   │    └── 52005. مصاريف عمومية وإدارية (General Expenses) - فرعي
   └── 53. خصم مسموح به (Discounts Allowed) - فرعي
```

---

## 3. الخطوات التنفيذية التفصيلية (Implementation Steps)

### الخطوة 2.1: كتابة خدمة بذر الشجرة `DefaultChartOfAccountsSeeder`
* مسار الملف الجديد: `lib/database/seeders/default_coa_seeder.dart`
* **المطلوب:**
  * دالة تقبل `businessId` و `currencyId`.
  * تقوم بإدراج الحسابات المذكورة أعلاه في جدول `chart_of_accounts`.
  * تقوم بربط الحسابات الأساسية في جدول `account_mappings`:
    * `'cash_main'` -> `11101`
    * `'bank_main'` -> `11102`
    * `'accounts_receivable'` -> `11201`
    * `'inventory_asset'` -> `11301`
    * `'accounts_payable'` -> `21101`
    * `'sales_revenue'` -> `41`
    * `'cogs'` -> `51`
    * `'inventory_adjustment_loss'` -> `52004`
    * `'retained_earnings'` -> `32`

### الخطوة 2.2: استكمال دوال `AccountingApplicationService`
* مسار الملف: `lib/modules/accounting/application/services/accounting_application_service.dart`
* **إضافة الدوال التالية:**
  1. `createAccount(CreateAccountCommand cmd)`:
     * التحقق من عدم تكرار كود الحساب (`account_code`) داخل نفس المنشأة.
     * التحقق من وجود الحساب الأب (`parent_account_id`).
     * حساب المستوى تلقائياً (`account_level = parent.level + 1`).
     * منع جعل الحساب الأب يقبل حركات (`allow_posting = false` للحساب الرئيسي).
  2. `updateAccount(UpdateAccountCommand cmd)`:
     * منع تعديل كود الحساب أو نوعه إذا كان مرتبطاً بقيود سابقة.
  3. `safeDeleteAccount(String accountId)`:
     * فحص جدول `journal_entry_lines`: إذا وجد أي سطر قيد للحساب، يُرفض الحذف فوراً ويُرمى استثناء `AccountHasTransactionsFailure`.
     * فحص ما إذا كان للحساب أبناء: إذا كان له حسابات فرعية، يُرفض الحذف.
     * في حال لم تكن له حركات أو أبناء، يُحذف أو يُحول إلى غير نشط.
  4. `getChartOfAccountsTree()`:
     * إرجاع الشجرة بشكل متداخل (Hierarchical Tree) لعرضها في واجهة المستخدم.

### الخطوة 2.3: تطهير شاشة `financial_dashboard_view.dart` وربطها بالـ Riverpod
* مسار الملف: `lib/modules/accounting/presentation/pages/financial_dashboard_view.dart`
* **المطلوب:**
  1. حذف كلاسات ومصفوفات الموك: `_MockAccount`, `_mockAccounts`, `_mockJournalEntries`.
  2. تحويل `ChartOfAccountsTab` إلى `ConsumerStatefulWidget`.
  3. استهلاك الـ Provider الحقيقي:
     ```dart
     final accountsAsync = ref.watch(chartOfAccountsNotifierProvider);
     ```
  4. بناء شجرة العرض التفاعلية باستخدام بيانات الـ SQLite الحقيقية.
  5. ربط زر "إضافة حساب جديد" بـ `AccountFormSheet` لتنفيذ `createAccount` الحقيقية عبر الـ Use Case.
  6. ربط تبويب "القيود اليومية" بـ `journalEntriesNotifierProvider`.

### الخطوة 2.4: بناء نافذة القيد اليومي المتقدم (Manual Journal Entry Sheet)
* مسار الملف: `lib/modules/accounting/presentation/widgets/journal_entry_form_sheet.dart`
* **المواصفات:**
  * رأس القيد: رقم القيد (توليد تلقائي)، التاريخ، العملة وسعر الصرف، الملاحظات/البيان.
  * جدول السطور:
    * اختيار الحساب من قائمة الحسابات الفرعية فقط (`allow_posting == true`).
    * عمود مدين (Debit) وعمود دائن (Credit).
    * سطر البيان الخاص.
  * مؤشر التوازن الحي (Live Balance Indicator):
    * عرض إجمالي المدين وإجمالي الدائن والفرق.
    * زر "حفظ وترحيل" يكون **معطلاً (Disabled)** طالما أن الفرق لا يساوي صفراً!
  * زر "إضافة سطر جديد" وزر "حذف سطر".
  * زر ذكي "موازنة تلقائية" يقوم بملء المبلغ المتبقي في السطر الأخير لتسريع عمل المحاسب.

---

## 4. معايير القبول الصارمة (Acceptance Criteria)

- [ ] **AC-2.1:** عند إنشاء منشأة جديدة، يتم بذر شجرة الحسابات تلقائياً وتظهر 15 حساباً أساسياً على الأقل موزعة على المستويات الخمسة.
- [ ] **AC-2.2:** شاشة دليل الحسابات تعرض الحسابات الحقيقية من جدول `chart_of_accounts` وتحدث نفسها تلقائياً (Stream/Reactive) فور إضافة أي حساب.
- [ ] **AC-2.3:** محاولة حذف حساب مسجل عليه قيد في السابق (مثل حساب الصندوق) تفشل وتظهر رسالة واضحة للمستخدم: "لا يمكن حذف حساب يحتوي على حركات مالية مسجلة".
- [ ] **AC-2.4:** شاشة القيد اليدوي ترفض حفظ قيد غير متوازن (مثلاً: مدين 1000 ودائن 950) وتمنع الحفظ حتى يصبح الفرق 0.00.
- [ ] **AC-2.5:** القيد اليدوي المسجل ينعكس فوراً في جدول القيود وفي رصيد الحساب.

---

## 5. محاذير الخطر وقواعد الرفض (Danger Traps & Rejection Rules)

> [!CAUTION]
> **ممنوع قطعي (CRITICAL REJECTION):**
> 1. ممنوع السماح بالترحيل (`allow_posting = true`) على أي حساب رئيسي له حسابات فرعية. الترحيل يتم فقط على الحسابات الفرعية (Leaf Nodes).
> 2. ممنوع حذف أي سجل من جدول `chart_of_accounts` إذا كان معرّف الحساب موجوداً في جدول `account_mappings`.
> 3. ممنوع حفظ أي قيد يومي تكون فيه العملة مختلفة بين السطور دون تحديد سعر صرف واضح لكل عملة لحساب الـ `baseAmount`.
