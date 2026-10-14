# دليل تشغيل الذكاء الاصطناعي وقوالب البرومبت الجاهزة للتنفيذ
## AI Agent Execution Guide & Turnkey Prompt Templates

**الغرض:** هذا الملف مخصص ليستخدمه المؤسس أو المطور لتوجيه وكلاء الذكاء الاصطناعي (AI Agents) لتنفيذ كل مرحلة من المراحل الخمس بدقة متناهية دون نسيان أي تفصيلة أو الوقوع في الهلوسة البرمجية.

---

## 1. القواعد العامة لتوجيه الذكاء الاصطناعي (AI Prompting Rules)

عند إعطاء أي برومبت للذكاء الاصطناعي، التزم بالقواعد الثلاث الذهبية:
1. **قاعدة حظر الواجهات الوهمية (Zero Mock Tolerance):** "ممنوع استخدام أي بيانات وهمية أو قوائم محلية Mock Data في الواجهات. يجب ربط كل شاشة بـ Riverpod Notifier حقيقي يقرأ ويكتب في الـ Drift SQLite Database".
2. **قاعدة المعاملة الذرية (Atomic Transactions):** "أي دالة Use Case تقوم بأكثر من عملية على قاعدة البيانات (مثل: بيع + تحديث مخزون + قيد يومي) يجب حتماً أن تُغلف بـ `ApplicationTransactionRunner.runInTransaction`".
3. **قاعدة التوثيق المسبق:** "قبل كتابة الكود، قم بقراءة ملف مواصفات المرحلة المخصص كاملاً من مجلد `docs/execution_plan/` والالتزام بمعايير القبول ومحاذير الرفض المذكورة فيه".

---

## 2. قوالب البرومبت الجاهزة للنسخ المباشر (Copy-Paste AI Prompts)

### 🤖 برومبت تنفيذ المرحلة الأولى (Phase 1 Prompt)
```text
مهمتك الآن هي تنفيذ المرحلة الأولى (Phase 1: Core Math Engine, Inventory & Currency Normalization) في مشروع smart_merchant_erp بدقة متناهية.

المستند المرجعي الإلزامي: 
اقرأ أولاً ملف: docs/execution_plan/01_PHASE_1_CORE_MATH_AND_INVENTORY_ENGINE.md

المطلوب تنفيذه برمجياً:
1. إنشاء كلاس الحسابات الدقيقة lib/core/utils/precision_math.dart لمعالجة كسور الفاصلة العائمة (تقريب مالي للعملات برقمين، وتقريب للكميات بـ 3 أرقام، وفحص توازن القيود).
2. تعديل lib/modules/purchasing/application/usecases/record_purchase_usecase.dart:
   - تصحيح معادلة متوسط التكلفة WAC: تحويل سعر شراء الصنف item.unitCost إلى العملة الأساسية Base Currency فوراً باستخدام params.exchangeRate قبل إدخاله في معادلة WAC.
   - تحويل كمية الشراء إلى الوحدة الأساسية Base Unit بضربها في conversionFactor قبل زيادة رصيد المخزن في Inventories.
   - تصحيح سطور القيد اليومي للمخزون والموردين.
3. تعديل lib/modules/sales/application/usecases/complete_sale_usecase.dart:
   - تحويل الكمية المباعة إلى الوحدة الأساسية قبل فحص الرصيد وقبل الخصم من Inventories.
   - تصحيح حساب تكلفة البضاعة المباعة COGS: (الكمية بالوحدة الأساسية * inventory.averageCost) وحذف عملية الضرب الخاطئة في سعر الصرف.
4. التأكد من دالة ProcessStockAdjustmentUseCase لإنشاء قيود عجز وفائض الجرد المتزنة في دفتر الأستاذ.
5. كتابة وتشغيل اختبارات Unit Tests في test/unit/accounting/wac_currency_calculation_test.dart والتأكد من نجاحها بالكامل.

محاذير حاسمة:
- ممنوع تخزين averageCost بغير العملة الأساسية.
- ممنوع خصم المخزون دون ضرب الكمية في معامل التحويل conversionFactor.
- ممنوع السماح بحدوث خطأ DivisionByZeroException إذا كان رصيد المخزون صفراً.
```

---

### 🤖 برومبت تنفيذ المرحلة الثانية (Phase 2 Prompt)
```text
مهمتك الآن هي تنفيذ المرحلة الثانية (Phase 2: Real Chart of Accounts & General Ledger Engine) في مشروع smart_merchant_erp.

المستند المرجعي الإلزامي:
اقرأ أولاً ملف: docs/execution_plan/02_PHASE_2_CHART_OF_ACCOUNTS_AND_REAL_LEDGER.md

المطلوب تنفيذه برمجياً:
1. كتابة خدمة بذر الشجرة التلقائية lib/database/seeders/default_coa_seeder.dart لبذر شجرة الحسابات التجارية القياسية (المستويات الخمسة) وربطها في جدول account_mappings تلقائياً عند تأسيس النشاط التجاري.
2. استكمال دوال CRUD في lib/modules/accounting/application/services/accounting_application_service.dart:
   - createAccount: مع فحص عدم تكرار الكود، ووجود الحساب الأب، واحتساب المستوى، ومنع الترحيل على الحسابات الرئيسية.
   - updateAccount: تعديل الاسم والحالة، ومنع تغيير النوع أو الأب إذا كان للحساب قيود.
   - safeDeleteAccount: فحص journal_entry_lines ومنع حذف أي حساب يحتوي على حركات سابقة قطعياً.
3. تطهير شاشة lib/modules/accounting/presentation/pages/financial_dashboard_view.dart:
   - إزالة كافة كلاسات ومصفوفات الموك (_MockAccount, _mockAccounts, _mockJournalEntries).
   - ربط تبويب دليل الحسابات ChartOfAccountsTab بالـ Provider الحقيقي chartOfAccountsNotifierProvider.
   - ربط تبويب القيود اليومية بالـ Provider الحقيقي journalEntriesNotifierProvider.
4. بناء نافذة القيد اليومي المتقدم lib/modules/accounting/presentation/widgets/journal_entry_form_sheet.dart:
   - نموذج إضافة قيد يومي مع سطور ديناميكية (مدين/دائن/بيان/حساب فرعي).
   - مؤشر توازن حي باللونين الأخضر والأحمر، وتعطيل زر الحفظ طالما أن القيد غير متوازن.
5. كتابة وتشغيل اختبارات test/unit/accounting/chart_of_accounts_tree_test.dart.

محاذير حاسمة:
- ممنوع السماح بالترحيل allow_posting = true على أي حساب رئيسي له أبناء.
- ممنوع حذف أي حساب مسجل في جدول account_mappings أو journal_entry_lines.
```

---

### 🤖 برومبت تنفيذ المرحلة الثالثة (Phase 3 Prompt)
```text
مهمتك الآن هي تنفيذ المرحلة الثالثة (Phase 3: Treasury, Cashflows, Vouchers & Party Settlements) في مشروع smart_merchant_erp.

المستند المرجعي الإلزامي:
اقرأ أولاً ملف: docs/execution_plan/03_PHASE_3_TREASURY_VOUCHERS_AND_PARTIES.md

المطلوب تنفيذه برمجياً:
1. استبدال شاشة حجز المكان في lib/modules/accounting/presentation/pages/receipt_vouchers_view.dart وبناء شاشة سندات القبض الحقيقية:
   - جدول السندات مع البحث والفلترة.
   - نموذج إنشاء سند قبض: اختيار عميل (مع عرض رصيده وقائمة فواتيره الآجلة لتسديدها بنظام FIFO) أو اختيار حساب إيراد عام.
   - تحديد الصندوق/البنك المستلم، والمبلغ وطريقة الدفع.
   - حفظ المعاملة وتحديث رصيد العميل وإنشاء قيد آلي متزن في الأستاذ العام وتوليد إيصال للطباعة.
2. استبدال شاشة حجز المكان في lib/modules/accounting/presentation/pages/payment_vouchers_view.dart وبناء شاشة سندات الصرف الحقيقية:
   - سداد لمورد (تسديد فواتير شراء آجلة وتحديث رصيد المورد) أو سداد مصروف تشغيلي (إيجار، رواتب، كهرباء).
   - خصم المبلغ من الصندوق المحدد وإنشاء قيد آلي متزن.
3. بناء نافذة التحويل الداخلي بين الصناديق والبنوك مع فحص توفر الرصيد وتوليد قيد التحويل.
4. بناء شاشة وخدمة الأرصدة الافتتاحية lib/modules/accounting/presentation/pages/opening_balances_view.dart:
   - إدخال الأرصدة النقدية وديون العملاء والموردين وتوليد القيد الافتتاحي الموزون في رأس المال.
5. كتابة وتشغيل اختبارات test/unit/treasury/voucher_balance_allocation_test.dart.

محاذير حاسمة:
- ممنوع صرف مبلغ أكبر من رصيد الصندوق المتوفر إلا بتصريح السحب على المكشوف.
- ممنوع حذف سند مقبوضات أو مدفوعات؛ التصحيح يتم فقط عبر سند عكسي.
```

---

### 🤖 برومبت تنفيذ المرحلة الرابعة (Phase 4 Prompt)
```text
مهمتك الآن هي تنفيذ المرحلة الرابعة (Phase 4: Financial Reports Engine & Period Closing) في مشروع smart_merchant_erp.

المستند المرجعي الإلزامي:
اقرأ أولاً ملف: docs/execution_plan/04_PHASE_4_FINANCIAL_REPORTS_AND_CLOSING.md

المطلوب تنفيذه برمجياً:
1. استبدال الأرقام النصية الثابتة في تبويب التقارير بقاعدة بيانات حقيقية وبناء الخدمات التالية:
   - lib/modules/reports/application/services/account_statement_service.dart: كشف حساب تفصيلي لعميل، مورد، صندوق، أو حساب عام مع حساب الرصيد الافتتاحي السابق والرصيد التراكمي لكل سطر.
   - lib/modules/reports/application/services/trial_balance_service.dart: ميزان المراجعة بالمجاميع والأرصدة مع التحقق الصارم من توازن الأعمدة.
   - lib/modules/reports/application/services/profit_loss_service.dart: قائمة الدخل (المبيعات - مردودات المبيعات - تكلفة المبيعات COGS = مجمل الربح، ناقص المصروفات التشغيلية = صافي الربح).
   - تقرير تقييم المخزون الفعلي ومطابقته بحساب المخزون في الدفتر العام.
2. تطبيق آلية تاريخ قفل الحركات (Transaction Lock Date) في إعدادات النظام ومنع أي إدخال أو تعديل لحركة سابقة له.
3. بناء دالة الإقفال السنوي (Year-End Close Use Case):
   - تصفير حسابات الإيرادات والمصروفات، وترحيل صافي النتيجة إلى حساب الأرباح المحتجزة / المرحلة (حساب 32)، وتدوير أرصدة الميزانية وتحديث تاريخ القفل.
4. كتابة وتشغيل اختبارات test/integration/scenarios/year_end_close_and_retained_equity_test.dart.

محاذير حاسمة:
- ممنوع حساب الأرباح دون خصم تكلفة البضاعة المباعة COGS.
- ممنوع إرجاع تاريخ القفل للخلف إلا بكلمة مرور المدير العليا.
```

---

### 🤖 برومبت تنفيذ المرحلة الخامسة (Phase 5 Prompt)
```text
مهمتك الآن هي تنفيذ المرحلة الخامسة (Phase 5: Accounting Invariants & Comprehensive Unit Testing Suite) في مشروع smart_merchant_erp.

المستند المرجعي الإلزامي:
اقرأ أولاً ملف: docs/execution_plan/05_TESTING_AND_ACCOUNTING_INVARIANTS.md

المطلوب تنفيذه برمجياً:
1. بناء ملف فحص القواعد الذهبية الشامل:
   test/invariants/ledger_invariants_validator_test.dart
   يتحقق من:
   - قاعدة التوازن المزدوج المطلق لكل قيد في النظام: SUM(Debit) == SUM(Credit).
   - قانون حفظ المخزون: تطابق رصيد المخزن مع مجموع الحركات.
   - تطابق تقييم المخزون مع رصيد حساب بضاعة المخزن في الأستاذ العام.
   - تطابق أرصدة العملاء والموردين والصناديق.
2. بناء اختبارات السيناريوهات المتكاملة:
   - test/integration/scenarios/full_purchase_to_sale_lifecycle_test.dart: شراء بضاعة -> بيع جزء منها -> سداد جزء -> كشف حساب -> تحقق من قائمة الدخل.
   - test/integration/scenarios/sales_return_and_cogs_reversal_test.dart: إرجاع بضاعة والتحقق من عودة المخزن وعكس قيد الإيراد والـ COGS.
   - test/integration/scenarios/atomic_rollback_test.dart: تعمد إفشال قيد والتأكد من عدم خصم المخزون.
3. تشغيل جميع الاختبارات والتأكد من نجاحها 100%:
   flutter test

محاذير حاسمة:
- يجب أن تعمل الاختبارات على NativeDatabase.memory() لتكون سريعة ومنعزلة.
- أي فشل في فحص التوازن المحاسبي يعتبر خطأ P0 حرجاً يمنع دمج الكود.
```

---

## 3. معايير الواجهات وتجربة المستخدم (UI/UX Best Practices)

لضمان واجهات احترافية ومريحة للتاجر، الزم الذكاء الاصطناعي بهذه القواعد:
1. **تنسيق العملات والأرقام:**
   * استخدام منسق أرقام موحد لا يعكس الفواصل الإنجليزية مع النصوص العربية:
     `NumberFormat('#,##0.00', 'en_US').format(amount)` مع إضافة رمز العملة بجانبها (مثلاً: `1,500.00 ر.ي`).
2. **شاشات التحميل والحالات الفارغة (States):**
   * ممنوع الشاشات البيضاء أو الدوائر الدوارة العشوائية:
     * أثناء التحميل: استخدام Skeletal shimmer بارتفاعات مطابقة لعناصر القائمة.
     * القائمة فارغة: ويدجت أنيقة بأيقونة واضحة وزر CTA مباشر (مثلاً: "لا توجد سندات قبض مسجلة اليوم - اضغط هنا لإنشاء سند جديد").
     * الخطأ: بطاقة خطأ واضحة باللون الأحمر الهادئ مع زر "إعادة المحاولة" (Retry).
3. **التجاوب مع الشاشات (Responsive Design):**
   * شاشة الكاشير والمبيعات يجب أن تعمل بسلاسة على شاشات التابلت والشاشات اللمسية العريضة (Landscape) مع لوحة مفاتيح أرقام كبيرة (Numpad) لتسريع الإدخال دون الحاجة للكيبورد التقليدي.
