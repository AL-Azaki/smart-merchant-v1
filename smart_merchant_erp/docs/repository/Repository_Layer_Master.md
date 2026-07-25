# SMART MERCHANT ERP — COMPLETE REPOSITORY LAYER MASTER ARCHITECTURE & CLOSURE

**Document Status:** MASTER REPOSITORY SPECIFICATION & IMPLEMENTATION CLOSURE  
**Layer:** Repository / Domain Contracts & Infrastructure Implementations  
**Underlying Foundation:** Drift 72-Table ORM & 11 Module-Driven DAOs (Phase 01–10 Recovery Complete)  

---

## 1. Executive Summary & Objective

The **Repository Layer** of Smart Merchant ERP serves as the authoritative, local-first domain data abstraction over the completed 72-table Drift SQLite database and its 11 domain-specific Data Access Objects (DAOs). 

This document establishes the master specification, architecture guidelines, module mapping, error handling rules, and formal verification of the Complete Repository Layer. The repository layer isolates the application use-cases, domain models, and presentation layer from raw database tables, SQL queries, and low-level Drift ORM mechanics while preserving strict multi-tenant scoping (`businessId`), branch isolation (`branchId`), offline-first sync tracking (`syncStatus`), and reactive data streams (`Stream<T>`).

---

## 2. Architectural Design & Folder Structure

In alignment with the project's established modularClean Architecture, repositories are organized by domain under `lib/modules/<domain_name>/`:
- **Domain Contracts (Interfaces):** `lib/modules/<domain_name>/domain/repositories/<domain_name>_repository.dart`
- **Infrastructure Implementations:** `lib/modules/<domain_name>/infrastructure/repositories/<domain_name>_repository_impl.dart`

### 2.1 Domain-to-Repository Module Mapping

| # | Domain Module | DAO Source | Repository Interface (`domain/repositories/`) | Repository Implementation (`infrastructure/repositories/`) | DI Registration (`injectable`) |
|---|---|---|---|---|---|
| 1 | **Authentication** | `AuthDao` | `AuthRepository` | `AuthRepositoryImpl` | `@LazySingleton(as: AuthRepository)` |
| 2 | **Core Foundation** | `CoreDao` | `CoreRepository` | `CoreRepositoryImpl` | `@LazySingleton(as: CoreRepository)` |
| 3 | **Catalog** | `CatalogDao` | `CatalogRepository` | `CatalogRepositoryImpl` | `@LazySingleton(as: CatalogRepository)` |
| 4 | **Inventory** | `InventoryDao` | `InventoryRepository` | `InventoryRepositoryImpl` | `@LazySingleton(as: InventoryRepository)` |
| 5 | **Sales** | `SalesDao` | `SalesRepository` | `SalesRepositoryImpl` | `@LazySingleton(as: SalesRepository)` |
| 6 | **Purchasing** | `PurchasingDao` | `PurchasingRepository` | `PurchasingRepositoryImpl` | `@LazySingleton(as: PurchasingRepository)` |
| 7 | **Accounting** | `AccountingDao` | `AccountingRepository` | `AccountingRepositoryImpl` | `@LazySingleton(as: AccountingRepository)` |
| 8 | **Treasury** | `TreasuryDao` | `TreasuryRepository` | `TreasuryRepositoryImpl` | `@LazySingleton(as: TreasuryRepository)` |
| 9 | **HR** | `HrDao` | `HrRepository` | `HrRepositoryImpl` | `@LazySingleton(as: HrRepository)` |
| 10 | **Fixed Assets** | `FixedAssetsDao` | `FixedAssetsRepository` | `FixedAssetsRepositoryImpl` | `@LazySingleton(as: FixedAssetsRepository)` |
| 11 | **System Admin** | `SystemDao` | `SystemRepository` | `SystemRepositoryImpl` | `@LazySingleton(as: SystemRepository)` |

---

## 3. Error Abstraction & Result Handling Strategy

To prevent raw low-level database exceptions (`SqliteException`, `DriftWrappedException`) from leaking into domain logic or UI handlers, the Repository Layer enforces a centralized error abstraction through `RepositoryErrorGuard` and `RepositoryException`.

### 3.1 Repository Exception Hierarchy (`lib/kernel/error/repository_exceptions.dart`)
- **`RepositoryException`**: Abstract base class for all repository-level exceptions.
- **`RepositoryTenantScopeException`**: Thrown when `businessId` or `branchId` scoping violations occur (`TenantScopingException` mapping).
- **`RepositoryNotFoundException`**: Thrown when a requested record or resource is missing (`RecordNotFoundException` mapping).
- **`RepositoryConflictException`**: Thrown during duplicate records, foreign key constraint failures, or unique key violations (`DuplicateRecordException` / `ForeignKeyConstraintException` mapping).
- **`RepositoryValidationException`**: Thrown when domain or accounting validation fails (`BalancedJournalRequiredException` mapping).
- **`RepositoryPersistenceException`**: Thrown for low-level SQLite execution failures.

Each `RepositoryException` provides a `.toFailure()` method to convert directly into standard equatable `Failure` objects (`RepositoryFailure`, `TenantScopeFailure`, `NotFoundFailure`, `ConflictFailure`, `PersistenceFailure`) for UseCase `Either<Failure, T>` return flows.

---

## 4. Multi-Tenant & Branch Scoping Rules

1. **Mandatory Tenant Scoping:** Every repository method interacting with domain data must explicitly require `businessId` (and `branchId` where applicable) and forward them directly to the underlying DAO.
2. **Branch Override Resolution:** Repositories abstract complex fallback logic (such as `CatalogRepository.getEffectiveProductUnitPrice` or `CoreRepository.getEffectivePrintSetting`) by delegating to specialized DAO resolution methods.
3. **Reactive Stream Preservation:** All reactive queries (`watch*`) return domain `Stream<T>` without conversion to one-shot futures, enabling seamless state management subscription.
4. **Soft-Delete & Sync Status:** Repositories expose soft-delete (`softDelete*`, `restore*`), archive listing, and offline sync tracking (`getPendingSync*`, `mark*AsSynced`) exactly as defined by the underlying DAO contracts.

---

## 5. Verification & Testing Matrix

Every repository is covered by dedicated regression unit tests located in `test/repositories/` verifying:
- **Contract & DI Verification:** Ensuring clean constructor injection via `GetIt` / `Injectable`.
- **Method Forwarding:** Verifying 1:1 fidelity with DAO calls across all query, insert, update, soft-delete, and sync operations.
- **Error Mapping:** Confirming that `RepositoryErrorGuard` catches and maps low-level DAO exceptions to domain-safe `RepositoryException` subclasses.
- **Reactive Streams:** Verifying stream updates upon data mutations.

---

## 6. Implementation Checklist & Final Status

- [x] Phase 1: Repository Master Architecture & Error Abstraction Setup
- [ ] Phase 2: Auth Repository Alignment & Extension
- [ ] Phase 3: Core Repository Implementation & Verification
- [ ] Phase 4: Catalog Repository Implementation & Verification
- [ ] Phase 5: Inventory Repository Implementation & Verification
- [ ] Phase 6: Sales Repository Implementation & Verification
- [ ] Phase 7: Purchasing Repository Implementation & Verification
- [ ] Phase 8: Accounting Repository Implementation & Verification
- [ ] Phase 9: Treasury Repository Implementation & Verification
- [ ] Phase 10: HR Repository Implementation & Verification
- [ ] Phase 11: Fixed Assets Repository Implementation & Verification
- [ ] Phase 12: System Repository Implementation & Verification & Final Verification
