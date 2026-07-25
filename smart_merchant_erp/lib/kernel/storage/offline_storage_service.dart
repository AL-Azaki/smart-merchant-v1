import '../core/data_sources.dart';
import 'offline_record.dart';
import 'storage_state.dart';
import 'storage_strategy.dart';

/// Reusable contract and persistence standard governing local storage operations
/// for every future module across the Smart Merchant ERP system.
///
/// Implements [LocalDataSource] to ensure clean architecture compliance and provides
/// standard guarantees for ACID transactions, soft delete, restore, and sync queue preparation
/// without directly implementing network or background worker logic.
abstract interface class OfflineStorageService<T> implements LocalDataSource {
  /// Retrieves a single domain entity by its unique identifier.
  Future<T?> getById(String id);

  /// Retrieves the complete [OfflineRecord] wrapper including state and idempotency keys.
  Future<OfflineRecord<T>?> getRecordById(String id);

  /// Retrieves all local domain entities, optionally including soft-deleted records.
  Future<List<T>> getAll({bool includeSoftDeleted = false});

  /// Retrieves all complete [OfflineRecord] wrappers, optionally including soft-deleted records.
  Future<List<OfflineRecord<T>>> getAllRecords({
    bool includeSoftDeleted = false,
  });

  /// Saves a new domain entity locally, wrapping it with [OfflineRecord] metadata
  /// and setting initial state to [StorageState.created].
  Future<OfflineRecord<T>> save(
    T entity, {
    StoragePolicy? policy,
    String? idempotencyKey,
  });

  /// Batch persistence operation to save multiple domain entities atomically.
  Future<List<OfflineRecord<T>>> saveAll(
    List<T> entities, {
    StoragePolicy? policy,
  });

  /// Updates an existing domain entity locally and marks its storage state as [StorageState.updated]
  /// unless overridden by [newState].
  Future<OfflineRecord<T>> update(T entity, {StorageState? newState});

  /// Marks a local record as soft-deleted ([StorageState.deleted]) without immediate physical removal.
  Future<bool> softDelete(String id);

  /// Restores a soft-deleted record back to [StorageState.updated] or [StorageState.created].
  Future<bool> restore(String id);

  /// Permanently purges a record from local physical storage (`Hard Delete`).
  /// Should only be executed after sync confirmation (`StorageState.synced`) or for temporary data.
  Future<bool> hardDelete(String id);

  /// Executes multiple local operations within an ACID database transaction.
  Future<R> runInTransaction<R>(Future<R> Function() action);

  /// Retrieves all records currently in a dirty state (`created`, `updated`, `deleted`, `dirty`)
  /// requiring future synchronization with the remote cloud server.
  Future<List<OfflineRecord<T>>> getPendingSyncRecords();

  /// Marks a batch of record identifiers as [StorageState.synced] following successful remote acknowledgment.
  Future<void> markAsSynced(List<String> ids);
}
