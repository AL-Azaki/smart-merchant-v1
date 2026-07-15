# Finance Dependency Diagram

هذه الوثيقة تمثل المرجع النهائي لترتيب تنفيذ كيانات Finance Domain بناءً على الاعتماديات بينها.

---

## 1. AccountType

**Depends On:**
- لا يعتمد على أي كيان داخل Finance Domain.
- يعتمد على وجود النظام الأساسي فقط (System Level).

**Required Before:**
- ChartOfAccount

**Dependency Reason:**
كيان تأسيسي يُعبّأ عبر Seeder. يجب أن يكون موجوداً قبل إنشاء أي حساب في شجرة الحسابات لأن كل حساب ينتمي لنوع محدد.

---

## 2. ChartOfAccount

**Depends On:**
- AccountType
- Business (Core Domain)

**Required Before:**
- JournalEntryLine

**Dependency Reason:**
كل حساب في الشجرة يجب أن ينتمي لنوع حساب (AccountType). ويجب أن يرتبط بشركة (Business) لتحقيق عزل البيانات. يجب أن تكون الشجرة موجودة قبل إنشاء أي سطر قيد يومي.

---

## 3. FiscalYear

**Depends On:**
- Business (Core Domain)

**Required Before:**
- FiscalPeriod

**Dependency Reason:**
يرتبط بالشركة مباشرة. يجب أن يكون موجوداً قبل إنشاء الفترات المحاسبية التابعة له.

---

## 4. FiscalPeriod

**Depends On:**
- FiscalYear

**Required Before:**
- JournalEntry

**Dependency Reason:**
كيان تابع لـ FiscalYear. يجب أن يكون موجوداً قبل ترحيل أي قيد يومي لأن كل قيد يرتبط بفترة محاسبية محددة.

---

## 5. ExchangeRate

**Depends On:**
- Business (Core Domain)
- Currency (Core Domain)

**Required Before:**
- JournalEntry (في حالة القيود متعددة العملات)

**Dependency Reason:**
يعتمد على تعريف العملات الموجودة في Core Domain. يجب أن يكون متاحاً قبل إنشاء قيود بعملات أجنبية لتخزين سعر الصرف كـ Snapshot.

---

## 6. Tax

**Depends On:**
- Business (Core Domain)

**Required Before:**
- لا يوجد كيان داخل Finance يعتمد عليه مباشرة. يُستخدم من قبل Sales و Purchasing.

**Dependency Reason:**
يرتبط بالشركة فقط. كيان مرجعي مستقل لا يعتمد على أي كيان مالي آخر.

---

## 7. PaymentTerm

**Depends On:**
- Business (Core Domain)

**Required Before:**
- لا يوجد كيان داخل Finance يعتمد عليه مباشرة. يُستخدم من قبل Sales و Purchasing.

**Dependency Reason:**
يرتبط بالشركة فقط. كيان مرجعي مستقل يُعرّف شروط الدفع.

---

## 8. CashRegister

**Depends On:**
- Business (Core Domain)
- Branch (Core Domain)

**Required Before:**
- Payment (كوجهة للدفع النقدي)

**Dependency Reason:**
يرتبط بشركة وفرع محددين. يجب أن يكون موجوداً قبل تسجيل عمليات الدفع النقدية التي تستهدف خزينة.

---

## 9. BankAccount

**Depends On:**
- Business (Core Domain)
- Currency (Core Domain)

**Required Before:**
- Payment (كوجهة للدفع البنكي والتحويلات)

**Dependency Reason:**
يرتبط بشركة وعملة محددتين. يجب أن يكون موجوداً قبل تسجيل عمليات الدفع البنكية أو التحويلات.

---

## 10. JournalEntry

**Depends On:**
- Business (Core Domain)
- FiscalPeriod

**Required Before:**
- JournalEntryLine
- Payment (كل عملية دفع مرحلة تولد قيداً)

**Dependency Reason:**
يرتبط بشركة وفترة محاسبية. يجب أن يكون موجوداً قبل إنشاء سطور القيد. ويجب أن تكون بنيته جاهزة قبل بناء Payment لأن كل عملية دفع مرحلة تولد قيداً.

---

## 11. JournalEntryLine

**Depends On:**
- JournalEntry
- ChartOfAccount

**Required Before:**
- لا يوجد كيان يعتمد عليه مباشرة.

**Dependency Reason:**
كيان تابع لـ JournalEntry. كل سطر يشير لحساب في شجرة الحسابات (ChartOfAccount). لا يمكن إنشاؤه دون وجود كليهما.

---

## 12. Payment

**Depends On:**
- Business (Core Domain)
- JournalEntry (يولد قيداً عند الترحيل)
- CashRegister (للدفع النقدي)
- BankAccount (للدفع البنكي والتحويلات)

**Required Before:**
- لا يوجد كيان يعتمد عليه مباشرة.

**Dependency Reason:**
كيان حركي يعتمد على وجود الوجهات المالية (خزينة أو حساب بنكي) وعلى جاهزية منظومة القيود اليومية (JournalEntry) لأن كل عملية دفع مرحلة تولد قيداً عبر Posting Engine.

---

## Dependency Matrix

| Entity | Depends On | Required Before |
| :--- | :--- | :--- |
| AccountType | — | ChartOfAccount |
| ChartOfAccount | AccountType, Business | JournalEntryLine |
| FiscalYear | Business | FiscalPeriod |
| FiscalPeriod | FiscalYear | JournalEntry |
| ExchangeRate | Business, Currency | JournalEntry |
| Tax | Business | — |
| PaymentTerm | Business | — |
| CashRegister | Business, Branch | Payment |
| BankAccount | Business, Currency | Payment |
| JournalEntry | Business, FiscalPeriod | JournalEntryLine, Payment |
| JournalEntryLine | JournalEntry, ChartOfAccount | — |
| Payment | Business, JournalEntry, CashRegister, BankAccount | — |

---

## Implementation Order

1. **AccountType** — لا يعتمد على أي كيان مالي. نقطة البداية.
2. **ChartOfAccount** — يعتمد فقط على AccountType (تم بناؤه في الخطوة 1).
3. **FiscalYear** — يعتمد فقط على Business (Core Domain — موجود).
4. **FiscalPeriod** — يعتمد فقط على FiscalYear (تم بناؤه في الخطوة 3).
5. **ExchangeRate** — يعتمد فقط على Business و Currency (Core Domain — موجودان).
6. **Tax** — يعتمد فقط على Business (Core Domain — موجود).
7. **PaymentTerm** — يعتمد فقط على Business (Core Domain — موجود).
8. **CashRegister** — يعتمد على Business و Branch (Core Domain — موجودان).
9. **BankAccount** — يعتمد على Business و Currency (Core Domain — موجودان).
10. **JournalEntry** — يعتمد على Business و FiscalPeriod (تم بناؤه في الخطوة 4).
11. **JournalEntryLine** — يعتمد على JournalEntry (الخطوة 10) و ChartOfAccount (الخطوة 2). يُبنى ضمن نفس Aggregate مع JournalEntry.
12. **Payment** — يعتمد على JournalEntry (الخطوة 10) و CashRegister (الخطوة 8) و BankAccount (الخطوة 9). آخر كيان في سلسلة البناء.

**ملاحظة:** الكيانات من 5 إلى 9 (ExchangeRate, Tax, PaymentTerm, CashRegister, BankAccount) لا تعتمد على بعضها البعض ويمكن بناؤها بالتوازي. تم ترتيبها حسب الأولوية المنطقية فقط (Reference Data أولاً، ثم Operational Entities).

---

## Development Readiness

- **هل جميع الاعتماديات واضحة؟** نعم. جميع الاعتماديات بين الكيانات الـ 12 موثقة ولا توجد تبعيات دائرية.
- **هل يوجد أي كيان يمنع البدء بالتنفيذ؟** لا. جميع الاعتماديات الخارجية (Business, Branch, Currency) موجودة ومبنية بالكامل في Core Domain المُجمّد.
- **هل أصبح ترتيب التنفيذ معتمداً؟** نعم. ترتيب التنفيذ أعلاه هو الترتيب الرسمي المعتمد لبناء Finance Domain.

---

## Approval

- **Status:** APPROVED
- **Version:** Finance Dependency Diagram v1.0
