import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/hr/application/services/employee_application_service.dart';
import 'package:smart_merchant_erp/database/daos/hr_dao.dart';
import 'package:smart_merchant_erp/modules/hr/domain/repositories/hr_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/hr/infrastructure/repositories/hr_repository_impl.dart';

void main() {
  late AppDatabase db;
  late HrRepository repository;
  late ApplicationContext context;
  late String businessId;
  late EmployeeApplicationService service;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    repository = HrRepositoryImpl(HrDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    service = EmployeeApplicationService(
      repository,
      context,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('EmployeeApplicationService - Create Employee', () async {
    final command = EmployeeCommand(
      employeeCode: 'EMP01',
      name: 'Test Employee',
      phone: '1234567890',
    );

    final result = await service.saveEmployee(command);
    expect(result.isRight(), isTrue);

    final employees = await db.select(db.employees).get();
    expect(employees.length, 1);
    expect(employees.first.firstName, 'Test Employee');
  });

  test('EmployeeApplicationService - Update Employee', () async {
    final id = const Uuid().v4();
    final command = EmployeeCommand(
      id: id,
      employeeCode: 'EMP01',
      name: 'Updated Employee',
      phone: '0987654321',
    );

    await repository.insertEmployee(EmployeesCompanion.insert(
        id: id,
        businessId: businessId,
        firstName: 'Old',
        lastName: 'Employee',
        employeeCode: 'EMP01',
        syncStatus: const drift.Value('pending'),
        currencyId: 'USD',
        hireDate: DateTime.now(),
    ));

    final result = await service.saveEmployee(command);
    expect(result.isRight(), isTrue);

    final employees = await db.select(db.employees).get();
    expect(employees.length, 1);
    expect(employees.first.firstName, 'Updated Employee');
  });

  test('EmployeeApplicationService - Soft Delete Employee', () async {
    final id = const Uuid().v4();
    await repository.insertEmployee(EmployeesCompanion.insert(
        id: id,
        businessId: businessId,
        firstName: 'Test',
        lastName: 'Employee',
        employeeCode: 'EMP01',
        syncStatus: const drift.Value('pending'),
        currencyId: 'USD',
        hireDate: DateTime.now(),
    ));

    final result = await service.deleteEmployee(id);
    expect(result.isRight(), isTrue);

    final employees = await db.select(db.employees).get();
    expect(employees.length, 1);
    expect(employees.first.deletedAt, isNotNull);
  });
}
