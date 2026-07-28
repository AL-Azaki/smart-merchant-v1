import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('QA Foundation Integrity Test', () async {
    final seeder = QaDataSeeder(db);
    await seeder.seedAll();

    // Verify all seeded data
    final business = await (db.select(db.businesses)..where((t) => t.id.equals('qa-business-id'))).getSingleOrNull();
    expect(business, isNotNull);

    final branch = await (db.select(db.branches)..where((t) => t.id.equals('qa-branch-id'))).getSingleOrNull();
    expect(branch, isNotNull);
    expect(branch!.businessId, 'qa-business-id');

    final user = await (db.select(db.usersTable)..where((t) => t.id.equals('qa-user-id'))).getSingleOrNull();
    expect(user, isNotNull);

    final currency = await (db.select(db.currencies)..where((t) => t.id.equals('YER'))).getSingleOrNull();
    expect(currency, isNotNull);

    final warehouse = await (db.select(db.warehouses)..where((t) => t.id.equals('wh-qa-main'))).getSingleOrNull();
    expect(warehouse, isNotNull);
    expect(warehouse!.businessId, 'qa-business-id');
    expect(warehouse.branchId, 'qa-branch-id');

    final supplier = await (db.select(db.suppliers)..where((t) => t.id.equals('supplier-qa-01'))).getSingleOrNull();
    expect(supplier, isNotNull);
    expect(supplier!.businessId, 'qa-business-id');

    // Test SQLite Foreign Key Check (Pragma)
    final result = await db.customSelect('PRAGMA foreign_key_check;').get();
    expect(result, isEmpty, reason: 'PRAGMA foreign_key_check failed! There are FK violations in the QA Seed.');
  });
}
