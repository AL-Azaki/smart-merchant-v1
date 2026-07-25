/// Represents the lifecycle state of any local entity or record stored within
/// the Smart Merchant ERP Offline-First storage foundation.
///
/// This state governs whether a record needs future synchronization, whether it
/// is safely persisted, or if it has been marked for deletion without immediate
/// physical removal (Soft Delete).
enum StorageState {
  /// Newly created locally and has not yet been synced or pushed to the remote server.
  created,

  /// Modified locally after being synced or created; contains changes requiring upload.
  updated,

  /// Marked for soft deletion locally; awaits sync confirmation before physical purge.
  deleted,

  /// Currently queued or waiting in the background worker processing pipeline.
  pending,

  /// Historical or archived data retained locally for reference or compliance.
  archived,

  /// General dirty state for records with local modifications not yet reconciled.
  dirty,

  /// Fully synchronized and reconciled with the remote cloud source of truth.
  synced,
}

/// Extension methods providing semantic checks for [StorageState] across repositories
/// and local storage services.
extension StorageStateX on StorageState {
  /// Whether the record has local modifications that have not been acknowledged by the cloud.
  bool get isDirty =>
      this == StorageState.created ||
      this == StorageState.updated ||
      this == StorageState.deleted ||
      this == StorageState.dirty ||
      this == StorageState.pending;

  /// Whether the record requires future background synchronization.
  bool get requiresSync =>
      this == StorageState.created ||
      this == StorageState.updated ||
      this == StorageState.deleted ||
      this == StorageState.dirty;

  /// Whether the record is marked as deleted locally (soft deleted).
  bool get isSoftDeleted => this == StorageState.deleted;

  /// Whether the record is finalized and safe to prune if storage constraints require.
  bool get isPrunable =>
      this == StorageState.synced || this == StorageState.archived;
}
