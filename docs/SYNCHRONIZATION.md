# عقد المزامنة وحدود التنفيذ

آخر مراجعة: 18 أكتوبر 2026. [الفهرس](../README.md). هذا مرجع للسلوك الموجود، مع فصل الفجوات عن التصميم المقصود.

## الملكية والنطاق

Flutter هو مصدر الكتالوج والمخزون التشغيلي والقيود المحلية. Laravel مصدر الهوية والصلاحيات والاشتراكات والطلبات الإلكترونية، ويحتفظ بإسقاط للكتالوج وتوفر المخزون.

الكيانات المسجلة للرفع بالترتيب: `categories`, `brands`, `units`, `products`, `product_units`, `product_images`, `inventory_projections`. السحب المسجل: `orders` فقط. يتطابق [SyncEntityMap](../smart_merchant_erp/lib/kernel/sync/mapping/sync_entity_map.dart) مع [SyncEntityRegistry](../smart_merchant_platform/app/Services/Sync/SyncEntityRegistry.php)، لكن التسجيل لا يثبت اكتمال المعالجة.

واجهة الاتصال: `POST /api/sync/push` و`pull` و`ack` بعد المصادقة وتهيئة السياق والجهاز. المرجع [SyncContextResolver](../smart_merchant_platform/app/Services/Sync/SyncContextResolver.php) و[SyncRemoteApiClient](../smart_merchant_erp/lib/kernel/sync/api/sync_remote_api_client.dart).

## المسار التشغيلي

[SyncCoordinator](../smart_merchant_erp/lib/kernel/sync/coordinator/sync_coordinator.dart) يرفع البيانات المحلية ثم يسحب الطلبات ويحفظها قبل تقدم المؤشر والإقرار. فشل الاتصال يصنف ولا ينبغي أن يلغي معاملة بيع محلية ناجحة. توجد بنية عامة للطوابير وفض النزاعات في `kernel/sync`؛ لا يعني وجودها أن كل خصائصها موصولة بالخادم.

إنشاء طلب المتجر لا ينشئ فاتورة أو قيداً ولا يخصم المخزون التشغيلي. يقبل الكاشير الطلب ويراجعه وينقله إلى نقطة البيع؛ التنفيذ المالي والمخزني يتم عند إكمال البيع. المراجع: [StorefrontOrderService](../smart_merchant_platform/app/Services/Storefront/StorefrontOrderService.php)، و[اختبار مسار الطلب](../smart_merchant_erp/test/unit/modules/sales/application/online_order_workflow_test.dart).

## فجوات مؤكدة من المصدر

- في [SyncEngine الخادم](../smart_merchant_platform/app/Services/Sync/SyncEngine.php)، تحديث معظم كيانات الكتالوج الموجودة يغير `revision` فقط، دون تطبيق حقول البيانات الجديدة. لا يجوز وصف تحديث الكتالوج بأنه مكتمل.
- `product_images` مسجل للرفع لكنه غير موجود في خريطة النماذج داخل المحرك نفسه، فيرجع `unsupported_entity`.
- سحب الطلبات يستخدم `revision > cursor` مع الترتيب بالنسخة فقط، بينما الطلب الجديد يبدأ بالنسخة 1؛ يلزم مراجعة عدم فقد طلبات لها النسخة نفسها، والصفحات وبنود الطلب وحالات الإقرار. الإقرار الحالي يضبط الحالة إلى `Acknowledged` بصيغة مبسطة.
- [DurableSyncQueueStorage](../smart_merchant_erp/lib/kernel/sync/queue/sync_queue_storage.dart) يخزن في خريطة بالذاكرة حالياً؛ تحميل القرص مؤجل في تعليق التنفيذ. الاسم لا يعني بقاء الطابور بعد إعادة التشغيل.
- لا تشمل قائمة الكيانات الحالية مزامنة شاملة للفواتير والقيود والجرد. المزامنة الحالية ليست نسخة احتياطية كاملة للنظام.
- خدمة طلب المتجر تختار أول عملة وقناة احتياطية، وتتحقق من توفر إسقاط المخزون دون حجزه؛ يلزم اختبار الإعدادات والتزامن وسياسة الفرع قبل الاستخدام التجاري.

توجد اختبارات عميل وخادم، لكن لم تُعد اختبارات تكامل حقيقية بينهما ضمن مراجعة الوثائق. راجع [الحالة الحالية](STATUS.md) قبل وصف المزامنة بأنها جاهزة للإنتاج.
