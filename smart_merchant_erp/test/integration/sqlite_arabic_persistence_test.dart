import 'package:drift/drift.dart' hide equals, isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(connection: NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Arabic text persists perfectly in SQLite', () async {
    const arabicName = 'بشير العزكي';
    
    // We need to insert a customer. But we might need a business/branch first 
    // due to foreign keys. Let's disable foreign keys for this isolated test or insert dependencies.
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    final customerId = const Uuid().v4();
    
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        id: customerId,
        businessId: 'test-business',
        customerName: arabicName,
        phone: const Value('123456789'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final fetchedCustomer = await (db.select(db.customers)
          ..where((t) => t.id.equals(customerId)))
        .getSingle();

    expect(fetchedCustomer.customerName, equals(arabicName));
  });

  test('English text persists perfectly in SQLite', () async {
    const englishName = 'Bashir Al-Azaki';
    
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    final customerId = const Uuid().v4();
    
    await db.into(db.customers).insert(
      CustomersCompanion.insert(
        id: customerId,
        businessId: 'test-business',
        customerName: englishName,
        phone: const Value('123456789'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final fetchedCustomer = await (db.select(db.customers)
          ..where((t) => t.id.equals(customerId)))
        .getSingle();

    expect(fetchedCustomer.customerName, equals(englishName));
  });
}
