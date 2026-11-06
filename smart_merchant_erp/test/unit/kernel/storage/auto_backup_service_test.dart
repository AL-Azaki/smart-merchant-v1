import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_merchant_erp/kernel/storage/auto_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AutoBackupService settings defaults and persistence test', () async {
    expect(await AutoBackupService.isEnabled(), false);
    expect(await AutoBackupService.getFrequency(), 'daily');
    expect(await AutoBackupService.getRetentionLimit(), 7);
    expect(await AutoBackupService.getLastRunTime(), isNull);

    await AutoBackupService.setEnabled(true);
    await AutoBackupService.setFrequency('weekly');
    await AutoBackupService.setRetentionLimit(14);

    expect(await AutoBackupService.isEnabled(), true);
    expect(await AutoBackupService.getFrequency(), 'weekly');
    expect(await AutoBackupService.getRetentionLimit(), 14);
  });
}
