import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../../kernel/storage/tables/auth_tables.dart';

part 'auth_dao.g.dart';

/// Module-Driven DAO for Domain: Foundation & Auth (Phase 01).
///
/// Encapsulates pure local database CRUD, queries, streams, and transactional setup
/// for [UsersTable], [AccountsTable], and [SubscriptionsTable].
///
/// Strictly enforces local-first operational focus without network/remote API calls
/// or domain DTO mapping.
@DriftAccessor(tables: [UsersTable, AccountsTable, SubscriptionsTable])
class AuthDao extends DatabaseAccessor<AppDatabase> with _$AuthDaoMixin {
  AuthDao(super.db);

  // ==========================================
  // 1. USERS OPERATIONS (Global / Multi-Tenant)
  // ==========================================

  /// Retrieves a user by their unique ID.
  Future<UserAccount?> getUserById(String id) {
    return (select(
      usersTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves a user by their unique email address.
  Future<UserAccount?> getUserByEmail(String email) {
    return (select(
      usersTable,
    )..where((tbl) => tbl.email.equals(email))).getSingleOrNull();
  }

  /// Lists all users, optionally filtered by active status.
  Future<List<UserAccount>> listUsers({bool? isActive}) {
    final query = select(usersTable);
    if (isActive != null) {
      query.where((tbl) => tbl.isActive.equals(isActive));
    }
    return query.get();
  }

  /// Reactive stream watching a user by ID.
  Stream<UserAccount?> watchUserById(String id) {
    return (select(
      usersTable,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Inserts a new user record into the local SQLite database.
  Future<int> insertUser(UsersTableCompanion user) {
    return into(usersTable).insert(user);
  }

  /// Updates an existing user record.
  Future<bool> updateUser(UsersTableCompanion user) {
    return update(usersTable).replace(user);
  }

  /// Hard-deletes a user record (as no deleted_at column exists in schema).
  Future<int> deleteUser(String id) {
    return (delete(usersTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==========================================
  // 2. ACCOUNTS OPERATIONS (Global / Tenant Root)
  // ==========================================

  /// Retrieves a business account by its unique ID.
  Future<BusinessAccount?> getAccountById(String id) {
    return (select(
      accountsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Lists accounts owned by a specific user.
  Future<List<BusinessAccount>> listAccountsByOwnerId(String ownerId) {
    return (select(
      accountsTable,
    )..where((tbl) => tbl.ownerId.equals(ownerId))).get();
  }

  /// Reactive stream watching a business account by ID.
  Stream<BusinessAccount?> watchAccountById(String id) {
    return (select(
      accountsTable,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  /// Reactive stream watching accounts owned by a specific user.
  Stream<List<BusinessAccount>> watchAccountsByOwnerId(String ownerId) {
    return (select(
      accountsTable,
    )..where((tbl) => tbl.ownerId.equals(ownerId))).watch();
  }

  /// Inserts a new account record.
  Future<int> insertAccount(AccountsTableCompanion account) {
    return into(accountsTable).insert(account);
  }

  /// Updates an existing account record.
  Future<bool> updateAccount(AccountsTableCompanion account) {
    return update(accountsTable).replace(account);
  }

  /// Hard-deletes an account record (as no deleted_at column exists in schema).
  Future<int> deleteAccount(String id) {
    return (delete(accountsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==========================================
  // 3. SUBSCRIPTIONS OPERATIONS (accountId Scoped)
  // ==========================================

  /// Retrieves a subscription by its unique ID.
  Future<SubscriptionData?> getSubscriptionById(String id) {
    return (select(
      subscriptionsTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Lists all subscriptions associated with a specific account ID.
  Future<List<SubscriptionData>> listSubscriptionsByAccountId(
    String accountId,
  ) {
    return (select(
      subscriptionsTable,
    )..where((tbl) => tbl.accountId.equals(accountId))).get();
  }

  /// Retrieves the active subscription for an account ID (status == 'active' or 'trial').
  Future<SubscriptionData?> getActiveSubscriptionByAccountId(String accountId) {
    return (select(subscriptionsTable)
          ..where(
            (tbl) =>
                tbl.accountId.equals(accountId) &
                (tbl.status.equals('active') | tbl.status.equals('trial')),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.endDate, mode: OrderingMode.desc),
          ]))
        .getSingleOrNull();
  }

  /// Reactive stream watching the active subscription for an account ID.
  Stream<SubscriptionData?> watchActiveSubscriptionByAccountId(
    String accountId,
  ) {
    return (select(subscriptionsTable)
          ..where(
            (tbl) =>
                tbl.accountId.equals(accountId) &
                (tbl.status.equals('active') | tbl.status.equals('trial')),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.endDate, mode: OrderingMode.desc),
          ]))
        .watchSingleOrNull();
  }

  /// Reactive stream watching all subscriptions of an account ID.
  Stream<List<SubscriptionData>> watchSubscriptionsByAccountId(
    String accountId,
  ) {
    return (select(
      subscriptionsTable,
    )..where((tbl) => tbl.accountId.equals(accountId))).watch();
  }

  /// Inserts a new subscription record.
  Future<int> insertSubscription(SubscriptionsTableCompanion subscription) {
    return into(subscriptionsTable).insert(subscription);
  }

  /// Updates an existing subscription record.
  Future<bool> updateSubscription(SubscriptionsTableCompanion subscription) {
    return update(subscriptionsTable).replace(subscription);
  }

  /// Hard-deletes a subscription record (as no deleted_at column exists in schema).
  Future<int> deleteSubscription(String id) {
    return (delete(subscriptionsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ==========================================
  // 4. TRANSACTIONAL PERSISTENCE
  // ==========================================

  /// Atomically creates an account along with its initial subscription setup.
  Future<void> createAccountWithSubscription(
    AccountsTableCompanion account,
    SubscriptionsTableCompanion subscription,
  ) {
    return transaction(() async {
      await into(accountsTable).insert(account);
      await into(subscriptionsTable).insert(subscription);
    });
  }
}
