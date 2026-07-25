# Drift Foundation Corrections & Audit Log

This document records architectural corrections, schema alignments, and verification audits performed on the Drift ORM Database Foundation (`lib/database/`) to maintain 100% fidelity to the authoritative SQLite extraction specifications.

---

## [2026-07-21] Inventory Enum / CHECK Constraint Alignment & Foundation Resolution

### 1. Issue Summary
Before initiating Phase 03 (`InventoryDao`) implementation, a critical foundation-level discrepancy was identified in the Inventory domain schema:
- **Discrepancy:** The `CHECK` constraints defined in `lib/database/tables/inventory/inventory_transactions_table.dart` and `inventory_transfers_table.dart` enforced the legacy space-separated/uppercase string literals established in `docs/sqlite_schema/SQLite_Enums_Specification.md` (e.g., `'Receipt'`, `'Adjustment In'`, `'IN'`, `'OUT'`, `'Draft'`, `'Posted'`, `'Reversed'`, `'SalesInvoice'`, `'Pending'`, `'Completed'`, `'Cancelled'`).
- However, the initial Dart enum definitions in `lib/database/enums/inventory_*.dart` and their associated Drift `TypeConverter` mappings were outputting unaligned camelCase/normalized string literals (`'adjustmentIn'`, `'inbound'`, `'draft'`, `'purchaseInvoice'`, `'inTransit'`).
- **Impact:** Any database `INSERT` or `UPDATE` operation attempting to persist these unaligned enum values triggered a `CHECK constraint failed` exception (`sqlite3.SqliteException`), blocking valid inventory operations.

### 2. Authoritative Persistence Contract Established
Per `docs/sqlite_schema/SQLite_Enums_Specification.md` Section 1 & 2 (`منع الافتراض` and `تخزين SQLite كـ TEXT بالسلاسل النصية الدقيقة الموضحة في وثيقة المرجع`), the **Canonical Persisted SQLite Storage Representation** is strictly defined by the authoritative SQLite `CHECK` constraints. 

To achieve 100% alignment without altering established table definitions or breaking domain consistency, **Option A / Canonical Alignment** was executed:
Every Dart Enum class in `lib/database/enums/inventory_*.dart` was updated so that its `.value` property directly returns the canonical string literal mandated by the SQLite `CHECK` constraint, and `.fromValue(String value)` performs case-insensitive matching (`e.value.toLowerCase() == value.toLowerCase()`) with safe fallbacks.

The canonical mapping contract:
| Enum Type | Dart Case | Canonical SQLite String (`toSql` / `.value`) | Matching Table `CHECK` Constraint |
| :--- | :--- | :--- | :--- |
| **`InventoryTransactionType`** | `receipt`<br>`dispatch`<br>`adjustmentIn`<br>`adjustmentOut`<br>`openingBalance` | `'Receipt'`<br>`'Dispatch'`<br>`'Adjustment In'`<br>`'Adjustment Out'`<br>`'Opening Balance'` | `CHECK (transaction_type IN ('Receipt', 'Dispatch', 'Adjustment In', 'Adjustment Out', 'Opening Balance'))` |
| **`InventoryMovementDirection`** | `inbound`<br>`outbound` | `'IN'`<br>`'OUT'` | `CHECK (movement_direction IN ('IN', 'OUT'))` |
| **`InventoryTransactionStatus`** | `draft`<br>`posted`<br>`reversed` | `'Draft'`<br>`'Posted'`<br>`'Reversed'` | `CHECK (status IN ('Draft', 'Posted', 'Reversed'))` |
| **`InventoryReferenceType`** | `salesInvoice`<br>`salesReturn`<br>`purchaseInvoice`<br>`purchaseReturn`<br>`transfer`<br>`adjustment` | `'SalesInvoice'`<br>`'SalesReturn'`<br>`'PurchaseInvoice'`<br>`'PurchaseReturn'`<br>`'Transfer'`<br>`'Adjustment'` | `CHECK (reference_type IS NULL OR reference_type IN ('SalesInvoice', 'SalesReturn', 'PurchaseInvoice', 'PurchaseReturn', 'Transfer', 'Adjustment'))` |
| **`InventoryTransferStatus`** | `pending`<br>`completed`<br>`cancelled` | `'Pending'`<br>`'Completed'`<br>`'Cancelled'` | `CHECK (status IN ('Pending', 'Completed', 'Cancelled'))` |

### 3. Modified Files & Rationale
1. **`lib/database/enums/inventory_transaction_type.dart`**
   - **Change:** Replaced non-canonical cases (`purchase`, `sale`, etc.) with canonical cases (`receipt`, `dispatch`, `adjustmentIn`, `adjustmentOut`, `openingBalance`) and set `.value` to `'Receipt'`, `'Dispatch'`, `'Adjustment In'`, `'Adjustment Out'`, `'Opening Balance'`.
2. **`lib/database/enums/inventory_movement_direction.dart`**
   - **Change:** Aligned cases `inbound` and `outbound` with canonical values `'IN'` and `'OUT'`. Removed non-canonical `internal` case which was rejected by table `CHECK` constraints.
3. **`lib/database/enums/inventory_transaction_status.dart`**
   - **Change:** Aligned cases `draft`, `posted`, `reversed` with canonical values `'Draft'`, `'Posted'`, `'Reversed'`.
4. **`lib/database/enums/inventory_reference_type.dart`**
   - **Change:** Aligned cases (`salesInvoice`, `salesReturn`, `purchaseInvoice`, `purchaseReturn`, `transfer`, `adjustment`) with canonical values (`'SalesInvoice'`, `'SalesReturn'`, `'PurchaseInvoice'`, `'PurchaseReturn'`, `'Transfer'`, `'Adjustment'`).
5. **`lib/database/enums/inventory_transfer_status.dart`**
   - **Change:** Aligned cases (`pending`, `completed`, `cancelled`) with canonical values (`'Pending'`, `'Completed'`, `'Cancelled'`).
6. **`test/database/inventory_enum_persistence_test.dart`**
   - **Change:** Created a permanent, comprehensive regression test suite verifying `toSql`/`fromSql` round-trip fidelity, zero-failure `INSERT` operations for all enum values, and positive rejection of invalid raw SQL strings by `CHECK` constraints.

*Note: Table definitions (`inventory_transactions_table.dart`, `inventory_transfers_table.dart`) and `TypeConverter` classes required zero modifications as their existing definitions and `value.value` delegation were already structurally sound.*

### 4. Code Regeneration & Verification Proof
- **Regeneration Command Run:** `dart run build_runner build --delete-conflicting-outputs`
  - **Outcome:** Successfully completed (`Built with build_runner in 66s; wrote 56 outputs`).
- **Regression Verification Run:** `flutter test test/database/`
  - **Outcome:** All 36 database foundation & DAO tests passed cleanly in 2 seconds with zero regressions across `AuthDao`, `CoreDao`, `CatalogDao`, and `inventory_enum_persistence_test.dart`.

```text
00:00 +0: loading test/database/inventory_enum_persistence_test.dart
00:01 +15: All tests passed! (inventory_enum_persistence_test.dart)
00:02 +36: All tests passed! (test/database/ suite including auth_dao_test.dart, core_dao_test.dart, catalog_dao_test.dart)
```

### 5. Phase 03 Unblock Confirmation
With exact canonical alignment achieved and verified across both positive insert operations and negative constraint rejections, the Drift ORM foundation discrepancy is permanently resolved.

**DAO Phase 03 (`InventoryDao`) is officially UNBLOCKED and ready for implementation.**
