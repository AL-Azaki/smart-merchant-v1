# Smart Merchant ERP - Platform Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  
**Level:** Supreme Architecture Document  

---

## 1. Purpose
تمثل هذه الوثيقة المرجع الأعلى (Supreme Architecture Document) لكامل منصة Smart Merchant ERP. الغرض منها هو تقديم الرؤية الشاملة لكيفية عمل النظام المتكامل وتحديد مسؤوليات الطبقات، حدود النطاقات (Domains)، وطرق التواصل بينها دون الدخول في التفاصيل البرمجية، لتكون الدستور الذي يجب أن تتوافق معه جميع الوثائق والمكونات الأخرى.

---

## 2. Vision
تهدف المنصة إلى تقديم نظام تخطيط موارد المؤسسات (ERP) عالمي المستوى يتميز بالسرعة، الموثوقية، وقابلية التوسع المفتوحة. تم اختيار مجموعة محددة من الأنماط الهندسية لتحقيق هذا الهدف:
- **Domain-Driven Design (DDD):** لضمان أن الكود يعكس تماماً العمليات التجارية الحقيقية.
- **Clean Architecture:** لعزل النواة (Core) عن البنية التحتية والواجهات، مما يضمن استدامة النظام ومرونته.
- **Modular Monolith:** للحصول على بساطة النشر والتطوير مع قوة الفصل المعماري الموازي للخدمات المصغرة (Microservices).
- **Offline First:** لضمان استمرارية الأعمال للعملاء في بيئات الاتصال غير المستقرة.
- **API First:** لتكون المنصة قابلة للاندماج مع أي واجهات أمامية أو أنظمة خارجية في المستقبل.

---

## 3. Platform Overview
المنصة عبارة عن نظام بيئي متكامل يتألف من الأجزاء الرئيسية التالية:
1. **Core ERP Backend** (المحرك الرئيسي).
2. **REST API** (نقطة الاتصال الموحدة).
3. **Flutter Mobile** (تطبيق الجوال للبائعين والمدراء).
4. **Flutter Desktop / Tablet** (نظام نقاط البيع POS والأجهزة اللوحية).
5. **Web ERP** (واجهة الويب المحاسبية والتشغيلية المتقدمة).
6. **Admin Panel** (لوحة تحكم إدارة النظام والمشتركين).
7. **E-Commerce** (متجر إلكتروني متصل مباشرة بالمنصة).
8. **Reporting & Analytics** (وحدة التقارير المتقدمة).
9. **Notification System** (نظام التنبيهات).
10. **Synchronization Engine** (محرك المزامنة غير المتصل).
11. **AI Assistant** (Future) (المساعد الذكي للمبيعات والتحليل).

---

## 4. Platform Layers
يعتمد النظام على هيكلية طبقية صارمة من الداخل إلى الخارج:
- **Persistence Layer:** قواعد البيانات والجداول الفعلية (محظور الوصول لها مباشرة لتخطي الكيانات).
- **Infrastructure Layer:** التعامل مع التخزين الخارجي، إرسال البريد، وتطبيقات الطرف الثالث (APIs).
- **Domain Layer:** قلب النظام، يحتوي على الـ Entities, Value Objects, Domain Events, والمبادئ التجارية البحتة (لا يعتمد على أي طبقة أخرى).
- **Application Layer:** يحتوي على الـ Use Cases, Actions, و Orchestration Services.
- **Presentation Layer:** واجهات الـ API، الـ Controllers، الـ Resources، و Form Requests.

---

## 5. Domain Landscape
تتكون المنصة من مجموعة من النطاقات المنفصلة (Bounded Contexts):
**الحالية:**
- `Core Domain` (الإعدادات الأساسية، الشركات، الفروع، المستخدمين).
- `Finance Domain` (الحسابات العامة، القيود، السنة المالية).
- `Sales Domain` (المبيعات، الفواتير، نقاط البيع الأساسية).
- `Inventory Domain` (المخزون، المستودعات، الحركات المخزنية).
- `Purchasing Domain` (المشتريات، الموردين).

**المستقبلية:**
- `Payments Domain` (Future)
- `CRM Domain` (Future)
- `HR Domain` (Future)
- `POS Domain` (Advanced - Future)
- `E-Commerce Domain` (Future)

---

## 6. Shared Foundations
لضمان التناغم، تعتمد المنصة على دساتير مشتركة (Foundations) تحكم جميع النطاقات:
- **Financial Documents Foundation:** لتوحيد دورة حياة المستندات، الترقيم، وعمليات الترحيل والإلغاء (Draft -> Posted -> Reversed).
- **Shared Value Objects Foundation:** لتوحيد الكيانات الصغرى (Money, Quantity, Percentage, Exchange Rate) وقواعد مساواتها.
- **System Domain Events Foundation:** لتوحيد تسمية ونشر واستهلاك الأحداث عبر النطاقات (مثل `SalesInvoicePosted`).

---

## 7. Shared Services
هناك خدمات محورية مركزية تخدم المنصة بالكامل، وتعمل كوسيط للـ Domains الأخرى:
- **Posting Engine:** المحرك المالي الوحيد القادر على كتابة قيود اليومية.
- **Inventory Stock Service:** الخدمة الوحيدة القادرة على تغيير أرصدة المخزون.
- **Account Mapping Service:** المسؤولة عن تحويل الأحداث إلى حسابات شجرة الحسابات (COA).
- **Synchronization Engine (Future):** لإدارة التزامن عند عودة الاتصال.
- **Notification Service (Future):** مركز الإشعارات الموحد.

---

## 8. Cross-Domain Communication
لضمان مبدأ الـ Modular Monolith وعدم تحول النظام إلى Spaghetti Code، يحظر التواصل المباشر لقواعد البيانات أو الـ Eloquent بين النطاقات. يتم التواصل حصرياً عبر:
1. **Interfaces & Contracts:** عقود ملزمة وثابتة (DTOs).
2. **Application Services:** استدعاء خدمات الـ Application الخاصة بالنطاق الهدف.
3. **Domain Events:** استماع النطاقات للأحداث (Synchronous Events في V1) والتفاعل معها.

---

## 9. Application Landscape
تشمل التطبيقات المستهلكة لخدمات المنصة ما يلي:
- **Flutter Mobile:** للمناديب، تتبع المبيعات المتنقلة، والموافقات.
- **Flutter Tablet (POS):** واجهة الكاشير ونقاط البيع المكثفة والسريعة.
- **Web ERP:** للإدارة المالية والمخزنية المتقدمة وتقارير الإدارة العليا.
- **Admin Panel:** للتحكم المركزي بالمستأجرين (Tenants) والباقات والفواتير الخاصة بـ SaaS.
- **Store:** واجهة B2B / B2C لعملاء المنشأة.
- **REST API:** للاستخدام العام والتكامل مع أنظمة الطرف الثالث.

---

## 10. Offline First Strategy
تستهدف المنصة العمل بسلاسة حتى عند انقطاع الإنترنت، خاصة في أنظمة الـ POS وتطبيقات الجوال الميدانية. يُخزن التطبيق العمليات محلياً ويديرها بشكل ذكي ريثما يعود الاتصال.
*(ملاحظة: التفاصيل المعمارية الدقيقة تخضع لوثيقة `Offline_First_Foundation_Architecture.md` المستقلة).*

---

## 11. Synchronization Strategy
عند استعادة الاتصال، يعمل محرك المزامنة (Sync Engine) على رفع البيانات المحفوظة محلياً بترتيبها الزمني مع معالجة التضاربات (Conflict Resolution) وتحديث البيانات المرجعية في الأطراف (Clients).
*(التفاصيل في وثائق المزامنة الخاصة).*

---

## 12. Security Strategy
- **Authentication:** التحقق من الهوية مركزياً.
- **Authorization & Permissions:** نظام صلاحيات يعتمد على الـ Roles والـ Business Scopes.
- **Audit:** تسجيل كامل وموثوق لعمليات الإنشاء، الترحيل، الإلغاء (`created_by`, `posted_by`, `reversed_by`).
- **Encryption:** تشفير البيانات الحساسة أثناء النقل (TLS) وفي حالة السكون (Data at Rest).

---

## 13. Deployment Architecture
الهيكل العام للنشر والتوزيع:
- **Clients:** Flutter Apps (iOS, Android, Web, Desktop).
- **Gateway/Web Server:** NGINX.
- **Application Server:** Laravel API (PHP).
- **Relational Database:** PostgreSQL (باعتباره الأفضل لضمان سلامة العمليات المالية).
- **In-Memory Cache:** Redis (للتخزين المؤقت وتحسين الأداء).
- **Storage:** S3 Compatible Storage للمرفقات والملفات.

---

## 14. Scalability Strategy
مع نمو النظام، يمكن التوسع أفقياً (Horizontal Scaling) للـ Application Servers وإضافة Load Balancers. يضمن تصميم الـ Modular Monolith إمكانية فصل النطاقات مستقبلاً إلى Microservices حقيقية إذا اقتضت الحاجة الماسة ذلك بجهد هندسي منظم بفضل الـ Interfaces والـ Contracts المحددة بدقة.

---

## 15. Technology Stack
- **Frontend / Mobile / POS:** Flutter, Dart.
- **Backend API:** Laravel (PHP 8.x).
- **Database:** PostgreSQL.
- **Caching & Sessions:** Redis.
- **Containerization:** Docker.
- **Architecture:** REST API, Clean Architecture, DDD.

---

## 16. Future Roadmap
يشمل التطور المستقبلي للمنصة إضافة وإطلاق النطاقات والخدمات التالية:
- Payments
- Cash Management
- Bank Reconciliation
- CRM (Customer Relationship Management)
- HR (Human Resources)
- Manufacturing
- Advanced POS
- Online Store
- BI (Business Intelligence)
- AI (Artificial Intelligence Assistant)

---

## 17. Architecture Principles
ترتكز المنصة على مجموعة صارمة من المبادئ غير القابلة للمساومة:
- **DDD (Domain-Driven Design):** العمليات التجارية تقود التصميم.
- **Clean Architecture & SOLID:** استقلالية وسهولة الصيانة.
- **Dependency Injection:** فصل الاعتماديات واستخدام الانعكاس الداخلي (Inversion of Control).
- **Repository Pattern:** عزل التعامل مع قواعد البيانات.
- **Aggregate Root:** الحفاظ على اتساق الكيانات وعدم تعديل الكيانات التابعة مباشرة.
- **Domain Events:** للتواصل الفعّال والمنفصل بين النطاقات.
- **Value Objects:** لضمان سلامة البيانات الصغرى (Immutability).
- **Offline First & API First:** الجاهزية للعمل في جميع الظروف ومع جميع الواجهات.

---

## 18. Dependencies
تعتبر هذه الوثيقة المظلة الرئيسية، وتعتمد في تشريعاتها على مجموعة الأدلة ودساتير العمل التفصيلية (Foundations)، وأبرزها:
- `01-foundations/platform/Shared_Value_Objects_Foundation_Architecture.md`
- `01-foundations/platform/Financial_Documents_Foundation_Architecture.md`
- `01-foundations/platform/System_Domain_Events_Foundation_Architecture.md`
- الفهرس العام وخريطة الاعتماديات: `Architecture_Index.md` و `Architecture_Dependency_Map.md`.

---

## 19. Out Of Scope
التقنيات والأساليب التالية تعتبر **Out Of Scope**، وتم استبعادها من الإصدار الأول (V1) لتجنب التعقيد غير المبرر:
- Microservices Architecture (الاعتماد على Modular Monolith).
- CQRS (Command Query Responsibility Segregation) بالفصل الكامل للقواعد.
- Event Sourcing.
- Distributed Event Brokers (Kafka, RabbitMQ).
- Distributed Transactions (Two-Phase Commit).
- Multi-Database Systems (استخدام قاعدة بيانات واحدة مركزية PostgreSQL لكل المشتركين بنمط Row-Level Tenancy أو Schema-based).
