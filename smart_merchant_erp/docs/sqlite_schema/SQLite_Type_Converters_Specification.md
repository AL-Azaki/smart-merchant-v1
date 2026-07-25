# SQLite Type Converters Specification
**Project:** Smart Merchant ERP
**Source of Truth:** `Database_Schema_Extraction.md`, `SQLite_Phase_01` to `SQLite_Phase_10`, & `SQLite_Enums_Specification.md`
**Date:** 2026-07-18

---

## Architecture & Governance Rules

> [!IMPORTANT]
> **Frozen Architecture & Single Source of Truth Mandate:**
> تحدد هذه الوثيقة الهندسية كيفية تمثيل وتخزين جميع أنواع البيانات الرسمية المعتمدة في قاعدة بيانات **`SQLite ERP`**، وكيفية ربطها وتحويلها (`Type Conversion`) إلى الأنواع المقابلة لها في لغة **`Dart`** عبر إطار عمل **`Drift ORM`**.
>
> 1. **منع التعديل والابتكار:** جميع أنواع البيانات مستخرجة بدقة من الجداول المستخرجة في المراحل العشر السابقة ومرجع مصدر الحقيقة. يمنع منعاً باتاً اقتراح أنواع بيانات جديدة أو تغيير أي نوع معتمد أو تعديل أسماء الأعمدة والجداول.
> 2. **التخزين في SQLite:** يتم الالتزام الصارم بفئات التخزين الرسمية في SQLite (`TEXT`, `INTEGER`, `REAL`, `BLOB`, `NULL`).
> 3. **التوثيق الهندسي فقط:** هذه الوثيقة هي المرجع المعتمد لإنشاء الجداول والتحويلات البرمجية لاحقاً، ولا تتضمن أو تنشئ أي أكواد برمجية لـ `Dart` أو `Drift TypeConverters` أو `DAOs`.

---

## 1. Data Type Mapping & Conversion Specification

### 1. `UUID`
- **Source Type:** `UUID` (PostgreSQL `uuid`)
- **SQLite Storage Type:** `TEXT`
- **Dart Runtime Type:** `String`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  يتم تخزين معرفات الـ `UUID` في قاعدة بيانات `SQLite` على شكل سلاسل نصية قياسية مكونة من 36 حرفاً (`TEXT`). نظراً لأن إطار عمل `Drift` يقوم بربط عمود `TextColumn` بشكل مباشر ومدمج مع نوع البيانات `String` في لغة `Dart`، فإنه لا توجد حاجة لإنشاء محول بيانات مخصص (`TypeConverter`) للـ UUID.

---

### 2. `TEXT / VARCHAR / STRING`
- **Source Type:** `TEXT`, `VARCHAR`, `STRING(n)` (PostgreSQL `string(n)`, `text`)
- **SQLite Storage Type:** `TEXT`
- **Dart Runtime Type:** `String`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  تُخزن جميع النصوص والأسماء والعناوين والرموز القياسية مباشرة ضمن فئة التخزين `TEXT` في `SQLite`. تُترجم هذه الأعمدة تلقائياً في `Drift` إلى كائنات `String` في `Dart` دون أي حاجة لتحويل إضافي.

---

### 3. `INTEGER / BIGINT`
- **Source Type:** `INTEGER`, `BIGINT` (PostgreSQL `integer`, `bigint`)
- **SQLite Storage Type:** `INTEGER`
- **Dart Runtime Type:** `int`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  تُخزن الأرقام الصحيحة وعدادات التسلسل ومستويات الشجرة المحاسبية كأرقام صحيحة بدقة تصل إلى 64 بت (`INTEGER`) في `SQLite`. يربط عمود `IntColumn` أو `Int64Column` في `Drift` مباشرة مع نوع `int` في لغة `Dart` دون الحاجة لأي محول مخصص.

---

### 4. `BOOLEAN`
- **Source Type:** `BOOLEAN` (PostgreSQL `boolean`)
- **SQLite Storage Type:** `INTEGER`
- **Dart Runtime Type:** `bool`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  قاعدة بيانات `SQLite` لا تمتلك فئة تخزين مخصصة للقيم المنطقية (`Boolean`)، بل تخزن القيم المنطقية رقمياً كـ `INTEGER` حيث يمثل الصفر (`0`) القيمة `false` ويمثل الرقم واحد (`1`) القيمة `true`. يوفر `Drift` عمود `BoolColumn` الذي يتولى عملية التحويل المدمج تلقائياً بين رقم `INTEGER` في قاعدة البيانات والقيمة المنطقية `bool` في `Dart`، مما يلغي الحاجة لكتابة `TypeConverter` خارجي.

---

### 5. `DECIMAL / NUMERIC / REAL`
- **Source Type:** `DECIMAL(p,s)`, `NUMERIC(p,s)` (PostgreSQL `decimal(18,2)`, `decimal(18,4)`, `decimal(18,8)`, `decimal(20,8)`)
- **SQLite Storage Type:** `REAL`
- **Dart Runtime Type:** `double`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  تُخزن جميع المبالغ المالية والأسعار والكميات المخزنية وأسعار الصرف كأرقام عشرية ذات فاصلة عائمة (`REAL`) داخل `SQLite`. يربط `Drift` هذه الأعمدة من خلال `RealColumn` بشكل مباشر مع النوع `double` في `Dart`، وبالتالي لا يلزم إنشاء `TypeConverter` عند استخدام التخزين العائم الافتراضي المعتمد في وثائق استخراج المراحل السابقة.

---

### 6. `DATE`
- **Source Type:** `DATE` (PostgreSQL `date`)
- **SQLite Storage Type:** `INTEGER`
- **Dart Runtime Type:** `DateTime`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  تُخزن تواريخ الاستحقاق وتواريخ الاقتناء وتواريخ الجلسات المالية على شكل طابع زمني رقمي (`Unix Timestamp Integer`) في فئة `INTEGER` داخل `SQLite`. يمتلك `Drift` دعماً أصلياً ومدمجاً عبر عمود `DateTimeColumn` الذي يقوم بتشفير وفك تشفير كائنات `DateTime` في `Dart` من وإلى طوابع `INTEGER` الزمنية في `SQLite` تلقائياً.

---

### 7. `TIMESTAMP`
- **Source Type:** `TIMESTAMP` (PostgreSQL `timestamp`)
- **SQLite Storage Type:** `INTEGER`
- **Dart Runtime Type:** `DateTime`
- **Drift Converter Required:** `No`
- **Conversion Notes:**  
  تُخزن الطوابع الزمنية الكاملة للإنشاء والتحديث وسجلات النشاط وحركات المخزون كأرقام صحيحة (`INTEGER`) تمثل الثواني أو الأجزاء من الثواني منذ حقبة يونكس (`Epoch Time`). يتم الربط المباشر مع كائنات `DateTime` في وقت تشغيل `Dart` عبر `DateTimeColumn` المدمج في `Drift` دون الحاجة لأي محول بيانات مخصص.

---

### 8. `JSON / JSONB`
- **Source Type:** `JSON`, `JSONB` (PostgreSQL `jsonb`, `json` — مثال: `system_settings.setting_value`, `activity_logs.details`)
- **SQLite Storage Type:** `TEXT`
- **Dart Runtime Type:** `Map<String, dynamic>` أو `List<dynamic>`
- **Drift Converter Required:** `Yes`
- **Conversion Notes:**  
  قاعدة بيانات `SQLite` تقوم بتخزين البيانات الهيكلية المعقدة (`JSON/JSONB`) على هيئة سلاسل نصية متسلسلة (`Serialized JSON Strings`) ضمن فئة `TEXT`. ولأن `Drift` يتعامل مع `TEXT` كـ `String` فقط، يتطلب الأمر إنشاء محول بيانات مخصص (`Custom TypeConverter<Map<String, dynamic>, String>`) يقوم بتحويل السلسلة النصية القادمة من `SQLite` إلى هيكل بيانات `Map/List` في `Dart` عند القراءة، وتحويل هيكل `Dart` إلى نص `JSON String` عند حفظ البيانات في قاعدة البيانات.

---

### 9. `ENUM`
- **Source Type:** `ENUM` (`CHECK Constraints` & `PostgreSQL ENUMs`)
- **SQLite Storage Type:** `TEXT`
- **Dart Runtime Type:** `Enum` (تحديداً الـ `Dart Enums` الرسمية المطابقة للوثيقة المرجعية `SQLite_Enums_Specification.md`)
- **Drift Converter Required:** `Yes`
- **Conversion Notes:**  
  تُخزن جميع القوائم المحددة وحالات المستندات (`Status`) وأنواع الحركات (`Transaction Types`) كقيم نصية دقيقة (`TEXT`) في `SQLite` محكومة بقيود `CHECK Constraints`. لضمان الأمان البرمجي (`Type Safety`) ومنع إدخال نصوص غير صالحة في طبقة `Dart`، يلزم إنشاء محول بيانات مخصص (`Custom Drift TypeConverter<DartEnumType, String>`) لكل Enum معتمد، يتولى مطابقة السلسلة النصية المخزنة في `SQLite` مع عنصر الـ `Dart Enum` المقابل له عند القراءة والعكس عند الحفظ.

---

## 2. Official Enums Mapping Reference Table

تعتمد جميع التحويلات الخاصة بـ `ENUM` حصرياً على الوثيقة المرجعية `SQLite_Enums_Specification.md`. يوضح الجدول التالي ارتباط كل Enum معتمد بنوع التخزين ومتطلب المحول:

| Official Enum Name | Target Table(s) | Target Column(s) | SQLite Storage Type | Dart Runtime Type | Drift Converter Required |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `AccountTypeStatus` | `account_types` | `status` | `TEXT` | `AccountTypeStatus` | **Yes** |
| `SystemSettingType` | `system_settings` | `setting_type` | `TEXT` | `SystemSettingType` | **Yes** |
| `PrintPaperSize` | `print_settings` | `paper_size` | `TEXT` | `PrintPaperSize` | **Yes** |
| `SequenceResetFrequency`| `sequences` | `reset_frequency` | `TEXT` | `SequenceResetFrequency`| **Yes** |
| `InventoryTransactionType`| `inventory_transactions` | `transaction_type`| `TEXT` | `InventoryTransactionType`| **Yes** |
| `InventoryMovementDirection`| `inventory_transactions` | `movement_direction`| `TEXT`| `InventoryMovementDirection`| **Yes** |
| `InventoryTransactionStatus`| `inventory_transactions` | `status` | `TEXT` | `InventoryTransactionStatus`| **Yes** |
| `InventoryReferenceType`| `inventory_transactions` | `reference_type` | `TEXT` | `InventoryReferenceType`| **Yes** |
| `InventoryTransferStatus`| `inventory_transfers` | `status` | `TEXT` | `InventoryTransferStatus`| **Yes** |
| `TaxType` | `taxes` | `tax_type` | `TEXT` | `TaxType` | **Yes** |
| `CustomerOpeningBalanceType`| `customers` | `opening_balance_type`| `TEXT`| `CustomerOpeningBalanceType`| **Yes** |
| `SalesChannelType` | `channels` | `channel_type` | `TEXT` | `SalesChannelType` | **Yes** |
| `CartStatus` | `carts` | `status` | `TEXT` | `CartStatus` | **Yes** |
| `SalesInvoicePaymentStatus`| `sales_invoices` | `payment_status` | `TEXT` | `SalesInvoicePaymentStatus`| **Yes** |
| `SalesInvoiceStatus` | `sales_invoices` | `status` | `TEXT` | `SalesInvoiceStatus` | **Yes** |
| `CustomerReceivableStatus`| `customer_receivables` | `status` | `TEXT` | `CustomerReceivableStatus`| **Yes** |
| `ReceivableEntryType` | `receivable_entries` | `entry_type` | `TEXT` | `ReceivableEntryType`| **Yes** |
| `SupplierOpeningBalanceType`| `suppliers` | `opening_balance_type`| `TEXT`| `SupplierOpeningBalanceType`| **Yes** |
| `PurchaseInvoicePaymentStatus`| `purchase_invoices` | `payment_status`| `TEXT` | `PurchaseInvoicePaymentStatus`| **Yes** |
| `PurchaseInvoiceStatus` | `purchase_invoices` | `status` | `TEXT` | `PurchaseInvoiceStatus`| **Yes** |
| `SupplierPayableStatus` | `supplier_payables` | `status` | `TEXT` | `SupplierPayableStatus`| **Yes** |
| `PayableEntryType` | `payable_entries` | `entry_type` | `TEXT` | `PayableEntryType` | **Yes** |
| `FiscalYearStatus` | `fiscal_years` | `status` | `TEXT` | `FiscalYearStatus` | **Yes** |
| `FiscalPeriodStatus` | `fiscal_periods` | `status` | `TEXT` | `FiscalPeriodStatus` | **Yes** |
| `AccountNormalBalance` | `chart_of_accounts` | `normal_balance` | `TEXT` | `AccountNormalBalance`| **Yes** |
| `JournalEntryType` | `journal_entries` | `journal_type`, `document_type`| `TEXT`| `JournalEntryType` | **Yes** |
| `JournalEntryStatus` | `journal_entries` | `status` | `TEXT` | `JournalEntryStatus` | **Yes** |
| `JournalLineType` | `journal_entry_lines` | `type` | `TEXT` | `JournalLineType` | **Yes** |
| `AccountingPeriodStatus`| `accounting_periods` | `status` | `TEXT` | `AccountingPeriodStatus`| **Yes** |
| `PaymentMethodType` | `payment_methods` | `payment_type` | `TEXT` | `PaymentMethodType` | **Yes** |
| `CashRegisterStatus` | `cash_registers` | `status` | `TEXT` | `CashRegisterStatus` | **Yes** |
| `CashTransactionType` | `cash_transactions` | `transaction_type`| `TEXT` | `CashTransactionType`| **Yes** |
| `BankAccountStatus` | `bank_accounts` | `status` | `TEXT` | `BankAccountStatus` | **Yes** |
| `BankTransactionType` | `bank_transactions` | `transaction_type`| `TEXT` | `BankTransactionType`| **Yes** |
| `BankTransactionDirection`| `bank_transactions` | `direction` | `TEXT` | `BankTransactionDirection`| **Yes** |
| `PaymentTransactionType`| `payments` | `payment_type` | `TEXT` | `PaymentTransactionType`| **Yes** |
| `PaymentContactType` | `payments` | `contact_type` | `TEXT` | `PaymentContactType` | **Yes** |
| `PaymentStatus` | `payments` | `status` | `TEXT` | `PaymentStatus` | **Yes** |
| `BankReconciliationStatus`| `bank_reconciliations`| `status` | `TEXT` | `BankReconciliationStatus`| **Yes** |
| `EmployeeStatus` | `employees` | `status` | `TEXT` | `EmployeeStatus` | **Yes** |
| `FixedAssetStatus` | `fixed_assets` | `status` | `TEXT` | `FixedAssetStatus` | **Yes** |
| `DepreciationScheduleStatus`| `depreciation_schedules`| `status` | `TEXT` | `DepreciationScheduleStatus`| **Yes** |
| `ExpenseStatus` | `expenses` | `status` | `TEXT` | `ExpenseStatus` | **Yes** |
| `StockAdjustmentType` | `stock_adjustments` | `adjustment_type` | `TEXT` | `StockAdjustmentType`| **Yes** |
| `StockAdjustmentStatus` | `stock_adjustments` | `status` | `TEXT` | `StockAdjustmentStatus`| **Yes** |

---

## Final Validation Report

- Data Types ................ PASS
- SQLite Compatibility ...... PASS
- Enum Mapping .............. PASS
- UUID Mapping .............. PASS
- Date Mapping .............. PASS
- Numeric Mapping ........... PASS
- JSON Mapping .............. PASS
- Architecture Compliance ... PASS

**SQLite Type Converters Specification Completed ✅**
