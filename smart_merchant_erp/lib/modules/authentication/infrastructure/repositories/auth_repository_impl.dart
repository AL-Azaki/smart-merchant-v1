import 'package:drift/drift.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../kernel/storage/app_database.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  
  AuthRepositoryImpl(this._db);

  @override
  Future<bool> login(String email, String password) async {
    // 1. In a real system, you'd hash the password and compare.
    // 2. Here we verify against local DB or dummy credentials
    if (email == 'admin@smartmerchant.com' && password == 'admin123') {
      return true;
    }

    final query = _db.select(_db.usersTable)..where((u) => u.email.equals(email));
    final user = await query.getSingleOrNull();
    
    if (user != null && user.passwordHash == password) { // Dummy plain text comparison for offline dev
      return true;
    }
    return false;
  }

  @override
  Future<void> register(String firstName, String lastName, String email, String password) async {
    await _db.into(_db.usersTable).insert(
      UsersTableCompanion.insert(
        email: email,
        passwordHash: password, // Raw for now, hash in production
        firstName: firstName,
        lastName: lastName,
      )
    );
  }

  @override
  Future<void> completeBusinessSetup(String businessName, String businessType) async {
    // Usually links to the currently registered user
    final users = await _db.select(_db.usersTable).get();
    if (users.isEmpty) return;

    final userId = users.last.id;
    
    await _db.into(_db.accountsTable).insert(
      AccountsTableCompanion.insert(
        ownerId: userId,
        businessName: businessName,
        businessType: businessType,
        defaultCurrency: 'YER',
      )
    );
  }

  @override
  Future<bool> checkAuthStatus() async {
    // Check if there's an active token or local session
    return false;
  }

  @override
  Future<void> logout() async {
    // Clear session
  }
}
