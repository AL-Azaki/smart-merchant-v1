import 'package:injectable/injectable.dart';
import '../../domain/repositories/fixed_assets_repository.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../../../kernel/error/repository_exceptions.dart';
import '../../../../database/daos/fixed_assets_dao.dart';

@LazySingleton(as: FixedAssetsRepository)
class FixedAssetsRepositoryImpl implements FixedAssetsRepository {
  final FixedAssetsDao _dao;

  FixedAssetsRepositoryImpl(this._dao);

  // Fixed Assets
  @override
  Future<FixedAsset?> getFixedAssetById(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getFixedAssetById(id, businessId),
    );
  }

  @override
  Future<FixedAsset?> getFixedAssetByCode(String assetCode, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.getFixedAssetByCode(assetCode, businessId),
    );
  }

  @override
  Future<FixedAssetWithDetails?> getFixedAssetWithDetails(
    String id,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.getFixedAssetWithDetails(id, businessId),
    );
  }

  @override
  Future<List<FixedAsset>> listFixedAssets(FixedAssetFilter filter) {
    return RepositoryErrorGuard.run(() => _dao.listFixedAssets(filter));
  }

  @override
  Stream<FixedAsset?> watchFixedAssetById(String id, String businessId) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchFixedAssetById(id, businessId),
    );
  }

  @override
  Stream<List<FixedAsset>> watchFixedAssets(FixedAssetFilter filter) {
    return RepositoryErrorGuard.guardStream(_dao.watchFixedAssets(filter));
  }

  @override
  Future<int> insertFixedAsset(FixedAssetsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.insertFixedAsset(companion));
  }

  @override
  Future<bool> updateFixedAsset(FixedAssetsCompanion companion) {
    return RepositoryErrorGuard.run(() => _dao.updateFixedAsset(companion));
  }

  @override
  Future<bool> updateFixedAssetStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateFixedAssetStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<void> insertFixedAssetWithSchedules(
    FixedAssetsCompanion asset,
    List<DepreciationSchedulesCompanion> schedules,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.insertFixedAssetWithSchedules(asset, schedules),
    );
  }

  @override
  Future<List<FixedAsset>> getPendingSyncFixedAssets(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncFixedAssets(businessId, limit: limit),
    );
  }

  @override
  Future<void> markFixedAssetAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markFixedAssetAsSynced(id, businessId),
    );
  }

  // Depreciation Schedules
  @override
  Future<DepreciationSchedule?> getScheduleById(String id, String businessId) {
    return RepositoryErrorGuard.run(() => _dao.getScheduleById(id, businessId));
  }

  @override
  Future<List<DepreciationSchedule>> listSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.listSchedulesByAssetId(fixedAssetId, businessId),
    );
  }

  @override
  Future<List<DepreciationSchedule>> listSchedules(
    DepreciationScheduleFilter filter,
  ) {
    return RepositoryErrorGuard.run(() => _dao.listSchedules(filter));
  }

  @override
  Stream<List<DepreciationSchedule>> watchSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  ) {
    return RepositoryErrorGuard.guardStream(
      _dao.watchSchedulesByAssetId(fixedAssetId, businessId),
    );
  }

  @override
  Future<int> insertDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.insertDepreciationSchedule(companion),
    );
  }

  @override
  Future<void> insertScheduleBatch(
    List<DepreciationSchedulesCompanion> schedules,
  ) {
    return RepositoryErrorGuard.run(() => _dao.insertScheduleBatch(schedules));
  }

  @override
  Future<bool> updateDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateDepreciationSchedule(companion),
    );
  }

  @override
  Future<bool> updateScheduleStatus(
    String id,
    String businessId,
    String newStatus,
  ) {
    return RepositoryErrorGuard.run(
      () => _dao.updateScheduleStatus(id, businessId, newStatus),
    );
  }

  @override
  Future<List<DepreciationSchedule>> getPendingSyncSchedules(
    String businessId, {
    int limit = 500,
  }) {
    return RepositoryErrorGuard.run(
      () => _dao.getPendingSyncSchedules(businessId, limit: limit),
    );
  }

  @override
  Future<void> markScheduleAsSynced(String id, String businessId) {
    return RepositoryErrorGuard.run(
      () => _dao.markScheduleAsSynced(id, businessId),
    );
  }
}
