# Platform Tenant Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الموحد لإدارة المستأجرين (Tenant Management) على مستوى منصة Smart Merchant ERP بالكامل. الغرض الأساسي منها هو وضع القواعد الصارمة التي تضمن العزل التام لبيانات العملاء (Multi-Tenant Architecture)، وتوحيد مفاهيم دورة حياة المستأجر وملكية البيانات عبر جميع التطبيقات، الواجهات، وآليات المزامنة.

---

## 2. Scope
تطبق هذه المبادئ المعمارية بشكل إلزامي على جميع الواجهات والتطبيقات المرتبطة بالمنصة، بما في ذلك:
- ERP (النظام الأساسي).
- Flutter Mobile (تطبيقات الجوال).
- Flutter Desktop / POS (تطبيقات سطح المكتب ونقاط البيع).
- Admin Panel (لوحة تحكم إدارة المنصة الشاملة).
- E-Commerce (الواجهات الخاصة بمتاجر المستأجرين).
- REST API (نقاط الاتصال).
- أنظمة الـ Offline First و Synchronization.

---

## 3. Tenant Principles
- **Complete Isolation:** العزل الشامل والقطعي للبيانات؛ لا يمكن لمستأجر رؤية أو تعديل بيانات مستأجر آخر بتاتاً.
- **Shared Platform:** المنصة تعمل ببنية تحتية مشتركة وكود موحد يخدم جميع المستأجرين (SaaS Model).
- **Independent Data Ownership:** كل مستأجر يملك بياناته الخاصة بشكل مستقل وحصري.
- **Independent Lifecycle:** حالة كل مستأجر ودورة حياته لا تؤثر على المستأجرين الآخرين (إيقاف مستأجر لا يوقف المنصة).
- **Tenant Context Required:** لا يُسمح بتنفيذ أي استعلام أو عملية تشغيلية إلا في ظل وجود سياق مستأجر واضح ومُعرّف.
- **Zero Cross-Tenant Access:** المنع المطلق للوصول العابر بين المستأجرين تحت أي ظرف من الظروف.

---

## 4. Tenant Model
يعتمد نموذج المستأجر على التسلسل الهرمي المنطقي التالي:
Platform (المنصة الشاملة - مالك الـ SaaS)
↓
Tenant (حساب المستأجر الفعلي/المشترك)
↓
Business (المنشأة/الشركة التابعة للمستأجر)
↓
Branch (الفروع والمستودعات التابعة للشركة)
↓
User (المستخدمون والموظفون المرتبطون بالشركة)
↓
Resources (البيانات والموارد التشغيلية الخاصة بالمستخدم والشركة)

---

## 5. Tenant Lifecycle
دورة الحياة الرسمية والموحدة لأي حساب مستأجر في النظام:
**Provisioning** (جاري التجهيز والإنشاء) ➔ **Active** (نشط ويعمل بشكل طبيعي) ➔ **Suspended** (موقوف مؤقتاً بسبب الإدارة أو الدفع) ➔ **Archived** (مؤرشف ومجمد للقراءة فقط أو الاحتفاظ المحدود) ➔ **Deleted** (محذوف كلياً - إن سُمح بذلك).
*(الانتقالات المسموحة تكون متسلسلة، ولا يمكن لمستأجر محذوف العودة إلى نشط).*

---

## 6. Tenant Provisioning Strategy
عند إنشاء حساب مستأجر جديد (Onboarding)، تتطلب المنصة معمارياً:
- إنشاء الكيان الرئيسي للـ Tenant.
- إنشاء الـ Business الأولى الخاصة به.
- إنشاء المستخدم الإداري الأول (Admin) وربطه بالـ Business.
- تعبئة الإعدادات الافتراضية والدساتير الأساسية للعمل.
- بناء البيانات التمهيدية (Seed Data) إن استلزمت خطة الاشتراك ذلك.
كل هذا كعملية ذرية (Atomic Operation) لضمان عدم وجود Tenant غير مكتمل التجهيز.

---

## 7. Tenant Isolation
يُطبق عزل بيانات المستأجر إجبارياً على كافة مستويات المنصة:
- **Application:** المنطق البرمجي يفصل مسارات التنفيذ.
- **API:** نقطة الاتصال تفلتر الطلبات.
- **Synchronization:** المزامنة لا تسحب ولا ترفع إلا بيانات المستأجر المعني.
- **Offline:** قاعدة البيانات المحلية محصورة لمستأجر واحد.
- **Reporting:** التقارير محصورة تماماً.
- **Storage:** مساحات رفع الملفات (Attachments) تُعزل منطقياً بين المستأجرين.

---

## 8. Business Ownership
- جميع الكيانات، الموارد، والبيانات التشغيلية تتبع حصرياً وإجبارياً لـ (Business) واحدة فقط.
- لا يُسمح معمارياً بمشاركة أي سجل أو مورد بين كيانين (Business A لا يستطيع استخدام منتجات أو فواتير Business B، حتى لو كانا تحت نفس الـ Tenant إذا قررت المنصة السماح بتعدد الشركات للمستأجر الواحد مستقبلاً).

---

## 9. Branch Scope
التسلسل الداخلي لملكية البيانات:
Business (الشركة) ➔ Branches (الفروع).
- الموارد إما أن تكون عامة على مستوى الشركة (Global Business Resource) كشجرة الحسابات.
- أو محصورة على فرع محدد (Branch Scoped Resource) كفواتير المبيعات ونقاط البيع، لضمان استقلالية العمليات الفرعية.

---

## 10. Tenant Context
كل عملية أو استعلام داخل النظام، سواء للاسترجاع أو الحفظ، يجب أن تُجرى داخل (Tenant Context) كامل الوضوح يشتمل بالضرورة على:
- معرف المستأجر (Tenant).
- معرف الشركة (Business).
- معرف الفرع (Branch) إن لزم.
- هوية المستخدم المُنفذ (User).
غياب هذا السياق يعني رفض العملية أمنياً (باستثناء الإجراءات الإدارية الخاصة بـ Platform Admin).

---

## 11. Tenant Context Resolution Strategy
لضمان الأمان والاتساق، يجب أن تمتلك المنصة آلية موحدة وموثوقة لاستنباط وتحديد الـ Tenant Context الحالي قبل الشروع في أي مهمة، سواء أتى السياق من:
- طلبات الـ API (عبر الـ Token).
- جلسات المستخدمين (Sessions).
- الأجهزة العاملة بنمط (Offline) عبر هويتها المخزنة.
- أوامر المزامنة (Sync Payload).
- المهام المجدولة في الخلفية (Background Jobs).
وجود هذه الآلية المركزية يمنع تسرب البيانات ויضمن العمل حصرياً داخل الـ Tenant الصحيح.

---

## 12. Subscription Principles
- كل Tenant يمتلك اشتراكاً (Subscription) يتحكم في ميزاته.
- المبادئ تشمل تحديد: الباقة (Plan)، الحالة (Status)، تاريخ الانتهاء (Expiration)، التجديد (Renewal)، وفترة السماح (Grace Period).
- انتهاء الاشتراك يغير حالة الـ Tenant مما يؤثر على قدرة العملاء (Clients) على إنشاء مستندات جديدة.

---

## 13. Feature Availability
- توافر الميزات ووظائف النظام يتغير بناءً على الخطة (Plan) المشترك بها الـ Tenant.
- يجب على التطبيقات والأطراف (Clients) تعديل الواجهات المعروضة بناءً على الميزات المتاحة للـ Tenant لمنع إحباط المستخدم وتجنب أخطاء الـ API اللاحقة.

---

## 14. Resource Quotas
يعتمد النظام مبدأ الحصص (Quotas) لتقييد الموارد وفقاً لباقة الـ Tenant، وتشمل قيوداً منطقية على:
- عدد المستخدمين المسموحين.
- عدد الفروع أو المستودعات.
- عدد الأجهزة الطرفية (POS/Mobiles).
- عدد المنتجات أو العملاء.
- حجم حركات الفواتير إن لزم الأمر.

---

## 15. Offline Relationship
للتوافق مع `Offline_First_Platform_Foundation_Architecture.md`:
- قاعدة البيانات المحلية (Local Database) على جهاز العميل يجب أن تُعامل كخزينة مؤمنة لـ Tenant واحد فقط.
- في حالة تغيير الـ Tenant أو الـ Business (إن سُمح بذلك)، يجب مسح أو عزل البيانات المحلية بالكامل لتجنب اختلاط البيانات دون اتصال.

---

## 16. Synchronization Relationship
للتوافق مع `Platform_Data_Synchronization_Foundation_Architecture.md`:
- محرك المزامنة (Sync Engine) لا يتفاوض أبداً خارج نطاق الـ Tenant.
- جميع طلبات سحب (Pull) ورفع (Push) البيانات يجب أن تكون مُغلفة بمعرف الـ Tenant الموثق لضمان سلامة التكامل المرجعي.

---

## 17. Authentication Relationship
- عملية المصادقة (`Platform_Authentication_Foundation_Architecture.md`) هي التي تُعرّف المستخدم وتُثبت ارتباطه بالـ Tenant.
- الرمز (Token) الناتج عن المصادقة يمثل بحد ذاته مفتاح العبور للـ Tenant Context المعني.

---

## 18. Authorization Relationship
- منظومة التفويض (`Platform_Authorization_Foundation_Architecture.md`) تعمل بشكل صارم داخل سياق الـ Tenant المُثبت.
- الصلاحيات والأدوار لا تتجاوز حدود الشركة (Business) ولا يمكن استخدامها لمنح قدرات على شركة أخرى.

---

## 19. API Relationship
- واجهات النظام (`Platform_API_Contract_Foundation_Architecture.md`) تتعامل مع الطلبات كأحداث فردية (Stateless) تتبع لـ Tenant واحد فقط.
- أي طلب لا يمتلك سياق Tenant واضحاً وصالحاً، يُرفض مباشرة من الواجهة قبل الوصول لمنطق التطبيق.

---

## 20. Security Principles
- **Cross-Tenant Protection:** الجدار الناري البرمجي لمنع تداخل الجداول.
- **Tenant Validation:** التحقق المسبق في كل دورة تنفيذ.
- **Ownership Verification:** التأكد من ملكية أي مورد للـ Tenant قبل القراءة أو التعديل (ID Hijacking Prevention).
- **Isolation Verification:** التأكد من عدم وجود استعلامات حرة (Unscoped Queries) في طبقة قواعد البيانات.

---

## 21. Audit Principles
للمحافظة على المساءلة والامتثال، يجب تتبع وتسجيل الأحداث الإدارية التالية:
- Provision (تأسيس المستأجر).
- Suspend / Activate (إيقاف وتفعيل المستأجر).
- Archive / Delete (أرشفة أو حذف).
- Tenant / Business Switch (تبديل السياق للمستخدمين متعددي الشركات).

---

## 22. Platform Responsibilities
- **Platform (النظام المركزي):** إدارة الاشتراكات، الحصص، والفواتير السحابية للـ Tenants.
- **Tenant (المستأجر):** يمثل الكيان المالي المشترك في الخدمة السحابية.
- **Business/Branch:** تشغيل العمليات اليومية وإدارة البيانات الأساسية والمالية.
- **API/Synchronization:** التحقق الصارم من العزل وتمرير السياق بأمان.
- **Client:** مسح الذاكرة المحلية عند تبديل الحساب واحترام سياسات الحصص (Quotas) والميزات.

---

## 23. Dependencies
هذا الدستور يتكامل ويعتمد على:
- `Platform_Architecture.md`
- `Platform_Authentication_Foundation_Architecture.md`
- `Platform_Authorization_Foundation_Architecture.md`
- `Platform_API_Contract_Foundation_Architecture.md`
- `Offline_First_Platform_Foundation_Architecture.md`
- `Platform_Data_Synchronization_Foundation_Architecture.md`

---

## 24. Out Of Scope
يخرج عن إطار هذه الوثيقة المعمارية العليا التفاصيل التقنية الخاصة بـ:
- فواتير الاشتراكات الشهرية وتكامل بوابات الدفع (Subscription Billing & Payment Gateway).
- آليات مولد مفاتيح التراخيص (License Keys).
- محرك تفعيل الميزات برمجياً (Feature Flag Engine).
- استراتيجيات تقسيم قواعد البيانات (Database Sharding / Multi Database / Database Per Tenant).
- أدوات الحماية في قواعد البيانات (Row Level Security - RLS).
- تفاصيل نقل مستأجر بين الخوادم (Tenant Migration) أو استراتيجية النسخ الاحتياطي الدقيقة (Backup Strategy).
