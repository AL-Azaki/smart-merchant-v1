# Core Domain Test Strategy

## 1. Executive Summary

تحدد هذه الوثيقة الاستراتيجية الرسمية الشاملة لاختبارات (Testing Strategy) النطاق الأساسي **Core Domain** لنظام `Smart Merchant ERP`. الغرض الأساسي من هذه الاستراتيجية هو إنشاء إطار عمل معياري وموحد لضمان جودة الكود، حماية القواعد المعمارية الصارمة التي تم بناؤها (مثل Tenant Isolation و Immutability)، وضمان أن أي تعديلات مستقبلية لن تؤثر سلباً على العمليات التأسيسية التي تعتمد عليها بقية ה-Domains.

---

## 2. Scope

تغطي هذه الاستراتيجية اختبار جميع مكونات ה-Core Domain، ويشمل ذلك:
- **الكيانات (Entities):** Account, Business, Branch, User, Role, Permission, Currency, Plan, Subscription, SubscriptionPayment.
- **طبقات التطبيق:** 
  - Controllers (API Layer)
  - Actions (Business Logic)
  - Repositories (Data Access Layer)
  - Policies (Authorization)
  - Form Requests (Validation Layer)

---

## 3. Testing Objectives

تم تصميم الاختبارات لتحقيق الأهداف الاستراتيجية التالية:
- **ضمان صحة Business Rules:** التأكد من تطبيق القيود الصارمة (مثلاً: لا يمكن حذف عملة مستخدمة، لا يمكن تحديث SubscriptionPayment ناجح).
- **منع Regression:** توفير شبكة أمان (Safety Net) تكتشف أي انهيار في الوظائف الأساسية عند إضافة ميزات جديدة لاحقاً.
- **ضمان استقرار الـ APIs:** التحقق من صيغة المخرجات (Resources) والمدخلات (DTOs) واستجابات HTTP الصحيحة للنجاح والفشل.
- **حماية Tenant Isolation:** ضمان أن الحسابات لا يمكنها بأي شكل الوصول إلى أو تعديل بيانات حسابات أخرى (Business/Account level).
- **التحقق من RBAC:** اختبار Policies بصرامة للتأكد من أن المستخدمين يملكون الصلاحيات المحددة فقط لإجراء العمليات المسموحة.

---

## 4. Testing Levels

سيتم تطبيق ثلاث مستويات رئيسية للاختبار:

1. **Unit Tests (اختبارات الوحدة):**
   - **الاستخدام:** اختبار ה-`Actions`, `DTOs`, و `Policies` بمعزل عن قواعد البيانات.
   - **آلية العمل:** يتم عزل ה-Dependencies تماماً عبر حقن Mock للمستودعات (Repositories) لضمان سرعة الاختبار والتركيز على الـ Business Logic فقط.

2. **Feature Tests (اختبارات الخصائص/الـ API):**
   - **الاستخدام:** اختبار مسارات الـ API (الـ Controllers والـ Routes) من البداية للنهاية (End-to-End ضمن ה-Backend).
   - **آلية العمل:** إرسال طلب HTTP حقيقي وفحص الاستجابة (Status Code + JSON Structure)، مع السماح بالاتصال الفعلي بقاعدة بيانات الاختبار (Test DB).

3. **Integration Tests (الاختبارات التكاملية):**
   - **الاستخدام:** لاختبار تفاعل ה-`Actions` المعقدة (Orchestrators) مع الـ `Repositories` الفعلية للتأكد من حفظ وتكامل البيانات (مثال: التأكد من تسجيل `SetDefaultCurrencyAction` في الـ DB).

---

## 5. Test Coverage Goals

تم تحديد الحد الأدنى المسموح لنسب التغطية (Code Coverage) كالتالي:
- **Actions:** تغطية بنسبة **100%** (شاملة مسارات النجاح، والفشل `Exceptions`).
- **Policies:** تغطية بنسبة **100%** (اختبار جميع حالات الصلاحيات).
- **Requests:** تغطية بنسبة **100%** (اختبار القواعد الناجحة وجميع القيود المفروضة).
- **Controllers:** تغطية بنسبة **90%** (عبر الـ Feature Tests).
- **Repositories:** تغطية بنسبة **90%** (عبر ה-Integration Tests).

---

## 6. Critical Business Scenarios

ستحظى السيناريوهات الجوهرية التالية باختبارات مكثفة تغطي تمامی Edge Cases:
- **Create Business:** التحقق من إنشاء الشركات بشكل صحيح.
- **Create User:** التحقق من التشفير الآمن وربط المستخدم بالكيان المناسب.
- **Create Subscription:** التأكد من أخذ الـ Snapshot الصحيح من ה-Plan.
- **Activate Subscription:** التحقق من قاعدة (اشتراك نشط واحد فقط)، واعتماد الدفع أو السبب الإداري.
- **Set Default Currency:** التأكد من تعديل الـ Default السابق بشكل ذري (Atomic Transaction).
- **Sync Role Permissions:** ضمان إحلال الصلاحيات ومسح القديمة دون تعارض.
- **Delete Branch:** التأكد من تفاعلات الحذف وفقاً لقيود قواعد البيانات.
- **Suspend Account:** التأكد من تحديث الحالة وفعالية سياسات العزل (Cascade logic future testing).

---

## 7. Test Data Strategy

لضمان نظافة بيئة الاختبار وسرعة الأداء:
- **Factories:** سيتم بناء `Model Factories` حديثة ومرنة لتوليد بيانات اختبارية لكل Entity.
- **Seeders:** استخدام مصغرات للـ Seeders الأساسية (مثل إعداد Roles & Permissions) لبيئة الاختبار فقط.
- **Fake Data:** استخدام مكتبة `Faker` لإنشاء بيانات عشوائية آمنة وواقعية أثناء اختبار الـ Validations.
- **Database Transactions:** جميع الـ Feature/Integration Tests ستستخدم خاصية `RefreshDatabase` أو `DatabaseTransactions` لضمان إرجاع قاعدة البيانات לחالتها النظيفة بعد كل اختبار مباشرة (منع تلوث البيانات).

---

## 8. Mocking Strategy

لتحقيق سرعة وموثوقية في ה-Unit Tests:
- **Mock:** سيتم استخدامه بكثافة مع `Repository Interfaces` لمراقبة أن دوال محددة تم استدعاؤها بمعاملات محددة (Behavior Verification).
- **Stub:** سيتم استخدامه لإرجاع قيم افتراضية معينة من ה-Repositories لإجبار ה-Action على السير في مسار محدد (State Verification).
- **Fake:** سيتم استخدامه עם واجهات Laravel الأساسية (`Event::fake()`, `Mail::fake()`) لمنع إرسال أحداث حقيقية عند تفعيل الاشتراك مثلاً.

---

## 9. Test Naming Convention

تم توحيد معيار التسمية للوضوح وتسهيل القراءة:
- **ملفات الاختبار (Classes):** يُسمى بـ `[TargetName]Test` (مثال: `ActivateSubscriptionActionTest` أو `AccountControllerTest`).
- **دوال الاختبار (Methods):** يُستخدم نمط `snake_case` ويبدأ بكلمة `it_` ليشرح السلوك المتوقع بدقة.
  - مثال للنجاح: `it_successfully_activates_a_pending_subscription()`
  - مثال للفشل: `it_throws_an_exception_if_no_successful_payment_found()`

---

## 10. Success Criteria

يعتبر تدقيق الـ Core Domain من ناحية الاختبارات ناجحاً (Passed) عندما:
- تمر جميع الاختبارات الـ (Unit, Feature, Integration) بنجاح 100%.
- تحقق نسب التغطية (Code Coverage) الأهداف المحددة في القسم رقم 5.
- لا توجد اختبارات هشة (Flaky Tests) تتعطل عشوائياً بسبب مشاكل الذاكرة أو قاعدة البيانات.

---

## 11. Future Expansion

هذه الاستراتيجية التأسيسية قابلة للتوسع المباشر (Plug-and-Play). سيتم استخدام نفس المعايير والأدوات والـ Coverage Goals وتطبيقها تلقائياً عند بناء واختبار הנطاقات التالية:
- **Finance**
- **Inventory**
- **Sales**
- **Purchasing**
- **HR**

بذلك، تعتبر هذه الوثيقة مسودة دستورية لاختبارات كامل نظام `Smart Merchant ERP`.

---

## 12. Approval

- **Status:** APPROVED
- **Version:** Core Test Strategy v1.0
- **Date:** 2026-07-12
