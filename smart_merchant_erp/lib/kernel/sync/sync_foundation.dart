// Central barrel file exporting the Smart Merchant ERP Phase 2.2 & 2.3 Synchronization Foundation.
// Every ERP module and application initialization sequence should import this foundation
// when registering synchronization handlers, resolution policies, or monitoring dashboards.

// Phase 2.2 — Sync Queue & Background Processing
export 'queue/sync_queue_item.dart';
export 'queue/sync_queue_contract.dart';
export 'queue/sync_queue_storage.dart';
export 'queue/sync_queue_impl.dart';

export 'engine/sync_monitor.dart';
export 'engine/sync_upload_pipeline.dart';
export 'engine/sync_scheduler.dart';
export 'engine/background_sync_worker.dart';

// Phase 2.3 — Conflict Resolution & Synchronization Engine
export 'resolution/version_management.dart';
export 'resolution/change_detection.dart';
export 'resolution/conflict_detection.dart';
export 'resolution/merge_engine.dart';
export 'resolution/conflict_resolution.dart';

export 'engine/sync_download_pipeline.dart';
export 'engine/sync_state_machine.dart';
export 'engine/sync_history.dart';
export 'engine/sync_engine.dart';

export '../network/retry/sync_retry_policy.dart';
export '../network/connectivity/network_monitor.dart';
