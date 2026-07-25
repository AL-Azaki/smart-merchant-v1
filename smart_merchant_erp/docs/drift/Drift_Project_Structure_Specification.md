# Drift Project Structure Specification
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`, `SQLite_Phase_01` → `SQLite_Phase_10`, `SQLite_Enums_Specification.md`, & `SQLite_Type_Converters_Specification.md`
**Date:** 2026-07-18

---

## Architectural & Governance Mandate

> [!IMPORTANT]
> **Frozen Architecture & Zero-Code Structural Specification:**
> هذه الوثيقة هي المرجع الهندسي المعماري المعتمد لتصميم وتنظيم هيكل مجلدات ومحتويات إطار عمل **`Drift ORM`** داخل تطبيق Flutter (**`Smart Merchant ERP`**).
>
> 1. **الالتزام الكامل بالمعمارية:** يمنع منعاً باتاً تعديل قاعدة البيانات المعتمدة في مصدر الحقيقة (`Database_Schema_Extraction.md` ومراحل التوثيق العشر) أو إضافة/حذف أي جدول، أو تعديل العلاقات أو أنواع البيانات المعتمدة.
> 2. **التنظيم القياسي العالي:** تم تصميم هذا الهيكل ليدعم مشروع **Offline-First Multi-Module ERP** واسع النطاق يضم أكثر من 70 جدولاً، عشرات الـ `DAOs` والـ `TypeConverters`، ومحرك مزامنة متطور (`Sync Engine`)، مع الحفاظ على سرعة التجميع (`build_runner performance`) وسهولة الصيانة والاختبار.
> 3. **حظر الأكواد البرمجية:** تقتصر هذه الوثيقة حصرياً على تحديد الهيكل التنظيمي ومسؤوليات الملفات والمجلدات وحدود الوحدات (`Module Boundaries`)، ولا تتضمن أو تنشئ أي أكواد برمجية لـ `Drift Tables`, `DAOs`, `Repositories`, أو `TypeConverters`.

---

## 1. Official Directory Structure Blueprint (`lib/database/`)

الهيكل الرسمي والموحد لطبقة قاعدة البيانات المعتمدة على `Drift ORM` داخل مشروع Flutter:

```text
lib/
└── database/
    ├── app_database.dart             # نقطة الدخول الرئيسية والموحدة لقاعدة البيانات (Database Entry Point)
    ├── tables/                       # تعريفات جداول Drift مقسمة بدقة حسب الوحدات البرمجية (Modules)
    │   ├── core/                     # جداول الأساس الإعدادية والتسلسلية (Phase 1)
    │   ├── inventory/                # جداول المخزون والحركات والتحويلات (Phase 2)
    │   ├── catalog/                  # جداول المنتجات والضرائب والأسعار والوحدات (Phase 3)
    │   ├── sales/                    # جداول المبيعات، العملاء، القنوات، السلال، والفواتير (Phase 4)
    │   ├── purchasing/               # جداول المشتريات، الموردين، وفواتير ومرتجعات الشراء (Phase 5)
    │   ├── accounting/               # جداول المحاسبة العامة، السنوات والفتار والمستندات القيادية (Phase 6)
    │   ├── treasury/                 # جداول الخزينة، البنوك، المدفوعات، وطرق الدفع والتسويات (Phase 7)
    │   ├── hr/                       # جداول الموارد البشرية، الأقسام، الموظفين، والمستندات (Phase 8)
    │   ├── fixed_assets/             # جداول الأصول الثابتة وإهلاكاتها (Phase 9)
    │   └── system/                   # جداول الإدارة العامة، المصروفات، المرفقات، وسجلات النشاط (Phase 10)
    ├── daos/                         # كائنات الوصول للبيانات (DAOs) منظمة معمارياً حسب النطاقات الوظيفية (Modules)
    │   ├── core_dao.dart
    │   ├── inventory_dao.dart
    │   ├── catalog_dao.dart
    │   ├── sales_dao.dart
    │   ├── purchasing_dao.dart
    │   ├── accounting_dao.dart
    │   ├── treasury_dao.dart
    │   ├── hr_dao.dart
    │   ├── fixed_assets_dao.dart
    │   └── system_dao.dart
    ├── converters/                   # محولات أنواع البيانات (Drift TypeConverters) المخصصة
    ├── enums/                        # تعريفات Dart Enums الرسمية المطابقة لقاعدة البيانات
    ├── views/                        # استعلامات العروض المجمعة (Drift Views & Custom Select Queries)
    ├── migrations/                   # منطق وترقيات إصدارات قاعدة البيانات ومخططات المزامنة (Schema Migrations)
    ├── utils/                        # أدوات الربط والدعم واستعلامات الفلترة ومحركات الاتصال (Database Utilities)
    └── extensions/                   # امتدادات ومساعدات الاستعلامات المتقدمة (Query & Column Extensions)
```

---

## 2. Detailed Folder Specifications

### 1. `lib/database/tables/`
- **Folder Name:** `tables/`
- **Purpose:** احتضان كافة تعريفات جداول `Drift` الرسمية (البالغة 85+ جدولاً مستخرجة في المراحل العشر) مقسمة في مجلدات فرعية تعكس تصنيف الوحدات (`Modules`) لضمان الانفصال المعماري ومنع التكدس.
- **What belongs here:** ملفات تعريفات الجداول (`Drift Table Definitions`) المشتقة حصرياً من وثائق استخراج المراحل `Phase 01` إلى `Phase 10` (مثال: جدول `businesses`, جدول `inventories`, جدول `journal_entries`).
- **What must NOT be placed here:** أكواد الـ `DAOs` أو الـ `TypeConverters` أو منطق الأعمال (`Business Logic`) أو كائنات التحويل الخارجية (`DTOs`).

---

### 2. `lib/database/daos/`
- **Folder Name:** `daos/`
- **Purpose:** توفير واجهات وصول معزولة ومتخصصة لاستعلامات وتعديلات قاعدة البيانات لكل نطاق وظيفي (`Data Access Objects`).
- **What belongs here:** فئات الـ `DAOs` المعتمدة على `Drift` التي تجمع العمليات الاستعلامية والحركات التبادلية (`Transactions`) الخاصة بوحدة واحدة محددة.
- **What must NOT be placed here:** تعريفات الجداول (`Tables`) أو استعلامات التبعيات الخارجية أو استدعاءات الشبكة (`API Calls` / `Repositories`).

---

### 3. `lib/database/converters/`
- **Folder Name:** `converters/`
- **Purpose:** احتضان جميع فئات التحويل المخصصة (`Drift TypeConverters`) المعتمدة في وثيقة `SQLite_Type_Converters_Specification.md`.
- **What belongs here:** محولات بيانات الـ `JSONB` إلى `Map/List`، ومحولات فئات الـ `Dart Enums` إلى نصوص `TEXT` في `SQLite` المحددة رسمياً في التوثيق.
- **What must NOT be placed here:** منطق الأعمال العام أو تحويلات واجهات مستخدم التطبيق أو النماذج المعمارية (`Domain Models`).

---

### 4. `lib/database/enums/`
- **Folder Name:** `enums/`
- **Purpose:** الموطن الحصري والوحيد لجميع فئات الـ `Dart Enums` الرسمية (الـ 45 Enum المعتمدة) التي تم استخراجها وتوثيقها في وثيقة `SQLite_Enums_Specification.md`.
- **What belongs here:** تعريفات الـ Enums الصافية (مثل `AccountTypeStatus`, `InventoryTransactionType`, `SalesInvoiceStatus`) المطابقة لسلاسل `CHECK Constraints`.
- **What must NOT be placed here:** أي Enum غير موجود في وثيقة الاستخراج الرسمية، أو محولات `Drift TypeConverters`، أو أي كود يعتمد على واجهة المستخدم.

---

### 5. `lib/database/views/`
- **Folder Name:** `views/`
- **Purpose:** إدارة وتخزين استعلامات العروض المجمعة (`Drift Views`) والاستعلامات التحليلية الجاهزة للقراءة فقط المخصصة للأداء العالي والتقارير.
- **What belongs here:** تعريفات `Drift View Definitions` لاستعلامات التقارير الموحدة (مثل عروض أرصدة المخزون، أو كشف حساب الأستاذ المجمع).
- **What must NOT be placed here:** جداول التخزين الأساسية (`Tables`) أو حركات كتابة البيانات (`Insert/Update/Delete operations`).

---

### 6. `lib/database/migrations/`
- **Folder Name:** `migrations/`
- **Purpose:** إدارة دورة حياة ترقيات المخطط (`Schema Versioning & Migrations`) ومعالجات تحديث الجداول والأعمدة عند ترقية إصدار تطبيق Flutter.
- **What belongs here:** منطق ترقية المخطط (`Migration Strategies` & `Schema Steps`) ومراحل فك ارتباط النسخ التمهيدية ومحركات تحديث الفهارس الموضعية.
- **What must NOT be placed here:** أكواد العمليات اليومية للـ `DAOs` أو معالجات استعلامات الواجهة الأمامية.

---

### 7. `lib/database/utils/`
- **Folder Name:** `utils/`
- **Purpose:** توفير الأدوات المساعدة لمعالجة اتصال `SQLite` (`Database Connections & Openers`)، وأدوات الفلترة والترتيب المشتركة، وثوابت إدارة المزامنة الأساسية.
- **What belongs here:** ملفات إعداد محركات الاتصال (`NativeDatabase` / `WebDatabase` / `Connection Poolers`) وأدوات معالجة الـ `Batch Operations` وثوابت فئات البيانات المساعدة.
- **What must NOT be placed here:** منطق الأعمال أو استعلامات نطاقات محددة تتبع لوحدات `Modules` مستقلة.

---

### 8. `lib/database/extensions/`
- **Folder Name:** `extensions/`
- **Purpose:** احتضان الامتدادات والمساعدات (`Dart Extensions`) المضافة على استعلامات وأعمدة `Drift` لتسهيل قراءة وكتابة الشروط المتقدمة (`Custom Expressions`).
- **What belongs here:** امتدادات الفلترة على التواريخ (`Date Filter Extensions`) أو البحث في نصوص `JSON String` أو فلترة أعمدة المزامنة (`Sync Metadata Extensions`).
- **What must NOT be placed here:** فئات الـ `DAOs` الكاملة أو الجداول الرسمية.

---

## 3. Architectural Decision: DAO Organization (`Domain/Module-Driven DAOs`)

> [!IMPORTANT]
> **Official Architecture Decision on DAO Structure:**
> تم اتخاذ القرار المعماري الموحد بعدم إنشاء `DAO` منفصل لكل جدول على حدة (تجنباً للتشتت وكثرة الملفات المترابطة لـ 85+ جدولاً)، وبدلاً من ذلك يُعتمد تنظيم **`Module-Driven DAOs` (كائن وصول بيانات مركزي لكل وحدة وظيفية/Domain)**.

### مبررات ومواصفات القرار:
1. **تكامل الحركات التبادلية (`Cross-Table Transactions`):** العمليات التجارية في نظام ERP (مثل ترحيل فاتورة مبيعات) تتطلب تعديل جدول الفاتورة (`sales_invoices`)، وعناصر الفاتورة (`sales_invoice_items`)، وربطها مع طلب المبيعات، وربما قيود العملاء، ضمن حركة واحدة (`Transaction`). وجود كائن وصول موحد مثل `SalesDao` يضمن تنفيذ هذه العمليات بذرية دقيقة (`Atomic Execution`) دون تداخل وتبعية معقدة بين عشرات الـ DAOs المنفصلة.
2. **الانفصال التام والتخصص المباشر:** كل وحدة وظيفية (`Module`) تمتلك `DAO` مخصص يضم فقط جداول النطاق الموثقة في استخراجها الرسمي:
   - `CoreDao`: يدير `account_types`, `system_settings`, `print_settings`, `sequences`.
   - `InventoryDao`: يدير `inventories`, `inventory_transactions`, `inventory_transfers` وجداول بنودها.
   - `CatalogDao`: يدير `branch_product_prices`, `taxes`, `product_taxes`, `product_variants`.
   - `SalesDao`: يدير `customers`, `channels`, `carts`, `orders`, `sales_invoices`, `sales_returns` والمقبوضات المرتبطة.
   - `PurchasingDao`: يدير `suppliers`, `purchase_invoices`, `purchase_returns`, والمدفوعات المرتبطة.
   - `AccountingDao`: يدير `fiscal_years`, `fiscal_periods`, `chart_of_accounts`, `journal_entries`, والقيود المحاسبية.
   - `TreasuryDao`: يدير `cash_registers`, `bank_accounts`, `payments`, وجميع الحركات النقدية والبنكية.
   - `HrDao`: يدير `departments`, `job_titles`, `employees`, `employee_documents`.
   - `FixedAssetsDao`: يدير `fixed_assets`, `depreciation_schedules`.
   - `SystemDao`: يدير `expense_categories`, `expenses`, `activity_logs`, `attachments`, `exchange_rates`.
3. **سهولة الحقن الصديق لطبقة المستودعات (`Clean Repository Injection`):** كل Repository في طبقة الـ Domain يُحقن بـ `DAO` واحد واضح ومباشر، مما يسهل كتابة اختبارات الـ Unit Testing والـ Mocking.

---

## 4. Database Entry Point: `app_database.dart`

### المسار الحصري: `lib/database/app_database.dart`

### المسؤولية الحصرية والمحددة (`Single Responsibility & Core Scope`):
1. **التجميع المعماري المركزي:** يُعد فئة `AppDatabase` الموروثة من `@DriftDatabase` هي نقطة الالتقاء الوحيدة (`Central Hub`) التي تقوم بتجميع كافة تعريفات الجداول (`Tables`) المستوردة من المجلدات العشر في `tables/`، وتجميع كافة الـ `DAOs` المستوردة من مجلد `daos/`.
2. **إدارة دورة حياة المخطط رقمياً (`Schema Version Controller`):** يحتوي الملف على تحديد رقم إصدار قاعدة البيانات المعتمد (`schemaVersion`) وتوجيه عمليات الإنشاء لأول مرة أو الترقية (`Migration Strategy`).
3. **تهيئة محرك الاتصال محلياً (`Offline-First Connection Controller`):** تمرير محرك الاتصال المعتمد على `SQLite` (سواء في بيئات سطح المكتب أو الأجهزة المحمولة أو الويب) وضمان تفعيل القيود القياسية (`PRAGMA foreign_keys = ON`).
4. **حظر منطق الأعمال والحركات المباشرة:** يُمنع حظراً نهائياً كتابة أي استعلامات تجارية أو منطق إدراج وحذف أو فلترة داخل `app_database.dart`، حيث تقع هذه المسؤولية حصرياً داخل الـ `DAOs`.

---

## 5. Strict Module Boundaries (`ERP Domain Boundaries`)

لضمان سلامة البنية التحتية ومنع تداخل الكود أو حدوث اعتمادات دائرية (`Circular Dependencies`)، تفرض هذه الوثيقة حدوداً صارمة لا يجوز تخطيها بين الوحدات:

### 1. `Core Module` (`lib/database/tables/core/`)
- **المتضمنات الرسمية:** `account_types`, `system_settings`, `print_settings`, `sequences` + `CoreDao`.
- **الحدود والمحرمات:** لا يتضمن أي علاقة بمنتجات المخزون أو قيود المحاسبة أو الموردين. يمثل الأساس الإعدادي المشترك.

### 2. `Inventory Module` (`lib/database/tables/inventory/`)
- **المتضمنات الرسمية:** `inventories`, `inventory_transactions`, `inventory_transaction_lines`, `inventory_transfers`, `inventory_transfer_items` + `InventoryDao`.
- **الحدود والمحرمات:** يُعنى بحساب وتتبع الأرصدة والكميات الفعلية والحركات المخزنية فقط. يمنع منعه من إدراج أو إدارة القيود المحاسبية المالية المباشرة أو فواتير المبيعات.

### 3. `Catalog Module` (`lib/database/tables/catalog/`)
- **المتضمنات الرسمية:** `branch_product_prices`, `taxes`, `product_taxes`, `product_variants` + `CatalogDao`.
- **الحدود والمحرمات:** يدير تعريفات البضائع وهياكل الأسعار والضرائب ومصفوفات المتغيرات. يمنع عليه تعديل أرصدة المخزون أو إنشاء طلبات الشراء.

### 4. `Sales Module` (`lib/database/tables/sales/`)
- **المتضمنات الرسمية:** `customers`, `channels`, `product_channels`, `carts`, `cart_items`, `orders`, `order_items`, `sales_invoices`, `sales_invoice_items`, `sales_returns`, `sales_return_items`, `customer_receivables`, `receivable_entries` + `SalesDao`.
- **الحدود والمحرمات:** يدير كافة أطراف وحركات المبيعات والعملاء وسجلات الذمم المدينة. يمنع عليه التعديل المباشر على أرصدة البنوك أو جدول الأستاذ العام (`chart_of_accounts`).

### 5. `Purchasing Module` (`lib/database/tables/purchasing/`)
- **المتضمنات الرسمية:** `suppliers`, `purchase_invoices`, `purchase_invoice_items`, `purchase_returns`, `purchase_return_items`, `supplier_payables`, `payable_entries` + `PurchasingDao`.
- **الحدود والمحرمات:** يختص بالموردين ودورة الشراء وذمم الموردين الدائنة. يمنع عليه إصدار سندات صرف نقدية من الخزينة أو تعديل أصول المخزون الثابتة.

### 6. `Accounting Module` (`lib/database/tables/accounting/`)
- **المتضمنات الرسمية:** `fiscal_years`, `fiscal_periods`, `chart_of_accounts`, `journal_entries`, `journal_entry_lines`, `account_mappings`, `accounting_periods` + `AccountingDao`.
- **الحدود والمحرمات:** يمثل العصب المالي القيادي القياسي (`General Ledger Foundation`). يختص حصرياً بالقيود وشجرة الحسابات والفترات المالية. يمنع عليه تتبع تفاصيل حركات المنتجات المخزنية الفردية أو فواتير الشراء الخام.

### 7. `Treasury Module` (`lib/database/tables/treasury/`)
- **المتضمنات الرسمية:** `payment_methods`, `cash_registers`, `cash_transactions`, `bank_accounts`, `bank_transactions`, `payments`, `payment_allocations`, `bank_reconciliations`, `bank_reconciliation_lines` + `TreasuryDao`.
- **الحدود والمحرمات:** يدير النقدية والصناديق والبنوك ومدفوعات وسندات القبض والصرف والتسويات البنكية. يمنع عليه إنشاء فواتير مبيعات أو تعديل بيانات الموظفين.

### 8. `HR Module` (`lib/database/tables/hr/`)
- **المتضمنات الرسمية:** `departments`, `job_titles`, `employees`, `employee_documents` + `HrDao`.
- **الحدود والمحرمات:** يختص بالموظفين والأقسام والمسميات الوظيفية ووثائق شؤون العاملين. يمنع عليه حساب أو إنشاء مصروفات عامة أو قيود يومية للمرتبات دون العبور عبر الخدمة المالية المختصة.

### 9. `Fixed Assets Module` (`lib/database/tables/fixed_assets/`)
- **المتضمنات الرسمية:** `fixed_assets`, `depreciation_schedules` + `FixedAssetsDao`.
- **الحدود والمحرمات:** يختص بتسجيل الأصول الثابتة وجداول الإهلاك الدوري. يمنع عليه استهلاك المخزون المتداول أو التعديل المباشر على سندات البنوك.

### 10. `System & Extended Module` (`lib/database/tables/system/`)
- **المتضمنات الرسمية:** `expense_categories`, `expenses`, `activity_logs`, `attachments`, `exchange_rates`, `stock_adjustments`, `stock_adjustment_items` + `SystemDao`.
- **الحدود والمحرمات:** يدير الإدارة العامة للمصروفات، مرفقات النظام، أسعار الصرف الدورية، وسجلات المراجعة وأرصدة الجرد والتسويات المخزنية الدورية. يمثل نطاق الموائمات والوحدات المساندة.

---

## 6. Performance & Maintainability Rules (`Build Runner & Scalability Standards`)

لتلافي مشاكل الأداء وتأخيرات التجميع الشائعة في مشاريع `Drift` الكبيرة، يجب الالتزام بالمعايير الهندسية التالية:

1. **منع الملفات الضخمة (`Prohibit Monolithic Files`):** يمنع حظراً نهائياً وضع أكثر من جدول أو عدة كائنات في ملف `dart` واحد إذا تجاوز أو تسبب في تضخم الكود. يجب أن يمثل كل ملف جدولاً واحداً دقيقاً (أو جدولاً مع بنوده المباشرة إذا كانت في نفس الملف ومقسمة بوضوح)، لضمان نظافة الملفات وسرعة الفهرسة في الـ IDE.
2. **التقسيم الصارم حسب الوحدات (`Modular Table Categorization`):** توزيع الجداول على المجلدات العشر المستقلة في `tables/` يسهل قراءة الهيكل المعماري، ويجعل التنقل بين الملفات فورياً ومباشراً دون التشتت بين 85+ ملفاً في مسار مسطح واحد.
3. **حظر الاعتماد الدائري (`Zero Circular Dependencies`):** يمنع أن يستورد جدول من وحدة معينة جدولاً آخر يقوم بدوره باستيراد الجدول الأول. في حال وجود علاقة ربط هرمية، يتم التعامل مع المفاتيح الخارجية كـ `UUID strings` نظيفة دون فرض استيراد تبادلي يتسبب في انهيار شجرة التجميع (`Build Graph Breakdown`).
4. **تقليل وقت التجميع (`Build Runner Optimization`):** 
   - فصل الجداول والـ `DAOs` عن نقاط الدخول الرئيسية يقلل من حجم إعادة التحليل (`Re-analysis overhead`).
   - استيراد محولات الـ `TypeConverters` والـ `Enums` بشكل محدد ومعزول يمنع `build_runner` من إعادة توليد أكواد جداول غير متعلقة عند تعديل ملف مستقل.
5. **قابلية التوسع وإضافة وحدات جديدة (`Plug-and-Play Scalability`):** عند الحاجة المستقبليّة (بعد التجميد الحالي) لإضافة وحدة جديدة (مثل `Manufacturing Module`)، يتم ببساطة إنشاء مجلد `tables/manufacturing/` وإنشاء `ManufacturingDao` في `daos/` وإضافتها لنقطة الدخول المركزية `app_database.dart` دون أي تعديل أو تعارض مع الوحدات العشر الحالية.
6. **سهولة وسرعة التراص والاختبار (`Isolated Unit Testing & Mocking`):** بفضل هيكل الـ `Module-Driven DAOs` والفصل الواضح للجداول، يمكن اختبار كل وحدة وظيفية في بيئة `In-Memory SQLite Database` معزولة تماماً واختبار استعلاماتها وحركاتها التبادلية في ثوانٍ معدودة.

---

## Final Validation Report

- Project Structure .............. PASS
- Module Separation .............. PASS
- Scalability .................... PASS
- Maintainability ................ PASS
- Performance Organization ....... PASS
- Architecture Compliance ........ PASS

**Drift Project Structure Specification Completed ✅**
