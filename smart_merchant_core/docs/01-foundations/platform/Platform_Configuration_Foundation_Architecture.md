# Platform Configuration Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الموحد لإدارة الإعدادات (Configuration Management) على مستوى منصة Smart Merchant ERP بالكامل. الغرض منها هو وضع المبادئ الموحدة للتعامل مع خيارات النظام، تفضيلات المستخدمين، وإعدادات الأجهزة والفروع عبر جميع التطبيقات، لضمان سلوك متناسق ومرن دون اللجوء للقيم الثابتة (Hardcoding).

---

## 2. Scope
يغطي هذا الدستور إدارة الإعدادات بجميع أشكالها وتصنيفاتها، وينطبق على:
- Flutter Mobile
- Flutter Desktop / POS
- Web ERP
- Admin Panel
- E-Commerce (Store)
- أنظمة الـ Offline First و Synchronization.

---

## 3. Configuration Principles
ترتكز المنصة في إدارتها للإعدادات على المبادئ التالية:
- **Configuration Driven:** يتم توجيه سلوك النظام والواجهات من خلال الإعدادات بدلاً من المنطق البرمجي الصلب.
- **Centralized Configuration:** الخادم هو المصدر المركزي للإعدادات المشتركة.
- **Hierarchical Configuration:** تُنظم الإعدادات في هرمية تسمح بالوراثة من المستوى الأعلى للأدنى.
- **Immutable Defaults:** الإعدادات الافتراضية للنظام ثابتة ولا يمكن تغييرها، بل يتم تجاوزها (Override).
- **Override by Scope:** القدرة على تخصيص إعداد معين لنطاق محدد (مثال: فرع معين) دون التأثير على البقية.
- **Runtime Configuration:** دعم قراءة وتطبيق الإعدادات الحيوية أثناء تشغيل التطبيق دون الحاجة لإعادة التشغيل.
- **Secure Configuration:** حماية الإعدادات الحساسة وعدم كشفها للواجهات أو المستخدمين غير المصرح لهم.

---

## 4. Configuration Hierarchy
تتبع الإعدادات تسلسلاً هرمياً يعكس بيئة الـ Multi-Tenant، وتنتقل الوراثة للأسفل كالتالي:
**Platform** (الإعدادات العامة للمنصة)
↓
**Tenant** (إعدادات المستأجر/المشترك الشاملة)
↓
**Business** (إعدادات الشركة المحددة)
↓
**Branch** (إعدادات الفرع أو نقطة البيع)
↓
**User** (تفضيلات المستخدم الشخصية)
↓
**Device** (إعدادات الجهاز المحلي - مثل الطابعة)

---

## 5. Configuration Categories
لضمان التنظيم، تُقسم الإعدادات معمارياً إلى فئات:
- **General:** الإعدادات العامة (العملة الافتراضية، اسم النظام).
- **Accounting:** الإعدادات المالية (القيود التلقائية، ترحيل الفواتير).
- **Inventory:** إعدادات المخزون (السماح بالسحب بالسالب، التقييم).
- **Sales:** إعدادات المبيعات (ضريبة المبيعات الافتراضية، التسعير).
- **Purchasing:** إعدادات المشتريات (اعتماد الموردين، الضرائب).
- **POS:** إعدادات نقاط البيع (فتح الدرج، شاشات العرض).
- **Notifications:** تنبيهات النظام.
- **Printing:** قوالب الطباعة وأبعاد الورق.
- **Synchronization:** تردد المزامنة وأنماطها.
- **Offline:** الحدود المسموحة للعمل دون اتصال.
- **Security:** سياسات كلمات المرور والقفل.
- **API:** حدود الاستخدام (Rate Limiting).
- **Reporting:** تفضيلات العرض والتصدير.
- **Store:** إعدادات المتجر الإلكتروني للعملاء.

---

## 6. Configuration Resolution
الوصول للقيمة النهائية (Resolved Value) لأي إعداد يتم عبر محرك يقيم القيمة من الأسفل للأعلى (أو من الأعلى للأسفل حسب زاوية النظر)، بحثاً عن أقرب تجاوز (Override):
**Default** (القيمة المبرمجة الافتراضية)
↓
**Platform** (تجاوز المنصة)
↓
**Tenant** (تجاوز المشترك)
↓
**Business** (تجاوز الشركة)
↓
**Branch** (تجاوز الفرع - إن وجد)
↓
**User** (تفضيل المستخدم - إن وجد)
↓
**Runtime / Device** (تجاوز الجهاز اللحظي)
(إذا لم يُعثر على تجاوز، يُؤخذ المستوى الذي يسبقه).

---

## 7. Configuration Inheritance
- ترث المستويات الدنيا تلقائياً جميع إعدادات المستويات العليا التي لم يتم تجاوزها.
- تضمن الوراثة عدم الحاجة لتكرار تعريف نفس الإعداد في كل فرع إذا كان موحداً على مستوى الـ Business.

---

## 8. Configuration Override
- يُسمح بالتجاوز (Override) لإعداد معين متى ما كانت صلاحيات المستوى تسمح بذلك (مثال: يحق للمستخدم تغيير نسق التاريخ الخاص به).
- يُمنع التجاوز إذا تم إقفال الإعداد (Locked) من مستوى أعلى (مثال: مدير النظام يمنع الكاشير من تغيير سياسة الخصم في نقطة البيع).

---

## 9. Runtime Configuration
- الإعدادات الحيوية (كالضرائب أو رسائل النظام) يمكن جلبها وتحديثها محلياً أثناء تشغيل العميل (Client) عبر المزامنة أو الاستعلام الحي (Live Query).
- تغيير إعداد حساس أثناء التشغيل يجب ألا يكسر العمليات المفتوحة الحالية، بل يُطبق على العمليات الجديدة.

---

## 10. Offline Relationship
وفقاً لـ `Offline_First_Platform_Foundation_Architecture.md`:
- يجب أن يحتفظ العميل (Client) بنسخة مخبأة (Cached) من الإعدادات اللازمة للعمل ليتمكن من الإقلاع والتشغيل عند غياب الشبكة.
- تُعامل الإعدادات كبيانات أساسية (Master Data) مقروءة لا تتغير محلياً للـ (Global Configs)، باستثناء إعدادات الجهاز (Device Settings) التي تُحفظ محلياً فقط.

---

## 11. Synchronization Relationship
وفقاً لـ `Platform_Data_Synchronization_Foundation_Architecture.md`:
- الإعدادات المركزية تُحدث لدى العملاء من خلال قنوات المزامنة كغيرها من البيانات الأساسية (Download).
- تفضيلات المستخدم يمكن مزامنتها (Two-Way Sync) ليجدها المستخدم في أجهزته الأخرى.

---

## 12. Authentication Relationship
- وفقاً لـ `Platform_Authentication_Foundation_Architecture.md`، تحديد الإعدادات الشخصية للمستخدم (User Preferences) يتطلب هوية مثبتة.
- تحميل إعدادات العميل بعد تسجيل الدخول هو خطوة أساسية في عملية الـ Authentication.

---

## 13. Authorization Relationship
- استناداً لـ `Platform_Authorization_Foundation_Architecture.md`، لا يمكن تغيير أي إعداد أو تجاوزه إلا بوجود الـ Permission الصريحة لذلك الفعل (مثال: `Update Sales Settings`).

---

## 14. Tenant Relationship
- تطبيقاً لـ `Platform_Tenant_Foundation_Architecture.md`، جميع الإعدادات مقيدة ومفصولة تماماً داخل إطار الـ Tenant.
- لا يمكن استرداد أو استنساخ إعدادات من Tenant إلى Tenant آخر تحت أي ظرف.

---

## 15. Localization Principles
المبادئ المتعلقة بتهيئة البيئة المحلية (Localization) تُعامل كإعدادات:
- **Language:** لغة الواجهة الأساسية واللغات البديلة.
- **Time Zone:** المنطقة الزمنية للمستخدم لعرض التواريخ (في حين يحفظ الخادم بـ UTC).
- **Date Format:** نمط عرض التواريخ المفضل.
- **Number Format:** الفواصل العشرية والآلاف حسب المنطقة.
- **Currency Format:** مكان عرض رمز العملة وعدد الخانات العشرية (مرتبط بـ Shared Value Objects).

---

## 16. Feature Availability Relationship
- الإعدادات تُستخدم لتفعيل أو تعطيل وظائف محددة ضمن الباقة أو الشركة.
- إذا لم تكن الميزة متاحة في الـ Tenant Subscription، فلن تظهر إعداداتها للمستخدم النهائي.

---

## 17. Performance Principles
- **Configuration Caching:** يتم تخزين الإعدادات المجمعة والمحللة مؤقتاً في الذاكرة السريعة (In-Memory) لتفادي استهلاك قاعدة البيانات عند كل عملية Resolution.
- **Lazy Loading:** جلب فئات الإعدادات التي لا حاجة لها في بدء التشغيل عند الطلب فقط (إن أمكن).
- **Minimal Reads:** تجميع الإعدادات في (Bulk) عند تحميل التطبيق.

---

## 18. Security Principles
- **Sensitive Settings:** الأسرار والمفاتيح الخارجية لا ترسل للعملاء (Clients) إطلاقاً وتظل في الخادم.
- **Encryption:** الإعدادات الحساسة يجب تخزينها مشفرة.
- **Read/Update Permissions:** حصر القدرة على قراءة وتعديل الإعدادات الحيوية (كالضرائب) بالأدوار العليا فقط.
- **Audit:** تتبع العمليات الأمنية.

---

## 19. Audit Principles
للمحافظة على المساءلة، يجب أن تخضع الإعدادات ذات التأثير المالي والتشغيلي للتتبع الكامل للأفعال التالية:
- Create Setting (إنشاء إعداد جديد).
- Update Setting (تحديث القيمة).
- Reset Setting (العودة للافتراضي).
- Override Setting (تجاوز الإعداد لفئة محددة).
*(يُخزن من عدّل، متى، القيمة القديمة، والقيمة الجديدة).*

---

## 20. Platform Responsibilities
- **Platform (النظام المركزي):** إدارة القيم الافتراضية وحفظ سرية الإعدادات الحساسة.
- **Tenant / Business:** تخصيص الإعدادات لتتوافق مع طبيعة العمل (كالسياسات المحاسبية).
- **Branch:** تخصيص الإعدادات الموقعية (كالمستودع الافتراضي).
- **User:** إدارة التفضيلات الشخصية والعرض.
- **Device:** حفظ الإعدادات المتعلقة بالعتاد (الطابعات وقارئات الباركود).

---

## 21. Dependencies
تعتمد هذه الوثيقة وتتكامل مع:
- `Platform_Architecture.md`
- `Platform_Tenant_Foundation_Architecture.md`
- `Platform_Authentication_Foundation_Architecture.md`
- `Platform_Authorization_Foundation_Architecture.md`
- `Platform_API_Contract_Foundation_Architecture.md`
- `Offline_First_Platform_Foundation_Architecture.md`
- `Platform_Data_Synchronization_Foundation_Architecture.md`

---

## 22. Out Of Scope
يخرج عن إطار هذه الوثيقة المعمارية التفاصيل التقنية التالية:
- تصميم شاشات الإعدادات (Configuration UI).
- مخططات قاعدة البيانات لحفظ الإعدادات (Database Schema).
- نظام التخزين المؤقت (Redis Cache).
- متغيرات البيئة الخاصة بالخادم (Environment Variables / `.env`).
- ملفات إعدادات إطار العمل (Laravel Config Files).
- محركات تبديل الميزات المتقدمة (Feature Flag Engine).
- خدمات الإعدادات الخارجية السحابية (Remote Config Services).
