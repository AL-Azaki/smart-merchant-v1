# Smart Merchant ERP - Architecture Documentation

## وصف المجلد
هذا المجلد هو المرجع الشامل لجميع الوثائق المعمارية، التصميمية، والتقنية لنظام Smart Merchant ERP.

## الغرض منه
الهدف من هذا المجلد هو تنظيم الوثائق في هيكل قياسي يسهل عملية البحث، القراءة، والمراجعة، ويمنع التكرار، ويحافظ على قواعد Clean Architecture و Domain-Driven Design.

## قائمة الوثائق الموجودة داخله
يحتوي هذا المستوى على المجلدات الرئيسية:
- `00-overview/`: نظرة عامة على النظام.
- `01-foundations/`: القواعد والمبادئ المشتركة.
- `02-domains/`: النطاقات المعمارية (Finance, Sales, Inventory, Purchasing, Core وغيرها).
- `03-integrations/`: وثائق التكامل بين النطاقات.
- `04-api/`: وثائق واجهات برمجة التطبيقات.
- `05-mobile/`: وثائق تطبيقات الجوال.
- `06-admin/`: وثائق لوحة التحكم.
- `99-archive/`: الأرشيف.
- `Architecture_Index.md`: الفهرس الشامل للوثائق.
- `Architecture_Dependency_Map.md`: خريطة الاعتماديات.

## ترتيب قراءة الوثائق
1. قراءة `Architecture_Dependency_Map.md` لفهم التسلسل الهرمي.
2. قراءة `Architecture_Index.md` للاطلاع على محتويات النظام.
3. التوجه إلى `00-overview` ثم `01-foundations`.
4. قراءة تفاصيل كل نطاق داخل `02-domains`.

## الاعتماديات (Dependencies)
يعتمد هذا المجلد بشكل أساسي على الدساتير الموجودة داخل `01-foundations`.
