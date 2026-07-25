import '../../../../kernel/storage/app_database.dart';

abstract class AuthRepository {
  Future<bool> login(String email, String password);
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  );
  Future<void> completeBusinessSetup(String businessName, String businessType);
  Future<bool> checkAuthStatus();
  Future<void> logout();

  // Users
  Future<UserAccount?> getUserById(String id);
  Future<UserAccount?> getUserByEmail(String email);
  Future<List<UserAccount>> listUsers({bool? isActive});
  Stream<UserAccount?> watchUserById(String id);
  Future<int> insertUser(UsersTableCompanion user);
  Future<bool> updateUser(UsersTableCompanion user);
  Future<int> deleteUser(String id);

  // Accounts
  Future<BusinessAccount?> getAccountById(String id);
  Future<List<BusinessAccount>> listAccountsByOwnerId(String ownerId);
  Stream<BusinessAccount?> watchAccountById(String id);
  Stream<List<BusinessAccount>> watchAccountsByOwnerId(String ownerId);
  Future<int> insertAccount(AccountsTableCompanion account);
  Future<bool> updateAccount(AccountsTableCompanion account);
  Future<int> deleteAccount(String id);

  // Subscriptions
  Future<SubscriptionData?> getSubscriptionById(String id);
  Future<List<SubscriptionData>> listSubscriptionsByAccountId(String accountId);
  Future<SubscriptionData?> getActiveSubscriptionByAccountId(String accountId);
  Stream<SubscriptionData?> watchActiveSubscriptionByAccountId(
    String accountId,
  );
  Stream<List<SubscriptionData>> watchSubscriptionsByAccountId(
    String accountId,
  );
  Future<int> insertSubscription(SubscriptionsTableCompanion subscription);
  Future<bool> updateSubscription(SubscriptionsTableCompanion subscription);
  Future<int> deleteSubscription(String id);

  // Transactional
  Future<void> createAccountWithSubscription(
    AccountsTableCompanion account,
    SubscriptionsTableCompanion subscription,
  );
}
