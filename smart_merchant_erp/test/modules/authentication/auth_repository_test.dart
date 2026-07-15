import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/authentication/infrastructure/repositories/auth_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AuthRepositoryImpl authRepository;

  setUp(() {
    // استخدم قاعدة بيانات في الذاكرة (In-Memory) للاختبارات (Unit Test)
    db = AppDatabase(connection: NativeDatabase.memory());
    authRepository = AuthRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AuthRepository Unit Tests', () {
    test('Dummy credentials should allow login', () async {
      // Act
      final result = await authRepository.login('admin@smartmerchant.com', 'admin123');
      
      // Assert
      expect(result, isTrue, reason: 'Dummy credentials must always allow login during development.');
    });

    test('Registering a user should save them to the local database', () async {
      // Act
      await authRepository.register('Ahmed', 'Ali', 'ahmed@test.com', 'pass123');
      
      // Verify
      final users = await db.select(db.usersTable).get();
      expect(users.length, 1);
      expect(users.first.email, 'ahmed@test.com');
    });

    test('Login with correct registered credentials should succeed', () async {
      // Arrange
      await authRepository.register('Ahmed', 'Ali', 'ahmed@test.com', 'pass123');
      
      // Act
      final success = await authRepository.login('ahmed@test.com', 'pass123');
      final fail = await authRepository.login('ahmed@test.com', 'wrongpass');
      
      // Assert
      expect(success, isTrue);
      expect(fail, isFalse);
    });

    test('Completing business setup should create an account linked to the user', () async {
      // Arrange
      await authRepository.register('Ahmed', 'Ali', 'ahmed@test.com', 'pass123');
      
      // Act
      await authRepository.completeBusinessSetup('Ahmed Store', 'Retail');
      
      // Verify
      final accounts = await db.select(db.accountsTable).get();
      final users = await db.select(db.usersTable).get();
      
      expect(accounts.length, 1);
      expect(accounts.first.businessName, 'Ahmed Store');
      expect(accounts.first.ownerId, users.first.id); // Linked properly
    });
  });
}
