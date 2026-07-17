# CashRegister Architecture

## 1. Purpose
The purpose of the `CashRegister` Aggregate Root is to represent a logical and physical container for cash within a branch. It acts as the central point for managing cash inflows, outflows, daily reconciliations, and strict session-based financial integrity.

## 2. Responsibilities
- **Container Management:** Managing the state and details of the cash box or till.
- **Session Control:** Governing the opening and closing of the cash register.
- **Balance Tracking:** Tracking the current calculated balance accurately based on immutable cash transactions.
- **Transaction Receipt:** Receiving and validating cash movements (inflows and outflows).
- **Discrepancy Calculation:** Computing expected vs. actual physical cash during the closing process.

## 3. Entity Classification
- **Classification:** Aggregate Root
- **Domain:** Cash Management

## 4. Relationships
The `CashRegister` interacts with the following conceptual entities:
- **Business:** The tenant that owns the cash register.
- **Branch:** The specific physical or logical location where the register operates.
- **Currency:** The base currency assigned to this specific register.
- **User (Responsible User):** The assigned cashier or treasurer currently responsible for the register's physical cash.

## 5. Lifecycle
The `CashRegister` operates within a strict session-based lifecycle:
- **Closed:** The register is physically locked or logically deactivated. No cash transactions can be processed. This is the default initial state.
- **Open:** The register is active, assigned to a user, and has a declared opening balance. It is ready to process cash transactions.

*(Note: "Suspended" or "Locked" states are omitted to maintain simplicity and strict accountability. If an operator steps away, the platform's authentication session handles it. From a cash flow perspective, it is either Open and receiving transactions, or Closed and reconciled).*

## 6. Business Rules
- A `CashRegister` cannot exist without being assigned to a specific `Currency`.
- A `CashRegister` strictly belongs to one `Business` and one `Branch`.
- A `CashRegister` cannot process any cash transaction while in a `Closed` state.
- A `CashRegister` can only have one active session (i.e., be `Open`) at a time.
- The `current_balance` of the register must always be exactly equal to the mathematical sum of its Opening Balance plus all approved transactions during the current open session.

## 7. Opening Balance Policy
- When transitioning from `Closed` to `Open`, the user MUST declare the initial physical cash in the drawer (Opening Balance).
- This declared amount becomes the baseline for the current session.
- The system may compare the new Opening Balance against the previous Closing Balance and log any discrepancies as an internal audit event.

## 8. Closing Balance Policy
- When transitioning from `Open` to `Closed`, the user MUST declare the final physical cash counted in the drawer (Actual Balance).
- The system computes the `Expected Balance` (Opening Balance + Inflows - Outflows).
- Any difference between the `Actual Balance` and `Expected Balance` is recorded as a Discrepancy (Overage or Shortage).
- Closing the register creates an immutable snapshot of the session.

## 9. Currency Policy
- The `CashRegister` has a strict single **Base Currency**.
- The `current_balance` is always maintained and represented in this Base Currency.
- If a transaction occurs in a foreign currency, the exact exchange rate at the moment of the transaction must be applied to determine the equivalent impact on the register's Base Currency balance. The register itself does not hold multi-currency balances natively.

## 10. Security Rules
- Only users with explicitly assigned roles (e.g., Cashier, Branch Manager) can open or close a `CashRegister`.
- A user can only interact with a `CashRegister` assigned to their permitted `Branch`.
- High-variance discrepancies during closing may trigger an immediate security alert or require dual-authorization (Branch Manager approval).

## 11. Audit Trail
- Every state change (Open -> Closed, Closed -> Open) must be logged with the timestamp, user ID, expected balance, actual balance, and any discrepancy details.
- Standard platform audit fields (`created_by`, `created_at`, `updated_by`, `updated_at`) apply to the register definition itself.

## 12. Ownership Rules
- The `CashRegister` is an independent Aggregate Root.
- It "owns" its current session state and acts as the gatekeeper for any `CashTransaction` that attempts to alter its balance.
- A `CashTransaction` (which will be defined separately) cannot modify the register's balance bypassing the `CashRegister` rules.

## 13. Dependencies
- **Platform Tenant Foundation:** For Business and Branch isolation.
- **Platform Authentication & Authorization:** For enforcing user constraints and roles.
- **Finance Domain (Currency):** For validating the base currency.

## 14. Out Of Scope
- **General Ledger Accounting:** The register does not post its own overages/shortages directly to the GL. This is handled by a separate settlement/posting engine integration.
- **Payment Method Setup:** The register stores cash, not configuration for credit card terminals or online gateways.
- **Sales Data:** The register does not care about what products were sold, only the cash inflow resulting from a transaction.
