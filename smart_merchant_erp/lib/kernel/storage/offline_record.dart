import 'package:equatable/equatable.dart';
import 'storage_state.dart';
import 'storage_strategy.dart';

/// Base contract that all offline-capable persistence models and DAOs must adhere to
/// across the Smart Merchant ERP system.
abstract interface class OfflineRecordContract {
  /// Unique identifier of the record (may match localUuid or server-generated ID after sync).
  String get id;

  /// Immutable client-side UUID generated upon creation on the local device (`UUID v4`).
  String get localUuid;

  /// Optional idempotency key used by remote sync engines to prevent duplicate ledger or invoice creation.
  String? get idempotencyKey;

  /// Current lifecycle state (`created`, `updated`, `deleted`, `synced`, etc.).
  StorageState get storageState;

  /// Timestamp of the last local or remote modification.
  DateTime get lastModified;
}

/// Generic wrapper that encapsulates any domain entity (`T`) with standardized
/// offline storage metadata required by local persistence engines and sync queue preparation.
class OfflineRecord<T> extends Equatable implements OfflineRecordContract {
  @override
  final String id;

  @override
  final String localUuid;

  @override
  final String? idempotencyKey;

  @override
  final StorageState storageState;

  @override
  final DateTime lastModified;

  /// The underlying domain entity or DTO payload.
  final T entity;

  /// The governing storage policy for this record.
  final StoragePolicy policy;

  const OfflineRecord({
    required this.id,
    required this.localUuid,
    required this.entity,
    required this.policy,
    required this.lastModified,
    this.idempotencyKey,
    this.storageState = StorageState.created,
  });

  /// Creates a copy of this record with updated lifecycle state or payload.
  OfflineRecord<T> copyWith({
    String? id,
    String? localUuid,
    String? idempotencyKey,
    StorageState? storageState,
    DateTime? lastModified,
    T? entity,
    StoragePolicy? policy,
  }) {
    return OfflineRecord<T>(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      storageState: storageState ?? this.storageState,
      lastModified: lastModified ?? this.lastModified,
      entity: entity ?? this.entity,
      policy: policy ?? this.policy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    localUuid,
    idempotencyKey,
    storageState,
    lastModified,
    entity,
    policy,
  ];
}
