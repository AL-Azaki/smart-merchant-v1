import 'dart:async';
import '../queue/sync_queue_item.dart';
import 'sync_monitor.dart';

/// Represents the response returned by a remote API after transmitting a queued item.
class SyncPipelineResponse {
  /// Whether the remote transmission was successful (`HTTP 200/201`).
  final bool success;

  /// HTTP status code returned by the server.
  final int statusCode;

  /// Optional server-assigned unique ID for newly created records (`remoteId`).
  final String? remoteId;

  /// Raw response data dictionary from the Laravel server.
  final Map<String, dynamic>? responsePayload;

  /// Error message returned by the server if validation or authorization failed.
  final String? errorMessage;

  const SyncPipelineResponse({
    required this.success,
    required this.statusCode,
    this.remoteId,
    this.responsePayload,
    this.errorMessage,
  });

  /// Successful response factory (`HTTP 200 OK`).
  factory SyncPipelineResponse.success({
    int statusCode = 200,
    String? remoteId,
    Map<String, dynamic>? payload,
  }) => SyncPipelineResponse(
    success: true,
    statusCode: statusCode,
    remoteId: remoteId,
    responsePayload: payload,
  );

  /// Failure response factory (`HTTP 4xx / 5xx`).
  factory SyncPipelineResponse.failure({
    required int statusCode,
    required String message,
  }) => SyncPipelineResponse(
    success: false,
    statusCode: statusCode,
    errorMessage: message,
  );
}

/// Generic contract that specific domain synchronizers (e.g., `SalesInvoiceSyncHandler`)
/// implement to delegate API communication through existing [RemoteDataSource] contracts
/// without coupling the upload pipeline to business logic.
abstract interface class SyncPipelineHandler<T> {
  /// The entity type string this handler processes (`SalesInvoice`, `Customer`).
  String get entityType;

  /// Validates the queue item locally before attempting transmission.
  Future<void> validate(SyncQueueItem<T> item);

  /// Transforms the item payload into the JSON dictionary expected by the Laravel API endpoint.
  Future<Map<String, dynamic>> prepareRequest(SyncQueueItem<T> item);

  /// Transmits the prepared request data via the appropriate domain [RemoteDataSource].
  Future<SyncPipelineResponse> sendRequest(
    SyncQueueItem<T> item,
    Map<String, dynamic> requestData,
  );

  /// Hook executed upon successful server acknowledgment to update local storage (`StorageState.synced`).
  Future<void> onSyncSuccess(
    SyncQueueItem<T> item,
    SyncPipelineResponse response,
  );

  /// Hook executed upon transmission failure to record errors or trigger local fallback logic.
  Future<void> onSyncFailure(SyncQueueItem<T> item, SyncError error);
}

/// Orchestrates the standardized offline-first upload pipeline:
/// `Queue -> Prepare Request -> Validate -> Send via API -> Receive Response -> Update Queue -> Update Local Storage`
class SyncUploadPipeline {
  final Map<String, SyncPipelineHandler<dynamic>> _handlers = {};
  final SyncLoggerContract? _monitor;

  SyncUploadPipeline({SyncLoggerContract? monitor}) : _monitor = monitor;

  /// Registers a domain handler for a specific entity type.
  void registerHandler(SyncPipelineHandler<dynamic> handler) {
    _handlers[handler.entityType] = handler;
  }

  /// Executes the generic upload sequence for a queued item using the registered domain handler.
  Future<SyncPipelineResponse> execute<T>(SyncQueueItem<T> item) async {
    final handler = _handlers[item.entityType];
    if (handler == null) {
      final error = SyncError(
        message:
            'No SyncPipelineHandler registered for entity type ${item.entityType}',
        statusCode: 500,
        occurredAt: DateTime.now(),
        canRetry: false,
      );
      _monitor?.log(
        SyncLogEvent(
          timestamp: DateTime.now(),
          kind: SyncEventKind.uploadFailed,
          itemId: item.id,
          entityType: item.entityType,
          message: error.message,
        ),
      );
      return SyncPipelineResponse.failure(
        statusCode: 500,
        message: error.message,
      );
    }

    try {
      _monitor?.log(
        SyncLogEvent(
          timestamp: DateTime.now(),
          kind: SyncEventKind.uploadStarted,
          itemId: item.id,
          entityType: item.entityType,
          message:
              'Starting pipeline execution for ${item.operationType.name} on ${item.entityType}',
        ),
      );

      // Step 1: Validate payload
      await handler.validate(item);

      // Step 2: Prepare request payload
      final requestData = await handler.prepareRequest(item);

      // Step 3: Send via API (RemoteDataSource delegation)
      final response = await handler.sendRequest(item, requestData);

      // Step 4: Process Response
      if (response.success) {
        _monitor?.log(
          SyncLogEvent(
            timestamp: DateTime.now(),
            kind: SyncEventKind.uploadCompleted,
            itemId: item.id,
            entityType: item.entityType,
            message:
                'Upload completed successfully (HTTP ${response.statusCode})',
            details: {'remoteId': response.remoteId},
          ),
        );

        // Step 5: Update Local Storage Hook
        await handler.onSyncSuccess(item, response);
      } else {
        final error = SyncError(
          message: response.errorMessage ?? 'Unknown server rejection',
          statusCode: response.statusCode,
          occurredAt: DateTime.now(),
        );
        _monitor?.log(
          SyncLogEvent(
            timestamp: DateTime.now(),
            kind: SyncEventKind.uploadFailed,
            itemId: item.id,
            entityType: item.entityType,
            message: error.message,
            details: {'statusCode': response.statusCode},
          ),
        );
        await handler.onSyncFailure(item, error);
      }

      return response;
    } catch (e) {
      final error = SyncError(
        message: e.toString(),
        statusCode: 500,
        occurredAt: DateTime.now(),
      );
      _monitor?.log(
        SyncLogEvent(
          timestamp: DateTime.now(),
          kind: SyncEventKind.uploadFailed,
          itemId: item.id,
          entityType: item.entityType,
          message:
              'Exception during upload pipeline execution: ${error.message}',
        ),
      );
      await handler.onSyncFailure(item, error);
      return SyncPipelineResponse.failure(
        statusCode: 500,
        message: error.message,
      );
    }
  }
}
