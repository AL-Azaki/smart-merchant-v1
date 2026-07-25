import 'package:injectable/injectable.dart';
import '../../../../kernel/core/data_sources.dart';
import '../../../../kernel/error/exceptions.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/auth_dao.dart';

/// Contract for local authentication data operations.
/// Isolates concrete SQLite / Drift database interactions from the Repository layer.
abstract class AuthLocalDataSource implements LocalDataSource {
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

  AuthDao get authDao;
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AppDatabase _db;
  late final AuthDao _authDao;

  AuthLocalDataSourceImpl(this._db) : _authDao = AuthDao(_db);

  @override
  AuthDao get authDao => _authDao;

  @override
  Future<bool> login(String email, String password) async {
    try {
      final user = await _authDao.getUserByEmail(email);

      if (user != null && user.passwordHash == password) {
        return true;
      }
      return false;
    } catch (e) {
      throw LocalDatabaseException(e.toString());
    }
  }

  @override
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      await _authDao.insertUser(
        UsersTableCompanion.insert(
          email: email,
          passwordHash: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );
    } catch (e) {
      throw LocalDatabaseException(e.toString());
    }
  }

  @override
  Future<void> completeBusinessSetup(
    String businessName,
    String businessType,
  ) async {
    try {
      final users = await _authDao.listUsers();
      if (users.isEmpty) {
        return;
      }

      final userId = users.last.id;

      await _authDao.insertAccount(
        AccountsTableCompanion.insert(
          ownerId: userId,
          businessName: businessName,
          businessType: businessType,
          defaultCurrency: 'YER',
        ),
      );
    } catch (e) {
      throw LocalDatabaseException(e.toString());
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    return false;
  }

  @override
  Future<void> logout() async {
    // Local session clearing
  }
}
