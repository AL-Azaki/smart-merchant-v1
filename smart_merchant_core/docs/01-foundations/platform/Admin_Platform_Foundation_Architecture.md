# Admin Platform Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الرسمي لمنصة الإدارة والتشغيل (Platform Administration Console) الخاصة بـ Smart Merchant ERP. الغرض منها هو تحديد القواعد والمبادئ التي تحكم كيفية إدارة المنصة المركزية نفسها (Tenants, Subscriptions, Infrastructure)، بشكل منفصل ومستقل تماماً عن إدارة الأعمال اليومية للمستأجرين (Business Operations).

---

## 2. Scope
تخدم منصة الإدارة المركزية (Admin Platform) حصرياً الفئات التالية:
- **Platform Administrators:** ملاك المنصة وصناع القرار فيها.
- **Support Team:** فريق الدعم الفني لحل المشكلات التقنية للمشتركين.
- **Operations Team:** فريق العمليات والفوترة.
- **System Administrators:** مهندسو النظام والبنية التحتية.

هذه المنصة لا تُستخدم أبداً من قِبل المستخدمين العاديين (ملاك الشركات، الكاشير، المحاسبين، أو عملاء المتجر الإلكتروني).

---

## 3. Admin Platform Principles
- **Platform First:** التركيز على صحة وإعدادات المنصة المركزية ككل وليس على تفاصيل شركة معينة.
- **Secure by Default:** تتطلب أقوى معايير المصادقة (كالمصادقة الثنائية 2FA) نظراً لخطورة الصلاحيات.
- **Tenant Aware (Macro Level):** ترى المنصة المستأجرين ككيانات (Entities) يُمكن تفعيلها أو إيقافها، دون التدخل في محتوى أعمالهم.
- **Read Before Write:** جميع الإجراءات التخريبية أو الحساسة (مثل حذف أو إيقاف Tenant) تتطلب استعراضاً وتأكيداً صارماً.
- **Least Privilege:** فرق الإدارة (مثل الدعم الفني) تُمنح الحد الأدنى من الصلاحيات المطلوبة لأداء عملها.
- **Auditable:** لا توجد عملية في منصة الإدارة لا تخضع للتدقيق الصارم (Audit Trail).
- **Observable:** منصة الإدارة توفر رؤية شاملة (Visibility) لحالة النظام الكلية.

---

## 4. Administrative Domains
تدير هذه المنصة المجالات الاستراتيجية التالية وفق التسلسل الهرمي:
Platform (النظام ككل)
↓
Tenants (العملاء/المشتركون في المنصة)
↓
Businesses (الشركات التابعة لكل مشترك)
↓
Users (المستخدمون المركزيون وحساباتهم الأساسية)
↓
Subscriptions (خطط الاشتراك والفوترة)
↓
Background Jobs (طوابير المعالجة الخلفية المركزية)
↓
Notifications (نظام إرسال التنبيهات الشاملة)
↓
Reports (التقارير الإدارية الخاصة بالمنصة نفسها)
↓
Configurations (الإعدادات العامة للـ Platform)
↓
Monitoring (المقاييس والصحة التشغيلية)

---

## 5. Administrative Responsibilities
مسؤوليات منصة الإدارة تنحصر في الأفعال التالية:
- إدارة المستأجرين (إنشاء، إيقاف، حذف Tenants).
- إدارة خطط الاشتراك (Plans, Features, Quotas).
- إدارة اشتراكات العملاء وتجديدها أو تعليقها.
- إدارة المستخدمين على المستوى المركزي (Reset Passwords, Block Users).
- إدارة إعدادات المنصة (Global Platform Settings).
- مراقبة صحة النظام وأداء البنية التحتية.
- مراجعة سجلات التدقيق (System Audit Logs).
- متابعة طوابير المعالجة (Background Jobs) وصيانتها.

---

## 6. Administrative Boundaries
لضمان أمان وخصوصية بيانات المشتركين، **يُمنع معمارياً** على منصة الإدارة الآتي:
- عدم تنفيذ أي عمليات تخص منطق الأعمال (Business Logic) الخاص بالشركات (مثل إنشاء فاتورة مبيعات).
- عدم تجاوز قواعد الأعمال (Domain Rules) المفروضة داخل ה-ERP.
- عدم التدخل المباشر أو تعديل البيانات المحاسبية، المخزنية، أو المالية للمشتركين.
- عدم منح فريق الدعم صلاحيات الدخول نيابة عن العميل (Impersonation) دون توثيق قانوني وتقني صارم ضمن صلاحية مؤقتة إن لزم.

---

## 7. Tenant Administration
العلاقة مع `Platform_Tenant_Foundation_Architecture.md`:
- منصة الإدارة هي المتحكم الأول في دورة حياة الـ Tenant.
- هي المكان الوحيد الذي يُسمح فيه بإنشاء قاعدة البيانات أو المساحة المخصصة للـ Tenant وتمرير السياق الأولي له (Provisioning).

---

## 8. User Administration
العلاقة مع `Platform_Authentication_Foundation_Architecture.md` و `Platform_Authorization_Foundation_Architecture.md`:
- إدارة الهوية المركزية للمستخدمين تتم هنا (الاسم، الإيميل، رقم الهاتف، حالة الحظر).
- لا تدير المنصة صلاحيات المستخدم التشغيلية (Permissions/Roles) داخل الـ ERP الخاص بشركته، فهذا شأن يخص الـ Tenant Admin فقط.

---

## 9. Configuration Administration
العلاقة مع `Platform_Configuration_Foundation_Architecture.md`:
- تدير المنصة إعدادات الـ Platform Level فقط (القيم الافتراضية القصوى، مفاتيح التكامل المركزية، سياسات الأمان).
- يمكنها إجبار (Lock) إعدادات معينة لمنع المستأجرين من تغييرها.

---

## 10. Subscription Administration
إدارة الاشتراكات والفوترة الخاصة بالمنصة (SaaS Billing):
- **Plans:** تعريف الباقات (أساسي، متقدم، شركات) وما تحويه من ميزات.
- **Lifecycle:** إدارة دورة حياة الاشتراك.
- **Activation:** تفعيل الاشتراك بعد الدفع.
- **Suspension:** تعليق الـ Tenant برمجياً عند انتهاء الاشتراك.
- **Renewal:** معالجة تجديد الاشتراكات ورفع القيود.

---

## 11. Monitoring Relationship
العلاقة مع `Platform_Observability_Foundation_Architecture.md`:
- منصة الإدارة هي الواجهة الرئيسية لفريق العمليات لعرض المقاييس المركزية (Metrics)، التتبعات (Traces)، وتشخيص الأعطال (Diagnostics) الكلية.

---

## 12. Reporting Relationship
العلاقة مع `Platform_Reporting_Foundation_Architecture.md`:
- تستفيد المنصة من بنية التقارير لتوليد تقارير إدارية تخص الإيرادات الخاصة بالمنصة (SaaS Revenue)، معدل نمو المشتركين، ومعدل الاستهلاك للموارد.

---

## 13. Notification Relationship
العلاقة مع `Platform_Notification_Foundation_Architecture.md`:
- إرسال تنبيهات إدارية شاملة (System-wide Broadcasts) لجميع المشتركين (مثل: إشعار بوجود صيانة مجدولة).

---

## 14. Background Processing Relationship
العلاقة مع `Platform_Background_Processing_Foundation_Architecture.md`:
- متابعة مركزية لحالة العمال (Workers)، والطوابير الميتة (Dead Letters)، وإعادة محاولة المهام العالقة التي تخص البنية التحتية للمنصة.

---

## 15. Security Principles
- **Strong Authentication:** يجب فرض وسائل حماية قصوى كـ (MFA / 2FA) للوصول لمنصة الإدارة.
- **Strong Authorization:** تطبيق صارم لـ Role-Based Access Control (RBAC) بين أعضاء فريق الإدارة أنفسهم.
- **Sensitive Operations:** العمليات الحساسة (تغيير خطة المستأجر أو إيقافه) يجب أن تُنفذ عبر تحقق إضافي (Re-authentication) لتجنب الأخطاء.

---

## 16. Audit Principles
المساءلة القصوى لأي حركة يقوم بها فريق المنصة، وتشمل:
- التغييرات على الـ Tenants (تفعيل، إيقاف، تغيير باقة).
- التغييرات على حسابات الـ Users (حظر، تغيير أرقام سرية).
- التغييرات في ה-Configurations (تعديل السياسات الافتراضية).
- التغييرات في ה-Subscriptions.
- التغييرات في صلاحيات وأدوار مدراء المنصة أنفسهم.

---

## 17. Platform Support Operations
هذا القسم يميز إدارة المنصة (Platform Administration) عن إدارة أعمال العميل (Business Administration). فريق الدعم الفني ينفذ العمليات التالية بأمان دون المساس ببيانات الأعمال:
- **البحث والتحقق:** البحث عن Tenant أو Business باستخدام المعرفات دون فتح سجلاتهم المالية.
- **مراجعة السجلات (Audit Logs):** قراءة سجلات نظام المراقبة والأخطاء التقنية المرتبطة بالـ Tenant لتشخيص شكواه.
- **متابعة المزامنة:** التحقق من طوابير المزامنة وحالتها للمساعدة في تشخيص تأخر وصول البيانات في ה-Offline First.
- **متابعة المهام الخلفية:** رؤية المهام المعلقة الخاصة بالمشترك.
- **التحقق من حالة الخدمات (Health Checks):** متابعة توافر الخدمات التي تعتمد عليها بيئة المشترك.

---

## 18. Platform Responsibilities
- **Platform Administrator:** إدارة المنصة بالكامل، إعداد الباقات، ومنح الصلاحيات لفريق الدعم.
- **Support Team:** حل الشكاوى التقنية باستخدام أدوات الـ Support Operations.
- **Operations Team:** متابعة تجديد الاشتراكات، الفوترة، ومراجعة تقارير الاستهلاك.
- **System Administrator:** متابعة الطوابير، مقاييس الأداء، التنبيهات، والتدخل في حالات تعطل البنية التحتية.

---

## 19. Dependencies
هذه الوثيقة تعتمد بشكل رئيسي على الدساتير التالية:
- `Platform_Architecture.md`
- `Platform_Tenant_Foundation_Architecture.md`
- `Platform_Authentication_Foundation_Architecture.md`
- `Platform_Authorization_Foundation_Architecture.md`
- `Platform_Configuration_Foundation_Architecture.md`
- `Platform_Observability_Foundation_Architecture.md`
- `Platform_Background_Processing_Foundation_Architecture.md`

---

## 20. Out Of Scope
يخرج عن إطار منصة الإدارة المركزية (Admin Platform) كافة العمليات التشغيلية التجارية للمستأجرين، وتشمل:
- ERP Business Operations.
- Accounting Operations.
- Inventory Operations.
- Sales & Purchasing Operations.
- CRM & HR Operations.
- POS Operations.
