
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/purchasing/application/services/supplier_application_service.dart';
import 'package:smart_merchant_erp/database/daos/purchasing_dao.dart';
import 'package:smart_merchant_erp/modules/purchasing/domain/repositories/purchasing_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/purchasing/infrastructure/repositories/purchasing_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PurchasingRepository repository;
  late ApplicationContext context;
  late String businessId;
  late SupplierApplicationService service;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    repository = PurchasingRepositoryImpl(PurchasingDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    service = SupplierApplicationService(
      repository,
      context,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('SupplierApplicationService - Create Supplier', () async {
    final command = SupplierCommand(
      name: 'Test Supplier',
      phone: '1234567890',
    );

    final result = await service.saveSupplier(command);
    expect(result.isRight(), isTrue);

    final suppliers = await db.select(db.suppliers).get();
    expect(suppliers.length, 1);
    expect(suppliers.first.supplierName, 'Test Supplier');
  });

  test('SupplierApplicationService - Update Supplier', () async {
    final id = const Uuid().v4();
    final command = SupplierCommand(
      id: id,
      name: 'Updated Supplier',
      phone: '0987654321',
    );

    await repository.insertSupplier(SuppliersCompanion.insert(
        id: id,
        businessId: businessId,
        supplierName: 'Old Supplier',
    ));

    final result = await service.saveSupplier(command);
    expect(result.isRight(), isTrue);

    final suppliers = await db.select(db.suppliers).get();
    expect(suppliers.length, 1);
    expect(suppliers.first.supplierName, 'Updated Supplier');
  });

  test('SupplierApplicationService - Soft Delete Supplier', () async {
    final id = const Uuid().v4();
    await repository.insertSupplier(SuppliersCompanion.insert(
        id: id,
        businessId: businessId,
        supplierName: 'Test Supplier',
    ));

    final result = await service.deleteSupplier(id);
    expect(result.isRight(), isTrue);

    final suppliers = await db.select(db.suppliers).get();
    expect(suppliers.length, 1);
    expect(suppliers.first.isActive, isFalse);
  });
}
