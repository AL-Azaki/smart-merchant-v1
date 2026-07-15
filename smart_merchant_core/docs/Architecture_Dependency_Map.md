# Architecture Dependency Map

هذه الخريطة توضح تسلسل الاعتماديات الهرمي بين طبقات النظام ونطاقاته.

Platform Foundations
(Shared Value Objects, System Events, Financial Documents)
        ↓
Shared Foundations
(Core Domain, Base Models, Global Contracts)
        ↓
Domains
(Finance, Inventory, Sales, Purchasing)
        ↓
Integrations
(Sales-Finance, Sales-Inventory, Purchasing-Inventory, Purchasing-Finance)
        ↓
Applications
(Application Layer, Actions, Orchestration)
        ↓
Presentation
(API Resources, Controllers, Policies, Requests)
        ↓
Flutter
(Mobile Application Integration)
        ↓
Admin
(Control Panel and Web Interfaces)
        ↓
Store
(B2B / B2C Interfaces)

---
**القاعدة الأساسية للتبعية (Dependency Rule):**
اتجاه السهم (↓) يمثل "يعتمد على". أي أن الطبقة السفلى تعتمد على الطبقة العليا.
لا يجوز إطلاقاً لطبقة عليا (مثل Domains) أن تعتمد على طبقة سفلى (مثل Integrations أو Presentation).
