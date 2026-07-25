
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/sales/application/services/customer_application_service.dart';
import 'package:smart_merchant_erp/database/daos/sales_dao.dart';
import 'package:smart_merchant_erp/modules/sales/domain/repositories/sales_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/sales/infrastructure/repositories/sales_repository_impl.dart';

void main() {
  late AppDatabase db;
  late SalesRepository salesRepository;
  late ApplicationContext context;
  late String businessId;
  late CustomerApplicationService service;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    salesRepository = SalesRepositoryImpl(SalesDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    service = CustomerApplicationService(
      salesRepository,
      context,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('CustomerApplicationService - Create Customer', () async {
    final command = CustomerCommand(
      name: 'Test Customer',
      phone: '1234567890',
    );

    final result = await service.saveCustomer(command);
    expect(result.isRight(), isTrue);

    final customers = await db.select(db.customers).get();
    expect(customers.length, 1);
    expect(customers.first.customerName, 'Test Customer');
  });

  test('CustomerApplicationService - Update Customer', () async {
    final id = const Uuid().v4();
    final command = CustomerCommand(
      id: id,
      name: 'Updated Customer',
      phone: '0987654321',
    );

    // Insert manually first
    await salesRepository.insertCustomer(CustomersCompanion.insert(
        id: id,
        businessId: businessId,
        customerName: 'Old Customer',
    ));

    final result = await service.saveCustomer(command);
    expect(result.isRight(), isTrue);

    final customers = await db.select(db.customers).get();
    expect(customers.length, 1);
    expect(customers.first.customerName, 'Updated Customer');
  });

  test('CustomerApplicationService - Soft Delete Customer', () async {
    final id = const Uuid().v4();
    await salesRepository.insertCustomer(CustomersCompanion.insert(
        id: id,
        businessId: businessId,
        customerName: 'Test Customer',
    ));

    final result = await service.deleteCustomer(id);
    expect(result.isRight(), isTrue);

    final customers = await db.select(db.customers).get();
    expect(customers.length, 1);
    expect(customers.first.isActive, isFalse);
  });
}
