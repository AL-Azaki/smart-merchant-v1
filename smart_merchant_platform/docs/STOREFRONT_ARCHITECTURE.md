# وثيقة المعمارية الرسمية للمتجر الإلكتروني (Storefront Architecture Blueprint)
## منصة التاجر الذكي (Smart Merchant Ecosystem)

---

### 1. التقسيم المعماري المعتمد (Approved System Architecture)

تتكون منظومة المتجر الإلكتروني من ثلاثة أركان رئيسية واضحة الحدود:

1. **الخادم المركزي والباك إند (Laravel 11 / PostgreSQL - `smart_merchant_platform`)**:
   - مصدر الحقيقة الوحيد (Single Source of Truth) لكافة البيانات وقواعد الأعمال.
   - إدارة المصادقة (Sanctum Tokens)، الجلسات، وعزل المنشآت المتعددة (Multi-Tenancy).
   - توفير واجهات RESTful API الرسمية لمنصة التاجر (`/api/platform/storefront/*`) وللمتجر العام للعملاء (`/api/storefront/v1/*`).
   - معالجة المزامنة، الكتالوج، وإدارة دورة حياة الطلبات.
   - **تأكيد معماري:** لا توجد واجهة متجر عامة مبنية باستخدام Laravel Blade.

2. **تطبيق التاجر (Flutter Desktop / Mobile - `smart_merchant_erp`)**:
   - تطبيق الإدارة المخصص للتاجر ونقاط البيع المحاسبية (ERP / POS).
   - إدارة إعدادات المتجر (الهوية، الرابط، وسائل التواصل، التفعيل والتعطيل).
   - إدارة المنتجات وتحديد خيارات العرض والنشر في المتجر (`show_in_store`).
   - استهلاك واجهات Laravel الرسمية ومزامنة البيانات بأمان عبر الذاكرة والـ SQLite دون إنشاء جداول ازدواجية.

3. **واجهة المتجر العامة للعملاء (Next.js Public Storefront)**:
   - واجهة ويب عصرية وتفاعلية مبنية باستخدام **Next.js** ومحسنة لمحركات البحث (SEO).
   - تستهلك حصرياً واجهات الـ Public Storefront APIs من Laravel.
   - تتيح تصفح الأقسام والمنتجات، إدارة السلة، وإتمام الطلب كزائر (Guest Checkout).
   - لا تحتوي على أي منطق أعمال أو قاعدة بيانات مستقلة.

---

### 2. إعدادات الروابط (Storefront URL Configuration)

- يتم تكوين العنوان الأساسي لواجهة المتجر العامة عبر متغير البيئة:
  ```env
  STOREFRONT_URL=http://localhost:3000
  ```
- يتم توليد روابط المتاجر حصرياً على الخادم بالصيغة:
  ```text
  {STOREFRONT_URL}/store/{normalized_slug}
  ```
- يتم تنظيف أي شرطات مائلة زائدة في نهاية العنوان الأساسي تلقائياً.
- إذا لم يكن للمنشأة رابط مخصص (Slug)، يعيد الخادم قيمة `store_url = null`.
- حقل `store_url` هو حقل محسوب على الخادم ولا يُقبل ضمن حمولة التحديث `PUT`.

---

### 3. سياسة تعطيل المتجر والمزامنة (Store Deactivation & Sync Policy)

- **تعطيل المتجر (`storefront_active = false`)**:
  - يمنع وصول العملاء لواجهة المتجر العامة ولا يقبل طلبات جديدة.
  - **لا يوقف** إطلاقاً مزامنة ERP أو عمليات نقاط البيع والمبيعات والفواتير.
  - يسمح للتاجر بإعداد المنتجات وضبط المتجر قبل الإطلاق مع بقاء المنتجات محفوظة ومزامنة في Laravel.
- **تفعيل المتجر (`storefront_active = true`)**:
  - يشترط وجود رابط (Slug) صالح وغير محجوز، اسم معتمد، ووسيلة اتصال واحدة على الأقل.
  - يجعل المتجر مؤهلاً للعرض العام للعملاء.

---

### 4. خارطة طريق المراحل المعتمدة (Implementation Roadmap)

- **Phase 1: Database & Foundation** (مكتملة).
- **Phase 2: Storefront Settings API in Laravel** (مكتملة).
- **Phase 3: Flutter Storefront Settings Integration** (مكتملة).
- **Pre-Phase 4: Stabilization & Integration Verification** (المرحلة الحالية).
- **Phase 4: Product Publishing Pipeline** (المرحلة القادمة).
- **Phase 5: Next.js Customer Storefront**.
- **Phase 6: Guest Checkout and Order Creation**.
- **Phase 7: ERP Order Processing and POS Conversion**.
