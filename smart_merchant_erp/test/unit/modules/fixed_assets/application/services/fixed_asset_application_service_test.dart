import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_merchant_erp/kernel/storage/app_database.dart';
import 'package:smart_merchant_erp/kernel/core/application_context.dart';
import 'package:smart_merchant_erp/modules/fixed_assets/application/services/fixed_asset_application_service.dart';
import 'package:smart_merchant_erp/database/daos/fixed_assets_dao.dart';
import 'package:smart_merchant_erp/modules/fixed_assets/domain/repositories/fixed_assets_repository.dart';
import 'package:drift/native.dart';
import 'package:smart_merchant_erp/modules/fixed_assets/infrastructure/repositories/fixed_assets_repository_impl.dart';

void main() {
  late AppDatabase db;
  late FixedAssetsRepository repository;
  late ApplicationContext context;
  late String businessId;
  late FixedAssetApplicationService service;

  setUp(() async {
    db = AppDatabase(connection: NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    repository = FixedAssetsRepositoryImpl(FixedAssetsDao(db));

    businessId = const Uuid().v4();
    final branchId = const Uuid().v4();
    final userId = const Uuid().v4();

    context = StaticApplicationContext(
      businessId: businessId,
      branchId: branchId,
      userId: userId,
    );

    service = FixedAssetApplicationService(
      repository,
      context,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('FixedAssetApplicationService - Create Fixed Asset', () async {
    final command = FixedAssetCommand(
      assetCode: 'FA-01',
      assetName: 'Test Asset',
      purchasePrice: 1000.0,
      currentBookValue: 1000.0,
      purchaseDate: DateTime.now(),
      usefulLifeMonths: 60,
    );

    final result = await service.saveFixedAsset(command);
    expect(result.isRight(), isTrue);

    final assets = await db.select(db.fixedAssets).get();
    expect(assets.length, 1);
    expect(assets.first.assetName, 'Test Asset');
  });

  test('FixedAssetApplicationService - Update Fixed Asset', () async {
    final id = const Uuid().v4();
    final command = FixedAssetCommand(
      id: id,
      assetCode: 'FA-01',
      assetName: 'Updated Asset',
      purchasePrice: 1200.0,
      currentBookValue: 1200.0,
      purchaseDate: DateTime.now(),
      usefulLifeMonths: 60,
    );

    await repository.insertFixedAsset(FixedAssetsCompanion.insert(
        id: id,
        businessId: businessId,
        branchId: drift.Value(context.currentBranchId!),
        assetCode: 'FA-01',
        assetName: 'Old Asset',
        acquisitionDate: DateTime.now(),
        acquisitionCost: 1000.0,
        baseAcquisitionCost: 1000.0,
        usefulLife: 60,
        depreciationMethod: 'straight_line',
        depreciationStartDate: DateTime.now(),
        currencyId: 'USD',
        createdBy: context.currentUserId!,
        syncStatus: const drift.Value('pending'),
    ));

    final result = await service.saveFixedAsset(command);
    expect(result.isRight(), isTrue);

    final assets = await db.select(db.fixedAssets).get();
    expect(assets.length, 1);
    expect(assets.first.assetName, 'Updated Asset');
  });
}
