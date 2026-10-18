# التحقق والاختبارات

آخر مراجعة: 18 أكتوبر 2026. [الفهرس](../README.md).

## تشغيل التحقق

من مجلد تطبيق Flutter:

```sh
flutter analyze
flutter test
```

للنطاق المتعلق بالمنتجات والمخزن والجرد:

```sh
flutter test --concurrency=2 test/unit/inventory/stock_count_workflow_test.dart test/widget/modules/corrective_inventory_ui_test.dart test/widget/modules/inventory_view_test.dart test/widget/modules/catalog_entry_test.dart test/unit/inventory/unit_conversion_stock_test.dart test/database/daos/inventory_dao_test.dart test/database/inventory_enum_persistence_test.dart
```

اختبارات شجرة الحسابات في [chart_of_accounts_test.dart](../smart_merchant_erp/test/widget/modules/chart_of_accounts_test.dart) و[phase2_chart_of_accounts_ledger_test.dart](../smart_merchant_erp/test/unit/accounting/phase2_chart_of_accounts_ledger_test.dart). اختبارات القيود والتقارير والخزينة في [test/invariants](../smart_merchant_erp/test/invariants) و[test/unit](../smart_merchant_erp/test/unit).

من مجلد Laravel، بعد إعداد قاعدة اختبار منفصلة: `php artisan test`. لا يضبط `phpunit.xml` الحالي قاعدة داخل الذاكرة؛ افحص الاتصال قبل التشغيل. اختبارات المصدر متاحة في [tests](../smart_merchant_platform/tests)، ولم تُعد ضمن تنظيف الوثائق.

## آخر أدلة نطاق المخزن: 18 أكتوبر 2026

| الفحص | النتيجة المسجلة وحدودها |
|---|---|
| الملفات السبعة بالأمر أعلاه | 67 اختباراً ناجحاً |
| نواة الجرد بعد إحاطة ترقية القاعدة بمعاملة | 16 اختباراً ناجحاً |
| تحليل الملفات المعدلة ضمن هذا النطاق | دون ملاحظات؛ ليس تحليلاً شاملاً لكل تغييرات المستودع |
| بناء التطبيق | حزمة Android تجريبية arm64 ناجحة؛ ليس بناء إصدار توزيع معتمد |
| مراجعة الجهاز | نافذة الجرد والمراجعة على Samsung SM-X218U؛ لا تمثل اختبار كل الشاشات والأجهزة |

تشمل الاختبارات نقصاً وزيادة منفصلين، والمعالجة للخسائر أو الموظف، وتغير الرصيد أثناء العد، والتكلفة المجمدة، ومنع التكرار المتزامن، والفترات المغلقة وعزل المنشأة والفرع. تشمل أيضاً ترقية نسخة 5 إلى 6 دون اختلاق قيود للجرد القديم، وفشل التحويل والتراجع، والصفر والكسور العربية، وأربعة مقاسات ولوحة المفاتيح وقائمة ألف سطر.

السجلات المحلية لهذه الجولة: `corrective-test.log` و`corrective-core-final-test.log` و`corrective-final-analysis.log` و`corrective-final-build.log` داخل مجلد التطبيق. هي مخرجات محلية متجاهلة في Git، وليست ملفات لازمة لتشغيل المشروع أو دليلاً دائماً متاحاً لكل نسخة.

## سياسة النتائج

سجل التاريخ والأمر والنطاق والنتيجة. أعد الفحص المناسب بعد تغييرات المصدر؛ لا تنقل عدداً قديماً للنتائج إلى وصف عام للجاهزية. تستخدم اختبارات الجرد قواعد SQLite في الذاكرة وقاعدة مؤقتة لاختبار الترقية، ولا تحتاج مسح بيانات الجهاز.

تقارير الاختبار المولدة توضع تحت `build/test-reports/`، لتبقى الوثائق اليدوية قليلة وثابتة. في جولة تنظيف الوثائق جرى فحص الروابط المحلية والمراجع والملفات؛ لم تُعد حزم الاختبارات البرمجية بسبب تغيير النصوص فقط.
