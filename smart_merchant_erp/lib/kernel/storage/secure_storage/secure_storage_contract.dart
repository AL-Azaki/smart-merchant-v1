/// Testable abstraction over platform-specific secure storage.
/// Production uses [FlutterSecureStorage]; tests inject a simple in-memory map.
abstract class SecureStorageContract {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}
