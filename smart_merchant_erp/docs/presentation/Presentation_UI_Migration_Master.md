# PRESENTATION UI MIGRATION MASTER

## A. Initial Audit
- **projectUi**: A React/Vite-based UI reference project containing the visual designs and workflows for the Smart Merchant ERP. Key features are modularized into folders like `auth`, `crm`, `dashboard`, `finance`, `inventory`, `purchases`, `reports`, `sales`, `settings`, `setup`, and `users`. It uses shadcn UI and Tailwind-like utility classes.
- **smart_merchant_erp**: The authoritative production Flutter app. It already contains the offline-first Riverpod/Drift architecture, syncing mechanisms, domain models, and partial Sales/POS implementation. Its core architecture is split into `app`, `core`, `kernel`, `modules`, and `shared`.

## B. UI Inventory & Migration Matrix

| UI Component/Flow | projectUi Source | Exists in Production? | Reusable Prod Component? | Migration Required? | Refactor Required? | Business Integration Now? | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Inventory & Products** | | | | | | | |
| ProductListScreen | `features/inventory/screens/ProductListScreen.tsx` | No | Partially (needs table/grid) | Yes | Yes (to Flutter) | Presentation boundary only | **MIGRATED** |
| ProductFormSheet | `features/inventory/components/ProductFormSheet.tsx` | No | No | Yes | Yes (to Flutter dialog/sheet) | Presentation boundary only | Deferred |
| ProductDetailScreen | `features/inventory/components/ProductDetailScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| CategoryListScreen | `features/inventory/screens/CategoryListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| CategoryFormSheet | `features/inventory/components/CategoryFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| UnitListScreen | `features/inventory/screens/UnitListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| UnitFormSheet | `features/inventory/components/UnitFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| WarehouseListScreen | `features/inventory/screens/WarehouseListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| WarehouseFormSheet | `features/inventory/components/WarehouseFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| StockAdjustmentsScreen | `features/inventory/screens/StockAdjustmentsScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| StockAdjustmentFormSheet| `features/inventory/components/StockAdjustmentFormSheet.tsx`| No | No | Yes | Yes | Presentation boundary only | Deferred |
| **Purchasing** | | | | | | | |
| PurchaseListScreen | `features/purchases/screens/PurchaseListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| NewPurchaseScreen | `features/purchases/screens/NewPurchaseScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| SupplierListScreen | `features/purchases/screens/SupplierListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| SupplierFormSheet | `features/purchases/components/SupplierFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| **Customers & Suppliers** | | | | | | | |
| ContactListScreen | `features/crm/screens/ContactListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| ContactFormSheet | `features/crm/components/ContactFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| CustomerStatementScreen | `features/crm/components/CustomerStatementScreen.tsx`| No | No | Yes | Yes | Presentation boundary only | Deferred |
| **Employees** | | | | | | | |
| EmployeeListScreen | `features/inventory/screens/EmployeeListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| EmployeeFormSheet | `features/inventory/components/EmployeeFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| **Fixed Assets** | | | | | | | |
| FixedAssetListScreen | `features/inventory/screens/FixedAssetListScreen.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| FixedAssetFormSheet | `features/inventory/components/FixedAssetFormSheet.tsx` | No | No | Yes | Yes | Presentation boundary only | Deferred |
| **Shared/Modals** | | | | | | | |
| ConfirmDeleteModal | `shared/components/ConfirmDeleteModal.tsx` | No | Needs creation in Flutter | Yes | Yes | Yes | Deferred |

*Note: This matrix will be dynamically updated as migration progresses.*

## C. Shared Components
- **Reused**:
  - [custom_text_field.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/shared/design_system/widgets/custom_text_field.dart)
  - [stat_card.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/shared/design_system/widgets/stat_card.dart) - Refactored to wrap the title Text widget in `Expanded` to prevent horizontal layout overflows.
  - [primary_button.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/shared/design_system/widgets/primary_button.dart) - Refactored text widget wrapping to `Flexible` to avoid horizontal layout overflows on small screen boundaries.
- **Created**:
  - Custom horizontally scrollable KPI card list in ProductsView.
  - TabBar-driven module views layout.

## D. Migrated Modules
- **Inventory & Products**:
  - Developed [inventory_module_view.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/modules/inventory/presentation/views/inventory_module_view.dart) with localized tabs (المنتجات, المشتريات, العملاء والموردين, الموظفين, الأصول الثابتة, الأرشيف والمستندات, تسوية وجرد المخزون).
  - Developed [products_view.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/modules/catalog/presentation/views/products_view.dart) containing the products grid layout, search actions, adding product actions, and KPI indicators.

## E. Routes Added/Modified
- Updated `/inventory` route in [app_router.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/lib/app/routes/app_router.dart) to direct to the new `InventoryModuleView`.

## F. Tests
- Created [inventory_view_test.dart](file:///d:/ALL-My_Projects/smart_merchant_v1/smart_merchant_erp/test/widget/modules/inventory_view_test.dart) to test widget rendering and correct stream provider mapping. All tests passed.

## G. Known Issues & Fixes
- Fixed compilation errors in `customer_select_modal.dart` and `customer_add_modal.dart` due to incorrect positional parameter counts for `setCustomer` (2 expected, 1 found).
- Fixed compilation error in `treasury_provider.dart` due to incorrect parameters passed to `ReceivePaymentCommand` and `PaymentAllocationCommand`.
- Fixed compilation error in `catalog_provider.dart` due to missing `ProductFilter` import.

## H. Final Status
`PRESENTATION UI MIGRATION FOUNDATION — COMPLETE`
