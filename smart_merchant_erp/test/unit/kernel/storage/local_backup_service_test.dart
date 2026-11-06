import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/local_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalBackupService file metadata structure and container magic test', () {
    final meta = BackupMetadata(
      appName: 'Smart Merchant ERP',
      schemaVersion: 7,
      createdAt: DateTime(2026, 11, 6),
      platform: 'windows',
      originalSizeBytes: 1024,
      notes: 'Test backup note',
    );

    final json = meta.toJson();
    expect(json['appName'], 'Smart Merchant ERP');
    expect(json['schemaVersion'], 7);
    expect(json['notes'], 'Test backup note');

    final decoded = BackupMetadata.fromJson(json);
    expect(decoded.appName, meta.appName);
    expect(decoded.schemaVersion, 7);
    expect(decoded.notes, meta.notes);
  });
}