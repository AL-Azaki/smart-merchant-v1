import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_contract.dart';

/// Production implementation using [FlutterSecureStorage].
/// Registered as a lazy singleton via GetIt.
class FlutterSecureStorageImpl implements SecureStorageContract {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageImpl({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();

  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}
