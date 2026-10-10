# 📚 الدليل المعماري الشامل لنظام Smart Merchant ERP (Flutter Offline-First)

مرحباً بك في الوثيقة المرجعية الرسمية لتنفيذ وبناء نظام **Smart Merchant ERP**.
تم إعداد هذه الوثائق بدقة هندسية ومحاسبية صارمة لتوجيه المطورين وأدوات الذكاء الاصطناعي (AI Coding Assistants) لبناء النظام بأعلى المعايير، ومنع أي أخطاء أو انحرافات حسابية أو تكرار في العمل.

---

## 📑 فهرس وثائق المراحل التنفيذية (The Complete Blueprint Index)

| الوثيقة | المرحلة | المحتوى الرئيسي |
|---|---|---|
| [00_MASTER_ERP_EXECUTION_BLUEPRINT.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/00_MASTER_ERP_EXECUTION_BLUEPRINT.md) | **المخطط التنفيذي الشامل** | فلسفة المحاسبة الصامتة، تقليص النطاق للـ MVP، مصفوفة الـ 15 فخاً خفياً، وتوزيع المهام بين أعضاء الفريق. |
| [PHASE_1_CORE_ENGINE_AND_STORAGE.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_1_CORE_ENGINE_AND_STORAGE.md) | **المرحلة 1: النواة وقاعدة البيانات والمحرك المالي** | جداول Drift الـ 18، شجرة الحسابات المقفلة مسبقاً (Pre-Seeded COA)، محرك اتزان القيود المزدوجة، الدقة العشرية، وحزمة اختبارات القيد. |
| [PHASE_2_CATALOG_INVENTORY_AND_COSTING.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_2_CATALOG_INVENTORY_AND_COSTING.md) | **المرحلة 2: الكتالوج، المخزون، والوحدات والتكلفة** | محرك تحويل الوحدات (حبة/كرتون)، خوارزمية المتوسط المرجح المتحرك (Moving Average Cost)، سياسة البيع بالسالب، وسجل الحركات المخزنية. |
| [PHASE_3_SALES_AND_POS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_3_SALES_AND_POS.md) | **المرحلة 3: المبيعات ونقطة البيع والكاشير** | المعاملة الذرية الخماسية للبيع، ربط واجهة الـ POS الحقيقية، توزيع الخصومات، المرتجعات، وتوليد قيود المبيعات وتكلفة المبيعات آلياً. |
| [PHASE_4_PURCHASING_AND_SUPPLIERS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_4_PURCHASING_AND_SUPPLIERS.md) | **المرحلة 4: المشتريات والموردين وإدارة الديون** | فواتير الشراء النقدية والآجلة، تحديث أسعار التكلفة التلقائي، مصاريف الشحن الإضافية وتوزيعها، ومرتجعات المشتريات. |
| [PHASE_5_TREASURY_AND_VOUCHERS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_5_TREASURY_AND_VOUCHERS.md) | **المرحلة 5: الخزينة، الصناديق، والسندات** | سندات القبض والصرف، التحويل بين الصناديق، معالجة فروق أسعار الصرف (FX Gain/Loss)، وجرد الصندوق وإقفال الكاشير اليومي (X & Z Reports). |
| [PHASE_6_CLOSINGS_AND_FINANCIAL_REPORTS.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_6_CLOSINGS_AND_FINANCIAL_REPORTS.md) | **المرحلة 6: الإقفالات المالية والتقارير والأرباح** | كشف حساب العميل التراكمي اللحظي، قائمة الدخل والأرباح والخسائر (P&L)، بطاقة حركة الصنف، والإقفال السنوي وقفل الفترات. |
| [PHASE_7_OFFLINE_SYNC_AND_STORE_BRIDGE.md](file:///d:/laragon/www/smart-merchant-v1/smart_merchant_erp/docs/blueprint/PHASE_7_OFFLINE_SYNC_AND_STORE_BRIDGE.md) | **المرحلة 7: المزامنة الأوفلاين وجسر المتجر** | نمط صندوق الصادر (Outbox Pattern)، سياسة فض النزاعات، مزامنة الكتالوج، واستقبال طلبات المتجر وتحويلها لفاتورة بضغطة واحدة. |

---

## 🎯 القواعد الذهبية الإلزامية لكل مبرمج في الفريق (Gold Rules):
1. **المحاسبة الصامتة:** لا تسأل التاجر عن حساب مدين ودائن في أي واجهة؛ استخدم المعرفات النظامية (`systemRole`) في المحرك الآلي.
2. **الذرية المطلقة (Atomicity):** أي عملية بيع أو شراء أو سند يجب أن تتم داخل كتلة `db.transaction()` واحدة؛ لا تقبل أبداً حفظ فاتورة بدون خصم مخزن أو بدون قيد متزن.
3. **الدقة العشرية:** ممنوع استخدام نوع `double` الخام بدون استدعاء `PrecisionMath.roundMoney`.
4. **منع الحذف في المحاسبة (Immutability):** لا يوجد حذف للفواتير أو السندات المرحّلة؛ التعديل يتم فقط عبر قيود وسندات وفواتير عكسية (Void / Return).
5. **وحدة الأساس المخزنية:** الكميات في جدول `inventories` تُخزن دائماً بالوحدة الصغرى للمنتج (حبة).
