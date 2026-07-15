# 🏛️ الخطة المعمارية والتنفيذية لـ Smart Merchant ERP (Backend Phase)

## 1. التسميات والهيكلة العامة للمشروع (Monorepo Structure)

بما أن النظام يتكون من عدة منصات (تطبيق، لوحة تحكم/API، ومتجر مستقبلي)، فإن أفضل تنظيم هو استخدام نمط الـ **Monorepo** المنطقي داخل مجلد المشروع الرئيسي `smart_merchant_v1`.

### التسميات المقترحة:
- **اسم قاعدة البيانات (PostgreSQL):** `smart_merchant_db` (قصيرة، معبرة، ومناسبة لبيئة الـ Production). 
  - *لقاعدة بيانات الاختبار (Testing):* `smart_merchant_db_testing`.
- **اسم مجلد الـ Backend (Laravel):** `smart_merchant_core` (لأنه يمثل العقل المدبر، واجهات الـ API، ولوحة التحكم).

### هيكلية المجلدات المقترحة:
```text
d:\ALL-My_Projects\smart_merchant_v1\
│
├── smart_merchant_erp/          # تطبيق Flutter (POS & ERP Mobile/Tablet) [موجود حالياً]
│
├── smart_merchant_core/         # مشروع Laravel (API, Admin Panel, Background Jobs) [جديد]
│
├── smart_merchant_storefront/   # المتجر الإلكتروني المستقبلي (مثلاً Next.js أو Vue/Nuxt) [مستقبلي]
│
├── docs/                        # وثائق المشروع (ملفات SQL، التصاميم، الـ API Specs، خطط العمل)
│
└── .gitignore                   # تجاهل الملفات غير الضرورية على مستوى الـ Workspace
```
> **الميزة:** هذا التنظيم يفصل كل منصة (Frontend/Backend) في بيئة تطوير مستقلة، لكن يجمعهم في مستودع (Workspace) واحد لسهولة التنسيق.

---

## 2. معمارية Offline-First (الأساسيات التي يجب تبنيها اليوم)

بما أن تطبيق Flutter سيعمل كـ Offline-First، يجب أن يتم تصميم Laravel API وقاعدة البيانات لدعم هذه الآلية فوراً:

1. **الاعتماد على UUID:** 
   - تطبيقك (Flutter) سيقوم بتوليد الـ ID (UUID) محلياً عند إنشاء فاتورة أو عميل جديد أوفلاين. 
   - *تم تحقيق ذلك:* قاعدة البيانات (v3.0) تعتمد بالكامل على الـ UUID، مما يمنع تعارض الـ IDs عند المزامنة (Collision).
2. **تتبع التعديلات (Timestamps & Soft Deletes):**
   - الـ API سيعتمد على `updated_at` و `deleted_at` لجلب "ما تغير منذ آخر مزامنة".
   - لا يجوز الحذف النهائي (Hard Delete) لأي كيان، بل نستخدم Soft Deletes لكي يعرف التطبيق أن هذا السجل قد تم حذفه ويقوم بحذفه من قاعدته المحلية.
3. **تصميم Sync API Endpoints:**
   - بدلاً من بناء واجهات CRUD تقليدية للتطبيق، سنبني واجهات مزامنة (Sync API).
   - التطبيق يرسل: `{"last_pulled_at": 1690000000, "changes": {...}}`
   - Laravel يعالج التغييرات المحلية، ثم يعيد للتطبيق التغييرات التي حدثت في السيرفر منذ `last_pulled_at`.

---

## 3. استراتيجية الاختبارات (Unit & Feature Testing)

بما أن النظام محاسبي (مالي)، جودة الكود هي أولوية قصوى.

### في بيئة Laravel (Backend):
- **الاعتماد على Pest PHP أو PHPUnit:** سنقوم بكتابة اختبارات لكل Feature.
- **عزل طبقة الأعمال (Service Pattern):** لن نكتب الكود المعقد داخل الـ Controllers. سننشئ (Services) مثل `JournalEntryService`، وستكون قابلة للاختبار (Unit Testable) بشكل مستقل دون الحاجة لطلبات HTTP.
- **قاعدة بيانات منفصلة للاختبار:** لأننا نستخدم خصائص متقدمة في PostgreSQL (Partial Indexes و Triggers)، لا يمكننا استخدام SQLite للاختبارات (كما هو شائع في Laravel). يجب إعداد `smart_merchant_db_testing` في PostgreSQL لضمان أن الاختبارات تطابق بيئة الإنتاج 100%.

### في بيئة Flutter (Frontend):
- **اختبارات الـ Business Logic (Bloc/Cubit):** التأكد من حساب إجماليات الفواتير والضرائب محلياً بشكل صحيح.
- **اختبارات قاعدة البيانات المحلية (Isar/Drift/Sqflite):** التأكد من أن الحفظ الأوفلاين يعمل.

---

## 4. خطوات التنفيذ (Action Plan)

هذه هي خريطة الطريق التفصيلية التي سنمشي عليها خطوة بخطوة:

### 🟩 المرحلة الأولى: تهيئة بيئة Backend (Laravel)
1. إنشاء مجلد `smart_merchant_core` باستخدام أمر `composer create-project laravel/laravel`.
2. تثبيت الحزم الأساسية:
   - **Filament PHP:** لبناء لوحة تحكم (Admin Panel) احترافية وبسرعة فائقة.
   - **Laravel Sanctum أو Passport:** لإدارة المصادقة والـ API Tokens للتطبيق.
3. إعداد اتصال قاعدة البيانات بـ PostgreSQL في ملف `.env`.
4. إعداد بيئة الاختبار (Testing Database).

### 🟦 المرحلة الثانية: تحويل قاعدة البيانات إلى Laravel Migrations
هذه المرحلة حساسة، سنقوم بتحويل ملف `smart_merchant_erp_v3_final.sql` إلى ملفات Migration.
1. **ترتيب الـ Migrations:** يجب أن نلتزم بنفس الترتيب الذي بنينا به الـ SQL (CORE -> CATALOG -> INVENTORY -> FINANCE ...).
2. **الدوال والـ Triggers (القيود المتقدمة):** سنقوم بإنشاء Migration مخصص (Custom Migration) في النهاية لتنفيذ أوامر الـ PL/pgSQL لتريجرات المحاسبة وتحديث `updated_at`.
3. **الاختبار:** تشغيل `php artisan migrate:fresh` والتأكد من بناء القاعدة بالكامل دون أخطاء.

### 🟨 المرحلة الثالثة: بناء طبقة النماذج (Models & Relationships)
1. إنشاء جميع الـ Eloquent Models.
2. تعريف العلاقات (Relationships) والـ Casts.
3. كتابة **Unit Tests** بسيطة للتأكد من أن إنشاء قيد محاسبي أو فاتورة يعمل ويحترم قيود قاعدة البيانات.

### 🟧 المرحلة الرابعة: لوحة التحكم (Admin Panel)
1. بناء واجهات الإدارة (Filament Resources) لإعداد النظام:
   - إدارة الفروع والأعمال (Businesses & Branches).
   - شجرة الحسابات (COA) وإعدادات الضرائب.
   - إدارة المستخدمين والصلاحيات.

### 🟥 المرحلة الخامسة: الـ Sync API وتطبيق Flutter
1. بناء الـ Sync Engine في Laravel (واجهات المزامنة للتطبيق).
2. العودة لمشروع Flutter، تحديث قاعدة البيانات المحلية لتتوافق مع الهيكلية الجديدة.
3. تنفيذ وتشغيل آلية المزامنة (Offline/Online Sync).

---

## 💡 التوصية التقنية الأهم (لوحة التحكم):
أوصي بشدة باستخدام **Filament PHP v3** لبناء الـ Admin Panel في Laravel. فهو مبني على (TALL Stack: Tailwind, Alpine, Laravel, Livewire) وسيوفر علينا أسابيع من كتابة واجهات الـ CRUD، وهو الأقوى حالياً في بناء أنظمة الـ ERP.
