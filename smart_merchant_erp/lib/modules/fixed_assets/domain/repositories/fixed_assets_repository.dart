import '../../../../kernel/storage/app_database.dart';
import '../../../../database/daos/fixed_assets_dao.dart';

/// Contract for Fixed Assets domain data operations.
abstract class FixedAssetsRepository {
  // Fixed Assets
  Future<FixedAsset?> getFixedAssetById(String id, String businessId);
  Future<FixedAsset?> getFixedAssetByCode(String assetCode, String businessId);
  Future<FixedAssetWithDetails?> getFixedAssetWithDetails(
    String id,
    String businessId,
  );
  Future<List<FixedAsset>> listFixedAssets(FixedAssetFilter filter);
  Stream<FixedAsset?> watchFixedAssetById(String id, String businessId);
  Stream<List<FixedAsset>> watchFixedAssets(FixedAssetFilter filter);
  Future<int> insertFixedAsset(FixedAssetsCompanion companion);
  Future<bool> updateFixedAsset(FixedAssetsCompanion companion);
  Future<bool> updateFixedAssetStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<void> insertFixedAssetWithSchedules(
    FixedAssetsCompanion asset,
    List<DepreciationSchedulesCompanion> schedules,
  );
  Future<List<FixedAsset>> getPendingSyncFixedAssets(
    String businessId, {
    int limit = 500,
  });
  Future<void> markFixedAssetAsSynced(String id, String businessId);

  // Depreciation Schedules
  Future<DepreciationSchedule?> getScheduleById(String id, String businessId);
  Future<List<DepreciationSchedule>> listSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  );
  Future<List<DepreciationSchedule>> listSchedules(
    DepreciationScheduleFilter filter,
  );
  Stream<List<DepreciationSchedule>> watchSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  );
  Future<int> insertDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  );
  Future<void> insertScheduleBatch(
    List<DepreciationSchedulesCompanion> schedules,
  );
  Future<bool> updateDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  );
  Future<bool> updateScheduleStatus(
    String id,
    String businessId,
    String newStatus,
  );
  Future<List<DepreciationSchedule>> getPendingSyncSchedules(
    String businessId, {
    int limit = 500,
  });
  Future<void> markScheduleAsSynced(String id, String businessId);
}
