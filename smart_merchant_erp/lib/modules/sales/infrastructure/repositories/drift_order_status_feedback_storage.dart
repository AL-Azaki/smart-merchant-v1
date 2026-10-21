import 'package:drift/drift.dart';
import '../../../../kernel/storage/app_database.dart';
import '../../domain/models/order_status_feedback_item.dart';
import '../../domain/repositories/order_status_feedback_storage.dart';

/// True persistent storage for Order Status Feedback backed by Drift / SQLite.
///
/// Ensures strict outbox durability across application restarts, isolate teardowns,
/// and device power cycles.
///
/// PRIVACY & SECURITY INVARIANT:
/// Never stores customer PII, order line items, pricing, or sensitive credentials.
class DriftOrderStatusFeedbackStorage implements OrderStatusFeedbackStorage {
  final AppDatabase _db;
  bool _initialized = false;

  DriftOrderStatusFeedbackStorage(this._db);

  /// Ensures the outbox table and indexes exist in SQLite.
  Future<void> ensureTable() async {
    if (_initialized) {
      return;
    }
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS order_status_feedback_outbox (
        id TEXT PRIMARY KEY NOT NULL,
        order_id TEXT NOT NULL,
        target_status TEXT NOT NULL,
        invoice_id TEXT,
        invoice_number TEXT,
        completed_at TEXT,
        idempotency_key TEXT NOT NULL UNIQUE,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error_code INTEGER,
        last_error_message TEXT,
        next_retry_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_osfo_sync_status ON order_status_feedback_outbox (sync_status);',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_osfo_next_retry ON order_status_feedback_outbox (next_retry_at);',
    );
    await _db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_osfo_order_id ON order_status_feedback_outbox (order_id);',
    );
    await _db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_osfo_idempotency_key ON order_status_feedback_outbox (idempotency_key);',
    );
    _initialized = true;
  }

  @override
  Future<void> save(OrderStatusFeedbackItem item) async {
    await ensureTable();

    final syncStatus = item.isSynced ? 'synced' : 'pending';
    final createdAtMillis = item.createdAt.millisecondsSinceEpoch;
    final updatedAtMillis = item.updatedAt.millisecondsSinceEpoch;
    final nextRetryMillis = item.nextRetryAt?.millisecondsSinceEpoch;

    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO order_status_feedback_outbox (
        id, order_id, target_status, invoice_id, invoice_number,
        completed_at, idempotency_key, sync_status, attempt_count,
        last_error_code, last_error_message, next_retry_at,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        item.id,
        item.orderId,
        item.status,
        item.invoiceId,
        item.invoiceNumber,
        item.completedAt,
        item.idempotencyKey,
        syncStatus,
        item.retryCount,
        item.lastErrorCode,
        item.lastError,
        nextRetryMillis,
        createdAtMillis,
        updatedAtMillis,
      ],
    );
  }

  @override
  Future<List<OrderStatusFeedbackItem>> getPending() async {
    await ensureTable();

    final rows = await _db.customSelect(
      '''
      SELECT * FROM order_status_feedback_outbox
      WHERE sync_status = 'pending'
      ORDER BY created_at ASC;
      ''',
    ).get();

    return rows.map((row) => _fromRow(row)).toList();
  }

  @override
  Future<OrderStatusFeedbackItem?> getById(String id) async {
    await ensureTable();

    final rows = await _db.customSelect(
      '''
      SELECT * FROM order_status_feedback_outbox
      WHERE id = ? LIMIT 1;
      ''',
      variables: [Variable.withString(id)],
    ).get();

    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  @override
  Future<void> markSynced(String id) async {
    await ensureTable();

    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    await _db.customStatement(
      '''
      UPDATE order_status_feedback_outbox
      SET sync_status = 'synced', updated_at = ?
      WHERE id = ?;
      ''',
      [nowMillis, id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await ensureTable();

    await _db.customStatement(
      'DELETE FROM order_status_feedback_outbox WHERE id = ?;',
      [id],
    );
  }

  @override
  Future<void> clear() async {
    await ensureTable();

    await _db.customStatement('DELETE FROM order_status_feedback_outbox;');
  }

  OrderStatusFeedbackItem _fromRow(QueryRow row) {
    final nextRetry = row.read<int?>('next_retry_at');
    final createdAt = row.read<int>('created_at');
    final updatedAt = row.read<int>('updated_at');

    return OrderStatusFeedbackItem(
      id: row.read<String>('id'),
      orderId: row.read<String>('order_id'),
      status: row.read<String>('target_status'),
      invoiceId: row.read<String?>('invoice_id'),
      invoiceNumber: row.read<String?>('invoice_number'),
      completedAt: row.read<String?>('completed_at'),
      idempotencyKey: row.read<String>('idempotency_key'),
      isSynced: row.read<String>('sync_status') == 'synced',
      retryCount: row.read<int>('attempt_count'),
      lastErrorCode: row.read<int?>('last_error_code'),
      lastError: row.read<String?>('last_error_message'),
      nextRetryAt: nextRetry != null
          ? DateTime.fromMillisecondsSinceEpoch(nextRetry)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}
