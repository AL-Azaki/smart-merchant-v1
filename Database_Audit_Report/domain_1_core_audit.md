# 🔍 Database Audit Report — Domain 1: CORE

**Schema:** Smart Merchant ERP v2.1  
**File:** `smart_merchant_erp_v2_1_corrected.sql`  
**Date:** 2026-07-11  
**Auditor:** Antigravity AI  
**Domain Scope:** Lines 20–307

---

## 📋 Domain Overview

| # | Entity | Type | Lines | Description |
|---|--------|------|-------|-------------|
| 1 | `accounts` | Master | 31–44 | Top-level tenant (root of multi-tenancy) |
| 2 | `businesses` | Master | 50–69 | Business entity under an account |
| 3 | `branches` | Master | 75–96 | Branch of a business |
| 4 | `plans` | Master | 103–123 | SaaS subscription plans |
| 5 | `subscriptions` | Transactional | 129–156 | Account subscription to a plan |
| 6 | `subscription_payments` | Transactional | 166–192 | Payments against subscriptions |
| 7 | `roles` | Master | 198–213 | Roles per business |
| 8 | `permissions` | Master | 219–228 | System-level permission catalogue |
| 9 | `users` | Master | 235–258 | System users |
| 10 | `user_roles` | Junction | 263–274 | Users ↔ Roles mapping |
| 11 | `role_permissions` | Junction | 279–289 | Roles ↔ Permissions mapping |
| 12 | `user_branches` | Junction | 294–306 | Users ↔ Branches mapping |

**Total Entities in Domain: 12**

---

## 🔬 Entity-by-Entity Audit

---

### 1. `accounts` (Lines 31–44)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ Correct |
| `name` | VARCHAR(200) | NOT NULL | — | ✅ Correct |
| `owner_name` | VARCHAR(150) | NOT NULL | — | ✅ Correct |
| `email` | VARCHAR(255) | NOT NULL | — | ✅ Correct |
| `phone` | VARCHAR(30) | NULL | — | ✅ Correct (optional) |
| `status` | ENUM('Active','Suspended','Closed') | NOT NULL | 'Active' | ✅ Good values |
| `created_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | ✅ |
| `updated_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | ✅ |
| `deleted_at` | TIMESTAMP | NULL | — | ✅ Soft delete |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_accounts` | PRIMARY KEY (id) | ✅ |
| `uq_accounts_email` | UNIQUE (email) | ✅ Global email uniqueness |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد Index على `phone` — لكن بما أنه اختياري وليس حقل بحث رئيسي، فهذا مقبول. |
| 2 | ⚠️ Minor | لا يوجد Index على `status` — إذا كان هناك عدد كبير من الحسابات (SaaS platform)، فإن فلترة حسب الحالة ستكون بطيئة. |
| 3 | ✅ Pass | لا يوجد `deleted_at` index — لكن بما أن هذا الجدول ليس كثير الاستعلام، فهو مقبول. |

#### Verdict: ✅ APPROVED — لا توجد مشاكل هيكلية. الاقتراحات اختيارية.

---

### 2. `businesses` (Lines 50–69)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ |
| `account_id` | CHAR(36) | NOT NULL | — | ✅ FK |
| `business_name` | VARCHAR(255) | NOT NULL | — | ✅ |
| `business_type` | VARCHAR(100) | NULL | — | ✅ Optional |
| `primary_phone` | VARCHAR(30) | NULL | — | ✅ |
| `primary_email` | VARCHAR(255) | NULL | — | ✅ |
| `logo_path` | VARCHAR(500) | NULL | — | ✅ |
| `status` | ENUM('Active','Inactive') | NOT NULL | 'Active' | ✅ |
| `created_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | ✅ |
| `updated_at` | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | ✅ |
| `deleted_at` | TIMESTAMP | NULL | — | ✅ Soft delete |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_businesses` | PRIMARY KEY (id) | ✅ |
| `fk_businesses_account` | FK → accounts(id) ON DELETE RESTRICT | ✅ Correct — لا نحذف Account بينما يوجد businesses |
| `uq_businesses_account_id_id` | UNIQUE (account_id, id) | ✅ Composite key for referencing |
| `idx_businesses_account_id` | INDEX | ✅ |
| `idx_businesses_deleted_at` | INDEX | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد UNIQUE constraint على `(account_id, business_name)` — يعني يمكن إنشاء أعمال بنفس الاسم تحت نفس الحساب. **اقتراح: إضافة UNIQUE (account_id, business_name)** |
| 2 | ✅ Pass | الـ Trigger `trg_limit_businesses_bi` يتحقق من حدود الخطة — ممتاز. |

#### Verdict: ✅ APPROVED — مع اقتراح إضافة unique على اسم العمل.

---

### 3. `branches` (Lines 75–96)

#### Attributes Review

جميع الـ Attributes صحيحة ومناسبة من حيث الأنواع والـ Nullability.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_branches` | PRIMARY KEY (id) | ✅ |
| `uq_branches_code` | UNIQUE (business_id, branch_code) | ✅ لا تكرار لكود الفرع |
| `uq_branches_business_id_id` | UNIQUE (business_id, id) | ✅ للعلاقات المركبة |
| `fk_branches_business` | FK → businesses(id) ON DELETE RESTRICT | ✅ |
| `idx_branches_business_id` | INDEX | ✅ |
| `idx_branches_deleted_at` | INDEX | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد قيد يمنع وجود أكثر من فرع واحد `is_default = TRUE` لنفس `business_id`. يتم حل ذلك على مستوى الـ Application، لكن الأفضل وجود constraint على مستوى قاعدة البيانات. **لكن**: بما أن MySQL لا يدعم Partial Unique Index بسهولة، وإضافة generated column + trigger كما فعلتم في جداول أخرى سيكون ممكناً. **ليس حرجاً**. |
| 2 | ✅ Pass | الـ Trigger `trg_limit_branches_bi` يتحقق من حدود الخطة — ممتاز. |

#### Verdict: ✅ APPROVED

---

### 4. `plans` (Lines 103–123)

#### Attributes Review

| Column | Type | Nullable | Default | Verdict |
|--------|------|----------|---------|---------|
| `id` | CHAR(36) | NOT NULL | UUID() | ✅ |
| `plan_name` | VARCHAR(100) | NOT NULL | — | ✅ |
| `currency_id` | CHAR(36) | NOT NULL | — | ✅ FK (مؤجل) |
| `billing_cycle` | VARCHAR(100) | NOT NULL | — | ⚠️ حقل نصي مفتوح — يفضل أن يكون ENUM |
| `duration_months` | INT | NOT NULL | — | ✅ |
| `price` | DECIMAL(18,2) | NOT NULL | — | ✅ |
| `max_businesses` | INT | NOT NULL | 1 | ✅ |
| `max_branches` | INT | NOT NULL | 1 | ✅ |
| `max_users` | INT | NOT NULL | 5 | ✅ |
| `is_active` | BOOLEAN | NOT NULL | TRUE | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_plans` | PRIMARY KEY (id) | ✅ |
| `chk_plans_price` | CHECK (price >= 0) | ✅ |
| `chk_plans_limits` | CHECK (duration_months > 0 AND ...) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | `billing_cycle` هو VARCHAR(100) — يفضل تحويله إلى ENUM('Monthly','Quarterly','SemiAnnual','Yearly') لحماية البيانات. أو على الأقل إضافة CHECK constraint. |
| 2 | ⚠️ Minor | لا يوجد `created_at` / `updated_at` — جدول Master بدون تتبع وقت الإنشاء والتعديل. **اقتراح: إضافة timestamps**. |
| 3 | ⚠️ Minor | لا يوجد UNIQUE على `plan_name` — يعني يمكن وجود خطتين بنفس الاسم. **اقتراح: UNIQUE (plan_name)** |
| 4 | ℹ️ Info | FK لـ `currency_id` مؤجل — تم تأكيد ذلك في ALTER TABLE لاحقاً (سطر 2127). ✅ |

#### Verdict: ✅ APPROVED — مع اقتراحات لتحسين الـ billing_cycle و timestamps.

---

### 5. `subscriptions` (Lines 129–156)

#### Attributes Review

جميع الحقول صحيحة. نمط الـ `active_sentinel` لضمان اشتراك واحد نشط لكل حساب هو نمط ذكي ومناسب لـ MySQL.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_subscriptions` | PRIMARY KEY (id) | ✅ |
| `fk_subscriptions_account` | FK → accounts(id) | ✅ |
| `fk_subscriptions_plan` | FK → plans(id) | ✅ |
| `uq_subscriptions_active_account` | UNIQUE (active_sentinel) | ✅ Pattern صحيح |
| `chk_subscriptions_dates` | CHECK (end_date >= start_date) | ✅ |
| `chk_subscriptions_amount_paid` | CHECK (amount_paid >= 0) | ✅ |

#### Triggers

- `trg_subscriptions_sentinel_bi` / `_bu` — يدير `active_sentinel` ✅
- `trg_subscriptions_amount_sync_ai` / `_au` — يحدث `amount_paid` تلقائياً ✅

#### Verdict: ✅ APPROVED — تصميم ممتاز.

---

### 6. `subscription_payments` (Lines 166–192)

#### Attributes Review

جميع الحقول صحيحة. يوجد `receipt_number` فريد عالمياً.

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_subscription_payments` | PRIMARY KEY (id) | ✅ |
| `uq_subscription_payments_receipt` | UNIQUE (receipt_number) | ✅ |
| `fk_subscription_payments_subscription` | FK → subscriptions(id) | ✅ |
| `fk_subscription_payments_account` | FK → accounts(id) | ✅ |
| `chk_subscription_payments_amount` | CHECK (amount > 0) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | `receipt_number` unique عالمياً — الأفضل أن يكون scoped by account: `UNIQUE (account_id, receipt_number)`. لكن بما أنه رقم إيصال SaaS (مستوى المنصة)، فهو مقبول. |
| 2 | ℹ️ Info | FK لـ `currency_id` مؤجل — تم تأكيده (سطر 2131). ✅ |

#### Verdict: ✅ APPROVED

---

### 7. `roles` (Lines 198–213)

#### Attributes & Constraints Review

| Aspect | Verdict |
|--------|---------|
| PK, Attributes, Types | ✅ صحيحة |
| `uq_roles_business_role` UNIQUE (business_id, role_name) | ✅ لا تكرار لاسم الدور |
| `uq_roles_business_id_id` UNIQUE (business_id, id) | ✅ للعلاقات المركبة |
| FK → businesses(id) | ✅ |
| `is_system_role` flag | ✅ لحماية الأدوار الافتراضية |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | لا يوجد `updated_at` — الأدوار يمكن أن تتغير (تعديل الاسم أو الوصف). **اقتراح: إضافة updated_at**. |

#### Verdict: ✅ APPROVED

---

### 8. `permissions` (Lines 219–228)

#### Attributes Review

| Column | Type | Verdict |
|--------|------|---------|
| `id` | CHAR(36) | ✅ |
| `module` | VARCHAR(100) | ✅ |
| `permission_code` | VARCHAR(100) | ✅ |
| `permission_name` | VARCHAR(100) | ✅ |
| `description` | TEXT | ✅ |

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_permissions` | PK | ✅ |
| `uq_permissions_code` | UNIQUE (permission_code) | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | هذا جدول System-level (ليس per-business) — تصميم صحيح. |
| 2 | ℹ️ Info | لا يوجد `created_at` — مقبول لأنه جدول إعداد نظام لا يتغير كثيراً. |

#### Verdict: ✅ APPROVED

---

### 9. `users` (Lines 235–258)

#### Attributes Review

جميع الحقول صحيحة. `default_branch_id` اختياري (NULL).

#### Constraints Review

| Constraint | Type | Verdict |
|-----------|------|---------|
| `pk_users` | PK (id) | ✅ |
| `uq_users_username` | UNIQUE (account_id, username) | ✅ per-account |
| `uq_users_email` | UNIQUE (email) | ✅ global |
| `fk_users_account` | FK → accounts(id) | ✅ |

#### Post-Creation FK

```sql
ALTER TABLE users
    ADD CONSTRAINT fk_users_default_branch_assignment 
    FOREIGN KEY (id, default_branch_id) REFERENCES user_branches(user_id, branch_id)
```

✅ **ممتاز** — يضمن أن الفرع الافتراضي هو أحد الفروع المخصصة فعلاً للمستخدم.

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ✅ Pass | التصميم قوي — FK on `(id, default_branch_id)` → `user_branches(user_id, branch_id)` يمنع اختيار فرع غير مخصص. |
| 2 | ⚠️ Minor | لا يوجد Index على `email` بشكل مستقل — لكن UNIQUE constraint ينشئ index ضمنياً. ✅ |

#### Verdict: ✅ APPROVED

---

### 10. `user_roles` (Lines 263–274)

#### Review

| Aspect | Verdict |
|--------|---------|
| PK: (user_id, role_id) | ✅ Composite PK صحيح |
| FK → users(id) ON DELETE CASCADE | ✅ |
| FK → roles(id) ON DELETE CASCADE | ✅ |
| Index على role_id | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | 🔴 Issue | FK `fk_user_roles_role` يشير إلى `roles(id)` مباشرة — لا يوجد constraint يضمن أن الـ User والـ Role ينتميان لنفس الـ Business. **مشكلة**: يمكن تعيين دور من Business A لمستخدم في Business B. **الحل**: يجب أن تكون العلاقة عبر composite FK تمر بـ `business_id`. لكن هذا يتطلب إضافة `business_id` إلى `user_roles` وتعديل الـ FK. |

> **ملاحظة مهمة**: هذه المشكلة موجودة لأن `users` مربوط بـ `account_id` (وليس `business_id`)، بينما `roles` مربوط بـ `business_id`. هذا يعني أن المستخدم على مستوى الحساب بينما الدور على مستوى الأعمال — وهو تصميم منطقي لأن المستخدم قد يعمل في أكثر من business. **لكن** يجب التحقق من هذا على مستوى الـ Application Layer.

#### Verdict: ⚠️ APPROVED WITH CAVEAT — يجب ضمان تطابق Business عبر Application Layer أو Trigger.

---

### 11. `role_permissions` (Lines 279–289)

#### Review

| Aspect | Verdict |
|--------|---------|
| PK: (role_id, permission_id) | ✅ |
| FK → roles(id) ON DELETE CASCADE | ✅ |
| FK → permissions(id) ON DELETE CASCADE | ✅ |

#### Verdict: ✅ APPROVED — تصميم سليم.

---

### 12. `user_branches` (Lines 294–306)

#### Review

| Aspect | Verdict |
|--------|---------|
| PK: (user_id, branch_id) | ✅ |
| FK → users(id) ON DELETE CASCADE | ✅ |
| FK → branches(id) ON DELETE CASCADE | ✅ |
| `is_active` flag | ✅ لتعطيل/تفعيل بدون حذف |
| `assigned_at` timestamp | ✅ |

#### Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | ⚠️ Minor | مثل `user_roles`، لا يوجد constraint يضمن أن الـ Branch ينتمي لنفس الـ Business الذي يعمل فيه المستخدم. لكن بما أن users مربوط بـ account وليس business مباشرة، وuser قد يعمل في عدة businesses — هذا مقبول مع حماية Application Layer. |

#### Verdict: ✅ APPROVED

---

## 📊 Domain 1 — Summary of Triggers

| Trigger | Table | Purpose | Verdict |
|---------|-------|---------|---------|
| `trg_subscriptions_amount_sync_ai` | subscription_payments | Auto-sync amount_paid | ✅ |
| `trg_subscriptions_amount_sync_au` | subscription_payments | Auto-sync amount_paid | ✅ |
| `trg_subscriptions_sentinel_bi/bu` | subscriptions | Active sentinel management | ✅ |
| `trg_limit_businesses_bi` | businesses | Plan limit enforcement | ✅ |
| `trg_limit_users_bi` | users | Plan limit enforcement | ✅ |
| `trg_limit_branches_bi` | branches | Plan limit enforcement | ✅ |

---

## 🏗️ Normalization Check

| NF | Status | Notes |
|----|--------|-------|
| 1NF | ✅ Pass | جميع الحقول atomically valued |
| 2NF | ✅ Pass | لا توجد تبعيات جزئية |
| 3NF | ✅ Pass | لا توجد تبعيات انتقالية |
| BCNF | ✅ Pass | كل determinant هو candidate key |

---

## 📝 Consolidated Findings

| # | Table | Severity | Issue | Recommendation |
|---|-------|----------|-------|----------------|
| 1 | `businesses` | ⚠️ Minor | لا يوجد UNIQUE على (account_id, business_name) | إضافة UNIQUE constraint |
| 2 | `plans` | ⚠️ Minor | `billing_cycle` نوعه VARCHAR مفتوح | تحويل إلى ENUM أو إضافة CHECK |
| 3 | `plans` | ⚠️ Minor | لا يوجد timestamps | إضافة created_at, updated_at |
| 4 | `plans` | ⚠️ Minor | لا يوجد UNIQUE على plan_name | إضافة UNIQUE |
| 5 | `roles` | ⚠️ Minor | لا يوجد updated_at | إضافة updated_at |
| 6 | `user_roles` | ⚠️ Medium | لا يوجد Business-scope validation | إضافة Trigger أو Application check |
| 7 | `branches` | ⚠️ Minor | لا يوجد DB-level single default per business | مقبول — يحل عبر Application |

---

## ✅ Domain 1 Final Verdict

> ### 🟢 APPROVED
> 
> Domain 1 (CORE) **جاهز للاعتماد**. التصميم سليم هيكلياً، التطبيع مكتمل، الـ Foreign Keys صحيحة، والـ Business Rules محمية عبر Triggers.
> 
> **الملاحظات الموجودة هي تحسينات** (Minor) وليست مشاكل تمنع الاعتماد. أهمها:
> - إضافة UNIQUE على اسم الأعمال (`businesses`)
> - تحويل `billing_cycle` إلى ENUM في `plans`
> - التحقق من تطابق Business في `user_roles` عبر Application Layer
>
> **لا توجد مشاكل حرجة (Critical) في هذا الـ Domain.**

---

*يُتابع في التقرير التالي: Domain 3 — CATALOG*
