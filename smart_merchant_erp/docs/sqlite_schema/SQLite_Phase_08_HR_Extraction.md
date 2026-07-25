# SQLite Schema Extraction
## Phase 8 — Human Resources (HR)
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`
**Date:** 2026-07-18

---

## Architecture Compliance & Single Source of Truth Mandate

> [!IMPORTANT]
> **Single Source of Truth Mandate for Human Resources (HR):**
> تطبيق **Flutter SQLite ERP** هو المصدر الرسمي والوحيد (Single Source of Truth) لجميع بيانات الموارد البشرية، وتشمل:
> (الأقسام، المسميات الوظيفية، الموظفين، ومستندات الموظفين). جميع عمليات إنشاء وتعديل وإدارة بيانات الموارد البشرية تتم محلياً داخل SQLite.
> 
> **مسؤولية Laravel PostgreSQL:**  
> ليس مسؤولاً عن إنشاء أو تعديل بيانات الموارد البشرية أو تنفيذ عملياتها، وتقتصر مسؤوليته فقط على: استقبال البيانات بعد المزامنة، التقارير المركزية، لوحة التحكم Dashboard، التحليلات، وحفظ النسخة السحابية.
>
> **اتجاه المزامنة الرسمي:**  
> `Flutter SQLite ERP` → `Sync Engine` → `Laravel PostgreSQL` → `Dashboard / Reporting`
> 
> عند ظهور جداول سبق استخراجها أو جداول خارجية في العلاقات (`businesses`, `branches`, `users`, `chart_of_accounts`, `currencies`, `payment_methods`, `payments` إلخ)، يتم توثيق العلاقة فقط كمرجع دون إعادة استخراجها أو نسخ أعمدتها.

---

## 1. Table: `departments`

### 1. General Information
- **Table Name:** `departments`
- **Purpose:** Human Resources departments hierarchy per business.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `department_name`| `string(100)` | No | — | |
| `department_code`| `string(50)` | Yes | — | |
| `parent_id` | `uuid` | Yes | — | Self-referential composite FK |
| `manager_id` | `uuid` | Yes | — | Composite FK → employees (nullable initially) |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), composite `(business_id, parent_id)` → `departments` (self, RESTRICT), composite `(business_id, manager_id)` → `employees` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, department_name)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `departments` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `departments` | `departments` | `belongsTo` (Parent/Child) | `parent_id` | `RESTRICT` | *غير محدد* |
| `employees` | `departments` | `belongsTo` (Manager) | `manager_id` | `SET NULL` | *غير محدد* |

*(Note: acts as parent `hasMany` for `Employee` (`employees`) and `Department` (`children`)).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, department_name)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `department_name`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, department_name)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` / `(50)` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** هيكل الأقسام الإدارية وتعيين مديري الأقسام يدار محلياً في الـ ERP ويعتبر المرجع لتوزيع الموظفين محلياً، ويتطلب المزامنة مع السحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 2. Table: `job_titles`

### 1. General Information
- **Table Name:** `job_titles`
- **Purpose:** Employee job titles classification per business.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `title_name` | `string(100)` | No | — | |
| `description` | `text` | Yes | — | |
| `is_active` | `boolean` | No | `true` | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, title_name)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `job_titles` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |

*(Note: acts as parent for `Employee.job_title_id`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, title_name)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `title_name`, `is_active`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, title_name)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `is_active` = `true`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(100)` | `TEXT` | `TextColumn` |
| `text` | `TEXT` | `TextColumn` |
| `boolean` | `INTEGER` | `BoolColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** المسميات الوظيفية تُنشأ وتدار محلياً لربط الموظفين بها وتتطلب المزامنة لتوحيد التعريفات الوظيفية عبر الفروع والسحابة.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 3. Table: `employees`

### 1. General Information
- **Table Name:** `employees`
- **Purpose:** Employee personnel records linked optionally to a system user account and department.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | FK → businesses (CASCADE) |
| `user_id` | `uuid` | Yes | — | FK → users (SET NULL) |
| `employee_code` | `string(50)` | No | — | |
| `first_name` | `string(100)` | No | — | |
| `last_name` | `string(100)` | No | — | |
| `email` | `string(255)` | Yes | — | |
| `phone` | `string(30)` | Yes | — | |
| `hire_date` | `date` | No | — | |
| `termination_date`| `date` | Yes | — | CHECK: >= hire_date |
| `department_id` | `uuid` | Yes | — | Composite FK → departments |
| `job_title_id` | `uuid` | Yes | — | Composite FK → job_titles |
| `salary` | `decimal(18,2)` | No | `0.00` | CHECK: >= 0 |
| `currency_id` | `uuid` | No | — | FK → currencies |
| `status` | `string(20)` | No | `'Active'` | CHECK: Active, Terminated, OnLeave |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |
| `deleted_at` | `timestamp` | Yes | — | Soft Delete |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** `business_id` → `businesses.id` (CASCADE), `user_id` → `users.id` (SET NULL), `currency_id` → `currencies.id` (RESTRICT), composite `(business_id, department_id)` → `departments` (SET NULL), composite `(business_id, job_title_id)` → `job_titles` (SET NULL)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`, `(business_id, employee_code)`, `(business_id, user_id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `businesses` | `employees` | `belongsTo` | `business_id` | `CASCADE` | *غير محدد* |
| `users` | `employees` | `belongsTo` | `user_id` | `SET NULL` | *غير محدد* |
| `departments` | `employees` | `belongsTo` | `department_id` | `SET NULL` | *غير محدد* |
| `job_titles` | `employees` | `belongsTo` | `job_title_id` | `SET NULL` | *غير محدد* |
| `currencies` | `employees` | `belongsTo` | `currency_id` | `RESTRICT` | *غير محدد* |

*(Note: acts as parent `hasMany` for `Department` (`managedDepartments`), `EmployeeDocument`, `AttendanceRecord`, `PayrollSlip`).*

> [!NOTE]
> **ملاحظة هندسية حول نماذج HR بدون هجرات:**  
> النماذج `AttendanceRecord` (`attendance_records`) و `PayrollSlip` (`payroll_slips`) مذكورة في العلاقات وموجودة في ملفات Models (`App\Domains\HR\Models\`)، ولكن **لا توجد لها جداول منشأة في ملفات الهجرة (Migrations)** داخل مرجع قاعدة البيانات المعتمد، حيث تمثل بنيات مخطط لها أو معلقة ولا يتم استخراجها كجداول حالية.

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`, `(business_id, employee_code)`, `(business_id, user_id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `employee_code`, `first_name`, `last_name`, `hire_date`, `salary`, `currency_id`, `status`
- **UNIQUE Constraints:** `(business_id, id)`, `(business_id, employee_code)`, `(business_id, user_id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`, `salary` = `0.00`, `status` = `'Active'`
- **CHECK Constraints:** `chk_emp_dates` (`termination_date >= hire_date`), `chk_emp_salary` (`salary >= 0`), `chk_emp_status` (`status IN ('Active', 'Terminated', 'OnLeave')`)

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(255)` / `(30)` / `(20)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `decimal(18,2)` | `REAL` | `RealColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بيانات الموظفين الأساسية ورواتبهم وحالاتهم الوظيفية تُدار وتعدّل محلياً في SQLite كمرجع حصري للموارد البشرية، وتتطلب الرفع الدوري للمزامنة مع الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## 4. Table: `employee_documents`

### 1. General Information
- **Table Name:** `employee_documents`
- **Purpose:** Employee files, identification documents, and certificates storage tracking.
- **Domain:** DOMAIN 8 — EXTENDED DOMAINS (Human Resources)
- **Database Owner:** SQLite (ERP)

### 2. Columns
| Column Name | PostgreSQL Type | Nullable | Default Value | Description / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `uuid` | No | `gen_random_uuid()` | PK |
| `business_id` | `uuid` | No | — | Composite FK |
| `employee_id` | `uuid` | No | — | Composite FK |
| `document_type` | `string(50)` | No | — | e.g. ID, Passport, Contract |
| `document_number`| `string(100)` | Yes | — | |
| `file_path` | `string(500)` | No | — | |
| `issue_date` | `date` | Yes | — | |
| `expiry_date` | `date` | Yes | — | |
| `created_at` | `timestamp` | Yes | — | |
| `updated_at` | `timestamp` | Yes | — | |

### 3. Keys
- **Primary Key:** `id` (uuid)
- **Foreign Keys:** composite `(business_id, employee_id)` → `employees` (CASCADE)
- **Composite Keys:** None
- **Unique Constraints:** `(business_id, id)`

### 4. Relationships
| Parent Table | Child Table | Relationship Type | Foreign Key Column | On Delete Rule | On Update Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `employees` | `employee_documents`| `belongsTo` | `employee_id` | `CASCADE` | *غير محدد* |

*(Note: Associated composite with `businesses` via `business_id`).*

### 5. Indexes
- **Unique Indexes:** `(business_id, id)`

### 6. Constraints
- **NOT NULL Constraints:** `id`, `business_id`, `employee_id`, `document_type`, `file_path`
- **UNIQUE Constraints:** `(business_id, id)`
- **DEFAULT Constraints:** `id` = `gen_random_uuid()`
- **CHECK Constraints:** None

### 7. SQLite Compatibility
| PostgreSQL Type | SQLite Type | Drift Column Type |
| :--- | :--- | :--- |
| `uuid` | `TEXT` | `TextColumn` |
| `string(50)` / `(100)` / `(500)` | `TEXT` | `TextColumn` |
| `date` | `INTEGER` | `DateTimeColumn` |
| `timestamp` | `INTEGER` | `DateTimeColumn` |

### 8. Offline Metadata Analysis
- **القرار:** يحتاج.
- **السبب:** بيانات تعريف مستندات وشهادات الموظف تُضاف محلياً وتتطلب المزامنة لتوثيق أرشفة الملفات وسجلات المستندات في الخادم.

### 9. Validation
- Table Extraction ........ PASS
- Columns Extraction ...... PASS
- Relationships ........... PASS
- Constraints ............. PASS
- Type Mapping ............ PASS
- SQLite Compatibility .... PASS

---

## Final Verification Report

- HR Tables ................ PASS
- Columns Extraction ....... PASS
- Relationships ............ PASS
- Constraints .............. PASS
- Type Mapping ............. PASS
- SQLite Compatibility ..... PASS
- Architecture Compliance .. PASS

**Ready For Drift Generation — Phase 8 ✅**
