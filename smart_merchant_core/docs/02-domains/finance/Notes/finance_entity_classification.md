# Finance Entity Classification

هذه الوثيقة تمثل المرجع النهائي لتصنيف جميع كيانات Finance Domain. جميع التصنيفات الواردة هنا ثابتة ومعتمدة كأساس لمرحلة التنفيذ.

---

## 1. AccountType

- **Classification:** System Catalog
- **Ownership:** مستقل. لا يتبع لأي كيان آخر.
- **Tenant Scope:** System Level
- **Lifecycle:** لا يمتلك دورة حياة مستقلة. بيانات ثابتة يتم تعبئتها عبر Seeder.
- **Mutability:** Reference Data
- **Deletion Strategy:** No Delete
- **Relationships:**
  - hasMany ChartOfAccount
- **Notes:** يمثل التصنيفات المحاسبية الخمسة الأساسية (Assets, Liabilities, Equity, Revenue, Expenses). بيانات مُعرّفة مسبقاً في النظام ولا يُنشئها المستخدم.

---

## 2. ChartOfAccount

- **Classification:** Reference Master Data
- **Ownership:** مستقل. يمثل شجرة هرمية ذاتية المرجع (Self-Referencing).
- **Tenant Scope:** Business Level
- **Lifecycle:** لا يمتلك دورة حياة مستقلة. يمكن تعديل بياناته الوصفية.
- **Mutability:** Mutable (باستثناء AccountType الذي لا يتغير بعد الإنشاء).
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا احتوى على حركات مرحلة).
- **Relationships:**
  - belongsTo AccountType
  - belongsTo Business (Core Domain)
  - belongsTo ChartOfAccount (parent — self-referencing)
  - hasMany ChartOfAccount (children — self-referencing)
  - hasMany JournalEntryLine
- **Notes:** يتم توليد شجرة افتراضية عند إنشاء Business جديدة. يمكن للمستخدم إضافة حسابات فرعية وتعديل الأسماء. لا يمكن تغيير نوع الحساب (AccountType) بعد الإنشاء.

---

## 3. JournalEntry

- **Classification:** Aggregate Root (Transactional)
- **Ownership:** مستقل. يمتلك JournalEntryLine ككيان تابع.
- **Tenant Scope:** Business Level
- **Lifecycle:** يمتلك دورة حياة مستقلة (Draft → Posted → Reversed). مُعرّفة في Finance Architecture Decisions.
- **Mutability:** Immutable After Posting
- **Deletion Strategy:** Hard Delete (فقط في حالة Draft). No Delete بعد Posting.
- **Relationships:**
  - belongsTo Business (Core Domain)
  - belongsTo FiscalPeriod
  - hasMany JournalEntryLine
- **Notes:** يحمل المرجع المصدري الموحد (document_type, document_id, document_number). يحمل عملة العملية وسعر الصرف كـ Snapshot. رقم القيد (Journal Number) يُولّد مركزياً ولا يُعدّل يدوياً.

---

## 4. JournalEntryLine

- **Classification:** Child Entity
- **Ownership:** JournalEntry
- **Tenant Scope:** Business Level (يرث من JournalEntry)
- **Lifecycle:** لا يمتلك دورة حياة مستقلة. يتبع دورة حياة JournalEntry.
- **Mutability:** Immutable After Posting (يرث من JournalEntry)
- **Deletion Strategy:** يتبع JournalEntry. لا يُحذف بشكل مستقل.
- **Relationships:**
  - belongsTo JournalEntry
  - belongsTo ChartOfAccount
- **Notes:** يحتوي على المبلغ بعملة العملية (amount) والمبلغ بالعملة الأساسية (local_amount). يمثل طرف المدين أو الدائن.

---

## 5. FiscalYear

- **Classification:** Aggregate Root (Operational)
- **Ownership:** مستقل. يمتلك FiscalPeriod ككيان تابع.
- **Tenant Scope:** Business Level
- **Lifecycle:** يمتلك دورة حياة مستقلة (Open, Closed).
- **Mutability:** Mutable (حتى الإقفال).
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا احتوت فتراته على قيود مرحلة).
- **Relationships:**
  - belongsTo Business (Core Domain)
  - hasMany FiscalPeriod
- **Notes:** عند الإقفال السنوي يتم ترصيد الحسابات المؤقتة (الإيرادات والمصروفات) وتدوير الأرصدة الدائمة.

---

## 6. FiscalPeriod

- **Classification:** Child Entity
- **Ownership:** FiscalYear
- **Tenant Scope:** Business Level (يرث من FiscalYear)
- **Lifecycle:** يمتلك دورة حياة مرتبطة (Open, Closed). لكنها تُدار من خلال FiscalYear.
- **Mutability:** Mutable (حتى الإقفال).
- **Deletion Strategy:** يتبع FiscalYear. لا يُحذف بشكل مستقل.
- **Relationships:**
  - belongsTo FiscalYear
  - hasMany JournalEntry
- **Notes:** يمنع تسجيل أو ترحيل أي قيد داخل فترة مغلقة. يمثل عادةً شهراً مالياً واحداً.

---

## 7. CashRegister

- **Classification:** Operational Entity
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** يمتلك دورة حياة مستقلة (Active, Inactive).
- **Mutability:** Mutable
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا ارتبط بحركات مالية).
- **Relationships:**
  - belongsTo Business (Core Domain)
  - belongsTo Branch (Core Domain)
- **Notes:** يمثل خزينة نقدية مرتبطة بفرع محدد. يُستخدم كوجهة في عمليات الدفع النقدية.

---

## 8. BankAccount

- **Classification:** Operational Entity
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** يمتلك دورة حياة مستقلة (Active, Inactive).
- **Mutability:** Mutable
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا ارتبط بحركات مالية).
- **Relationships:**
  - belongsTo Business (Core Domain)
  - belongsTo Currency (Core Domain)
- **Notes:** يمثل حساباً بنكياً حقيقياً. يُستخدم كوجهة في عمليات الدفع والتحويلات البنكية.

---

## 9. ExchangeRate

- **Classification:** Reference Master Data
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** لا يمتلك دورة حياة مستقلة.
- **Mutability:** Reference Data (الأسعار المستخدمة في قيود مرحلة لا تُعدّل).
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا استُخدم في قيد مرحل).
- **Relationships:**
  - belongsTo Business (Core Domain)
  - belongsTo Currency (Core Domain — العملة المصدر)
  - belongsTo Currency (Core Domain — العملة الهدف)
- **Notes:** يمثل سعر الصرف بين عملتين في تاريخ محدد. يُخزّن كلقطة (Snapshot) داخل JournalEntry عند الترحيل.

---

## 10. Tax

- **Classification:** Reference Master Data
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** لا يمتلك دورة حياة مستقلة.
- **Mutability:** Mutable
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا استُخدم في عمليات تشغيلية).
- **Relationships:**
  - belongsTo Business (Core Domain)
- **Notes:** يحتوي على تعريف الضريبة ونسبتها. يُستخدم من قبل Sales و Purchasing عند حساب الضرائب على الفواتير.

---

## 11. PaymentTerm

- **Classification:** Reference Master Data
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** لا يمتلك دورة حياة مستقلة.
- **Mutability:** Mutable
- **Deletion Strategy:** Protected Delete (يُمنع الحذف إذا ارتبط بفواتير أو عمليات تشغيلية).
- **Relationships:**
  - belongsTo Business (Core Domain)
- **Notes:** يمثل شروط الدفع (نقدي، 30 يوم، 60 يوم...). يُستخدم من قبل Sales و Purchasing لتحديد تواريخ الاستحقاق.

---

## 12. Payment

- **Classification:** Transactional Entity
- **Ownership:** مستقل.
- **Tenant Scope:** Business Level
- **Lifecycle:** يمتلك دورة حياة مستقلة.
- **Mutability:** Immutable After Posting
- **Deletion Strategy:** Hard Delete (فقط قبل الترحيل). No Delete بعد Posting.
- **Relationships:**
  - belongsTo Business (Core Domain)
  - belongsTo JournalEntry (القيد الذي أنشأه عند الترحيل)
- **Notes:** يدعم ثلاثة أنواع: receipt, voucher, transfer. جميع الأنواع تمثل نفس الكيان ويتم تمييزها بحقل payment_type. كل عملية دفع تولد قيداً يومياً عبر Posting Engine عند الترحيل.

---

## Quick Reference Table

| Entity | Classification | Owner | Tenant Scope |
| :--- | :--- | :--- | :--- |
| AccountType | System Catalog | مستقل | System Level |
| ChartOfAccount | Reference Master Data | مستقل | Business Level |
| JournalEntry | Aggregate Root (Transactional) | مستقل | Business Level |
| JournalEntryLine | Child Entity | JournalEntry | Business Level |
| FiscalYear | Aggregate Root (Operational) | مستقل | Business Level |
| FiscalPeriod | Child Entity | FiscalYear | Business Level |
| CashRegister | Operational Entity | مستقل | Business Level |
| BankAccount | Operational Entity | مستقل | Business Level |
| ExchangeRate | Reference Master Data | مستقل | Business Level |
| Tax | Reference Master Data | مستقل | Business Level |
| PaymentTerm | Reference Master Data | مستقل | Business Level |
| Payment | Transactional Entity | مستقل | Business Level |

---

## Approval

- **Status:** APPROVED
- **Version:** Finance Entity Classification v1.0
