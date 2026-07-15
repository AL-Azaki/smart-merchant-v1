# Account Mapping Entity Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الرسمي لكيان `AccountMapping`. الهدف منها هو توثيق بنية هذا الكيان وكافة القواعد المتعلقة بدورة حياته وعلاقاته، ليكون المرجع الأساسي للتنفيذ في قاعدة البيانات (Migration) وطبقة الـ Model.

---

## 2. Responsibilities
- **حفظ الربط:** تخزين العلاقة بين نوع الحركة (Mapping Type) وبين الحساب المحاسبي (Chart of Account) لكل شركة.
- **تأمين التوجيه:** منع استخدام حسابات غير نشطة أو غير مخصصة للترحيل في الربط.
- **منع التكرار:** ضمان وجود ربط واحد فقط لكل نوع حركة داخل نفس الشركة.

---

## 3. Entity Classification
- **Domain:** Finance
- **Type:** Aggregate Root (بالنسبة لإعدادات الربط المحاسبي).
- **Tenant Scope:** مرتبط بالشركة (`business_id`).

---

## 4. Relationships
- **belongsTo:** `Business` (الشركة المالكة للربط).
- **belongsTo:** `ChartOfAccount` (الحساب المحاسبي المرتبط).
(لا يُسمح بأي علاقات أخرى خارج هذا النطاق).

---

## 5. Lifecycle
- **إنشاء (Create):** يتم عند تهيئة الإعدادات المالية للشركة وتحديد حساب لكل نوع ربط.
- **تحديث (Update):** يمكن تعديل الحساب المربوط إذا تغيرت السياسة المالية.
- **حذف (Delete):** يُسمح بحذف الربط (Hard Delete) إذا لم تعد الشركة بحاجة إليه أو لإنشاء ربط جديد، ولا يستخدم الـ `SoftDeletes` نهائياً.

---

## 6. Business Rules
- **Unique Constraint:** لا يمكن أن تمتلك نفس الشركة أكثر من ربط واحد نشط لنفس نوع الحركة (`business_id`, `mapping_type`).
- **Isolation:** كل شركة تمتلك إعدادات ربط معزولة تماماً ولا تتشارك الحسابات مع شركات أخرى.

---

## 7. Mapping Types
الأنواع المسموحة في الإصدار V1 هي فقط:
- SalesRevenue
- SalesDiscount
- SalesTax
- AccountsReceivable
- PurchaseExpense
- AccountsPayable
- Cash
- Bank
- Inventory
- InventoryAdjustment
- COGS
- OpeningBalance
- ManualJournal

---

## 8. Validation Rules
- `business_id`: إلزامي، ويجب أن يكون UUID صالحاً.
- `mapping_type`: إلزامي، ويجب أن ينتمي للأنواع المعرفة في V1 حصراً (String, Max: 50).
- `chart_of_account_id`: إلزامي، ويجب أن يكون UUID صالحاً لحساب يتبع لنفس الـ `business_id` ويكون `is_active = true` و `allow_posting = true`.

---

## 9. Ownership Rules
- النطاق المالي (Finance Domain) هو المالك الوحيد والمسؤول عن إدارة هذا الكيان.
- لا يجوز لأي نطاق تشغيلي آخر تعديله أو حذفه.

---

## 10. Mutability Rules
- **Mutable:** يمكن تغيير الـ `chart_of_account_id` المربوط بأي نوع.
- بمجرد تغيير الربط، فإن الحركات الجديدة ستأخذ الحساب الجديد، بينما الحركات القديمة والمرحلة لا تتأثر لأنها تمتلك نسخة ثابتة (Snapshot) خاصة بها داخل `JournalEntryLine`.

---

## 11. Dependencies
تتكامل هذه الوثيقة وتخضع تماماً للقواعد الموجودة في:
- `Finance_Account_Mapping_Foundation_Architecture.md`
- `Finance_General_Ledger_Foundation_Architecture.md`
- `Posting_Engine_Contract_Architecture.md`

---

## 12. Security Rules
- يمنع قطعياً تمرير أي `mapping_type` غير معرف ضمن الـ Supported Types.
- يمنع ربط أي حساب ينتمي لشركة أخرى (Cross-Tenant Validation).
- يمنع استخدام حساب رئيسي (Header Account).

---

## 13. Out Of Scope
- ربط معقد مبني على شروط ديناميكية (Dynamic Rules).
- نظام الموافقات على التعديل (Workflow Approval).
- حفظ النسخ التاريخية للربط (Versioning).
