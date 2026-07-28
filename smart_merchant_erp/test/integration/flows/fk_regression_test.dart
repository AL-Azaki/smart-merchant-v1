import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:smart_merchant_erp/app/di/injection.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';
import 'package:smart_merchant_erp/modules/sales/application/usecases/complete_sale_usecase.dart';
import 'package:smart_merchant_erp/kernel/error/failures.dart';

class TestApplicationContext implements ApplicationContext {
  final String businessId;
  final String? branchId;
  final String userId;

  TestApplicationContext({
    required this.businessId,
    required this.branchId,
    required this.userId,
  });

  @override
  String get currentBusinessId => businessId;
  @override
  String? get currentBranchId => branchId;
  @override
  String get currentUserId => userId;
}

void main() {
  late AppDatabase db;
  late QaDataSeeder seeder;

  setUp(() async {
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.allowReassignment = true;
    
    db = AppDatabase(connection: NativeDatabase.memory());
    configureDependencies();
    
    getIt.registerSingleton<AppDatabase>(db);
    seeder = QaDataSeeder(db);
    // Seed real data for the happy path
    await seeder.seedAll(
      businessId: 'test-biz',
      branchId: 'test-branch',
      userId: 'test-user',
      accountId: 'test-acc',
    );
  });

  tearDown(() async {
    await db.close();
    await GetIt.instance.reset();
  });

  test('CompleteSaleUseCase fails with ValidationFailure if session user is missing locally', () async {
    final getIt = GetIt.instance;
    
    // Create an ApplicationContext with a non-existent user ID
    getIt.registerSingleton<ApplicationContext>(TestApplicationContext(
      businessId: 'test-biz',
      branchId: 'test-branch',
      userId: 'non-existent-user',
    ));
    
    final useCase = getIt<CompleteSaleUseCase>();
    
    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER-id',
      isCreditSale: false,
      items: [
        CompleteSaleItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 1.0,
          unitPrice: 150.0,
          warehouseId: 'wh-qa-main',
        )
      ],
    );

    final result = await useCase(request);
    
    expect(result.isLeft(), true);
    result.fold(
      (failure) {
        expect(failure is ValidationFailure, true);
        expect(failure.message.contains('المستخدم غير موجود محلياً'), true);
      },
      (r) => fail('Should have failed'),
    );
  });

  test('CompleteSaleUseCase succeeds and PRAGMA foreign_key_check is zero when context is valid', () async {
    final getIt = GetIt.instance;
    
    // Valid Context
    getIt.registerSingleton<ApplicationContext>(TestApplicationContext(
      businessId: 'test-biz',
      branchId: 'test-branch',
      userId: 'test-user',
    ));
    
    final useCase = getIt<CompleteSaleUseCase>();
    
    final request = CompleteSaleCommand(
      customerId: 'cust-qa-01',
      currencyId: 'YER-id',
      isCreditSale: false,
      items: [
        CompleteSaleItemCommand(
          productUnitId: 'pu-prod-qa-01',
          quantity: 1.0,
          unitPrice: 150.0,
          warehouseId: 'wh-qa-main',
        )
      ],
    );

    final result = await useCase(request);
    expect(result.isRight(), true);
    
    // Check foreign keys
    final fkCheck = await db.customSelect('PRAGMA foreign_key_check').get();
    expect(fkCheck.isEmpty, true, reason: 'Foreign key check must return 0 violations');
  });
}
