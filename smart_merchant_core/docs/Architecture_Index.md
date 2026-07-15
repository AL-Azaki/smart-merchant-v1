# Architecture Index

## 1. Platforms & Foundations (01-foundations)
- Shared_Value_Objects_Foundation_Architecture.md
- Financial_Documents_Foundation_Architecture.md
- System_Domain_Events_Foundation_Architecture.md

## 2. Domains (02-domains)

### 2.1 Finance Domain
- **Foundation**: Finance_General_Ledger_Foundation_Architecture.md, Finance_Account_Mapping_Foundation_Architecture.md
- **Entities**: JournalEntry_Architecture.md, JournalEntryLine_Architecture.md
- **Services**: PostingEngine_Architecture.md, AccountMapping_Architecture.md
- **Contracts**: Posting_Engine_Contract_Architecture.md
- **Notes**: finance_architecture_decisions.md, finance_dependency_diagram.md, finance_domain_architecture_analysis.md, finance_entity_classification.md, finance_implementation_plan.md, read_operations_classification.md

### 2.2 Sales Domain
- **Foundation**: Sales_Foundation_Architecture.md
- **Entities**: SalesInvoice_Architecture.md, SalesInvoiceItem_Architecture.md

### 2.3 Inventory Domain
- **Foundation**: Inventory_Foundation_Architecture.md
- **Entities**: InventoryTransaction_Architecture.md, InventoryTransactionLine_Architecture.md

### 2.4 Purchasing Domain
- **Foundation**: Purchasing_Foundation_Architecture.md
- **Entities**: PurchaseInvoice_Architecture.md, PurchaseInvoiceItem_Architecture.md

## 3. Integrations (03-integrations)
*(مجلد مخصص لوثائق التكامل بين النطاقات)*

## 4. Other Directories
- 00-overview (نظرة عامة على النظام)
- 04-api (مواصفات الواجهات البرمجية)
- 05-mobile (تطبيقات الجوال)
- 06-admin (لوحة التحكم)
- 99-archive (الأرشيف)
