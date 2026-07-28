import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/app/di/injection.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';

class TestApplicationContext implements ApplicationContext {
  @override
  String get currentBusinessId => 'test-biz';
  @override
  String? get currentBranchId => 'test-branch';
  @override
  String get currentUserId => 'test-user';
}

void main() {
  late AppDatabase db;
  late CompleteSaleUseCase useCase;

  setUpAll(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.allowReassignment = true;
    
    db = AppDatabase(connection: NativeDatabase.memory());
    
    configureDependencies();
    
    getIt.registerSingleton<AppDatabase>(db);
    getIt.registerSingleton<ApplicationContext>(TestApplicationContext());

    final seeder = QaDataSeeder(db);
    await seeder.seedAll(
      businessId: 'test-biz',
      branchId: 'test-branch',
      userId: 'test-user',
      accountId: 'test-acc',
    );

    useCase = getIt<CompleteSaleUseCase>();
  });

  tearDownAll(() async {
    await db.close();
    await GetIt.instance.reset();
  });

  test('test_sale_deducts_inventory_exactly_once', () async {
    final initialInv = await (db.select(db.inventories)..where((t) => t.productUnitId.equals('pu-prod-qa-01'))).getSingle();
    expect(initialInv.quantity, 100.0);

    final items = [
      CompleteSaleItemCommand(
        productUnitId: 'pu-prod-qa-01',
        quantity: 2.0,
        unitPrice: 150.0,
        warehouseId: 'wh-qa-main',
        tax: 0.0,
        discount: 0.0,
      )
    ];

    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER-id',
      isCreditSale: false,
      items: items,
    );

    final result = await useCase(request);
    expect(result.isRight(), true);

    final finalInv = await (db.select(db.inventories)..where((t) => t.productUnitId.equals('pu-prod-qa-01'))).getSingle();
    expect(finalInv.quantity, 98.0, reason: 'Inventory must be deducted exactly once (100 - 2 = 98)');

    final lines = await (db.select(db.inventoryTransactionLines)..where((t) => t.productUnitId.equals('pu-prod-qa-01'))).get();
    expect(lines.length, 2);
  });
}
