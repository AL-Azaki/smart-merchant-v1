# SMART MERCHANT PLATFORM

# LARAVEL FOUNDATION & READINESS AUDIT

# FINAL REPORT

## 1. Final Status

`FOUNDATION PARTIALLY READY — CORRECTIONS REQUIRED`

The base structure, database configuration, and foundational schema exist, but major components (models, synchronization fields, API structure, and tests) are missing and must be built before implementing full APIs.

## 2. Laravel / PHP / Database Baseline

* **Laravel Version:** 13.20.0
* **PHP Requirement:** 8.4.14
* **Database Engine:** PostgreSQL (pgsql)
* **Testing Framework:** PHPUnit 12.5.12 (with Pest plugin allowed)
* **Authentication Packages:** `laravel/sanctum` (^4.0)
* **Authorization Packages:** None (Core Laravel features only)
* **API Packages:** None
* **Queue Configuration:** `database`
* **Cache Configuration:** `database`
* **Storage Configuration:** `local` (public/storage NOT LINKED)
* **Frontend Tooling:** Vite, TailwindCSS (in package.json)

## 3. Existing Architecture

Standard baseline Laravel initialization.
The project does not currently employ Domain architecture, Modular architecture, Service Layer, Action classes, or DTOs. It is a completely fresh scaffold containing only configuration and database migrations.

## 4. Database Summary

Exact table count: 28 migrations/tables.

## 5. Domain Table Matrix

| Domain | Tables |
| :--- | :--- |
| **Platform / Core** | `cache`, `jobs`, `currencies`, `accounts`, `personal_access_tokens` |
| **Businesses** | `businesses`, `branches` |
| **Users** | `users`, `user_branches` |
| **Roles / Permissions** | `roles`, `permissions`, `role_permissions`, `user_roles` |
| **Subscriptions** | `plans`, `subscriptions`, `subscription_payments` |
| **E-Commerce / Storefront** | `channels`, `categories`, `brands`, `units`, `products`, `product_units`, `product_images`, `product_channels`, `carts`, `cart_items`, `orders`, `order_items` |

## 6. Migration Verification

All 28 migrations successfully ran using `php artisan migrate:status`. Relationships, foreign keys (`restrict` constraints), and structural indexes (UUIDs) exist. No duplicate or overlapping migrations found.

## 7. Models Verification

* **Missing:** 27 Models.
* **Complete:** Only `User.php` exists.
* Models for Businesses, Products, Orders, Branches, etc., have not been created yet.

## 8. Authentication Readiness

`laravel/sanctum` is installed and the `personal_access_tokens` table exists.
Routes and controllers for issuing tokens, logging in, or handling sessions are missing.

## 9. Authorization / Permissions Readiness

Tables exist (`roles`, `permissions`, `role_permissions`, `user_roles`).
No Laravel Policies, Gates, or middleware are implemented to handle permission checks.

## 10. Business / Tenant Architecture

The schema heavily relies on `business_id` as a foreign key on operational tables (e.g., `products`, `orders`, `categories`). The table `businesses` exists and links to `account_id`. This provides a strong foundation for tenant isolation at the database level.

## 11. Subscription Readiness

Tables exist (`plans`, `subscriptions`, `subscription_payments`).
Logic and enforcement boundaries (Middleware / Policies) to restrict features based on subscription status are entirely missing.

## 12. Device Management Readiness

**CRITICAL DEFICIENCY:** No device tables exist. The concept of device management (needed for mobile client sync registration, revocation, and tracking) is missing from the schema.

## 13. Synchronization Readiness

**CRITICAL DEFICIENCY:** No synchronization schema exists.
Operational tables (like `businesses`, `products`, `orders`) do NOT contain:
* `sync_status`
* `version`
* `device_id`
* `last_synced_at`
* `server_updated_at`
* tombstone tables for soft deletions in sync contexts.
The current schema cannot support a robust offline-first synchronization protocol.

## 14. Idempotency Readiness

No idempotency keys or sync batch tables are present in the schema to protect against network retries or duplicate payloads.

## 15. Flutter ↔ Laravel Ownership Matrix

| Entity | Flutter SQLite | Laravel | Authority | Sync Direction |
| :--- | :--- | :--- | :--- | :--- |
| **User / Account** | Read-Only | Read-Write | `REMOTE AUTHORITATIVE` | Laravel → Flutter |
| **Business / Branch**| Read-Only | Read-Write | `REMOTE AUTHORITATIVE` | Laravel → Flutter |
| **Subscription / Plan**| Read-Only | Read-Write | `REMOTE AUTHORITATIVE` | Laravel → Flutter |
| **Product / Category** | Read-Write | Read-Write | `SYNCHRONIZED` | Bidirectional |
| **Sales Invoice** | Read-Write | Read-Only | `LOCAL AUTHORITATIVE` | Flutter → Laravel |
| **Inventory** | Read-Write | Read-Only | `LOCAL AUTHORITATIVE` | Flutter → Laravel |
| **E-Commerce Product** | Read-Only | Read-Write | `REMOTE AUTHORITATIVE` | Laravel → Storefront |
| **Online Order** | Read-Only | Read-Write | `REMOTE AUTHORITATIVE` | React Storefront → Laravel → Flutter |

## 16. E-Commerce Readiness

Tables exist (`products`, `categories`, `brands`, `carts`, `channels`).
No controllers or storefront APIs are implemented.

## 17. Storefront Readiness

No configuration for storefront slugs, domains, or tenant-scoping logic exists on the `businesses` or `channels` schemas. The database is prepared for e-commerce entities, but tenant resolution for a public storefront is undefined.

## 18. Online Order Readiness

`orders` and `order_items` tables exist. The integration logic to pass these down to the Flutter ERP is missing.

## 19. Admin Dashboard Backend Readiness

No API boundaries or controllers exist for the React Admin Dashboard.

## 20. API Status

**MISSING:** The API is empty. `routes/api.php` only contains a default `/api/user` and commented placeholders. No actual endpoints are implemented.

## 21. API Versioning

No API versioning structure (e.g., `/api/v1/`) is currently established.

## 22. Route Audit

Only standard framework routes are registered:
* `/`
* `api/user`
* `sanctum/csrf-cookie`
* `storage/{path}`
* `up`

## 23. Validation / Resources / Errors

* No Laravel Form Requests.
* No Laravel API Resources.
* No standardized API error envelopes or exception handlers.

## 24. Security Audit

Tenant isolation exists strictly through foreign keys (`business_id`). There is no middleware to enforce it yet. Mass assignment (`$fillable`/`$guarded`) is undefined because models do not exist.

## 25. Tenant Isolation Audit

Strong database relations for `business_id` exist. Middleware and Global Scopes must be introduced to guarantee tenant data separation during queries.

## 26. CORS / Rate Limiting

Standard default Laravel configuration. Needs customization for React Admin, React Storefront, and Flutter Mobile clients.

## 27. Queue / Cache / Storage

* **Queue/Cache:** Configured for `database`.
* **Storage/Media:** Configured for `local`. Must run `php artisan storage:link`.

## 28. Existing Unit Tests

Only `tests/Unit/ExampleTest.php` exists. (1 test file)

## 29. Existing Feature Tests

Only `tests/Feature/ExampleTest.php` exists. (1 test file)

## 30. Test Execution Results

Total tests: 2 default Laravel examples. No application-specific tests exist.

## 31. Missing Critical Tests

* Authentication & Token generation
* Tenant isolation and cross-business attack prevention
* Synchronization (Idempotency, Conflicts, Retries)
* Subscription enforcement
* E-commerce tenant isolation

## 32. Code Quality Results

No specialized static analysis tools (e.g., PHPStan, Pint) are actively configured or run in CI.

## 33. React Admin Recommendation

**Separate Project Repository.** Keep Laravel strictly as an API backend. `smart_merchant_admin` should be its own Vite/React project to ensure independent scaling, deployment, and stateless API consumption.

## 34. React Storefront Recommendation

**Separate Project Repository.** Similar to the admin dashboard, the storefront (`smart_merchant_storefront`) should be fully decoupled to optimize for customer-facing performance and SEO (e.g., Next.js or dedicated React SPA).

## 35. Repository / Deployment Recommendation

**Option B:** Laravel API remains a standalone backend repository, while the React applications are separate client projects.

## 36. Recommended Laravel Directory Structure

```
app/
├── Http/
│   ├── Controllers/
│   │   ├── Api/
│   │   │   ├── V1/
│   │   │   │   ├── Admin/
│   │   │   │   ├── Mobile/
│   │   │   │   ├── Storefront/
│   │   │   │   └── Sync/
│   ├── Requests/
│   ├── Resources/
│   └── Middleware/
├── Models/
├── Policies/
└── Services/
```

## 37. Recommended API Families

* `/api/v1/auth/`
* `/api/v1/mobile/` (General ERP fetch)
* `/api/v1/sync/` (Idempotent sync protocol)
* `/api/v1/admin/` (Platform dashboard)
* `/api/v1/storefront/` (E-Commerce)

## 38. First Login / Bootstrap Readiness

Missing. A session bootstrap endpoint is required to return User, Business, Branch, Permissions, and Subscription context to Flutter after login.

## 39. Admin First-Visibility Readiness

Missing. Seeders or CLI commands are required to securely bootstrap the initial Platform Admin account.

## 40. Files Modified During Audit

NONE.

## 41. Master Document

Confirmed: `docs/architecture/Laravel_Platform_Readiness_Audit.md`

## 42. Critical Problems

* **Missing Synchronization Schema:** The database lacks all required sync fields (`sync_status`, `device_id`, `version`) to support offline-first Flutter synchronization.
* **Missing Device Tracking:** No tables for mobile devices.
* **Missing Models:** Only `User.php` exists.

## 43. What Is Already Complete

* Project setup (Laravel 13).
* Core relational tables & migrations.
* Database tenant hierarchy.

## 44. What Is Partially Complete

* Authentication (Schema exists, logic missing).
* E-Commerce (Schema exists, logic missing).

## 45. What Is Missing

* Eloquent Models.
* Synchronization Schema (Version, Sync Status).
* Form Requests, API Resources, and API Controllers.
* Middleware for Tenant/Subscription validation.
* Test suite.

## 46. Exact Next Laravel Stage

**Foundation Corrections:** Generate all missing Eloquent Models and upgrade migrations to include mandatory synchronization fields (versions, sync states, device linking, and tombstones) and device management tables.

## 47. Recommended Execution Order

1. **Foundation Corrections** (Models & Sync/Device Schema Migrations)
2. **Authentication** (Sanctum setup & login)
3. **Session / Bootstrap** (Context delivery for Flutter)
4. **Tenant / Business Context** (Middleware isolation)
5. **Authorization / Permissions** (Policies & Roles)
6. **Device Registration** (Linking Flutter devices)
7. **Sync Protocol** (Idempotent API for mobile sync)
8. **Admin API**
9. **E-Commerce / Storefront API**

## 48. Final Readiness Decision

`FOUNDATION PARTIALLY READY — CORRECTIONS REQUIRED`
