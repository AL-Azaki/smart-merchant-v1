import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/database/daos/fixed_assets_dao.dart';
import 'package:smart_merchant_erp/database/seeders/qa_data_seeder.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/modules/fixed_assets/application/services/fixed_asset_application_service.dart';
import 'package:smart_merchant_erp/modules/fixed_assets/infrastructure/repositories/fixed_assets_repository_impl.dart';

void main() {
  late AppDatabase db;
  late QaDataSeeder seeder;
  late FixedAssetApplicationService service;
  late FixedAssetsDao dao;
  late FixedAssetsRepositoryImpl repo;
  late SessionHolder sessionHolder;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    seeder = QaDataSeeder(db);
    dao = FixedAssetsDao(db);
    repo = FixedAssetsRepositoryImpl(dao);
    
    await seeder.seedAll();

    sessionHolder = SessionHolder();
    sessionHolder.setSession(
      businessId: 'qa-business-id',
      branchId: 'qa-branch-id',
      userId: 'qa-user-id',
    );
    
    final context = RuntimeApplicationContext(sessionHolder);
    
    service = FixedAssetApplicationService(
      repo,
      context,
    );
  });

  tearDown(() async {
    sessionHolder.clearSession();
    await db.close();
  });

  test('CREATE FIXED ASSET - surgical integration test', () async {
    final command = FixedAssetCommand(
      assetCode: 'FA-1001',
      assetName: 'Test Machine',
      purchasePrice: 15000,
      currentBookValue: 15000,
      purchaseDate: DateTime(2026, 1, 1),
      usefulLifeMonths: 12,
      assetCategoryId: 'أجهزة إلكترونية', // Should map to null internally per our fix
    );

    final result = await service.saveFixedAsset(command);
    
    expect(result.isRight(), isTrue);
    final assetId = result.getOrElse(() => '');
    expect(assetId, isNotEmpty);

    final assets = await dao.watchFixedAssets(FixedAssetFilter(businessId: 'qa-business-id', searchQuery: '')).first;
    expect(assets.length, equals(1));
    expect(assets.first.assetName, equals('Test Machine'));
    expect(assets.first.assetCode, equals('FA-1001'));
    expect(assets.first.currencyId, equals('YER'));
    expect(assets.first.assetCategoryId, isNull);
  });
}
