import '../../domain/repositories/auth_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/auth_dao.dart';
import '../data_sources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthDao _authDao;
  AuthRepositoryImpl(dynamic source)
    : _localDataSource = source is AuthLocalDataSource
          ? source
          : (source is AppDatabase
                ? AuthLocalDataSourceImpl(source)
                : (source is AuthDao
                      ? AuthLocalDataSourceImpl(source.attachedDatabase)
                      : throw ArgumentError(
                          'Expected AuthLocalDataSource, AppDatabase or AuthDao',
                        ))),
      _authDao = source is AuthLocalDataSource
          ? source.authDao
          : (source is AppDatabase
                ? AuthDao(source)
                : (source is AuthDao
                      ? source
                      : throw ArgumentError('Expected valid data source')));


  factory AuthRepositoryImpl.injectable(AuthLocalDataSource local) =>
      AuthRepositoryImpl(local);

  @override
  Future<bool> login(String email, String password) async {
    return RepositoryErrorGuard.run(
      () => _localDataSource.login(email, password),
    );
  }

  @override
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    return RepositoryErrorGuard.run(
      () => _localDataSource.register(firstName, lastName, email, password),
    );
  }

  @override
  Future<void> completeBusinessSetup(
    String businessName,
    String businessType,
  ) async {
    return RepositoryErrorGuard.run(
      () => _localDataSource.completeBusinessSetup(businessName, businessType),
    );
  }

  @override
  Future<bool> checkAuthStatus() async {
    return RepositoryErrorGuard.run(() => _localDataSource.checkAuthStatus());
  }

  @override
  Future<void> logout() async {
    return RepositoryErrorGuard.run(() => _localDataSource.logout());
  }

  // Users
  @override
  Future<UserAccount?> getUserById(String id) {
    return RepositoryErrorGuard.run(() => _authDao.getUserById(id));
  }

  @override
  Future<UserAccount?> getUserByEmail(String email) {
    return RepositoryErrorGuard.run(() => _authDao.getUserByEmail(email));
  }

  @override
  Future<List<UserAccount>> listUsers({bool? isActive}) {
    return RepositoryErrorGuard.run(
      () => _authDao.listUsers(isActive: isActive),
    );
  }

  @override
  Stream<UserAccount?> watchUserById(String id) {
    return RepositoryErrorGuard.guardStream(_authDao.watchUserById(id));
  }

  @override
  Future<int> insertUser(UsersTableCompanion user) {
    return RepositoryErrorGuard.run(() => _authDao.insertUser(user));
  }

  @override
  Future<bool> updateUser(UsersTableCompanion user) {
    return RepositoryErrorGuard.run(() => _authDao.updateUser(user));
  }

  @override
  Future<int> deleteUser(String id) {
    return RepositoryErrorGuard.run(() => _authDao.deleteUser(id));
  }

  // Accounts
  @override
  Future<BusinessAccount?> getAccountById(String id) {
    return RepositoryErrorGuard.run(() => _authDao.getAccountById(id));
  }

  @override
  Future<List<BusinessAccount>> listAccountsByOwnerId(String ownerId) {
    return RepositoryErrorGuard.run(
      () => _authDao.listAccountsByOwnerId(ownerId),
    );
  }

  @override
  Stream<BusinessAccount?> watchAccountById(String id) {
    return RepositoryErrorGuard.guardStream(_authDao.watchAccountById(id));
  }

  @override
  Stream<List<BusinessAccount>> watchAccountsByOwnerId(String ownerId) {
    return RepositoryErrorGuard.guardStream(
      _authDao.watchAccountsByOwnerId(ownerId),
    );
  }

  @override
  Future<int> insertAccount(AccountsTableCompanion account) {
    return RepositoryErrorGuard.run(() => _authDao.insertAccount(account));
  }

  @override
  Future<bool> updateAccount(AccountsTableCompanion account) {
    return RepositoryErrorGuard.run(() => _authDao.updateAccount(account));
  }

  @override
  Future<int> deleteAccount(String id) {
    return RepositoryErrorGuard.run(() => _authDao.deleteAccount(id));
  }

  // Subscriptions
  @override
  Future<SubscriptionData?> getSubscriptionById(String id) {
    return RepositoryErrorGuard.run(() => _authDao.getSubscriptionById(id));
  }

  @override
  Future<List<SubscriptionData>> listSubscriptionsByAccountId(
    String accountId,
  ) {
    return RepositoryErrorGuard.run(
      () => _authDao.listSubscriptionsByAccountId(accountId),
    );
  }

  @override
  Future<SubscriptionData?> getActiveSubscriptionByAccountId(String accountId) {
    return RepositoryErrorGuard.run(
      () => _authDao.getActiveSubscriptionByAccountId(accountId),
    );
  }

  @override
  Stream<SubscriptionData?> watchActiveSubscriptionByAccountId(
    String accountId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _authDao.watchActiveSubscriptionByAccountId(accountId),
    );
  }

  @override
  Stream<List<SubscriptionData>> watchSubscriptionsByAccountId(
    String accountId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _authDao.watchSubscriptionsByAccountId(accountId),
    );
  }

  @override
  Future<int> insertSubscription(SubscriptionsTableCompanion subscription) {
    return RepositoryErrorGuard.run(
      () => _authDao.insertSubscription(subscription),
    );
  }

  @override
  Future<bool> updateSubscription(SubscriptionsTableCompanion subscription) {
    return RepositoryErrorGuard.run(
      () => _authDao.updateSubscription(subscription),
    );
  }

  @override
  Future<int> deleteSubscription(String id) {
    return RepositoryErrorGuard.run(() => _authDao.deleteSubscription(id));
  }

  // Transactional
  @override
  Future<void> createAccountWithSubscription(
    AccountsTableCompanion account,
    SubscriptionsTableCompanion subscription,
  ) {
    return RepositoryErrorGuard.run(
      () => _authDao.createAccountWithSubscription(account, subscription),
    );
  }
}
