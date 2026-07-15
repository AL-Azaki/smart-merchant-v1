# E-Commerce Platform Foundation Architecture

**Status:** APPROVED  
**Version:** 1.0  
**State:** FROZEN  

---

## 1. Purpose
تمثل هذه الوثيقة الدستور المعماري لمنصة التجارة الإلكترونية (E-Commerce Platform) ضمن بيئة Smart Merchant ERP. الغرض منها هو ترسيخ مبدأ أن المتجر الإلكتروني ليس نظاماً معزولاً، بل هو قناة بيع رسمية (Sales Channel) تتكامل معمارياً وعضوياً مع الـ ERP لضمان توحيد مصدر الحقيقة (Single Source of Truth) فيما يخص المخزون، التسعير، الحسابات، والعملاء.

---

## 2. Scope
يغطي هذا الدستور المعماري جميع القنوات والواجهات التي تخدم المستهلك النهائي (B2C أو B2B) نيابة عن المستأجر، وتشمل:
- Web Store (واجهة المتجر على الويب).
- Mobile Store (Future) (تطبيقات التسوق للمستهلكين).
- Public Catalog (الكتالوج العام القابل للتصفح).
- Customer Portal (بوابة العميل لمتابعة طلباته وحساباته).

---

## 3. E-Commerce Principles
ترتكز معمارية التجارة الإلكترونية على المبادئ التالية:
- **ERP Driven:** الـ ERP هو المحرك الأساسي؛ أي طلب في المتجر يجب أن ينتهي كحركة بيع مالية ومخزنية نظامية داخل ה-ERP.
- **Catalog Driven:** يعتمد المتجر في العرض على كتالوج المنتجات المعرف مسبقاً في الـ ERP والمصرح بعرضه إلكترونياً.
- **Inventory Aware:** لا يمكن بيع منتج إلكترونياً إذا كان غير متوفر في مخزون ה-ERP (ما لم ينص إعداد خاص على غير ذلك).
- **Pricing Aware:** أسعار المتجر، الخصومات، والضرائب تُستمد آلياً من سياسات التسعير في الـ ERP.
- **Tenant Aware:** كل متجر يتبع لمستأجر (Tenant) وشركة (Business) محددين بشكل صارم.
- **API First:** يُبنى المتجر بالكامل كواجهة أمامية تستهلك واجهات برمجة (APIs) مخصصة ومعزولة.
- **Offline Compatible (Future):** إمكانية تصفح الكتالوج وحفظ سلة المشتريات محلياً في تطبيقات المتجر المستقبلية.

---

## 4. Platform Model
التسلسل المعماري وارتباط الكيانات داخل المنصة:
Platform (منصة Smart Merchant المركزية)
↓
Tenant (المشترك المالك للمتجر)
↓
Business (المنشأة التجارية التي تملك المنتجات)
↓
Store (قناة البيع الإلكترونية/واجهة المتجر)
↓
Catalog (المنتجات المتاحة للعرض عبر هذه القناة)
↓
Customer (المستهلك النهائي المتسوق)
↓
Order (طلب الشراء الناتج)

---

## 5. Store Responsibilities
مسؤوليات واجهة المتجر الإلكتروني (Storefront) تنحصر في:
- **عرض المنتجات:** تقديم واجهة جذابة لقراءة الكتالوج (Read-Only للمنتجات).
- **البحث والتصفح:** توفير آليات بحث، فلترة، وتصنيف للمنتجات.
- **الطلبات (Cart & Checkout):** إدارة سلة المشتريات وإتمام عملية الدفع/الطلب المبدئي.
- **حساب العميل (Customer Profile):** تمكين العميل من إدارة بياناته الشخصية وعناوينه.
- **العروض:** إبراز الخصومات والتخفيضات المعتمدة من الـ ERP.

---

## 6. Store Boundaries
لضمان الفصل المعماري السليم، يُمنع على المتجر الإلكتروني القيام بالآتي:
- لا يقوم بإنشاء قيود محاسبية أو سندات مالية مباشرة في قاعدة البيانات.
- لا يدير ولا يخصم المخزون برمجياً بنفسه، بل يرسل الطلب للـ ERP ليقوم بالخصم.
- لا يُعدّل أسعار المنتجات أو يخلق سياسات تسعير مستقلة غير مدعومة بالـ ERP.
- **القاعدة الذهبية:** المتجر هو مجرد "عارض بيانات" (Viewer) ومستقبل للطلبات (Order Catcher)، ويعتمد كلياً على الـ ERP كمصدر للحقيقة.

---

## 7. Catalog Relationship
- المنتجات المعروضة في المتجر هي انعكاس לكتالوج الـ ERP.
- لا يُعرض المنتج إلكترونياً إلا إذا تم تفعيل خاصية (Published/Available Online) في بطاقة الصنف داخل الـ ERP.

---

## 8. Inventory Relationship
- يرتبط المتجر بمستودع (Warehouse) أو مجموعة مستودعات محددة مسبقاً من قِبل الـ Business لخدمة التجارة الإلكترونية.
- يستعلم المتجر عن الكمية المتاحة (Available Stock) وقت التصفح ووقت الدفع (Checkout) لمنع بيع منتج نفد (Overselling).

---

## 9. Sales Relationship
- الطلب الإلكتروني (E-Commerce Order) يُترجم فورياً أو لاحقاً (بحسب تدفق العمل) إلى أمر بيع (Sales Order) أو فاتورة مبيعات (Sales Invoice) قياسية داخل Sales Domain في ה-ERP.
- تُطبق عليه كافة قوانين ה-Sales (الضرائب، مراكز التكلفة، عمولات البائعين لو وُجدت).

---

## 10. Pricing Principles
- السعر المعروض للعميل في المتجر الإلكتروني يجب أن يُحسب بناءً على قائمة أسعار مخصصة للمتجر (Store Price List) أو السعر الافتراضي، وتشمل حساب الضرائب بدقة.
- أي خصم (Promo Code) يجب التحقق من صحته عبر الـ ERP قبل اعتماده في ה-Checkout.

---

## 11. Customer Principles
- العميل الإلكتروني هو انعكاس לكيان `Customer` في ה-ERP.
- عند تسجيل عميل جديد في المتجر، يُنشأ له ملف كعميل اعتيادي في ה-ERP ويرتبط بالـ Business، مما يوحد كشوف حسابات العملاء سواء اشتروا من المتجر أو من الـ POS.

---

## 12. Order Principles
- **Draft Order:** يبدأ الطلب كمسودة في سلة المشتريات.
- **Submitted Order:** بمجرد الدفع أو التأكيد، يُرسل الطلب للـ ERP كـ (Pending Order).
- حالة الطلب (قيد التجهيز، مشحون، مكتمل) تُدار من داخل الـ ERP، وينعكس التحديث على بوابة العميل (Customer Portal).

---

## 13. Payment Relationship
العلاقة مع Payments Domain (المستقبلي):
- بوابات الدفع الإلكترونية (Payment Gateways) تندمج في مرحلة الـ Checkout.
- بمجرد تأكيد الدفع الإلكتروني، يُرسل إشعار (Webhook) للـ ERP لتوليد سند قبض (Receipt Voucher) وتسويته مع الفاتورة.

---

## 14. Notification Relationship
العلاقة مع `Platform_Notification_Foundation_Architecture.md`:
- يعتمد المتجر على منصة الإشعارات المركزية لإرسال رسائل تأكيد الطلب للعميل (Email/SMS)، وإشعار مدير الـ ERP بوجود طلب جديد.

---

## 15. File Attachment Relationship
العلاقة مع `Platform_File_Attachment_Foundation_Architecture.md`:
- صور المنتجات (Public Assets) وبانرات العروض الترويجية تُجلب من منصة المرفقات.
- الإيصالات أو المرفقات التي يرفعها العميل تُعامل كـ (Private/Shared Assets) مرتبطة بملف العميل.

---

## 16. Synchronization Relationship
العلاقة مع `Platform_Data_Synchronization_Foundation_Architecture.md`:
- إذا كان هناك Mobile Store يدعم ה-Offline، فإنه سيستخدم محرك المزامنة لسحب الكتالوج المحدّث.
- مزامنة الطلبات وتحديثات المخزون تعتمد على المزامنة المركزية.

---

## 17. Offline Relationship
العلاقة مع `Platform_Offline_First_Foundation_Architecture.md`:
- الكتالوج في تطبيق الهاتف للمتجر قد يُخزن محلياً لتصفح سريع (Read-Only Cache).
- إرسال الطلب (Checkout) يتطلب بالضرورة اتصالاً بالإنترنت لحجز المخزون وتأكيد الدفع.

---

## 18. API Relationship
العلاقة مع `Platform_API_Contract_Foundation_Architecture.md`:
- يتواصل المتجر مع الـ ERP عبر (Storefront API) مخصص ومعزول أمنياً عن (Admin API).
- هذا الـ API مجهز للقراءة السريعة (Read Heavy) ويدعم الـ Caching لسرعة استجابة المتجر.

---

## 19. Security Principles
- **Customer Authentication:** تسجيل الدخول للمتجر منفصل أمنياً (مستويات الجلسة) عن تسجيل الدخول لموظفي الـ ERP، رغم اعتمادهما على بنية تحتية واحدة.
- **Order Authorization:** العميل لا يرى ولا يُعدل إلا طلباته الخاصة.
- **Public Catalog:** أجزاء الكتالوج المفتوحة تُصمم لتحمل الزيارات العشوائية وحمايتها من هجمات الحرمان من الخدمة (DDoS).
- **Secure Checkout:** الدفع ونقل البيانات الشخصية يجب أن يتم عبر قنوات مشفرة وفق معايير الأمان (PCI-DSS principles).

---

## 20. Audit Principles
المساءلة والتتبع تشمل عمليات التجارة الإلكترونية الحساسة:
- إنشاء وتعديل وإلغاء الطلبات (Orders).
- تعديلات العميل لبياناته وعناوينه (Customer Changes).
- تغييرات حالة توفر المنتجات وعرضها في المتجر (Catalog Changes).
- تعديل إعدادات المتجر من قبل مدير الـ ERP (Store Configuration).

---

## 21. Platform Responsibilities
- **Platform (Core):** توفير البنية التحتية لعزل المتجر وتوجيه الطلبات عبر ה-APIs.
- **ERP:** المحرك الخلفي لإدارة الكتالوج، المخزون، الحسابات، وتسعير الطلبات، وتجهيزها (Fulfillment).
- **Store (Client):** عرض المنتجات بطريقة ممتازة، استقبال الطلبات، ونقلها بأمان للـ ERP.
- **Customer:** تصفح المتجر، إضافة المنتجات للسلة، إتمام الدفع، وتتبع الطلب.
- **API (Storefront):** وسيط الاتصال الآمن والسريع بين واجهة المتجر وقاعدة بيانات ה-ERP.

---

## 22. Dependencies
تعتمد هذه الوثيقة وتتكامل مع:
- `Platform_Architecture.md`
- `Platform_API_Contract_Foundation_Architecture.md`
- `Platform_Notification_Foundation_Architecture.md`
- `Platform_File_Attachment_Foundation_Architecture.md`
- `Platform_Tenant_Foundation_Architecture.md`
- `Offline_First_Platform_Foundation_Architecture.md`
- `Platform_Data_Synchronization_Foundation_Architecture.md`

---

## 23. Out Of Scope
يخرج عن إطار هذه الوثيقة التفاصيل التنفيذية والخدمات التكميلية التالية:
- بوابات الدفع الإلكترونية (Payment Gateway Providers).
- شركات الشحن وآلية الربط بها (Shipping Provider Integrations).
- الأسواق المجمعة (Marketplace/Multi-Vendor).
- برامج الولاء والنقاط (Loyalty Program Implementation).
- محركات التوصية (Recommendation Engine).
- آليات وتكتيكات تحسين محركات البحث (SEO Implementation).
- محركات البحث المتقدمة كـ (Algolia أو ElasticSearch) بالتفصيل.
- محركات إدارة الحملات التسويقية الآلية (Marketing Campaign Engine).
