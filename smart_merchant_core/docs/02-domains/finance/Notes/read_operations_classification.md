# Architecture Standard: Read Operations Classification

**Status:** APPROVED
**Scope:** Entire Smart Merchant ERP (Core, Catalog, Inventory, Sales, Finance, HR, Extended)

جميع عمليات القراءة (Read Operations) داخل النظام تُصنّف وتُنفّذ وفقاً لثلاثة أنماط رئيسية حصراً. يمنع الخلط بينها أو ابتكار أنماط قراءة جديدة دون اعتماد معماري مسبق.

---

## 1. View Operation
- **المسؤولية:** استرجاع سجل واحد فقط (Single Record).
- **الخصائص:**
  - يعتمد على الـ Identifier (مثل الـ UUID).
  - يدعم تضمين العلاقات (Includes) بنظام Whitelist.
  - يرمي `DomainException` (مثل `CoreDomainException`) في حال عدم وجود السجل بدلاً من الـ 404 الافتراضي، لضمان معالجة الخطأ ضمن طبقة الـ Application.
- **التسمية:** `View<Entity>Action`, `View<Entity>DTO`

---

## 2. List Operation
- **المسؤولية:** استرجاع قائمة عامة لجميع السجلات التابعة للشركة (Tenant) دون فلاتر.
- **الخصائص:**
  - يدعم التقسيم (Pagination).
  - يدعم الترتيب (Sorting) والترتيب الافتراضي (Default Ordering).
  - يدعم تضمين العلاقات (Includes).
  - **ممنوع قطعياً** احتوائه على Business Filters (مثل الحالة، أو التاريخ، أو نصوص البحث).
- **التسمية:** `List<Entity>sAction`, `<Entity>ListCriteriaDTO`
- **مثال للـ Repository:** `paginate(<Entity>ListCriteriaDTO $criteria)`

---

## 3. Search Operation
- **المسؤولية:** استرجاع قائمة من السجلات متوافقة مع شروط بحث متقدمة (Business Filters).
- **الخصائص:**
  - مخصص للـ Keyword Search، فلاتر الحالة (Status)، فلاتر التواريخ (Date Filters)، والفلاتر المخصصة (Custom Filters).
  - يدعم التقسيم (Pagination)، الترتيب (Sorting)، والعلاقات (Includes) بنفس طريقة الـ List.
  - **القاعدة الذهبية:** أي فلتر جديد يضاف مستقبلاً يتم إضافته كـ Property داخل الـ `<Entity>SearchCriteriaDTO` فقط، دون الحاجة لتعديل ה-Action أو ה-Controller.
- **التسمية:** `Search<Entity>sAction`, `<Entity>SearchCriteriaDTO`
- **مثال للـ Repository:** `search(<Entity>SearchCriteriaDTO $criteria)`

---

## ⚠️ مبادئ حاسمة
1. لا يجوز للـ **Search** أن يعيد تنفيذ منطق الـ **List**. (هما عمليتان مستقلتان لهما Endpoints و Actions مختلفة).
2. لا يجوز للـ **List** أن يحتوي على Business Filters.
3. جميع عمليات الـ List والـ Search تعتمد على تمرير `DTOs` للـ Repository، ويُمنع تمرير مصفوفات عشوائية (Arrays).

---

## 4. Search Criteria Design (Build for Current Requirements, Extend for Future Requirements)
- `SearchCriteriaDTO` يجب أن يحتوي فقط على الفلاتر المطلوبة فعلياً في الإصدار الحالي من النظام.
- لا يتم إضافة فلاتر مستقبلية لمجرد توقع استخدامها. أي فلتر جديد يضاف فقط عندما تظهر حاجة عمل (Business Requirement) واضحة ومعتمدة.
- **أهداف هذا المبدأ:**
  - تقليل تعقيد ה-DTO.
  - الحفاظ على بساطة واجهات الـ API.
  - منع تضخم طبقة Application Layer.
  - تسهيل الصيانة والاختبار.
------------------------------------------------------------

## 5. Read Operation Flow

جميع عمليات القراءة داخل النظام يجب أن تمر بنفس التسلسل التالي:

HTTP Request

↓

Request (Validation)

↓

DTO (Criteria)

↓

Policy (Authorization)

↓

Action

↓

Repository

↓

Resource

↓

HTTP Response

------------------------------------------------------------

مسؤولية كل طبقة:

Request

- التحقق من صحة المدخلات فقط.

DTO

- نقل معايير القراءة.

Policy

- التحقق من الصلاحيات.

Action

- تنسيق العملية.
- لا يحتوي على Query Builder.

Repository

- بناء الاستعلام.
- تطبيق Tenant Isolation.
- تطبيق Filters.
- تطبيق Includes.
- تطبيق Sorting.
- تطبيق Pagination.

Resource

- تحويل البيانات إلى JSON.

------------------------------------------------------------

أي مخالفة لهذا التسلسل تعتبر Architecture Violation.

------------------------------------------------------------

## 6. Includes Whitelist Standard

أي علاقة يتم تحميلها عبر Query Parameter (include)

يجب أن تمر عبر Whitelist.

مثال:

Allowed Includes

- business

- users

------------------------------------------------------------

أي علاقة غير موجودة داخل القائمة البيضاء يتم تجاهلها.

ولا يجوز تحميل أي Relation مباشرة من Request.

هدف هذا المعيار:

- منع N+1 Queries.

- حماية العلاقات الداخلية.

- منع كشف بيانات غير مصرح بها.

------------------------------------------------------------

Repository لا يستقبل Includes الخام القادمة من Request.

Action مسؤول عن فلترة الـ Includes أولاً.

------------------------------------------------------------

## 7. Repository Responsibilities

Repository مسؤول عن:

✔ Query Builder

✔ Filters

✔ Includes

✔ Sorting

✔ Pagination

✔ Tenant Isolation

Repository غير مسؤول عن:

✘ Authorization

✘ Validation

✘ Business Rules

✘ HTTP Requests

✘ JSON Responses

أي Business Logic يجب أن يبقى داخل Action.

--------------------------------------------------------

# ============================================================
# Architecture Standard
# Update Operations Standard
# Status: APPROVED
# ============================================================

جميع عمليات Update داخل المشروع تعتمد على:

Partial Update (PATCH Semantics)

============================================================

Request

↓

Update<Entity>DTO

↓

Action

↓

Repository

============================================================

Update DTO

جميع الخصائص تكون Nullable.

ولا يحتوي على أي Business Logic.

============================================================

Repository

لا يستقبل Array.

ولا يستقبل ID فقط.

بل يستقبل:

Entity

+

UpdateDTO

مثال

update(
    Branch $branch,
    UpdateBranchDTO $dto
)

============================================================

تحويل DTO إلى Array

يتم داخل DTO نفسه.

مثال

$dto->toArray()

بحيث يعيد فقط الحقول غير Null.

ولا يسمح بتمرير بيانات غير موجودة.

============================================================

الفوائد

✔ Type Safety

✔ IDE Support

✔ Consistency

✔ No Magic Arrays

✔ Reusable Pattern

============================================================

هذا المعيار إلزامي لجميع عمليات Update داخل المشروع.

- Core

- Catalog

- Inventory

- Purchasing

- Sales

- Finance

- HR

- Extended





# ============================================================



# ============================================================
# Architecture Standard
# State Transition Operations Standard
# Status: APPROVED
# Priority: HIGH
# ============================================================

## الهدف

ليست جميع العمليات في النظام عبارة عن:

- Create
- View
- List
- Search
- Update
- Delete

يوجد نوع آخر من العمليات يسمى:

State Transition Operations

وهي العمليات التي تغير "حالة" الكيان (State) دون تعديل بياناته الأساسية.

============================================================

## أمثلة

Core Domain

- Set Default Branch
- Activate Branch
- Deactivate Branch

Sales Domain

- Approve Sales Invoice
- Cancel Sales Invoice
- Post Sales Invoice

Purchasing Domain

- Approve Purchase Invoice
- Cancel Purchase Invoice

Finance Domain

- Post Journal Entry
- Reverse Journal Entry
- Close Fiscal Period
- Reopen Fiscal Period

HR Domain

- Approve Payroll
- Lock Payroll

============================================================

## خصائص State Transition

هذه العمليات:

✔ لا تعدل بيانات الكيان العامة.

✔ لا تستخدم UpdateDTO.

✔ لكل عملية Action مستقلة.

✔ لكل عملية Request مستقلة عند الحاجة.

✔ لكل عملية Endpoint مستقل.

============================================================

## التسمية

Action

SetDefaultBranchAction

ActivateBranchAction

DeactivateBranchAction

ApproveSalesInvoiceAction

CloseFiscalPeriodAction

------------------------------------------------------------

Request

SetDefaultBranchRequest

ActivateBranchRequest

DeactivateBranchRequest

============================================================

## Repository

Repository مسؤول فقط عن تنفيذ التغيير المطلوب.

ولا يحتوي على Business Rules.

============================================================

## Business Rules

جميع قواعد الانتقال بين الحالات تبقى داخل Action.

مثال

SetDefaultBranchAction

يتحقق من:

- Business Exists

- Branch Exists

- Branch belongs to Business

- Branch is Active

ثم فقط بعد نجاح جميع الشروط:

يقوم باستدعاء Repository.

============================================================

## Transactions

إذا أثرت العملية على أكثر من سجل:

يجب استخدام DB::transaction().

مثال

Set Default Branch

↓

Remove Default From Old Branch

↓

Set Default To New Branch

هذه العملية Atomic بالكامل.

============================================================

## Return Type

ترجع Entity بعد تحديث حالتها.

ولا ترجع Boolean.

============================================================

## Project Rule

أي عملية تغير حالة الكيان

(State)

يجب أن تعتبر State Transition Operation.

ولا يجوز تنفيذها داخل Update Action.

============================================================

# END OF STANDARD



============================================================

Architecture Decision

Status:

APPROVED

Mandatory:

YES

Applies To:

- Core

- Catalog

- Inventory

- Purchasing

- Sales

- Finance

- HR

- Extended

أي عملية قراءة جديدة داخل المشروع يجب أن تلتزم بهذه الوثيقة.

ولا يجوز إنشاء Read Operation جديدة خارج هذه المعايير إلا بعد اعتماد Architecture Decision جديد.

============================================================



# ============================================================
# Architecture Standard
# Aggregate Root Operations
# Status: APPROVED
# ============================================================

إذا كانت العملية تعمل على Aggregate واحد فقط

↓

تستخدم Action واحدة.

------------------------------------------------------------

إذا كانت العملية تنسق بين أكثر من Aggregate
أو أكثر من عملية مستقلة

↓

تستخدم Orchestrator.

------------------------------------------------------------

أمثلة

Create Role

↓

Action

------------------------------------------------------------

Create Role

+

Sync Permissions

↓

Orchestrator

------------------------------------------------------------

Create User

+

Assign Roles

+

Assign Branches

↓

Orchestrator

------------------------------------------------------------

Create Business

+

Create Branch

+

Create Subscription

↓

Orchestrator

# ============================================================

# ============================================================
# Architecture Standard
# Tenant Aggregate Root
# Status: APPROVED
# Priority: CRITICAL
# ============================================================

## تعريف

يمثل Account الجذر الأعلى (Tenant Aggregate Root)
داخل منصة SaaS.

جميع بيانات العميل في النظام ترجع إليه بشكل مباشر أو غير مباشر.

مثال:

Account
│
├── Businesses
│      ├── Branches
│      ├── Users
│      ├── Roles
│      ├── Inventory
│      ├── Sales
│      └── Finance
│
├── Subscriptions
│
└── Subscription Payments

============================================================

## Responsibilities

Account مسؤول عن:

✔ إدارة المشترك.

✔ حالة المشترك.

✔ حدود الاشتراك.

✔ ملكية الشركات.

✔ نقطة بداية Tenant Isolation.

============================================================

## Important Rule

أي عملية تؤثر على Account

قد تؤثر على جميع البيانات التابعة له.

لذلك:

أي تغيير في حالة Account

(State Transition)

يعتبر عملية عالية الخطورة.

============================================================

## State Cascade

Suspend Account

↓

Suspend Tenant Access

↓

Prevent Login

↓

Stop API Access

↓

Businesses remain unchanged.

Data is never deleted.

============================================================

ملاحظة:

عملية Cascade لا تنفذ داخل Action نفسها.

بل تنفذ لاحقاً عبر Middleware أو Authorization Layer.

Action مسؤولة فقط عن تغيير حالة Account.

============================================================

## Architecture Rule

Account

هو أعلى Aggregate Root داخل النظام.

ولا يوجد أي Entity أعلى منه.

# ============================================================

# ============================================================
# Architecture Standard
# Entity Classification
# Status: APPROVED
# ============================================================

جميع الكيانات داخل النظام تصنف إلى أربعة أنواع.

============================================================

1. Aggregate Root

يمثل نقطة البداية لإدارة البيانات.

أمثلة:

- Account
- Business
- Role
- SalesInvoice
- PurchaseInvoice

============================================================

2. Operational Entity

كيان يمثل عمليات النظام اليومية.

أمثلة:

- Branch
- User
- Customer
- Supplier
- Warehouse

============================================================

3. Reference Master Data

بيانات مرجعية نادرة التغيير.

أمثلة:

- Currency
- Tax
- PaymentMethod
- Unit
- Country

خصائصها:

✔ عدد العمليات قليل.

✔ التعديل نادر.

✔ تستخدم في جميع Domains.

============================================================

4. System Catalog

كيانات معرفة مسبقاً داخل النظام.

أمثلة:

- Permission

تدار بواسطة النظام أو Seeders.

============================================================

أي Entity جديدة يجب تصنيفها قبل البدء في تنفيذها.

# ============================================================
# ============================================================
# Architecture Standard
# Reference Master Data Rules
# Status: APPROVED
# ============================================================

Reference Master Data

يمثل البيانات المرجعية المستخدمة في جميع أنحاء النظام.

أمثلة:

- Currency

- Tax

- Payment Method

- Unit

- Country

============================================================

Business Rules

✔ نادر التغيير.

✔ لا يحذف بعد الاستخدام.

✔ بعض الحقول تصبح Immutable بعد الإنشاء.

✔ يستخدم State Transition بدلاً من الحذف متى أمكن.

============================================================

أي بيانات تشغيلية مرتبطة به

لا تخزن داخله.

بل تنقل إلى Operational Entity مستقلة.

مثال

Currency

↓

ExchangeRate

# ============================================================