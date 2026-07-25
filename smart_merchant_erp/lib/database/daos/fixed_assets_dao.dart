import 'package:drift/drift.dart';
import '../../kernel/storage/app_database.dart';
import '../tables/fixed_assets/depreciation_schedules_table.dart';
import '../tables/fixed_assets/fixed_assets_table.dart';
import 'dao_exceptions.dart';

part 'fixed_assets_dao.g.dart';

/// Filter DTO for [FixedAssets] queries.
class FixedAssetFilter {
  final String businessId;
  final String? branchId;
  final String? assetCategoryId;
  final String? status;
  final String? responsibleUserId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const FixedAssetFilter({
    required this.businessId,
    this.branchId,
    this.assetCategoryId,
    this.status,
    this.responsibleUserId,
    this.searchQuery,
    this.limit = 50,
    this.offset = 0,
  });
}

/// Filter DTO for [DepreciationSchedules] queries.
class DepreciationScheduleFilter {
  final String businessId;
  final String? fixedAssetId;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;
  final int offset;

  const DepreciationScheduleFilter({
    required this.businessId,
    this.fixedAssetId,
    this.status,
    this.fromDate,
    this.toDate,
    this.limit = 100,
    this.offset = 0,
  });
}

/// Composite result containing a [FixedAsset] and its associated [DepreciationSchedule] lines.
class FixedAssetWithDetails {
  final FixedAsset asset;
  final List<DepreciationSchedule> schedules;

  const FixedAssetWithDetails({required this.asset, required this.schedules});
}

@DriftAccessor(tables: [FixedAssets, DepreciationSchedules])
class FixedAssetsDao extends DatabaseAccessor<AppDatabase>
    with _$FixedAssetsDaoMixin {
  FixedAssetsDao(super.db);

  // ============================================================================
  // TENANT & SCOPE VALIDATION HELPERS
  // ============================================================================

  void _validateTenantScope(String businessId) {
    if (businessId.trim().isEmpty) {
      throw const TenantScopingException();
    }
  }

  // ============================================================================
  // 1. SINGLE RECORD & COMPOSITE READ METHODS
  // ============================================================================

  /// Retrieves a single [FixedAsset] by [id] and [businessId].
  Future<FixedAsset?> getFixedAssetById(String id, String businessId) async {
    _validateTenantScope(businessId);
    return (select(fixedAssets)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a single [FixedAsset] by [assetCode] within the tenant scope.
  Future<FixedAsset?> getFixedAssetByCode(
    String assetCode,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(fixedAssets)..where(
          (tbl) =>
              tbl.assetCode.equals(assetCode) &
              tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves a filtered and paginated list of [FixedAsset] records.
  Future<List<FixedAsset>> listFixedAssets(FixedAssetFilter filter) async {
    _validateTenantScope(filter.businessId);

    final query = select(fixedAssets)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.assetCategoryId != null &&
        filter.assetCategoryId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.assetCategoryId.equals(filter.assetCategoryId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((tbl) => tbl.status.equals(filter.status!));
    }
    if (filter.responsibleUserId != null &&
        filter.responsibleUserId!.trim().isNotEmpty) {
      query.where(
        (tbl) => tbl.responsibleUserId.equals(filter.responsibleUserId!),
      );
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((tbl) => tbl.assetCode.like(q) | tbl.assetName.like(q));
    }

    final safeLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 50 : filter.limit);
    final safeOffset = filter.offset < 0 ? 0 : filter.offset;

    query
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.acquisitionDate,
          mode: OrderingMode.desc,
        ),
        (tbl) => OrderingTerm(expression: tbl.id),
      ])
      ..limit(safeLimit, offset: safeOffset);

    return query.get();
  }

  /// Retrieves a single [DepreciationSchedule] by [id] and [businessId].
  Future<DepreciationSchedule?> getScheduleById(
    String id,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(depreciationSchedules)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .getSingleOrNull();
  }

  /// Retrieves all [DepreciationSchedule] lines for a specific [fixedAssetId], ordered chronologically.
  Future<List<DepreciationSchedule>> listSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    return (select(depreciationSchedules)
          ..where(
            (tbl) =>
                tbl.fixedAssetId.equals(fixedAssetId) &
                tbl.businessId.equals(businessId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.depreciationPeriod),
          ]))
        .get();
  }

  /// Retrieves a filtered and paginated list of [DepreciationSchedule] entries.
  Future<List<DepreciationSchedule>> listSchedules(
    DepreciationScheduleFilter filter,
  ) async {
    _validateTenantScope(filter.businessId);

    final query = select(depreciationSchedules)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.fixedAssetId != null && filter.fixedAssetId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.fixedAssetId.equals(filter.fixedAssetId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((tbl) => tbl.status.equals(filter.status!));
    }
    if (filter.fromDate != null) {
      query.where(
        (tbl) =>
            tbl.scheduledPostingDate.isBiggerOrEqualValue(filter.fromDate!),
      );
    }
    if (filter.toDate != null) {
      query.where(
        (tbl) => tbl.scheduledPostingDate.isSmallerOrEqualValue(filter.toDate!),
      );
    }

    final safeLimit = filter.limit > 500
        ? 500
        : (filter.limit <= 0 ? 100 : filter.limit);
    final safeOffset = filter.offset < 0 ? 0 : filter.offset;

    query
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.scheduledPostingDate),
        (tbl) => OrderingTerm(expression: tbl.depreciationPeriod),
        (tbl) => OrderingTerm(expression: tbl.id),
      ])
      ..limit(safeLimit, offset: safeOffset);

    return query.get();
  }

  /// Retrieves a [FixedAsset] joined with its complete list of [DepreciationSchedule] lines.
  Future<FixedAssetWithDetails?> getFixedAssetWithDetails(
    String id,
    String businessId,
  ) async {
    _validateTenantScope(businessId);
    final asset = await getFixedAssetById(id, businessId);
    if (asset == null) {
      return null;
    }

    final schedules = await listSchedulesByAssetId(id, businessId);
    return FixedAssetWithDetails(asset: asset, schedules: schedules);
  }

  // ============================================================================
  // 2. REACTIVE STREAM METHODS (`watch...`)
  // ============================================================================

  /// Watches a single [FixedAsset] by [id] and [businessId].
  Stream<FixedAsset?> watchFixedAssetById(String id, String businessId) {
    _validateTenantScope(businessId);
    return (select(fixedAssets)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .watchSingleOrNull();
  }

  /// Watches a filtered list of [FixedAsset] records.
  Stream<List<FixedAsset>> watchFixedAssets(FixedAssetFilter filter) {
    _validateTenantScope(filter.businessId);

    final query = select(fixedAssets)
      ..where((tbl) => tbl.businessId.equals(filter.businessId));

    if (filter.branchId != null && filter.branchId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.branchId.equals(filter.branchId!));
    }
    if (filter.assetCategoryId != null &&
        filter.assetCategoryId!.trim().isNotEmpty) {
      query.where((tbl) => tbl.assetCategoryId.equals(filter.assetCategoryId!));
    }
    if (filter.status != null && filter.status!.trim().isNotEmpty) {
      query.where((tbl) => tbl.status.equals(filter.status!));
    }
    if (filter.responsibleUserId != null &&
        filter.responsibleUserId!.trim().isNotEmpty) {
      query.where(
        (tbl) => tbl.responsibleUserId.equals(filter.responsibleUserId!),
      );
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final q = '%${filter.searchQuery!.trim()}%';
      query.where((tbl) => tbl.assetCode.like(q) | tbl.assetName.like(q));
    }

    final safeLimit = filter.limit > 200
        ? 200
        : (filter.limit <= 0 ? 50 : filter.limit);
    final safeOffset = filter.offset < 0 ? 0 : filter.offset;

    query
      ..orderBy([
        (tbl) => OrderingTerm(
          expression: tbl.acquisitionDate,
          mode: OrderingMode.desc,
        ),
        (tbl) => OrderingTerm(expression: tbl.id),
      ])
      ..limit(safeLimit, offset: safeOffset);

    return query.watch();
  }

  /// Watches all [DepreciationSchedule] lines for a specific [fixedAssetId].
  Stream<List<DepreciationSchedule>> watchSchedulesByAssetId(
    String fixedAssetId,
    String businessId,
  ) {
    _validateTenantScope(businessId);
    return (select(depreciationSchedules)
          ..where(
            (tbl) =>
                tbl.fixedAssetId.equals(fixedAssetId) &
                tbl.businessId.equals(businessId),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.depreciationPeriod),
          ]))
        .watch();
  }

  // ============================================================================
  // 3. MUTATION & ATOMIC TRANSACTION METHODS
  // ============================================================================

  /// Inserts a single [FixedAsset] record with offline sync initialization.
  Future<int> insertFixedAsset(FixedAssetsCompanion companion) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final normalized = companion.copyWith(
      syncStatus: const Value('pending_insert'),
      version: const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
    );

    try {
      return await into(fixedAssets).insert(normalized);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint') || msg.contains('duplicate')) {
        throw const DuplicateRecordException();
      } else if (msg.contains('foreign key constraint')) {
        throw const ForeignKeyConstraintException();
      }
      rethrow;
    }
  }

  /// Inserts a single [DepreciationSchedule] record with offline sync initialization.
  Future<int> insertDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  ) async {
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final normalized = companion.copyWith(
      syncStatus: const Value('pending_insert'),
      version: const Value(1),
      createdAt: companion.createdAt.present
          ? companion.createdAt
          : Value(DateTime.now()),
    );

    try {
      return await into(depreciationSchedules).insert(normalized);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint') || msg.contains('duplicate')) {
        throw const DuplicateRecordException();
      } else if (msg.contains('foreign key constraint')) {
        throw const ForeignKeyConstraintException();
      }
      rethrow;
    }
  }

  /// Atomically inserts a [FixedAsset] master record along with its associated [DepreciationSchedule] entries.
  /// If any schedule insertion violates a constraint (e.g. duplicate period or invalid foreign key),
  /// the entire transaction rolls back cleanly.
  Future<void> insertFixedAssetWithSchedules(
    FixedAssetsCompanion assetCompanion,
    List<DepreciationSchedulesCompanion> scheduleCompanions,
  ) async {
    final businessId = assetCompanion.businessId.value;
    _validateTenantScope(businessId);

    await transaction(() async {
      await insertFixedAsset(assetCompanion);

      final assetId = assetCompanion.id.value;
      for (final sCompanion in scheduleCompanions) {
        final lineBusinessId = sCompanion.businessId.value;
        if (lineBusinessId != businessId) {
          throw const TenantScopingException(
            'Schedule line businessId does not match parent asset businessId.',
          );
        }

        final normalizedSchedule = sCompanion.copyWith(
          fixedAssetId: Value(assetId),
          businessId: Value(businessId),
        );
        await insertDepreciationSchedule(normalizedSchedule);
      }
    });
  }

  /// Atomically inserts a batch of [DepreciationSchedule] records inside a transaction.
  Future<void> insertScheduleBatch(
    List<DepreciationSchedulesCompanion> schedules,
  ) async {
    if (schedules.isEmpty) {
      return;
    }
    final businessId = schedules.first.businessId.value;
    _validateTenantScope(businessId);

    await transaction(() async {
      for (final sCompanion in schedules) {
        if (sCompanion.businessId.value != businessId) {
          throw const TenantScopingException(
            'Inconsistent businessId within schedule batch.',
          );
        }
        await insertDepreciationSchedule(sCompanion);
      }
    });
  }

  /// Updates an existing [FixedAsset], incrementing [version] and marking [syncStatus] as 'pending_update'.
  Future<bool> updateFixedAsset(FixedAssetsCompanion companion) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'Both id and businessId must be present to update fixed asset.',
      );
    }
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getFixedAssetById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'Fixed asset record not found for update.',
      );
    }

    final newStatus = existing.syncStatus == 'pending_insert'
        ? 'pending_insert'
        : 'pending_update';
    final normalized = companion.copyWith(
      syncStatus: Value(newStatus),
      version: Value(existing.version + 1),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final rowsAffected =
          await (update(fixedAssets)..where(
                (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
              ))
              .write(normalized);
      return rowsAffected > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint') || msg.contains('duplicate')) {
        throw const DuplicateRecordException();
      } else if (msg.contains('foreign key constraint')) {
        throw const ForeignKeyConstraintException();
      }
      rethrow;
    }
  }

  /// Updates the lifecycle status of a [FixedAsset] (e.g. 'Active', 'Depreciating', 'Fully Depreciated', 'Disposed').
  Future<bool> updateFixedAssetStatus(
    String id,
    String businessId,
    String newStatus, {
    String? updatedBy,
  }) async {
    _validateTenantScope(businessId);
    final existing = await getFixedAssetById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'Fixed asset record not found for status update.',
      );
    }

    final syncState = existing.syncStatus == 'pending_insert'
        ? 'pending_insert'
        : 'pending_update';
    final companion = FixedAssetsCompanion(
      status: Value(newStatus),
      updatedBy: updatedBy != null ? Value(updatedBy) : const Value.absent(),
      syncStatus: Value(syncState),
      version: Value(existing.version + 1),
      updatedAt: Value(DateTime.now()),
    );

    final rowsAffected =
        await (update(fixedAssets)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(companion);
    return rowsAffected > 0;
  }

  /// Updates an existing [DepreciationSchedule] entry, incrementing [version] and updating [syncStatus].
  Future<bool> updateDepreciationSchedule(
    DepreciationSchedulesCompanion companion,
  ) async {
    if (!companion.id.present || !companion.businessId.present) {
      throw const TenantScopingException(
        'Both id and businessId must be present to update depreciation schedule.',
      );
    }
    final id = companion.id.value;
    final businessId = companion.businessId.value;
    _validateTenantScope(businessId);

    final existing = await getScheduleById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'Depreciation schedule record not found for update.',
      );
    }

    final newStatus = existing.syncStatus == 'pending_insert'
        ? 'pending_insert'
        : 'pending_update';
    final normalized = companion.copyWith(
      syncStatus: Value(newStatus),
      version: Value(existing.version + 1),
      updatedAt: Value(DateTime.now()),
    );

    try {
      final rowsAffected =
          await (update(depreciationSchedules)..where(
                (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
              ))
              .write(normalized);
      return rowsAffected > 0;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique constraint') || msg.contains('duplicate')) {
        throw const DuplicateRecordException();
      } else if (msg.contains('foreign key constraint')) {
        throw const ForeignKeyConstraintException();
      }
      rethrow;
    }
  }

  /// Updates the posting status of a [DepreciationSchedule] entry (e.g. 'Pending', 'Ready', 'Posted', 'Cancelled').
  Future<bool> updateScheduleStatus(
    String id,
    String businessId,
    String newStatus, {
    String? updatedBy,
  }) async {
    _validateTenantScope(businessId);
    final existing = await getScheduleById(id, businessId);
    if (existing == null) {
      throw const RecordNotFoundException(
        'Depreciation schedule record not found for status update.',
      );
    }

    final syncState = existing.syncStatus == 'pending_insert'
        ? 'pending_insert'
        : 'pending_update';
    final companion = DepreciationSchedulesCompanion(
      status: Value(newStatus),
      updatedBy: updatedBy != null ? Value(updatedBy) : const Value.absent(),
      syncStatus: Value(syncState),
      version: Value(existing.version + 1),
      updatedAt: Value(DateTime.now()),
    );

    final rowsAffected =
        await (update(depreciationSchedules)..where(
              (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
            ))
            .write(companion);
    return rowsAffected > 0;
  }

  // ============================================================================
  // 4. OFFLINE-FIRST SYNCHRONIZATION HELPERS
  // ============================================================================

  /// Retrieves [FixedAsset] records requiring cloud synchronization.
  Future<List<FixedAsset>> getPendingSyncFixedAssets(
    String businessId, {
    int limit = 500,
  }) async {
    _validateTenantScope(businessId);
    return (select(fixedAssets)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotIn(['synced']),
          )
          ..limit(limit))
        .get();
  }

  /// Marks a [FixedAsset] as synchronized with the remote cloud.
  Future<void> markFixedAssetAsSynced(
    String id,
    String businessId, {
    DateTime? syncedAt,
  }) async {
    _validateTenantScope(businessId);
    await (update(fixedAssets)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(const FixedAssetsCompanion(syncStatus: Value('synced')));
  }

  /// Retrieves [DepreciationSchedule] records requiring cloud synchronization.
  Future<List<DepreciationSchedule>> getPendingSyncSchedules(
    String businessId, {
    int limit = 500,
  }) async {
    _validateTenantScope(businessId);
    return (select(depreciationSchedules)
          ..where(
            (tbl) =>
                tbl.businessId.equals(businessId) &
                tbl.syncStatus.isNotIn(['synced']),
          )
          ..limit(limit))
        .get();
  }

  /// Marks a [DepreciationSchedule] as synchronized with the remote cloud.
  Future<void> markScheduleAsSynced(
    String id,
    String businessId, {
    DateTime? syncedAt,
  }) async {
    _validateTenantScope(businessId);
    await (update(depreciationSchedules)..where(
          (tbl) => tbl.id.equals(id) & tbl.businessId.equals(businessId),
        ))
        .write(
          const DepreciationSchedulesCompanion(syncStatus: Value('synced')),
        );
  }
}
