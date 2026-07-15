# Platform Background Processing Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري الرسمي لمنصة معالجة المهام الخلفية والعمليات غير المتزامنة (Background Processing Platform) على مستوى Smart Merchant ERP بالكامل. الغرض منها هو وضع إطار عمل موثوق وآمن للتعامل مع العمليات الطويلة، المهام المجدولة، وعمليات إعادة المحاولة، لضمان استجابة سريعة لواجهات المستخدم (Non-blocking UI) والحفاظ على سلامة وتناسق بيانات المنصة.

---

## 2. Scope
تغطي هذه الوثيقة المبادئ المعمارية التي تحكم كل جزء في المنصة يعتمد على المهام غير المتزامنة، وتشمل:
- واجهات برمجة التطبيقات (APIs) التي تفوّض معالجة البيانات.
- عمليات המزامنة من تطبيقات Flutter (Mobile & Desktop).
- طلبات التقارير الثقيلة من (Web ERP & Admin Panel).
- عمليات المتجر الإلكتروني (E-Commerce) مثل معالجة الطلبات وإرسال الإيميلات.

---

## 3. Background Processing Principles
- **Asynchronous by Design:** المهام التي لا تتطلب رداً فورياً للمستخدم يجب أن تُنفذ دائماً في الخلفية (Offloaded).
- **Reliable Processing:** ضمان تسليم وتنفيذ المهمة (At-least-once delivery) وعدم فقدانها في حال تعطل الخادم.
- **Idempotent Execution:** القدرة على إعادة تنفيذ المهمة بأمان دون التسبب في أخطاء أو تكرار الآثار الجانبية.
- **Tenant Aware:** تنفيذ المهمة يكون مقيداً بشدة بسياق المستأجر (Tenant Context).
- **Observable:** حالة كل مهمة يجب أن تكون قابلة للرصد والقياس.
- **Recoverable:** قدرة النظام على استئناف العمل ومتابعة المهام الفاشلة بعد إصلاح الخلل.
- **Scalable:** دعم زيادة طاقة المعالجة وتوزيع الحمل (Load Distribution) عند زيادة الضغط.

---

## 4. Processing Model
مسار المعالجة المنطقي والاعتمادية للمهمة:
Client (تطبيق المستخدم أو النظام)
↓
Request (طلب التنفيذ)
↓
Background Task (إنشاء المهمة وإدراجها في الطابور)
↓
Processing (تفريغ واجهة المستخدم وتنفيذ المهمة في الخلفية)
↓
Completion (انتهاء المعالجة)
↓
Result (النتيجة وإشعار المستفيد)

---

## 5. Task Lifecycle
تمر المهمة الخلفية بدورة حياة مقيدة وصارمة:
**Created** (تم بناء المهمة) ➔ **Queued / Scheduled** (أُدرجت في الطابور أو جُدولت) ➔ **Running** (قيد التنفيذ حالياً) ➔ **Completed** (نجحت واكتملت) ➔ **Failed** (فشلت لسبب ما) ➔ **Retry** (مجدولة لإعادة المحاولة) ➔ **Cancelled** (أُلغيت يدوياً أو آلياً) ➔ **Archived** (حُفظت السجلات للأرشيف).
*(الانتقالات المسموحة تكون متسلسلة لضمان تتبع الحالة بدقة).*

---

## 6. Task Categories
تُصنف المهام حسب النطاق أو الوظيفة إلى:
- Synchronization (معالجة طوابير المزامنة الواردة).
- Notification (إرسال تنبيهات ورسائل).
- Reporting (توليد التقارير وتصديرها).
- Import / Export (معالجة الملفات الضخمة).
- File Processing (تحسين الصور وتوليد المصغرات).
- Accounting (الترحيلات المالية الجماعية).
- Maintenance (أرشفة السجلات).
- Cleanup (حذف البيانات المهملة).
- Integration (التخاطب مع أنظمة خارجية).

---

## 7. Task Classification (تصنيف طبيعة المهام)
لتنظيم التصميم المستقبلي للنطاقات (Domains)، تُقسم المهام من حيث الطبيعة وآلية الانطلاق إلى:
- **Interactive Tasks:** مهام مرتبطة مباشرة بطلب من المستخدم، وتتطلب إشعاراً مرئياً عند الانتهاء (مثال: طلب تقرير ضخم).
- **Deferred Tasks:** مهام تؤجل لما بعد إرجاع الاستجابة لتسريع الـ API (مثال: تسجيل حركة التدقيق Audit Log).
- **Scheduled Tasks:** مهام تعمل تلقائياً في أوقات محددة مسبقاً (مثال: إغلاق الورديات اليومي).
- **Event-Driven Tasks:** مهام تنطلق كاستجابة لحدث وقع في النظام - Domain Event (مثال: تحديث الأرصدة التراكمية بعد عملية بيع).
- **Maintenance Tasks:** مهام دورية لتنظيف وصيانة قواعد البيانات والملفات المؤقتة.

---

## 8. Queue Principles
المبادئ العامة لإدارة الطوابير التي تحتضن المهام:
- **Queue Isolation:** فصل الطوابير حسب تصنيف المهمة (مثال: طابور للمزامنة، طابور للتقارير) لضمان عدم حجب المهام السريعة بسبب مهام بطيئة.
- **FIFO:** الحفاظ على ترتيب التنفيذ (First In, First Out) في المهام التي تعتمد على الترتيب كالترحيل المالي.
- **Priority Support:** تمييز طوابير أو مهام ذات أولوية عالية تتخطى المهام الأقل أهمية.
- **Independent Processing:** العامل (Worker) لا يشارك حالته (State) مع عمال آخرين لتفادي التداخل (Race Conditions).

---

## 9. Scheduling Principles
- توفر المنصة آلية موحدة لجدولة المهام المتكررة (أسبوعياً، شهرياً، أو حسب نمط مخصص).
- المهام المجدولة يجب أن تدعم العمل في بيئات موزعة بحيث لا يتم إطلاق نفس المهمة مرتين في حال وجود خوادم متعددة.

---

## 10. Retry Principles
في حالة فشل تنفيذ المهمة، يجب الالتزام بـ:
- **Retry Eligibility:** ليس كل فشل يستحق المحاولة؛ الفشل التقني المؤقت (مثل انقطاع الاتصال بقاعدة البيانات) يعاد، الفشل المنطقي الدائم (مثل بيانات غير صالحة) يُوقف فوراً.
- **Retry Limits:** حد أقصى للمحاولات لمنع الاستهلاك اللانهائي لموارد الخادم.
- **Backoff Strategy:** تباعد زمني تصاعدي بين محاولات الإعادة (Exponential Backoff).
- **Failure Escalation:** تصعيد الفشل إلى الدعم الفني والإشعارات بعد استنفاد محاولات الـ Retry.

---

## 11. Idempotency Principles
- يجب تصميم أي مهمة خلفية بحيث تكون قابلة للتكرار مئات المرات بأمان (Idempotent).
- إذا فُصل سلك الطاقة أثناء تنفيذ ترحيل مالي وأُعيدت المهمة بعد عودة الخادم، يجب أن يتأكد الكود أولاً مما تم تنفيذه سابقاً لئلا يكرر القيد المالي، دون الاعتماد فقط على ضمانات الطابور.

---

## 12. Priority Principles
- **Low:** مهام الصيانة وتنظيف الأرشيف.
- **Normal:** مهام التقارير والإرسال المؤجل للبريد.
- **High:** أوامر المزامنة من أجهزة الـ Offline وطلبات نقاط البيع.
- **Critical:** رسائل التوثيق (OTP) ومهام التأمين الحيوي.

---

## 13. Batch Processing Principles
- المهام الجماعية (Batch) يجب تقسيمها إلى أجزاء صغيرة (Chunks) لتقليل استهلاك الذاكرة وحماية النظام من الانهيار (OOM).
- يجب أن يكون النظام قادراً على تتبع حالة تقدم الدفعة (Progress) واستئنافها من النقطة التي توقفت عندها في حال الفشل.

---

## 14. Dead Letter Principles
- المهام التي استنفدت جميع محاولات الإعادة (Max Retries) وفشلت نهائياً لا تحذف.
- تُنقل هذه المهام إلى قائمة ميتة (Dead Letter Queue/Table) للمراجعة اليدوية (Manual Intervention) والتحليل التقني.

---

## 15. Offline Relationship
للتوافق مع `Offline_First_Platform_Foundation_Architecture.md`:
- التطبيقات غير المتصلة تمتلك طوابير محلية خاصة بها (Local Queues).
- طوابير الـ Offline تتولى محاولة إعادة الإرسال نحو الخادم عند استقرار شبكة الإنترنت، وتعتمد مبدأ الإيقاف المؤقت (Pause) وليس الفشل (Fail) في حال تعطل الشبكة.

---

## 16. Synchronization Relationship
للتوافق مع `Platform_Data_Synchronization_Foundation_Architecture.md`:
- عملية المزامنة الكبيرة تتم كـ Background Task لضمان عدم انقطاع الاتصال (HTTP Timeout) أثناء سحب بيانات ضخمة كالمخزون.

---

## 17. Notification Relationship
للتوافق مع `Platform_Notification_Foundation_Architecture.md`:
- جميع الإشعارات الصادرة تمر عبر منصة المهام الخلفية للإرسال الفعلي.
- المنصة مسؤولة عن إشعار المستخدم عند اكتمال أو فشل مهمته المعلقة (كتقرير جاهز للتحميل).

---

## 18. Reporting Relationship
للتوافق مع `Platform_Reporting_Foundation_Architecture.md`:
- تصدير التقارير الضخمة (PDF / Excel) يعتمد حصرياً على الـ Background Processing.
- التقارير المجدولة تُدار بالكامل عبر Scheduling Principles الخاصة بهذه الوثيقة.

---

## 19. Observability Relationship
للتوافق مع `Platform_Observability_Foundation_Architecture.md`:
- المهام الخلفية يجب أن تُصدر قياسات (Metrics) لحالة الطابور والتأخير وتمرر ה-Correlation ID في سجلاتها لتسهيل التتبع.
- الأعطال الدائمة في المهام (Dead Letters) تطلق تنبيهات حيوية (Alerts) لفريق الدعم.

---

## 20. Tenant Relationship
للتوافق مع `Platform_Tenant_Foundation_Architecture.md`:
- تُنفذ كل مهمة داخل (Tenant Context) حصري ومغلق.
- استعادة حالة الـ Tenant (والـ User إن وجد) هي أول خطوة يقوم بها العامل (Worker) قبل الشروع في أي مهمة لضمان عزل البيانات وحماية الصلاحيات.

---

## 21. Security Principles
- **Authorization:** التأكد من صلاحيات منشئ المهمة حتى أثناء التنفيذ في الخلفية (لأن الصلاحية قد تكون سُحبت أثناء انتظار المهمة في الطابور).
- **Task Validation:** التحقق من مدخلات المهمة قبل برمجتها في الطابور لمنع الهجمات الموجهة أو الأعطال المتعمدة.
- **Secure Execution:** لا تُطبع تفاصيل حساسة (ككلمات المرور) في سجلات المهمة أو الخطأ المنطقي.
- **Isolation:** عزل بيئات التنفيذ في حال استخدام عمليات فرعية.

---

## 22. Performance Principles
- **Concurrency:** القدرة على تنفيذ عشرات المهام بالتوازي (Parallel Processing) لتقليل زمن الانتظار.
- **Resource Efficiency:** تحديد استهلاك الذاكرة ووقت التنفيذ (Timeout) المسموح لكل مهمة لئلا تحتكر عامل التنفيذ (Worker) للأبد.
- **Scalability & Load Distribution:** توزيع العمال لمعالجة مهام الخادم المركزي عند بلوغ الحد الأقصى.

---

## 23. Audit Principles
المساءلة جزء أساسي. يجب أن يكون النظام قادراً على تسجيل الأفعال التالية للمهام الحساسة:
- Create Task (توقيت ومنشئ المهمة).
- Queue (دخول المهمة للطابور).
- Start / Complete (بدء وانتهاء التنفيذ وتحديد الزمن المستغرق).
- Retry / Cancel (المحاولات والإلغاء).
- Fail (توثيق رسالة الفشل الجذري).

---

## 24. Platform Responsibilities
- **Client:** رفع طلب التنفيذ والاستماع للإشعار أو الاستعلام (Polling) عن الحالة.
- **API:** التحقق من الطلب، تغليفه، وحقنه في نظام الطوابير وإرجاع (Job ID) للعميل.
- **Background Processing Platform:** تنسيق الطوابير، التوزيع، إدارة العمال (Workers)، وتتبع الحالات وتطبيق سياسة الـ Retry.
- **Domain:** معالجة المهمة التجارية نفسها بمنطق معزول وآمن.
- **Infrastructure:** توفير وسيلة التخزين والاسترداد السريع لرسائل الطابور.

---

## 25. Dependencies
هذه الوثيقة تعتمد بشكل مباشر على:
- `Platform_Architecture.md`
- `Platform_Tenant_Foundation_Architecture.md`
- `Platform_Data_Synchronization_Foundation_Architecture.md`
- `Platform_Notification_Foundation_Architecture.md`
- `Platform_Reporting_Foundation_Architecture.md`
- `Platform_Observability_Foundation_Architecture.md`
- `Offline_First_Platform_Foundation_Architecture.md`

---

## 26. Out Of Scope
يخرج عن إطار ومسؤولية هذه الوثيقة التفاصيل التنفيذية والتقنية التالية:
- تقنيات وأنظمة الطوابير المحددة (Redis, RabbitMQ, Kafka).
- أدوات إطار العمل (Laravel Queue, Horizon, Telescope).
- آليات وتطبيقات الجدولة (Cron Implementation).
- إعدادات وبنية عمال التنفيذ (Worker Configuration & Supervisor).
- استخدام خدمات الجدولة السحابية (Cloud Scheduler).
- وظائف المعالجة السحابية بلا خادم (Serverless Jobs / AWS Lambda).
