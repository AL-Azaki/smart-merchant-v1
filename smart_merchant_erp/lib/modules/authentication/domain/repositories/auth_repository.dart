abstract class AuthRepository {
  Future<bool> login(String email, String password);
  Future<void> register(String firstName, String lastName, String email, String password);
  Future<void> completeBusinessSetup(String businessName, String businessType);
  Future<bool> checkAuthStatus();
  Future<void> logout();
}
